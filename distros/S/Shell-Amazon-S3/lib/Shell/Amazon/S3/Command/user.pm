package Shell::Amazon::S3::Command::user;
use Moose;

extends 'Shell::Amazon::S3::Command';

override 'validate_tokens', sub {
    my ( $self, $tokens ) = @_;
    if( @{$tokens} != 1) {
        return (0, "error: user <aws access key id>");
    }
    return ( 1, "" );
};

override 'parse_tokens', sub {
    my ( $self, $tokens ) = @_;
    my $args = {};
    $args->{aws_access_key_id} = $tokens->[0];
    $args;
};

sub execute {
    my ( $self, $args ) = @_;
    my $config_loader = Shell::Amazon::S3::ConfigLoader->instance;
    $config_loader->update( 'aws_access_key_id', $args->{aws_access_key_id} );

    $self->setup_api;
    return 'Updated accecc key id';
}

1;
