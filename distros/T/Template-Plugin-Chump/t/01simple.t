use Test::More qw(no_plan);
use Template::Plugin::Chump;
use Template;

my $tt   = Template->new({});
my $vars = {};
my $out;

my $expected = <<EOF;

<a href='http://thegestalt.org/' >http://thegestalt.org</a>
<a href='http://thegestalt.org' >foo</a>
<img src='http://thegestalt.org/scr/images/scr.jpg' alt='bar' title='bar' border='0' />

EOF

ok($tt->process(\*DATA, $vars, \$out));
is($out,$expected); 


__DATA__
[% USE Chump; FILTER chump %]
http://thegestalt.org
[foo|http://thegestalt.org]
+[http://thegestalt.org/scr/images/scr.jpg|bar]
[% END %]
