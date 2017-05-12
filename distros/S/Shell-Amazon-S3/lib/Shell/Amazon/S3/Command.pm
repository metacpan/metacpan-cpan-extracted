package Shell::Amazon::S3::Command;
use Moose;
use MooseX::ClassAttribute;
use Net::Amazon::S3;
use Shell::Amazon::S3::ConfigLoader;

class_has 'api_' => (
    is       => 'rw',
    default  => sub {
        Shell::Amazon::S3::Command->setup_api;
    }
);

class_has 'bucket_name_' => (
    is  => 'rw',
    isa => 'Str',
);

has 'desc' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'No description',
);

# template method
sub do_execute {
    my ( $self,             $tokens )  = @_;
    my ( $is_check_success, $message ) = $self->check_pre_condition;
    return $message unless $is_check_success;

    my ( $is_validation_success, $validation_status_message )
        = $self->validate_tokens($tokens);
    return $validation_status_message unless $is_validation_success;

    my $args = $self->parse_tokens($tokens);
    return $self->execute($args);
}

sub check_pre_condition {
    my ( $self, $tokens ) = @_;
    return ( 1, "" );
}

sub validate_tokens {
    my ( $self, $tokens ) = @_;
    return ( 1, "" );
}

sub parse_tokens {
    my ( $self, $tokens ) = @_;
    die 'virtual method';
}

sub set_bucket_name {
    my ( $self, $bucket_name ) = @_;
    Shell::Amazon::S3::Command->bucket_name_($bucket_name);
}

sub get_bucket_name {
    Shell::Amazon::S3::Command->bucket_name_;
}

sub api {
    Shell::Amazon::S3::Command->api_;
}

sub bucket {
    my ($self) = shift;
    my $bucket = $self->api->bucket( $self->get_bucket_name );
    $bucket;
}

sub setup_api {
    my $self          = shift;
    my $config_loader = Shell::Amazon::S3::ConfigLoader->new;
    my $config        = $config_loader->load;
    my $api           = Net::Amazon::S3->new(
        {   aws_access_key_id     => $config->{aws_access_key_id},
            aws_secret_access_key => $config->{aws_secret_access_key},
        }
    );
    $api;
}

__PACKAGE__->meta->make_immutable;

1;
