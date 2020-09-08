#!perl
use 5.006;

use strict;
use warnings;

use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::Pod::Spelling;";
plan skip_all => "Test::Pod::Spelling required for testing POD spelling"
  if $@;

add_stopwords(
    qw(
      Mattijsen
      Tilly
      noexit
      modulino
      perldoc
      AnnoCPAN
      CPAN
      sym
      Symlinks
      cron
      )
);

TODO: {
    local $TODO = "Need to correct spelling mistakes";

    all_pod_files_spelling_ok();
}

done_testing();
exit;

__END__
