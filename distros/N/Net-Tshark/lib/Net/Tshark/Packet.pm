package Net::Tshark::Packet;
use strict;
use warnings;

our $VERSION = '0.04';

use XML::Simple;
use base 'Net::Tshark::Field';

sub new
{
    my ($class, $string) = @_;
    return if !defined $string;

    # Parse the string as PDML (Packet Description Markup Language)
    my $parsed_xml = XMLin($string, ForceArray => 1, KeyAttr => 0);

    # Tie a new hash to this package so we can access parts of the parsed
    # PDML using hash notation (e.g. $packet->{ip}). Note that the TIEHASH
    # subroutine does the actual construction of the object.
    my $self = $class->SUPER::new($parsed_xml);
    return bless $self, $class;
}

sub received_time
{
    my ($self) = @_;
    return $self->{frame}->{time_relative};
}

# Avoid having to check for the defined-ness of fields by simply
# passing in an array of field names and returning undef if any
# are not defined
sub get
{
    my ($self, @field_names) = @_;

    my $value = $self;
    foreach my $field_name (@field_names)
    {
        $value = $value->{$field_name};
        last if !defined $value;
    }

    return $value;
}

1;

__END__
