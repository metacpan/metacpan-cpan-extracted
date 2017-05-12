#! perl

requires 'Module::Build::Pluggable';

on test => sub {

   requires 'Test::More';
   requires 'Test::Module::Build::Pluggable';

};

on develop => sub {

    requires 'App::ModuleBuildTiny';

    requires 'Test::Fixme';
    requires 'Test::NoBreakpoints';
    requires 'Test::Pod';
    requires 'Test::Perl::Critic';
    requires 'Test::CPAN::Changes';
    requires 'Test::CPAN::Meta';
    requires 'Test::CPAN::Meta::JSON';
};
