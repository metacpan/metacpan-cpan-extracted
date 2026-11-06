# Tests of Proc::ShellSubset::Large (claude/large-subset-spec.md); IDs LS:n. Same line format as shell-subset-tests.pl.
# With -s, each string the parser accepts is also given to dash -n and bash --posix -n, which must accept it too.
use strict; use warnings; use FindBin; use lib "$FindBin::Bin/../../lib"; use Proc::ShellSubset::Large; use Data::Dumper;
$Data::Dumper::Indent = 0; $Data::Dumper::Terse = 1; $Data::Dumper::Sortkeys = 1; $Data::Dumper::Useqq = 1;
$ENV{HOME} //= '/root'; delete $ENV{CDPATH};
my $SYN = @ARGV && $ARGV[0] eq '-s';
sub syn { my ($t, @sh) = @_; my $pid = fork // die;
  unless ($pid) { open STDERR, '>', '/dev/null'; open STDOUT, '>', '/dev/null'; exec @sh, '-n', '-c', $t; exit 127 }
  waitpid $pid, 0; $? == 0 }
my ($bad, $n) = (0, 0);
my %tree = (   # the whole expected tree, where acceptance alone would not show a bug
  q~LS:319~ => q~[[[{"argv" => ["grep",[["*","^["],"><",["*","]"]],"f"]}]],[[{"argv" => ["ls",[["*","[a"],"]",["*","]"]],[["*","[!"],"x",["*","]*"]],[["*","["],"",["\"\$","v"],["*","x]"]],[["*","["],["\$","v"],["*","]"]],[["*","c["],"^",["*","]"]]]}]]]~,
  q~LS:314~ => q~[[[{"set" => ["v","X"]}]],[[{"argv" => ["alias",["a=echo ",["\"\$","v"]]]}]],[[{"lineoff" => 1,"rest" => "a"}]]]~,
  q~LS:299~ => q~[[[{"body" => {"group" => [[[{"argv" => ["command","cd",["",["\"\$","\@"]]]}]]]},"func" => "cd"}]],[[{"argv" => ["cd","/tmp"],"fn" => 1}]],[[{"body" => {"group" => [[[{"argv" => [":"]}]]]},"func" => "read"}]],[[{"argv" => ["read","-z"],"fn" => 1}]],[[{"body" => {"group" => [[[{"argv" => [":"]}]]]},"func" => "jobs"}]],[[{"argv" => ["jobs","-x"],"fn" => 1}]],[[{"body" => {"group" => [[[{"argv" => [":"]}]]]},"func" => "kill"}]],[[{"argv" => ["kill","-SIGHUP",1],"fn" => 1}]]]~,
  q~LS:305~ => q~[[[{"argv" => ["echo",[["\$","LINENO"]]],"line" => 1}]],[[{"if" => [[[[{"argv" => ["true"],"line" => 2}]]],[[[{"argv" => ["echo",[["\$","LINENO"]],[["\$((","LINENO + 1"]]],"line" => 3}]]]],"line" => 2}]]]~,
  q~LS:33~ => q~[[[{"argv" => ["echo",["",["\"\${","x",":-","a}b"]],["",["\"\${","x",":-","a\$b\\\\e"]],[["\${","x",":-",[["'","a"]]]]]}]]]~,
  q~LS:1~ => q~[[[{"body" => {"group" => [[[{"argv" => ["echo",["",["\"\$","#"],":",["\"\$",1]]]}]]]},"func" => "f"}]],[[{"argv" => ["f","a","b"]}]],[[{"argv" => ["echo",["",["\"\$","#"]]]}]]]~,
  q~LS:4~ => q~[[[{"body" => {"group" => [[[{"argv" => ["echo","a"]}]]],"redir" => [[1,">","/dev/null"]]},"func" => "f"}]],[[{"argv" => ["f"]}]]]~,
  q~LS:18~ => q~[[[{"body" => {"group" => [[[{"argv" => ["cat"],"redir" => [[0,"<<","body\n"]]}]]]},"func" => "f"}]],[[{"argv" => ["f"]}]]]~,
  q~LS:19~ => q~[[[{"set" => ["x",[["\$(",[[[{"argv" => ["cat"],"redir" => [[0,"<<","in\n"]]}]]]]]]}]],[[{"argv" => ["echo",["",["\"\$","x"]]]}]]]~,
  q~LS:20~ => q~[[[{"set" => ["x","a.b.c"]}]],[[{"argv" => ["echo",[["\${","x","%",[["*",".*"]]]],[["\${","x","%%",[["*",".*"]]]],[["\${","x","#",[["*","*."]]]],[["\${","x","##",[["*","*."]]]]]}]]]~,
  q~LS:23~ => q~[[[{"argv" => ["echo",["",["\"\${","x",":-","'a'"]],[["\${","x",":-",[["'","a  b"]]]],["",["\"\${","x","#","a"]],[["\${","x","%","*"]]]}]]]~,
  q~LS:40~ => q~[[[{"set" => ["cmd","ls"]}]],[[{"argv" => [[["\$","cmd"]],"-d","/"]}]]]~,
  q~LS:43~ => q~[[[{"exec" => 1,"redir" => [[1,">","log"],[2,">&",1]]}]]]~,
  q~LS:60~ => q~[[[{"argv" => ["cat"],"redir" => [[0,"<<",[["\"\$","HOME"],"-x \"q\"\n"]]]}]],[[{"argv" => ["echo","after"]}]]]~,
  q~LS:61~ => q~[[[{"argv" => ["cat"],"redir" => [[0,"<<","a \$x\n"]]}]]]~,
  q~LS:62~ => q~[[[{"argv" => ["cat"],"redir" => [[0,"<<","one\n"]]}]],[[{"argv" => ["cat"],"redir" => [[0,"<<","two\n"]]}]]]~,
  q~LS:63~ => q~[[[{"argv" => ["cat"],"redir" => [[0,"<<",["a\$x ",["\"\$(",[[[{"argv" => ["echo","bq"]}]]]]," b\n"]]]}]]]~,
  q~LS:67~ => q~[[[{"argv" => ["echo",[["\$((","1<<2"]]],"redir" => [[0,"<<","x\n"]]}]]]~,
  q~LS:68~ => q~[[[{"argv" => ["cat"],"redir" => [[0,"<<","a\n"],[0,"<<","b\n"]]}]]]~,
  q~LS:69~ => q~[[[{"argv" => ["echo","<<x","<<y"]}]]]~,
  q~LS:80~ => q~[[[{"export" => ["a",[["\$","x"]],"b",undef]}]],[[{"readonly" => ["r",1]}]]]~,
  q~LS:192~ => q~[[[{"argv" => [],"redir" => [[1,">","f"]]}]]]~,
  q~LS:194~ => q~[[[{"redir" => [[1,">","f"],[2,">&",1]],"set" => ["x",1,"y",2]}]]]~,
  q~LS:198~ => q~[[[{"argv" => ["echo","foo","bar"]}]]]~,
  q~LS:201~ => q~[[[{"argv" => ["echo",[["\$((","1+2"]],"ab",[["\$(",[[[{"argv" => ["echo","cd"]}]]]]]]}]]]~,
  q~LS:202~ => q~[[[{"argv" => ["echo","a\\\\\nb"]}]]]~,
  q~LS:204~ => q~[[[{"if" => [[[[{"argv" => ["true"]}]]],[[[{"argv" => ["echo","y"]}]]]]}]]]~,
);
while (<DATA>) {
  chomp; next unless /\S/ && !/^#/;
  my ($exp, $opt, $id, $s) = /^(ok|rej)\s+(\S+)\s+(\S+)\s+(.*)$/ or die "bad line $_";
  $s =~ s/\@N/\n/g; $s =~ s/\@T/\t/g; $s =~ s/\@R/\r/g;
  my %o = map { /=/ ? split(/=/, $_, 2) : ($_ => 1) } grep length && $_ ne '-', split /,/, $opt;   # NAME or NAME=VALUE
  my $t = Proc::ShellSubset::Large::parse($s, %o); my $ok = ref $t eq 'ARRAY'; $n++;
  my $m = $ok eq ($exp eq 'ok') && (!$ok || !exists $tree{$id} || Dumper($t) eq $tree{$id})
    && (!$ok || !$SYN || syn($s, 'dash') && syn($s, qw(bash --posix))) ? '  ' : '!!';
  $bad++ if $m eq '!!';
  (my $show = $s) =~ s/\n/\\n/g; $show =~ s/\t/\\t/g;
  printf "%s %-7s %-44s %s\n", $m, $id, $show, $ok ? Dumper($t) : "REJ $t->{error} \@$t->{pos}";
}
print "$bad of $n unexpected\n";
__DATA__
# functions, positional parameters (F1)
ok  -  LS:1  f() { echo "$#:$1"; }; f a b; echo "$#"
ok  -  LS:2  f() ( echo sub ); f
ok  -  LS:3  f() if true; then echo y; fi; f
ok  -  LS:4  f() { echo a; } >/dev/null; f
ok  -  LS:5  f()for i in "$@"; do echo "$i"; done
rej -  LS:6  f() echo x
rej -  LS:7  if() { :; }
rej -  LS:8  export() { :; }
ok  -  LS:9  f(){ local x=1 y=$2; return 3; }
rej -  LS:10  f(){ local x; }
rej -  LS:11  local x=1
ok  -  LS:12  return
ok  -  LS:13  f(){ while :; do return 1; done; }
rej -  LS:14  while :; do f(){ break; }; done
ok  -  LS:15  echo $1 ${10} $# $@ "$*" $0
ok  -  LS:16  set -- a b; shift; echo $1; shift $n
rej -  LS:17  shift a
ok  -  LS:18  f() { cat <<E; }@Nbody@NE@Nf
ok  -  LS:19  x=$(cat <<E@Nin@NE@N); echo "$x"
# parameter forms (F2, F9)
ok  -  LS:20  x=a.b.c; echo ${x%.*} ${x%%.*} ${x#*.} ${x##*.}
ok  -  LS:21  echo ${x:=1} ${y=2} ${z:?unset} ${w?}
rej -  LS:22  echo ${1:=x}
ok  -  LS:23  echo "${x:-'a'}" ${x:-"a  b"} "${x#"a"}" ${x%\*}
rej -  LS:24  echo ${x/a/b}
rej -  LS:25  echo ${x:1:2}
rej -  LS:26  echo ${!x}
rej -  LS:27  echo ${x:-~}
ok  -  LS:28  echo ${#} ${#1} ${@:-none} ${1+"$1"}
ok  -  LS:29  echo $$ ${$} /tmp/x.$$
rej -  LS:30  echo $-
rej -  LS:31  echo ${CDPATH:=x}
rej -  LS:32  echo ${x^^}
ok  -  LS:33  echo "${x:-a\}b}" "${x:-a\$b\e}" ${x:-\a}
# command names from expansions, exec (F3)
ok  -  LS:40  cmd=ls; $cmd -d /
ok  -  LS:41  "$EDITOR" file
ok  -  LS:42  echo a; exec true; echo c
ok  -  LS:43  exec >log 2>&1
rej -  LS:44  exec
rej -  LS:45  exec -a x ls
rej -  LS:46  exec cd /
ok  -  LS:47  ! exec false
rej -  LS:48  a[1]=x
rej -  LS:49  [[ -n x ]]
ok  -  LS:50  x=1 :; y=2 exit 3
rej -  LS:51  function f { :; }
rej -  LS:52  ((x=1))
# here-documents (F4)
ok  -  LS:60  cat <<EOF@N$HOME-x "q"@NEOF@Necho after
ok  -  LS:61  cat <<-'E'@N@Ta $x@N@TE
ok  -  LS:62  cat <<E1; cat <<E2@None@NE1@Ntwo@NE2
ok  -  LS:63  cat <<E@Na\$x `echo bq` \@Nb@NE
rej -  LS:64  cat <<E@Nno end
rej -  LS:65  cat <<$x@Nb@N$x
rej -  LS:66  cat <<<word
ok  -  LS:67  echo $((1<<2)) <<E@Nx@NE
ok  -  LS:68  cat <<"E" <<-F@Na@NE@N@Tb@N@TF
ok  -  LS:69  echo '<<x' "<<y" # <<z
# variables and builtins (F5–F8, F12)
ok  -  LS:80  export a=$x b; readonly r=1
rej -  LS:81  export
rej -  LS:82  export -p
rej -  LS:83  readonly -p
ok  -  LS:84  unset x; unset -f f; unset -v y; unset IFS
rej -  LS:85  unset PPID
rej -  LS:86  unset -x y
ok  -  LS:87  set -eu; set +e; set -o errexit; set -o nounset +o noglob; set -C -a -f
rej -  LS:88  set
rej -  LS:89  set -x
rej -  LS:90  set -o pipefail
rej -  LS:91  set -o
rej -  LS:92  set -v
ok  -  LS:93  trap 'echo bye' EXIT; trap - INT; trap '' TERM HUP
rej -  LS:94  trap
rej -  LS:95  trap 'echo x'
rej -  LS:96  trap -p
rej -  LS:97  trap 'echo x' ERR
rej -  LS:98  trap '[[ x ]]' EXIT
ok  -  LS:99  trap "$cmd" INT
ok  -  LS:100  wait; wait $! 123
rej -  LS:101  wait %1
ok  -  LS:102  umask; umask 022
ok  -  LS:103  umask -S
ok  -  LS:104  command -v ls; command ls -l
rej -  LS:105  command -V ls
ok  -  LS:106  command; command | cat; command >f
rej -  LS:107  command alias x
ok  -  LS:108  getopts ab: o -b x
rej -  LS:109  getopts ab:
rej -  LS:110  getopts ab: PPID
rej -  LS:111  pwd; pwd -P; pwd -x
ok  -  LS:113  cd -
ok  -  LS:114  cd -P /
ok  -  LS:115  . ./lib.sh; eval "echo \$((1+2))"
rej -  LS:116  . a b
rej -  LS:117  source x
ok  -  LS:118  alias e=echo
rej -  LS:119  shopt -s x
ok  -  LS:120  type ls
ok  -  LS:121  IFS=: read -r a b; read x; for IFS in a; do b; done
rej -  LS:122  CDPATH=x
rej -  LS:123  break
# arithmetic (F10)
ok  -  LS:130  echo $((x=5)) $((y+=1)) $(( $1 + $# )) $((a<<=1))
rej -  LS:131  echo $((i++))
rej -  LS:132  echo $((1=2))
rej -  LS:133  echo $((PPID=1))
ok  -  LS:134  echo $((x==1)) $((x<=1)) $((x!=1))
# patterns that may match . or .. (U2), strings sh reads as options (U1)
ok  -  LS:140  ls -d .* | cat
ok  -  LS:141  echo .*perf.* .[!.]* ./* x/.git
rej -  LS:142  -x foo; true
rej -  LS:143    +x foo | cat
ok  -  LS:144  echo -x | cat
# found by the cold review of 2026-11-01
rej -  LS:150  echo ${x#<<E;}@Necho INJECTED@NE
rej -  LS:151  x=`cat <<E@N$HOME@NE@N`
rej -  LS:152  echo $(cat <<E)@Nbody@NE@Necho end
ok  -  LS:153  cat <<E@Na\@NE@NE@Necho done
rej -  LS:154  command set -x
rej -  LS:155  command local x
ok  -  LS:156  "exec" echo hi; echo after
rej -  LS:157  x[a; echo hi]
rej -  LS:158  echo[
ok  -  LS:159  echo ${##}
rej -  LS:160  echo ${#-}
ok  -  LS:161  echo "${@#?}"
rej -  LS:162  x=$@
rej -  LS:163  export z=$@
rej -  LS:164  case "$@" in a) ;; esac
rej -  LS:165  echo ${x:=$@}
rej -  LS:166  cat <<E@N$@@NE
rej -  LS:167  echo "${x:-`echo \"q\"`}"
ok  -  LS:168  echo ${x:-a\@Nb} "${x:-c\@Nd}"
ok  -  LS:169  unset HOME
ok  -  LS:170  read HOME
rej -  LS:171  CDPATH=/ :
rej -  LS:172  PPID=5 :
rej -  LS:173  local() { :; }
rej -  LS:174  source() { :; }
ok  -  LS:175  cd() { :; }
rej -  LS:176  unset 1
rej -  LS:177  getopts ab 1x
rej -  LS:178  echo $((0 ? 1 : b = 2))
rej -  LS:179  x=g; f() { local x=1; g; }; g() { unset x; }; f
ok  -  LS:180  trap 'if true; then echo y; fi' EXIT
rej -  LS:181  trap 1 2
ok  -  LS:182  for x in "$@"; do echo $x; done; set -- ${1+"$@"}
# for NAME without in (2026-11-01, evening)
ok  -  LS:183  for i; do echo $i; done
ok  -  LS:184  f() { for a do echo "[$a]"; done; }; f x
ok  -  LS:185  for i@Ndo :; done
rej -  LS:186  for i x; do :; done
# here-documents inside "$( )" (2026-11-02)
ok  -  LS:187  x="$(cat <<E@Nbody@NE@N)"; echo "$x"
ok  -  LS:188  echo "a $(cat <<E@Nb@NE@N) c"
ok  -  LS:189  echo "$(echo "$(cat <<E@Ndeep@NE@N)")"
ok  -  LS:190  echo "<<E $(echo ")") x"
rej -  LS:191  echo "$(cat <<E)"@Nb@NE
ok  -  LS:192  >f
ok  -  LS:193  > f | grep foo
ok  -  LS:194  x=1 y=2 >f 2>&1
ok  -  LS:195  x=$(v) 2>/dev/null
ok  -  LS:196  x=$y >f
ok  -  LS:197  x=1 <<E@Nb@NE
ok  -  LS:198  echo foo\@N   bar
ok  -  LS:199  'foo'\@N  'bar'
ok  -  LS:200  ec\@Nho hi
ok  -  LS:201  echo $((1+\@N2)) "a\@Nb" `echo c\@Nd`
ok  -  LS:202  echo 'a\@Nb'
ok  -  LS:203  echo a # c \@Necho b
ok  -  LS:204  i\@Nf true; then echo y; fi
ok  -  LS:205  cat <<E@Na\@Nb@NE
rej -  LS:206  echo x &>g
ok  -  LS:207  echo x & >g
rej -  LS:208  x=$(<f)
rej -  LS:209  echo `<f`
rej -  LS:210  cat </dev/tcp/host/80
ok  -  LS:211  a &&>g
# P1-P4 of "Shell Corpus Gaps" (2026-11-02): forms that dash and bash run alike are accepted
ok  -  LS:212  echo @{-1} x{a}y {} {.}.png \{} a} {b
ok  -  LS:213  git log @{u}..HEAD
ok  -  LS:214  find . -exec echo \{} \;
ok  -  LS:215  case x{a} in x{a}) echo m;; esac
rej -  LS:216  echo {a,b}
rej -  LS:217  echo {1..3}
rej -  LS:218  echo {x{a,b}}
rej -  LS:219  { echo a }
ok  -  LS:220  echo $(($(echo 6) / 2)) $((${#HOME} > 0)) $((`echo 2` * 3)) $(( $((1+2)) * 2 ))
ok  -  LS:221  x=4; echo "$(( $(echo $x) * 2 ))"
rej -  LS:222  echo $(( ${x:-1} ))
rej -  LS:223  echo $(( $(echo 1)++ ))
ok  -  LS:224  PS1='> '; PS4='+ '; HOSTNAME=h PIPESTATUS=1 BASH=x
rej -  LS:225  export PS1
rej -  LS:226  echo "$PS1"
rej -  LS:227  LINENO=5
ok  -  LS:228  v=x; export $v="$y" ${v}; export $v
rej -  LS:229  export $v=$y
rej -  LS:230  export $v=~/q
ok  -  LS:231  exit 1000
rej -  LS:232  exit 4294967296
rej -  LS:233  f() { return 1000; }
ok  -  LS:234  umask 022; umask -S
rej -  LS:235  umask -S 077
ok  -  LS:236  command -p ls /
rej -  LS:237  command -p cd /
rej -  LS:238  {a; }
rej -  LS:239  echo a; }
ok  -  LS:240  { echo }; }
rej -  LS:241  bar() {
rej -  LS:242  {
rej -  LS:243  exec {n}>&2
rej -  LS:244  echo {fd}>f
ok  -  LS:245  echo {fd} >f
# Q1 of "Shell Corpus Gaps" (2026-11-03): kill with a SIG signal name; both shells refuse it
rej -  LS:246  kill -SIGHUP 1
rej -  LS:247  kill -s SIGHUP 1
rej -  LS:248  kill -l SIGHUP
rej -  LS:249  kill -sighup 1
ok  -  LS:250  kill -HUP 1; kill -s TERM 1; kill -l
# Y2 of "Shell Corpus Gaps" (2026-11-03): a backslash at the very end is a literal \, as in both shells
ok  -  LS:251  echo a\
ok  -  LS:252  find . -inum 5 -exec rm {} \
rej -  LS:253  echo "a\
# P5 and R1 of "Shell Corpus Gaps" (2026-11-03): [ and test are the program; < and > between operands need the option
ok  -  LS:254  [ a == a ]; [ -v x ]; test -a f; [ -N f ]
ok  -  LS:255  [ a \< b ]
rej -  LS:256  test "$x" '>' b -a c
ok  test_lt_gt  LS:257  [ a \< b ]
ok  -  LS:258  [ "<" = "<" ]; test ">" != x
# B1-B3 of "Shell Corpus Gaps" (2026-11-03): alias (expanded in the lines after its definition), the job builtins as dash,
# the interactive ones as nothing (option interactive)
ok  -  LS:259  alias ll="echo L"@Nll x
ok  -  LS:260  alias ll="echo L"; ll x
ok  -  LS:261  alias e="echo " x=X@Ne x
ok  -  LS:262  alias a=b; unalias a; alias | wc -l; alias a
ok  -  LS:263  if true; then alias a=b; fi
ok  -  LS:264  x && alias a=b
ok  -  LS:265  alias a=b &
rej -  LS:266  alias x=if@Nx true; then :; fi
ok  -  LS:267  alias $n=v
ok  -  LS:268  jobs; times; hash ls; hash -r; hash; type ls cd; ulimit -n; ulimit -Hn; ulimit; bg; fg %1
rej -  LS:269  ulimit -n 10
ok  -  LS:270  jobs -l
ok  -  LS:271  history; fc -l; bind -l; set -o vi; set -o emacs; set -o history
rej interactive=reject  LS:272  history
# P6 of "Shell Corpus Gaps" (post-0.03): forms both shells run alike
ok  -  LS:273  read -p 'Name: ' x; read -rp q x y; read -p q -r x; read -p "$p" x
rej -  LS:274  read -p
ok  -  LS:275  cd -P /tmp; cd -L ..; cd -LP x; cd -PL x; cd -P; cd -P -- x
rej -  LS:276  cd -P -
rej -  LS:277  cd -x y
ok  -  LS:278  echo a >*.log; cat <[ab].txt; echo b >>x?y
ok  -  LS:279  set -o nounset; set -o errexit -o noglob; set +o noclobber; set -o allexport; set -o ignoreeof; set -o notify; set -o nolog; set -b; set +m
rej -  LS:280  set -m
rej -  LS:281  set -o monitor
ok  -  LS:282  trap 'echo c' int; trap f 2 hup 15; trap - int; trap f fpe 8 9 stop usr1; trap f exit 0
rej -  LS:283  trap f sigint
rej -  LS:284  trap f 65
rej -  LS:285  trap f chld
ok  -  LS:286  pwd; pwd -L; pwd -P; pwd -LP; pwd -- x
rej -  LS:287  pwd -x
# post3-0.03: jobs where dash lists nothing (a pipeline, $( ), a compound command)
ok  -  LS:288  jobs; jobs >f; jobs || echo; sleep 1 & jobs && echo
ok  -  LS:289  jobs | wc -l
ok  -  LS:290  x=$(jobs)
ok  -  LS:291  echo | jobs
ok  -  LS:292  if true; then jobs; fi
# rule E (the user, 2026-11-03): where the shells differ, the plainly logical behaviour (doc/large-subset/large-subset-logical.md)
ok  -  LS:293  cd a b; echo hi 10>/dev/null; case b in [^a]) echo n;; esac; echo .*; x=$(f) 2>/dev/null
rej -  LS:294  local x
ok  -  LS:295  echo $LINENO
# post4-0.03: more forms both shells run alike
ok  -  LS:296  echo $PPID; export "$foo" "${bar}"; umask a+r; umask g+w,o=rx; umask =rx; cd - >/dev/null; jobs -p; jobs -lp
rej -  LS:297  PPID=3
rej -  LS:298  umask -S a=
# post-0.04: 3A (the user, 2026-11-03): a function comes before a regular builtin of that name (POSIX order)
ok  -  LS:299  cd() { command cd "$@"; }; cd /tmp; read() { :; }; read -z; jobs() { :; }; jobs -x; kill() { :; }; kill -SIGHUP 1
rej -  LS:300  alias() { :; }
ok  -  LS:301  command cd /tmp; command read x; command umask 022
# post-0.04: rule E choices (doc/large-subset/large-subset-logical.md): break, continue in a subshell in a loop end it (as dash);
# ${@#p} on each parameter (G4); $LINENO (G8; not in eval or trap text); UID an ordinary variable where set (G15); jobs %N
ok  -  LS:302  for v in a; do (cd "$v" || continue; echo x); x=$(break); echo a | { continue; }; done
rej -  LS:303  (continue)
ok  -  LS:304  set -- ab; echo ${@#a} "${*%b}" ${*##a} "${@%%b*}"
ok  -  LS:305  echo $LINENO@Nif true; then@N  echo ${LINENO} $((LINENO + 1))@Nfi
rej -  LS:306  trap 'echo $LINENO' EXIT
ok  -  LS:307  UID=5 env; echo $UID
rej -  LS:308  echo $UID
ok  -  LS:309  sleep 1 & jobs %1 %% %+ %-; jobs -l %1; jobs -p %%
rej -  LS:310  jobs %sleep
# post-0.04 (the user, 2026-11-03: "cannot we do it easily?"): read with names from expansions, checked at run time; lengths of special parameters
ok  -  LS:311  v=x; read $v; read -r "$v" y; read -p "$p" $v z
rej -  LS:312  read arr[$i]
ok  -  LS:313  echo ${##} ${#?} ${#!} ${#$}
# post2-0.04, P1 (the user, 2026-11-03: "go with better aliases"): after a line with an alias known only when it runs, the rest is parsed then
ok  -  LS:314  v=X; alias a="echo $v"@Na
ok  -  LS:315  { alias x=y@Nx@N}@Nx
ok  -  LS:316  f() { alias z="echo Z"; }; f@Nz
# post2-0.04, rule F (the user, 2026-11-03: where the program is wrong, we may do better): s1 < s2 and s1 > s2 alone, compared by us
ok  -  LS:317  [ ! "$x" \> y ]; test a \< b
rej -  LS:318  [ a \< b -a c ]
# post4-0.04: bracket expressions with quoted members, expansions or '/' (both shells: quoted characters are members; a '/' makes the '[' literal)
ok  -  LS:319  grep ^[\>\<] f; ls [a"]"] [!"x"]* ["$v"x] [$v] c['^']
ok  -  LS:320  find . | grep /path/to/something[^/]*$; echo a[/]*
ok  -  LS:321  x=a.b; echo ${x%["."]*} "${x#*[.]}"; read -r -p "${1:-Are you sure? [y/N]} " r; echo ${1:-a?}
rej -  LS:322  unset foo[$i]
rej -  LS:323  echo [{a]
