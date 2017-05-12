use strict;
use warnings;
#use diagnostics;
use Test::More qw/tests 10/;
#use Test::More qw/no_plan/;

{
  package My::TX;

  use strict;
  use warnings;

  use TX;
  @My::TX::ISA=qw/TX/;

  our @attributes;
  BEGIN {
    # define attributes and implement accessor methods
    @attributes=(TX::attributes(), qw/p1 p2 _p3/);
    for( my $i=TX::attributes(); $i<@attributes; $i++ ) {
      my $method_num=$i;
      ## no critic
      no strict 'refs';
      *{__PACKAGE__.'::'.$attributes[$method_num]}=
	sub : lvalue {$_[0]->[$method_num]};
      ## use critic
    }
  }
  sub attributes {@attributes}
}

use constant {dbg=>0};
{
  my @wlog;
  my $sw;

  sub start_warnlog {
    $sw=$SIG{__WARN__};
    @wlog=();
    $SIG{__WARN__}=sub {
      print STDERR @_ if dbg;
      push @wlog, "@_";
    };
  }

  sub stop_warnlog {
    $SIG{__WARN__}=$sw;
    return @wlog;
  }
}

start_warnlog;
my $T=My::TX->new(p1=>10, p2=>20, _p3=>'not set', p4=>'invalid');
my $msg=(stop_warnlog)[0];
like( $msg, qr/_p3/, 'unknown key _p3' );
like( $msg, qr/p4/, 'unknown key p4' );

cmp_ok $T->p1, '==', 10, 'p1';
cmp_ok $T->p2, '==', 20, 'p2';
cmp_ok defined $T->_p3 ? '_p3' : 'undef', 'eq', 'undef', '_p3 not defined';

$T->_p3='defined';
cmp_ok $T->_p3, 'eq', 'defined', '_p3 set';

{
  no warnings qw/once/;
  *My::TX::init=sub {
    package My::TX;
    my ($I, %o)=@_;
    $I->_p3=delete $o{p3};
    @_=($I, %o);
    goto \&TX::init;
  };
}

start_warnlog;
$T=My::TX->new(p1=>100, p2=>200, _p3=>'not set',
	       p3=>'now valid', p4=>'still invalid');
$msg=(stop_warnlog)[0];
like( $msg, qr/_p3/, 'unknown key _p3' );
like( $msg, qr/p4/, 'unknown key p4' );

cmp_ok $T->_p3, 'eq', 'now valid', '_p3 initialized';

is_deeply $T->cache, {}, 'cache also initialized';

# Local Variables:
# mode: cperl
# End:
