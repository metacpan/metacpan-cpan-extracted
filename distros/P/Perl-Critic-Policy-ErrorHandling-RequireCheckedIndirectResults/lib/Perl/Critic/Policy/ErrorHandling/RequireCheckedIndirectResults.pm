package Perl::Critic::Policy::ErrorHandling::RequireCheckedIndirectResults 0.001;

# ABSTRACT: Check the result of a syscall or an eval that a sub returns to you.

use strict;
use warnings FATAL => 'all';
use 5.014;
use re '/aa';
use Readonly;
use List::Util                 qw{any first};
use Perl::Critic::Distribution ();
use Perl::Critic::Utils        qw{ :severities };

use parent qw{Perl::Critic::Policy};


Readonly::Scalar my $DESC => q{The result of %s, returned by a sub, is not checked};
Readonly::Scalar my $EXPL => q{Check what the call returns, or make the sub die on failure};

# Those of InputOutput::RequireCheckedSyscalls, which this policy mirrors.
Readonly::Array my @DEFAULT_FUNCTIONS => qw{ open close print say };
Readonly::Array my @BUILTIN_FUNCTIONS => qw{
  accept bind binmode chdir chmod chown close closedir connect
  dbmclose dbmopen exec fcntl flock fork ioctl kill link listen
  mkdir msgctl msgget msgrcv msgsnd open opendir pipe print read
  readdir readline readlink readpipe recv rename rmdir say seek seekdir
  semctl semget semop send setpgrp setpriority setsockopt shmctl
  shmget shmread shutdown sleep socket socketpair symlink syscall
  sysopen sysread sysseek system syswrite tell telldir truncate
  umask unlink utime wait waitpid
};

Readonly::Hash my %RESULT      => map { $_ => 1 } @BUILTIN_FUNCTIONS, 'eval';
Readonly::Hash my %MODIFIER    => map { $_ => 1 } qw{ if unless while until for foreach };
Readonly::Hash my %SEPARATOR   => map { $_ => 1 } ( q{,}, q{=>} );
Readonly::Hash my %DIES_ITSELF => map { $_ => 1 } qw{ autodie Fatal };

# Change it when what the collector returns changes shape.
Readonly::Scalar my $DATA_FORMAT => 1;

# The part of a name after its last ::, which is all of a bare name.
my $bare_name = sub {
    my ($name) = @_;
    my $at     = rindex $name, '::';
    return $at < 0 ? $name : substr $name, $at + 2;
};


sub supported_parameters {
    return (
        {
            name           => 'functions',
            description    => 'The builtins whose result a sub must not return to a caller that drops it.  :builtins is every one that returns a status.',
            default_string => join( q{ }, @DEFAULT_FUNCTIONS ),
            behavior       => 'string list',
        },
        {
            name           => 'exclude_functions',
            description    => 'Builtins to leave out of functions.',
            default_string => q{},
            behavior       => 'string list',
        },
    );
}


sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw{ bugs maintenance } }
sub applies_to       { return 'PPI::Document' }


sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    my @functions = map { $_ eq ':builtins' ? @BUILTIN_FUNCTIONS : $_ } keys %{ $self->{_functions} };
    my %counted   = map { ( $_ => 1 ) } @functions, 'eval';
    delete @counted{ keys %{ $self->{_exclude_functions} } };
    $self->{_counted} = \%counted;

    Perl::Critic::Distribution->register(
        name    => __PACKAGE__,
        version => join( q{/}, $DATA_FORMAT, Perl::Critic::Distribution->stamp(__FILE__) // q{} ),
        collect => sub {
            my ($ppi) = @_;
            return { result_subs => { map { ( $_->[1] => $_->[2] ) } grep { !$_->[0]->type } result_subs_in( $ppi, packages_in($ppi) ) } };
        },
    );
    return $self->SUPER::initialize_if_enabled($config);
}


