package Perl::Metrics::Simple::Analysis::File;
use strict;
use warnings;

use Carp qw(cluck confess);
use Data::Dumper;
use English qw(-no_match_vars);
use Perl::Metrics::Simple::Analysis;
use PPI 1.113;
use PPI::Document;
use Readonly;

our $VERSION = 'v1.0.3';

Readonly::Scalar my $ALL_NEWLINES_REGEX =>
    qr/ ( \Q$INPUT_RECORD_SEPARATOR\E ) /sxm;
Readonly::Array our @DEFAULT_LOGIC_OPERATORS => qw(
    !
    !~
    &&
    &&=
    //
    <
    <<=
    <=>
    ==
    =~
    >
    >>=
    ?
    and
    cmp
    eq
    gt
    lt
    ne
    not
    or
    xor
    ||
    ||=
    ~~
    );

Readonly::Array our @DEFAULT_LOGIC_KEYWORDS => qw(
    else
    elsif
    for
    foreach 
    goto
    grep
    if
    last
    map
    next
    unless
    until
    while
    );

Readonly::Array our @DEFAULT_METHOD_MODIFIERS => qw(
    before
    after
    around
    );

Readonly::Scalar my $LAST_CHARACTER => -1;

Readonly::Scalar my $ONE_SPACE => q{ };

Readonly::Scalar my $PPI_CHILD_INDEX_AFTER => 1;
Readonly::Scalar my $PPI_CHILD_INDEX_METHOD_NAME => 2;
Readonly::Scalar my $PPI_CHILD_INDEX_OPERATOR => 3;
Readonly::Scalar my $PPI_CHILD_INDEX_SUBROUTINE => 4;
Readonly::Scalar my $PPI_CHILD_INDEX_BLOCK => 5;

our (@LOGIC_KEYWORDS, @LOGIC_OPERATORS, @METHOD_MODIFIERS); # For user-supplied values;

our (%LOGIC_KEYWORDS, %LOGIC_OPERATORS, %METHOD_MODIFIERS); # Populated in _init()

# Private instance variables:
my %_PATH       = ();
my %_MAIN_STATS = ();
my %_SUBS       = ();
my %_PACKAGES   = ();
my %_LINES      = ();
my %_LOGIC_KEYWORDS = ();
my %_LOGIC_OPERATORS = ();
my %_METHOD_MODIFIERS = ();

sub new {
    my ( $class, %parameters ) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init(%parameters);
    return $self;
}

sub _init {
    my ( $self, %parameters ) = @_;
    $_PATH{$self} = $parameters{'path'};

    my $path = $self->path();

    my $document;
    if (ref $path) {
        if (ref $path eq 'SCALAR') {
            $document = PPI::Document->new($path);
        } else {
            $document = $path;
        }
    } else {
        if ( !-r $path ) {
            Carp::confess "Path '$path' is missing or not readable!";
        }
        $document = _create_ppi_document($path);
    }

    my @logic_keywords = @LOGIC_KEYWORDS  ? @LOGIC_KEYWORDS : @DEFAULT_LOGIC_KEYWORDS;
    %LOGIC_KEYWORDS = hashify(@logic_keywords);
    $_LOGIC_OPERATORS{$self} = \%LOGIC_KEYWORDS;

    my @logic_operators = @LOGIC_OPERATORS ? @LOGIC_OPERATORS : @DEFAULT_LOGIC_OPERATORS;
    %LOGIC_OPERATORS = hashify(@logic_operators);
    $_LOGIC_OPERATORS{$self} = \%LOGIC_OPERATORS;

    my @method_modifiers = @METHOD_MODIFIERS ? @METHOD_MODIFIERS : @DEFAULT_METHOD_MODIFIERS;
    %METHOD_MODIFIERS = hashify(@method_modifiers);
    $_METHOD_MODIFIERS{$self} = \%METHOD_MODIFIERS;

    $document = $self->_make_pruned_document($document);

    if ( !defined $document ) {
        cluck "Could not make a PPI document from '$path'";
        return;
    }

    my $packages = _get_packages($document);

    my @sub_analysis = ();
    my $sub_elements = $document->find('PPI::Statement::Sub');
    @sub_analysis = @{ $self->_iterate_over_subs($sub_elements) };

    $_MAIN_STATS{$self}
        = $self->analyze_main( $document, $sub_elements, \@sub_analysis );
    $_SUBS{$self}     = \@sub_analysis;
    $_PACKAGES{$self} = $packages;
    $_LINES{$self}    = $self->get_node_length($document);

    return $self;
}

