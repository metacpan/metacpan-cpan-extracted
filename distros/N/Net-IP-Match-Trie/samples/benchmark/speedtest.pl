#!/usr/bin/perl -w

use strict;
use FindBin;
use Path::Class qw(file dir);
use lib map {dir($FindBin::Bin, '..', '..', @$_)->stringify} [qw(lib)], [qw(blib lib)], [qw(blib arch)], [qw(.)];
use Net::IP::Match::Regexp qw();
use Net::IP::Match::XS qw();
use Net::IP::Match::Trie;

use Time::HiRes qw(gettimeofday tv_interval);
use List::Util qw(max);
use Getopt::Long;
use Pod::Usage;

my %opts = (
   networks => "1,10,100,1000",
   ips => 10000,
   skipsimple => 0,
   dump => undef,
   verbose => 0,
   help => undef,
   version => undef,
);
Getopt::Long::Configure("bundling");
GetOptions("v|verbose"    => \$opts{verbose},
           "d|dump"       => \$opts{dump},
           "n|networks=s" => \$opts{networks},
           "i|ips=s"      => \$opts{ips},
           "s|skipsimple" => \$opts{skipsimple},
           "h|help"       => \$opts{help},
           "V|version"    => \$opts{version},
          ) or pod2usage(1);
pod2usage(-exitstatus => 0, -verbose => 2) if ($opts{help});
print("Net::IP::Match::Regexp v$Net::IP::Match::Regexp::VERSION\n"),exit(0)
    if ($opts{version});

my @num_networks = split /,/, $opts{networks};
my $max_networks = max(@num_networks);

# Choose realistic masks.  Nobody ever really uses /1 thru /7 in real life.
my @masks = (8,15..32); # used by rand_mask() below

# Global test data, to be populated with random data
my @ranges;
my @rangeips;
my @ips;

my $t0 = [gettimeofday];
my %seen;
while (@ranges < $max_networks)
{
   my $ip = rand_ip();
   my $mask = rand_mask();
   my $numip1 = ip2numip($ip);
   my $numip = apply_mask($numip1, $mask);

   # Avoid duplicates
   unless ($seen{$numip}++)
   {
      push @ranges, [$numip >> (32-$mask), $mask, scalar(@ranges)+1, $ip];
      push @rangeips, $ip;
   }
}
for (my $i=0;$i<$opts{ips};$i++)
{
   # Duplicates are OK
   push @ips, rand_ip();
}

my $t1 = [gettimeofday];
print "Initialization time of test: ".tv_interval($t0,$t1)."\n\n";

my @tests = (
   {
      name => "simple", ###############
      setup => sub {
         my $ranges = shift;

         return [sort {$a->[1] <=> $b->[1]} @$ranges];
      },
      match => sub {
         my $ip = shift;
         my $ranges = shift;

         my $numip = ip2numip($ip);
         for my $range (@$ranges)
         {
            if ($range->[0] == $numip >> (32-$range->[1]))
            {
               return $range->[2];
            }
         }
         return undef;
      },
   },
   {
      name => "Net::IP::Match::XS", ###############
      bool => 1, # this test just returns true/false, not the ID of the matched network
      setup => sub {
         my $ranges = shift;
         my $test = shift;

         return [map {$_->[3]."/".$_->[1]} @$ranges];
      },
      match => sub {
         my $ip = shift;
         my $ranges = shift;

         return Net::IP::Match::XS::match_ip($ip, @$ranges);
      },
   },
   {
      name => "Net::IP::Match::Regexp", ###############
      setup => sub {
         my $ranges = shift;
         my $test = shift;

         my %map;
         for my $r (@$ranges)
         {
            $map{$r->[3]."/".$r->[1]} = $r->[2];
         }
         my $re = Net::IP::Match::Regexp::create_iprange_regexp(\%map);
         return $re;
      },
      match => sub {
         my $ip = shift;
         my $ranges = shift;

         return Net::IP::Match::Regexp::match_ip($ip, $ranges),
      },
   },
   {
      name => "Net::IP::Match::Trie", ###############
      setup => sub {
         my $ranges = shift;
         my $test = shift;

         my $matcher = Net::IP::Match::Trie->new;

         my %map;
         for my $r (@$ranges)
         {
             $matcher->add($r->[2] => [$r->[3]."/".$r->[1]]);
         }

         return $matcher;
      },
      match => sub {
         my $ip = shift;
         my $matcher = shift;

         return $matcher->match_ip($ip);
      },
   },
);

my %tests = map {$_->{name} => $_} @tests;
if ($opts{skipsimple})
{
   $tests{simple}->{skip} = 1;
}

# Make sure all tests have setup() and match() methods
for my $test (@tests)
{
   for my $type (qw(setup match))
   {
      if (!ref $test->{$type})
      {
         $test->{$type} = $tests{$test->{$type} || "simple"}->{$type};
      }
   }
}

