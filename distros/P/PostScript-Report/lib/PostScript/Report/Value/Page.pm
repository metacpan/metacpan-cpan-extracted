#---------------------------------------------------------------------
package PostScript::Report::Value::Page;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 12 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Evaluate a page number expression
#---------------------------------------------------------------------

our $VERSION = '0.01';

use Moose;
use MooseX::Types::Moose qw(Str);

with 'PostScript::Report::Role::Value';


has value => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);

sub get_value
{
  my ($self, $rpt) = @_;

  my $text = $self->value;

  # Handle the following % codes:
  my %sub = (
    '%' => '%',
    'n' => $rpt->page_number,
    't' => $rpt->page_count,
  );

  # Substitute the % codes (unrecognized codes are unchanged):
  $text =~ s{\%(.)}{
    defined($sub{$1}) ? $sub{$1} : "\%$1"
  }ge;

  $text;
} # end get_value

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

PostScript::Report::Value::Page - Evaluate a page number expression

=head1 VERSION

This document describes version 0.01 of
PostScript::Report::Value::Page, released November 30, 2013
as part of PostScript-Report version 0.13.

=head1 DESCRIPTION

This L<Value|PostScript::Report::Role::Value> substitutes page numbers
into a string.

=for Pod::Coverage get_value

=head1 ATTRIBUTES

=head2 value

This string can contain the following C<%> codes, which will be
substituted when it is returned by C<get_value>.

=over

=item C<%n>

The current page number

=item C<%t>

The total number of pages in the report

=item C<%%>

A literal C<%> sign

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-PostScript-Report AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=PostScript-Report >>.

You can follow or contribute to PostScript-Report's development at
L<< https://github.com/madsen/postscript-report >>.

=head1 ACKNOWLEDGMENTS

I'd like to thank Micro Technology Services, Inc.
L<http://www.mitsi.com>, who sponsored development of
PostScript-Report, and fREW Schmidt, who recommended me for the job.
It wouldn't have happened without them.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
