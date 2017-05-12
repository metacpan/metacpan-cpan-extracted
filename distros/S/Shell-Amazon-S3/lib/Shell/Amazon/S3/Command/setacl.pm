package Shell::Amazon::S3::Command::setacl;
use Moose;
use Perl6::Say;

extends 'Shell::Amazon::S3::Command';

has '+desc' => ( default =>
        "setacl ['bucket'|'item'] <id> ['private'|'public-read'|'public-read-write'|'authenticated-read']"
);

override 'validate_tokens', sub {
    my ( $self, $tokens ) = @_;
    if ( !@{$tokens} == 3 ) {
        return ( 0,
            "setacl ['bucket'|'item'] <id> ['private'|'public-read'|'public-read-write'|'authenticated-read']"
        );
    }

    my $object_type = $tokens->[0];
    unless ( $object_type eq 'bucket'
        || $object_type eq 'item' )
    {
        return ( 0, "object type must be ['bucket'|'item'] " );
    }
    my $acl = $tokens->[2];
    unless ( $self->is_valid_acl($acl) ) {

    }

    return ( 1, '' );
};

override 'parse_tokens', sub {
    my ( $self, $tokens ) = @_;
    my $args = {};
    $args->{object_type} = $tokens->[0];
    $args->{key}         = $tokens->[1];
    $args->{acl}         = $tokens->[2];
    $args;
};

sub execute {
    my ( $self, $args ) = @_;

    my $object_type = $args->{object_type};
    my $key         = $args->{key};
    my $acl         = $args->{acl};

    if ( $object_type eq 'bucket' ) {
        my $is_succeeded = $self->_set_acl_for_bucket( $key, $acl );
        return unless $is_succeeded;
    }
    else {
        return unless is_bucket_set();

        my $is_succeeded = $self->_set_acl_for_item( $key, $acl );
        return unless $is_succeeded;
    }
}

sub _set_acl_for_bucket {
    my ( $self, $bucket_name, $acl ) = @_;
    my $bucket = $self->bucket;
    my $is_success = $bucket->set_acl( { acl_short => $acl } );
    if ($is_success) {
        say 'success';
        return 1;
    }
    else {
        say $bucket->err . ": " . $bucket->errstr;
        return 0;
    }
}

sub _set_acl_for_item {
    my ( $self, $key, $acl ) = @_;
    my $bucket = $self->bucket;
    my $is_success = $bucket->set_acl( { acl_short => $acl, key => $key, } );
    if ($is_success) {
        say 'success';
        return 1;
    }
    else {
        say $bucket->err . ": " . $bucket->errstr;
        return 0;
    }
}

1;
