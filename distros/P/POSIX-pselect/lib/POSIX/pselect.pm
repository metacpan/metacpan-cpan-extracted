package POSIX::pselect;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.03';

use Exporter ();
our @ISA    = qw(Exporter);
our @EXPORT = qw(pselect);

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=head1 NAME

POSIX::pselect - Perl interface to pselect(2)

=head1 VERSION

This document describes POSIX::pselect version 0.03.

=for test_synopsis my($rfdset, $wfdset, $efdset, $timeout, $sigset);

=head1 SYNOPSIS

    use POSIX::pselect;

    pselect($rfdset, $wfdset, $efdset, $timeout, $sigset);

=head1 DESCRIPTION

This is an interface to C<pselect(2)>.

Note that we've made sure C<pselect(2)> works atomically B<only in Linux>.
Other operating systems like MacOSX don't support atomic C<pselect(2)>,
providing C<pselect(3)> as a non-atomic implementation instead.

=head1 INTERFACE

=head2 Functions

=head3 C<< pselect($rfdset, $wfdset, $efdset, $timeout, $sigmask) >>

Calls C<pselect(2)>.

The arguments are the same as Perl's C<select()> except for I<$sigmask>.

I<$sigmask> must be a C<POSIX::SigSet> object or an ARRAY reference
consisting of signal names (e.g. C<< [qw(INT HUP)] >>), or signal numbers.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<pselect(2)>

L<perlfunc/"select">

=head1 THANKS TO

@kazuho

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
