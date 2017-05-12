use Test::More;
use strict;
use PPM::Make::Search;

my $search = PPM::Make::Search->new();
ok($search);
is(ref($search), 'PPM::Make::Search');

my $dist = 'libnet';
my $mod = 'Net::FTP';
my %mode = ($dist => 'dist', $mod => 'mod');
foreach my $query( ($dist, $mod) ) {
  my @query = ($query);
  my $mode = $mode{$query};
  $search->search(\@query, mode => $mode); 
  my $key = $mode . '_results';
  my $results = $search->{$key};
  ok($results);
  is(ref($results), 'HASH');
  my $info = $results->{$query};
  ok($info);
  is(ref($info), 'HASH'); 
  is($info->{dist_name}, $dist);
  ok($info->{author} =~ /\w+/);
  ok($info->{cpanid} =~ /\w+/);
  ok($info->{dist_file} =~ /$dist/);
  if ($mode eq 'mod') {
    is($info->{mod_name}, $query);
    ok($info->{mod_vers} > 0);

  }
  else {
    ok($info->{dist_vers} > 0);
    my $flag = 0;
    my @mods = @{$info->{mods}};
    foreach (@mods) {
      if ($_->{mod_name} eq 'Net::FTP') {
        $flag = 1;
        last;
      }
    }
    ok($flag > 0);
  }
}

done_testing;
