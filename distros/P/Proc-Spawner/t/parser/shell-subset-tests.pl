# Hand-written tests, one rule of shell-subset-spec.md per line; IDs OWN:n (see PROVENANCE.md).
use strict; use warnings; use FindBin; use lib "$FindBin::Bin/../../lib"; use Proc::ShellSubset; use Data::Dumper;
$Data::Dumper::Indent = 0; $Data::Dumper::Terse = 1; $Data::Dumper::Sortkeys = 1; $Data::Dumper::Useqq = 1;
$ENV{HOME} //= '/root'; delete $ENV{CDPATH};
my ($bad, $n) = (0, 0);
my %tree = (   # the whole expected tree, where acceptance alone would not show a bug
  'OWN:205' => q{[[[{"argv" => ["env"],"env" => ["A",[["\$(",[[[{"argv" => ["true"]}]]]]],"B",[["\$(",[[[{"argv" => ["false"]}]]]]]]}]]]},
  'OWN:206' => q{[[[{"set" => ["x",[["\$(",[[[{"argv" => ["echo",1]}]],[[{"argv" => ["exit",6]}]]]]]]}]],[[{"argv" => ["echo",["[",["\"\$","x"],"] st=",["\"\$","?"]]]}]]]},
  'OWN:207' => q{[[[{"argv" => ["c"],"env" => ["A",[["\$(",[[[{"argv" => ["a"]}]]]]],"B",[["\$((",1]]]}]]]},
);
while (<DATA>) {
  chomp; next unless /\S/ && !/^#/;
  my ($exp, $opt, $id, $s) = /^(ok|rej)\s+(\S+)\s+(\S+)\s+(.*)$/ or die "bad line $_";
  $s =~ s/\@N/\n/g; $s =~ s/\@T/\t/g; $s =~ s/\@R/\r/g;
  my %o = map +($_ => 1), grep length && $_ ne '-', split /,/, $opt;
  my $t = Proc::ShellSubset::parse($s, %o); my $ok = ref $t eq 'ARRAY'; $n++;
  my $m = $ok eq ($exp eq 'ok') && (!$ok || !exists $tree{$id} || Dumper($t) eq $tree{$id}) ? '  ' : '!!';
  $bad++ if $m eq '!!';
  (my $show = $s) =~ s/\n/\\n/g;
  printf "%s %-22s %-38s %s\n", $m, $id, $show, $ok ? Dumper($t) : "REJ $t->{error} \@$t->{pos}";
}
print "$bad of $n unexpected\n";
__DATA__
ok  -  OWN:1  LANG=C sort -k2 <in.txt 2>/dev/null | uniq -c >"$OUT" && echo done
ok  -  OWN:2  a && b & c
ok  -  OWN:3  ! a | b || c; d
rej -  OWN:4  ! ! a
ok  -  OWN:5  echo a #b
rej -  OWN:6  # note
ok  empty  OWN:7  # note
rej -  OWN:8  
ok  -  OWN:9  @N@Na@N@Nb@N
ok  -  OWN:10  a |@N b
ok  -  OWN:11  a \@N b
rej -  OWN:12  a\@Nb
rej -  OWN:13  2\@N>f a
ok  -  OWN:14  (a; b) >f 2>&1
rej -  OWN:15  ((a))
rej -  OWN:16  ()
ok  -  OWN:17  { a; b; } >f
rej -  OWN:18  { a }
rej -  OWN:19  {a; }
ok  -  OWN:20  { a; exec b; }
rej -  OWN:21  { a; exec b; }; c
rej -  OWN:22  { { exec b; }; c; }
ok  -  OWN:23  ( exec b ); c
rej -  OWN:24  exec b && c
ok  -  OWN:25  a && exec b
rej -  OWN:26  ! exec b
rej -  OWN:27  exec
rej -  OWN:28  exec -a x b
rej -  OWN:29  exec cd /
ok  -  OWN:30  A=1 exec b
ok  -  OWN:31  exec b | c
ok  -  OWN:32  { exec b; } | c
ok  -  OWN:33  exec b & c
rej -  OWN:34  exec b && c &
rej -  OWN:35  { exec b; c; } | d
ok  -  OWN:36  echo $(exec b) c
ok  -  OWN:37  A=1 B=$A env
rej -  OWN:38  A=1
rej -  OWN:39  >f
rej -  OWN:40  A+=1 b
ok  -  OWN:41  b A+=1
rej -  OWN:42  A=1 :
ok  -  OWN:43  : >f $(touch x)
ok  -  OWN:44  exit 3
rej -  OWN:45  exit 256
rej -  OWN:46  exit 07
rej -  OWN:47  exit $x
ok  -  OWN:48  cd /tmp
ok  -  OWN:49  cd
rej -  OWN:50  cd -
rej -  OWN:51  cd /tmp >f
rej -  OWN:52  if true
ok  -  OWN:53  "if" x
ok  -  OWN:54  echo if then
rej -  OWN:55  set -e
rej -  OWN:56  "set" -e
ok  -  OWN:57  echo "$HOME" ${HOME} x$HOME"y"
rej -  OWN:58  echo $1
ok  -  OWN:59  echo $?
rej -  OWN:60  echo ${x:-y}
rej -  OWN:61  echo $IFS
rej -  OWN:62  echo $BASH_VERSION
ok  -  OWN:63  echo a$
rej -  OWN:64  echo $'a'
ok  -  OWN:65  echo $((1 + 2*3)) "$((x ? 0x1f : 010))"
rej -  OWN:66  echo $((x = 1))
rej -  OWN:67  echo $((x++))
rej -  OWN:68  echo $((x--y))
rej -  OWN:69  echo $((2 ** 3))
rej -  OWN:70  echo $((1,2))
rej -  OWN:71  echo $((08))
rej -  OWN:72  echo $((1 ? 2))
rej -  OWN:73  echo $((a : b))
ok  -  OWN:74  echo $(( (1) ? (2 ? 3 : 4) : 5 ))
ok  -  OWN:75  echo `echo \`echo x\``
ok  -  OWN:76  echo "`echo \"a b\"`"
ok  -  OWN:77  echo `echo \"a b\"`
rej -  OWN:78  echo `echo '`'`
rej -  OWN:79  echo `a\@Nb`
ok  -  OWN:80  echo "$(echo ")")"
ok  -  OWN:81  echo $( )
ok  -  OWN:82  echo ~ ~root/x a~b
rej -  OWN:83  echo ~+
rej -  OWN:84  echo ~"root"
ok  -  OWN:85  A=~/x:~root/y env
ok  -  OWN:86  make PREFIX=~/x
ok  tilde_args  OWN:87  make PREFIX=~/x:~/y
ok  -  OWN:88  ls *.c a?"b"[0-9]x
ok  -  OWN:89  ls *"x"*
rej -  OWN:90  ls [a"]"]
ok  -  OWN:91  [ -f x ]
ok  -  OWN:92  find . -exec rm {} +
rej -  OWN:93  echo {a,b}
ok  brace  OWN:94  echo f{,.bak} x{1..3}y {a,"b c",$x}
rej brace  OWN:95  echo {a}
rej brace  OWN:96  echo {a,{b,c}}
rej brace  OWN:97  echo {1..a}
ok  -  OWN:98  echo a^b
ok  caret  OWN:99  echo a^b
rej caret  OWN:100  echo [^a]
ok  -  OWN:101  echo $((1^2))
rej -  OWN:102  echo a@Rb
ok  -  OWN:103  echo "a@Rb" 'a@Rb'
ok  -  OWN:104  echo a@Tb
ok  -  OWN:105  echo a\@Tb
rej -  OWN:106  a &>f
rej -  OWN:107  a |& b
rej -  OWN:108  a 10>f
ok  fdmulti  OWN:109  a 10>f
rej -  OWN:110  a >&f
ok  -  OWN:111  a 2>&- <&0 3<>f >|g >>h
rej -  OWN:112  cat <<EOF
ok  -  OWN:113  a >$f
ok  -  OWN:114  a >"$f" <~/x
rej -  OWN:115  a >*.c
rej -  OWN:116  a;;b
rej -  OWN:117  ; a
rej -  OWN:118  a &; b
ok  -  OWN:119  a & b &
rej -  OWN:120  a (b)
rej -  OWN:121  a)
rej -  OWN:122  echo 'unterminated
rej -  OWN:123  echo "unterminated
rej -  OWN:124  echo `unterminated
rej -  OWN:125  echo $(unterminated
ok  -  OWN:126  echo "a\@Nb" '\@N'
ok  -  OWN:127  echo `echo $(echo x)` "`echo "a b"`"
rej -  OWN:128  echo `echo $IFS`
ok  -  OWN:129  echo "x`echo \`exec y\`; z`"
rej -  OWN:130  echo $(exec y; z)
rej nocaret  OWN:131  echo a^b
ok  -  OWN:132  grep "\.cgi$" list
rej -  OWN:133  echo $[1+1]
ok  -  OWN:134  cd $(dirname "$f")
rej -  OWN:135  cd -P /tmp
rej -  OWN:136  cd a b
ok  -  OWN:137  cd ''
ok  -  OWN:138  echo $((3+$x)) $((${y}*2))
rej -  OWN:139  echo $(($1+1))
rej -  OWN:140  diff <(sort a) b
ok  -  OWN:141  echo x >a$
rej -  OWN:142  grep ^[\>\<] f
ok  -  OWN:143  echo $PWD
rej nopwd  OWN:144  echo $PWD
ok  -  OWN:145  sleep 9 & echo "$!"
ok  -  OWN:146  echo $(($? + 1))
rej -  OWN:147  echo $#
ok  -  OWN:148  echo ${?} ${!}
ok  -  OWN:149  xargs -I{} du -sh {}
ok  -  OWN:150  f={} env x{}y
rej -  OWN:151  echo x}
ok  -  OWN:152  ls >$out 2>"$err" <$(mktemp)
rej -  OWN:153  ls >*.log
rej -  OWN:154  f=$(mktemp); ls >"$f"
ok  assign  OWN:155  f=$(mktemp); ls >"$f"
ok  assign  OWN:156  a=1 b=$a | cat & PATH=/opt/bin:$PATH
rej assign  OWN:157  f=x >out
rej assign  OWN:158  IFS=:
rej assign  OWN:159  HOME=/tmp
rej assign  OWN:160  x+=1
rej -  OWN:161  head -"${n:-10}"
ok  param_ops  OWN:162  head -"${n:-10}" ${x-a b} ${y:+$(date)} ${z+`pwd`} ${#x} ${x:-}
ok  param_ops  OWN:163  echo ${x:-${y:-z}}
rej param_ops  OWN:164  echo ${1:-10}
rej param_ops  OWN:165  echo ${x:-"q"}
rej param_ops  OWN:166  echo ${x:-~}
rej param_ops  OWN:167  echo ${x%.c}
rej param_ops  OWN:168  echo ${x:=1}
rej param_ops  OWN:169  echo ${x:-a
rej -  OWN:170  if a; then b; fi
ok  if  OWN:171  if a; then b; elif c; then d; else e; fi >log
ok  if  OWN:172  if a@Nthen b@Nfi; if ! a | b; then c && d; fi
rej if  OWN:173  if a; then fi
rej if  OWN:174  if a; b; fi
rej if  OWN:175  if a; then b; fi; then
ok  if  OWN:176  if a; then exec b; else exec c; fi
rej if  OWN:177  if exec a; then b; fi
ok  if  OWN:178  "if" a; echo if fi
ok  while  OWN:179  while a; do b; continue; break 1; done <f
ok  while  OWN:180  until a; do while b; do break 2; done; done
rej while  OWN:181  while a; do break 2; done
rej while  OWN:182  while a; do b | break; done
rej while  OWN:183  while a; do (break); done
rej while  OWN:184  while a; do exec b; done
rej -  OWN:185  while a; do b; done
rej while  OWN:186  break
ok  for  OWN:187  for f in *.c "a b" $x; do cc -c "$f"; done
ok  for  OWN:188  for f in@Ndo b@Ndone
rej for  OWN:189  for f; do b; done
rej for  OWN:190  for IFS in a; do b; done
rej for  OWN:191  for 1x in a; do b; done
ok  case  OWN:192  case $x in a|"b c") d;; (*.c) e; f;; *) ;; esac
ok  case  OWN:193  case x in@Ny) z;;@Nesac
ok  case  OWN:194  case x in esac
ok  case  OWN:195  case x in a) b;;esac
rej case  OWN:196  case x in a) b
rej case  OWN:197  case x a) b;; esac
rej -  OWN:198  read x
ok  read  OWN:199  read -r a b <f; IFS= read line
rej read  OWN:200  read
rej read  OWN:201  read -p x y
rej read  OWN:202  read HOME
ok  read,while  OWN:203  while IFS= read -r line; do echo "$line"; done <f
ok  if,while,for,case,read  OWN:204  for f in *; do if [ -f "$f" ]; then case $f in *.c) continue;; esac; fi; while read l; do break 2; done <"$f"; done
ok  -  OWN:205  A=$(true) B=$(false) env
ok  assign  OWN:206  x=$(echo 1; exit 6); echo "[$x] st=$?"
ok  -  OWN:207  A=`a` B=$((1)) c
rej -  OWN:208  -x foo; true
rej -  OWN:209    +x foo | cat
ok  -  OWN:210  echo -x | cat
rej -  OWN:211  ls -d .* | cat
rej -  OWN:212  echo "$d"/.? x
ok  -  OWN:213  echo .*perf.* .[!.]* ./* x/.git
ok  -  OWN:214  echo .a[] .[[:alpha:]]* [.]* ./* "$d"/*
rej -  OWN:215  echo "."*
rej -  OWN:216  echo .[!]]*
rej -  OWN:217  UID=5 echo hi
rej param_ops  OWN:218  echo "${x:-`echo \"q\"`}"
ok  param_ops  OWN:219  echo "${x:-`echo q`}" ${x:-`echo \"q\"`}
rej -  OWN:220  x >&2>f
rej -  OWN:221  x >1>f
ok  -  OWN:222  x >f1>g 2>&1 >&- <&0
