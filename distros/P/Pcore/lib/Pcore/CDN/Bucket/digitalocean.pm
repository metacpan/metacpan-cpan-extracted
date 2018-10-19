package Pcore::CDN::Bucket::digitalocean;

use Pcore -class;

extends qw[Pcore::CDN::Bucket::s3];

has edge_links => 0;    # generate edge links by default

has service => ( 's3', init_arg => undef );
has endpoint => ( 'digitaloceanspaces.com', init_arg => undef );
has prefix      => ( init_arg => undef );
has prefix_edge => ( init_arg => undef );
has s3          => ( init_arg => undef );    # InstanceOf['Pcore::API::S3']

sub BUILD ( $self, $args ) {
    $self->{prefix_edge} = "https://$self->{bucket}.$self->{region}.cdn.$self->{endpoint}";

    return;
}

sub get_url ( $self, $path ) {
    if ( $self->{edge_links} ) {
        return $self->{prefix_edge} . $path;
    }
    else {
        return $self->{prefix} . $path;
    }
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::CDN::Bucket::digitalocean

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
