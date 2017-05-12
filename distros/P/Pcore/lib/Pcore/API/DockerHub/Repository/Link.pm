package Pcore::API::DockerHub::Repository::Link;

use Pcore -class;

with qw[Pcore::Util::Result::Status];

has repo => ( is => 'ro', isa => InstanceOf ['Pcore::API::DockerHub::Repository'], required => 1 );
has id      => ( is => 'ro', isa => Int, required => 1 );
has to_repo => ( is => 'ro', isa => Str, required => 1 );

sub remove ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    return $self->repo->api->request( 'delete', "/repositories/@{[$self->repo->id]}/links/$self->{id}/", 1, undef, $args{cb} );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::DockerHub::Repository::Link

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
