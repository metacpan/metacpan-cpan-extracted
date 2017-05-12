package Shell::Amazon::S3::Command::get;
use Moose;

extends 'Shell::Amazon::S3::CommandWithBucket';

override 'validate_tokens', sub {
    my ( $self, $tokens ) = @_;
    if ( !@{$tokens} == 1 ) {
        return ( 0, "error: get <id>" );
    }
    return ( 1, '' );
};

override 'parse_tokens', sub {
    my ( $self, $tokens ) = @_;
    my $args = {};
    $args->{key} = $tokens->[0];
    $args;
};

sub execute {
    my ( $self, $args ) = @_;
    my $bucket = $self->bucket;
    my $key    = $args->{key};

    my $value  = $bucket->get_key($key);
    my $result = '';
    if ($value) {
        $result .= $value->{value} . "\n";
    }
    else {
        $result .= "couldn't get $key\n";
        $result .= $bucket->errstr . "\n";
    }
    $result;
}

1;
