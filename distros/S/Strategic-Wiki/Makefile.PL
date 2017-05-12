use inc::Module::Install;

die 'This software is not ready for you yet.'
    unless $ENV{I_AM_WILD_AND_CRAZY};

name            'Strategic-Wiki';
all_from        'lib/Strategic/Wiki.pm';
readme_from;
manifest_skip;
ack_xxx;

requires 'Mouse' => 0;
requires 'Try::Tiny' => 0;
requires 'Class:Throwable' => 0;
requires 'Git::Wrapper' => 0;
requires 'YAML::XS' => 0;

WriteAll;
