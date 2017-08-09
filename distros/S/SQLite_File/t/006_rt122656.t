use lib '../lib';
use Test::More;
use Test::Exception;
use File::Spec;
use DBM_Filter;
use SQLite_File;

my $dir = -d 't' ? 't' : '.';
my $db_name = File::Spec->catfile($dir,'test_f.db');
{
  my %db;
  ok my $db = tie(%db, 'SQLite_File', $db_name), 'tie';
  isa_ok $db, 'Tie::Hash';
  isa_ok $db, 'Tie::Array';
  can_ok $db, qw/filter_store_key filter_store_value
		 filter_fetch_key filter_fetch_value/;
  lives_ok { $db->filter_store_key( sub { $_ } ) };
  $db->filter_store_key();
  dies_ok { $db->filter_fetch_key( "boog" ) };

  $db->Filter_Push(Store => sub { $_.="boog" },
		   Fetch => sub { s/boog$// } );
  $db{a} = 'hey';
  is $db{a}, 'hey'; ### issue here ; not performing filtering right
}
{
  my %db;
  ok my $db = tie(%db, 'SQLite_File', $db_name), 'tie (2)';
  ok !defined( $db{a} );
  is $db{aboog}, 'heyboog';
}
unlink $db_name;
done_testing;
