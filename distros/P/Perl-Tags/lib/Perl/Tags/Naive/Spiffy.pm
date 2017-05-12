package Perl::Tags::Naive::Spiffy;

use strict; use warnings;
use parent 'Perl::Tags::Naive';

our $VERSION = '0.32';

=head2 C<get_parsers>

The following parsers are defined by this module.

=over 4

=cut

sub get_parsers
{
	my $self = shift;
	return (
		$self->SUPER::get_parsers(),
		$self->can('field_line'),
		$self->can('stub_line'),
	);
}

=item C<field_line>

Parse the declaration of a Spiffy class accessor method, returning a L<Perl::Tags::Tag::Field> if found.

=cut

sub field_line {
    my ($self, $line, $statement, $file) = @_;
    if ($statement=~/field\s+["']?(\w+)\b/) {
        return (
            Perl::Tags::Tag::Field->new(
                name => $1,
                file => $file,
                line => $line,
                linenum => $.,
            )
        );
    }
    return;
}

=item C<stub_line>

Parse the declaration of a Spiffy stub method, returning a L<Perl::Tags::Tag::Stub> if found.

=cut

sub stub_line {
    my ($self, $line, $statement, $file) = @_;
    if ($statement=~/stub\s+["']?(\w+)\b/) {
        return (
            Perl::Tags::Tag::Stub->new(
                name => $1,
                file => $file,
                line => $line,
                linenum => $.,
            )
        );
    }
    return;
}

=back

=head1 C<Perl::Tags::Tag::Field>

=head2 C<type>: Field

=cut

package Perl::Tags::Tag::Field;
our @ISA = qw/Perl::Tags::Tag/;

sub type { 'Field' }

=head1 C<Perl::Tags::Tag::Stub>

=head2 C<type>: Stub

=cut

package Perl::Tags::Tag::Stub;
our @ISA = qw/Perl::Tags::Tag/;

sub type { 'Stub' }

1;

=head1 AUTHOR and LICENSE

    dr bean - drbean at sign cpan a dot org
    osfameron (2006) - osfameron@gmail.com

For support, try emailing me or grabbing me on irc #london.pm on irc.perl.org

This was originally ripped off pltags.pl, as distributed with vim
and available from L<http://www.mscha.com/mscha.html?pltags#tools>
Version 2.3, 28 February 2002
Written by Michael Schaap <pltags@mscha.com>.

This is licensed under the same terms as Perl itself.  (Or as Vim if you +prefer).

=cut
