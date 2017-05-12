use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::uwsgi',
    VERSION_FROM     => 'lib/Net/uwsgi.pm',
);
