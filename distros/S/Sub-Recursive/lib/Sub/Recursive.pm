package Sub::Recursive;
use 5.006;

$VERSION = 0.05;
@EXPORT = qw/ recursive $REC /;
@EXPORT_OK = (@EXPORT, qw/ mutually_recursive %REC /);
$EXPORT_TAGS{ALL} = \@EXPORT_OK;

$REC = '$REC is a special variable used by ' . __PACKAGE__;
%REC = ($REC, $REC);

use strict;
use base 'Exporter';

sub recursive (&) {
    my ($code) = @_;

    my $rec = do { no strict 'refs'; \*{caller() . '::REC'} };
    return sub {
        local *$rec = \$code;
        &$code;
    };
}

sub mutually_recursive {
    my @p = @_;
    my %p = @_;

    my $rec = do { no strict 'refs'; \*{caller() . '::REC'} };

    my $c = 0;
    my @codes;
    for my $code (grep { $c++ % 2 } @p) {
        push @codes => sub {
            local *$rec = \$code;
            local *$rec = \%p;
            &$code;
        };
    }
    return @codes;
}

1;

__END__

=head1 NAME

Sub::Recursive - Anonymous memory leak free recursive subroutines


=head1 SYNOPSIS

    use Sub::Recursive;

    # LEAK FREE recursive subroutine.
    my $fac = recursive {
        my ($n) = @_;
        return 1 if $n < 1;
        return $n * $REC->($n - 1);
    };

    # Recursive anonymous definition in one line, plus invocation.
    print recursive { $_[0] <= 1 ? 1 : $_[0] * $REC->($_[0] - 1) } -> (5);

    # Experimental interface
    use Sub::Recursive qw/ mutually_recursive %REC /;

    my ($odd, $even) = mutually_recursive(
        odd  => sub { $_[0] == 0 ? 0 : $REC{even}->($_[0] - 1) },
        even => sub { $_[0] == 0 ? 1 : $REC{odd }->($_[0] - 1) },
    );


=head1 DESCRIPTION

Recursive closures suffer from a severe memory leak. C<Sub::Recursive> makes the problem go away cleanly and at the same time allows you to write recursive subroutines as expressions and can make them truly anonymous. There's no significant speed difference between using C<recursive> and writing the simpler leaking solution.

=head2 The problem

The following won't work:

    my $fac = sub {
        my ($n) = @_;
        return 1 if $n < 1;
        return $n * $fac->($n - 1);
    };

because of the recursive use of C<$fac> which isn't available until after the statement. The common fix is to do

    my $fac;
    $fac = sub {
        my ($n) = @_;
        return 1 if $n < 1;
        return $n * $fac->($n - 1);
    };

Unfortunately, this introduces another problem.

Because of perl's reference count system, the code above is a memory leak. C<$fac> references the anonymous sub which references C<$fac>, thus creating a circular reference. This module does not suffer from that memory leak.

There are two more reasons why I don't like to write recursive closures like that: (a) you have to first declare it, then assign it thus requiring more than a simple expression (b) you have to name it one way or another.

=head2 The solution

This module fixes all those issues. Just change C<sub> for C<recursive> and use C<< $REC->(...) >> for the recursive call:

    use Sub::Recursive;

    my $fac = recursive {
        my ($n) = @_;
        return 1 if $n < 1;
        return $n * $REC->($n - 1);
    };

It also makes it easy to pass it directly to a subroutine,

    foo(recursive { ... });

just as any other anonymous subroutine.


=head1 EXPORTS

If no arguments are given to the C<use> statement C<$REC> and C<recursive> are exported. If any arguments are given only those given are exported. C<:ALL> exports everything exportable.


=head2 C<$REC> - exported by default

C<$REC> holds a reference to the current subroutine inside subroutines created with C<recursive>. Don't ever touch C<$REC> inside or outside the subroutine except for the recursive call.

=head2 C<recursive> - exported by default

C<recursive> takes one argument and that's an anonymous sub defined in the same package as the call to C<recursive> is in. It's prototyped with C<&> so bare-block calling style is encouraged.

    recursive { ... }

The return value is an anonymous closure that has C<< $REC->(...) >> working in it.


=head2 C<%REC>

This is an experimental part of the API.

