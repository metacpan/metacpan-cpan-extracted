package Pcore::API::DockerHub::Repository::Build;

use Pcore -class, -const;

with qw[Pcore::Util::Result::Status];

has repo => ( is => 'ro', isa => InstanceOf ['Pcore::API::DockerHub::Repository'], required => 1 );

has build_status   => ( is => 'ro', isa => Int, required => 1 );
has dockertag_name => ( is => 'ro', isa => Str, required => 1 );
has created_date   => ( is => 'ro', isa => Str, required => 1 );
has last_updated   => ( is => 'ro', isa => Str, required => 1 );

has build_status_name => ( is => 'lazy', isa => Str, init_arg => undef );

const our $BUILD_STATUS_NAME => {
    -2 => 'Error',
    -1 => 'Error',
    0  => 'Queued',
    3  => 'Building',
    10 => 'Success',
};

sub _build_build_status_name ($self) {
    return $BUILD_STATUS_NAME->{ $self->{build_status} } // q[];
}

sub details ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    return $self->repo->api->request( 'get', "/repositories/@{[$self->repo->id]}/buildhistory/@{[$self->{build_code}]}/", 1, undef, $args{cb} );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::DockerHub::Repository::Build

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
