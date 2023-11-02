
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon # Test2::V0 etc.
  qw/t_like t_ok my_capture $silent $verbose $debug/;

package Inner;
our @ISA = ('Outer');
use Data::Dumper::Interp;
use Spreadsheet::Edit::Log qw/fmt_call log_call
                              nearest_call abbrev_call_fn_ln_subname/;

sub new { my $class=shift; bless {color => $_[0]}, $class }
sub get { my $self=shift; $self->{color} }
sub _pvt_noretval {
  my $self = shift;
  log_call {self => $self}, \@_;
}
sub _pvt_1retval {
  my $self = shift;
  log_call {self => $self}, \@_, 42;
}
sub _pvt_multiretval {
  my $self = shift;
  log_call {self => $self}, \@_, [42,99,{aaa=>100}];
}
sub func1 {
  log_call \@_, [\"z:",\"","ab",\"ccc",\"",99,{aaa=>100},\"there it was",99];
}

our %SpreadsheetEdit_Log_Options = (
  fmt_object => sub{
    my $obj = $_[1];
    if (eval{ $obj->can('get') }) {
      return addrvis($obj).'['.$obj->get().']';
    } else {
      return addrvis $obj;
    }
  },
);

package Outer;
sub new { my $class = shift; bless {inner=>Inner->new(@_)}, $class }
sub get              { my $self=shift; $self->{inner}->get(@_) }
sub meth_noretval    { my $self=shift; $self->{inner}->_pvt_noretval(@_); }
sub meth_1retval     { my $self=shift; $self->{inner}->_pvt_1retval(@_); }
sub meth_multiretval { my $self=shift; $self->{inner}->_pvt_multiretval(@_); }

package main;
use Spreadsheet::Edit::Log qw/nearest_call abbrev_call_fn_ln_subname/;

my $obj = Outer->new("red");
my $obj2 = Outer->new("blue");

sub checklog(&$;$$) {
  my ($code, $exptail, $test_label, $nohead) = @_;
  my ($file, $lno) = (caller(0))[1,2];
  $file = basename($file);
  my $exphead = $nohead ? "" : ">[${file}:${lno}] ";
  my $exp = ref($exptail) ? qr/\A\Q$exphead\E$exptail\n\z/
                          : $exphead.$exptail."\n";
  chomp( $test_label ||= $exp );
  my ($out, $err) = my_capture { $code->() };
  @_ = ($err, $exp, $test_label);
  unless ($out eq "") {
    &Test2::V0::like;
    warn "STDOUT was not empty:\n$out";
    @_ = (0, "STDOUT should be empty");
    goto &Test2::V0::ok;
  }
  goto &Test2::V0::like;  # show caller's line number
}

#### Test nearest_call & abbrev_call_fn_ln_subname used directly ####

sub _inner {
  my ($pkg,$fn,$lno,$subname) = @{ nearest_call() };
  my @abbr = abbrev_call_fn_ln_subname();
  warn ivis '$pkg $lno $subname abbrev=@abbr\n';
}
sub interm {
  &_inner;
}
sub foo {
  &interm;
}
checklog { &interm } '"main" '.__LINE__.' "main::interm" abbrev=("'.basename(__FILE__).'",'.__LINE__.',"interm")',"nerest_call() / abbrev_call_fn_ln_subname","NOHEAD";

#### Test log_call using our custom fmt_object callback ####

checklog { $obj->meth_noretval; } qr/Inner.*\[red\].meth_noretval/ ;
checklog { $obj2->meth_noretval } qr/Inner.*\[blue\].meth_noretval/ ;
checklog { $obj2->meth_noretval("A") } '.meth_noretval "A"' ;
checklog { $obj->meth_noretval(0,"0") } qr/Inner.*\[red\].meth_noretval 0,"0"/;
checklog { $obj->meth_noretval([3..7]) } '.meth_noretval [3,4,5,6,7]' ;

checklog { $obj->meth_1retval } '.meth_1retval() ==> 42' ;
checklog { $obj->meth_1retval("onearg") } '.meth_1retval "onearg" ==> 42' ;
checklog { $obj->meth_1retval("two", "args") } '.meth_1retval "two","args" ==> 42' ;

# log_call \@_, [\"z:",\"","ab",\"ccc",\"",99,{aaa=>100},\"there it was",99];
checklog { &Inner::func1("directcall") } 'func1 "directcall" ==> z:,"ab"ccc,99,{aaa => 100}there it was99' ;

#### Test log_call using the fallback default fmt_object ####
delete $Inner::SpreadsheetEdit_Log_Options{fmt_object};

my $obj_xx = Outer->new("purple");
checklog { $obj_xx->meth_noretval; } qr/<\d{3,}:[\da-fA-F]{3,}>\.meth_noretval/;
checklog { $obj_xx->meth_noretval; } qr/\.meth_noretval/;
checklog { $obj2->meth_1retval; } qr/<\d{3,}:[\da-fA-F]{3,}>\.meth_1retval\(\) ==> 42/;

done_testing();
exit 0;
