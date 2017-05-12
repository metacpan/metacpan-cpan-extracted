use Test::Most;
use Net::LDAP::Filter::SQL;
use Data::Dumper;

my $ldapfilter = new Net::LDAP::Filter('(&(name=Homer)(city=Springfield))');

my $sqlfilter  = new Net::LDAP::Filter::SQL('(&(name=Marge)(city=Springfield))');
my $sqlfilter2 = Net::LDAP::Filter::SQL->new_from_data({ 'equalityMatch' => { 'assertionValue' => 'bar', 'attributeDesc' => 'foo' } });
my $sqlfilter3 = bless($ldapfilter,'Net::LDAP::Filter::SQL');

explain { clause => $sqlfilter->sql_clause, values => $sqlfilter->sql_values };
# $VAR1 = {
#           'clause' => '(name = ?) and (city = ?)',
#           'values' => [
#                         'Marge',
#                         'Springfield'
#                       ]
#         };

explain { clause => $sqlfilter2->sql_clause, values => $sqlfilter2->sql_values };
# $VAR1 = {
#           'clause' => 'foo = ?',
#           'values' => [
#                         'bar'
#                       ]
#         };


explain { clause => $sqlfilter3->sql_clause, values => $sqlfilter3->sql_values };
# $VAR1 = {
#           'clause' => '(name = ?) and (city = ?)',
#           'values' => [
#                         'Homer',
#                         'Springfield'
#                       ]
#         };


ok(1, "example run");
done_testing();
