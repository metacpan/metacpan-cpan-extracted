use strict;
use inc::Module::Install;

name          'Plack-Handler-Net-FastCGI';
perl_version  '5.006';
all_from      'lib/Plack/Handler/Net/FastCGI.pm';
repository    'http://github.com/chansen/p5-plack-handler-net-fastcgi';
readme_from   'lib/Plack/Handler/Net/FastCGI.pm';

requires      'Plack'            => '0.9985';
requires      'Net::FastCGI'     => '12';

tests 't/*.t t/*/*.t';

WriteAll;

