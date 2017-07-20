package PawsX::DynamoDB::DocumentClient::Delete;

use strict;
use 5.008_005;

use PawsX::DynamoDB::DocumentClient::Util qw(make_arg_transformer unmarshal_attribute_map);

my $arg_transformer = make_arg_transformer(
    method_name => 'delete',
    to_marshall => ['ExpressionAttributeValues', 'Key'],
);

sub transform_arguments {
    my $class = shift;
    my %args = @_;
    return map { $_ => $arg_transformer->($_, $args{$_}) } keys %args;
}

sub transform_output {
    my ($class, $output) = @_;
    my $attributes = $output->Attributes;
    return undef unless $attributes;
    return unmarshal_attribute_map($attributes);
}

sub run_service_command {
    my ($class, $service, %args) = @_;
    return $service->DeleteItem(%args);
}

1;
__END__
