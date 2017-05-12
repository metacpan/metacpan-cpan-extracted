package Shell::Amazon::S3::Command::quit;
use Moose;

extends 'Shell::Amazon::S3::Command';

override 'parse_tokens', sub {
    my ($self, $token) = @_;
    return $token;
};

sub execute {
    my ($self, $args) = @_;
    return 'EXIT';
}

__PACKAGE__->meta->make_immutable;

1;
