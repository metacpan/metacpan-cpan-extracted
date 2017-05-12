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


=[SIMON|http://thegestalt.org]
:[SIMON|http://thegestalt.org]

EOF

ok($tt->process(\*DATA, $vars, \$out));
is($out,$expected); 


__DATA__
[% USE Chump; Chump.install('link', uc) %]
[% Chump.new_type('equal','=',lc,'simon') %]
[% Chump.new_type('nork',':',lc) %]
[% FILTER chump %]
[foo|http://thegestalt.org]
=[SIMON|http://thegestalt.org]
[% END %]
[% FILTER chump ( {norks=>0, equals=>0} )%]
=[SIMON|http://thegestalt.org]
:[SIMON|http://thegestalt.org]
[% END %]