sub _create_ppi_document {
    my $path = shift;
    my $document;
    if ( -s $path ) {
        $document = PPI::Document->new($path);
    }
    else {

        # The file is empty. Create a PPI document with a single whitespace
        # chararacter. This makes sure that the PPI tokens() method
        # returns something, so we avoid a warning from
        # PPI::Document::index_locations() which expects tokens() to return
        # something other than undef.
        my $one_whitespace_character = q{ };
        $document = PPI::Document->new( \$one_whitespace_character );
    }
    return $document;
}

sub _make_pruned_document {
    my ($self, $document) = @_;
    $document = _prune_non_code_lines($document);
    $document = $self->_rewrite_moose_method_modifiers($document);
    $document->index_locations();
    $document->readonly(1);
    return $document;
}

sub all_counts {
    my $self       = shift;
    my $stats_hash = {
        path       => $self->path,
        lines      => $self->lines,
        main_stats => $self->main_stats,
        subs       => $self->subs,
        packages   => $self->packages,
    };
    return $stats_hash;
}

sub analyze_main {
    my $self         = shift;
    my $document     = shift;
    my $sub_elements = shift;
    my $sub_analysis = shift;

    if ( !$document->isa('PPI::Document') ) {
        Carp::confess('Did not supply a PPI::Document');
    }

    my $lines = $self->get_node_length($document);
    foreach my $sub ( @{$sub_analysis} ) {
        $lines -= $sub->{lines};
    }
    my $document_without_subs = $document->clone;
    $document_without_subs->prune('PPI::Statement::Sub');
    my $complexity = $self->measure_complexity($document_without_subs);
    my $results    = {
        name              => '{code not in named subroutines}',
        lines             => $lines,
        mccabe_complexity => $complexity,
        path              => $self->path,
    };
    return $results;
}

sub get_node_length {
    my ( $self, $node ) = @_;
    my $eval_result = eval { $node = _prune_non_code_lines($node); };
    return 0 if not $eval_result;
    return 0 if ( !defined $node );
    my $string = $node->content;
    return 0 if ( !length $string );

    # Replace whitespace-newline with newline
    $string =~ s/ \s+ \Q$INPUT_RECORD_SEPARATOR\E /$INPUT_RECORD_SEPARATOR/smxg;
    $string =~ s/\Q$INPUT_RECORD_SEPARATOR\E /$INPUT_RECORD_SEPARATOR/smxg;
    $string =~ s/ \A \s+ //msx;    # Remove leading whitespace
    my @newlines = ( $string =~ /$ALL_NEWLINES_REGEX/smxg );
    my $line_count = scalar @newlines;

 # if the string is not empty and the last character is not a newline then add 1
    if ( length $string ) {
        my $last_char = substr $string, $LAST_CHARACTER, 1;
        if ( $last_char ne "$INPUT_RECORD_SEPARATOR" ) {
            $line_count++;
        }
    }

    return $line_count;
}

sub path {
    my ($self) = @_;
    return $_PATH{$self};
}

sub main_stats {
    my ($self) = @_;
    return $_MAIN_STATS{$self};
}

sub subs {
    my ($self) = @_;
    return $_SUBS{$self};
}

sub packages {
    my ($self) = @_;
    return $_PACKAGES{$self};
}

sub lines {
    my ($self) = @_;
    return $_LINES{$self};
}

sub logic_keywords {
    my ($self) = @_;
    return wantarray ? @{$_LOGIC_KEYWORDS{$self}} : $_LOGIC_KEYWORDS{$self};
}

sub logic_operators {
    my ($self) = @_;
    return wantarray ? @{$_LOGIC_OPERATORS{$self}} : $_LOGIC_OPERATORS{$self};
}

sub method_modifiers {
    my ($self) = @_;
    return wantarray ? @{$_METHOD_MODIFIERS{$self}} : $_METHOD_MODIFIERS{$self};
}

