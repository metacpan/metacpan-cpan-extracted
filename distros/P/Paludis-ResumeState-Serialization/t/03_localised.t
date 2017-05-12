use strict;
use warnings;

use Test::More 0.96;
use IO::Uncompress::Gunzip qw( gunzip );
use Paludis::ResumeState::Serialization::Grammar;

my (%files) = (
  'resume-1293352490.gz'     => 46,
  'resume-1293483679.gz'     => 34,
  'resumefile-1293138973.gz' => 34,
);

my $grammar = Paludis::ResumeState::Serialization::Grammar->grammar();

my %classes;

for ( keys %files ) {
  gunzip "t/tfiles/$_", \my $data;
  my $callback_called;
  local $Paludis::ResumeState::Serialization::Grammar::CLASS_CALLBACK = sub {
    $classes{ ( shift(@_) ) }++;
    $callback_called++;
  };
  ok( $data =~ $grammar, "$_ matches the grammar(+callback)" );
  is( $callback_called, $files{$_}, "Callback was called expected $files{$_} times" );
}
is_deeply(
  \%classes,
  {
    JobSkippedState   => 3,
    FetchJob          => 17,
    InstallJob        => 17,
    PretendJob        => 17,
    JobFailedState    => 8,
    JobLists          => 3,
    JobSucceededState => 23,
    ResumeData        => 3,
    JobList           => 6,
    JobRequirement    => 17
  },
  "Callbacks can properly track classes"
);
done_testing();
