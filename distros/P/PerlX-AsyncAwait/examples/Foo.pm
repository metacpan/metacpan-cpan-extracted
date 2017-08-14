package Foo;

use strictures 2;
use PerlX::Generator::Runtime;
use PerlX::Generator::Compiler;

my $gen = generator {
  my ($max) = @_;
  warn "Generator started";
  yield $max;
  warn "Entering loop";
  foreach my $x (reverse 0..$max-1) {
    my $sent = yield $x;
    warn "Received $sent" if $sent;
  }
  warn "Generator exiting";
};

my $inv = $gen->start(5);

warn $inv->next;
warn $inv->next;
warn $inv->next('foo');
warn $inv->next;
warn $inv->next;
$inv->error('ARGH');
#warn $inv->next;
#warn $inv->next;
