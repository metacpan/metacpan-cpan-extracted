use strict;
use utf8;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR         => 'Alexander Borisov <lex.borisov@gmail.com>',
    ABSTRACT_FROM  => 'Client.pm',
    VERSION_FROM   => 'Client.pm',
    NAME           => 'Net::RabbitMQ::Client',
    LICENSE        => 'perl',
    LINKTYPE       => 'dynamic',
    LIBS           => ["-L/usr/local/lib64 -L/usr/lib64 -L/usr/local/lib -L/usr/lib -lrabbitmq"],
    INC            => '-I/usr/local/include -I/usr/include -I/opt/local/include -I/opt/include'
);