sub violates {
    my ( $self, undef, $doc ) = @_;

    # The subs of this file by the name that a call here uses, and those of
    # the rest of the distribution by their full name, each with the builtin
    # whose result it returns.
    my $packages = packages_in($doc);
    my %local    = map { ( $_->[0]->name => $_->[2] ) } result_subs_in( $doc, $packages );
    my %remote;
    my $filename = $doc->filename;
    if ( my $dist = defined $filename && Perl::Critic::Distribution->for_file($filename) ) {
        %remote = map { %{ $_->{result_subs} } } values %{ $dist->collected(__PACKAGE__) };
    }
    my $counted = $self->{_counted};
    delete @local{ grep { !$counted->{ $local{$_} } } keys %local };
    delete @remote{ grep { !$counted->{ $remote{$_} } } keys %remote };
    return if !%local && !%remote;

    # The last part of each full name, so that a word that cannot be one is
    # passed over before its package is looked for.
    my %bare = map { ( $bare_name->($_) => 1 ) } keys %remote;

    my @violations;
    foreach my $word ( @{ $doc->find('PPI::Token::Word') || [] } ) {
        my $name = $word->content;
        next if !$local{$name} && !$bare{ $bare_name->($name) };
        my $full    = index( $name, '::' ) >= 0 ? $name : package_at( $word, $packages ) . "::$name";
        my $builtin = $local{$name} // $remote{$full} or next;
        next if !is_dropped($word);

        push @violations, $self->violation( sprintf( $DESC, $builtin eq 'eval' ? 'an eval block' : $builtin ), $EXPL, $word );
    }
    return @violations;
}


