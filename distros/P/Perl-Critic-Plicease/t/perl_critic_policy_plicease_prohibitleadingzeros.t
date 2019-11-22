use Test2::V0 -no_srand => 1;
use Perl::Critic::TestUtils qw( pcritique );

my @ok = (
  q{chmod 0200, "filename";},
  q{chmod(0200, "filename");},
  q{chmod 0000, "filename";},
  q{chmod oct(200), "filename";},
  q{mkpath "/foo/bar/baz", 1, 0755;},
  q{mkpath("/foo/bar/baz", 1, 0755);},
  q{mkpath("/foo/bar/baz", 1, 0000);},
  q{mkpath("/foo/bar/baz", 1, oct(700));},
  q{dir()->mkpath(1, 0700);},
  q{$data->mkpath(0,0700);},
);

my @not_ok = (
# q{chmod 200, "filename";},
# q{chmod "0200", "filename";},
# q{chmod oct(0200), "filename";},
  q{$x = 0100;},
);

my $policy = 'Perl::Critic::Policy::Plicease::ProhibitLeadingZeros';

for my $i ( 0 .. $#ok )
{
  my $violation_count = pcritique($policy, \$ok[$i]);
  is $violation_count, 0, "nothing wrong with : $ok[$i]";
}

for my $i ( 0 .. $#not_ok)
{
  my $violation_count = pcritique($policy, \$not_ok[$i]);
  is $violation_count, 1, "is not ok :          $not_ok[$i]";
}

done_testing;

