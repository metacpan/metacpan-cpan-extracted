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

ok(1,$t = NTS::Template->new());

ok(2,$t->process({ templ_dir => "./t/templ", templ_file => "mat.html", templ_vars => $vars,
    templ_extra => { source => 1, }}));
