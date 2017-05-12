
use Test::More tests => 3;
BEGIN { use_ok('Template::Process') };

my $tt = Template::Process->new();
isa_ok($tt, 'Template::Process');

my $tmpl = '[% a %] [% b %] [% FOREACH x = list %][% x %] [% END %]';
my @data = ( { a => 'A', b => 'B', list => [ qw(X1 X2) ] } );

my $out;
$tt->process(TT => \$tmpl, DATA => \@data, OUT => \$out);
#$tt->process(TT => \$tmpl, DATA => \@data, );

is($out, 'A B X1 X2 ');
