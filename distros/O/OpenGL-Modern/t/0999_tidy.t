use strict;
use warnings;
use Test::InDistDir;
use Test::More 0.88;
use IO::All 0.86 -binary;
use lib "t/lib";

plan skip_all => "test requires Capture::Tiny and Perl::Tidy"
  if !eval { require Capture::Tiny && require Perl::Tidy };

plan skip_all => "test skipped due to \$ENV{SKIP_TIDY_TESTS}"
  if $ENV{SKIP_TIDY_TESTS};

run();

sub run {
    note "set \$ENV{SKIP_TIDY_TESTS} to skip these";
    eval { report_untidied_files() };
    pass;
    done_testing;
}

sub report_untidied_files {
    require PerlTidyCheck;

    return unless    #
      my @untidied =
      PerlTidyCheck::find_untidied_files( sub { grep !/^signatures.*XS.*sig.*\.pl$|NameLists.*\.pm$/, @_ } );

    my $report = join "",    #
      "found untidied files:", "\n\n", map( PerlTidyCheck::format_untidied_entry( $_ ), @untidied ), "\n";
    diag $report;

    return;
}
