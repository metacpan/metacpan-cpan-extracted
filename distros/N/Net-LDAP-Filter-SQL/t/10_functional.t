use strict;
use warnings;
use Test::More;
use Test::Deep;
use Net::LDAP::Filter::SQL;


#############################################################################################################################
# setup
#############################################################################################################################
sub filter { return new Net::LDAP::Filter::SQL(shift) }

sub like_sql { like(shift->sql_clause, shift, shift); }
sub has_vals { cmp_deeply(shift->sql_values, shift, shift); } 

#############################################################################################################################
# test the setup
#############################################################################################################################
my $s = filter("(&(!(foo=bar))(baz=fnord))");
isa_ok($s,'Net::LDAP::Filter::SQL');
like($s->as_string(), qr/\(&\(!\(foo=bar\)\)\(baz=fnord\)\)/, "as_string still works like expected");

#############################################################################################################################
# present test: ['foo is not null', [ ] ]
#############################################################################################################################
my $pr = filter("foo=*");

isa_ok($pr,'Net::LDAP::Filter::SQL');

like_sql($pr, qr/foo is not null/, "present test must produce correct SQL");
has_vals($pr, [], "present test must produce correct values");

#############################################################################################################################
# equality test: ['foo = ?', [ 'bar' ] ]
#############################################################################################################################
my $eq = filter("(foo=bar)");

isa_ok($eq,'Net::LDAP::Filter::SQL');

like_sql($eq, qr/foo = \?/, "equality test must produce correct SQL");
has_vals($eq, ['bar'], "equality test must produce correct values");

#############################################################################################################################
# AND logic test : ['foo = ? and baz = ?', [ 'bar', 'fnord' ] ]
#############################################################################################################################
my $and = filter("(&(foo=bar)(baz=fnord))");

isa_ok($and,'Net::LDAP::Filter::SQL');

like_sql($and, qr/\(foo = \?\) and \(baz = \?\)/, "logic AND test must produce correct SQL");
has_vals($and, ['bar','fnord'], "logic AND test must produce correct values");

#############################################################################################################################
# mixed logic test : ['foo = ? and (baz = ? or fii = ?)', [ 'bar', 'fnord', 'faa' ] ]
#############################################################################################################################
my $mix = filter("(&(foo=bar)(|(baz=fnord)(fii=faa)))");

isa_ok($mix,'Net::LDAP::Filter::SQL');

like_sql($mix, qr/\(foo = \?\) and \(\(baz = \?\) or \(fii = \?\)\)/, "logic AND test must produce correct SQL");
has_vals($mix, ['bar','fnord', 'faa'], "logic AND test must produce correct values");

#############################################################################################################################
# substring rtest : ['foo like ?', [ 'bar%'] ]
#############################################################################################################################
my $rstr = filter("foo=bar*");

isa_ok($rstr,'Net::LDAP::Filter::SQL');

like_sql($rstr, qr/foo like \?/, "substring rtest must produce correct SQL");
has_vals($rstr, ['bar%'], "substring rtest must produce correct values");

#############################################################################################################################
# substring ltest : ['foo like ?', [ '%bar'] ]
#############################################################################################################################
my $lstr = filter("foo=*bar");

isa_ok($lstr,'Net::LDAP::Filter::SQL');

like_sql($lstr, qr/foo like \?/, "substring ltest must produce correct SQL");
has_vals($lstr, ['%bar'], "substring ltest must produce correct values");

#############################################################################################################################
# substring lrtest : ['foo like ?', [ '%bar%'] ]
#############################################################################################################################
my $lrstr = filter("foo=*bar*");

isa_ok($lrstr,'Net::LDAP::Filter::SQL');

like_sql($lrstr, qr/foo like \?/, "substring lrtest must produce correct SQL");
has_vals($lrstr, ['%bar%'], "substring lrtest must produce correct values");

#############################################################################################################################
done_testing();
