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
  my %o = map +($_ => 1), grep length && $_ ne '-', split /,/, $opt;
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
rej -  LS:12  return
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
rej -  LS:103  umask -S
ok  -  LS:104  command -v ls; command ls -l
rej -  LS:105  command -V ls
ok  -  LS:106  command; command | cat; command >f
rej -  LS:107  command alias x
ok  -  LS:108  getopts ab: o -b x
rej -  LS:109  getopts ab:
rej -  LS:110  getopts ab: PPID
ok  -  LS:111  pwd; pwd -P; pwd -x
ok  -  LS:113  cd -
rej -  LS:114  cd -P /
ok  -  LS:115  . ./lib.sh; eval "echo \$((1+2))"
rej -  LS:116  . a b
rej -  LS:117  source x
rej -  LS:118  alias e=echo
rej -  LS:119  shopt -s x
rej -  LS:120  type ls
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
rej -  LS:140  ls -d .* | cat
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
rej -  LS:159  echo ${##}
rej -  LS:160  echo ${#-}
rej -  LS:161  echo "${@#?}"
rej -  LS:162  x=$@
rej -  LS:163  export z=$@
rej -  LS:164  case "$@" in a) ;; esac
rej -  LS:165  echo ${x:=$@}
rej -  LS:166  cat <<E@N$@@NE
rej -  LS:167  echo "${x:-`echo \"q\"`}"
ok  -  LS:168  echo ${x:-a\@Nb} "${x:-c\@Nd}"
rej -  LS:169  unset HOME
rej -  LS:170  read HOME
rej -  LS:171  CDPATH=/ :
rej -  LS:172  PPID=5 :
rej -  LS:173  local() { :; }
rej -  LS:174  source() { :; }
rej -  LS:175  cd() { :; }
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
rej -  LS:195  x=$(v) 2>/dev/null
rej -  LS:196  x=$y >f
rej -  LS:197  x=1 <<E@Nb@NE
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
