use Test::Perl::Critic (-severity => 3, -exclude => ['ProhibitExcessComplexity'] );
all_critic_ok(qw(lib));
