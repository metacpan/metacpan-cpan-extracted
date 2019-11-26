package Pcore::Dist::CLI::Test;

use Pcore -class;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'test your distribution',
        opt      => {
            author  => { desc => 'enables the AUTHOR_TESTING env variable (default behavior)', default => 1 },
            release => { desc => 'enables the RELEASE_TESTING env variable', },
            smoke   => { desc => 'enables the AUTOMATED_TESTING env variable', },
            all     => { desc => 'enables the RELEASE_TESTING, AUTOMATED_TESTING and AUTHOR_TESTING env variables', },
            jobs    => { desc => 'number of parallel test jobs to run', isa => 'PositiveInt' },
            verbose => { desc => 'enables verbose testing (TEST_VERBOSE env variable on Makefile.PL, --verbose on Build.PL' },
            keep => {
                desc    => 'keep temp build dir',
                default => 0,
            },
        },
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dist = $self->get_dist;

    exit 3 if !$dist->build->test( $opt->%* );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Test - test your distribution

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