for my $num_networks (@num_networks)
{
   my @networks = @ranges[0..$num_networks-1];

   # We will store the "simple" results for comparison to make sure the
   # other methods get the right answer
   my @simple;
   
   for my $test (@tests)
   {
      next if ($test->{skip});
      
      printf "Testing %-12s ", $$test{name}."..." if ($opts{verbose});
      my @answer;
      my $t0 = [gettimeofday];
      my $ranges = $test->{setup}(\@networks, $test);
      my $t1 = [gettimeofday];
      for (my $i=0; $i<@ips; $i++)
      {
         $answer[$i] = $test->{match}($ips[$i], $ranges);
      }
      my $t2 = [gettimeofday];
      $test->{results} = {
         setup => tv_interval($t0,$t1),
         run   => tv_interval($t1,$t2),
      };
      print "$test->{results}->{run}  ($test->{results}->{setup})\n" if ($opts{verbose});
      if ($test->{name} eq "simple")
      {
         @simple = @answer;
      }
      elsif (@simple > 0)  # only do error testing if we have results from the "simple" test
      {
         my @err;
         for (0..$#simple)
         {
            my $a = $simple[$_]||0;
            my $b = $answer[$_]||0;

            # if bool is true, then this test just returns true/false,
            # not the ID of the matched network, so just perform a basic comparison
            if ($test->{bool} ? !(($a&&$b) || ((!$a)&&(!$b))) : $a ne $b)
            {
               push @err, join("|",$_,$a,$b,$ips[$_],unpack("B32", pack("C4", split(/\./, $ips[$_]))));
            }
         }
         $test->{results}->{errors} = scalar @err;
         if (@err > 0)
         {
            if (@err > 20)
            {
               print "Errors: many\n" if ($opts{verbose});
            }
            else
            {
               print "Errors: @err\n" if ($opts{verbose});
            }
            
            if ($opts{dump})
            {
               local *O;
               open O, "> ips.txt" or die;
               print O "$ips[$_] ".(unpack("B32", pack("C4", split(/\./, $ips[$_]))))."\n" for (0..$#ips);
               close O or die;
               print "Wrote ips.txt\n" if ($opts{verbose});
               
               open O, "> networks.txt" or die;
               print O "$rangeips[$_] ".(unpack("B32", pack("C4", split(/\./, $rangeips[$_]))))." @{$networks[$_]}\n" for (0..$#networks);
               close O or die;
               print "Wrote networks.txt\n" if ($opts{verbose});
               
               if ($test->{name} eq "Net::IP::Match::Regexp")
               {
                  local *P;
                  unlink "re.txt";
                  open P, "| perl format.pl > re.txt" or die;
                  print P $ranges;
                  close P or die;
                  print "Wrote re.txt\n" if ($opts{verbose});
               }
            }
         }
      }
   }

   print "\n" if ($opts{verbose});
   
   print "Networks: $num_networks, IPs: $opts{ips}\n";
   print "Test name              | Setup time | Run time | Total time | Errors \n";
   print "-----------------------+------------+----------+------------+--------\n";
   my $format = "%-22s |   %6.3f   | %6.3f   |   %6.3f   | %s\n";
   
   for my $test (@tests)
   {
      next if ($test->{skip});

      my $setup = $test->{results}->{setup};
      my $run = $test->{results}->{run};
      my $errs = $test->{results}->{errors};

      my $errstr = defined $errs ? $errs : "n/a";
      printf $format, $test->{name}, $setup, $run, $setup+$run, $errstr;
   }
   print "\n";
}

# Utility functions

sub rand_ip
{
   return join(".", int(rand(256)), int(rand(256)), int(rand(256)), int(rand(256)));
}
sub rand_mask
{
   return $masks[int(rand(scalar @masks))];
}
sub ip2numip
{
   my $ip = shift;
   return unpack("N", pack("C4", split(/\./, $ip)));
}
sub numip2ip
{
   my $numip = shift;
   return join(".", ($numip >> 24, ($numip >> 16) & 255, ($numip >> 8) & 255, $numip & 255));
}
sub apply_mask
{
   my $numip = shift;
   my $mask = 32 - shift;

   return ($numip >> $mask) << $mask;
}

__END__

=head1 NAME

speedtest.pl - Benchmark the various IP match implementations

=head1 SYNOPSIS

speedtest.pl [options]

 Options:
   -s --skipsimple     omit the naive comparison test (which is slow)
   -n --networks=num   comma-separated list of numbers of IP ranges to match against
   -i --ips            number of single IPs to test against the networks
   -d --dump           save the raw data to files
   -v --verbose        print the internal representation of the PDF
   -h --help           verbose help message
   -V --version        print Net::IP::Match::Regexp version

=head1 DESCRIPTION

This utility runs timed tests of Net::IP::Match:* modules.

__END__
