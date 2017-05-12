use strict;
use warnings;
use t::Utils;
use Mock::Basic;
use Test::More;
Mock::Basic->load_plugin('SearchBySQLAbstractMore');

Mock::Basic->sql_abstract_more_new_option(sql_dialect => 'OLD_MYSQL');
eval {
    Mock::Basic->sql_abstract_more_instance;
};
like $@, qr/^no such sql dialect/, 'no such sql dialect';
undef $@;
Mock::Basic->sql_abstract_more_new_option(sql_dialect => 'MySQL_old');
is ref Mock::Basic->sql_abstract_more_instance, 'SQL::Abstract::More', 'SQL::Abstract::More object';

done_testing;
