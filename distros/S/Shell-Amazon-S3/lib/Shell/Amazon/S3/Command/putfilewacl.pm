package Shell::Amazon::S3::Command::putfilewacl;
use Moose;
use Path::Class qw(file);

extends 'Shell::Amazon::S3::CommandWithBucket';

has '+desc' => ( default =>
        "putfilewacl <id> <file> ['private'|'public-read'|'public-read-write'|'authenticated-read']"
);

override 'validate_tokens', sub {
    my ( $self, $tokens ) = @_;
    if ( !@{$tokens} == 3 ) {
        return ( 0,
            "error: putfilewacl <id> <file> ['private'|'public-read'|'public-read-write'|'authenticated-read']"
        );
    }

    if ( @{$tokens} == 3 ) {
        my $acl = $tokens->[2];
        unless ( $self->is_valid_acl($acl) ) {
            return ( 0,
                "acl must be ['private'|'public-read'|'public-read-write'|'authenticated-read']"
            );
        }
    }

    return ( 1, '' );
};

override 'parse_tokens', sub {
    my ( $self, $tokens ) = @_;
    my $args = {};
    $args->{key}      = $tokens->[0];
    $args->{filename} = $tokens->[1];
    $args->{acl}      = $tokens->[2];
    $args;
};

sub is_valid_acl {
    my ( $self, $acl ) = @_;
    unless ( $acl eq 'private'
        || $acl eq 'public-read'
        || $acl eq 'public-read-write'
        || $acl eq 'authenticated-read' )
    {
        return 0;
    }
    return 1;
}

sub execute {
    my ( $self, $args ) = @_;
    my $bucket   = $self->bucket;
    my $key      = $args->{key};
    my $filename = $args->{filename};
    my $file     = file($filename);
    my $data     = $file->slurp;

    my $status = $bucket->add_key( $key, $data );

    my $acl = $args->{acl};
    my $is_success = $bucket->set_acl( { acl_short => $acl, key => $key, } );

    # TODO: error handling
    my $result = '';
    $result .= "Uploaded: $key\n";

    $result;

}

1;
