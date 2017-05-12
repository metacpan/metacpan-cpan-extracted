#!/usr/bin/perl -w

=pod

Schlage Perl Directories im /usr/local/ Directory zum Loeschen vor.
Based on Distance between neighbors. Born out of duenneresdone.pl

=cut

use strict;

use List::Util qw(reduce);
use File::Find;

use Getopt::Long;
our %Opt;
GetOptions(\%Opt, qw(max=i));

use Config;
my $max = 0;

my $root = shift or die "Usage: $0 directory";
die "Directory $root not found" unless -d $root;

my %no;
my %never_delete = map { $_ => undef }
    (
     1,41,170,273,379,496,   # this area needs manual intervention thus is precious
     266,267,     # Ilya's Jumbo patch
     9654,        # 5.6.1
     16904,16905, # Locale::TextDomain
     17637, # according to CoreList this is 5.008
     # 17705, # currently my oldest 5.9.0
     # 17706, # tentatively my oldest 5.9.0 with threads
     17656,17671, # JSON 2.07 (fixed in ticket 34599)
     17724,17725, # pseudo hashes
     17967,17968, # RCLAMP/Devel-LeakTrace-0.05.tar.gz
     18047,18048, # threads only: Devel::Caller
     18352, # 5.008
     ## 18408,18409, # PADBUSY for Scalar-Util-Clone-0.10

     # 19608, 19610, # wrong line number
     # 19391,19392, # maybe connected to Mail::Box, tests/nicholas-46463.pl
     19648,19649, # rt-perl-22977 ugly format bug and binary search needs help

     # 20556,20559, # DBI 1.58 (was a bug in perl)
     # 20939, # 5.008001 debugging
     21377, # according to CoreList this is 5.008001
     21670, # according to CoreList this is 5.008002
     21727, # 5.006001, Module::CoreList::patchlevel for 5.6.2 built with 'buildaperl --branch maint-5.6/perl-5.6.2 @21727'; installed as /home/src/perl/repoperls/installed-perls/maint-5.6/perl-5.6.2/p2dBQ7e/perl-5.6.1@21727/bin/perl

     ##22071,22074, # perlbug 53482 (magic/tie)

     22151, # according to CoreList this is 5.008003
     22314,22315, # B::Generate 1.06 without debugging, B::Generate 1.11 with debugging, Brackup
     # 22491, # 5.009001
     # 22552, # 5.008003 THREAD
     22729, # according to CoreList this is 5.008004
     ##22739,22741, # Devel::Profile 1.05
     22841,22842, # Encode::IMAPUTF7
     22861,22862, # fixes YAML::LibYAML 0.32
     23139, # according to CoreList this is 5.008005
     23390, # 5.008005 THREAD
     23470,23471, # DCOPPIT/Mail-Mbox-MessageParser-1.5000.tar.gz
     23552, # according to CoreList this is 5.008006
     23767,23768, # Readonly::XS
     23963,23964, # Hatena::Keyword(not sure if I put this in the right line back then)
     23965,23966, # encoding neutral unpack: Data::Serializer 0.44 with JSON 2.07
     24009,24010, # Unicode::RecursiveDowngrade, Hatena::Keyword 0.05
     24448, # 5.008006 THREAD
     24517,24518, # removed AvFLAGS
     24521,24522, # removed HvPMROOT
     24525,24529, # 26 removed xhv_eiter from XPVHV and 29 regained compilability
     # 24541,24542, # Math::Pari
     # 24556,24557, # Math::Pari after rafl's patch
     24641, # according to CoreList this is 5.008007
     24659,24660, # Class::constr, Data::Structure::Util
     24713,24714, # shared hash keys, manifested in AVIF/Tree-Trie-1.5
     24965,24966, # Safe::World but only of marginal importance because failure has changed
     25178,25179, # CharsetDetector 1.0
     25567,25568, # srezic-rx-problem
     25805,25808, # Text::Query
     25965,25966, # Safe::World 0.14
     25985,25986, # Mail::Box
     26369,26370, # Class::MOP 0.40
     26373,26374, # classes
     26452,26453, # Devel::Profiler 0.04 "Not a glob reference"
     26454,26465, # Term::ReadPassword 0.07 (proxysubs; No useable patch between)
     26486,26487, # SQL::Translator; Class::MOP ?
     26876, # 5.008007 THREAD
     26979,26980, # Math::Pari after Nicholas' patch (Message-ID: <877ifnfoal.fsf@k75.linux.bogus>)
     27002, # 5.009003
     27040, # 5.008008 according to corelist
     27263,27264, # JSON 1.12
     27533,27534, # regexp recursion stuff/regression(rtperl#60034)
     27648,27649, # Devel::Arena
     27704,27705, # Thread.pm emulation: Net::Daemon
     28358,28359, # encoding::source
     28867,28868, # Regexp::Optimizer 0.15
     28966, # 5.009004
     29025,29026, # DBIx::Class(?), Authen::Htpasswd
     29278,29279, # Apache::Parselog 1.02
     29317,29318, # String::Multibyte
     30038,30039, # forks 0.27
     30487,30488, # Devel::Cover 0.61
     30609,30610, # Sepia
     30637,30638, # XML-LibXML-Simple 0.12 (MarkOv) maint-5.8!
     30677,30678, # TAP::Parser 0.52
     30952,30953, # Thread.pm emulation: Net::Daemon
     30979,30980, # mro, Best 0.11, Class::Inner, Class::Prototyped
     31025,31027, # Regexp::Assemble
     31162, # 5.008008, my maint 5.8 installation under which I run Jifty
     31223, # 5.008008 THREAD
     31251,31252, # Data::Alias,Devel::EvalContext
     31940,31941, # Tcl (debugging perls)
     32147,       # my first bleadperl to run Jifty (yay!)
     32367,       # 5.10.0-RC1
     32491,       # 5.10.0-RC2
     32642,       # 5.10.0
     32706,32707, # breaks Data::Alias, Devel::Declare, autobox
     32733,32734, # DROLSKY/Class-MOP-0.65-70; replace RVs with IVs
     32739,32740, # breaks YAML::LibYAML due to ORANGE regexps
     32856,32857, # DCONWAY/Getopt-Euclid-v0.1.0 know your enemy, this is hard to binarysearch, not the usual oneliner!
     32953,32954, # Data-PostfixDeref-0.03
     33017,33018, # RCLAMP/Devel-Caller-2.03, Coro 4.37
     33021,33022, # DROLSKY/Devel-StackTrace-1.15, Devel-ebug-0.48
     33027,33028, # ROBIN/Want-0.16
     33029,33030, # ROBIN/PadWalker-1.6
     33056,33057, # ROBIN/Want-0.16 again
     33071,33072, # PJCJ/Devel-Cover-0.63, ANDYA/Devel-LeakTrace-Fast-0.11
     33085,33086, # PAR::Packer 0.978
     33087,33088, # OLAF/Net-DNS-0.62.tar.gz
     33709,33710, # PJCJ/Devel-Cover-0.64.tar.gz
     33871,33874, # DLAND/Regexp-Assemble-0.33.tar.gz
     34481,34482, # Perl6::Say broke on this makemaker
     # current smoker
     # 24329, # 5.8.6
     # 26727, # before 5.8.8, not acceptable, bug between 26696 and 26894
     27512, # 5.8.8
     34437, # 5.10.1 tobe
     35054, # ~5.8.9
     39999, # need a new plan for those
    );
