use inc::Module::Install;

name        'Net-Abuse-Utils-Spamhaus';
all_from    'lib/Net/Abuse/Utils/Spamhaus.pm';

requires    'Net::DNS'  => '0.74';

WriteAll();
