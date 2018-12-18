package Pcore::Dist::CLI::Docker::Create;

use Pcore -class;
use Pcore::API::Docker::Hub qw[:DOCKERHUB_SOURCE_TYPE];

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'create autobuild tag',
        opt      => {
            type => {
                desc    => qq[scm tag type, allowed values: "$DOCKERHUB_SOURCE_TYPE_TAG", "$DOCKERHUB_SOURCE_TYPE_BRANCH"],
                type    => 'STR',
                isa     => [ $DOCKERHUB_SOURCE_TYPE_TAG, $DOCKERHUB_SOURCE_TYPE_BRANCH ],
                default => 'tag',
            },
            name => {
                desc => q[scm source tag name],
                type => 'STR',
                isa  => 'Str',
            },
            dockerfile_location => {
                desc    => q[Dockerfile location],
                type    => 'STR',
                isa     => 'Str',
                default => '/',
            },
        },
        arg => [
            tag => {
                desc => 'tag',
                isa  => 'Str',
            },
        ],
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dist = $self->get_dist;

    $dist->build->docker->create_tag( $arg->{tag}, $opt->{name} // $opt->{type}, $opt->{type}, $opt->{dockerfile_location} );

    $dist->build->docker->status;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Docker::Create - create autobuild tag

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
