require Test::More;

eval { require Test::Perl::Critic; };

if (1 || $@) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    Test::More::plan(skip_all => $msg);
}

my $rcfile = File::Spec->catfile('t', 'perlcriticrc');

Test::Perl::Critic->import(-profile => $rcfile);

all_critic_ok();