sub measure_complexity {
    my $self = shift;
    my $elem = shift;

    my $complexity_count = 0;
    if ( $self->get_node_length($elem) == 0 ) {
        return $complexity_count;
    }

    if ($elem) {
        $complexity_count++;
    }

    # Count up all the logic keywords, weed out hash keys
    my $keywords_ref = $elem->find('PPI::Token::Word') || [];
    my @filtered = grep { !is_hash_key($_) } @{$keywords_ref};
    $complexity_count += grep { exists $LOGIC_KEYWORDS{$_} } @filtered;

    # Count up all the logic operators
    my $operators_ref = $elem->find('PPI::Token::Operator');
    if ($operators_ref) {
        $complexity_count
            += grep { exists $LOGIC_OPERATORS{$_} } @{$operators_ref};
    }
    return $complexity_count;
}

sub _get_packages {
    my $document = shift;

    my @unique_packages = ();
    my $found_packages  = $document->find('PPI::Statement::Package');

    return \@unique_packages
        if (
        !Perl::Metrics::Simple::Analysis::is_ref( $found_packages, 'ARRAY' ) );

    my %seen_packages = ();

    foreach my $package ( @{$found_packages} ) {
        $seen_packages{ $package->namespace() }++;
    }

    @unique_packages = sort keys %seen_packages;

    return \@unique_packages;
}

sub _iterate_over_subs {
    my $self       = shift;
    my $found_subs = shift;

    return []
        if ( !Perl::Metrics::Simple::Analysis::is_ref( $found_subs, 'ARRAY' ) );

    my @subs = ();

    foreach my $sub ( @{$found_subs} ) {
        my $sub_length = $self->get_node_length($sub);
        push @subs,
            {
            path              => $self->path,
            name              => $sub->name,
            lines             => $sub_length,
            mccabe_complexity => $self->measure_complexity($sub),
            };
    }
    return \@subs;
}

#-------------------------------------------------------------------------
# Copied from
# http://search.cpan.org/src/THALJEF/Perl-Critic-0.19/lib/Perl/Critic/Utils.pm
sub hashify {
    my @hash_keys = @_;
    return map { $_ => 1 } @hash_keys;
}

#-------------------------------------------------------------------------
# Copied and somehwat simplified from
# http://search.cpan.org/src/THALJEF/Perl-Critic-0.19/lib/Perl/Critic/Utils.pm
sub is_hash_key {
    my $ppi_elem = shift;

    my $is_hash_key = eval {
        my $parent      = $ppi_elem->parent();
        my $grandparent = $parent->parent();
        if ( $grandparent->isa('PPI::Structure::Subscript') ) {
            return 1;
        }
        my $sib = $ppi_elem->snext_sibling();
        if ( $sib->isa('PPI::Token::Operator') && $sib eq '=>' ) {
            return 1;
        }
        return;
    };

    return $is_hash_key;
}

sub _prune_non_code_lines {
    my $document = shift;
    if ( !defined $document ) {
        Carp::confess('Did not supply a document!');
    }
    $document->prune('PPI::Token::Comment');
    $document->prune('PPI::Token::Pod');
    $document->prune('PPI::Token::End');

    return $document;
}

