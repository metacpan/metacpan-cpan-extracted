use Test;
BEGIN { plan tests => 3 }

my $sock_no = `./pperl -Iblib/lib -Iblib/arch t/dickvd.plx`;
print "# Sockno: $sock_no\n";
ok($sock_no);

# now should try and open same socket
my $fhs = '';
for ($sock_no .. 13) {
  $fhs .= " $_<t/01basic.t";
}
$fhs .= " 3</dev/null 15<t/01basic.t 21<t/01basic.t";
my $new_sock_no = `./pperl -Iblib/lib -Iblib/arch t/dickvd.plx $fhs`;
print "# Sockno: $new_sock_no\n";

ok($new_sock_no);
ok($new_sock_no != $sock_no);

`./pperl -k t/dickvd.plx`;
