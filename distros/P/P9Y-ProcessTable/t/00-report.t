use Test::Most tests => 1;
use P9Y::ProcessTable;
use B::Deparse;

always_explain {
   fields  => find_package( \&P9Y::ProcessTable::Table::fields  ),
   list    => find_package( \&P9Y::ProcessTable::Table::list    ),
   table   => find_package( \&P9Y::ProcessTable::Table::table   ),
   process => find_package( \&P9Y::ProcessTable::Table::process ),
   kill    => find_package( \&P9Y::ProcessTable::Process::kill  ),
};

ok(1);

sub find_package {
   my $bdp = B::Deparse->new;
   my $code = $bdp->coderef2text(shift);
   $code =~ /package ([\w:]+)/;
   return $1;
}