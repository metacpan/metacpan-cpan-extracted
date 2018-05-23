package Pcore::Dist::CLI::Docker::Ls;

use Pcore -class;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return { abstract => 'list DockerHub repositories builds', };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    require Pcore::Dist::Build::Docker;

    Pcore::Dist::Build::Docker->new->build_status;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Docker::Ls - list DockerHub repositories builds

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
