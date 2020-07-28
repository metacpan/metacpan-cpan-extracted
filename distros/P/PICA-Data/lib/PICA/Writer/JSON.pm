package PICA::Writer::JSON;
use v5.14.1;

our $VERSION = '1.14';

use Scalar::Util qw(reftype);
use JSON::PP;
use PICA::Data;

use parent 'PICA::Writer::Base';

sub write_record {
    my ($self, $record) = @_;

    my $json = $self->{json};
    unless ($json) {
        $json = JSON::PP->new(%$self);
        $json->$_($self->{$_})
            for grep {exists $self->{$_}}
            qw(pretty ascii latin1 utf8 indent space_before space_after canonical);
        $self->{json} = $json;
    }

    print {$self->{fh}} $json->encode(PICA::Data::TO_JSON($record));
    print {$self->{fh}} "\n" unless $json->get_indent;
}

1;
__END__

=head1 NAME

PICA::Writer::JSON - PICA JSON serializer

=head2 DESCRIPTION

Writes L<PICA JSON|http://format.gbv.de/pica/json>, newline delimited by
default.  See L<PICA::Writer::Base> for synopsis and basic configuration. In
addition the configuration field C<json> can be used to set an instance of
L<JSON::PP>, L<JSON>, or L<JSON::XS> to be used for encoding. Otherwise,
additional fields can be passed to the constructor of L<JSON::PP>, like this:

    PICA::Writer->new( pretty => 1 )

The counterpart of this module is L<PICA::Parser::JSON>.

=cut
