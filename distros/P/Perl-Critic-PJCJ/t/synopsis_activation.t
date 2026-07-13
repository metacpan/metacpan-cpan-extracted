#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing is ok subtest );
use feature      qw( signatures );
use experimental qw( signatures );

use lib          qw( lib t/lib );
use File::Temp   qw( tempfile );
use Perl::Critic ();

my $Quoting_policy
  = "Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting";
my $Long_lines_policy = "Perl::Critic::Policy::CodeLayout::ProhibitLongLines";

sub synopsis_include_lines {
  open my $fh, "<", "lib/Perl/Critic/PJCJ.pm"
    or die "Cannot read lib/Perl/Critic/PJCJ.pm: $!";
  my @lines = <$fh>;
  close $fh or die "Cannot close lib/Perl/Critic/PJCJ.pm: $!";

  my $in_synopsis = 0;
  my @includes;
  for my $line (@lines) {
    $in_synopsis = 1, next if $line =~ /^=head1 SYNOPSIS/;
    last if $in_synopsis && $line =~ /^=head1 /;
    next unless $in_synopsis;
    if (my ($include) = $line =~ /^\s*(include = .+)/) {
      push @includes, $include;
    }
  }
  @includes
}

subtest "SYNOPSIS include line activates both policies" => sub {
  my @includes = synopsis_include_lines;
  is @includes, 1, "SYNOPSIS documents exactly one include line";

  my ($fh, $profile) = tempfile(UNLINK => 1);
  print $fh "$includes[0]\n";
  close $fh or die "Cannot close $profile: $!";

  my $critic = Perl::Critic->new(-profile => $profile);
  my $source = qq(my \$x = 'hello';\n) . ("x" x 90) . "\n";
  my %fired  = map { $_->policy => 1 } $critic->critique(\$source);

  ok $fired{$Quoting_policy},    "include activates RequireConsistentQuoting";
  ok $fired{$Long_lines_policy}, "include activates ProhibitLongLines";
};

subtest "pjcj theme selects exactly the two policies" => sub {
  my $critic   = Perl::Critic->new(-theme => "pjcj", -severity => 1);
  my @policies = sort map ref, $critic->policies;
  is \@policies, [sort $Long_lines_policy, $Quoting_policy],
    "theme pjcj selects both policies and nothing else";
};

done_testing;
