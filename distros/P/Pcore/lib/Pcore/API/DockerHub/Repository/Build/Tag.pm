package Pcore::API::DockerHub::Repository::Build::Tag;

use Pcore -class;
use Pcore::API::DockerHub qw[:CONST];

with qw[Pcore::Util::Result::Status];

has repo => ( is => 'ro', isa => InstanceOf ['Pcore::API::DockerHub::Repository'], required => 1 );
has id   => ( is => 'ro', isa => Int, required => 1 );
has name => ( is => 'ro', isa => Str, required => 1 );    # dockerhub tag name
has source_type => ( is => 'ro', isa => Enum [qw[Tag Branch]], required => 1 );
has source_name => ( is => 'ro', isa => Str, required => 1 );    # SCM tag / branch name

sub remove ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    return $self->repo->api->request( 'delete', "/repositories/@{[$self->repo->id]}/autobuild/tags/$self->{id}/", 1, undef, $args{cb} );
}

sub update ( $self, % ) {
    my %args = (
        cb                  => undef,
        name                => '{sourceref}',            # docker build tag name
        source_type         => $DOCKERHUB_SOURCE_TAG,    # Branch, Tag
        source_name         => '/.*/',                   # barnch / tag name in the source repository
        dockerfile_location => q[/],
        splice @_, 1,
    );

    return $self->repo->api->request(
        'put',
        "/repositories/@{[$self->repo->id]}/autobuilds/tags/$self->{id}/",
        1,
        {   id                  => $self->{id},
            name                => $args{name},
            source_type         => $Pcore::API::DockerHub::DOCKERHUB_SOURCE_NAME->{ $args{source_type} },
            source_name         => $args{source_name},
            dockerfile_location => $args{dockerfile_location},
        },
        $args{cb}
    );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::DockerHub::Repository::Build::Tag

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
