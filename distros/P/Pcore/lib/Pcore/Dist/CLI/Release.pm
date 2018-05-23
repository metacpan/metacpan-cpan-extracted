package Pcore::Dist::CLI::Release;

use Pcore -class;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'release distribution',
        opt      => {
            major => {
                short => 'M',
                desc  => 'increment major version',
            },
            minor  => { desc => 'increment minor version', },
            bugfix => { desc => 'increment bugfix version', },
        },
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dist = $self->get_dist;

    exit 3 if !$dist->build->release( $opt->%* );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Release - release distribution

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
