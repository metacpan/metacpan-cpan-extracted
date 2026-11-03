# Corpus regression tests: one sample per group of very similar commands. Each test carries the
# snippet ID of its source (see PROVENANCE.md); each '# ...' line names the group: its features (accepted)
# or its error and the construct at the error (rejected), and how many samples it has in which sources.
use strict; use warnings; use FindBin; use lib "$FindBin::Bin/../../lib"; use Proc::ShellSubset; use Data::Dumper;
$Data::Dumper::Indent = 0; $Data::Dumper::Terse = 1; $Data::Dumper::Sortkeys = 1; $Data::Dumper::Useqq = 1;
$ENV{HOME} //= '/root'; delete $ENV{CDPATH};
my ($bad, $n) = (0, 0);
while (<DATA>) {
  chomp; next unless /\S/ && !/^#/;
  my ($exp, $opt, $id, $s) = /^(ok|rej)\s+(\S+)\s+(\S+)\s+(.*)$/ or die "bad line $_";
  $s =~ s/\@N/\n/g; $s =~ s/\@T/\t/g; $s =~ s/\@R/\r/g;
  my %o = map +($_ => 1), grep length && $_ ne '-', split /,/, $opt;
  my $t = Proc::ShellSubset::parse($s, %o); my $ok = ref $t eq 'ARRAY'; $n++;
  my $m = $ok eq ($exp eq 'ok') ? '  ' : '!!'; $bad++ if $m eq '!!';
  (my $show = $s) =~ s/\n/\\n/g;
  printf "%s %-22s %-38s %s\n", $m, $id, $show, $ok ? Dumper($t) : "REJ $t->{error} \@$t->{pos}";
}
print "$bad of $n unexpected\n";
__DATA__
# cmd:c  (33050 samples: cookbook,makebook,nl2bash,pure-bash-bible,pure-sh-bible,shellcheck,tldr)
ok  -  TL:common/abduco.md:8  abduco
# cmd:c |  (957 samples: cookbook,makebook,nl2bash,shellcheck,tldr)
ok  -  TL:common/mpc.md:29  mpc +n|-n
# cmd:c redir:>w  (676 samples: cookbook,makebook,nl2bash,shellcheck,tldr)
ok  -  SC:Analytics.hs:prop_checkRedirectionToNumber2:1  foo 1>2
# cmd:c cmd:c+ |  (645 samples: nl2bash,tldr)
ok  -  TL:linux/free.md:12  free -b|k|m|g
# cmd:c word:*  (571 samples: cookbook,makebook,nl2bash,shellcheck,tldr)
ok  -  TL:common/dot.md:25  dot -?
# cmd:c cmd:echo |  (259 samples: makebook,nl2bash,shellcheck,tldr)
ok  -  NB:1499  echo 798|rev
# cmd:c word:$  (219 samples: cookbook,nl2bash,shellcheck,tldr)
ok  -  SC:Analytics.hs:prop_checkUuoc4:1  cat $var
# cmd:c word:* |  (178 samples: nl2bash,shellcheck,tldr)
ok  -  NB:8379  grep foo * | nl
# ( cmd:c cmd:w word:$(  (176 samples: nl2bash,shellcheck,tldr)
ok  -  NB:5602  mv `ls` /foo
# cmd:c word:"$  (157 samples: cookbook,nl2bash,pure-bash-bible,shellcheck,tldr)
ok  -  NB:3308  find "$dir"
# cmd:c redir:>w |  (156 samples: makebook,nl2bash,shellcheck,tldr)
ok  -  SC:Analytics.hs:prop_checkRedirectedNowhere5:1  foo | grep bar > baz
# cmd:c word:~  (144 samples: makebook,nl2bash,tldr)
ok  -  NB:5103  find ~
# cmd:echo  (85 samples: cookbook,makebook,pure-bash-bible,shellcheck,tldr)
ok  -  BC:ch17/func_shift_by:25  echo ''
# cmd:c redir:<w  (78 samples: makebook,nl2bash,shellcheck,tldr)
ok  -  TL:common/yj.md:8  yj <file.yml -y
# ( cmd:c word:$(  (66 samples: nl2bash,shellcheck,tldr)
ok  -  SC:Analytics.hs:prop_checkUnquotedExpansions1a:1  rm `ls`
# cmd:c word:$ |  (65 samples: nl2bash,shellcheck)
ok  -  NB:995  cat $i | wc -l
# cmd:c redir:N>w  (55 samples: nl2bash,tldr)
ok  -  TL:common/cppcheck.md:9  cppcheck . 2>cppcheck.log
# cmd:printf  (55 samples: cookbook,makebook,pure-bash-bible,shellcheck,tldr)
ok  -  BC:ch07/hist.awk:27e23  printf "#";
# E cmd:E  (52 samples: nl2bash,shellcheck,tldr)
ok  -  SC:Analytics.hs:prop_checkAssignAteCommand1:1  A=ls -l
# cmd:c word:"$ |  (49 samples: nl2bash,shellcheck)
ok  -  SC:Analytics.hs:prop_checkUuoc3:1  cat "$var" | grep bar
# ( cmd:c cmd:w word:"$(  (48 samples: nl2bash,tldr)
ok  -  NB:5237  tree -dfi "$(pwd)"
# cmd:[  (45 samples: shellcheck,tldr)
ok  -  SC:Analytics.hs:prop_checkConstantNullary6:1  [ 1 ]
# cmd:printf word:"$  (43 samples: cookbook,pure-bash-bible,pure-sh-bible,shellcheck,tldr)
ok  -  SC:Checks/Commands.hs:prop_checkPrintfVar1:1  printf "Lol: $s"
# cmd:c redir:<w>w  (39 samples: nl2bash,tldr)
ok  -  TL:common/suspend.md:8  bash <Enter> suspend
# cmd:c word:~ |  (37 samples: nl2bash,tldr)
ok  -  NB:8127  cat ~/.bashrc | pbcopy
# ( cmd:c cmd:w word:$( |  (30 samples: nl2bash,shellcheck,tldr)
ok  -  NB:6441  getent passwd `whoami` | cut -d : -f 5
# cmd:c cmd:echo word:"$ |  (30 samples: nl2bash)
ok  -  NB:5903  echo "$DIREC" | od -c
# cmd:c cmd:c+ redir:>w |  (28 samples: tldr)
ok  -  TL:common/ppmcie.md:12  ppmcie -cie|ebu|hdtv|ntsc|smpte >path/to/output.ppm
# cmd:c+  (28 samples: nl2bash,tldr)
ok  -  TL:common/cb.md:28  cb | cat
# cmd:echo word:"$  (26 samples: cookbook,shellcheck,tldr)
ok  -  SC:Analytics.hs:prop_subshellAssignmentCheck15:3  echo "$a"
# ( cmd:c cmd:| word:$( |  (25 samples: nl2bash)
ok  -  NB:6148  cat `which java` | file -
# && cmd:c  (24 samples: nl2bash,shellcheck,tldr)
ok  -  TL:common/qmake.md:20  qmake && make
# ( cmd:echo word:$(  (24 samples: nl2bash,shellcheck)
ok  -  SC:Analytics.hs:prop_checkBackticks1:1  echo `foo`
# cmd:exit  (24 samples: cookbook,nl2bash,pure-bash-bible,shellcheck,tldr)
ok  -  NB:1862  exit 1
# & cmd:c redir:N>&d |  (22 samples: nl2bash,tldr)
ok  -  NB:5722  make 2>&1 | less
# cd cmd:cd  (22 samples: makebook,nl2bash,shellcheck,tldr)
ok  -  NB:4739  cd "~"
# & cmd:c  (21 samples: makebook,nl2bash,shellcheck,tldr)
ok  -  TL:common/picom.md:8  picom &
# cmd:echo word:$  (21 samples: cookbook,shellcheck,tldr)
ok  -  SC:Analytics.hs:prop_subshellAssignmentCheck11:2  echo $n
# cmd:c cmd:echo word:$ |  (19 samples: nl2bash)
ok  -  NB:4771  echo $c | crontab
# cmd:c cmd:printf |  (19 samples: nl2bash,tldr)
ok  -  NB:5902  printf Aa | od -t x1
# ( cmd:echo word:"$(  (18 samples: nl2bash,shellcheck)
ok  -  SC:Analytics.hs:prop_checkUseBeforeDefinition7:3  echo "$(f)"
# cmd:c cmd:echo redir:>w |  (17 samples: makebook,nl2bash,tldr)
ok  -  MK:recipe:206.3  echo 'MAKEVAR' | sed 's/;/ /g' > /dev/null
# cmd:kill  (17 samples: nl2bash,tldr)
ok  -  NB:9048  kill %1
# cmd:[ word:$  (16 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkLiteralBreakingTest2:1  [ $foo=3 ]
# cmd:c redir:N>w |  (14 samples: nl2bash,tldr)
ok  -  NB:691  yes 2>/dev/null | ./MyScript.sh
# cmd:c word:"$ word:$  (14 samples: nl2bash)
ok  -  NB:389  chown $FUID:$FGID "$FILE2"
# ( cmd:echo cmd:w word:$(  (13 samples: nl2bash,shellcheck)
ok  -  NB:6445  echo -n $(pwd)
# cmd:c cmd:false |  (13 samples: nl2bash,tldr)
ok  -  NB:8240  false | tee /dev/null
# cmd:c redir:>w word:*  (12 samples: nl2bash,tldr)
ok  -  NB:4119  find . -name \*\\?\* > output.txt
# cmd:time  (12 samples: makebook,nl2bash,shellcheck,tldr)
ok  -  TL:common/time.md:14  time read
# ( cmd:kill cmd:w word:$(  (11 samples: nl2bash)
ok  -  NB:9464  kill -9 $(pgrep amarok)
# ( cmd:kill word:$(  (11 samples: nl2bash,tldr)
ok  -  TL:linux/pidof.md:21  kill $(pidof name)
# cmd::  (11 samples: cookbook,makebook,pure-bash-bible,shellcheck,tldr)
ok  -  TL:common/colon.md:8  :
# ( cmd:c word:"$(  (10 samples: nl2bash,shellcheck)
ok  -  NB:6386  basename "`pwd`"
# cmd:[ word:"$  (10 samples: shellcheck,tldr)
ok  -  SC:Checks/ShellSupport.hs:prop_checkBashisms6:1  [ "$a" == 42 ]
# cmd:c redir:<w |  (10 samples: nl2bash,shellcheck,tldr)
ok  -  SC:Analytics.hs:prop_checkPipeToNowhere11:1  ls | grep foo < file
# && cd cmd:c cmd:cd  (9 samples: makebook,nl2bash,tldr)
ok  -  MK:recipe:116.8  cd src && \@Nctags --recurse
# ( cmd:echo cmd:w word:"$(  (9 samples: nl2bash)
ok  -  NB:5971  echo -ne "Welcome `whoami`!\n"
# cmd:c cmd:pwd |  (9 samples: nl2bash)
ok  -  NB:843  pwd | xsel -i
# cmd:true  (9 samples: nl2bash,shellcheck,tldr)
ok  -  TL:common/true.md:9  true
# ( cmd:[ cmd:w word:$(  (8 samples: nl2bash,shellcheck)
ok  -  SC:Analytics.hs:prop_checkUnquotedExpansions3a:1  [ ! $(foo) ]
# E cmd:E cmd:c |  (8 samples: nl2bash,shellcheck,tldr)
ok  -  NB:86  v=5 env|less
# cmd:c redir:>>~  (8 samples: tldr)
ok  -  TL:common/npm-completion.md:16  npm completion >>~/.zshrc
# cmd:c word:"$ word:$ |  (8 samples: nl2bash)
ok  -  NB:6694  yes "$OPTARG" | head -$opt
# cmd:c word:$*  (8 samples: nl2bash,shellcheck)
ok  -  NB:5510  sort -m *.$suffix
# cmd:c word:* word:~  (8 samples: nl2bash)
ok  -  NB:8960  find ~ -name *.txt
# cmd:test  (8 samples: makebook,shellcheck,tldr)
ok  -  SC:Checks/ShellSupport.hs:prop_checkBashisms21b:1  test -a foo
# cmd:c redir:>>w  (7 samples: cookbook,nl2bash,tldr)
ok  -  TL:linux/genfstab.md:8  genfstab -U /mnt >>/mnt/etc/fstab
# cmd:echo redir:>w  (7 samples: makebook,pure-bash-bible,shellcheck,tldr)
ok  -  PB:README.md:1031  echo -n >file
# & cmd:echo redir:>&d  (6 samples: cookbook,makebook,tldr)
ok  -  TL:common/greater-than.md:36  echo text >&3
# & cmd:printf redir:>&d  (6 samples: cookbook,pure-bash-bible)
ok  -  BC:ch05/check_arg_count:13  printf "%b" "Error. Too many arguments.\n" >&2
# && cmd:[ word:$  (6 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkAndEq6:1  [ $a = a ] && [ $a = b ]
# && cmd:c cmd:echo ||  (6 samples: nl2bash,shellcheck,tldr)
ok  -  SC:Analytics.hs:prop_checkShorthandIf3:1  foo && bar || echo baz
# cmd:[ word:*  (6 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkTestArgumentSplitting12:1  [ *.png ]
# cmd:c cmd:c+ cmd:echo |  (6 samples: tldr)
ok  -  TL:common/boxes.md:24  echo "string" | boxes -a hl|c|r
# cmd:c cmd:time |  (6 samples: nl2bash,shellcheck,tldr)
ok  -  SC:Checks/Commands.hs:prop_checkTimedCommand1:2  time -p foo | bar
# ( ) cmd:(c cmd:c |  (5 samples: nl2bash)
ok  -  NB:4466  ( find ./ -name '*.php' -print0 | xargs -0 cat ) | wc -l
# ( cmd:c cmd:w word:$ word:$(  (5 samples: nl2bash)
ok  -  NB:1129  ln -s $file `basename $file`
# ( cmd:c word:$( |  (5 samples: nl2bash)
ok  -  NB:9216  ipcs -a | grep `whoami`
# ( cmd:c word:$(*  (5 samples: nl2bash,shellcheck)
ok  -  NB:4952  ls `pwd`/*
# ( cmd:echo word:$((  (5 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkDollarBrackets2:1  echo $((1+2))
# cmd:c redir:N>w>w  (5 samples: nl2bash)
ok  -  NB:11777  find . 2>/dev/null > some_file
# cmd:x:c x:  (5 samples: shellcheck,tldr)
ok  -  SC:Analytics.hs:prop_checkSpuriousExec1:1e9  exec foo;
# & cmd:c redir:>w  (4 samples: nl2bash,shellcheck,tldr)
ok  -  SC:Analytics.hs:prop_checkPipeToNowhere14:1e10  ls > foo &
# ( cmd:c cmd:echo cmd:w word:$( |  (4 samples: nl2bash)
ok  -  NB:6915  echo -n $(pwd) | pbcopy
# ( cmd:c cmd:w word:"$ word:"$(  (4 samples: nl2bash)
ok  -  NB:1117  ln -s "$(which bam2)" "$tmpdir"/bam
# ( cmd:echo cmd:| word:"$( |  (4 samples: nl2bash)
ok  -  NB:12419  echo "* * * * * touch $(pwd)/washere1" | crontab
# ( cmd:printf cmd:w word:$(  (4 samples: nl2bash,shellcheck)
ok  -  SC:Checks/Commands.hs:prop_checkPrintfVar3:1  printf -v cow $(cmd)
# cmd:c cmd:c+ cmd:test |  (4 samples: tldr)
ok  -  TL:common/bacon.md:20  bacon run|test|clippy|doc|...
# cmd:c cmd:echo word:* |  (4 samples: nl2bash,tldr)
ok  -  NB:638  echo *.txt | xargs gzip -9
# cmd:c cmd:true |  (4 samples: nl2bash,tldr)
ok  -  NB:1850  true | sleep 10
# cmd:c redir:>>w |  (4 samples: nl2bash)
ok  -  NB:2969  find dir -type f | xargs md5sum >> file.txt
# cmd:c redir:N>>w  (4 samples: nl2bash)
ok  -  NB:10553  find -name "*.txt" 2>>/dev/null
# cmd:c redir:N>w word:*  (4 samples: nl2bash)
ok  -  NB:2113  find / -name *.jpg 2>/dev/null
# cmd:c word:$ word:*  (4 samples: cookbook,nl2bash)
ok  -  NB:7359  find $HOME/. -name *.txt -ok rm {} \;
# cmd:c word:$ word:~  (4 samples: nl2bash)
ok  -  NB:2831  find ~ ! -user ${USER}
# cmd:printf word:*  (4 samples: cookbook,shellcheck)
ok  -  SC:Analytics.hs:prop_checkGlobsAsOptions6:1  printf '%s\n' *
# cmd:pwd  (4 samples: nl2bash,tldr)
ok  -  TL:common/pwd.md:12  pwd -P
# && cmd:[ cmd:printf word:"$  (3 samples: cookbook,pure-sh-bible)
ok  -  PS:README.md:426  [ -n "$line" ] && printf %s "$line"
# && cmd:c redir:>w  (3 samples: nl2bash,tldr)
ok  -  NB:1400  grep -v "pattern" file > temp && mv temp file
# ( ) cmd:(c  (3 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkSubshellAsTest1:1  ( -e file )
# ( cmd:>w cmd:c redir:>w word:$(  (3 samples: nl2bash)
ok  -  NB:10617  cat `find . -type f` > out.txt
# ( cmd:[ cmd:w word:"$(  (3 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkLiteralBreakingTest4:1  [ "$(ls) " ]
# ( cmd:c cmd:w redir:>w word:$(  (3 samples: nl2bash)
ok  -  NB:9954  tar cvf - `find . -print` > backup.tar
# ( cmd:c cmd:w word:"$( |  (3 samples: nl2bash)
ok  -  NB:6741  cal -h|sed -r "s/\b$(date|cut -d' ' -f3)\b/*/"
# ( cmd:c cmd:w word:$( word:~  (3 samples: nl2bash)
ok  -  NB:7059  sudo chown -R `whoami` ~/.npm
# ( cmd:echo cmd:| word:$( |  (3 samples: nl2bash)
ok  -  NB:6757  echo `date +%s`/86400 | bc
# cmd:c cmd:c+ word:* |  (3 samples: nl2bash,tldr)
ok  -  TL:common/egrep.md:38  egrep [[:alnum:|:alpha:|:space:|...]] path/to/file
# cmd:c redir:<w redir:>w |  (3 samples: nl2bash,tldr)
ok  -  NB:9699  head -16482 < file.in | tail -259 > file.out
# cmd:c redir:<w word:$  (3 samples: cookbook)
ok  -  BC:ch13/dbiniter:21  mysql $DB < ourInit.sql
# cmd:c redir:<w>w |  (3 samples: nl2bash)
ok  -  NB:7539  find <directory> -type f -size -1M -print0  | xargs -0 rm
# cmd:c redir:>w word:"$ |  (3 samples: nl2bash)
ok  -  NB:1929  find . -name "$i" -type f -print | xargs egrep -n "$SrchStr" >/dev/null
# cmd:c redir:>~  (3 samples: tldr)
ok  -  TL:linux/conky.md:12  conky -C >~/.conkyrc
# cmd:c word:$ word:$*  (3 samples: nl2bash)
ok  -  NB:2034  find $parentdir -name $tofind*
# cmd:c word:$ word:* |  (3 samples: nl2bash)
ok  -  NB:5252  cut -f $FIELD * | sort| uniq -c |sort -nr
# cmd:c word:* word:~ |  (3 samples: nl2bash)
ok  -  NB:896  find ~music -type f -iname *.mp3 | wc -l
# cmd:c word:*~  (3 samples: nl2bash)
ok  -  NB:191  rsync -vaut ~/.env* ~/.bash* app1:
# cmd:false cmd:true |  (3 samples: nl2bash,shellcheck)
ok  -  NB:8218  false | true
# cmd:kill word:$  (3 samples: nl2bash)
ok  -  NB:9627  kill $PID
# cmd:test word:"$  (3 samples: shellcheck,tldr)
ok  -  SC:Checks/ShellSupport.hs:prop_checkBashisms6b:1  test "$a" == 42
# ! cmd:! cmd:[ word:$ |  (2 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkUnnecessarilyInvertedTest3:1  ! [ -x $var ]
# ! cmd:! cmd:true |  (2 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkUselessBang10:3  ! true
# & ; cmd:; cmd:c word:* |  (2 samples: nl2bash)
rej  -  NB:11515  find /tmp -type f -name ‘*.txt*’ | sed -e ‘s/.*/\”&\”/’ |xargs -n 1 grep -l hello|sed -e ‘s/.*/\”&\”/’
# & cmd:c cmd:echo redir:>&d |  (2 samples: nl2bash)
ok  -  NB:9678  echo "error" 1>&2 | tee -a log
# & cmd:c redir:>&d  (2 samples: shellcheck)
ok  -  SC:Checks/ShellSupport.hs:prop_checkBashisms52:2  cmd >&2
# & cmd:c redir:>w redir:N>&d |  (2 samples: nl2bash)
ok  -  NB:10916  find . 2>&1 | grep -v 'Permission denied' > some_file
# & cmd:c redir:>w |  (2 samples: nl2bash)
ok  -  NB:4364  find . -type d -print0 | xargs -0 -n1 du -sk | sort -rn > dir-sizes.txt&
# && ( cmd:c cmd:w redir:>w word:$(  (2 samples: nl2bash,tldr)
ok  -  TL:linux/unzipsfx.md:8  cat $(which unzipsfx) path/to/archive.zip >filename && chmod 755 filename
# && cmd:c cmd:echo  (2 samples: nl2bash,tldr)
ok  -  TL:common/gh-run.md:24  gh run view workflow_run_number --exit-status && echo "run pending or passed"
# ( cmd:c word:"$ word:$(  (2 samples: nl2bash)
ok  -  NB:587  chown $(stat -c%u:%g "$srcdir") "$dstdir"
# ; cd cmd:c cmd:cd  (2 samples: makebook,shellcheck)
ok  -  SC:Analytics.hs:prop_checkCdAndBack5:1  cd ..; foo; cd ..
# ; cmd:c  (2 samples: nl2bash)
ok  -  NB:851  mkdir dir2; tar cvf - dir1/ --exclude "*/exclude" | tar xvf - -C dir2
# ; cmd:c cmd:c} cmd:{echo { | }  (2 samples: tldr)
ok  -  TL:linux/ttyplot.md:8  { echo 1 2 3; cat; } | ttyplot
# ; cmd:c cmd:echo |  (2 samples: nl2bash,tldr)
ok  -  TL:linux/sync.md:16  sync; echo 3 | sudo tee /proc/sys/vm/drop_caches
# ; cmd:c cmd:exit cmd:{echo word:"$ word:{ { || }  (2 samples: cookbook)
ok  -  BC:ch12/oodiff:54  mkdir "$PRIV1" || { echo "Unable to mkdir '$PRIV1'" ; exit 4; }
# ; cmd:c cmd:printf  (2 samples: nl2bash)
ok  -  NB:10991  find -s . -mindepth 1 -type f -print0; printf '\0';
# ; cmd:c redir:>w  (2 samples: nl2bash)
ok  -  NB:7682  grep -v "pattern" filename > filename2; mv filename2 filename
# cmd:: redir:>w  (2 samples: pure-bash-bible,pure-sh-bible)
ok  -  PS:README.md:510  :>file
# cmd:[ word:$ word:*  (2 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkComparisonAgainstGlob6:1  [ $f != /* ]
# cmd:[ word:$ ||  (2 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkOrNeq6:1  [ $a != a ] || [ $a != b ]
# cmd:c cmd:c+ cmd:false cmd:true |  (2 samples: tldr)
ok  -  TL:linux/setsebool.md:17  sudo setsebool -P container_use_devices 1|true|on|0|false|off
# cmd:c cmd:c+ word:~ |  (2 samples: nl2bash)
ok  -  NB:5884  find ~/code -name '.*' -prune -o -type f -a -perm /u+x -printf ':%h\n' | sort | uniq | tr -d '\n'
# cmd:c cmd:x:c word:$ x: |  (2 samples: nl2bash)
ok  -  NB:1756  exec 1 | tee ${LOG_FILE}
# cmd:c cmd:{c { | }  (2 samples: nl2bash)
ok  -  NB:9021  { yes yes | sed 4q; yes no | sed 1q; } | ./script
# cmd:c redir:>w word:"$  (2 samples: nl2bash,shellcheck)
ok  -  SC:Checks/Commands.hs:prop_checkExpr14:2  expr "$x" >=  "$y"
# cmd:c redir:>w word:* |  (2 samples: nl2bash)
ok  -  NB:195  find ./* | cpio -o > arch.cpio
# cmd:c redir:>w word:~  (2 samples: nl2bash)
ok  -  NB:8172  find ~ -name 'Foto*' > results.txt
# cmd:c redir:N>w word:~  (2 samples: nl2bash)
ok  -  NB:1166  find ~ -type d -exec mkdir junk {} \; 2> /dev/null
# cmd:c word:"$ word:~  (2 samples: nl2bash)
ok  -  NB:1106  ln -s "$source" -t ~/newlinks
# cmd:c word:$~  (2 samples: nl2bash)
ok  -  NB:3668  find ~/$folder -name "*@*" -type f
# cmd:echo redir:>>~  (2 samples: tldr)
ok  -  TL:common/gh-copilot.md:25  echo 'eval "$(gh copilot alias -- zsh)"' >>~/.zshrc
# cmd:echo word:*  (2 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkGlobAsCommand3:1  echo foo*
# cmd:false  (2 samples: nl2bash,tldr)
ok  -  TL:common/false.md:9  false
# cmd:printf redir:>w  (2 samples: cookbook,pure-bash-bible)
ok  -  PB:README.md:1032  printf '' >file
# cmd:printf word:$  (2 samples: cookbook)
ok  -  BC:ch12/load_mp3:71  printf "loaded %d songs (%d blocks)" $COUNT $SUM
# cmd:test word:$  (2 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkComparisonWithLeadingX4:1  test $foo = xbar
# cmd:{time redir:N>w}N>w { }  (2 samples: nl2bash)
ok  -  NB:7296  { time find / 2>/dev/null; } 2>time.txt
# ! && ( ) cmd:! cmd:([ cmd:[ cmd:c | ||  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkSubshelledTests1:1  a && ( [ b ] || ! [ c ] )
# ! ( ) cmd:(! cmd:c |  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkSubshellAsTest7:1  ( ! -d file )
# ! ( ) cmd:(! cmd:true cmd:true) |  (1 samples: shellcheck)
ok  -  SC:Checks/ShellSupport.hs:prop_checkBangAfterPipe2:1  true | ( ! true )
# ! ; cmd:! cmd:c cmd:true |  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkUselessBang2:1  ! true; rest
# ! cmd:! cmd:[ |  (1 samples: shellcheck)
ok  -  SC:Checks/ShellSupport.hs:prop_checkNegatedUnaryOps4:1  ! [ -o braceexpand ]
# ! cmd:! cmd:c redir:<w |  (1 samples: makebook)
ok  -  MK:recipe:114.29  ! grep --line-number '"debug:' MAKEVAR < /dev/null
# ! cmd:! cmd:c |  (1 samples: makebook)
ok  -  MK:recipe:114.20  ! grep --line-number '"debug:' MAKEVAR
# & ( ) cmd:&) cmd:(c word:$(  (1 samples: nl2bash)
ok  -  NB:9423  (chromium --user-data-dir=$(mktemp -d) &)
# & ( ) cmd:(c cmd:c redir:N>&d>&dN>&d |  (1 samples: nl2bash)
ok  -  NB:10193  (find /boot | sed s'/^/STDOUT:/' ) 3>&1 1>&2 2>&3 | sed 's/^/STDERR:/'
# & ( ) cmd:(time redir:>wN>&d  (1 samples: nl2bash)
ok  -  NB:8214  (time ls) > outfile 2>&1
# & ( cmd:c cmd:w redir:N>&d word:$( |  (1 samples: tldr)
ok  -  TL:common/tqdm.md:20  tar vzcf path/to/archive.tar.gz path/to/directory 2>&1 | tqdm --total $(find path/to/directory | wc -l) --unit files --null
# & ; cmd:; cmd:[  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkBadTestAndOr1:1  [ x ] & [ y ]
# & ; cmd:; cmd:c cmd:echo redir:>w  (1 samples: tldr)
ok  -  TL:linux/mopac.md:12  touch test.out; echo "PM7\n#comment\n\nH 0.95506 0.05781 -0.03133\nF 1.89426 0.05781 -0.03133" >test.mop; mopac test.mop & tail -f test.out
# & ; cmd:; cmd:c word:*  (1 samples: nl2bash)
ok  -  NB:3666  find . -type f -exec sed -i ‘s/.*abc.*/#&/’ {} \;
# & ; cmd:; cmd:test  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkBadTestAndOr2:1  test -e foo & [ y ]
# & ; cmd:[ cmd:exit cmd:{echo redir:>&d word:$ word:{ { || }  (1 samples: cookbook)
ok  -  BC:ch15/email_sample_css:8  [ -x $MAIL ] || { echo 'Cannot find a mailer!' >&2; exit 1; }
# & cmd:c cmd:test redir:N>&d>w |  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkStderrRedirect3:1  test 2>&1 > file | grep stderr
# & cmd:c cmd:x:c redir:N>&d word:$ x: |  (1 samples: nl2bash)
ok  -  NB:1757  exec 1 2>&1 | tee ${LOG_FILE}
# & cmd:c cmd:{c redir:N<&d word:{ { | }  (1 samples: nl2bash)
ok  -  NB:6335  zcat number.txt.gz | { zcat xxx.txt.gz | comm -12 /dev/fd/3 - ; } 3<&0
# & cmd:c cmd:{time redir:>w redir:N>&d { | }  (1 samples: nl2bash)
ok  -  NB:8208  { time ls; } 2>&1 |  cat > time.txt
# & cmd:c cmd:{time redir:N>&d { | }  (1 samples: nl2bash)
ok  -  NB:4440  { time sleep 1; } 2>&1 | grep real
# & cmd:c redir:>&dN>&dN>&d |  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkPipeToNowhere18:1  ls 1>&3 3>&1 3>&- | wc -l
# & cmd:c redir:>wN>&d  (1 samples: tldr)
ok  -  TL:linux/setsid.md:13  setsid program >/dev/null 2>&1
# & cmd:c redir:N>&d  (1 samples: shellcheck)
ok  -  SC:Checks/ShellSupport.hs:prop_checkBashisms51:2  cmd 2>&1
# & cmd:c redir:N>&d>w |  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkStderrRedirect6:1  foo | bar 2>&1 > /dev/null
# & cmd:c word:"$ word:$  (1 samples: nl2bash)
ok  -  NB:12009  su $USER -c "$WEB --quiet" &
# & cmd:c word:$ |  (1 samples: nl2bash)
ok  -  NB:9067  ping -W 1 -c 1 10.0.0.$i | grep 'from' &
# & cmd:c word:*~  (1 samples: nl2bash)
ok  -  NB:9420  nohup vlc -I dummy --quiet ~/mp3_directory/* &
# & cmd:c |  (1 samples: nl2bash)
ok  -  NB:8015  nohup cmd1 | cmd2 &
# & cmd:echo  (1 samples: shellcheck)
ok  -  SC:Checks/ShellSupport.hs:prop_checkBashisms108:2e12  echo magic &
# & cmd:echo redir:>w  (1 samples: tldr)
ok  -  TL:common/mkfifo.md:12  echo "Hello World" >path/to/pipe &
# & cmd:printf redir:>&d word:"$  (1 samples: cookbook)
ok  -  BC:ch03/func_choice.2:4  printf "%b" "This package's date is $THISPACKAGE\n" >&2
# & cmd:test redir:>wN>&d  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkStderrRedirect2:1  test > cow 2>&1
# & cmd:test redir:N>&d>w  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkStderrRedirect:1  test 2>&1 > cow
# & cmd:{c redir:>w}N>&d { }  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkStderrRedirect7:1  { cmd > file; } 2>&1
# && ( ) cd cmd:(cd cmd:c redir:>w  (1 samples: nl2bash)
ok  -  NB:9796  (cd A && find .) > tmp.txt
# && ( ) cmd:(:+)  (1 samples: pure-bash-bible)
ok  -  PB:README.md:2121  (:;:) && (:;:) && (:;:) && (:;:) && (:;:)
# && ( ) cmd:([ cmd:[ cmd:test ||  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkSubshelledTests3:1  ( [ a ] && [ b ] || test c )
# && ( ) cmd:([ cmd:[ cmd:{[ word:{ { }  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkSubshelledTests4:1  ( [ a ] && { [ b ] && [ c ]; } )
# && ( ) cmd:(c cmd:c  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkSubshellAsTest5:1  ( -e file && -x file )
# && ( ) cmd:(c cmd:c cmd:c+ word:$ |  (1 samples: nl2bash)
ok  -  NB:5179  (find . -type f -ctime $FTIME && find . -type f -atime $FTIME && find . -type f -mtime $FTIME) | sort | uniq
# && ( ) cmd:(c cmd:c cmd:c+ |  (1 samples: nl2bash)
ok  -  NB:1093  (rsync -rcn --out-format="%n" old/ new/ && rsync -rcn --out-format="%n" new/ old/) | sort | uniq
# && ( ) cmd:(c cmd:c ||  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkSubshellAsTest6:1  ( -e file || -x file && -t 1 )
# && ( cmd:[ cmd:echo cmd:w word:"$(  (1 samples: nl2bash)
ok  -  NB:5834  [ -z "$(find aaa/ -maxdepth 1 -type f)" ] && echo "empty"
# && ( cmd:[ cmd:echo cmd:w word:$( ||  (1 samples: nl2bash)
ok  -  NB:550  [ `md5sum $(which c++) | cut -d' ' -f1` == `md5sum $(which g++) | cut -d' ' -f1` ] && echo Yes, equal content || echo No, unequal content
# && ( cmd:c cmd:w word:$(  (1 samples: tldr)
ok  -  TL:linux/sport.md:8  sudo mkdir -p /usr/ports && sudo rsync -av rsync://slackbuilds.org /slackbuilds/$(awk '{print $2}' /etc/slackware-version)/ /usr/ports/
# && cd cmd:c cmd:cd redir:>>w  (1 samples: nl2bash)
ok  -  NB:9797  cd B && find . >> ../tmp.txt
# && cmd:[ cmd:c  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkConditionalAndOrs1:1  [ foo && bar ]
# && cmd:[ cmd:c word:$  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkAndEq4:1  [ a = $cow && b = $foo ]
# && cmd:[ cmd:c ||  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkShorthandIf9:1  foo && [ -x /file ] || bar
# && cmd:[ cmd:true word:$ ||  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkAndEq7:1  [ $a = a ] && [ $a = b ] || true
# && cmd:c cmd:echo word:$ word:* ||  (1 samples: nl2bash)
ok  -  NB:532  ssh -q $HOST [[ -f $FILE_PATH ]] && echo "File exists" || echo "File does not exist";
# && cmd:c cmd:false ||  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkShorthandIf11:1  foo && bar || false
# && cmd:c cmd:printf ||  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkShorthandIf5:1  foo && rm || printf b
# && cmd:c cmd:true ||  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkShorthandIf10:1  foo && bar || true
# && cmd:c redir:>"$ word:"$  (1 samples: nl2bash)
ok  -  NB:1471  tail -n +2 "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
# && cmd:c redir:>w |  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkRedirectToSame3:1  cat lol | sed -e 's/a/b/g' > foo.bar && mv foo.bar lol
# && cmd:c word:$  (1 samples: tldr)
ok  -  TL:linux/nixos-container.md:24  sudo $EDITOR /var/lib/container/container_name/etc/nixos/configuration.nix && sudo nixos-container update container_name
# && cmd:c word:*  (1 samples: tldr)
ok  -  TL:linux/rename.util.md:30  rename prefix prefix00 prefix? && rename prefix prefix0 prefix??
# && cmd:c |  (1 samples: tldr)
ok  -  TL:common/dvc-checkout.md:16  git checkout commit_hash|tag|branch target && dvc checkout target
# && cmd:c ||  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkTrailingBracket3:1  a || b ] && thing
# && cmd:echo cmd:test ||  (1 samples: tldr)
ok  -  TL:common/test.md:26  test condition && echo "true" || echo "false"
# ( ) ; cd cmd:(cd cmd:c |  (1 samples: nl2bash)
ok  -  NB:11071  find . -maxdepth 1 -type d -print0 | (cd /SomeWhere/Else; xargs -0 mkdir)
# ( ) ; cd cmd:(cd cmd:c)  (1 samples: nl2bash)
ok  -  NB:7995  ( cd /tmp; mycommand )
# ( ) ; cmd:(c cmd:c cmd:c) |  (1 samples: nl2bash)
ok  -  NB:1305  (ls -t|head -n X;ls)|sort|uniq -u|xargs rm
# ( ) ; cmd:(c cmd:echo word:$  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_subshellAssignmentCheck41:1  ( run true; ); echo $status
# ( ) ; cmd:(echo cmd:c cmd:echo |  (1 samples: tldr)
ok  -  TL:linux/zenity.md:25  (echo "#1"; sleep 1; echo "50"; echo "#2"; sleep 1; echo "100") | zenity --progress
# ( ) cmd:([  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkSubshelledTests2:1  ( [ a ] )
# ( ) cmd:(c redir:>w)  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkRedirectionToNumber1:1  ( 1 > 2 )
# ( ) cmd:(time redir:>wN>w  (1 samples: nl2bash)
ok  -  NB:8207  (time ls) > ls_results 2> time_results
# ( E cmd:E word:$(  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkExtraMaskedReturns38:1  x=$(time time time false) time $(time false)
# ( cmd:$ cmd:echo word:"$( word:$  (1 samples: nl2bash)
ok  -  NB:6424  echo "$(date): " $line
# ( cmd:$( cmd:echo word:"$( word:$(  (1 samples: nl2bash)
ok  -  NB:6858  echo `ls` "`cal`"
# ( cmd:* cmd:c word:$( word:*  (1 samples: nl2bash)
ok  -  NB:34  find /lib/modules/`uname -r` -regex .*perf.*
# ( cmd:* cmd:echo word:$( word:*  (1 samples: nl2bash)
ok  -  NB:5791  echo -n *Checking Partition Permission* Hostname=$(hostname) LastChecked=$(date)
# ( cmd:c cmd:echo cmd:w word:"$( word:$( |  (1 samples: nl2bash)
ok  -  NB:1916  echo -e "$(TZ=GMT+30 date +%Y-%m-%d)\n$(TZ=GMT+20 date +%Y-%m-%d)" | grep -v $(date +%Y-%m-%d) | tail -1
# ( cmd:c cmd:echo word:$( |  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkPipeToNowhere6:1  ls | echo $(cat)
# ( cmd:c cmd:w redir:N>w word:$(  (1 samples: nl2bash)
ok  -  NB:3829  find $(/usr/ucb/ps auwwx | grep weblogic | tr ' ' '\n' | grep security.policy | grep domain | awk -F'=' '{print $2}' | sed -e 's/weblogic.policy//' -e 's/security\///' -e 's/dep\///' | awk -F'/' '{print "/"$2"/"$3"/"$4"/somefile.cf"}' | sort | uniq) 2> /dev/null -exec ls {} \; -exec cat {} \;
# ( cmd:c cmd:w word:"$ word:"$( |  (1 samples: nl2bash)
ok  -  NB:9062  cat mail.tmp | mail -r "noreply@$(hostname)" -s "Config done!" "${MAIL}"
# ( cmd:c cmd:w word:"$( word:~  (1 samples: nl2bash)
ok  -  NB:8001  sed -i "s#\(export\ PATH=\"\)\(.*\)#\1/home/$(whoami)/bin:~/\.local/bin:\2#" ~/.zshrc
# ( cmd:c cmd:w word:$ word:$( |  (1 samples: nl2bash)
ok  -  NB:2167  find ${INPUT_LOCATION}/ -name "*.pdf.marker" | xargs -I file mv file $(basename file .marker) ${OUTPUT_LOCATION}/.
# ( cmd:c cmd:w word:$((  (1 samples: tldr)
ok  -  TL:common/fpsync.md:24  fpsync -v -n 4 -f 1000 -s $((100 * 1024 * 1024)) /path/to/source/ /path/to/destination/
# ( cmd:c cmd:w+ word:$(( |  (1 samples: nl2bash)
ok  -  NB:9623  yes | tr \\n x | head -c $((1024*1024*1024)) | pv -L $((1024*1024)) | grep n
# ( cmd:c cmd:|| word:$ word:$( ||  (1 samples: nl2bash)
ok  -  NB:475  chown ${JBOSS_USER}: $(dirname $JBOSS_PIDFILE) || true
# ( cmd:c word:"$ word:"$(  (1 samples: nl2bash)
ok  -  NB:743  cp "${FILE}" "COLLECT/$(mktemp job_XXXXXXXXX)"
# ( cmd:c word:"$( |  (1 samples: nl2bash)
ok  -  NB:5099  who | grep "$(tty | sed 's:/dev/::')"
# ( cmd:c word:"$(*  (1 samples: nl2bash)
ok  -  NB:4523  rm -rf "$(pwd -P)"/*
# ( cmd:c word:$ word:$(  (1 samples: nl2bash)
ok  -  NB:7701  mv $file $(echo $file | rev | cut -f2- -d- | rev).pkg
# ( cmd:c word:$$(  (1 samples: cookbook)
rej  -  BC:ch16/run_screen:48  -S $USER.$(date '+%Y-%m-%d_%H:%M:%S%z')
# ( cmd:echo cmd:true word:$( |  (1 samples: nl2bash)
ok  -  NB:8023  true | echo `tty | sed 's:/dev/::'`
# ( cmd:echo word:$ word:$(  (1 samples: cookbook)
ok  -  BC:ch13/pluralize:20  echo $num $(plural "$name" $num)
# ( cmd:echo word:$$(  (1 samples: nl2bash)
ok  -  NB:11879  echo $(pwd)/$filename
# ( cmd:echo word:$( |  (1 samples: nl2bash)
ok  -  NB:5814  echo "hello world" | echo test=$(cat)
# ( cmd:printf cmd:| word:$( |  (1 samples: nl2bash)
ok  -  NB:6916  printf $(pwd) | pbcopy
# ( cmd:printf word:"$(  (1 samples: nl2bash)
ok  -  NB:5813  printf "operator: `finger ${USER} | grep Name: | cut -f3 -d:` \n"
# ( cmd:time word:$(  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkExtraMaskedReturns37:1  time $(time false)
# ( cmd:true word:"$(  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkExtraMaskedReturns41:1  true "$(false || cat)"
# ( cmd:true word:$(  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkExtraMaskedReturns7:1  true $(false)
# ; E cmd:E cmd:c  (1 samples: tldr)
ok  -  TL:common/sccache.md:17  sccache --stop-server; SCCACHE_LOG=trace SCCACHE_START_SERVER=1 SCCACHE_NO_DAEMON=1 sccache
# ; cd cmd:c cmd:cd redir:>w  (1 samples: makebook)
ok  -  MK:recipe:93.14  cd MAKEVAR; \@Ngenerate-myfile MAKEVAR > MAKEVAR
# ; cd cmd:cd cmd:echo word:*  (1 samples: makebook)
ok  -  MK:recipe:256.36  cd i-dont-exist; \@Necho *.c
# ; cmd:c cmd:c+  (1 samples: tldr)
ok  -  TL:common/monodevelop.md:16  monodevelop path/to/file;line_number;column_number
# ; cmd:c cmd:c+ cmd:exit  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkCommandIsUnreachable1:1  foo; bar; exit; baz
# ; cmd:c cmd:echo  (1 samples: makebook)
ok  -  MK:recipe:115.28  rm rm-fails; echo But the next command executes anyway
# ; cmd:c cmd:echo redir:>~ word:~  (1 samples: tldr)
ok  -  TL:common/nix.md:11  mkdir -p ~/.config/nix; echo 'experimental-features = nix-command flakes' >~/.config/nix/nix.conf
# ; cmd:c cmd:echo word:"$  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkUnused42:1  DEFINE_string foo '' ''; echo "${FLAGS_foo}"
# ; cmd:c cmd:exit  (1 samples: shellcheck)
ok  -  SC:Checks/Commands.hs:prop_checkInteractiveSu2:1  su foo; something; exit
# ; cmd:c cmd:exit ||  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkCommandIsUnreachable3:1  foo; bar || exit; baz
# ; cmd:c cmd:{c word:* { | }  (1 samples: nl2bash)
ok  -  NB:3467  { find . -name '*my key phrase*'; grep -rl 'my key phrase' *; } | sed "s/^\.\///" | sort -u
# ; cmd:c cmd:{echo redir:>w { | }  (1 samples: nl2bash)
ok  -  NB:5776  { echo foo; cat bar; } | tee bar > /dev/null
# ; cmd:c redir:>>w |  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkMultipleAppends2:1  foo >> file; bar | grep f >> file; baz >> file;
# ; cmd:c word:$  (1 samples: shellcheck)
ok  -  SC:Checks/Commands.hs:prop_checkInteractiveSu1:1  su; rm file; su $USER
# ; cmd:c word:~  (1 samples: tldr)
ok  -  TL:common/fisher.md:17  editor ~/.config/fish/fishfile; fisher
# ; cmd:c |  (1 samples: nl2bash)
ok  -  NB:283  find path/to/folder -type f -print0  | sort -z | xargs -0 sha1sum; find path/to/folder \( -type f -o -type d \) -print0 | sort -z | xargs -0 stat -c '%n %a' | sha1sum
# ; cmd:echo cmd:printf word:$  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkUnassignedReferences20:1  printf -v foo bar; echo $foo
# ; cmd:echo cmd:x:c x:  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkSpuriousExec3:1  echo cow; exec foo
# E cmd:E cmd:c word:$ |  (1 samples: nl2bash)
ok  -  NB:9675  t=$(tty) echo ee | tee $t | foo
# E cmd:E cmd:echo |  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkPipeToNowhere7:1  echo foo | var=$(cat) ls
# E cmd:E word:$  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkPrefixAssign1:1  var=foo echo $var
# cd cmd:c cmd:cd |  (1 samples: nl2bash)
ok  -  NB:501  cd foo | cat
# cd cmd:cd cmd:true |  (1 samples: nl2bash)
ok  -  NB:1848  true | cd /
# cmd::} cmd:true cmd:{false { | || }  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkExtraMaskedReturns34:1  { false || :; } | true
# cmd:[ cmd:c cmd:c+ word:"$ |  (1 samples: tldr)
ok  -  TL:common/[.md:18  [ "$variable" -eq|ne|gt|lt|ge|le integer ]
# cmd:[ cmd:c word:$ ||  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkOrNeq4:1  [ a != $cow || b != $foo ]
# cmd:[ cmd:c ||  (1 samples: makebook)
ok  -  MK:shell:208.6#1  [ -d MAKEVAR ] || mkdir -p MAKEVAR
# cmd:[ cmd:true word:$ ||  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkOrNeq7:1  [ $a != a ] || [ $a != b ] || true
# cmd:[ redir:<w  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkNumberComparisons8:1  [ foo <= bar ]
# cmd:c cmd:c+ cmd:printf |  (1 samples: tldr)
ok  -  TL:linux/chpasswd.md:21  printf "username:new_password" | sudo chpasswd -c NONE|DES|MD5|SHA256|SHA512
# cmd:c cmd:c+ cmd:time |  (1 samples: tldr)
ok  -  TL:linux/lsns.md:20  lsns -t mnt|net|ipc|user|pid|uts|cgroup|time
# cmd:c cmd:c+ redir:>~ word:~ |  (1 samples: nl2bash)
ok  -  NB:4365  find ~/code -name '.*' -prune -o -type f -a -perm /u+x -printf ':%h\n' |sort |uniq |tr -d '\n' > ~/.codepath
# cmd:c cmd:c+ redir:N>w |  (1 samples: nl2bash)
ok  -  NB:2074  find / -name \*.dbf -print0 2>/dev/null | xargs -0 -n1 dirname | sort | uniq
# cmd:c cmd:echo redir:>>w |  (1 samples: tldr)
ok  -  TL:linux/systemd-creds.md:20  echo -n text | systemd-creds encrypt --name name --pretty - - >>service
# cmd:c cmd:echo word:"$ word:$ |  (1 samples: nl2bash)
ok  -  NB:5795  echo " RDBMS exit code : $RC  "     | tee -a ${LOG_FILE}
# cmd:c cmd:echo word:"$ word:$ | ||  (1 samples: nl2bash)
ok  -  NB:2214  find /directory/whatever -name '*.tar.gz' -mtime +$DAYS | grep 'tar.gz' || echo "You don't have files older than $DAYS days"
# cmd:c cmd:echo word:~ |  (1 samples: nl2bash)
ok  -  NB:1087  echo -e  'y\n'|ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa
# cmd:c cmd:false ||  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkUseBeforeDefinition5:1e15  false || mycmd;
# cmd:c cmd:kill |  (1 samples: tldr)
ok  -  TL:linux/scrun.md:32  scrun create|start|kill|delete container_id --debug
# cmd:c cmd:printf word:"$ |  (1 samples: nl2bash)
ok  -  NB:11622  printf '%s' "$pass" | md5
# cmd:c cmd:true ||  (1 samples: nl2bash)
ok  -  NB:8352  find MyApp.app -name Headers -type d -exec rm -rf "{}" \; || true
# cmd:c cmd:{c word:{ { | }  (1 samples: nl2bash)
ok  -  NB:685  yes 123456789 | grep --line-buffered . | { head -n 1; head -n 1; }
# cmd:c redir:<"$>>"$  (1 samples: cookbook)
ok  -  BC:ch06/checkfile:15  doscience < "$INFILE" >> "$OUTFILE"
# cmd:c redir:<w word:"$ word:$  (1 samples: nl2bash)
ok  -  NB:1763  ssh $USER@$SERVER "cd ${REMOTE_PATH}; mkdir -p $i" < /dev/null
# cmd:c redir:<w+  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkMultipleAppends3:1  foo < file; bar < file; baz < file;
# cmd:c redir:<w>w word:*  (1 samples: nl2bash)
ok  -  NB:4876  find <path> -xdev -type f -name *.txt -exec ls -l {} \;
# cmd:c redir:<~>~  (1 samples: tldr)
ok  -  TL:common/antibody.md:8  antibody <~/.zsh_plugins.txt bundle >~/.zsh_plugins.sh
# cmd:c redir:>>w word:$*  (1 samples: nl2bash)
ok  -  NB:12045  find $DBA/$ORACLE_SID/bdump/*.trc -mtime -1 -print >> /tmp/trace_list.lst
# cmd:c redir:>>w word:* |  (1 samples: nl2bash)
ok  -  NB:3440  find /mnt/naspath -mtime 0  -name .snapshot -prune -o \( \! -name *~ -print0 \) | du --files0-from=- -hc | tail -n1 >> /tmp/size.log
# cmd:c redir:>>w+  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkMultipleAppends1:1  foo >> file; bar >> file; baz >> file;
# cmd:c redir:>w word:$  (1 samples: nl2bash)
ok  -  NB:10576  find $HOME/projects/ -name ".*" -ls > foo.txt
# cmd:c redir:>w word:$ word:*  (1 samples: nl2bash)
ok  -  NB:2356  find $HOME/. -name *.txt -exec head -n 1 -v {} \; > report.txt
# cmd:c redir:>w word:~ |  (1 samples: nl2bash)
ok  -  NB:10817  find ~/lpi103-2/ -depth -print0 | cpio --null -o > ../lpicpio.2
# cmd:c redir:>w>w  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkPipeToNowhere12:1  ls > foo > bar
# cmd:c redir:>wN>w  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkRedirectToSame5:1  foo > bar 2> bar
# cmd:c redir:>wN>w>w  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkPipeToNowhere13:1  ls > foo 2> bar > baz
# cmd:c redir:>~ |  (1 samples: nl2bash)
ok  -  NB:3299  find . -mtime +2 | perl -pe 's{^}{\"};s{$}{\"}' > ~/output.file
# cmd:c redir:N>w word:$ |  (1 samples: nl2bash)
ok  -  NB:1925  crontab -u $user -l 2>/dev/null | grep -v '^#'
# cmd:c redir:N>w+  (1 samples: nl2bash)
ok  -  NB:8597  find /etc -type f -print0 2>/dev/null | xargs -0 grep --color=AUTO -Hn 'nameserver' 2>/dev/null
# cmd:c word:"$ word:"$* |  (1 samples: nl2bash)
ok  -  NB:2966  find "${searchpath}" -type f -print0 | xargs -0 grep -l -E "${string1}".*"${string2}".*"${string3}"
# cmd:c word:"$ word:$*  (1 samples: nl2bash)
ok  -  NB:2044  find "$source_dir" -name *.$input_file_type
# cmd:c word:"$ word:*  (1 samples: nl2bash)
ok  -  NB:7137  rsync --recursive --exclude 'foo' * "$other"
# cmd:c word:"$ word:* |  (1 samples: nl2bash)
ok  -  NB:8569  find /var/log/apache2/access*.gz -type f -newer ./tmpoldfile ! -newer ./tmpnewfile \ | xargs zcat | grep -E "$MONTH\/$YEAR.*GET.*ad=$ADVERTISER HTTP\/1" -c
# cmd:c word:"$*  (1 samples: shellcheck)
ok  -  SC:Checks/Commands.hs:prop_checkCatastrophicRmB:1  rm -rf "$STEAMROOT/"*
# cmd:c word:$* word:*  (1 samples: nl2bash)
ok  -  NB:7353  find $backup_path/* -name *.sql -mtime +30 -exec rm {} \;
# cmd:c word:*~ |  (1 samples: nl2bash)
rej  -  NB:6367  find ~/bin/FilesDvorak/.* -maxdepth 0 | awk -F"/" '{ print $6 }'
# cmd:c+ cmd:echo word:$ |  (1 samples: tldr)
ok  -  TL:common/$.md:24  echo $PS0|PS1|PS2|PS3|PS4
# cmd:c+ cmd:kill |  (1 samples: tldr)
ok  -  TL:linux/kill.md:13  kill -l|-L|--table
# cmd:echo cmd:false |  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkExtraMaskedReturns14:1  echo asdf | false
# cmd:echo cmd:true word:"$ |  (1 samples: nl2bash)
ok  -  NB:1849  true | echo "$ret"
# cmd:echo redir:>>"$  (1 samples: tldr)
ok  -  TL:common/newsboat.md:12  echo http://example.com/path/to/feed >>"${HOME}/.newsboat/urls"
# cmd:echo redir:>>w  (1 samples: tldr)
ok  -  TL:common/echo.md:21  echo "Hello World" >>file.txt
# cmd:echo redir:>w word:$  (1 samples: makebook)
ok  -  MK:shell:97.39#1  echo $i has no value > /dev/stderr
# cmd:false cmd:true cmd:true+ |  (1 samples: nl2bash)
ok  -  NB:8216  true | true | false | true | false
# cmd:false cmd:true | ||  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkExtraMaskedReturns6:1  false | true || true
# cmd:test redir:>w  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkTestRedirects1:1  test 3 > 1
# cmd:test redir:N>w  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkTestRedirects4:1  test 1 -eq 2 2> file
# cmd:time redir:>w  (1 samples: nl2bash)
ok  -  NB:1578  time find . -type f -exec stat {} + > /dev/null
# cmd:true cmd:true} cmd:{false { | || }  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkExtraMaskedReturns33:1  { false || true; } | true
# cmd:x:c redir:>w x:  (1 samples: shellcheck)
ok  -  SC:Analytics.hs:prop_checkSpuriousExec6:1e16  exec foo > file;
# cmd:x:c word:$ x:  (1 samples: cookbook)
ok  -  BC:ch16/run_screen:57  exec screen -r $USER/$screen_to_use
# cmd:{time redir:N>w { }  (1 samples: nl2bash)
ok  -  NB:7890  { time sleep 1 ; } 2> time.txt
# builtin *  (1240 samples: cookbook,makebook,nl2bash,pure-bash-bible,pure-sh-bible,shellcheck,tldr)
rej -  BC:ch16/builtin_tty.c:26c17  break;
# keyword *  (755 samples: cookbook,makebook,nl2bash,pure-bash-bible,pure-sh-bible,shellcheck,tldr)
rej -  BC:ch13/getopts_custom:28c9  esac >&2
# no command name  @ a  (321 samples: cookbook,nl2bash,pure-bash-bible,pure-sh-bible,shellcheck,tldr)
rej -  BC:ch10/func_max.1:13c5  HIDN=5
# command name not literal  (241 samples: cookbook,makebook,nl2bash,pure-bash-bible,pure-sh-bible,shellcheck,tldr)
rej -  SC:Analytics.hs:prop_checkUnnecessaryArithmeticExpansionIndex2:1  a[1+1]=n
# unsupported parameter form  @ $9  (239 samples: cookbook,makebook,nl2bash,pure-bash-bible,pure-sh-bible,shellcheck)
rej -  NB:6272  seq $1
# missing word  @ (a  (166 samples: nl2bash,shellcheck,tldr)
rej -  SC:Analytics.hs:prop_checkExtraMaskedReturns3:1  ls >(cat)
# unsupported parameter form  @ ${a  (165 samples: cookbook,nl2bash,pure-bash-bible,pure-sh-bible,shellcheck,tldr)
rej -  SC:Analytics.hs:prop_checkDollarStar9:1  ls ${arr[*]}
# '$' starting no expansion  @ $  (155 samples: cookbook,makebook,nl2bash,pure-bash-bible,pure-sh-bible,tldr)
ok  -  TL:common/regex.md:18  world$
# no command name  @ a=  (138 samples: cookbook,nl2bash,pure-bash-bible,pure-sh-bible,shellcheck,tldr)
rej -  PS:README.md:636  end=50
# unquoted '}'  @ }  (132 samples: cookbook,nl2bash,pure-bash-bible,pure-sh-bible,shellcheck,tldr)
rej -  NB:2614  find . -type d -exec /path/to/script.sh \{} \;
# unexpected '('  @ ()  (127 samples: cookbook,pure-bash-bible,pure-sh-bible,shellcheck,tldr)
rej -  PB:README.md:2102  bar() {
# missing word  @   (126 samples: nl2bash,tldr)
rej -  TL:common/ex.md:13  wq<Enter>
# bash-only $ form  @ $  (107 samples: cookbook,nl2bash,pure-bash-bible,shellcheck,tldr)
rej -  SC:Analytics.hs:prop_checkSuspiciousIFS2:1  IFS=$'\t'
# shell-set variable *  (89 samples: cookbook,nl2bash,pure-bash-bible,pure-sh-bible,shellcheck,tldr)
ok  -  SC:Analytics.hs:prop_checkSpacefulnessCfg19:1  echo $PWD
# missing command  (83 samples: cookbook,nl2bash,pure-bash-bible,pure-sh-bible,tldr)
rej -  BC:ch15/command_substitution:10  result=$(
# unsupported cd form  (76 samples: cookbook,makebook,nl2bash,shellcheck,tldr)
rej -  NB:356  cd -L ..
# unquoted '{'  @ {  (74 samples: cookbook,nl2bash,shellcheck,tldr)
rej -  TL:common/}.md:7  tldr {
# unquoted '{'  @ {}  (59 samples: nl2bash,shellcheck)
ok  -  SC:Checks/Commands.hs:prop_checkXargsDashi2:1  xargs -I{} echo {}
# '((' at the start of a command  (54 samples: cookbook,pure-bash-bible,shellcheck,tldr)
rej -  SC:Analytics.hs:prop_checkArithmeticDeref5:1  (($1))
# unsupported parameter form  @ $@  (50 samples: cookbook,makebook,nl2bash,pure-bash-bible,pure-sh-bible,shellcheck)
rej -  SC:Analytics.hs:prop_checkConcatenatedDollarAt4:1  echo $@
# here-document  (43 samples: cookbook,makebook,nl2bash,shellcheck,tldr)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms139:1  cat <<< foo
# unexpected ')'  @ )  (40 samples: cookbook,makebook,nl2bash,pure-bash-bible)
rej -  BC:ch14/MakeTemp:23c9  file )
# missing word  @ <a>  (33 samples: tldr)
rej -  TL:common/vimdiff.md:21  <]><c>
# bad arithmetic expression  (31 samples: cookbook,nl2bash,pure-bash-bible,shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms3:1  echo $((i++))
# unsupported parameter form  @ $*  (31 samples: cookbook,nl2bash,pure-bash-bible,pure-sh-bible,shellcheck)
rej -  SC:Checks/Commands.hs:prop_checkEvalArray5:1  eval "$*"
# empty command  (26 samples: makebook,tldr)
rej -  MK:recipe:90.13  #
# unquoted '{'  @ {}.a  (26 samples: nl2bash)
ok  -  NB:9976  find -name "*.txt" cp {} {}.bkup \;
# no command name  @ a9=  (25 samples: cookbook,nl2bash,pure-bash-bible,pure-sh-bible,shellcheck,tldr)
rej -  SC:Analytics.hs:prop_checkPS18:1  PS1='\[\e\]'
# no command name  @ a=$(  (21 samples: nl2bash,pure-sh-bible,shellcheck)
rej -  NB:7925  a=$(false)
# no command name  @ a=9;  (21 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkPlusEqualsNumber7:1  n=4; x+=n
# unquoted '{'  @ {9..  (21 samples: nl2bash,pure-bash-bible,shellcheck,tldr)
rej -  SC:Analytics.hs:prop_checkArrayAsString4:1  a={1..10}
# unsupported parameter form  @ $?  (21 samples: cookbook,nl2bash,shellcheck,tldr)
ok  -  TL:common/echo.md:29  echo $?
# missing word  @ <a  (20 samples: tldr)
rej -  TL:common/wuzz.md:16  <Ctrl j><Tab>
# unsupported parameter form  @ ${9:  (20 samples: cookbook,nl2bash,pure-bash-bible,pure-sh-bible)
rej -  BC:ch06/dashes:18c16  CHAR=${1:--}
# final backslash  (19 samples: makebook,nl2bash)
rej -  MK:recipe:164.49  MAKEVAR          \
# unsupported parameter form  @ $$  (19 samples: nl2bash,pure-sh-bible)
rej -  NB:6082  ps -p $$
# unterminated quote  (19 samples: nl2bash,shellcheck,tldr)
rej -  NB:2325  find -name '*.jpg
# unquoted '^'  @ ^a  (18 samples: makebook,nl2bash,tldr)
ok  -  TL:common/git-alias.md:17  git alias ^name
# unquoted '{'  @ {a  (16 samples: nl2bash,pure-bash-bible,shellcheck,tldr)
rej -  PB:README.md:1979  exec {sleep_fd}<> <(:)
# bracket expression with a quote, expansion or slash  (15 samples: cookbook,nl2bash,pure-bash-bible,shellcheck,tldr)
rej -  BC:ch07/hist.awk:17c5  user[$3]++
# unsupported exit status  (15 samples: cookbook,nl2bash,shellcheck,tldr)
rej -  NB:1863  exit N
# no command name  @ a=(  (14 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkSplittingInArrays8:1  a=( * )
# no command name  @ a=a  (14 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkPlusEqualsNumber6:1  n=foo; x+=n
# unexpected '('  @ (a  (14 samples: cookbook,makebook,shellcheck,tldr)
rej -  BC:ch16/builtin_tty.c:12  tty_builtin (list)
# unexpected '('  @ (  (13 samples: cookbook,makebook,nl2bash,shellcheck)
rej -  BC:ch16/builtin_tty.c:28c17  builtin_usage ( );
# unexpected '|'  @ |&  (13 samples: nl2bash,shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms142:1  make |& less
# unsupported parameter form  @ ${!a  (13 samples: pure-bash-bible,shellcheck,tldr)
rej -  SC:Analytics.hs:prop_checkUnassignedReferences22:1  echo ${!os*}
# unquoted expansion in a redirection target  @ $a  (12 samples: nl2bash,shellcheck,tldr)
ok  -  NB:1012  wc -l < $FILE
# no command name  @ a=$  (11 samples: nl2bash)
rej -  NB:8202  me=$(whoami)
# unsupported parameter form  @ ${9}  (11 samples: cookbook,nl2bash,pure-bash-bible)
rej -  BC:ch13/pluralize:12c9  echo ${1}
# no command name  @ a=`a  (10 samples: nl2bash,shellcheck)
rej -  NB:1229  f=`mktemp -p .`
# unsupported parameter form  @ ${9#  (10 samples: cookbook,pure-bash-bible,pure-sh-bible)
rej -  BC:ch13/getopts_custom:21c13  printf "Usage: %s: [-a] [-b value] args\n" ${0##*/}
# unterminated double quote  (10 samples: nl2bash)
rej -  NB:3526  find . -type f -name ".*
# '$' starting no expansion  @ $//  (9 samples: nl2bash)
ok  -  NB:7622  find dir -type f -print0 | xargs -0 sed -i .bak -E "s/[[:space:]]*$//"
# 'NAME+='  (9 samples: nl2bash,pure-bash-bible,shellcheck)
rej -  SC:Analytics.hs:prop_checkPlusEqualsNumber5:1  x+='1'
# missing word  @ <(a  (8 samples: nl2bash,shellcheck)
rej -  SC:Analytics.hs:prop_checkExtraMaskedReturns1:1  cat < <(ls)
# no command name  @ <a  (8 samples: nl2bash,shellcheck,tldr)
rej -  NB:7673  rm $(<xaa)
# pattern in a redirection target  (8 samples: shellcheck,tldr)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms19:1  foo > file*.txt
# unquoted '^'  @ ^  (8 samples: makebook,nl2bash,tldr)
ok  -  TL:common/git-paste.md:13  git paste @^
# unquoted '{'  @ {9,9  (8 samples: nl2bash,shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkBraceExpansionVars2:1  echo {1,3,$n}
# unsupported parameter form  @ $9:$  (8 samples: cookbook)
rej -  BC:ch16/func_pathmunge:10c13  PATH="$1:$PATH"
# unsupported parameter form  @ ${9%  (8 samples: cookbook,pure-bash-bible,pure-sh-bible)
rej -  BC:ch12/mkalbum:33c5  LASTPH="${5%.*}.html"
# 'exec' without a command  (7 samples: nl2bash,shellcheck,tldr)
rej -  TL:common/less-than-more-than.md:16  exec 3<>-
# missing word  @ <a>|  (7 samples: tldr)
rej -  TL:common/herdr.md:38  <Ctrl b><v>|<->
# no command name  @ >  (7 samples: nl2bash,shellcheck)
rej -  SC:Analytics.hs:prop_checkRedirectedNowhere3:1  grep foo | > bar
# unsupported parameter form  @ $#  (7 samples: cookbook,nl2bash,pure-bash-bible,shellcheck,tldr)
rej -  TL:common/$.md:32  echo $#
# unsupported parameter form  @ $9)  (7 samples: cookbook,nl2bash)
rej -  NB:6911  pushd $(dirname $0)
# unsupported parameter form  @ $9`  (7 samples: nl2bash)
rej -  NB:8133  DIR=`pwd`/`dirname $0`
# '>&' takes one digit or '-'  (6 samples: cookbook,nl2bash,shellcheck,tldr)
rej -  BC:ch15/fpmath:13c5  echo "scale=5" >& ${bcin}
# no command name  @ a=(9  (6 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkCommarrays7:1  a=(1,2)
# no command name  @ a=`  (6 samples: nl2bash)
rej -  NB:9193  OS=`uname -s`
# unquoted '{'  @ {}\;  (6 samples: nl2bash)
ok  -  NB:3376  find -exec <script> {}\;
# unquoted '{'  @ {}’  (6 samples: nl2bash)
ok  -  NB:2602  find folder_name -type d -exec chmod 775 ‘{}’ \;
# unsupported parameter form  @ ${  (6 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkExpansionWithRedirection3:1  var=${ foo >> bar; }
# unsupported parameter form  @ ${#a  (6 samples: cookbook,pure-bash-bible,shellcheck,tldr)
rej -  SC:Analytics.hs:prop_checkUnassignedReferences21:1  echo ${#foo}
# no command name  @ </>a  (5 samples: tldr)
rej -  TL:common/zmore.md:16  </>regex
# no command name  @ a9  (5 samples: cookbook,nl2bash)
rej -  BC:ch06/strvsnum:7  VAR2="5"
# unquoted '{'  @ {a..  (5 samples: nl2bash,pure-bash-bible,tldr)
rej -  PB:README.md:1330  echo {A..Z}
# unsupported 'exec' form  (5 samples: shellcheck,tldr)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms13:1  exec -c env
# unsupported parameter form  @ $$/a  (5 samples: nl2bash)
rej -  NB:6664  echo $(cat /proc/$$/cmdline)
# unsupported parameter form  @ $9))  (5 samples: nl2bash)
rej -  NB:370  cd $(dirname $(readlink -f $0))
# unsupported parameter form  @ ${9/  (5 samples: pure-bash-bible)
rej -  PB:README.md:558c5-559  # Usage: urldecode "string"@N    : "${1//+/ }"
# unsupported parameter form  @ ${a:  (5 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkSpacefulnessCfg27:1  echo ${a:+'foo'}
# '$' starting no expansion  @ $//a  (4 samples: nl2bash)
ok  -  NB:7577  find /home -type f -name "*.ext" -exec sed -i -e "s/\r$//g" {} \;
# missing word  @ (  (4 samples: cookbook,nl2bash)
rej -  NB:5213  more <( ls /usr/bin )
# missing word  @ <a><  (4 samples: tldr)
rej -  TL:linux/minicom.md:25  <Ctrl a><x><Enter>
# missing word  @ |  (4 samples: nl2bash)
rej -  NB:1033  grep "OK" <filename> | wc -l
# no command name  @ a=9  (4 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkUnused37:1  fd=2; exec {fd}>&-
# unquoted '{'  @ {a,a  (4 samples: nl2bash,shellcheck,tldr)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms137a:1  echo {a,b}
# unsupported parameter form  @ $-  (4 samples: cookbook,pure-sh-bible,shellcheck)
rej -  PS:README.md:1003  "$-"
# unsupported parameter form  @ $9/$  (4 samples: nl2bash,shellcheck)
rej -  SC:Checks/Commands.hs:prop_checkCatastrophicRm1:1  rm -r $1/$2
# unsupported parameter form  @ ${a/  (4 samples: pure-bash-bible,shellcheck)
rej -  PB:README.md:428c5  printf '%s\n' "${_//\"}"
# missing word  @ (./a  (3 samples: nl2bash)
rej -  NB:1563  diff <(./a) <(./b)
# missing word  @ (a)  (3 samples: nl2bash,shellcheck)
rej -  SC:Analytics.hs:prop_checkExtraMaskedReturns2:1  read -ra arr <(ls)
# no command name  @ <  (3 samples: pure-bash-bible,shellcheck)
rej -  SC:Analytics.hs:prop_checkRedirectedNowhere8:1  var=`< file`
# no command name  @ <:>a  (3 samples: tldr)
rej -  TL:common/vimdiff.md:33  <:>diffupdate
# no command name  @ >a  (3 samples: pure-bash-bible,pure-sh-bible,tldr)
rej -  TL:common/greater-than.md:24  >path/to/file
# unexpected '('  @ (){  (3 samples: pure-bash-bible,shellcheck)
rej -  SC:Analytics.hs:prop_checkSetESuppressed2:1  f(){ :; }; x=$(f)
# unquoted '^'  @ ^9  (3 samples: tldr)
ok  -  TL:common/set-nodeversion.md:13  Set-NodeVersion ^20
# unquoted '{'  @ {,}  (3 samples: nl2bash)
rej -  NB:1793  awk -f script.awk file{,} | column -t
# unquoted '{'  @ {a}>  (3 samples: shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms28:1  exec {n}>&2
# unquoted '{'  @ {}-a  (3 samples: nl2bash)
ok  -  NB:3686  find . -name "sample*" | xargs -i echo program {}-out {}
# unquoted expansion in a redirection target  @ $$  (3 samples: nl2bash)
rej -  NB:11405  find . -name ‘*.mp4’ >> /tmp/$$
# unquoted expansion in a redirection target  @ $$;  (3 samples: makebook)
rej -  MK:recipe:53.2  MAKEVAR -M MAKEVAR MAKEVAR > MAKEVAR.$$;                  \@Nsed 's,\(MAKEVAR\)\.o[ :]*,\1.o MAKEVAR : ,g' < MAKEVAR.$$ > MAKEVAR; \@Nrm -f MAKEVAR.$$
# unsupported parameter form  @ $9*  (3 samples: nl2bash)
rej -  NB:5084  find /usr /bin /sbin /opt -name "$1*" -type f -ls
# unsupported parameter form  @ $9/a  (3 samples: nl2bash)
rej -  NB:1113  ln -s "`pwd`" $1/link
# unsupported parameter form  @ $9:a  (3 samples: cookbook,nl2bash)
rej -  NB:7049  chown -R $1:httpd *
# unsupported parameter form  @ $@)  (3 samples: makebook,nl2bash)
rej -  NB:6944  read -r -p "$(echo $@) ? [y/N] " YESNO
# unsupported ~ form  (3 samples: shellcheck,tldr)
rej -  TL:common/~.md:16  ls ~-
# '! !'  (2 samples: shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkMultipleBangs1:1  ! ! true
# '$' starting no expansion  @ $/.a  (2 samples: nl2bash)
ok  -  NB:7741  find . -name "*.andnav" | rename "s/\.andnav$/.tile/"
# '$' starting no expansion  @ $//;  (2 samples: nl2bash)
ok  -  NB:1437  sed -n "s/^$//;t;p;"
# '$' starting no expansion  @ $/\9  (2 samples: nl2bash)
ok  -  NB:6595  mount | tail -1 | sed -e "s/^[^/]*\(.*\) type .*$/\1/g"
# '$' starting no expansion  @ $|\.  (2 samples: nl2bash)
ok  -  NB:4245  find . -type f | grep -P "\.dll$|\.exe$"
# '$' starting no expansion  @ $|a  (2 samples: nl2bash)
ok  -  NB:1041  git ls-files | sed 's/ /\\ /g' | grep -E "\.*(swift$|mm$)" | xargs wc -l
# backslash-newline in a word  (2 samples: shellcheck)
rej -  SC:Checks/Commands.hs:prop_checkUnquotedEchoSpaces6:1c9-2  echo foo\@N        bar
# missing word  @ <9>|  (2 samples: tldr)
rej -  TL:common/gpg-tui.md:28  <1>|<2>|<3>
# missing word  @ <:>a  (2 samples: tldr)
rej -  TL:common/vimtutor.md:13  <Esc><:>q<Enter>
# missing word  @ <?>  (2 samples: tldr)
rej -  TL:common/htop.md:34  <F1>|<?>
# missing word  @ >(a  (2 samples: nl2bash)
rej -  NB:7292  exec > >(tee -a $HOME/logfile) 2>&1
# no command name  @ <a>a  (2 samples: tldr)
rej -  TL:common/clifm.md:29  <r>sel
# no command name  @ a=([  (2 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkCommarrays5:1  a=([a]=b, [c]=d)
# no command name  @ a=(a  (2 samples: shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms143:1  a=(foo bar)
# unexpected '('  @ ($9,  (2 samples: makebook)
rej -  MK:recipe:185.44  { print substr($1, 1, length($1)-1) }' $1 |      \@Nsort |                                                    \@Npr -T -w 80 -4
# unexpected '('  @ ()(a  (2 samples: pure-bash-bible)
rej -  PB:README.md:653c5  f()(printf '%s\n' "${BASH_ARGV[@]}"); f "$@"
# unexpected '('  @ ()a  (2 samples: pure-bash-bible)
rej -  PB:README.md:1889  f()for i in "$@"; do echo "$i"; done
# unexpected ')'  @ ))  (2 samples: makebook)
rej -  MK:recipe:89.23  MAKEVAR))
# unexpected ')'  @ ))))  (2 samples: makebook)
rej -  MK:recipe:94.37  MAKEVAR))))))
# unquoted '^'  @ ^#  (2 samples: nl2bash)
ok  -  NB:1926  cd /var/cron/tabs && grep -vH ^# *
# unquoted '^'  @ ^$  (2 samples: nl2bash)
ok  -  NB:1030  cat fileName | grep -v ^$ | wc -l
# unquoted '^'  @ ^$a  (2 samples: nl2bash)
ok  -  NB:5600  ls -1 | grep -v ^$EXCLUDE | xargs -I{} mv {} $TARGET
# unquoted '^'  @ ^@  (2 samples: nl2bash)
ok  -  NB:922  diff -U 0 file1 file2 | grep ^@ | wc -l
# unquoted '{'  @ {*}  (2 samples: tldr)
rej -  TL:linux/csplit.md:17  csplit path/to/file 5 {*}
# unquoted '{'  @ {,a  (2 samples: nl2bash,shellcheck)
rej -  SC:Checks/Commands.hs:prop_checkMvArguments3:1  mv 'foo bar'{,bak}
# unquoted '{'  @ {.}  (2 samples: nl2bash)
rej -  NB:11642  find . -type f -wholename \*.mbox | parallel mv {} {.}
# unquoted '{'  @ {9  (2 samples: nl2bash,shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkBraceExpansionVars3:1  eval echo DSC{0001..$n}.jpg
# unquoted '{'  @ {9a9  (2 samples: tldr)
rej -  TL:common/roll.md:20  roll --verbose 2{2d12}
# unquoted '{'  @ {9}  (2 samples: nl2bash)
rej -  NB:4687  ifconfig en0 | grep -Eo ..\(\:..\){5}
# unquoted '{'  @ {{a.  (2 samples: nl2bash)
rej -  NB:4580  echo -e {{a..n},ñ,{o..z}}"\n" | nl
# unquoted '{'  @ {}\  (2 samples: nl2bash)
ok  -  NB:12345  find "Test Folder" -type d -name .dummy -exec rm -rf \"{}\" \;
# unquoted '{'  @ {}a  (2 samples: nl2bash)
ok  -  NB:6577  find . -exec echo xx{}xx \;
# unquoted '}'  @ };  (2 samples: cookbook)
rej -  BC:ch16/builtin_tty.c:46  };
# unquoted expansion in a redirection target  @ $((a  (2 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkModifiedArithmeticInRedirection1:1  ls > $((i++))
# unsupported parameter form  @ $$a9  (2 samples: cookbook)
rej -  BC:ch12/oodiff:32  PRIV2="/tmp/${BAS2}.$$_2"
# unsupported parameter form  @ $9*.  (2 samples: nl2bash)
rej -  NB:11427  find "/path/to/pdfs/" -type f -name "$1*.pdf" -exec stat -f "%10Dm %SN" {}\;  | sort -k1,1n -k2,2
# unsupported parameter form  @ $9:  (2 samples: cookbook,makebook)
rej -  BC:ch16/func_tweak_path:105c5  local pattern=":$1:"
# unsupported parameter form  @ $9;  (2 samples: makebook,shellcheck)
rej -  SC:Analytics.hs:prop_checkSpacefulnessCfg32:1  var=$1; [ -v var ]
# unsupported parameter form  @ $9\  (2 samples: nl2bash,shellcheck)
rej -  SC:Analytics.hs:prop_checkSpacefulnessCfg31:1  echo "`echo \"$1\"`"
# unsupported parameter form  @ $9\a  (2 samples: nl2bash)
rej -  NB:8155  ver=`echo -ne "$1\n$2" |sort -Vr |head -n1`
# unsupported parameter form  @ ${#9  (2 samples: cookbook)
rej -  BC:ch16/func_cd:20c9-21  # We are using special syntax@N        length=${#1}  # Assume that $1 has nothing but dots and count them
# unterminated backquote  (2 samples: cookbook,nl2bash)
rej -  NB:11450  find . -maxdepth 1 -type f -name 'image*png' `
# '$' starting no expansion  @ $%  (1 samples: tldr)
ok  -  TL:linux/fcrackzip.md:12  fcrackzip -v -b -l 3 -c a:$% archive
# '$' starting no expansion  @ $)  (1 samples: nl2bash)
ok  -  NB:7251  find . | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rf
# '$' starting no expansion  @ $.  (1 samples: nl2bash)
ok  -  NB:11644  find . -type f  -name "your_pattern" -exec du -ch {} + 2>/dev/null | grep total$.
# '$' starting no expansion  @ $/,/  (1 samples: nl2bash)
rej -  NB:8129  subj="$(date) - $(hostname) - $(echo "$changes" | sed "s/$/,/" | tr "\n" " ")"
# '$' starting no expansion  @ $::  (1 samples: nl2bash)
rej -  NB:8058  JAVA_HOME="$( readlink -f "$( which java )" | sed "s:bin/.*$::" )"
# '$' starting no expansion  @ $<  (1 samples: makebook)
rej -  MK:recipe:165.27  MAKEVAR MAKEVAR MAKEVAR MAKEVAR -M $< | \@NMAKEVAR 's,\($(notdir $*)\.o\) *:,$(dir $@)\1 $@: ,' > $@.tmp
# '$' starting no expansion  @ $\a-  (1 samples: cookbook)
ok  -  BC:ch16/inputrc:41c3-43  # Edit variable on current line.@N    #"\M-\C-v": "\C-a\C-k$\C-y\M-\C-e\C-a\C-y="@N    "\C-xe": "\C-a\C-k$\C-y\M-\C-e\C-a\C-y="
# '$' starting no expansion  @ $\|^  (1 samples: nl2bash)
ok  -  NB:3993  find -regex "^.*~$\|^.*#$"
# '$' starting no expansion  @ $`  (1 samples: nl2bash)
ok  -  NB:6200  wc `find | grep .php$`
# '$' starting no expansion  @ $|.a  (1 samples: nl2bash)
ok  -  NB:11379  find . -name “*.jar” -print -exec jar tvf {} \; |grep -E “jar$|.class”
# '<&' takes one digit or '-'  (1 samples: tldr)
rej -  TL:common/coproc.md:20  read <&"${name[0]}" variable
# bash-only $ form  @ $[9  (1 samples: shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms135:1  var=$[1 + 2]
# bash-only $ form  @ $[9+  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkDollarBrackets1:1  echo $[1+2]
# bash-only $ form  @ $[9/  (1 samples: nl2bash)
rej -  NB:4769  echo $[4/0] || exit $?
# missing word  @ (a))  (1 samples: nl2bash)
rej -  NB:4469  USERS=$(awk '/\/X/ {print $1}' <(w))
# missing word  @ <(  (1 samples: nl2bash)
rej -  NB:8321  read -t 3 variable < <( tail -f logfile.log | grep "something" )
# missing word  @ </>a  (1 samples: tldr)
rej -  TL:common/nvim.md:26  <Esc></>search_pattern<Enter>
# missing word  @ <:>%  (1 samples: tldr)
rej -  TL:common/nvim.md:30  <Esc><:>%s/regex/replacement/g<Enter>
# missing word  @ <~><  (1 samples: tldr)
rej -  TL:common/ssh.md:37  <Enter><~><.>
# missing word  @ |>  (1 samples: tldr)
rej -  TL:common/scim.md:29  <|>
# multi-digit descriptor  (1 samples: shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms47:1-2  #!/bin/dash@Necho foo 42>/dev/null
# no command name  @ <+|-  (1 samples: tldr)
rej -  TL:common/gource.md:37  <+|-|<|>>
# no command name  @ >/a  (1 samples: nl2bash)
rej -  NB:7294  { time find / &>/dev/null; } 2>&1 | grep real
# no command name  @ >>  (1 samples: nl2bash)
rej -  NB:11457  find ./ -type f -name '*.c*' -print0 | xargs -0 rm -rf &>> log_del.txt
# no command name  @ a9=$  (1 samples: nl2bash)
rej -  NB:7894  t1=$(date -u -d "1970.01.01-$string1" +"%s")
# no command name  @ a=$a  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkAssignToSelf1:1  x=$x
# no command name  @ a=${  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkAssignToSelf2:1  x=${x}
# no command name  @ a=($  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkUnassignedReferences53:1  x=($foo)
# no command name  @ a=*.  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkArrayAsString3:1  a=*.png
# no command name  @ a=;  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkSpacefulnessCfg38:1  a=; echo $a
# no command name  @ a=a+  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkWrongArit:1  i=i+1
# unexpected '('  @ ()((  (1 samples: pure-bash-bible)
rej -  PB:README.md:1880-1884  # Using arithmetic@N# This can be used to assign integer values.@N# Example: f a=1@N#          f a++@Nf()(($1))
# unexpected '('  @ ();  (1 samples: tldr)
rej -  TL:common/yacas.md:16  Example();
# unexpected '('  @ (*.[  (1 samples: nl2bash)
rej -  NB:5260  ls -d !(*.[ch])
# unexpected '('  @ (*.a  (1 samples: shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms4:1  rm !(*.hs)
# unexpected '('  @ (*@(  (1 samples: nl2bash)
rej -  NB:5261  ls -d !(*@(.c|.h))
# unexpected '('  @ (*a  (1 samples: nl2bash)
rej -  NB:5265  ls !(*foo)
# unexpected '('  @ (-9.  (1 samples: tldr)
rej -  TL:common/pnmnlfilt.md:16  pnmnlfilt -0.9..(-0.1) radius path/to/image.pnm >path/to/output.pnm
# unexpected '('  @ (9);  (1 samples: cookbook)
rej -  BC:ch16/builtin_tty.c:34c5  t = ttyname (0);
# unexpected '('  @ (a)a  (1 samples: tldr)
rej -  TL:common/yacas.md:12  Integrate(x)Cos(x);
# unexpected '('  @ (a*)  (1 samples: nl2bash)
rej -  NB:5266  ls !(b*)
# unexpected '('  @ (‘  (1 samples: nl2bash)
rej -  NB:2307  find -iname “*.c” -exec grep -l ‘main(‘ {} \; -a -exec cp {} test1/ \;
# unexpected ')'  @ )))  (1 samples: makebook)
rej -  MK:recipe:185.21  MAKEVAR)))
# unexpected 'N'  @ a  (1 samples: cookbook)
rej -  BC:ch16/builtin_tty.c:45c5  (char *)NULL
# unexpected 'c'  @ a  (1 samples: makebook)
rej -  MK:recipe:194.14  (/usr/java/toplink-2.5/TopLinkX.jar) cannot be found
# unexpected end  @   (1 samples: nl2bash)
rej -  NB:10760  (find $DIR/tmp/daily/ -name *.tar.gz | sort -n | head -2
# unquoted '^'  @ ^!  (1 samples: tldr)
ok  -  TL:common/git-range-diff.md:8  git range-diff commit_1^! commit_2^!
# unquoted '^'  @ ^-  (1 samples: nl2bash)
ok  -  NB:5935  diff -dbU0 a b | tail -n +4 | grep ^- | cut -c2-
# unquoted '^'  @ ^.*  (1 samples: nl2bash)
ok  -  NB:902  find /home/my_dir -name '*.txt' | xargs grep -c ^.*
# unquoted '^'  @ ^.*a  (1 samples: nl2bash)
ok  -  NB:1404  find ./ -type f -name \*.php -exec sed -i ’s/^.*iframe bla bla bla.*$//g’ {} \;
# unquoted '^'  @ ^9|9  (1 samples: tldr)
ok  -  TL:common/qalc.md:21  qalc 66+99|2^4|6 feet to cm|1 bitcoin to USD|20 kmph to mph|...
# unquoted '^'  @ ^[\>  (1 samples: nl2bash)
rej -  NB:924  diff file1 file2 | grep ^[\>\<] | wc -l
# unquoted '^'  @ ^[a-  (1 samples: nl2bash)
ok  -  NB:9012  apropos -s 3 . | grep ^[a-z]
# unquoted '^'  @ ^a.*  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkGlobbedRegex4:1  [[ $foo =~ ^c.* ]]
# unquoted '^'  @ ^|!$  (1 samples: tldr)
rej -  TL:common/!.md:25  command !^|!$|!*
# unquoted '{'  @ {$a.  (1 samples: shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkBraceExpansionVars4:1  echo {$i..100}
# unquoted '{'  @ {*.a  (1 samples: nl2bash)
rej -  NB:9967  tar --exclude={*.png,*.mp3,*.wav,.git,node_modules} -Jcf ${target_tarball}  ${source_dirname}
# unquoted '{'  @ {-9}  (1 samples: tldr)
rej -  TL:common/git-check-ref-format.md:12  git check-ref-format --branch @{-1}
# unquoted '{'  @ {.,}  (1 samples: nl2bash)
rej -  NB:5620  mv /path/subfolder/{.,}* /path/
# unquoted '{'  @ {.[!  (1 samples: nl2bash)
rej -  NB:5619  mv /source/path/{.[!.],}* /destination/path
# unquoted '{'  @ {.a  (1 samples: shellcheck)
rej -  SC:Checks/Commands.hs:prop_checkCatastrophicRm10:1  rm -r "${DIR}"/{.gitignore,.gitattributes,ci}
# unquoted '{'  @ {.}.  (1 samples: tldr)
rej -  TL:common/parallel.md:17  parallel convert {} {.}.png ::: *.jpg
# unquoted '{'  @ {9.  (1 samples: pure-bash-bible)
rej -  PB:README.md:1335-1337  # Print zero-padded numbers.@N# CAVEAT: bash 4+@Necho {01..100}
# unquoted '{'  @ {9.a  (1 samples: tldr)
rej -  TL:common/git-guilt.md:29  git guilt @{3.weeks.ago}
# unquoted '{'  @ {9}-  (1 samples: tldr)
rej -  TL:common/immich-go.md:25  immich-go -server=server_url -key=server_key tool album delete \d{4}-\d{2}-\d{2}
# unquoted '{'  @ {9}\  (1 samples: nl2bash)
rej -  NB:4690  ifconfig eth0 | grep -Eoi [:0-9A-F:]{2}\(\:[:0-9A-F:]{2}\){5}
# unquoted '{'  @ {?,[  (1 samples: nl2bash)
rej -  NB:8907  find /path/to/directory/folder{?,[1-4]?,50} -name '*.txt'
# unquoted '{'  @ {a9  (1 samples: nl2bash)
rej -  NB:8022  mpv --no-audio \`ls ~/Down/other/*.{mp4,flv} --color=never\`
# unquoted '{'  @ {a?  (1 samples: cookbook)
rej -  BC:ch10/ad:103c9  rm -fv {ch??,app?}.{pdf,xml,html} book.xml docbook-xsl.css     # <12>
# unquoted '{'  @ {{a  (1 samples: shellcheck)
rej -  SC:Checks/Commands.hs:prop_checkCatastrophicRm12:1  rm -r /{{usr,},{bin,sbin}}/$exec
# unquoted '{'  @ {{a,  (1 samples: shellcheck)
rej -  SC:Checks/Commands.hs:prop_checkCatastrophicRm13:1  rm -r /{{a,b},{c,d}}/$exec
# unquoted '{'  @ {},  (1 samples: nl2bash)
ok  -  NB:5274  ls | xargs -I {} echo {}, | xargs echo
# unquoted '{'  @ {}/*  (1 samples: nl2bash)
ok  -  NB:2643  find  . -type d -mindepth 1 -print -exec chmod 755 {}/* \;
# unquoted '{'  @ {}/a  (1 samples: nl2bash)
ok  -  NB:1159  find . -type d -exec touch {}/index.html \;
# unquoted '{'  @ {}[9  (1 samples: nl2bash)
ok  -  NB:1208  find /path/to/dir -name '*.pdf' -exec convert -thumbnail x80 {}[0] {}-thumb.png \;
# unquoted '}'  @ }.a  (1 samples: nl2bash)
rej -  NB:2178  find $STARTDIR -name '*.ps' -print | sed -e 's/.ps$//' | xargs -l -i  ps2pdf \{}.ps
# unquoted expansion in a redirection target  @ $@  (1 samples: makebook)
rej -  MK:recipe:219.15  printf "#! /bin/bash -x\nmake\n" > $@
# unquoted expansion in a redirection target  @ $a.  (1 samples: nl2bash)
ok  -  NB:10303  find $x -type d -wholename '*' ! -wholename */@eaDir* > /tmp/mediaindex/$nn.dir
# unquoted expansion in a redirection target  @ ${a  (1 samples: nl2bash)
rej -  NB:10611  find src/js -type f -name "*.js" -exec cat {} >> ${jsbuild}$@ \;
# unsupported parameter form  @ $!  (1 samples: nl2bash)
ok  -  NB:9049  kill $!
# unsupported parameter form  @ $!|$  (1 samples: tldr)
rej -  TL:common/$.md:16  echo $!|$?
# unsupported parameter form  @ $#;  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkSpacefulnessCfg36:1  arg=$#; echo $arg
# unsupported parameter form  @ $$.a  (1 samples: cookbook)
rej -  BC:ch12/cdscript:17  ISOIMAGE=/tmp/cd$$.iso                                # <1>
# unsupported parameter form  @ $$`  (1 samples: nl2bash)
rej -  NB:4624  ps | grep `echo $$` | awk '{ print $4 }'
# unsupported parameter form  @ $*;  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkDollarStar:1  for f in $*; do ..; done
# unsupported parameter form  @ $9$  (1 samples: nl2bash)
rej -  NB:9875  screen -list | awk '{print $1}' | grep -q "$1$"
# unsupported parameter form  @ $9).  (1 samples: nl2bash)
rej -  NB:1251  mktemp -dt "$(basename $0).XXXXXXXXXX"
# unsupported parameter form  @ $9)/  (1 samples: nl2bash)
rej -  NB:9348  source $(dirname $0)/incl.sh
# unsupported parameter form  @ $9)a  (1 samples: pure-bash-bible)
rej -  PB:README.md:2021c5-2023  # Usage: date "format"@N    # See: 'man strftime' for format.@N    printf "%($1)T\\n" "-1"
# unsupported parameter form  @ $9,  (1 samples: nl2bash)
rej -  NB:12450  alias logspace="find /apps/ /opt/ -type f -size +100M -exec ls -lh {} \; | awk '{print $5, $9 }'"
# unsupported parameter form  @ $9.a  (1 samples: nl2bash)
rej -  NB:6017  cat $1.tmp | sort -u
# unsupported parameter form  @ $9/.  (1 samples: nl2bash)
rej -  NB:2558  find $1/.hg -type d -exec chmod g+s {} \;
# unsupported parameter form  @ $9;;  (1 samples: cookbook)
rej -  BC:ch12/dash:20c9  CHAR=$1;;
# unsupported parameter form  @ $9=  (1 samples: shellcheck)
rej -  SC:Checks/Commands.hs:prop_checkAliasesUsesArgs2:1  alias $1='foo'
# unsupported parameter form  @ $9\`  (1 samples: nl2bash)
rej -  NB:9947  ln -s `cd \`dirname $2\`; pwd`/`basename $2` $1/link
# unsupported parameter form  @ $9`,  (1 samples: nl2bash)
rej -  NB:6820  echo "The script you are running has basename `basename $0`, dirname `dirname $0`"
# unsupported parameter form  @ $9}  (1 samples: nl2bash)
rej -  NB:3080  find -type f -printf "%s %p\n" | sort -nr | head -n 4 | awk "{print $2}"
# unsupported parameter form  @ $?;  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkSpuriousExec10:1c12  r=$?; printf >&2 'failed
# unsupported parameter form  @ $@*  (1 samples: nl2bash)
rej -  NB:10197  find . -iname "*$@*" -or -iname ".*$@*"
# unsupported parameter form  @ $@,  (1 samples: makebook)
rej -  MK:recipe:186.37  $(call add-manifest, $@, $($1_name), $($1_manifest))
# unsupported parameter form  @ $@.a  (1 samples: makebook)
rej -  MK:recipe:165.29  MAKEVAR $@.tmp $@
# unsupported parameter form  @ $@`)  (1 samples: nl2bash)
rej -  NB:6906  pushd $(dirname `which $@`)
# unsupported parameter form  @ ${##  (1 samples: shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms56:1-2  #!/bin/sh@Necho ${##}
# unsupported parameter form  @ ${#*  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkDollarStar8:1  ls ${#*}
# unsupported parameter form  @ ${#@  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkUnquotedDollarAt1:1  ls ${#@}
# unsupported parameter form  @ ${$#  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkBadParameterSubstitution3:1  ${$#}
# unsupported parameter form  @ ${$(  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkBadParameterSubstitution8:1  ${$(x)//x/y}
# unsupported parameter form  @ ${${  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkBadParameterSubstitution11:1  ${${x%.*}##*/}
# unsupported parameter form  @ ${*/  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkDollarStar5:1  ls ${*//foo/bar}
# unsupported parameter form  @ ${*}  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkDollarStar7:1  ls ${*}
# unsupported parameter form  @ ${.a  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkUnassignedReferences28:1-2  #!/bin/ksh@Necho "${.sh.version}"
# unsupported parameter form  @ ${9  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkSpacefulnessCfg11:1  rm ${10//foo/bar}
# unsupported parameter form  @ ${9+  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkSpacefulnessCfg35:1  echo ${1+"$1"}
# unsupported parameter form  @ ${9,  (1 samples: pure-bash-bible)
rej -  PB:README.md:350c5-351  # Usage: lower "string"@N    printf '%s\n' "${1,,}"
# unsupported parameter form  @ ${9^  (1 samples: pure-bash-bible)
rej -  PB:README.md:376c5-377  # Usage: upper "string"@N    printf '%s\n' "${1^^}"
# unsupported parameter form  @ ${9~  (1 samples: pure-bash-bible)
rej -  PB:README.md:402c5-403  # Usage: reverse_case "string"@N    printf '%s\n' "${1~~}"
# unsupported parameter form  @ ${@%  (1 samples: shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms55:1-2  #!/bin/sh@Necho ${@%foo}
# unsupported parameter form  @ ${@+  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkUnquotedDollarAt10:1  echo ${@+"$@"}
# unsupported parameter form  @ ${@:  (1 samples: nl2bash)
rej -  NB:6087  diff "${@:3}" <(sort "$1") <(sort "$2")
# unsupported parameter form  @ ${a%  (1 samples: pure-bash-bible)
rej -  PB:README.md:197c5  : "${_%"${_##*[![:space:]]}"}"
# unsupported parameter form  @ ${a+  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkInexplicablyUnquoted10:1  cmd ${x+--name="$x" --output="$x.out"}
# unsupported parameter form  @ ${a[  (1 samples: shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms116:3  ${x[1]}
# unsupported parameter form  @ ${a^  (1 samples: shellcheck)
rej -  SC:Checks/ShellSupport.hs:prop_checkBashisms119:3  ${x^^[t]}
# unsupported parameter form  @ ${{a  (1 samples: shellcheck)
rej -  SC:Analytics.hs:prop_checkBadParameterSubstitution7:1  ${{var}
