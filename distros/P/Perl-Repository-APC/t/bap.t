#!perl -- -*- mode: cperl -*-

use strict;

my $REPO = $ENV{PERL_REPOSITORY_APC_REPO};

my $Id = q$Id: bap.t 299 2008-04-29 20:28:44Z k $;

if (not defined $REPO or not -d $REPO) {
  print "1..0 # Skipped: no repository found\n";
  exit;
}

use Perl::Repository::APC::BAP;
my $apc = Perl::Repository::APC->new($REPO);
my $bap = Perl::Repository::APC::BAP->new($apc);

my $tests = [
             [qw(maint-5.10  5.10.0@33133 5.10.0   5.10.1   32695 33133 perl-5.10.x-diffs   )],
             [qw(perl        5.9.4@30000  5.9.4    5.9.5    28728 30000 5.9.0   )],
             [qw(perl        0@           0        5.004_50 1        60 5.004_50)],
             [qw(perl        5.004_00@    DIE                                   )],
             [qw(perl        5.004_50@    5.004_50 5.004_51 61       98 5.004_51)],
             [qw(perl        5.004_57@    5.004_57 5.004_58 462     485 5.004_58)],
             [qw(perl        @60          0        5.004_50 1        60 5.004_50)],
             [qw(perl        @519         5.004_58 5.004_59 496     519 5.004_59)],
             [qw(perl        5.9.0@4677   DIE                                   )],
             [qw(perl        5.6.1@18400  DIE                                   )],
             [qw(perl        5.6.0@6666   5.6.0    5.7.0    5903   6666 5.7.0   )],
             [qw(maint-5.004 0@           0        5.004_00 32       32 5.004_00)],
             [qw(maint-5.004 5.004_00@    5.004_00 5.004_01 42       42 5.004_01)],
             [qw(maint-5.004 5.004_50@    DIE                                   )],
             [qw(maint-5.004 0@           0        5.004_00 32       32 5.004_00)],
             [qw(maint-5.004 0@           0        5.004_00 32       32 5.004_00)],
             [qw(maint-5.004 0@           0        5.004_00 32       32 5.004_00)],
             [qw(maint-5.004 0@           0        5.004_00 32       32 5.004_00)],
             [qw(maint-5.6   5.6.0@       5.6.0    5.6.1    7242   9654 5.6.1   )],
             [qw(maint-5.6   5.6.0@7242   5.6.0    5.6.1    7242   7242 5.6.1   )],
             [qw(perl        5.9.0@22058  5.9.0    5.9.1    21540 22058 5.9.0   )],
            ];

print "1..", scalar @$tests, "\n";

for my $t (1..@$tests) {
  my($branch,$arg,$wbp,$wnp,$wfp,$wlp,$wdir) = @{$tests->[$t-1]};
  my($ver,$lev) = $arg =~ /^([^\@]*)@(\d*)$/;
  my($rbp,$rnp,$rfp,$rlp,$rdir);
  eval {($rbp,$rnp,$rfp,$rlp,$rdir) = $bap->translate($branch,$ver,$lev);};
  if ($@ && $wbp eq "DIE") {
    print "ok $t # $@\n";
  } elsif ($rbp eq $wbp && $rnp eq $wnp && $rfp eq $wfp && $rlp eq $wlp && $wdir eq $rdir) {
    print "ok $t # $rbp, $rnp, $rfp, $rlp, $rdir\n";
  } else {
    print "not ok $t # branch,arg,ver,lev[$branch,$arg,$ver,$lev]".
        "expected[$wbp,$wnp,$wfp,$wlp,$wdir]received[$rbp,$rnp,$rfp,$rlp,$rdir]\n";
  }
}

__END__

Todo: Something like

for f in 0@ 5.004_00@ 5.004_50@ 5.004_57@ @60 @519 5.9.0@4677 @ 5.6.1@18400 5.6.0@6666
do
echo INPUT: $f
./Perl-Repository-APC/scripts/buildaperl $f
done
