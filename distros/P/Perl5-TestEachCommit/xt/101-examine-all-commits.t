# xt/101-examine-all-commits.t
use 5.014;
use warnings;
use Perl5::TestEachCommit;
use Carp;
use File::Temp qw(tempfile tempdir);
use File::Spec::Functions;
use String::PerlIdentifier qw(make_varname);
use Data::Dump qw(dd pp);
use Capture::Tiny qw(capture_stdout);

use Test::More;
if( (! defined $ENV{SECONDARY_CHECKOUT_DIR}) or
    (! -d $ENV{SECONDARY_CHECKOUT_DIR} )
){
    plan skip_all => 'Could not locate git checkout of Perl core distribution';
}
elsif (! $ENV{PERL_AUTHOR_TESTING}) {
    plan skip_all => 'Lengthy test; set PERL_AUTHOR_TESTING to run';
}
else {
    plan tests => 13;
    #plan 'no_plan';
}

# NOTE:  The tests in this file depend on having a git checkout of the Perl
# core distribution on disk.  We'll skip all if that is not the case.  If that
# is the case, then set the path to that checkout in the envvar
# SECONDARY_CHECKOUT_DIR; example:
#
#   export SECONDARY_CHECKOUT_DIR=/home/username/gitwork/perl2
#
# Perl5::TestEachCommit will detect that and default to it for 'workdir' --
# which is why we'll be able to omit it from calls to new() in this file.

my $opts = {
    #workdir => "/tmp",
    branch  => "blead",
    start   => "c9cd2e0cf4ad570adf68114c001a827190cb2ee9",
    end     => "0dfa8ac113680e6acdef0751168ab231b9bf842c",
    configure_command => "sh ./Configure -des -Dusedevel 1>/dev/null",
    make_test_prep_command => "make test_prep 1>/dev/null",
    make_test_harness_command => "make test_harness 1>/dev/null",
    skip_test_harness => 1,
    verbose => 1,
};

{
    my $self = Perl5::TestEachCommit->new( $opts );
    ok($self, "new() returned true value");
    isa_ok($self, 'Perl5::TestEachCommit',
        "object is a Perl5::TestEachCommit object");

    note("Testing prepare_repository() ...");

    my $rv = $self->prepare_repository();
    ok($rv, "prepare_repository() returned true value");

    note("Testing get_commits() and display_commits() ...");

    my $expected_commits = [
      "c9cd2e0cf4ad570adf68114c001a827190cb2ee9",
      "79b32d926ef5961b4946ebe761a7058cb235f797",
      "0dfa8ac113680e6acdef0751168ab231b9bf842c",
    ];
    my $commits = $self->get_commits();
    is_deeply($commits, $expected_commits,
        "Got expected list of SHAs");

    my $stdout = capture_stdout {
        $rv = $self->display_commits();
    };
    ok($rv, "display_commits() returned true value");
    my @lines = split /\n/, $stdout;
    my @got_lines = ();
    for my $l (@lines) {
        push @got_lines, $l;
    }
    is_deeply([@got_lines], $expected_commits,
        "Displayed list of commits as expected");

    $self->examine_all_commits();
    my $expected_results = [
        { commit => "c9cd2e0cf4ad570adf68114c001a827190cb2ee9", score => 2 },
        { commit => "79b32d926ef5961b4946ebe761a7058cb235f797", score => 1 },
        { commit => "0dfa8ac113680e6acdef0751168ab231b9bf842c", score => 2 },
    ];
    my $results_ref = $self->get_results();
    is(ref($results_ref), 'ARRAY', "get_results() returned array ref");
    is_deeply($results_ref, $expected_results,
        "examine_all_commits() gave expected results");

    $stdout = capture_stdout {
        $rv = $self->display_results();
    };
    ok($rv, "display_results() returned true value");
    my @theselines = split /\n/, $stdout;
    like($theselines[0], qr/^.*? commit .*? score/x,
        "Got expected header from display_results");
    for my $datum (@theselines[2..$#theselines]) {
        like($datum, qr/^[a-f0-9]{40}\s\|\s{3}[0-3]/,
            "Got expected data from display_results");
    }
}



