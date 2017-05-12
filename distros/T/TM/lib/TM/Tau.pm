package TM::Tau;

use TM::Tau::Filter;
use base qw(TM::Tau::Filter);

use Data::Dumper;

=pod

=head1 NAME

TM::Tau - Topic Maps, Tau Expressions

=head1 SYNOPSIS

  use TM::Tau;
  # read a map from an XTM file
  $tm = new TM::Tau ('test.xtm');        # or
  $tm = new TM::Tau ('file:test.xtm');   # or
  $tm = new TM::Tau ('file:test.xtm >'); # or
  $tm = new TM::Tau ('file:test.xtm > null:');

  # read it now and write it back to the file when object goes out of scope
  $tm = new TM::Tau ('test.xtm > test.xtm');

  # create empty map at start and then let it automatically flush onto file
  $tm = new TM::Tau ('null: > test.xtm'); # or
  $tm = new TM::Tau ('> test.xtm');

  # read-in at the start (i.e. constructor time) and then flush it back
  $tm = new TM::Tau ('> test.xtm >');

  # load and merge maps at constructor time
  $tm = new TM::Tau ('file:test.xtm + http://..../test.atm');

  # load map and filter it with a constraint at constructor time
  $tm = new TM::Tau ('mymap.atm * myontology.ont');

  # convert between different formats
  $tm = new TM::Tau ('test.xtm > test.atm');

=head1 DESCRIPTION

When you need to make maps persistent, then you can resort to either using the prefabricated
packages L<TM::Materialized::*>, or you can build your own persistent forms using any of the
available synchronizable traits.  In either case your application will have to invoke methods like
C<sync_in> and C<sync_out> to copy content from the resource into memory and back.

While this gives you great flexibility, in some cases your needs may be much simpler:

=over

=item consumer model:

A map should be sourced into memory when the map object is created.

A typical use case is a web server application which accesses the map on disk with every request and
which returns parts of the map to an HTTP client.

=item producer model: 

A map is created first in memory and is flushed onto disk at destruction time.

One example here is a script which extracts content from a relational database, puts it into a map
in memory. At the end all map content is copied onto disk.

=item maintainer model: 

A map is sourced from the disk at map object creation time, you update it
and it will be flushed back to the same disk location at object destruction.

Your application may be started with with new content to be put into an existing map. So first the
map will be loaded, the new content added, and after that the map will be written back from where it
came.

=item translator model: 

A map is sourced from the disk, is translated into some other representation
and is written back to disk to another location or format.

As an example, you might want to convert between XTM and CTM format.

=item filter model:

A map is sourced from some backend, is transformed and/or filtered before being
used.

Your application could be one which only needs a particular portion of the map. So before processing
the map is filtered down to the necessary parts.

=item integration model:

One or more maps are sourced from backends and are merged before
processing.

If you want to provide a consolidated view over several different data resources, you could first
bring them all into topic map form, and then merge them before handing it to the application.

=back

What is common to all these cases is that there is a I<breath-in> phase when the map object is
constructed, and a I<breath-out> phase when it is destroyed. In between theses phases the map
object is just a normal instance of L<TM>.

=head1 TAU EXPRESSIONS

=head2 Overview

To control what happens in these two phases, this package provides a simple expression language,
call B<Tau>. With it you can control

=over

=item * where maps are supposed to come from, or go to,

Here the language provides a URI mechanism for addressing, such as

   file:tm.atm

or

   http://topicmaps/some/map.xtm

=item * when (or how) they should be merged,

To merge two (manifested or virtual) topic maps together the C<+> operator can be used

   file:tm.atm + http://topicmaps/some/map.xtm

=item * when (or how) they should be transformed,

To transform product data to only something a customer is supposed to see, the C<*> can be used:

   product_data.atm * file:customer_view.tmql

=item * when (or whether at all) they should be loaded oder saved

=back

B<NOTE>: Later versions of this package will heavily overload the operators to also operate on other
objects.

=head2 Syntax

