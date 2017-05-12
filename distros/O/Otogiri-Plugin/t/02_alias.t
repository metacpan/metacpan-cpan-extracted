use strict;
use warnings;

use Test::More;
use Otogiri;
use Otogiri::Plugin;
use lib qw(./t/lib);

my $dbfile  = ':memory:';
my $db = Otogiri->new( connect_info => ["dbi:SQLite:dbname=$dbfile", '', ''] );

(ref $db)->load_plugin('TestPlugin', {
    alias => {
        very_useful_method_but_has_so_long_name => 'useful_method',
    },
});
ok( $db->can('useful_method') );
is( $db->useful_method(), 'long method name desune' );

done_testing;
