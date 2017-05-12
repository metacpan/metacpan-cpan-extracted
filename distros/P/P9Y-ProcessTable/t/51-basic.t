use Devel::SimpleTrace;
use Test::Most tests => 5;
use P9Y::ProcessTable;

my @tbl;
die_on_fail;
lives_ok { @tbl = P9Y::ProcessTable->table } 'get table';
cmp_ok(@tbl, '>', 5, 'more than 5 processes');

my $p = P9Y::ProcessTable->process;
isa_ok($p, 'P9Y::ProcessTable::Process') || always_explain( P9Y::ProcessTable::Table->_process_hash($$) );

# neuter the ENV vars before posting
if ($p->has_environ) {
   delete $p->environ->{$_} for (keys %{ $p->environ });
}
always_explain $p;
ok($p, 'process exists');

lives_ok { $p->refresh } 'refresh works';