sub _rewrite_moose_method_modifiers {
    my ($self, $document) = @_;
    if ( !defined $document ) {
        Carp::confess('Did not supply a document!');
    }

    my $re = q{^(} . join(q{|}, map {quotemeta} keys %{$_METHOD_MODIFIERS{$self}}) . q{)$};
    my @method_modifiers =
        # 5th child: { ... }
        grep { $_->[$PPI_CHILD_INDEX_BLOCK]->isa('PPI::Structure::Block') }

        # 4th child: sub
        grep {
               $_->[$PPI_CHILD_INDEX_SUBROUTINE]->isa('PPI::Token::Word')
            && $_->[$PPI_CHILD_INDEX_SUBROUTINE]->content eq 'sub'
        }

        # 3rd child: =>
        grep {
               $_->[$PPI_CHILD_INDEX_OPERATOR]->isa('PPI::Token::Operator')
            && $_->[$PPI_CHILD_INDEX_OPERATOR]->content eq '=>'
        }

        # 2nd child: 'method_name'
        grep { $_->[$PPI_CHILD_INDEX_METHOD_NAME]->isa('PPI::Token::Quote')
            || $_->[$PPI_CHILD_INDEX_METHOD_NAME]->isa('PPI::Token::Word') }

        # 1st child: after
        grep {
               $_->[$PPI_CHILD_INDEX_AFTER]->isa('PPI::Token::Word')
            && $_->[$PPI_CHILD_INDEX_AFTER]->content =~ /$re/smx
        }

        # create an arrayref [item, child0, child1, child2]
        # for easier, cheaper access
        map { [ $_, $_->schildren ] }

        # don't want subclasses of PPI::Statement here
        grep { $_->class eq 'PPI::Statement' } $document->schildren;

    for (@method_modifiers) {
        my ($old_stmt, @children) = @{$_};
        my $name = '_' . $children[0]->literal . '_';
        if ( $children[1]->can('literal') ) {
            $name .= $children[1]->literal;
        }
        else {
            my $string = $children[1]->string;
            $name .= $string;
        }
        my $new_stmt = PPI::Statement::Sub->new();
        $new_stmt->add_element(PPI::Token::Word->new('sub'));
        $new_stmt->add_element(PPI::Token::Whitespace->new($ONE_SPACE));
        $new_stmt->add_element(PPI::Token::Word->new($name));
        $new_stmt->add_element(PPI::Token::Whitespace->new($ONE_SPACE));
        $new_stmt->add_element($children[$PPI_CHILD_INDEX_SUBROUTINE]->clone());

        $old_stmt->insert_after($new_stmt);
        $old_stmt->delete();
    }

    return $document;
}

1;

__END__

=head1 NAME

Perl::Metrics::Simple::Analysis::File - Methods analyzing a single file.

=head1 SYNOPSIS

  use Perl::Metrics::Simple::Analysis::File;
  my $object = Perl::Metrics::Simple::Analysis::File->new(file => 'path/to/file');

=head1 VERSION

This is VERSION 0.1

=head1 DESCRIPTION

A B<Perl::Metrics::Simple::Analysis::File> object is created by
B<Perl::Metrics::Simple> for each file analyzed. These objects are aggregated into
a B<Perl::Metrics::Simple::Analysis> object by B<Perl::Metrics::Simple>.

In general you will not use this class directly, instead you will use
B<Perl::Metrics::Simple>, but there's no harm in exposing the various methods
this class provides.

=head1 CLASS METHODS

=head2 new

Takes named parameters, current only the I<path> parameter is recognized:

  my $file_results = BPerl::Metrics::Simple::Analysis::File->new( path => $path );

Returns a new B<Perl::Metrics::Simple::Analysis::File> object which has been
populated with the results of analyzing the file at I<path>.

Throws an exception if the I<path> is missing or unreadable.


=head1 OBJECT METHODS

Call on an object.

=head2 all_counts

Convenience method.
Takes no arguments and returns a hashref of all counts:
    {
        path       => $self->path,
        lines      => $self->lines,
        main_stats => $self->main_stats,
        subs       => $self->subs,
        packages   => $self->packages,
    }

=head2 analyze_main

Takes a B<PPI> document and an arrayref of B<PPI::Statement::Sub> objects
and returns a hashref with information about the 'main' (non-subroutine)
portions of the document:

  {
    lines             => $lines,      # Line count outside subs. Skips comments and pod.
    mccabe_complexity => $complexity, # Cyclomatic complexity of all non-sub areas
    path              => '/path/to/file',
    name              => '{code not in named subroutines}',  # always the same name
  };

=head2 get_node_length

Takes a B<PPI> node and returns a count of the newlines it
contains. B<PPI> normalizes line endings to newlines so
CR/LF, CR and LF all come out the same. The line counts reported by
the various methods in this class all B<exclude> blank lines,
comment lines and pod
(the B<PPI> document is pruned before counting.)

=head2 lines

Total non-blank, non-comment, non-pod lines.

=head2 main_stats

Returns the hashref generated by I<analyze_main> without re-analyzing document.

=head2 logic_keywords

Returns an array (in array context) or ref-to-ARRAY of the keywords
used in calculating complexity. See I<Logic Keywords> section below.

=head2 logic_operators

Returns an array (in array context) or ref-to-ARRAY of the operators
used in calculating complexity. See I<Logic Operators> section below.

