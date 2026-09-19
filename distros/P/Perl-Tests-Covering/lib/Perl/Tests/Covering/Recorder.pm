package Perl::Tests::Covering::Recorder;
$Perl::Tests::Covering::Recorder::VERSION = '0.002';
# ABSTRACT: Writes down every file a perl loaded, as it exits.

use 5.014;

use strict;
use warnings FATAL => 'all';


END {
    # Taken whole, which also untaints it for a test run under -T.
    my ($dir) = ( $ENV{PERL_TESTS_COVERING_LOADED} // q{} ) =~ m/\A(.+)\z/saa;
    if ( defined $dir && open my $fh, '>>', "$dir/loaded.$$" ) {
        print {$fh} map { "$_\n" } grep { defined && index( $_, "\n" ) < 0 } $0, values %INC;
        close $fh;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Tests::Covering::Recorder - Writes down every file a perl loaded, as it exits.

=head1 VERSION

version 0.002

=head1 DESCRIPTION

L<Perl::Tests::Covering> loads this into each coverage run through
C<PERL5OPT>, next to L<Devel::Cover>.  At C<END> it appends C<$0> and every
file in C<%INC> to a file named after the process id, in the directory named by
C<PERL_TESTS_COVERING_LOADED>.  Without that variable it does nothing.

It is there because Devel::Cover builds its record from the subs that exist
when the program ends.  The code at the top of a required file has been freed
by then.  So a module that is nothing but top-level code, such as one that
only sets a hash of configuration, is not in Devel::Cover's record at all.

It loads nothing but L<strict> and L<warnings>, so that the test sees the
C<%INC> it would see without it.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Perl::Tests::Covering|Perl::Tests::Covering>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/perl-tests-covering/issues>

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
