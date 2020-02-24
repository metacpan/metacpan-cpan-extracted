# http://bit.ly/cpanfile
# http://bit.ly/cpanfile_version_formats
requires 'perl', '5.008005';
requires 'strict';
requires 'warnings';
requires 'Test::Builder::Module';
requires 'Test::Name::FromLine';
requires 'Text::MatchedPosition';
requires 'Scalar::Util';

on 'configure' => sub {
    requires 'Module::Build' , '0.40';
    requires 'Module::Build::Pluggable';
    requires 'Module::Build::Pluggable::CPANfile';
};

on 'develop' => sub {
    requires 'Software::License';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod::Coverage';
    requires 'Test::Pod';
    requires 'Test::NoTabs';
    requires 'Test::Perl::Metrics::Lite';
    requires 'Test::Vars';
    requires 'Test::File::Find::Rule';
};
