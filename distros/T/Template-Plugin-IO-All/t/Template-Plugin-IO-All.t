use strict;
use Test::More tests => 5;
#use lib qw(lib);
use Template;
use Data::Dumper;
use IO::All;

my $outfile = 't/output';
my $tt = Template->new() or die $!;

ok($tt->process('t/template.tt', {}, \$_ ) || die $tt->error);
ok(/Line\t+submit/);
ok(m(File name\t+t/data));
ok(/Size\t+158/);
ok(m(t/Template-Plugin-IO-All.t));