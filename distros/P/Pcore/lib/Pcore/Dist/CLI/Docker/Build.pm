package Pcore::Dist::CLI::Docker::Build;

use Pcore -class;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'build image',
        opt      => {
            remove => {
                desc    => 'remove images after build',
                default => 0,
            },
            push => {
                desc    => 'push images after build',
                default => 1,
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

    my $res = $dist->build->docker->build_local( $arg->{tag}, $opt );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Docker::Build - build image

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
