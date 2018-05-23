package Pcore::Dist::CLI::Docker::Init;

use Pcore -class;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'create and link to the DockerHub repository',
        opt      => {
            namespace => {
                short => 'N',
                desc  => 'DockerHub repository namespace',
                type  => 'STR',
                isa   => 'Str',
            },
            name => {
                desc => 'DockerHub repository name',
                type => 'STR',
                isa  => 'Str',
            },
        },
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dist = $self->get_dist;

    $dist->build->docker->init($opt);

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Docker::Init - init docker repository

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