The Tau expression language supports two binary operators, C<+> and C<*>. The C<+> operator
intuitively puts things together, the C<*> applies the right-hand operand to the left-hand operand
and behaves as a transformer or a filter. The exact semantics depends on the operands. In any case,
the C<*> binds stronger than the C<+>, and that precedence order can be overridden with parentheses.

The parser understands the following syntax for Tau expression:

   tau_expr    -> mul_expr

   mul_expr    -> source { ('>' | '*') filter }

   source      -> '(' add_expr ')' | primitive

   add_expr    -> mul_expr { '+' mul_expr }

   filter      -> '(' filter ')' | primitive

   primitive   -> uri [ module_spec ]

   module_spec -> '{' name '}'

Terms in quotes are terminals, terms inside {} can appear any number of times (also zero), terms
inside [] are optional. All other terms are non-terminals.

B<NOTE>: Filters are planned to be composite, hence the optional bracketing in the grammar.

=cut

#== tau expressions =======================================================

$::RD_HINT = 1;

our $tau_grammar = q{

   {
       my $sources;
       my $filters;
       my $ms;
       use Data::Dumper;

       sub _mk_node {
	   my $uri   = shift;
	   my $spec  = shift;
	   my $first = shift || 0;
	   my $last  = shift || 0;

	   my $node;

	   $uri = ( $first ? 'io:stdin' : 'io:stdout' ) if $uri eq '-';             # decide what - actually should mean

	   if (ref ($spec)) {                                                       # if it is a list, then we have filter with traits
	       $node = new TM::Tau::Filter (url => $uri, baseuri => $uri );         # in any case this will be a filter
	       bless $node, 'TM::Tau' if $last;                                     # but if it is the last in the row, then a TM::Tau

	       foreach my $trait (@{ $spec }) {                                     # the rest of the list are traits
		   eval {
		       Class::Trait->apply ( $node => $trait => { exclude => [ 'mtime', 'sync_out', 'source_in' ] } ); # which we add now
                   }; die "cannot apply trait '$trait' for URI '$uri' ($@)" if $@;
	       }
	   } else {                                                                 # otherwise it is a simple module
	       my $module = $spec;                                                  # take that
	       eval "use $module";                                                  # try to load it on the fly
	       eval {                                                               # try to
		   $node = $module->new (url => $uri, baseuri => $uri );            # instantiate an object
	       }; 
	       die "cannot load '$module' for URI '$uri' ($@)"    if $@;
	       die "cannot instatiate object for '$module' ($@)"  unless $node;
	   }
	   return $node;
       }

       sub _mk_tree {
	   my $spec = shift;
	   my $top  = shift || 0;                                                     # are we at the top?
	   
#warn "mktree: ". Dumper $spec;
	   my $t;                                                                     # here we collect the tree
	   while (my $m = shift @$spec) {                                             # walk through the mul_expr's
	       my $c;                                                                 # find a new chain member
	       if (ref ($m) eq 'ARRAY') {                                             # this means that this operand (can only be the first) is an add_expr
		   my $d1 = _mk_tree (shift @{$m});                                   # take the first and make it a node
		   while (my $d2 = _mk_tree (shift @{$m})) {                          # if there are more things to add
		       use TM::Tau::Federate;
		       $d1 = new TM::Tau::Federate (left       => $d1,                # build a federation
						    right      => $d2,
						    url        => 'what:ever');
		   }
		   $c = $d1;                                                          # tuck it away for the end of the loop

	       } elsif (ref ($m) eq 'HASH') {                                         # this is just a primitive source/filter
		   $c = _mk_node (%$m,                                                # create a source/filter node
				  !defined $t,                                        # this is the first in a chain, so we have no $t yet
				  $top && ! @$spec);                                  # let it also know whether this is the top-top-top, so last, last, last
	       } else {
		   die "now this is bad";
	       }
	       
	       if ($t) {                                                              # we know there was something in the chain already and c is a filter
		   $c->left ($t);
		   $t = $c;
	       } else {
		   $t = $c;
	       }
	   }

	   return $t;
       }
    }

   startrule    : { $sources = $arg[0]; $filters = $arg[1]; }                                            # collect parameters
                  tau_expr

   tau_expr     : mul_expr                                { $return = _mk_tree ($item[1], 1); }          # a tau expr is a filter

   mul_expr     : source ( '*' filter )(s?)               { $return = [ $item[1], @{$item[2]} ]; }  

   source       : '(' add_expr ')'                        { $return = $item[2]; }
                | primitive[$sources]

   add_expr     : <leftop: mul_expr '+' mul_expr>

   filter       : '(' filter ')'                          { $return = $item[2]; }                        # we allow arbitrary ()-nesting here, but
                | primitive[$filters]                                                                    # a filter cannot be composite (yet)

   primitive    : <rulevar: $schemes = $arg[0]>

   primitive    : /[^\s()>\*\{\}]+/ module(?)
                {
#warn "using schemes ".Dumper ($schemes)." for $item[1]";
		    my $uri = $item[1];
		    if (@{$item[2]} && $item[2]->[0]) {                                                  # its defined and there is a module specification
			$return = { $uri, $item[2]->[0] };                                               # take that
		    } else {                                                                             # no module, so we have to guess via schemes
			$return = undef;
			foreach my $s (keys %$schemes) {                                                 # look at all of them
			    if ($uri =~ /$s/) {                                                          # if it matches
				$return = { $uri, $schemes->{$s} };
				last;                                                                    # if we found something, we stop
			    }
			}
			die "expression parser: undefined scheme '$uri' detected" unless $return;        # loop exhausted and nothing found => bad
		    }
		}

   module       : '{' /[\w:]*/ '}' { $return = $item[2]; }

};

