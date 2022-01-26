requires "Config::INI::Reader"                             => 0;
requires "Perl::Critic"                                    => 0;
requires "Perl::Critic::Exception::AggregateConfiguration" => 0;
requires "Perl::Critic::Exception::Configuration::Generic" => 0;
requires "Perl::Critic::Policy"                            => 0;
requires "Perl::Critic::Utils"                             => 0;

{
    # issue on 5.18.4
    # Unexpected warning: Module::Pluggable will be removed from the Perl core distribution
    # in the next major release. Please install it from CPAN.
    # It is being used at /usr/local/lib/perl5/site_perl/5.18.4/Perl/Critic/PolicyFactory.pm, line 51.

    recommends "Module::Pluggable" => 5.2;
}

on "test" => sub {
    requires "Test::More"                => "0";
    requires "Test2::Bundle::Extended"   => "0";
    requires "Test2::Tools::Explain"     => "0";
    requires "Test2::Plugin::NoWarnings" => "0";
    requires "File::Temp"                => "0";
    requires "Test::MockFile"            => "0";
};

