package PICA::Parser::JSON;
use v5.14.1;

our $VERSION = '2.09';

use JSON::PP;
our $JSON = JSON::PP->new;

use parent 'PICA::Parser::Base';

sub _next_record {
    my ($self) = @_;

    if (my $line = $self->{reader}->getline) {
        my $record = $JSON->decode($line);
        $record = $record->{record} if ref $record eq 'HASH';

        return $record;

        # TODO: cleanup occurrence and annotation
    }
}

1;
__END__

=head1 NAME

PICA::Parser::JSON - PICA JSON parser

=head2 DESCRIPTION

This parser parses L<PICA JSON|http://format.gbv.de/pica/json> format. The
current implementation expects records to be on a line each (newline delimited
JSON), this may be extended to full JSON in a later version.

Records may also be given as object with field C<record>.

See L<PICA::Parser::Base> for synopsis and basic configuration.

The counterpart of this module is L<PICA::Writer::JSON>.

=cut
