package PICA::Writer::Plain;
use strict;
use warnings;

our $VERSION = '1.06';

use charnames qw(:full);

use parent 'PICA::Writer::Base';

sub SUBFIELD_INDICATOR {'$' }
sub END_OF_FIELD       { "\n" }
sub END_OF_RECORD      { "\n" }

sub write_subfield {
    my ($self, $code, $value) = @_;
    $value =~ s/\$/\$\$/g;
    $self->{fh}->print($self->SUBFIELD_INDICATOR . $code . $value);
}

1;
__END__

=head1 NAME

PICA::Writer::Plain - Plain PICA+ format serializer

=head2 DESCRIPTION

See L<PICA::Writer::Base> for synopsis and details.

The counterpart of this module is L<PICA::Parser::Plain>.

=cut
