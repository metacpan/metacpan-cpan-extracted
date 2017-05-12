use inc::Module::Install;

name 'Qpsmtpd-Plugin-EmailAddressLoose';
all_from 'lib/Qpsmtpd/Plugin/EmailAddressLoose.pm';

die "\nPlease install Qpsmtpd first. http://smtpd.develooper.com/\n"
    unless eval { require Qpsmtpd };

requires 'Qpsmtpd::Plugin';
requires 'Email::Address::Loose';

auto_include;

WriteAll;
