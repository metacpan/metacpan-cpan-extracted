use strict;
use warnings;
use Test::More;
use Path::Tiny;

use Test::CLI qw< tc >;

$|++;
my $sparring = path(__FILE__)->parent->child('sparring')->stringify;

my $tc = tc($sparring, qw{ stdout 0 [stuff] });

my $exact_stdout = "this goes\nto\nstdout\n";
my $exact_stderr = "here we go\non\nstderr\n";
for my $case (
   {
      stdout => {
         exact     => $exact_stdout,
         different => 'this goes',
         like      => qr{goes\s+to},
         unlike    => qr{go\s+on},
      },
      merged => {
         exact     => "this goes\nto\nstdout\n",
         different => 'this goes',
         like      => qr{goes\s+to},
         unlike    => qr{go\s+on},
      },
   },
   {
      stderr => {
         exact     => $exact_stderr,
         different => 'this goes',
         unlike    => qr{goes\s+to},
         like      => qr{go\s+on},
      },
      merged => {
         exact     => "here we go\non\nstderr\n",
         different => 'here we go',
         unlike    => qr{goes\s+to},
         like      => qr{go\s+on},
      },
   },
   {
      stdout => {
         exact     => $exact_stdout,
         different => 'this goes',
         like      => qr{goes\s+to},
         unlike    => qr{go\s+on},
      },
      stderr => {
         exact     => $exact_stderr,
         different => 'this goes',
         unlike    => qr{goes\s+to},
         like      => qr{go\s+on},
      },
      merged => {
         exact     => "$exact_stderr$exact_stdout",
         different => 'here we go',
         unlike    => qr{blah},
         like      => qr{(?mxs:go\s+on.*goes\s+to)},
      },
   },
) {
   my %case = %$case;
   my @stuff;
   for my $channel (qw< stdout stderr >) {
      my $c = $case{$channel} or next;
      push @stuff, "-$channel=$c->{exact}";
   }
   $tc->run(stuff => \@stuff);

   if ($case{stdout}) {
      $tc->stdout_is($case{stdout}{exact}, 'stdout_is') if $case{stdout}{exact};
      $tc->stdout_isnt($case{stdout}{different}, 'stdout_isnt') if $case{stdout}{different};
      $tc->stdout_like($case{stdout}{like}, 'stdout_like') if $case{stdout}{like};
      $tc->stdout_unlike($case{stdout}{unlike}, 'stdout_unlike') if $case{stdout}{unlike};
   }

   if ($case{stderr}) {
      $tc->stderr_is($case{stderr}{exact}, 'stderr_is') if $case{stderr}{exact};
      $tc->stderr_isnt($case{stderr}{different}, 'stderr_isnt') if $case{stderr}{different};
      $tc->stderr_like($case{stderr}{like}, 'stderr_like') if $case{stderr}{like};
      $tc->stderr_unlike($case{stderr}{unlike}, 'stderr_unlike') if $case{stderr}{unlike};
   }

   if ($case{merged}) {
      $tc->merged_is($case{merged}{exact}, 'merged_is') if $case{merged}{exact};
      $tc->merged_isnt($case{merged}{different}, 'merged_isnt') if $case{merged}{different};
      $tc->merged_like($case{merged}{like}, 'merged_like') if $case{merged}{like};
      $tc->merged_unlike($case{merged}{unlike}, 'merged_unlike') if $case{merged}{unlike};
   }
}

done_testing();
