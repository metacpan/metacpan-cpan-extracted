package PICA::Writer::Plus;
use v5.14.1;

our $VERSION = '2.05';

use charnames qw(:full);

use parent 'PICA::Writer::Base';

sub SUBFIELD_INDICATOR {"\N{INFORMATION SEPARATOR ONE}"}
sub END_OF_FIELD       {"\N{INFORMATION SEPARATOR TWO}"}
sub END_OF_RECORD      {"\N{LINE FEED}";}

sub write_start_field {
    my ($self, $field) = @_;

    $self->write_identifier($field);
    my $annotation = $self->annotation($field);
    $self->{fh}->print("$annotation" || " ");
}

1;
__END__

=head1 NAME

PICA::Writer::Plus - Normalized PICA+ format serializer

=head2 DESCRIPTION

See L<PICA::Writer::Base> for synopsis and details.

The counterpart of this module is L<PICA::Parser::Plus>.

=cut
