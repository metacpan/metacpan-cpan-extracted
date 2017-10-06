use strict;
use warnings;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}


use PPR;

my $neg = 0;
while (my $str = <DATA>) {
           if ($str =~ /\A# TH[EI]SE? SHOULD MATCH/) { $neg = 0;       next; }
        elsif ($str =~ /\A# TH[EI]SE? SHOULD FAIL/)  { $neg = 1;       next; }
        elsif ($str !~ /^####\h*\Z/m)                { $str .= <DATA>; redo; }

        $str =~ s/\s*^####\h*\Z//m;

        if ($neg) {
            ok $str !~ m/\A \s* (?&PerlDocument) \s* \Z   $PPR::GRAMMAR/xo => $str;
        }
        else {
            ok $str =~ m/\A \s* (?&PerlDocument) \s* \Z   $PPR::GRAMMAR/xo => $str;
        }
}

done_testing();

__DATA__
# THESE SHOULD MATCH...
no strict;
####
indirect $foo;
####
indirect_class_with_colon Foo::;
####
$bar->method_with_parentheses;
####
print SomeClass->method_without_parentheses + 1;
####
sub_call();
####
$baz->chained_from->chained_to;
####
a_first_thing a_middle_thing a_last_thing;
####
(first_list_element, second_list_element, third_list_element);
####
first_comma_separated_word, second_comma_separated_word, third_comma_separated_word;
####
single_bareword_statement;
####
{ bareword_no_semicolon_end_of_block }
$buz{hash_key};
####
fat_comma_left_side => $thingy;
####
$foo and'bar';
####
$foo cmp'bar';
####
$foo eq'bar';
####
$foo ge'bar';
####
$foo gt'bar';
####
$foo le'bar';
####
$foo lt'bar';
####
$foo ne'bar';
####
not'bar';
####
$foo or'bar';
####
$foo x'bar';
####
$foo xor'bar';
####
q'foo';
####
qq'foo';
####
qr'foo';
####
qw'foo';
####
qx'foo';
####
m'foo';
####
s'foo'bar';
####
tr'fo'ba';
####
y'fo'ba';
####
abs'3';
####
accept'1234',2345;
####
alarm'5';
####
atan2'5';
####
bind'5',"";
####
binmode'5';
####
bless'foo', 'bar';
####
break when 1;
####
caller'3';
####
chdir'foo';
####
chmod'0777', 'foo';
####
chomp'a';
####
chop'a';
####
chown'a';
####
chr'32';
####
chroot'a';
####
close'1';
####
closedir'1';
####
connect'1234',$foo;
####
continue;
####
cos'3';
####
crypt'foo', 'bar';
####
dbmclose'foo';
####
dbmopen'foo','bar';
####
default {}
defined'foo';
####
delete'foo';
####
die'foo';
####
do'foo';
####
dump'foo';
####
each'foo';
####
else {};
####
elsif {};
####
endgrent;
####
endhostent;
####
endnetent;
####
endprotoent;
####
endpwent;
####
endservent;
####
eof'foo';
####
eval'foo';
####
evalbytes'foo';
####
exec'foo';
####
exists'foo';
####
exit'foo';
####
exp'foo';
####
fc'foo';
####
fcntl'1';
####
fileno'1';
####
flock'1', LOCK_EX;
####
fork;
####
format
=
.
formline'@',1;
####
getc'1';
####
getgrent;
####
getgrgid'1';
####
getgrnam'foo';
####
gethostbyaddr'1', AF_INET;
####
gethostbyname'foo';
####
gethostent;
####
getlogin;
####
getnetbyaddr'1', AF_INET;
####
getnetbyname'foo';
####
getnetent;
####
getpeername'foo';
####
getpgrp'1';
####
getppid;
####
getpriority'1',2;
####
getprotobyname'tcp';
####
getprotobynumber'6';
####
getprotoent;
####
getpwent;
####
getpwnam'foo';
####
getpwuid'1';
####
getservbyname'foo', 'bar';
####
getservbyport'23', 'tcp';
####
getservent;
####
getsockname'foo';
####
getsockopt'foo', 'bar', TCP_NODELAY;
####
glob'foo';
####
gmtime'1';
####
goto'label';
####
hex'1';
####
index'1','foo';
####
int'1';
####
ioctl'1',1;
####
join'a',@foo;
####
keys'foo';
####
kill'KILL';
####
last'label';
####
lc'foo';
####
lcfirst'foo';
####
length'foo';
####
link'foo','bar';
####
listen'1234',10;
####
local'foo';
####
localtime'1';
####
lock'foo';
####
log'foo';
####
lstat'foo';
####
mkdir'foo';
####
msgctl'1','foo',1;
####
msgget'1',1;
####
msgrcv'1',$foo,1,1,1;
####
msgsnd'1',$foo,1;
####
my $foo;
####
next'label';
####
oct'foo';
####
open'foo';
####
opendir'foo';
####
ord'foo';
####
our $foo;
####
pack'H*',$data;
####
pipe'in','out';
####
pop'foo';
####
pos'foo';
####
print'foo';
####
printf'foo','bar';
####
prototype'foo';
####
push'foo','bar';
####
quotemeta'foo';
####
rand'1';
####
read'1',$foo,100;
####
readdir'1';
####
readline'1';
####
readlink'1';
####
readpipe'1';
####
recv'1',$foo,100,1;
####
redo'label';
####
ref'foo';
####
rename'foo','bar';
####
require'foo';
####
reset'f';
####
return'foo';
####
reverse'foo','bar';
####
rewinddir'1';
####
rindex'1','foo';
####
rmdir'foo';
####
say'foo';
####
scalar'foo','bar';
####
seek'1',100,0;
####
seekdir'1',100;
####
select'1';
####
semctl'1',1,1;
####
semget'foo',1,1;
####
semop'foo','bar';
####
send'1',$foo'100,1;
####
setgrent'foo';
####
sethostent'1';
####
setnetent'1';
####
setpgrp'1',2;
####
setpriority'1',2, 3;
####
setprotoent'1';
####
setpwent'foo';
####
setservent'1';
####
setsockopt'1',2,'foo',3;
####
shift'1','2';
####
shmctl'1',2,$foo;
####
shmget'1',2,1;
####
shmread'1',$foo,0,10;
####
shmwrite'1',$foo,0,10;
####
shutdown'1',0;
####
sin'1';
####
sleep'1';
####
socket'1',2,3,6;
####
socketpair'1',2,3,4,6;
####
splice'1',2;
####
split'1','foo';
####
sprintf'foo','bar';
####
sqrt'1';
####
srand'1';
####
stat'foo';
####
state $foo;
####
study'foo';
####
substr'foo',1;
####
symlink'foo','bar';
####
syscall'foo';
####
sysopen'foo','bar',1;
####
sysread'1',$bar,1;
####
sysseek'1',0,0;
####
system'foo';
####
syswrite'1',$bar,1;
####
tell'1';
####
telldir'1';
####
tie'foo',$bar;
####
tied'foo';
####
time;
####
times;
####
truncate'foo',1;
####
uc'foo';
####
ucfirst'foo';
####
umask'foo';
####
undef'foo';
####
unlink'foo';
####
unpack'H*',$data;
####
unshift'1';
####
untie'foo';
####
utime'1','2';
####
values'foo';
####
vec'1',0.0;
####
wait;
####
waitpid'1',0;
####
wantarray;
####
warn'foo';
####
when('foo') {}
####
write'foo';
####
1 for'foo';
####
1 foreach'foo';
####
1 if'foo';
####
1 unless'foo';
####
1 until'foo';
####
1 while'foo';
####
