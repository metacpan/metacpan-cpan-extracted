use FindBin;
use lib $FindBin::Bin;
use nmsgtest;

use Test::More tests => 296;

use File::Temp;

use constant MSGTYPE_CLASS => 'Net::Nmsg::Msg::base::email';

use_ok(IO_CLASS);
use_ok(OUTPUT_CLASS);
use_ok(INPUT_CLASS);
use_ok(MSG_CLASS);

use Net::Nmsg::Util qw( :sniff );

my($count, $total) = (0, 20);

my %template = (
  srcip   => '127.0.0.1',
  srchost => 'localhost.localdomain',
  helo    => 'helo',
  from    => 'foo@bar.example.com',
  rcpt    => [qw(
    bar%d@baz.example.com
    baz%d@baz.example.com
  )],
);

sub _result_ok {
  my($m, $i) = @_;
  isa_ok($m, MSGTYPE_CLASS);
  for my $f (qw( type helo srchost srcip from )) {
    my $meth = "get_$f";
    is($m->$meth, $template{$f}, "msg[$i] $f");
  }
  my @tgt = map { sprintf($_, $i) } @{$template{rcpt}};
  my @src = $m->get_rcpt;
  is_deeply(\@src, \@tgt, "msg[$i] rcpt");
}

sub _new_ok {
  my $class = shift;
  my $obj = $class->new(@_);
  isa_ok($obj, $class, 'new');
  $obj;
}

my $fh   = File::Temp->new;
my $file = $fh->filename;

my $o = _new_ok(OUTPUT_CLASS);
$o->open_file($fh);
ok($o->opened, "output opened");
my $m = _new_ok(MSGTYPE_CLASS);
for my $i (0 .. $total-1) {
  $m->set_type($template{type});
  $m->set_helo($template{helo});
  $m->set_srchost($template{srchost});
  $m->set_srcip($template{srcip});
  $m->set_from($template{from});
  $m->set_rcpt(map { sprintf($_, $i) } @{$template{rcpt}});
  $o->write($m);
  ++$count;
}
$o->close;
is($count, $total, "output count");
ok(is_nmsg_file($file), "output is nmsg format");

my $i = _new_ok(INPUT_CLASS);
$i->open_file($file);
ok($i->opened, "input opened");

$count = 0;
while (my $m = $i->read) {
  _result_ok($m, $count);
  ++$count;
}
is($count, $total, "msg count");

$count = 0;
my $io = _new_ok(IO_CLASS);
$io->add_input($file);
$io->add_output(sub {
  _result_ok(shift, $count);
  ++$count;
});
my @inputs  = $io->inputs;
my @outputs = $io->outputs;
is(scalar @inputs,  1, "input count");
is(scalar @outputs, 1, "output count");
$io->loop;
is($count, $total, "io msg count");
