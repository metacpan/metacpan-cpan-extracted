package Perl::Critic::Policy::ProhibitMisplacedMethods 0.001;

# ABSTRACT: A method goes in the class whose subclasses all need it, no higher and no lower.

use 5.014;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use Readonly;

use List::Util   ();
use Scalar::Util ();

use Perl::Critic::Distribution ();
use Perl::Critic::Utils        qw{ :severities :classification };
use parent                     qw{Perl::Critic::Policy};


Readonly::Hash my %EXPL_FOR => (
    down => q{Move it into the subclass that uses it, so that no other subclass inherits it},
    up   => q{Move it into the class that they inherit from, so that they share one copy},
);

Readonly::Hash my %DESC_FOR => (
    down => q{Sub %s is used only by %s, a subclass of %s},
    up   => q{Sub %s is also defined in %s, and %s, which they inherit from, does not define it},
);

Readonly::Scalar my $DEFAULT_ALLOW_SUBS => join ' ', Perl::Critic::Distribution->called_by_perl();

# The parts of a distribution that are read, and checked.  A subclass or a
# call in a test is the business of the test.
Readonly::Hash my %CODE_AREA => ( bin => 1, lib => 1 );

Readonly::Array my @INTERPOLATING => qw{
  PPI::Token::Quote::Double
  PPI::Token::Quote::Interpolate
  PPI::Token::QuoteLike::Backtick
  PPI::Token::QuoteLike::Command
  PPI::Token::QuoteLike::Regexp
  PPI::Token::Regexp
  PPI::Token::HereDoc
};

# The words before sub that make it a lexical sub, which is not a method.
Readonly::Hash my %LEXICAL => ( my => 1, state => 1 );

Readonly::Scalar my $INTERPOLATED_CALL_RX => qr/ -> \s* (?: \w+ :: )* (\w+) /xs;
Readonly::Scalar my $NAME_RX              => qr/ \A \w+ \z /xs;

# One index per distribution root, for the life of the process, as
# ProhibitUnusedDefinitions keeps.  our, so that a test can empty it.
our %INDEX_FOR;

# Change it when what _parse returns changes shape.
Readonly::Scalar my $DATA_FORMAT => 1;

# The record of a package in what walk found, made on first mention.
my $package = sub {
    my ( $found, $pkg ) = @_;
    return $found->{packages}{$pkg} //= { parents => [], subs => {} };
};

# Whether a class above the first of $chain defines $name.
my $inherits = sub {
    my ( $index, $chain, $name ) = @_;
    return grep { $index->{defines}{$_}{$name} } @{$chain}[ 1 .. $#$chain ];
};


sub supported_parameters {
    return (
        {
            name           => 'allow_subs',
            description    => 'Subs that are never reported, in addition to the built-in list.',
            default_string => $DEFAULT_ALLOW_SUBS,
            behavior       => 'string list',
        },
        Perl::Critic::Distribution->policy_parameters(),
    );
}

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    # 'string list' hands us the configured value in place of the default.
    $self->{_allow_subs}{$_} = 1 for split m/\s+/xs, $DEFAULT_ALLOW_SUBS;

    # Through a closure, so that a test that replaces collect is seen.
    Perl::Critic::Distribution->register(
        name    => __PACKAGE__,
        version => join( q{/}, $DATA_FORMAT, Perl::Critic::Distribution->stamp(__FILE__) // q{} ),
        collect => sub { return collect(@_) },
    );

    return $self->SUPER::initialize_if_enabled($config);
}

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw(maintenance) }
sub applies_to       { return qw(PPI::Statement::Sub) }


sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $subs = $self->subs_in($doc)                             or return;
    my $def  = $subs->{by_elem}{ Scalar::Util::refaddr($elem) } or return;
    my ( $pkg, $name ) = @$def;
    return if $self->{_allow_subs}{$name} || $self->{_allow_subs}{"${pkg}::$name"};

    my $index = $INDEX_FOR{ $subs->{dist}->root() } //= index_of( $subs->{dist} );

    my @found;
    if ( my $below = used_only_below( $index, $pkg, $name ) ) {
        push @found, $self->violation( sprintf( $DESC_FOR{down}, "${pkg}::$name", $below, $pkg ), $EXPL_FOR{down}, $elem );
    }
    if ( my ( $above, @others ) = defined_beside( $index, $pkg, $name ) ) {
        push @found, $self->violation( sprintf( $DESC_FOR{up}, "${pkg}::$name", join( ', ', @others ), $above ), $EXPL_FOR{up}, $elem );
    }
    return @found;
}


