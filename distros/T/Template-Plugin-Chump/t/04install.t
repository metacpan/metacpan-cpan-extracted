use Test::More qw(no_plan);
use Template::Plugin::Chump;
use Template;

my $tt   = Template->new({});
my $vars = {};
my $out;


$vars->{uc} = sub { return sub { return uc $_[1] } };
$vars->{lc} = sub { return sub { return lc $_[1] } };
my $expected = <<EOF;

HTTP://THEGESTALT.ORG
simon

EOF

ok($tt->process(\*DATA, $vars, \$out));
is($out,$expected); 


__DATA__
[% USE Chump; Chump.install('link', uc); Chump.install('link',lc,'simon'); FILTER chump %]
[MUTTLEY|http://thegestalt.org]
[SIMON|http://thegestalt.org]
[% END %]
