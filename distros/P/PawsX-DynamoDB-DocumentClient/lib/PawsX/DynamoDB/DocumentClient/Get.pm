package PawsX::DynamoDB::DocumentClient::Get;

use strict;
use 5.008_005;

use PawsX::DynamoDB::DocumentClient::Util qw(make_arg_transformer unmarshal_attribute_map);

my $arg_transformer = make_arg_transformer(
    method_name => 'get',
    to_marshall => ['Key'],
);

sub transform_arguments {
    my ($class, %args) = @_;
    my $force_type = delete $args{force_type};
    return map
        {
            $_ => $arg_transformer->($_, $args{$_}, $force_type)
        }
        keys %args;
}

sub transform_output {
    my ($class, $output) = @_;
    my $item = $output->Item;
    return undef unless $item;
    return unmarshal_attribute_map($item);
}

sub run_service_command {
    my ($class, $service, %args) = @_;
    return $service->GetItem(%args);
}

1;
__END__
