requires 'perl', '5.020';
requires 'Mojolicious', '7.77';
requires 'Path::Tiny';
requires 'Syntax::Keyword::Try';
requires 'List::MoreUtils';
requires 'Digest::SHA';
requires 'Net::Statsite::Client';
requires 'failures';
requires 'Safe::Isa';
requires 'Guard', '1.023';
requires 'Mojolicious::Plugin::CHI', '0.09';
requires 'CHI::Driver::Memcached', '0.16';
requires 'Cache::Memcached::Fast', '0.25';
requires 'HTTP::Date', '6.02';
requires 'Net::Amazon::S3';
requires 'Log::Dispatch';
requires 'Log::Dispatch::Gelf';
requires 'MojoX::Log::Dispatch::Simple';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception';
    requires 'Mock::Quick';
    requires 'Test::Mock::Cmd', '0.7';
    requires 'HTTP::Request';
    requires 'Test::Mojo';
    requires 'Port::Selector', '0.1.6';
};

on 'develop' => sub {
    requires 'Minilla';
    requires 'Module::Build::Tiny';
};