sub subs_in {
    my ( $self, $doc ) = @_;

    my $last = $self->{_last};
    return $last->{subs} if $last && Scalar::Util::refaddr( $last->{doc} ) == Scalar::Util::refaddr($doc);

    my $subs;
    my $file = $doc->filename();
    my ( undef, $area ) = Perl::Critic::Distribution->root_of($file);
    if ( $area && $CODE_AREA{$area} ) {

        my $dist = Perl::Critic::Distribution->for_file( $file, cache => $self->{_cache}, cache_dir => $self->{_cache_dir} );
        if ($dist) {
            my %by_elem = map { Scalar::Util::refaddr( $_->[0] ) => [ @$_[ 1, 2 ] ] } @{ walk( $doc->ppi_document() )->{defs} };
            $subs = { dist => $dist, by_elem => \%by_elem };
        }
    }

    # The document is held, not just its address, so the address cannot be
    # handed to the next document while we still think we know what is in it.
    $self->{_last} = { doc => $doc, subs => $subs };
    return $subs;
}


sub index_of {
    my ($dist) = @_;

    my $by_file = $dist->collected(__PACKAGE__);
    my ( %parents, %defines, %users );
    foreach my $file ( sort keys %$by_file ) {
        next if !$CODE_AREA{ $dist->area_of($file) // q{} };

        my $found = $by_file->{$file};
        foreach my $pkg ( keys %{ $found->{packages} } ) {
            my $declared = $found->{packages}{$pkg};
            push @{ $parents{$pkg} }, @{ $declared->{parents} };
            $defines{$pkg}{$_} = 1 for @{ $declared->{subs} };
        }
        foreach my $use ( @{ $found->{uses} } ) {
            my ( $pkg, $in_sub, $name ) = @$use;
            $users{$name}{$pkg}{$in_sub} = 1;
        }
    }

    foreach my $pkg ( keys %parents ) {
        my %seen;
        $parents{$pkg} = [ grep { !$seen{$_}++ } @{ $parents{$pkg} } ];
    }
    return { parents => \%parents, defines => \%defines, users => \%users };
}


sub ancestry {
    my ( $index, $pkg ) = @_;

    my @chain = ($pkg);
    my %seen  = ( $pkg => 1 );
    my @parents;
    while ( @parents = @{ $index->{parents}{ $chain[-1] } // [] } ) {
        return                if @parents > 1 || $seen{ $parents[0] }++;
        return ( \@chain, 1 ) if !$index->{parents}{ $parents[0] };
        push @chain, $parents[0];
    }
    return ( \@chain, 0 );
}


sub used_only_below {
    my ( $index, $pkg, $name ) = @_;

    my $users = $index->{users}{$name} // {};
    my %user;
    foreach my $user ( keys %$users ) {

        # A use inside the sub itself is recursion, and not a user.
        my @in = grep { $user ne $pkg || $_ ne "${pkg}::$name" } keys %{ $users->{$user} };
        $user{$user} = 1 if @in;
    }
    $user{$_} = 1 for grep { $_ ne $pkg && $index->{defines}{$_}{$name} } keys %{ $index->{defines} };
    return if !%user;

    # The path from the class below $pkg down to each user, and what they share.
    my $shared;
    foreach my $user ( sort keys %user ) {
        my ($chain) = ancestry( $index, $user ) or return;
        my ($at)    = grep { $chain->[$_] eq $pkg } 0 .. $#$chain;
        return if !defined $at;
        my @down = reverse @{$chain}[ 0 .. $at - 1 ];
        $shared //= \@down;
        my $common = 0;
        $common++ while $common < @$shared && $common < @down && $shared->[$common] eq $down[$common];
        $shared = [ @{$shared}[ 0 .. $common - 1 ] ];
    }
    return @$shared ? $shared->[-1] : undef;
}


sub defined_beside {
    my ( $index, $pkg, $name ) = @_;

    my ( $mine, $outside ) = ancestry( $index, $pkg );
    return if !$mine || $outside || $inherits->( $index, $mine, $name );

    my %above = map { $mine->[$_] => $_ } 1 .. $#$mine;
    my ( $nearest, @beside );
    foreach my $other ( sort grep { $_ ne $pkg && $index->{defines}{$_}{$name} } keys %{ $index->{defines} } ) {
        my ( $theirs, $out ) = ancestry( $index, $other );
        next if !$theirs || $out || $inherits->( $index, $theirs, $name );

        my ($shared) = grep { exists $above{$_} } @{$theirs}[ 1 .. $#$theirs ];
        next if !defined $shared;
        if ( !defined $nearest || $above{$shared} < $above{$nearest} ) {
            ( $nearest, @beside ) = ( $shared, $other );
        }
        elsif ( $shared eq $nearest ) {
            push @beside, $other;
        }
    }
    return defined $nearest ? ( $nearest, @beside ) : ();
}


sub collect {
    my ($ppi) = @_;

    my $found = walk($ppi);
    my %packages;
    foreach my $pkg ( keys %{ $found->{packages} } ) {
        my $declared = $found->{packages}{$pkg};
        $packages{$pkg} = { parents => $declared->{parents}, subs => [ sort keys %{ $declared->{subs} } ] };
    }
    return { packages => \%packages, uses => [ map { [ split m/\0/xs, $_, 3 ] } sort keys %{ $found->{uses} } ] };
}


sub walk {
    my ($ppi) = @_;

    my %found = ( defs => [], packages => {}, uses => {} );
    Perl::Critic::Distribution->walk(
        $ppi,
        sub {
            my ( $child, $pkg, $in_sub ) = @_;

            if ( $child->isa('PPI::Statement::Package') ) {
                $package->( \%found, $child->namespace() );
                return;
            }

            my $first = $child->isa('PPI::Statement') ? $child->schild(0) : undef;
            if ( $child->isa('PPI::Statement::Sub') && !$child->forward() && !( $first && $LEXICAL{ $first->content() } ) ) {
                my ( $owner, $name ) = $child->name() =~ m/\A(?:(.+)::)?(\w+)\z/xs;
                $owner //= $pkg;
                $package->( \%found, $owner )->{subs}{$name} = 1;
                push @{ $found{defs} }, [ $child, $owner, $name ];
                return;
            }

            # A class names its parents outside its subs.
            push @{ $package->( \%found, $pkg )->{parents} }, parents_named($child) if $child->isa('PPI::Statement') && !defined $in_sub;

            $found{uses}{ join "\0", $pkg, $in_sub // q{}, $_ } = 1 for $child->isa('PPI::Node') ? () : names_used($child);
            return;
        },
    );
    return \%found;
}


sub parents_named {
    my ($stmt) = @_;

    my $first = $stmt->schild(0) or return;
    my $names;
    if ( $stmt->isa('PPI::Statement::Include') ) {
        my $module = $stmt->module() // q{};
        $names = $stmt->type() eq 'use' && ( $module eq 'parent' || $module eq 'base' );
    }
    elsif ( $first->isa('PPI::Token::Word') && $first->content() eq 'extends' ) {
        $names = 1;
    }
    elsif ( $stmt->find_first( sub { $_[1]->isa('PPI::Token::Symbol') && $_[1]->symbol() =~ m/\A\@(?:\w+::)*ISA\z/xs } ) ) {
        $names = $first->content() eq 'push' || $stmt->find_first( sub { $_[1]->isa('PPI::Token::Operator') && $_[1]->content() eq q{=} } );
    }
    return if !$names;

    return grep { m/\A\w+(?:::\w+)*\z/xs } (
        map( { $_->literal() } @{ $stmt->find('PPI::Token::QuoteLike::Words') || [] } ),
        map( { $_->string() } @{ $stmt->find('PPI::Token::Quote')             || [] } ),
    );
}


sub names_used {
    my ($token) = @_;

    my @names;
    if ( $token->isa('PPI::Token::Word') ) {
        my $call =
             !$token->parent()->isa('PPI::Statement::Sub')
          && !is_package_declaration($token)
          && !is_included_module_name($token)
          && ( is_method_call($token) || is_function_call($token) );
        push @names, $token->content() =~ m/(\w+)\z/xs if $call;
    }
    elsif ( $token->isa('PPI::Token::Symbol') ) {
        push @names, $token->symbol() =~ m/\A&(?:\w+::)*(\w+)\z/xs;
    }
    elsif ( $token->isa('PPI::Token::QuoteLike::Words') ) {
        push @names, grep { m/$NAME_RX/xs } $token->literal();
    }
    elsif ( $token->isa('PPI::Token::Quote') ) {
        push @names, grep { m/$NAME_RX/xs } $token->string();
    }

    if ( List::Util::any { $token->isa($_) } @INTERPOLATING ) {
        my $content = $token->isa('PPI::Token::HereDoc') ? join( q{}, $token->heredoc() ) : $token->content();
        push @names, $content =~ m/$INTERPOLATED_CALL_RX/gxs;
    }
    return @names;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::ProhibitMisplacedMethods - A method goes in the class whose subclasses all need it, no higher and no lower.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::ProhibitMisplacedMethods

A class hierarchy works when each method is in the class whose subclasses all
need it.  A method that only one subclass needs, in the class above it, is
inherited by every other subclass for nothing.  Two subclasses that each define
the same method, under a class that defines none, are two copies of one thing,
and the next subclass makes a third.

Where a method is used is not a question that one file can answer.  So this
policy reads the whole distribution around the file that it critiques, through
L<Perl::Critic::Distribution>.  Another policy that reads the distribution
through the same library shares the parse.

It reports two things, each at the definition of the sub that is misplaced.

=over 4

=item A sub that only one subclass uses

A sub of a class, when everything in F<bin/> and F<lib/> that uses it is one
subclass, or that subclass and the classes below it.  Move it down into that
subclass.

=item A sub that two subclasses define, and the class above them does not

A sub of a class, when another class of the distribution defines a sub of the
same name, and the nearest class that both inherit from defines none, and
neither does any class above that one.  Move it up into that class.

=back

=head2 PROHIBITED

    package My::Base;
    sub helper { ... }                       # only My::Base::One uses it

    package My::Base::One;
    use parent -norequire, 'My::Base';
    sub run { my ($self) = @_; return $self->helper }

    package My::Base::Two;
    use parent -norequire, 'My::Base';
    sub release_command { ... }              # My::Base::Three has one too,
                                             # and My::Base has none

    package My::Base::Three;
    use parent -norequire, 'My::Base';
    sub release_command { ... }

=head2 ALLOWED

    package My::Base;
    sub hook { return () }                   # a default that a subclass can override
    sub run  { my ($self) = @_; return $self->hook }

    package My::Base::One;
    use parent -norequire, 'My::Base';
    sub hook { return 'one' }

A sub that the class itself uses, or that anything outside its subclasses uses,
is an interface.  It stays where it is, however few subclasses override it.

=head2 WHAT COUNTS AS A USE

Every use is matched by its name alone, because the class behind C<$obj> is not
known statically.  So this policy counts more uses than there are, and that
makes it report less, never more.

=over 4

=item * A method call, C<< $obj->helper >>, C<< $self->SUPER::helper >> or
C<< Some::Class->helper >>, and a method call inside an interpolating string,
as C<< "@{[ $obj->helper ]}" >>.

=item * A function call, bare or qualified: C<helper()>, C<My::Base::helper()>.

=item * A reference: C<\&helper>.

=item * A string or a C<qw{}> word that spells the name, as in
C<< $self->can('helper') >> or a dispatch table of names.

=item * A definition of the same name in a subclass, which overrides it.

=back

A use counts only from a file in F<bin/> or F<lib/>.  A call from a test does
not make a subclass need a sub.  A use inside the sub itself, which is
recursion, does not count.

A sub that nothing uses is not reported.  That is
L<Perl::Critic::Policy::ProhibitUnusedDefinitions>.

=head2 PARENTS

A class names its parents in one of these ways:

    use parent qw{My::Base};
    use parent -norequire, 'My::Base';
    use base 'My::Base';
    our @ISA = ('My::Base');
    push @ISA, 'My::Base';
    extends 'My::Base';                      # Moose, Moo and Mouse

=head2 CAVEATS

A class with more than one parent, or below one, is never reported, because
the class to move a sub to is not a single class.

A sub is reported as defined twice only when every class above both
definitions is in the distribution.  A class above them in another
distribution can define the sub, and this policy reads only this one.

A subclass in another distribution can use a sub of this one, and so can a
template.  Neither is read.  So a sub that a plugin outside the distribution
uses, and that one subclass in it uses, is reported.  That is what
C<allow_subs> and C<## no critic> are for.

A method name built at runtime, as in C<< $obj->$name >>, is not read.  The
string that holds the name usually is, as a string.

The distribution is read once per process.  A file edited after that is not
seen again in that process.  L<Perl::Critic::Distribution/THE CACHE ON DISK>
is how the next process sees it.

=head2 CONFIGURATION

=over 4

=item C<allow_subs>

Space separated subs that are never reported, as a bare name or qualified with
its package.  Adds to the built-in list, which is the names that perl or a
framework calls for you, such as C<DESTROY>, C<import> and C<BUILD>:

    [ProhibitMisplacedMethods]
    allow_subs = new My::Base::release_command

=item C<cache>

Whether to keep what was read on disk between runs.  On by default.

=item C<cache_dir>

Where it is kept.  The default is that of L<Perl::Critic::Distribution>.  Give
every policy that reads the distribution the same one, or none, so that they
share a parse.

=back

=head2 METHODS

=head3 supported_parameters

C<allow_subs>, the names that are never reported, added to the built-in list.
C<cache> and C<cache_dir>, as L<Perl::Critic::Distribution> keeps them.

=head3 initialize_if_enabled

Folds the built-in exemptions back into whatever was configured, and registers
C<collect> with L<Perl::Critic::Distribution>, so that it runs in the same
parse as what any other enabled policy needs.

=head3 default_severity

SEVERITY_LOW

=head3 default_themes

maintenance

=head3 applies_to

PPI::Statement::Sub

=head3 violates

Standard L<Perl::Critic::Policy> interface.  Returns a violation for a sub
that only one subclass uses, and one for a sub that another class defines
where the class above both does not.

=head3 subs_in

    my $subs = $policy->subs_in($doc);

The distribution of a L<Perl::Critic::Document>, and the package and the name
of each sub that it defines, keyed by the address of the statement:
C<< { dist => $dist, by_elem => { $address => [ $package, $name ] } } >>.
Undef for a file outside F<bin/> and F<lib/> of a distribution.

It keeps the answer for the document that it was last asked about, because
C<violates> asks once for each sub of a file.

=head2 FUNCTIONS

These are how the policy reads a distribution.  A caller has no need of them,
and they are documented for whoever changes the policy.

=head3 index_of

    my $index = index_of($dist);

What C<collect> found in each file of F<bin/> and F<lib/> of a
L<Perl::Critic::Distribution>, put together:
C<< { parents => { $package => [ @parents ] }, defines => { $package => { $sub => 1 } }, users => { $sub => { $package => { $in_sub => 1 } } } } >>.
C<$in_sub> is the qualified name of the sub that the use is in, or the empty
string.

=head3 ancestry

    my ( $chain, $outside ) = ancestry( $index, $package );

C<$package> and each class above it, nearest first, as far as the distribution
declares them.  C<$outside> is true when the last of them has a parent that
the distribution does not declare.  An empty list when a class on the way has
more than one parent, or when the parents loop.

=head3 used_only_below

    my $subclass = used_only_below( $index, $package, $sub );

The subclass of C<$package> that every use of its sub is in, or in a class
below that subclass.  A definition of the same name in a subclass counts as a
use.  Undef when C<$package> itself or anything outside its subclasses uses
the sub, and when nothing uses it.

=head3 defined_beside

    my ( $above, @others ) = defined_beside( $index, $package, $sub );

The nearest class above C<$package> that another definition of the sub shares
with it, and the classes that have that definition.  An empty list when there
is none, when a class above C<$package> defines the sub, and when a class above
it is outside the distribution.

=head3 collect

    my $found = collect($ppi);

What one L<PPI::Document> declares and uses, as plain data that JSON can hold:
C<< { packages => { $package => { parents => [ ... ], subs => [ ... ] } }, uses => [ [ $package, $in_sub, $name ], ... ] } >>.
L<Perl::Critic::Distribution> calls it for each file.

=head3 walk

    my $found = walk($ppi);

What C<collect> returns, before it is plain data, and C<defs>: each sub
statement, with its package and its name.  A lexical sub is not a method, and
is left out.  L<Perl::Critic::Distribution/walk> says which package and which
sub each element is in.

=head3 parents_named

    my @parents = parents_named($statement);

The classes that a statement names as the parents of its package, if it is
one that does: C<use parent>, C<use base>, an assignment or a C<push> to
C<@ISA>, or C<extends>.

=head3 names_used

    my @names = names_used($token);

Each name that a token can use: the name that a method or function call calls,
the last part of it when it is qualified, the name of a C<\&name>, a string or
C<qw{}> word that spells a name, and each method that an interpolating string
calls.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/perl-critic-policy-prohibitmisplacedmethods/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

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
