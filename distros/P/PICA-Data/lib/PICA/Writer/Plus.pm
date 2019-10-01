package PICA::Writer::Plus;
use strict;
use warnings;

our $VERSION = '1.00';

use charnames qw(:full);

use parent 'PICA::Writer::Base';

sub SUBFIELD_INDICATOR { "\N{INFORMATION SEPARATOR ONE}" }
sub END_OF_FIELD       { "\N{INFORMATION SEPARATOR TWO}" }
sub END_OF_RECORD      { "\N{LINE FEED}"; }

sub write_subfield {
    my ($self, $code, $value) = @_;
    $self->{fh}->print($self->SUBFIELD_INDICATOR . $code . $value);
}

1;
__END__

=head1 NAME

PICA::Writer::Plus - Normalized PICA+ format serializer

=head2 DESCRIPTION

See L<PICA::Writer::Base> for synopsis and details.

The counterpart of this module is L<PICA::Parser::Plus>.

=cut
