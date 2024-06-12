package Subs::Trace;

use 5.006;
use strict;
use warnings;

=head1 NAME

Subs::Trace - Trace all calls in a package.

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

Similar to

 around 'my_function' => sub {
   my $original = shift;
   print "--> my_function\n";
   $original->(@_);
 };

But for ALL functions in a class.

    package MyClass;

    sub Func1 { ... }
    sub Func2 { ... }
    sub Func3 { ... }

    use Subs::Trace;

    Func1();
    # Prints:
    # --> MyClass::Func1

=head1 DESCRIPTION

This module updates all methods/functions in a class to
also print a message when invoked.

(This is a more of a proof-of-concept than useful!)

=head1 SUBROUTINES/METHODS

=head2 import

NOTE: This must be put at the very bottom of a class.

Also, some reason C<INIT{ ... }> is not being called with Moose.

Will attach hooks to all functions defined BEFORE this import call.

=cut

sub import {
    my $pkg = caller();

    # print "pkg=$pkg\n";

    no strict 'refs';
    no warnings 'redefine';

    for my $func ( sort keys %{"${pkg}::"} ) {

        # print "func=$func\n";

        my $stash = "$pkg\::$func";
        my $code  = *$stash{CODE};
        next if not $code;

        # print "  Updated $stash\n";

        *$stash = sub {
            print "--> $pkg\::$func\n";
            &$code;
        }
    }
}

=head1 AUTHOR

Tim Potapov, C<< <tim.potapov at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/poti1/subs-trace/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Subs::Trace

=head1 ACKNOWLEDGEMENTS

TBD

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Tim Potapov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Subs::Trace
