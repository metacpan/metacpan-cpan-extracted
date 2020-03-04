use Test::Arrow;
eval q{ use Test::Perl::Critic };
Test::Arrow->plan(skip_all => "Test::Perl::Critic is not installed.") if $@;
all_critic_ok("lib");
