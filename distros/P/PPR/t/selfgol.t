use strict;
use warnings;
no warnings 'void';

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}


plan tests => 1;

use PPR;

my $selfgol = <<'END_SELFGOL';

#!/usr/bin/perl -s
$;=$/;seek+DATA,undef$/,!$s;$_=<DATA>;$s&&print||(*{q;::\;
;}=sub{$d=$d-1?$d:$0;s;';\t#$d#;,$_})&&$g&&do{$y=($x||=20)*($y||8);sub
l{sleep&f}sub'p{print$;x$=,join$;,$b=~/.{$x}/g,$;}sub'f{pop||1}sub'n{substr($b,
&f%$y,3)=~tr,O,O,}sub'g{@_[
~~@_]=@_;--($f=&f);$m=substr($b,&f,1);($w,$w,$m,O)
[n($f-$x)+n($x+$f)-(${m}eq+O=>)+n$f]||$w}$w="\40";$b=join'',@ARGV?<>:$_,$w
x$y;$b=~s).)$&=~/\w/?O:$w)gse;substr($b,$y)=q++;$g='$i=0;$i?$b:$c=$b;
substr+$c,$i,1,g$i;$g=~s?\d+?($&+1)%$y?e;$i-$y+1?eval$g:do{$b=$c;p;l}';
sub'e{eval$g;&e};e}||eval||die+No.$;
__DATA__
$d&&do{{$^W=$|;*_=sub{$=+s=#([A-z])(.*)#=#$+$1#=g}}
@s=(q[$_=sprintf+pop@s,@s],";\n"->($_=q[
$d&&do{{$^W=$|;*_=sub{$=+s=#([A-z])(.*)#=#$+$1#=g}}'
@s=(q[%s],q[%s])x2;%s;print"\n"x&_,$_;l;eval};
]))x2;$_=sprintf+pop@s,@s;print"\n"x&_,$_;l;eval};$/=$y;$"=",";print
q<#!/usr/bin/perl -sw
!$s?do{>,$_=<>,q<}:do{@s=(q[printf+pop@s,@s],q[#!/usr/bin/perl -sw
!$s?do{>.(s$%$%%$g,y=[====y=]==||&d,$_).q<}:do{@s=(q[%s],q[%s])x2;%s}
])x2;printf+pop@s,@s}
>

END_SELFGOL

ok $selfgol =~ m{ \A (?&PerlDocument) \Z  $PPR::GRAMMAR }xms  => 'matched selfgol';

done_testing();

