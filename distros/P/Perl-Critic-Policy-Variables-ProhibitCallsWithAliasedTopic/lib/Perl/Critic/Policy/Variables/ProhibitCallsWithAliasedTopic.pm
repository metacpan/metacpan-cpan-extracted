package Perl::Critic::Policy::Variables::ProhibitCallsWithAliasedTopic 0.001;

# ABSTRACT: Do not call a sub or method while $_ is an alias to the caller's data.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use List::Util qw{ any first };
use Readonly;
use Scalar::Util qw{ refaddr };

use Perl::Critic::Distribution ();
use Perl::Critic::Utils        qw{ :severities is_function_call is_method_call is_perl_builtin first_arg };
use parent                     qw{Perl::Critic::Policy};


Readonly::Scalar my $DESC_BLOCK   => q{A call in a list function block, while $_ is the caller's element};
Readonly::Scalar my $EXPL_BLOCK   => q{Say "local ($_) = $_;" before the first call, so that a callee that writes $_ writes a copy};
Readonly::Scalar my $DESC_POSTFIX => q{A call in a statement with a postfix for, while $_ is the caller's element};
Readonly::Scalar my $EXPL_POSTFIX => q{Write a block "for my $x (...) { ... }" instead, so that $_ is not the element};

Readonly::Array my @ALIASING_FUNCS => (
    qw{ map grep },
    map { ( $_, "List::Util::$_" ) } qw{ first any all none notall },
    map { ( $_, "List::MoreUtils::$_", "List::SomeUtils::$_" ) } qw{
      any all none notall true false firstidx first_index lastidx last_index
      firstval first_value lastval last_value firstres first_result lastres
      last_result onlyidx only_index onlyval only_value onlyres only_result
      indexes after after_incl before before_incl part insert_after
    },
    map { ( $_, "List::UtilsBy::$_" ) } qw{ max_by min_by },
);

Readonly::Hash my %LOOP => map { $_ => 1 } qw{ for foreach };

# Change it when what the collector returns changes shape.
Readonly::Scalar my $DATA_FORMAT => 1;


sub supported_parameters {
    my %seen;
    return (
        {
            name           => 'allow',
            description    => q{Subs and methods that do not write $_},
            default_string => q{can DOES isa VERSION},
            behavior       => 'string list',
        },
        {
            name           => 'list_funcs',
            description    => q{The functions whose block sees each element as $_},
            default_string => join( q{ }, grep { !$seen{$_}++ } @ALIASING_FUNCS ),
            behavior       => 'string list',
        },
        {
            name           => 'add_list_funcs',
            description    => q{More functions whose block sees each element as $_},
            default_string => q{},
            behavior       => 'string list',
        },
    );
}

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw{ bugs } }
sub applies_to       { return 'PPI::Token::Word' }


sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    $self->{_all_list_funcs} = { map { $_ => 1 } keys %{ $self->{_list_funcs} }, keys %{ $self->{_add_list_funcs} } };

    Perl::Critic::Distribution->register(
        name    => __PACKAGE__,
        version => join( q{/}, $DATA_FORMAT, Perl::Critic::Distribution->stamp(__FILE__) // q{} ),
        collect => sub {
            my ($ppi) = @_;
            return { subs => [ sub_names_in($ppi) ] };
        },
    );
    return $self->SUPER::initialize_if_enabled($config);
}


sub violates {
    my ( $self, $elem, $doc ) = @_;

    if ( my $statement = _postfix_statement($elem) ) {
        my $call = $self->_first_call( {}, grep { _is_before( $_, $elem ) } $statement->schildren ) or return;
        return $self->violation( $DESC_POSTFIX, $EXPL_POSTFIX, $call );
    }

    my @region = $self->_list_region($elem)                             or return;
    my $call   = $self->_first_call( $self->known_subs($doc), @region ) or return;
    return $self->violation( $DESC_BLOCK, $EXPL_BLOCK, $call );
}

# The statement of $elem, when $elem is the for or foreach of a postfix for.
sub _postfix_statement {
    my ($elem) = @_;

    return if !$LOOP{ $elem->content };
    my $statement = $elem->parent;
    return if !$statement || !$statement->isa('PPI::Statement') || $statement->isa('PPI::Statement::Compound');
    return if $statement->schild(0) == $elem;
    return $statement;
}

sub _is_before {
    my ( $elem, $mark ) = @_;
    my ( $line,  $col )  = @{ $elem->location }[ 0, 1 ];
    my ( $mline, $mcol ) = @{ $mark->location }[ 0, 1 ];
    return $line < $mline || ( $line == $mline && $col < $mcol );
}

# What runs with $_ aliased when $elem is a list function: the statements of
# its block up to the first local $_, or the expression of map EXPR.
sub _list_region {
    my ( $self, $elem ) = @_;

    return if !$self->{_all_list_funcs}{ $elem->content } || !is_function_call($elem);
    my $arg = first_arg($elem) or return;

    if ( !$arg->isa('PPI::Structure::Block') ) {
        my @expr;
        for ( my $part = $arg; $part && !( $part->isa('PPI::Token::Operator') && $part->content eq q{,} ); $part = $part->snext_sibling ) {
            push @expr, $part;
        }
        return @expr;
    }

    # The local statement is in the region, since its right side runs before
    # $_ is localized.
    my @region;
    foreach my $statement ( $arg->schildren ) {
        push @region, $statement;
        last if _localizes_topic($statement);
    }

    return @region;
}

sub _localizes_topic {
    my ($statement) = @_;
    return $statement->isa('PPI::Statement::Variable') && $statement->type eq 'local' && any { $_ eq q{$_} } $statement->variables;
}

# The first call in @queue, or inside it, that is not in a part where $_
# belongs to another construct.
sub _first_call {
    my ( $self, $known, @queue ) = @_;

    while ( defined( my $elem = shift @queue ) ) {
        next         if _is_own_block($elem);
        return $elem if $self->_is_call( $elem, $known );
        next         if !$elem->isa('PPI::Node');
        unshift @queue, _own_children($elem);
    }
    return;
}

# The children of $node in which $_ is still the alias that was set outside it.
sub _own_children {
    my ($node) = @_;

    return if $node->isa('PPI::Statement::Sub');

    my @children = $node->schildren;
    if ( $node->isa('PPI::Statement::Compound') ) {
        my $loop = $children[0];
        my $var  = $children[1];
        if ( $loop && $LOOP{ $loop->content } && $var && ( $var->isa('PPI::Structure::List') || $var->content eq q{$_} ) ) {
            return grep { !$_->isa('PPI::Structure::Block') } @children;
        }
        return @children;
    }
    if ( $node->isa('PPI::Statement') ) {
        my $postfix = first { $_->isa('PPI::Token::Word') && $LOOP{ $_->content } && $_ != $children[0] } @children;
        if ($postfix) {
            return grep { !_is_before( $_, $postfix ) } @children;
        }
    }
    return @children;
}

# Whether $elem is a block where $_ is not the alias from outside: that of an
# anonymous sub, which runs when it is called, or of a list function.
sub _is_own_block {
    my ($elem) = @_;

    return if !$elem->isa('PPI::Structure::Block');
    my $before = $elem->sprevious_sibling;
    while ( $before && ( $before->isa('PPI::Token::Prototype') || $before->isa('PPI::Token::Attribute') || $before->isa('PPI::Structure::List') ) ) {
        $before = $before->sprevious_sibling;
    }
    return   if !$before || !$before->isa('PPI::Token::Word');
    return 1 if $before->content eq 'sub';
    return   if !is_function_call($before);
    my $arg = first_arg($before);
    return $arg && $arg == $elem;
}

# Whether $elem calls a sub or method that is not a builtin, not allowed, and,
# for a sub, not in %$known.
sub _is_call {
    my ( $self, $elem, $known ) = @_;

    if ( $elem->isa('PPI::Token::Word') ) {
        my $name = $elem->content;
        return   if $self->{_allow}{$name};
        return 1 if is_method_call($elem);
        return   if !is_function_call($elem) || $self->{_all_list_funcs}{$name};
        ( my $core = $name ) =~ s/\ACORE::(?:GLOBAL::)?//xms;
        return if is_perl_builtin($core);
        return !$known->{ bare_name($name) };
    }
    if ( $elem->isa('PPI::Token::Symbol') && $elem->raw_type eq q{&} ) {
        my $name = substr $elem->content, 1;
        return !$self->{_allow}{$name} && !$known->{ bare_name($name) };
    }
    return 1 if $elem->isa('PPI::Token::Cast') && $elem->content eq q{&};
    if ( $elem->isa('PPI::Token::Operator') && $elem->content eq q{->} ) {
        my $next = $elem->snext_sibling;
        return $next && ( $next->isa('PPI::Structure::List') || $next->isa('PPI::Token::Symbol') );
    }
    return;
}


sub known_subs {
    my ( $self, $doc ) = @_;

    # The document is held, not just its address, so the address cannot be
    # handed to the next document while this still answers for it.
    my $last = $self->{_known};
    return $last->{subs} if $last && refaddr( $last->{doc} ) == refaddr($doc);

    my %subs = map { $_ => 1 } sub_names_in($doc);

    my $filename = $doc->filename;
    if ( my $dist = defined $filename && Perl::Critic::Distribution->for_file($filename) ) {
        foreach my $file ( values %{ $dist->collected(__PACKAGE__) } ) {
            $subs{$_} = 1 for @{ $file->{subs} };
        }
    }

    $self->{_known} = { doc => $doc, subs => \%subs };
    return \%subs;
}


sub sub_names_in {
    my ($ppi) = @_;
    return map { bare_name( $_->name ) } grep { defined $_->name } @{ $ppi->find('PPI::Statement::Sub') || [] };
}


sub bare_name {
    my ($name) = @_;
    my $at     = rindex $name, '::';
    return $at < 0 ? $name : substr $name, $at + 2;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitCallsWithAliasedTopic - Do not call a sub or method while $_ is an alias to the caller's data.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::Variables::ProhibitCallsWithAliasedTopic

C<map>, C<grep>, C<first> and the other list functions set C<$_> to each
element of their list in turn, and so does a postfix C<for>.  C<$_> is then
not a copy.  It is an alias, so an assignment to C<$_> changes the element.
C<$_> is also one global variable.  So a sub that the block calls, and that
writes C<$_> without a C<local $_> of its own, writes the caller's element:

    sub first_line {
        my ($file) = @_;
        open my $fh, '<', $file or die "$file: $!";
        while (<$fh>) { last }     # assigns each line to $_
        return $_;
    }

    my @heads = map { first_line($_) } @files;    # reported
    # @files now holds undef, or the first line of each file

The writer is seldom in sight.  It is a C<while (<$fh>)>, or a bare C<chomp;>
or C<s///>, in a helper sub, often in another module.  Nothing in the block
looks wrong.

In a list function block, say C<local ($_) = $_;> before the first call.  The
block then has a C<$_> of its own, with the same value, and a callee that
writes C<$_> writes that copy:

    my @heads = map { local ($_) = $_; first_line($_) } @files;    # OK!

A postfix C<for> has no block to put a C<local> in, and it cannot name its
variable.  Write it as a block C<for> with a lexical variable, which does not
make C<$_> an alias at all:

    $_->load for @documents;                  # reported
    for my $doc (@documents) { $doc->load }   # OK!

=head2 PROHIBITED

Each of these calls, in the block of a list function before any
C<local $_>, or before the C<for> of a statement with a postfix C<for>:

    f($_)                     # a sub
    Some::Where::f($_)        # a sub by its full name
    $_->is_ok                 # a method
    Some::Class->new($_)      # a class method
    $o->$name                 # a method by its name in a variable
    $code->($_)               # a code reference
    &$code  &f                # with an ampersand
    PI                        # a constant is a sub too

A copy does not help: the callee still writes C<$_>, which is still the
element.

    my @r = map { my $y = $_; f($y) } @x;                 # reported

C<map EXPR, LIST> and C<grep EXPR, LIST> alias C<$_> as the block forms do:

    my @r = map f($_), @x;                                # reported

=head2 ALLOWED

    my @r = map { lc } @x;                       # a builtin is not a call
    my @r = map { local ($_) = $_; f() } @x;     # the local comes first
    my @r = map { my $y = $_; local $_; f($y) } @x;
    sub f { ... } my @r = map { f($_) } @x;      # see below
    my @r = map { $_ } f(@x);                    # the list is made first
    my @r = map { sub { f() } } @x;              # not called here
    my @r = sort { f($a) <=> f($b) } @x;         # sort does not set $_
    print for @x;                                # no call
    for my $y (@x) { f($y) }                     # no alias

In a list function block, a call of a sub that is defined in the same file, or
in another file of the same distribution, is left alone.
L<Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctionsStricter>
reads the body of that sub, and reports the block if the sub changes C<$_>.
So the two policies can be enabled together, and neither reports what the
other does.  The name is matched without its package, so a sub named C<trim>
anywhere in the distribution covers every call of C<trim>.  A distribution is
what L<Perl::Critic::Distribution> finds above the file; a snippet with no file
has only its own subs.  A method call is never left alone, because the method
that runs can be another sub of the same name.  A postfix C<for> has no such
policy, so a call of any sub counts there.

=head2 WHICH CONSTRUCTS

A list function block is the block of C<map>, C<grep>, and of each list
function that makes C<$_> an alias to its elements, by its full name or with
no package.  These were each checked on perl 5.44, with a callee that assigns
to C<$_>:

    List::Util       first any all none notall
    List::MoreUtils  any all none notall true false firstidx first_index
    List::SomeUtils  lastidx last_index firstval first_value lastval
                     last_value firstres first_result lastres last_result
                     onlyidx only_index onlyval only_value onlyres
                     only_result indexes after after_incl before
                     before_incl part insert_after
    List::UtilsBy    max_by min_by

These do not alias C<$_>, and are not list functions here: C<sort> and
C<reduce>, which set C<$a> and C<$b>; C<apply> of List::MoreUtils, and
C<sort_by>, C<uniq_by> and the other functions of List::UtilsBy, which give
the block a copy.

Inside the block, C<$_> belongs to another construct in three places, and a
call there is not this block's: the body of a C<foreach> with no loop variable,
which saves C<$_> and puts it back; the block of a list function, or the part
of a statement before a postfix C<for>, which are reported on their own; and
an anonymous sub, which runs when it is called.

A block C<foreach> with no loop variable makes C<$_> an alias as well, but it
can name one.  L<Perl::Critic::Policy::Variables::ProhibitTopicIterator>, in
Perl-Critic-Grape, reports each of them, and this policy does not.

A C<local $_> covers the calls in the statements after it, at the top level of
the block.  It does not cover a call in the C<local> statement itself:
C<local ($_) = f($_)> calls C<f> before C<$_> is localized.  It can be
C<local $_;>, C<local $_ = $_;> or C<local ($_) = $_;>.  Of those, only the
last passes both
L<Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctions>,
which takes C<local $_ = $_> for a change to C<$_>, and
L<Perl::Critic::Policy::Variables::RequireInitializationForLocalVars>, which
reports C<local $_;>.  After C<local ($_) = $_;> the block reads the copy, so
a block that wants the value from before the call copies it into a lexical
first.

=head2 CAVEATS

A call that perl makes for the code, and that the code does not spell, is not
seen: an overloaded operator, a tied variable, a C<DESTROY>, C<sort SUBNAME>,
C<require> and C<do FILE>.

Some lists are not the caller's data, and the policy reports a call there all
the same.  C<keys> returns copies, so a write to C<$_> in
C<for (keys %h)> changes nothing that lasts.  A write to an element of a
literal list, as in C<for (1, 2)>, dies with "Modification of a read-only value
attempted", so it does not pass silently.  C<values> does return aliases.

=head1 CONFIGURATION

C<allow> names subs and methods that are known not to write C<$_>.  A sub is
matched as it is written in the call, so C<Some::g> does not allow C<g>, and a
method by its name alone.  The default is C<can DOES isa VERSION>, the methods
of C<UNIVERSAL>, which perl provides.  A list replaces the default, so name
them too to keep them:

    [Variables::ProhibitCallsWithAliasedTopic]
    allow = can DOES isa VERSION to_string Some::Util::is_blank id name

C<list_funcs> replaces the list functions above, and C<add_list_funcs> adds to
them:

    [Variables::ProhibitCallsWithAliasedTopic]
    add_list_funcs = My::Util::each_item each_item

=head2 METHODS

=head3 supported_parameters

=head3 default_severity

=head3 default_themes

=head3 applies_to

=head3 initialize_if_enabled

Joins the list functions of the two parameters, and registers with
L<Perl::Critic::Distribution> what this policy needs from each file of a
distribution: the names of its subs, without their package.

=head3 violates

=head3 known_subs

The names, without their package, of the subs of a document and of the rest
of its distribution.  Worked out once for each document, since C<violates> is
called once for each word.

=head2 FUNCTIONS

=head3 sub_names_in

The names of the named subs of a L<PPI::Document> or
L<Perl::Critic::Document>, lexical ones too, without their package.

=head3 bare_name

The part of a name after its last C<::>, which is all of a name with no package.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitcallswithaliasedtopic/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 CONTRIBUTOR

=for stopwords troglodyne-bot

troglodyne-bot <morpheus@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
