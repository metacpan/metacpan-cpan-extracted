use Signals::XSIG;
use t::SignalHandlerTest;
use Test::More tests => 11;
use strict;
use warnings;

# we can override what Perl does with  $SIG{sig} = 'DEFAULT'
# by setting  $Signals::XSIG::Default::DEFAULT_BEHAVIOR{sig}.

my $R = '';
my $S = 0;
my %f = ();
my $sig = 'ALRM';
sub CLEAR { $R = '' };
for my $letter ('A' .. 'Z') {
  $f{$letter} = sub { $R .= $letter };
}

$Signals::XSIG::Default::DEFAULT_BEHAVIOR{$sig}
	= sub { $S++; $R = 'DEFAULT' };

##################################################################

$XSIG{$sig}[0] = \&CLEAR;
$XSIG{$sig}[1] = $f{'A'};
$XSIG{$sig}[2] = $f{'B'};
$XSIG{$sig}[3] = $f{'C'};

ok($S==0 && $R eq '', 'no signals trapped yet');
trigger($sig);
ok($S==0 && $R eq 'ABC', '$XSIG{sig}[idx] assignments respected');

delete $XSIG{$sig}[2];
trigger($sig);
ok($S==0 && $R eq 'AC', 'signal handler deleted');

$XSIG{$sig}[7] = $f{'T'};
trigger($sig);
ok($S==0 && $R eq 'ACT', 'signal handler added');


@{$XSIG{$sig}} = (\&CLEAR, 'DEFAULT', $f{F}, $f{O}, $f{O}, 'DEFAULT');
trigger($sig);
ok($S==1, "DEFAULT signal handler called once even if registered twice");
ok($R eq 'DEFAULTFOO', 
   "DEFAULT signal handler called only first time it is encountered");

$XSIG{$sig} = [ $f{B}, undef, $f{A}, 'IGNORE', undef, $f{R}, 'DEFAULT' ];
trigger($sig);
ok($S==2 && $R eq 'DEFAULT', '$XSIG{sig} default override respected');

push @{$XSIG{$sig}}, sub { chop $R; $R .= 'Z' };
trigger($sig);
ok($S==3 && $R eq 'DEFAULZ', 'append @{$XSIG{sig}} works');

##################################################################

# bogus functions should act like ignore.
$R = '';
$S = 0;
$XSIG{$sig} = [ $f{H}, $f{E}, \&bogus, $f{L}, $f{L}, undef, $f{O} ];
trigger($sig);
ok($S==0 && $R eq 'HELLO', '$XSIG{sig} with \&bogus function ok');

$XSIG{$sig} = [ $f{W}, $f{O}, 'bogus', $f{R}, $f{L}, 'DEFAULT', $f{D} ];
trigger($sig);
ok($S==1 && $R eq 'DEFAULTD', '$XSIG{sig} with \'bogus\' function ok');


# $SIG{sig}=*glob is an error on 5.8, but
# $XSIG{sig}[idx]=*glob is ok.
$XSIG{$sig} = [ $f{W}, *bogus, \&CLEAR, $f{F}, $f{O}, undef, $f{O} ];
trigger($sig);
ok($S==1 && $R eq 'FOO', '$XSIG{sig} with *bogus function ok');

##################################################################
