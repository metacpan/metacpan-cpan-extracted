package Perl::Phase::AtRunTime;

use strict;
use warnings;

our $VERSION = '0.03';

sub import {
    my ( $class, @runtime_calls ) = @_;

    my $caller = caller();
    for my $rt_call (@runtime_calls) {

        # can not simply do:
        # $rt_call->() if Perl::Phase::is_run_time();
        # because then the code is not executed when the caller is loaded at compile time

        local $@;

        ## no critic qw(BuiltinFunctions::ProhibitStringyEval)
        eval qq{
            package $caller {
                { # for use()
                    no warnings; ## no critic qw(TestingAndDebugging::ProhibitNoWarnings)
                    INIT {
                        use warnings;
                        \$rt_call->();
                    }
                }

                # for require(), when its too late to run INIT
                if( \${^GLOBAL_PHASE} eq 'RUN') {
                    use warnings; # for consistency w/ the INIT version
                    \$rt_call->();
                }
            };
        };
        die if $@;
    }

    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::Phase::AtRunTime - Register code at compile time to run at run time

=head1 VERSION

This document describes Perl::Phase::AtRunTime version 0.03

=head1 SYNOPSIS

    package Foo::Bar;

    use Perl::Phase::AtRunTime sub { say "Hello " __PACKAGE__ . ": ${^GLOBAL_PHASE}" };

When Foo::Bar is loaded at compile time it will output C<Hello Foo::Bar: INIT>.

When Foo::Bar is loaded at run time it will output C<Hello Foo::Bar: RUN>.

=head1 DESCRIPTION

If you have a reason to run code when a module is loaded you might reach for C<INIT>.

The problem there is when it is loaded at runtime you get “Too late to run INIT block” warnings and your code does not run.

So then you have to repeat the code w/ an C<if ${^GLOBAL_PHASE} eq 'RUN'> clause.

This module aims to encapsulate all of that madness into a simpler syntax.

=head1 INTERFACE

Pass one or more code references to L<Perl::Phase::AtRunTime>’s C<import()> (i.e. typically a C<use>)
that you want to ensure are executed once at runtime anytime the module is loaded.

Note that C<use warnings;> will be in effect when your code references are run.

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES AND LIMITATIONS

None reported.

=head1 BUGS AND FEATURES

Please report any bugs or feature requests (and a pull request for bonus points)
 through the issue tracker at L<https://github.com/drmuey/p5-Perl-Phase/issues>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2020, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
