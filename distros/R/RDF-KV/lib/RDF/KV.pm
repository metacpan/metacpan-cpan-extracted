package RDF::KV;

use 5.010;
use strict;
use warnings FATAL => 'all';

# might as well use full-blown moose if URI::NamespaceMap uses it
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use Try::Tiny;

use Carp               ();
use Scalar::Util       ();
use XML::RegExp        ();
use Data::GUID::Any    ();
use Data::UUID::NCName ();

use URI;
use URI::BNode;
use URI::NamespaceMap;
# XXX remind me to rewrite this using Moo.

use RDF::KV::Patch;

=head1 NAME

RDF::KV - Embed RDF linked data in plain old HTML forms

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

class_type 'URI';

# here's ye olde grammar:

# XXX I know I said in the spec that the protocol should be parseable
# by a single regex, but regexes make for lame, all-or-nothing
# parsers. As such, this should really be rewritten when there's time
# to create a more helpful (in the error message sense) parser.

# ok you know what? no. This is waaaaaaay simpler.
my $MODIFIER     = qr/(?:[!=+-]|[+-]!|![+-])/o;
my $PREFIX       = qr/(?:$XML::RegExp::NCName|[A-Za-z][0-9A-Za-z.+-]*)/o;
my $TERM         = qr/(?:$PREFIX:\S*)/o;
my $RFC5646      = qr/(?:[A-Za-z]+(?:-[0-9A-Za-z]+)*)/o;
my $DESIGNATOR   = qr/(?:[:_']|\@$RFC5646|\^$TERM)/o;
my $DECLARATION  = qr/^\s*\$\s+($XML::RegExp::NCName)(?:\s+(\$))?\s*$/mo;
my $MACRO        = qr/(?:\$\{($XML::RegExp::NCName)\}|
                          \$($XML::RegExp::NCName))/xo;
my $NOT_MACRO    = qr/(?:(?!\$$XML::RegExp::NCName|
                              \$\{$XML::RegExp::NCName\}).)*/xso;
my $MACROS       = qr/($NOT_MACRO)(?:$MACRO)?($NOT_MACRO)/smo;
my $PARTIAL_STMT = qr/^\s*(?:($MODIFIER)\s+)?
                      (?:($TERM)(?:\s+($TERM))?(?:\s+($DESIGNATOR))?|
                          ($TERM)\s+($DESIGNATOR)\s+($TERM)|
                          ($TERM)\s+($TERM)(?:\s+($DESIGNATOR))?\s+($TERM))
                      (?:\s+(\$))?\s*$/xsmo;

my @MAP = qw(modifier term1 term2 designator term1 designator graph
             term1 term2 designator graph deref);

=head1 SYNOPSIS

    my $kv = RDF::KV->new(
        subject    => $uri,      # ordinarily the Request-URI
        graph      => $graphuri, # URI for the default graph
        namespaces => $ns,       # default namespace prefix map
        callback   => \&rewrite, # form-results-rewriting callback
    );

    # Processes a hashref-of-parameters, like found in Catalyst or
    # Plack::Request. This call will ignore obviously non-matching
    # keys, but will croak on botched attempts to use the protocol.

    my $patch = eval { $kv->process($params) };
    if ($@) {
        # return 409 Conflict ...
    }

    # add/remove statements from the graph
    $patch->apply($model);

=head1 DESCRIPTION

This module provides a reference implementation for the L<RDF-KV
protocol|http://doriantaylor.com/rdf-kv>. The objective of this
protocol is to convey RDF linked data from a web browser to a web
server using no mechanism beyond conventional
C<application/x-www-form-urlencoded> HTML forms. The overarching
purpose is to facilitate the development of linked data applications
by making the apparatus of JavaScript an I<optional>, rather than a
I<mandatory>, consideration.

This protocol implementation works by culling key-value pairs denoted
in a prescribed syntax from POSTed form input (parsed by something
like L<CGI>, L<Plack::Request> or L<Catalyst>), and then stitching
them together to create a L<patch object|RDF::KV::Patch> which is then
applied to an L<RDF::Trine::Model> graph.

=head1 METHODS

=head2 new

Instantiate the object. The following parameters are also (read-only)
accessors.

=over 4

=item subject

This is the default subject URI (or blank node).

=cut

has subject => (
    is       => 'rw',
    isa      => 'Str|URI',
    required => 1,
);

=item graph

This is the default graph URI.

=cut

has graph => (
    is      => 'rw',
    isa     => 'Str|URI',
    default => '',
);

=item namespaces

This L<URI::NamespaceMap> object will enable URI abbreviation through
the use of CURIEs in form input.

=cut

has namespaces => (
    is      => 'ro',
    isa     => 'URI::NamespaceMap',
    default => sub { URI::NamespaceMap->new },
);

=item callback

Supply a callback function that will be applied to subject and object
values, for instance to rewrite a URI. The return value of this
function must be understood by L<RDF::KV::Patch/add_this>.

=cut

has callback => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub { sub { shift } },
);

=back

=head2 process \%CONTENT

Process form content and return an L<RDF::KV::Patch> object. This is
the only significant method.

=cut

# variants of parameter getters

sub _1 {
    my ($params, $k) = @_;
    $params->get_all($k);
}

sub _2 {
    my ($params, $k) = @_;
    my $val = $params->{$k};
    ref $val ? @$val : $val;
}

sub _uuid4 () {
    lc Data::GUID::Any::v4_guid_as_string();
}

sub _uuid4urn () {
    'urn:uuid:' . _uuid4;
}

sub _uuid4bn () {
    URI::BNode->new;
}

# XXX these should all get syntax checks/CURIE expansion/etc
my %SPECIALS = (
    SUBJECT => sub {
        my ($self, $val) = @_;
        $self->subject($val->[-1]) if @$val;
    },
    GRAPH => sub {
        my ($self, $val) = @_;
        $self->graph($val->[-1]) if @$val;
    },
    PREFIX => sub {
        my ($self, $val) = @_;
        # XXX CHECK THIS MUTHA
        for my $v (@$val) {
            #warn $v;
            my ($prefix, $uri) = ($v =~ /^\s*(\S+):\s+(.*)$/)
                or Carp::croak("Invalid prefix mapping $val");
            #warn $uri;
            $self->namespaces->add_mapping($prefix, $uri);
        }
    },
);

my %GENERATED = (
    NEW_UUID     => [[\&_uuid4,    0]],
    NEW_UUID_URN => [[\&_uuid4urn, 0]],
    NEW_BNODE    => [[\&_uuid4bn,  0]],
);

sub _deref_content {
    my ($val, $macros) = @_;
    my @out;

    # if $val is scalar, this loop will run just once.
    for my $v (ref $val ? @$val : ($val)) {
        # make this versatile
        $v = $v->[0] if ref $v;

        my @chunks;
        while ($v =~ /\G$MACROS/gco) {
            #warn "seen me";
            my $pre   = $1;
            my $macro = $2 || $3;
            my $post  = $4;

            unless (defined $macro) {
                if (@chunks) {
                    @chunks = map { "$_$pre$post" } @chunks;
                }
                else {
                    @chunks = ($pre . $post);
                }
                next;
            }

            # do the actual macro dereferencing or noop in
            # lieu of a bound macro
            my @x = (defined $macros->{$macro} && @{$macros->{$macro}} ?
                         (map { sprintf('%s%s%s',
                                        $pre, ref $_ ? &$_ : $_, $post)
                            } @{$macros->{$macro}}) : ("$pre\$$macro$post"));
            # XXX LOLOLOL THIS IS THE MOST ILLEGIBLE PILE OF NONSENSE

            # it says: if a macro value is present, sub it or no-op,
            # but if the macro is a code ref, run it.

            #warn 'wat: ' . Data::Dumper::Dumper(\@x);

            # initialize chunks
            unless (@chunks) {
                #warn 'correct!';
                @chunks = @x;
                next;
            }

            # replace chunks with product of itself and x
            if (@x) {
                my @y;
                for my $c (@chunks) {
                    for my $d (@x) {
                        #warn 'halp wtf';
                        push @y, "$c$d";
                    }
                }
                @chunks = @y;
            }
        }

        push @out, @chunks;
    }
    #warn 'hurr: ' . Data::Dumper::Dumper(\@out);


    wantarray ? @out : \@out;
}

sub _massage_macros {
    my $macros = shift;
    # XXX this currently makes destructive changes to $macros insofar
    # as it rewrites the 'deref' flag with the actual variables to
    # dereference, or to 0 if there aren't any. If this becomes a
    # problem, just use Clone.

    # cycle detect, finished product
    my (%seen, %done);

    # shallow-copy the hash
    my %pending = %$macros;

    # get rid of generated
    map { delete $pending{$_} } keys %GENERATED;

    # Start a queue with a (quasi) random macro.
    my @queue = (keys %pending)[0];

    # If none of them contain a (bound) macro references, that macro
    # is 'done'.

    # If the values *do* contain bound macro references, check to see
    # if those are 'done'. If they aren't, *prepend* the keys to the
    # queue, before the current macro.

    while (@queue) {
        #warn 'Initial ' . join(';', @queue);
        my $k = shift @queue;
        #warn "beginning \$$k";

        $seen{$k}++;

        my @vals = @{$macros->{$k}};

        # 'done' and 'pending' macros
        my (%dm, %pm);

        # Examine each of its values.

        # Note: this test is equivalent to concatenating the values
        # together with spaces and performing the regex on that. But
        # we can't do that because we're storing the macro-matching
        # state of individual values.
        for my $pair (@vals) {
            my ($val, $deref) = @$pair;

            # no expando
            next unless $deref;

            if (ref $deref) {
                # already been scanned
                for my $m (@$deref) {
                    defined $done{$m} ? $dm{$m}++ : $pm{$m}++;
                }
            }
            else {
                my %m;
                for my $m (grep { defined $_ } ($val =~ /$MACRO/og)) {

                    # check first to see if it's bound
                    next unless $macros->{$m};
                    #warn $m;

                    # if it's yourself, explode
                    Carp::croak("Self reference found!") if $m eq $k;

                    # get this to replace deref
                    $m{$m}++;

                    # and get this to figure out if we can deref
                    defined $done{$m} ? $dm{$m}++ : $pm{$m}++;
                }

                # now replace deref
                $pair->[1] = keys %m ? [sort keys %m] : 0;
            }
        }

        # macro values have pending matches
        if (keys %pm) {
            # this is where we would detect a cycle

            # right HERE

            my @q;
            for my $m (keys %pm) {
                Carp::croak("Cycle detected between $k and $m") if $seen{$m};
                push @q, $m;
            }
            #warn join '/', @q;

            # do it again
            unshift @queue, @q, $k;
            #warn join ',', @queue;

            next;
        }
        elsif (keys %dm) {
            # macro values have actionable matches

            #warn "replacing values for \$$k";

            # replace contents and mark done
            $done{$k} = _deref_content(\@vals, \%done);
        }
        else {
            #warn Data::Dumper::Dumper(\@vals);
            # nothing to do, mark done
            $done{$k} = [map { $_->[0] } @vals];
        }

        # remember to remove this guy or we'll loop forever
        delete $pending{$k};

        # replenish the queue with another pending object
        push @queue, (keys %pending)[0] if !@queue and keys %pending;
    }

    \%done;
}


sub process {
    my ($self, $params) = @_;

    # assume this can also be a Hash::MultiValue
    my $sub = Scalar::Util::blessed($params)
        && $params->can('get_all') ? \&_1 : \&_2;
    # XXX do we want to do ->isa instead?

    # begin by seeding macros with generators
    my %macros = %GENERATED;

    my (%maybe, %neither);

    for my $k (keys %$params) {
        # Step 0: get the values into a homogeneous list
        my @v = $sub->($params, $k);

        # Step 1: pull out all the macro declarations
        if (my ($name, $sigil) = ($k =~ $DECLARATION)) {
            # Step 1.0.1: create [content, deref flag] pairs

            # skip over generated macros
            next if $GENERATED{$name};

            # OOH VERY CLEVER
            push @{$macros{$name} ||= []}, (map { [$_, int(!!$sigil)] } @v);
        }
        # Step 1.1: set aside candidate statements
        elsif ($k =~ /^\s*\S+\s+\S+.*?/ or $k =~ /[:\$]/) {
            # valid partial statements will contain space or : or $
            push @{$maybe{$k} ||= []}, @v;
        }
        # Step 1.2: put the rest in a discard pile
        else {
            push @{$neither{$k} ||= []}, @v;
        }
    }

    # cycles should cause a 409 Conflict error, but that isn't our job
    # here.

    # XXX although it may be useful to return an object in $@ that was
    # more informative.

    # Step 2: dereference all the macros (that asked to be)
    try {
        my $x = _massage_macros(\%macros);
        %macros = %$x;
    } catch {
        # move this error up in the stack
        Carp::croak($@);
    };

    # Step 2.1: overwrite any reserved/magic macros
    #$macros{NEW_UUID}     = [[\&_uuid4,    1]];
    #$macros{NEW_UUID_URN} = [[\&_uuid4urn, 1]];
    #$macros{NEW_BNODE}    = [[\&_uuid4bn,  1]];
    # XXX make this extensible?

    # Step 3: apply special control macros to $self
    try {
        for my $k (keys %SPECIALS) {
            next unless $macros{$k};
            $SPECIALS{$k}->($self, $macros{$k});
        }
    } catch {
        # cough any errors up the stack
        Carp::croak($@);
    };

    #require Data::Dumper;
    #warn Data::Dumper::Dumper(\%macros);


    # add/remove statements
    my $patch = RDF::KV::Patch->new;
    my (%pos, %neg);
    for my $k (keys %maybe) {
        # Step 4: dereference macros in statements

        # Step 4.1 dereference macros in statement *templates* first
        # so we can figure out which values need to be dereferenced
        # (since the terminating $ indicator can be substituted in via
        # macro).
        my @k = grep { defined $_ } ($k =~ /$MACRO/og) ?
            _deref_content($k, \%macros) : ($k);

        # we want to check the values for empty strings *before* we
        # dereference them so it's still possible to express the empty
        # string through the use of a macro
        my @v = grep { $_ ne '' } map { $_ =~ s/^\s*(.*?)\s*$/$1/sm; $_ }
            grep { defined $_ } @{$maybe{$k} || []};

        #require Data::Dumper;
        #warn Data::Dumper::Dumper($maybe{$k});

        # very well could loop just once here
        for my $template (@k) {
            #warn "lol $template";

            # nope actually we're parsing the template now
            my @tokens = ($template =~ $PARTIAL_STMT);

            #warn scalar @tokens;

            # ignore if there wasn't a match XXX WARN SOMEHOW?
            next unless @tokens;

            # do not ignore, however, if this screws up
            die 'INTERNAL ERROR: regex does not match map'
                unless @tokens == @MAP;

            # now make a nice hash of the contents
            my %contents;
            map {
                $contents{$MAP[$_]} = $tokens[$_] if defined $tokens[$_]
            } (0..$#MAP);

            # just to recap, %contents can contain, at maximum:
            # * modifier (reverse statement, negate, etc)
            # * term1 (either subject or predicate)
            # * term2 (either predicate or object)
            # * designator (treat input values as URI/blank/literal[type?])
            # * graph URI
            # * macro-dereference instruction

            # pull out the statement modifier first
            $contents{modifier} = {
                map { $_ => 1 } (split //, $contents{modifier} || '') };

            # now deal with designator
            if ($contents{designator}) {
                my ($sigil, $symbol) = ($contents{designator} =~ /^(.)(.*)$/);

                Carp::croak("Reversed statement templates " .
                                "cannot specify literals ($template)")
                      if ($contents{modifier}{'!'} and $sigil =~ /['@^]/);

                if ($sigil eq '^') {
                    # expand datatype URI
                    $symbol = $self->namespaces->uri($symbol) || $symbol;
                }

                $contents{designator} =
                    $symbol eq '' ? [$sigil] : [$sigil, $symbol];
            }
            else {
                # single-tick is the default designator for forward
                # statements, : is for reverse.
                $contents{designator} = [
                    $contents{modifier}{'!'} ? ':' : q/'/ ];
            }

            # now we should expand the rest of the abbreviations
            for my $which (qw(term1 term2 graph)) {
                if (defined $contents{$which}) {
                    my $uri = $self->namespaces->uri($contents{$which})
                        || $contents{$which};
                    # XXX should we do some sort of relative uri
                    # resolution thing?
                    $contents{$which} = $uri;
                }
            }

            # I suppose we can do this now
            if ($contents{deref}) {
                # XXX might want to trim bounding whitespace again
                @v = map { _deref_content($_, \%macros) } @v;
            }

            #require Data::Dumper;
            #warn Data::Dumper::Dumper([\%contents, \@v]);

            # statement reversal behaviour is not entirely symmetric.

            # + is a noop of the default behaviour: assert S P O or O P S.
            # = means remove S P * before asserting S P O. (no reversal)
            # - means either remove S P *, S P O or O P S, but not O P *.

            # No, you know what? Restricting reverse wildcards is
            # going to make it a hell of a problem to do things like
            # completely disconnect one resource from another set of
            # resources. This protocol has to assume the end user is
            # allowed to make these kinds of changes. We'll mop up the
            # permission stuff elsewhere.

            # thinking this oughta do it:
            # { g => { s => { p => [{ o => 1 }, { langordt => { o => 1 }}]}}}

            my $g = $contents{graph} || $self->graph;

            if ($contents{modifier}{'!'}) {
                # reverse statement (O P S)
                my $p = $contents{term1};
                my $o = URI::BNode->new($contents{term2} || $self->subject);

                # don't forget to do this
                $o = $self->callback->($o) if $self->callback;

                # you know what, it makes no sense for a reverse
                # statement to be anything but a URI or a blank node.

                next unless $contents{designator}[0] =~ /[_:]/;

                if ($contents{modifier}{'-'}) {
                    # remove these triples
                    for my $s (@v) {
                        if ($contents{designator}[0] eq '_') {
                            $s = '_:' . $s unless $s =~ /^_:/;
                        }
                        else {
                            $s = URI->new_abs($s, $o);
                            $s = $self->callback->($s) if $self->callback;
                        }

                        $neg{$g}         ||= {};
                        $neg{$g}{$s}     ||= {};
                        $neg{$g}{$s}{$p} ||= [{}, {}];
                        $neg{$g}{$s}{$p}[0]{$o} = 1 if ref $neg{$g}{$s}{$p};

                        $patch->remove_this($s, $p, $o, $g);
                    }
                }
                else {
                    # add these triples
                    for my $s (@v) {
                        next if $s eq '';
                        if ($contents{designator}[0] eq '_') {
                            $s = '_:' . $s unless $s =~ /^_:/;
                        }
                        else {
                            $s = URI->new_abs($s, $o);
                            $s = $self->callback->($s) if $self->callback;
                        }

                        $pos{$g}         ||= {};
                        $pos{$g}{$s}     ||= {};
                        $pos{$g}{$s}{$p} ||= [{}, {}];
                        $pos{$g}{$s}{$p}[0]{$o} = 1 if ref $pos{$g}{$s}{$p};

                        $patch->add_this($s, $p, $o, $g);
                    }
                }
            }
            else {
                # forward statement (S P O)
                my ($s, $p);
                if ($contents{term2}) {
                    ($s, $p) = @contents{qw(term1 term2)};
                }
                else {
                    $s = $self->subject;
                    $p = $contents{term1};
                }

                # (potentially) rewrite the URI
                $s = $self->callback->($s) if $self->callback;

                if ($contents{modifier}{'-'}) {
                    # remove these triples
                    $neg{$g}         ||= {};
                    $neg{$g}{$s}     ||= {};
                    $neg{$g}{$s}{$p} ||= [{}, {}];

                    if (@v and ref $neg{$g}{$s}{$p}) {
                        for my $o (@v) {
                            # empty string is a wildcard on negated
                            # templates
                            if ($o eq '') {
                                $neg{$g}{$s}{$p} = 1;
                                $patch->remove_this($s, $p, $o, $g);
                                last;
                            }

                            # haha holy shit
                            my $d = $contents{designator};
                            if ($d->[0] =~ /[_:]/) {
                                $o = "_:$o" if $d->[0] eq '_' and $o !~ /^_:/;
                                my $uri = $self->namespaces->uri($o) || $o;
                                if ($d->[0] eq ':') {
                                    $uri = URI->new_abs($uri, $s);
                                    $uri = $self->callback->($uri)
                                        if $self->callback;
                                }
                                $neg{$g}{$s}{$p}[0]{$uri} = 1;

                                $o = $uri;
                            }
                            elsif ($d->[0] =~ /[@^]/) {
                                my $x = join '', @$d;
                                my $y = $neg{$g}{$s}{$p}[1]{$x} ||= {};
                                $y->{$o} = 1;
                                $o = [$o, $d->[0] eq '@' ?
                                          $d->[1] : (undef, $d->[1])];
                            }
                            else {
                                my $x = $neg{$g}{$s}{$p}[1]{''} ||= {};
                                $x->{$o} = 1;
                            }

                            $patch->remove_this($s, $p, $o, $g);
                        }
                    }
                }
                else {
                    if ($contents{modifier}{'='}) {
                        # remove triple wildcard
                        $neg{$g}       ||= {};
                        $neg{$g}{$s}   ||= {};
                        $neg{$g}{$s}{$p} = 1;

                        $patch->remove_this($s, $p, undef, $g);
                    }

                    # add triples
                    $pos{$g}         ||= {};
                    $pos{$g}{$s}     ||= {};
                    $pos{$g}{$s}{$p} ||= [{}, {}];

                    for my $o (@v) {
                        my $d = $contents{designator};
                        if ($d->[0] =~ /[_:]/) {
                            next if $o eq '';

                            $o = "_:$o" if $d->[0] eq '_' and $o !~ /^_:/;
                            my $uri = $self->namespaces->uri($o) || $o;
                            if ($d->[0] eq ':') {
                                $uri = URI->new_abs($uri, $s);
                                $uri = $self->callback->($uri)
                                    if $self->callback;
                            }

                            $pos{$g}{$s}{$p}[0]{$uri} = 1;

                            $o = $uri;
                        }
                        elsif ($d->[0] =~ /[@^]/) {
                            my $x = join '', @$d;
                            my $y = $pos{$g}{$s}{$p}[1]{$x} ||= {};
                            $y->{$o} = 1;

                            $o = [$o,
                                  $d->[0] eq '@' ? $d->[1] : (undef, $d->[1])];
                        }
                        else {
                            my $x = $pos{$g}{$s}{$p}[1]{''} ||= {};
                            $x->{$o} = 1;
                        }

                        $patch->add_this($s, $p, $o, $g);
                    }
                }
            }

            # you can tell a blank node from a resource if it starts
            # with _:

            # for negative wildcards: { g => { s => { p => 1 } } }
            # since removing S P * overrides any S P O.

            # an empty @v means there was no value for this key that
            # was more than whitespace/empty string.


            # in this case we probably can't be clever and reuse the
            # values for multiple templates because some may or may
            # not include the indicator.

            # actually we can reuse the values, we just can't parse
            # them until we've parsed the statement templates, because
            # those tell us what to do with the values.

            # which also means we have to parse the statement
            # templates immediately.

            # there is still the issue of the empty string: what does
            # it mean, and in what context?

            # Step 4.2 dereference macros in statement *values* (that
            # asked to be)


            # Step 5: parse statement templates

            # Step 5.1 expand qnames

            # Step 6: generate complete statements
        }
    }

    #return [\%neg, \%pos];

    return $patch;
}

=head1 CAVEATS

B<BYOS> == Bring Your Own Security.

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rdf-kv at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RDF-KV>.  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RDF::KV

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RDF-KV>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RDF-KV>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RDF-KV>

=item * Search CPAN

L<http://search.cpan.org/dist/RDF-KV/>

=back

=head1 SEE ALSO

=over 4

=item L<RDF::KV::Patch>

=item L<URI::BNode>

=item L<RDF::Trine>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

__PACKAGE__->meta->make_immutable;

1; # End of RDF::KV
