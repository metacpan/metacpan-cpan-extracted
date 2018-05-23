package Pcore::Dist::CLI::Smoke;

use Pcore -class;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'smoke your distribution',
        opt      => {
            author => {
                desc    => 'enables the AUTHOR_TESTING env variable (default behavior)',
                default => 0,
            },
            release => {
                desc    => 'enables the RELEASE_TESTING env variable',
                default => 0,
            },
            all => {    #
                short => undef,
                desc  => 'enables the RELEASE_TESTING, AUTOMATED_TESTING and AUTHOR_TESTING env variables',
            },
            jobs => {
                desc => 'number of parallel test jobs to run',
                isa  => 'PositiveInt',
            },
            verbose => { desc => 'enables verbose testing (TEST_VERBOSE env variable on Makefile.PL, --verbose on Build.PL' },
        },
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dist = $self->get_dist;

    exit 3 if !$dist->build->test( $opt->%*, smoke => 1 );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Smoke - smoke your distribution

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
