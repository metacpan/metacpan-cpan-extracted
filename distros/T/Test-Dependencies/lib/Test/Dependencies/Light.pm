package Test::Dependencies::Light;

use warnings;
use strict;
use Pod::Strip;

use Exporter 'import';

our @EXPORT = qw/get_modules_used_in_file/;

=head1 NAME

Test::Dependencies::Light - Light style for checking for dependencies.

=head1 SYNOPSIS

You shouldn't have to include this module yourself.  Look at the
'style' option of L<Test::Dependencies>.

This module exports exactly one function.

=head1 EXPORTED FUNCTIONS

=head2 get_modules_used_in_file

Returns an array ref of all the modules that the passed file uses.
This style determines this list by opening the file, stripping out
any POD, and using regular expressions to try and find use
statements.

=cut

sub get_modules_used_in_file {
  my $file = shift;
  my ($fh, $code);
  my %used;

  local $/;
  open $fh, $file or return undef;
  my $data = <$fh>;
  close $fh;
  my $p = Pod::Strip->new;
  $p->output_string(\$code);
  $p->parse_string_document($data);
  $used{$2}++ while $code =~ /^\s*(use|with|extends)\s+['"]?([\w:]+)['"]?/gm;
  while ($code =~ m{^\s*use\s+base\s+(?:qw.|(?:(?:['"]|q.|qq.)))([\w\s:]+)}gm) {
    $used{$_}++ for split ' ', $1;
  }

  return [keys %used];
}

=head1 AUTHOR

=over 4

=item * Jesse Vincent C<< <jesse at bestpractical.com> >>

=item * Alex Vandiver C<< <alexmv at bestpractical.com> >>

=item * Zev Benjamin C<< <zev at cpan.org> >>

=item * Erik Huelsmann C<< <erik at gmail.com> >>

=back

Please report any bugs or feature requests to
C<bug-test-dependencies at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Dependencies>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Dependencies::Light

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Dependencies>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Dependencies>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Dependencies>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Dependencies>

=back

=head1 LICENCE AND COPYRIGHT

    Copyright (c) 2016, Erik Huelsmann, All rights reserved.
    Copyright (c) 2007, Best Practical Solutions, LLC. All rights reserved.

    This module is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself. See perlartistic.

    DISCLAIMER OF WARRANTY

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
    REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
    TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
    CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
    SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
    RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
    FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
    SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
    DAMAGES.

=cut

1;
