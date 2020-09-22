requires 'CGI::Simple::Cookie', '1.25';
requires 'Devel::StackTrace', '2.04';
requires 'Digest::MD5', '2.55';
requires 'Encode', '3.07';
requires 'File::LibMagic', '1.23';
requires 'File::MMagic', '1.30';
requires 'File::Slurp', '9999.32';
requires 'File::Temp', '0.2309';
requires 'HTML::Entities', '3.75';
requires 'HTML::FillInForm::ForceUTF8', '0.03';
requires 'HTTP::Date', '6.05';
requires 'List::Util', '1.55';
requires 'Module::Runtime', '0.016';
requires 'Moo', '2.004000';
requires 'Moo::Role';
requires 'Net::SMTP', '3.11';
requires 'Path::Tiny', '0.114';
requires 'Plack::Request', '1.0047';
requires 'Role::Tiny', '2.001004';
requires 'Scalar::Util', '1.55';
requires 'Sub::HandlesVia', '0.015';
requires 'Try::Catch', '1.1.0';
requires 'Type::Tiny', '1.010006';
requires 'Types::Path::Tiny', '0.006';
requires 'Types::Standard';
requires 'URI', '1.76';
requires 'URI::Escape';
requires 'namespace::clean', '0.27';

on configure => sub {
    requires 'Module::Build::Tiny', '0.039';
};

on test => sub {
    requires 'Class::MOP';
    requires 'DateTime';
    requires 'HTTP::Cookies', '6.08';
    requires 'HTTP::Request::Common';
    requires 'Plack::Test';
    requires 'Plack::Util';
    requires 'Test::Exception';
    requires 'Text::Lorem';
    requires 'Test::More';
    requires 'parent';
};

on develop => sub {
    requires 'Minilla';
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::CPAN::Meta';
    requires 'Test::Kwalitee::Extra';
    requires 'Test::MinimumVersion::Fast', '0.04';
    requires 'Test::PAUSE::Permissions', '0.04';
    requires 'Test::Pod', '1.41';
    requires 'Test::Spellunker', 'v0.2.7';
};
