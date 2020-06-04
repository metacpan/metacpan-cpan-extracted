package PICA::Parser::JSON;
use strict;
use warnings;

our $VERSION = '1.07';

use JSON::PP;
our $JSON = JSON::PP->new;

use parent 'PICA::Parser::Base';

sub _next_record {
    my ($self) = @_;

    if ( my $line = $self->{reader}->getline ) {
        return $JSON->decode($line);
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

See L<PICA::Parser::Base> for synopsis and basic configuration.

The counterpart of this module is L<PICA::Writer::JSON>.

=cut
