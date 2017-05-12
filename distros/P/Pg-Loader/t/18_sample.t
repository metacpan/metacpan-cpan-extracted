use Test::More qw( no_plan );
use Test::Exception;
use Pg::Loader::Misc_2 qw /sample_config /;
use v5.8;

my $_ = sample_config;
my @lines  = split/\n/,$_ ;

ok  @lines > 3;
ok  2<  grep { /\[\w{2,}\]/ } @lines;
ok  grep { /copy_columns/io } @lines;
ok  grep { /filename/io } @lines;
