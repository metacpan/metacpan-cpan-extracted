use Test::More qw(no_plan);
use Template::Plugin::Chump;
use Template;
use Text::Chump;
use Data::Dumper;


sub uc { return uc $_[1] };
sub lc { return lc $_[1] };


my $tc = Text::Chump->new();
$tc->install('link',\&uc);
$tc->new_type('equal','=',\&lc,'simon');
$tc->new_type('nork',':',\&lc);

print Dumper $tc;


my $tt   = Template->new();
my $vars = {};
my $out;


$vars->{chump} = $tc;
my $expected = <<EOF;


HTTP://THEGESTALT.ORG
simon


=[SIMON|http://thegestalt.org]
:[SIMON|http://thegestalt.org]

EOF

ok($tt->process(\*DATA, $vars, \$out));
is($out,$expected); 


__DATA__
[% USE Chump ({ chump=>chump }) %]
[% FILTER chump %]
[foo|http://thegestalt.org]
=[SIMON|http://thegestalt.org]
[% END %]
[% FILTER chump ( {norks=>0, equals=>0} )%]
=[SIMON|http://thegestalt.org]
:[SIMON|http://thegestalt.org]
[% END %]
