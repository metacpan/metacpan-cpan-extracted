use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::RealBin/../lib";
BEGIN { eval { require PPI; 1 } or plan skip_all => 'PPI not installed: optional parser integration test'; }
use Perl::CodeMap;
my $map=Perl::CodeMap->new(root=>"$FindBin::RealBin/../examples/sample",parser=>'ppi');
my $data=$map->analyze;
my %names=map { $_->{path} => $_ } @{$data->{pkgs}};
ok($names{'Demo::App'},'PPI discovers package');
ok(grep($_->{n} eq 'start',@{$names{'Demo::App'}{files}[0]{funcs}}),'PPI discovers subroutine');
ok(grep($_ eq 'Demo::Web',@{$names{'Demo::App'}{imports}}),'PPI discovers include');
is($data->{parser},'ppi','PPI used');
done_testing;
