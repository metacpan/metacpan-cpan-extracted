use inc::Module::Install;

name 'Qpsmtpd-Plugin-Queue-HTTPRequest';
all_from 'lib/Qpsmtpd/Plugin/Queue/HTTPRequest.pm';

die "\nPlease install Qpsmtpd first. http://smtpd.develooper.com/\n"
    unless eval { require Qpsmtpd };

requires 'Class::Accessor::Fast';
requires 'Email::Address';
requires 'Email::Abstract';
requires 'Email::Abstract::QpsmtpdTransaction';
requires 'HTTP::Request::Common';
requires 'LWP::UserAgent';
requires 'URI';
requires 'YAML';

test_requires 'Test::More';

auto_include;

WriteAll;
