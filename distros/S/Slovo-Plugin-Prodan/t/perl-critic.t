# t/perl-critic.t
use Mojo::Base -strict;
use Test::More;
use English qw(-no_match_vars);
use File::Basename;
eval { require Test::Perl::Critic; };

if ($EVAL_ERROR) {
  my $msg = 'Test::Perl::Critic required to criticise code';
  plan(skip_all => $msg);
}

my $rcfile = dirname(__FILE__) . '/../.perlcriticrc';

Test::Perl::Critic->import(-profile => $rcfile, -verbose => 10);
all_critic_ok();

