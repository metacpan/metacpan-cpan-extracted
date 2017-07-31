package PawsX::DynamoDB::DocumentClient::Query;

use strict;
use 5.008_005;

use aliased 'PawsX::DynamoDB::DocumentClient::QueryOrScan';

use PawsX::DynamoDB::DocumentClient::Util qw(
    make_arg_transformer
);

my $arg_transformer = make_arg_transformer(
    method_name => 'query',
    to_marshall => QueryOrScan->to_marshall,
);

sub transform_arguments {
    my $class = shift;
    my %args = @_;
    my $force_type = delete $args{force_type};
    return map
        {
            $_ => $arg_transformer->($_, $args{$_}, $force_type)
        }
        keys %args;
}

sub transform_output {
    my $class = shift;
    return QueryOrScan->transform_output(@_);
}

sub run_service_command {
    my ($class, $service, %args) = @_;
    return $service->Query(%args);
}

1;
__END__
