package Net::PostcodeNL::WebshopAPI::Response;
use strict;

use parent 'Class::Accessor::Fast';

Net::PostcodeNL::WebshopAPI::Response->mk_accessors(
    qw/street city municipality province/,
    qw/postcode houseNumber houseNumberAddition houseNumberAdditions/,
    qw/surfaceArea purposes addressType/,
    qw/bagNumberDesignationId bagAddressableObjectId/,
    qw/rdX rdY longitude latitude/,
);

sub new {
    my ($class, $data) = @_;
    my $self = bless { %$data }, $class;
    return $self;
}

sub is_error {
    my $self = shift;
    return exists $self->{exception};
}

sub err_str {
    my $self = shift;
    return $self->{exception};
}

1;
