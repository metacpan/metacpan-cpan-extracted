#!/usr/bin/env perl

require Test::More;

eval { require Test::Perl::Critic };

if ($@) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    Test::More::plan(skip_all => $msg);
}

# Use rc file if one exists
my $rcfile = File::Spec->catfile('xt', 'perlcriticrc');
if (-f $rcfile) {
    Test::Perl::Critic->import(-profile => $rcfile);
}
else {
    Test::Perl::Critic->import;
}

all_critic_ok();