my $parser; # will be compiled once when it is needed and then will be kept, this is faster

sub _parse {
    my $tau    = shift;
    my $ms     = shift;

    use Parse::RecDescent;
#    $::RD_TRACE = 1;
#    $::RD_HINT = 1;
#    $::RD_WARN = 1;
    $parser ||= new Parse::RecDescent ($tau_grammar)           or  $TM::log->logdie (scalar __PACKAGE__ . ": problem in tau grammar");

    my $f = $parser->startrule (\$tau,  1, \%sources,                  # predefined sources
				           \%filters)                  # add the currently known filters
				           ;
    $TM::log->logdie (scalar __PACKAGE__ . ": found unparseable '$tau'") if $tau =~ /\S/s ;
    return $f;
}

=pod

The (pre)parser supports the following shortcuts (I hate unnecessary typing):

=over

=item *

"whatever" is interpreted as "(whatever) > -"

=item *

"whatever >" is interpreted as "(whatever) > -"

=item *

"> whatever" is interpreted as  "- > (whatever)"

=item *

"< whatever >" is interpreted as "whatever > whatever", sync_in => 0

=item *

"> whatever <" is interpreted as "whatever > whatever", sync_out => 0

=item *

"> whatever >" is interpreted as "whatever > whatever"

=item *

"< whatever <" is interpreted as "whatever > whatever", sync_in => 0, sync_out => 0

=item *

The URI C<-> as source is interpreted as STDIN (via the L<TM::Serializable::AsTMa> trait).
Unless you override that.

=item *

The URI C<-> as filter is interpreted as STDOUT (via the L<TM::Serializable::Dumper> trait).
Unless you override that.

=back

=head2 Examples

  # memory-only map
  null: > null:

  # read at startup, sync out when map goes out of scope
  file:test.atm > file:test.atm

  # copy AsTMa= to XTM
  file:test.atm > file:test.xtm

  # using a dedicated driver to load a map, store it onto a file
  dns:my.dns.server { My::DNS::Driver } > file:dns_snapshot.atm
  # this will only work if the My::DNS::Driver supports to materialize
  # the whole map

  # read a map and compute the statistics
  file:test.atm * http://psi.tm.bond.edu.au/queries/1.0/statistics

=head2 Map Source URLs

URIs are used to address maps. An XTM map, for example, stored in the file system might be addressed
as

  file:mydir/somemap.xtm

