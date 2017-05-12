package Shell::Amazon::S3::Command::host;
use Moose;

extends 'Shell::Amazon::S3::Command';

override 'validate_tokens', sub {
    my ( $self, $tokens ) = @_;
    return ( 0, "not implemented yet" );
};

override 'parse_tokens', sub {
    my ( $self, $tokens ) = @_;
    my $args = {};
    $args;
};

sub execute {
    my ( $self, $args ) = @_;
}

1;