sub result_subs_in {
    my ( $ppi, $packages ) = @_;

    my $dies = any { $DIES_ITSELF{ $_->module // q{} } } @{ $ppi->find('PPI::Statement::Include') || [] };

    my @found;
    foreach my $sub ( @{ $ppi->find('PPI::Statement::Sub') || [] } ) {
        my $block = $sub->block or next;
        next if $block->find_any( sub { $_[1]->isa('PPI::Token::Word') && $_[1]->content eq 'wantarray' } );
        my $builtin = result_of($block) // next;
        next if $dies && $builtin ne 'eval';

        my $name = $sub->name;
        push @found, [ $sub, index( $name, '::' ) >= 0 ? $name : package_at( $sub, $packages ) . "::$name", $builtin ];
    }
    return @found;
}


sub result_of {
    my ($block) = @_;

    # The builtin that a statement starts with, past a return when it has one.
    my $leads = sub {
        my ( $statement, $skip ) = @_;
        my @parts = $statement->schildren;
        shift @parts if $skip;
        my $first = $parts[0];
        return if !$first || !$first->isa('PPI::Token::Word') || !$RESULT{ $first->content };
        return if $first->content eq 'eval' && !( $parts[1] && $parts[1]->isa('PPI::Structure::Block') );
        return $first->content;
    };

    my $returns = $block->find( sub { $_[1]->isa('PPI::Statement::Break') && ( $_[1]->schild(0) // q{} ) eq 'return' } ) || [];
    foreach my $return (@$returns) {
        my $builtin = $leads->( $return, 1 ) // next;

        # One inside an inner sub returns from that sub.
        my $inner = 0;
        for ( my $up = $return->parent; $up && $up != $block; $up = $up->parent ) {
            $inner ||= $up->isa('PPI::Statement::Sub') || ( $up->isa('PPI::Structure::Block') && ( $up->sprevious_sibling // q{} ) eq 'sub' );
        }
        return $builtin if !$inner;
    }

    my $last = ( grep { $_->isa('PPI::Statement') } $block->schildren )[-1];
    return if !$last || ref $last ne 'PPI::Statement';
    return $leads->( $last, 0 );
}


sub packages_in {
    my ($ppi) = @_;
    return $ppi->find('PPI::Statement::Package') || [];
}


sub package_at {
    my ( $elem, $packages ) = @_;

    my $package = 'main';
    foreach my $statement (@$packages) {
        my $block = first { $_->isa('PPI::Structure::Block') } $statement->schildren;
        if ($block) {
            for ( my $up = $elem->parent; $up; $up = $up->parent ) {
                return $statement->namespace if $up == $block;
            }
            next;
        }
        my ( $line,    $col )    = @{ $statement->location }[ 0, 1 ];
        my ( $at_line, $at_col ) = @{ $elem->location }[ 0, 1 ];
        $package = $statement->namespace if $line < $at_line || ( $line == $at_line && $col < $at_col );
    }
    return $package;
}


sub is_dropped {
    my ($word) = @_;

    # A plain statement that starts with the call: not a declaration, a
    # return, or an if.
    my $statement = $word->parent;
    return 0 if ref $statement ne 'PPI::Statement' || $statement->schild(0) != $word;

    # Its arguments, then a postfix modifier or the end.  Any other operator
    # does something with the result, such as or die.
    my @parts = $statement->schildren;
    foreach my $part ( @parts[ 1 .. $#parts ] ) {
        last     if $part->isa('PPI::Token::Word')     && $MODIFIER{ $part->content };
        return 0 if $part->isa('PPI::Token::Operator') && !$SEPARATOR{ $part->content };
    }

    # The last statement of a block passes its value on, unless the block is
    # that of an if, a loop or the like.
    my $holder = $statement->parent;
    return 1 if $statement->snext_sibling || !$holder->isa('PPI::Structure::Block');
    return $holder->parent && $holder->parent->isa('PPI::Statement::Compound') ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::ErrorHandling::RequireCheckedIndirectResults - Check the result of a syscall or an eval that a sub returns to you.

=head1 VERSION

version 0.001

=head1 DESCRIPTION

C<InputOutput::RequireCheckedSyscalls>, C<InputOutput::RequireCheckedOpen> and
C<ErrorHandling::RequireCheckingReturnValueOfEval> report a syscall or an
C<eval> block whose result nobody checks.  They look where the builtin is
called.  A sub that returns the result passes it on, so the builtin is
checked as far as they can see, and the caller that drops it is not looked at:

    sub finish { return close $_[0] }
    ...
    finish($fh);               # reported

This policy reports such a call.  The value of the sub is the result: the value
of a C<return>, or its last statement.  The call is reported when it is a
statement of its own, so that its result goes nowhere.

=head2 Which results

The builtins are those of C<InputOutput::RequireCheckedSyscalls>, configured
the same way: C<open>, C<close>, C<print> and C<say> by default, and every
builtin that returns a status, C<mkdir> among them, with
C<functions = :builtins>.  An C<eval> block
is always one.  A file that says C<use autodie> or C<use Fatal> has its
builtins die on failure, so its subs return no syscall result to check.  That
is decided for the whole file.

=head2 Dropped

A call is dropped when it is a statement of its own: alone, or with a postfix
modifier such as C<if> or C<foreach>.  A call followed by an operator, such as
C<or die>, is checked.  The last statement of a block passes its value on,
unless the block belongs to an C<if>, a loop or the like, or is the file
itself.  So the last statement of a sub, a C<do> or an C<eval> is not dropped.

=head2 Where the sub can be

In the same file, by its name.  In another file of the same distribution,
which L<Perl::Critic::Distribution> reads: a package sub, called by its full
name, as C<Some::finish()>, or by its bare name from the same package.  A
policy that reads the distribution through the same library shares its parse.

=head2 What it leaves alone

A call whose result is assigned, tested, returned or passed on.  A sub that
asks C<wantarray>.  A result that reaches the return through a variable, and a
C<return> inside an inner anonymous sub.  A method call, because the method
that runs can be another sub of the same name.  A bare call of a sub from
another file in another package, because what it imports is not known.  An
C<eval> of a string, which C<BuiltinFunctions::ProhibitStringyEval> is for.

=head1 CONFIGURATION

    [ErrorHandling::RequireCheckedIndirectResults]
    functions = :builtins
    exclude_functions = print

C<functions> and C<exclude_functions> are those of
C<InputOutput::RequireCheckedSyscalls>.  Give both policies the same, or this
one reports the results that the other was told to leave alone.

=head2 METHODS

=head3 supported_parameters

C<functions> and C<exclude_functions>, as in
C<InputOutput::RequireCheckedSyscalls>.

=head3 default_severity

=head3 default_themes

=head3 applies_to

The whole document, because a call can come before the sub that it calls.

=head3 initialize_if_enabled

Works out which results count, from C<functions> and C<exclude_functions>.
Registers what this policy needs from each file of a distribution with
L<Perl::Critic::Distribution>: the package subs whose value is a result, and
which builtin it comes from, whatever the configuration.  A lexical sub is left
out, because no other file can call it.

=head3 violates

=head2 FUNCTIONS

The steps of C<violates>, for its tests.

=head3 result_subs_in

    my @found = result_subs_in( $ppi, packages_in($ppi) );

Each sub of a document whose value is the result of a builtin of
C<InputOutput::RequireCheckedSyscalls> or of an C<eval> block, as its
statement, its full name and the builtin, C<eval> for an C<eval> block.  A sub
that asks C<wantarray> is not one, and a file under C<autodie> or C<Fatal> has
none but its C<eval> blocks.

=head3 result_of

The builtin whose result is the value of a block, or undef: that of a
C<return> anywhere in it, or of its last statement.  Not a C<return> inside an
inner sub, which returns from that sub.

=head3 packages_in

The C<package> statements of a document, in order, for C<package_at>.  A
document is searched once, and not once for each element.

=head3 package_at

    my $package = package_at( $elem, packages_in($ppi) );

The package that an element is in: that of the block of a C<package NAME { }>
around it, or else that of the last C<package NAME;> before it, or C<main>.

=head3 is_dropped

Whether a call is a statement of its own, whose result goes nowhere.
L</Dropped> says when.  A method, a hash key and the name in a sub statement
never start a plain statement, so they are never dropped calls.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-requirecheckedindirectresults/issues>

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
