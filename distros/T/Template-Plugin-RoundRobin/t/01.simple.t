use strict;
use Test::More tests => 1;
use Template;

my $tt = Template->new({POST_CHOMP=>1, PRE_CHOMP=>1});
my $text = "Hello";
my $out = "";
$tt->process(\*DATA,{},\$out);
is($out, "aba");
print $out;

__END__
[% USE RoundRobin;
   SET rr = RoundRobin.new("a","b") %]
[% rr.next %]
[% rr.next %]
[% rr.next %]