=head2 method_modifiers

Returns an array (in array context) or ref-to-ARRAY of the method modifiers
considered to return methods during calculating complexity. See I<Method modifiers> section below.

=head2 measure_complexity

Takes a B<PPI> element and measures an approximation of the
McCabe Complexity (aka Cyclomatic Complexity) of the code.

McCabe Complexity is basically a count of how many paths there are
through the code.

We use a simplified method for counting this, which ignores things like
the possibility that a 'use' statement could throw an exception.

The actual measurement we use for a chunk of code is 1 plus
1 each logic keyword or operator:

=head3 Logic operators:

The default list is:

I<@Perl::Metrics::Simple::Analysis::File::DEFAULT_LOGIC_OPERATORS>

    !
    !~
    &&
    &&=
    //
    <
    <<=
    <=>
    ==
    =~
    >
    >>=
    ?
    and
    cmp
    eq
    gt
    lt
    ne
    not
    or
    xor
    ||
    ||=
    ~~

You can supply your own list by setting:
I<@Perl::Metrics::Simple::Analysis::File::LOGIC_OPERATORS> before creating a
new object.

=head3 Logic keywords:

I<@Perl::Metrics::Simple::Analysis::File::DEFAULT_LOGIC_KEYWORDS>

    else
    elsif
    for
    foreach 
    goto
    grep
    if
    last
    map
    next
    unless
    until
    while

You can supply your own list by setting:
I<@Perl::Metrics::Simple::Analysis::File::LOGIC_KEYWORDS> before creating a
new object.

=head3 Method modifiers:

I<@Perl::Metrics::Simple::Analysis::File::DEFAULT_METHOD_MODIFIERS>

    before
    after
    around

You can supply your own list by setting:
I<@Perl::Metrics::Simple::Analysis::File::METHOD_MODIFIERS> before creating a new object.

=head3 Examples of Complexity

Here are a couple of examples of how we count complexity:

Example of complexity count of 1:

   use Foo;
   print "Hello world.\n";
   exit;

Example of complexity count of 2:

   if ( $a ) {         # The "if" adds 1.
       # do something
   }

Example of complexity count of 6:

    sub foo {                              # 1: for non-empty code
       if ( @list ) {                      # 1: "if"
           foreach my $x ( @list ) {       # 1: "foreach"
               if ( ! $x ) {               # 2: 1 for "if" and 1 for "!"
                   do_something($x);
               }
               else {                      # 1 for "else"
                   do_something_else($x);
               }
           }
       }
       return;
    }

=head2 packages

Arrayref of unique packages found in the file.

=head2 path

Either the path to the file, or a scalar ref if that was supplied
instead of a path.

=head2 subs

Count of subroutines found.

=head1 STATIC PACKAGE SUBROUTINES

Utility subs used internally, but no harm in exposing them for now.

=head2 hashify

 %hash = Perl::Metrics::Simple::Analysis::File::hashify(@list);

Takes an array and returns a hash using the array values
as the keys and with the values all set to 1.

=head2 is_hash_key

 $boolean = Perl::Metrics::Simple::Analysis::File::is_hash_key($ppi_element);

Takes a B<PPI::Element> and returns true if the element is a hash key,
for example C<foo> and C<bar> are hash keys in the following:

  { foo => 123, bar => $a }
 
Copied and somewhat simplified from
http://search.cpan.org/src/THALJEF/Perl-Critic-0.19/lib/Perl/Critic/Utils.pm
See L<Perl::Critic::Utils|Perl::Critic::Utils>.

=head1 BUGS AND LIMITATIONS

None reported yet ;-)

=head1 DEPENDENCIES

=over 4

=item L<Readonly|Readonly>

=item L<Perl::Metrics::Simple::Analysis|Perl::Metrics::Simple::Analysis>

=back

=head1 SUPPORT

Via CPAN:

=head2 Disussion Forum

http://www.cpanforum.com/dist/Perl-Metrics-Simple

=head2 Bug Reports

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Metrics-Simple

=head1 AUTHOR

    Matisse Enzer
    CPAN ID: MATISSE
    Eigenstate Consulting, LLC
    matisse@eigenstate.net
    http://www.eigenstate.net/

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2021 by Eigenstate Consulting, LLC.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=cut