ENDLESS: while () {
  my @dirs;
  find(sub {
         my $mname = $File::Find::name;
         $mname =~ s|\Q$root\E||;
         $File::Find::prune++ if $mname =~ tr[/][] > 2;
         return unless /perl.+\@(\d+)/;
         my $patch = $1;
         return if exists $never_delete{$patch};
         push @dirs, $File::Find::name if $mname;
       }, $root);
  my %n;

  # read them and give them a value
  warn "Found ". scalar @dirs ." deleteable perls";
  for my $dirent (@dirs) {
    next unless $dirent =~ m|/perl.+\@(\d+)|;
    next if exists $no{$dirent};
    $n{$dirent} = $1;
  }

  # sort them by value
  my @n = sort { $n{$a} <=> $n{$b} } keys %n;

  # we do not want to delete first and last one
  pop @n; shift @n;

  # group them by the difference to the next lower
  my %diff;
  for my $n (1..$#n) {
    my $diff = $n{$n[$n]} - $n{$n[$n-1]};
    $max = $diff if $diff > $max;
    $diff{$diff}{$n[$n]} = undef;
  }

  my $done;
  local($|) = 1;
 OUTER: for (my $i = 0; $i <= $max; $i++) {
    $done++ if $i == $max;
    next OUTER unless exists $diff{$i};
    # for my $d (sort { $n{$a} <=> $n{$b} } keys %{$diff{$i}}) {
  INNER: for my $d (reduce { $n{$a} < $n{$b} ? $a : $b } keys %{$diff{$i}}) {
      printf "unlink %s (distance %d) [Nyq]? ", $d, $i;
      my $ans;
      if ($Opt{max}) {
        sleep 1;
        if (@dirs > $Opt{max}) {
          $ans = "y";
        } else {
          $ans = "q";
        }
        print $ans, "\n";
        sleep 1;
      } else {
        $ans = <>;
      }
      if ($ans =~ /^y/i) {
        require File::Path;
        File::Path::rmtree($d) or die "Could not remove $d";
        if (-d $d) {
          die "ALERT: rmtree did not remove $d";
        } else {
          print "$d rmtreeed\n";
        }
      } elsif ($ans =~ /^q/i) {
        $done++;
      } else {
        print "Nothing done.\n";
        $no{$d} = undef;
      }
      last INNER;
    }
    last OUTER;
  }

  last ENDLESS if $done;
}
