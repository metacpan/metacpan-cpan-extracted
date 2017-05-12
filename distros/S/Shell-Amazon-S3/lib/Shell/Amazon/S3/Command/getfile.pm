package Shell::Amazon::S3::Command::getfile;
use Moose;
use Path::Class qw(file);

extends 'Shell::Amazon::S3::CommandWithBucket';

has '+desc' => ( default => 'getfile <id> <file>' );

override 'validate_tokens', sub {
    my ( $self, $tokens ) = @_;
    if ( !@{$tokens} == 2 ) {
        return ( 0, "error: getfile <id> <file>" );
    }
    return ( 1, "" );
};

override 'parse_tokens', sub {
    my ( $self, $tokens ) = @_;
    my $args = {};
    $args->{key}      = $tokens->[0];
    $args->{filename} = $tokens->[1];
    $args;
};

sub execute {
    my ( $self, $args ) = @_;
    my $bucket = $self->bucket;

    my $key   = $args->{key};
    my $value = $bucket->get_key($key);

    my $result = '';
    if ($value) {
        my $filename = $args->{filename};
        my $fh       = file($filename)->openw;
        $fh->print( $value->{value} );
        $fh->close;
        $result .= "Got item '$key' as '$filename'\n";
    }
    else {
        $result .= "Couldn't get $key\n";
        $result .= $bucket->errstr . "\n";
    }

    $result;
}

1;
