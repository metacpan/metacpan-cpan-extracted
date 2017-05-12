package Shell::Amazon::S3::Command::exit;
use Moose;

extends 'Shell::Amazon::S3::Command';

has 'desc' => (
    +default => 'exit',
);

sub parse_tokens {
    my ($self, $token) = @_;
    return $token;
}

sub execute {
    my ($self, $args) = @_;
    return 'EXIT';
}

1;
