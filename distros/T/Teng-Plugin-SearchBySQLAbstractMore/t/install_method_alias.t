use t::Utils;
use Mock::Basic;
use Test::More;
use strict;
use warnings;

Mock::Basic->load_plugin('SearchBySQLAbstractMore');
{
	package Mock::Basic;
	use Teng::Plugin::SearchBySQLAbstractMore;
}
my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});

$db->install_sql_abstract_more(alias => 'search');
ok defined &Mock::Basic::search, 'search';

$db->install_sql_abstract_more(pager => 'Pager', alias => 'search_complex');
ok defined &Mock::Basic::search_complex, 'search_complex';
ok defined &Mock::Basic::search_complex_with_pager, 'search_complex_with_pager';

$db->install_sql_abstract_more(pager => 'Pager', alias => 'search_complex', pager_alias => 'sp');
ok defined &Mock::Basic::search_complex, 'search_complex';
ok defined &Mock::Basic::sp, 'sp';

done_testing;
