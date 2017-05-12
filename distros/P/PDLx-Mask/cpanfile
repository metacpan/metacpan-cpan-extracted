#! perl

requires 'Params::Check';
requires 'Ref::Util';
requires 'PDL::Core';
requires 'Moo';
requires 'MooX::ProtectedAttributes';
requires 'namespace::clean' => 0.16;
requires 'Safe::Isa';
requires 'Package::Stash';
requires 'Data::GUID';
requires 'PDLx::DetachedObject';
requires 'Try::Tiny';
requires 'Scalar::Util';

on test => sub {
   requires 'Test::More';
   requires 'Test::Deep';
   requires 'Test::Fatal';
   requires 'Test::PDL';
   requires 'Safe::Isa';
};

on develop => sub {

    requires 'Module::Install';
    requires 'Module::Install::AuthorRequires';
    requires 'Module::Install::AuthorTests';
    requires 'Module::Install::AutoLicense';
    requires 'Module::Install::CPANfile';
    requires 'Module::Install::ReadmeFromPod';

    requires 'Test::Fixme';
    requires 'Test::NoBreakpoints';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Perl::Critic';
    requires 'Test::CPAN::Changes';
    requires 'Test::CPAN::Meta';
    requires 'Test::CPAN::Meta::JSON';
};
