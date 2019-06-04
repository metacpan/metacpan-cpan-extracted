package Pcore::Dist::CLI::Docker::Ls;

use Pcore -class;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return { abstract => 'show available DockerHub repository tags', };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dist = $self->get_dist;

    $dist->build->docker->ls;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Docker::Ls - show available DockerHub repository tags

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
