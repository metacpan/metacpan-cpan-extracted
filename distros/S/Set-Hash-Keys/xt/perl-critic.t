use Test::Perl::Critic (
    -severity => 3,
    -exclude => [
        'Subroutines::RequireArgUnpacking',
        'Subroutines::RequireFinalReturn',
        'Modules::ProhibitAutomaticExportation',
    ],
);

all_critic_ok();