C<%REC> holds the subroutine references given to C<&mutually_recursive>, with the same keys.

Don't ever touch C<%REC> inside or outside the subroutines except for the recursive calls.

=head2 C<mutually_recursive>

This is an experimental part of the API.

C<mutually_recursive> works like C<recursive> except it takes a list of key/value pairs where the key names are the names used for the keys in C<%REC> and the values are the subroutine references. The return values in list context are the subroutine references, ordered as given to C<mutually_recursive>.

    my ($odd, $even) = mutually_recursive(
        odd  => sub { $_[0] == 0 ? 0 : $REC{even}->($_[0] - 1) },
        even => sub { $_[0] == 0 ? 1 : $REC{odd }->($_[0] - 1) },
    );


=head1 BUGS

If you follow the rest of the manual you don't have to read this section. I include this section anyway to make debugging simpler.

C<$REC> is a package global and as such there are some gotchas. You won't encounter any of these bugs below if you just use

    recursive { ... }

and don't mention C<$REC> outside of such an expression. In short: it's quite unlikely you'll get bitten by any of these bugs.

=over

=item C<my> and C<our>

Don't declare C<$REC> with C<my>. That'll make C<$REC> mean your lexical variable rather than the global that C<Sub::Recursive> uses.

Don't declare C<$REC> with C<our>. In particular, problem arise the C<our> scopes over several packages. If you do

    package Foo;
    use Sub::Recursive;
    our $REC;

    # Below, in the same file:

    package Bar;

    my $fatal = recursive { $REC->() };

C<$REC> in C<$fatal> will be using the value of C<$Foo::REC> but C<Sub::Recursive> has no way of knowing that and will think you use C<$Bar::REC>.

If you for some reason need to have C<$REC> declared you can as a last resort get around both these issues by fully qualifying C<$REC> to the package in which the subroutine is created.

    package Foo;
    use Sub::Recursive;
    my $REC;                                 # Bad.
    my $fatal = recursive { $Foo::REC->() }; # Still works.

=item Subroutine reference defined in another package

This is a really far out edge case.

If the subroutine reference given to C<recursive> is defined in another package than the call to C<recursive> in it then it won't work.

    package Foo;
    my $foo = sub { $REC->() };

    package Bar;
    use Sub::Recursive;
    my $bar = &recursive($foo); # Won't work.

The subroutine referenced by C<$foo> is using C<$Foo::REC> but C<recursive> thinks it's using C<$Bar::REC>. Note that you have to circumvent prototyping in order to encounter this bug.

Why you'd want to do this escapes me. Please contact me if you find a reason for doing this.

=back


=head1 EXAMPLE

Some algorithms are perhaps best written recursively. For simplicity, let's say I have a tree consisting of arrays of array with arbitrary depth. I want to map over this data structure, translating every value to another. For this I might use

    my $translator = recursive {
        [ map { ref() ? $REC->($_) : $translate{$_} } @{$_[0]} ]
    };

    my $bar = $translator->($foo);

Now, a tree mapper isn't perhaps the best example as it's a pretty general problem to solve, and should perhaps be abstracted but it still serves as an example of how this module can be handy.

A similar but more specialized task would be to find all men who share their Y chromosome.

    # A person data structure looks like this.
    my $person = {
        name => ...,
        sons => [ ... ],        # objects like $person
        daughters => [ ... ],   # objects like $person
    };

    my @names = recursive {
        my ($person) = @_;

        return
            $person->{name},
            map $REC->($_), @{$person->{sons}}
    } -> ($forefather);

This particular example isn't a closure as it doesn't reference any lexicals outside itself (and thus could've been written as a named subroutine). It's easy enough to think of a case when it would be a closure though. For instance if some branches should be excluded. A simple flag would solve that.

    my %exclude = ...;

    my @names = recursive {
        my ($person) = @_;

        return if $exclude{$person};

        return
            $person->{name},
            map $REC->($_), @{$person->{sons}}
    } -> ($forefather);

Hopefully this illustrates how this module allows you to write recursive algorithms inline like any other algorithm.


=head1 AUTHOR

Johan Lodin <lodin@cpan.org>


=head1 COPYRIGHT

Copyright 2004-2015 Johan Lodin. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

L<perlref>


=cut