for a relative URL (relative to an application's current working directory), or via an
absolute URI such as

  http://myserver/somemap.atm

The package supports all those access methods (file:, http:, ...) which L<LWP> supports.

=head2 Drivers

Obviously a different deserializer package has to be used for an XTM file than for an AsTMa or LTM
file. Some topic map content may be in a TM backend database, some content may only exist virtually,
being emulated by a dedicated package.  While you may be mostly fine with system defaults, in some
cases you may want to have precise control on how files and other external sources are to be
interpreted. By their nature, drivers for sources must be subclasses of L<TM>.

A similar consideration applies to filters. Also here the specified URI determines which filter
actually has to be applied. It also can define where the content eventually is stored to. Drivers
for filters must be either subclasses of L<TM::Tau::Filter>, or alternatively must be a trait
providing a method C<sync_out>.

=head2 Binding by Schemes (implicit)

When a Tau expression is parsed, the parser tries to identify which driver to use for which part of
that composite map denoted by the expression. For this purpose a pattern matching approach is used
to map regular expression patterns to driver package names. If you would like to learn about the
current state of affairs do a

   use Data::Dumper;
   print Dumper \%TM::Tau::sources;
   print Dumper \%TM::Tau::filters;

Obviously, there is a distinction made between the namespace of resources (residing data) and
filters (and transformers).

Each entry in any of the hashes contains as key a regular expression and as value the name of the
driver to be used. That key is matched against the parsed URI and the first match wins. Since the
keys in a hash are not naturally ordered, that is undefined.

At any time you can override values there:

   $TM::Tau::sources{'null:'}          = 'TM';
   $TM::Tau::sources{'tm:server\.com'} = 'My::Private::TopicMap::Driver';

or delete existing ones. The only constraint is that the driver package must already be C<require>d
into your Perl program.

During parsing of a Tau expression, two cases are distinguished:

=over

=item *

If the URI specifies a I<source>, then this URI will be matched against the regexps in the
C<TM::Tau::sources> hash. The value of that entry will be used as class name to instantiate an
object whereby one component (C<uri>) will be passed as parameter like this:

I<$this_class_name>->new (uri => I<$this_uri>, baseuri => I<$this_uri>)

This class should be a subclass of L<TM>.

=item *

If the URI specifies a I<filter>, then you have two options: Either you use as entry the name of a
subclass of L<TM::Tau::Filter>. Then an object is created like above. Alternatively, the entry is a
list reference containing names of traits. Then a generic L<TM::Tau::Filter> node is generated first
and each of the traits are applied like this:

Class::Trait->apply ( $node => I<$trait> => {
                               exclude => [ 'mtime',
                                            'sync_out',
                                            'source_in' ]
                               } );

=back

If there is no match, this results in an exception.

=cut

our %sources = (
	        '^null:$'          	     => 'TM::Materialized::Null',

		'^(file|ftp|http):.*\.atm$'  => 'TM::Materialized::AsTMa',
		'^(file|ftp|http):.*\.ltm$'  => 'TM::Materialized::LTM',
		'^(file|ftp|http):.*\.ctm$'  => 'TM::Materialized::CTM',
                '^file:/tmp/.*'              => 'TM::Materialized::AsTMa',
		'^(file|ftp|http):.*\.xtm$'  => 'TM::Materialized::XTM',
		'^inline:.*'       	     => 'TM::Materialized::AsTMa',

		'^io:stdin$'       	     => 'TM::Materialized::AsTMa',
		'^-$'                        => 'TM::Materialized::AsTMa',                         # in "- > whatever:xxx" the - is the map coming via STDIN
                );

our %filters = (                                                                                   # TM::Tau::Filter::* packages are supposed to register there
		'^null:$'                    => [ 'TM::Serializable::Dumper' ],

		'^(file|ftp|http):.*\.atm$'  => [ 'TM::Serializable::AsTMa' ],
		'^(file|ftp|http):.*\.ltm$'  => [ 'TM::Serializable::LTM' ],
		'^(file|ftp|http):.*\.xtm$'  => [ 'TM::Serializable::XTM' ],
		'^(file|ftp|http):.*\.ctm$'  => [ 'TM::Serializable::CTM' ],

		'^-$'                        => [ 'TM::Serializable::Dumper' ],                    # in "whatever > -" the - is an empty filter
		'^io:stdout$'      	     => [ 'TM::Serializable::Dumper' ],                    # stdout can be a URL for a filter
		);

# make sure all registered packages have been loaded
use TM;
use TM::Tau::Filter;

=pod

=head2 Binding by Package Pragmas (Explicit)

Another way to define which package should be used for a particular map
is to specify this directly in the I<tau> expression:

   http://.../map.xtm { My::BrokenXTM }

In this case the resource is loaded and is processed using
C<My::BrokenXTM> as package to parse it (see L<TM::Materialized::Stream> on how to write
such a driver).

=head1 INTERFACE

=head2 Constructor

The constructor accepts a string following the I<Tau expression> L</Syntax>.  If that string is
missing, C<< null: >> will be assumed. An appropriate exception will be raised if the syntax is
violated or one of the mentioned drivers is not preloaded.

Examples:

   # map only existing in memory
   my $map = new TM::Tau;

   # map will be loaded as result of this tau expression
   my $map = new TM::Tau ('file:music.atm * file:beatles.tmql');

Apart from the Tau expression the constructor optionally interprets a hash with the following keys:

=over

=item C<sync_in> (default: C<1>)

If non-zero, in-synchronisation at constructor time will happen, otherwise it is suppressed. In that
case you can trigger in-synchronisation explicitly with the method C<sync_in>.

=item C<sync_out> (default: C<1>)

If non-zero, out-synchronisation at destruction time will happen, otherwise it is suppressed.

=back

Example:

   my $map = new TM::Tau ('test.xtm', 
                          sync_in => 0); # dont want to let it happen now
   ....                                  # time passes 
   $map->sync_in;                        # but now is a good time

=cut

sub new {
    my $class = shift;
    my $tau   = shift || "null:";
    my %opts  = @_;

#warn "cano0 '$tau'";

    # providing defaults
    $opts{sync_in}  = 1 unless defined $opts{sync_in};
    $opts{sync_out} = 1 unless defined $opts{sync_out};

    $_ = $tau;                                                                          # we do a number of things now

    # canonicalization, phase 0: remove leading/trailing blanks
    s/^\s*//;
    s/\s*$//;

    # canonicalization, phase I: reduce the ><><>< crazyness to A > B
    if (/^<(.*)>$/) {
	$_ = "($1) * ($1)";
	$opts{sync_in} = 0; $opts{sync_out} = 1;
    } elsif (/^>(.*)<$/) {
	$_ = "($1) * ($1)";
	$opts{sync_in} = 1; $opts{sync_out} = 0;
    } elsif (/^>(.*)>$/) {
	$_ = "($1) * ($1)";
	$opts{sync_in} =    $opts{sync_out} = 1;
    } elsif (/^<(.*)<$/) {
	$_ = "($1) * ($1)";
	$opts{sync_in} =    $opts{sync_out} = 0;

    } elsif (/^(.*)>$/) {                                                               # > - default
	$_ = "($1) * -";
    } elsif (/^>(.*)$/) {                                                               # - > default
	$_ = "- * $1";
    } elsif (/^(.*?)>(.*?)$/) {                                                         # there is a > somewhere in between
	$_ = "( $1 ) * ( $2 )";

    } else {                                                                            # no > to be see anywhere
	$_ = "($_) * -";
    }

#warn "cano2 '$_'";

    my $self = _parse ($_);                                                             # DIRTY, but then not
#warn "============> ". ref ($self->left) . " <-- left -- " . ref ($self);
#warn "base of top ".$self->{baseuri}." xxx";

    $self->{sync_in}  = $opts{sync_in};                                                 # same here
    $self->{sync_out} = $opts{sync_out};

    $self->sync_in if $self->{sync_in};                                                 # if user wants to sync at constructor time, lets do it
    return $self;
}

=pod

=head1 SEE ALSO

L<TM>, L<TM::Tau::Filter>

=head1 AUTHOR

Copyright 200[0-68], Robert Barta E<lt>drrho@cpan.orgE<gt>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html


=cut

our $VERSION  = '1.15';
our $REVISION = '$Id: Tau.pm,v 1.13 2006/12/05 09:50:38 rho Exp $';

1;

__END__

