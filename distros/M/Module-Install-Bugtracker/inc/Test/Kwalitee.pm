#line 1
use strict;
use warnings;
package Test::Kwalitee; # git description: v1.26-10-gb95ec58
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Test the Kwalitee of a distribution before you release it
# KEYWORDS: testing tests kwalitee CPANTS quality lint errors critic

our $VERSION = '1.27';

use Cwd ();
use Test::Builder 0.88;
use Module::CPANTS::Analyse 0.92;

use parent 'Exporter';
our @EXPORT_OK = qw(kwalitee_ok);

my $Test;
BEGIN { $Test = Test::Builder->new }

sub import
{
    my ($class, @args) = @_;

    # back-compatibility mode!
    if (@args % 2 == 0)
    {
        $Test->level($Test->level + 1);
        my %args = @args;
        my $result = kwalitee_ok(@{$args{tests}});
        $Test->done_testing;
        return $result;
    }

    # otherwise, do what a regular import would do...
    $class->export_to_level(1, @_);
}

sub kwalitee_ok
{
    my (@tests) = @_;

    warn "These tests should not be running unless AUTHOR_TESTING=1 and/or RELEASE_TESTING=1!\n"
        # this setting is internal and for this distribution only - there is
        # no reason for you to need to circumvent this check in any other context.
        # Please DO NOT enable this test to run for users, as it can fail
        # unexpectedly as parts of the toolchain changes!
        unless $ENV{_KWALITEE_NO_WARN} or $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING}
            or (caller)[1] =~ m{^(?:\.[/\\])?xt\b}
            or ((caller)[0]->isa(__PACKAGE__) and (caller(1))[1] =~ m{^(?:\.[/\\])?xt\b});

    my @run_tests = grep { /^[^-]/ } @tests;
    my @skip_tests = map { s/^-//; $_ } grep { /^-/ } @tests;

    # These don't really work unless you have a tarball, so skip them
    push @skip_tests, qw(extractable extracts_nicely no_generated_files
        has_proper_version has_version manifest_matches_dist);

    # MCA has a patch to add 'needs_tarball', 'no_build' as flags
    my @skip_flags = qw(is_extra is_experimental needs_db);

    my $basedir = Cwd::cwd;

    my $analyzer = Module::CPANTS::Analyse->new({
        distdir => $basedir,
        dist    => $basedir,
        # for debugging..
        opts => { no_capture => 1 },
    });

    my $ok = 1;

    for my $generator (@{ $analyzer->mck->generators })
    {
        $generator->analyse($analyzer);

        for my $indicator (sort { $a->{name} cmp $b->{name} } @{ $generator->kwalitee_indicators })
        {
            next if grep { $indicator->{$_} } @skip_flags;

            next if @run_tests and not grep { $indicator->{name} eq $_ } @run_tests;

            next if grep { $indicator->{name} eq $_ } @skip_tests;

            my $result = _run_indicator($analyzer->d, $indicator);
            $ok &&= $result;
        }
    }

    return $ok;
}

sub _run_indicator
{
    my ($dist, $metric) = @_;

    my $subname = $metric->{name};
    my $ok = 1;

    $Test->level($Test->level + 1);
    if (not $Test->ok( $metric->{code}->($dist), $subname))
    {
        $ok = 0;
        $Test->diag('Error: ', $metric->{error});

        # NOTE: this is poking into the analyse structures; we really should
        # have a formal API for accessing this.

        # attempt to print all the extra information we have
        my @details;
        push @details, $metric->{details}->($dist)
            if $metric->{details} and ref $metric->{details} eq 'CODE';
        push @details,
            (ref $dist->{error}{$subname}
                ? @{$dist->{error}{$subname}}
                : $dist->{error}{$subname})
            if defined $dist->{error} and defined $dist->{error}{$subname};
        $Test->diag("Details:\n", join("\n", @details)) if @details;

        $Test->diag('Remedy: ', $metric->{remedy});
    }
    $Test->level($Test->level - 1);

    return $ok;
}

1;

__END__

#line 450
