# -*- mode: cperl -*-


=pod

Framework for stress testing of the SVN part. These tests are disabled
because they take too long (~20 minutes on my machine). If you're
interested in running the tests, please set the environment variable
$PERL_REPOSITORY_APC_TESTSVN to 1.

The following pod sums up what we're doing:

1. Look if we have the two patches in the pair and the perl to build
   the source. Look if we have svn and svnadmin available. DONE

2. svnadmin create a repo DONE

3. check out the repo into a wc DONE

4. build the source DONE

5. mv the source to the wc DONE

6. check in the wc DONE

7. maybe we need to (cd ..; rm -rf test-wc) now and check it out again and then

8. perlpatch2svn the second patch DONE

9. invent some tests on the result DONE

10. rmtree DONE

E.g.:

 08:01  svnadmin create perl-564-repo
 08:01  svn co file:///`pwd`/perl-564-repo perl-564-wc
 08:02  buildaperl --noconfigure @564
 08:05  rsync -ax perl-p-5.004_59@564/ perl-564-wc/ 
 08:05  cd perl-564-wc
 08:05  svn add [A-z]*
 08:06  svn ci -m blah
 08:07  cd ..
 08:08  svnadmin dump perl-564-repo >| perl-564-repo.dump
 08:08  cd -
 08:09  perl -S perlpatch2svn ../APC/5.004_60/diffs/565.gz


=cut

use Perl::Repository::APC;
use Perl::Repository::APC::BAP;
use Cwd qw(cwd);
use File::Path qw(rmtree);
use File::Copy qw(move);

my $REPO = $ENV{PERL_REPOSITORY_APC_REPO};
my $TESTSVN = $ENV{PERL_REPOSITORY_APC_TESTSVN} || 0;
my $tests;

unless ($TESTSVN) {
  print "1..0 # SKIP: svn deprecated\n";
  exit;
}

# Note, originally we were interested in 564/5, 10675/6, 11622/3. Now
# we try it to expose a little more of the history before. We found
# that with the configuration: rev 118 and Subversion 0.26.0, we have
# a way to reproduce the "Transaction is out of date" problem. For
# 528/65 and 10637/676 it showed up while it didn't on 564/5 or
# 10675/6. So just prepending a little bit of history is sufficient.
# Rev 118 did cope with the bug well. I'm now adding a few revisions
# after 10676 to see if problems come later. [time passes] Looks good,
# 10637/87 do not expose a problem in rev. 119.

# What I do not understand right now is that these small tests expose
# a few FAILED patches. Under a proper run of apc2svn these do not
# appear, so apparently something is being done wrong as of rev 119.
# But we do not care much about it because we're after something else.

my @tests = ([528,565],[10637,10687],[11622,11623]);
printf "1..%d\n", scalar @tests;

my $apc;
my $skip_reason;

if (-d $REPO) {
  my $svnout = `svn --version`;
  if ($?) {
    warn "\n\n\a  Skipping tests! External command 'svn' not found";
    $skip_reason = "No svn";
  } else {
    $svnout = `svnadmin --version`;
    if ($?) {
      warn "\n\n\a  Skipping tests! External command 'svnadmin' not found";
      $skip_reason = "No svnadmin";
    } else {
      $apc = Perl::Repository::APC->new($REPO);
    }
  }
} else {
  warn "\n\n\a  Skipping tests! If you want to run the tests against your copy
  of APC, please set environment variable \$PERL_REPOSITORY_APC_REPO to
  the path to your APC\n\n";
  $skip_reason = "No APC";
}

my $cwd = cwd;
TESTARRAY: for my $p (0..$#tests) {
  if ($apc) {
    my($from,$to) = @{$tests[$p]};
    my $range = $apc->patch_range("perl",$from,$to);
    unless (@$range) {
      printf "ok %d # SKIP: $from not found in local APC\n", $p+1;
      next TESTARRAY;
    }
    my $bap = Perl::Repository::APC::BAP->new($apc);
    my($ver,$dir,$firstpatch)=$bap->translate("perl","",$from);
    my $repo = "test-repo";
    my $wc = "test-wc";
    rmtree [$repo, $wc];
    system svnadmin => "create", $repo;
    die if $?;
    system svn => "checkout", "--quiet", "file:///$cwd/$repo", $wc;
    die if $?;
    system "./blib/script/buildaperl" => "--noconfigure",
        "--apc=$REPO", "\@$from";
    die if $?;
    my $pdir = "perl-p-$ver\@$from";
    opendir my $dh, $pdir or die "Could not opendir $pdir: $!";
    for my $dirent (readdir $dh) {
      next if $dirent =~ /^\.\.?$/;
      move "$pdir/$dirent", "$wc/$dirent";
    }
    closedir $dh;
    rmdir $pdir or die "Could not rmdir $pdir: $!";
    chdir $wc or die;
    system "svn add [A-z]*"; # let the shell handle this
    die if $?;
    system svn => "commit", "-m", "blah";
    die if $?;

    # maybe we should now remove it and check out again?

    for my $i (1..$#$range) {
      my $nextpatch = $range->[$i];
      system "../blib/script/perlpatch2svn" => "$REPO/$dir/diffs/$nextpatch.gz";
      die if $?;
    }

    # REAL TESTS GO HERE

    # END OF TESTS

    chdir ".." or die;
    rmtree [$repo, $wc];
    printf "ok %d # from[$from]to[$to]range[@$range]ver[$ver]dir[$dir]".
        "firstpatch[$firstpatch]\n", $p+1;
  } else {
    printf "ok %d # SKIP: $skip_reason\n", $p+1;
  }
}

__END__
