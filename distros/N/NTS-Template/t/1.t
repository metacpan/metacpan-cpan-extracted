use strict;
use warnings;
use NTS::Template;

sub ok {
    my ($no,$ok) = @_;

    print "ok $no\n" if $ok;
    print "not ok $no\n" unless $ok;
    return $ok;
}

print "1..2\n";

my ($t,$vars,$out);

$vars->{test1} = "ok";
$vars->{test2}->{test2} = "ok";
$vars->{test3} = 3;

ok(1,$t = NTS::Template->new());

ok(2,$t->process({ templ_dir => "./t/templ", templ_file => "if.html", templ_vars => $vars,
    templ_extra => { source => 1, }}));
