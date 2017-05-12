#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 9;
use Parse::PAUSE;

my $data;

{
    local undef $/;
    $data = <DATA>;
}

my $upload = Parse::PAUSE->parse($data);

isa_ok($upload, 'Parse::PAUSE::Plugin::URL');
is($upload->upload(), 'http://voltar.org/PerlModules/Net-IMAP-Simple-1.1800.tar.gz');
is($upload->pathname(), '$CPAN/authors/id/J/JE/JETTERO/Net-IMAP-Simple-1.1800.tar.gz');
is($upload->size(), 11608);
is($upload->md5(), '9518f5e567123f02b8328082df61a4c6');
is($upload->entered_by(), 'JETTERO (Paul Miller)');
is($upload->entered_on(), 'Fri, 05 Jun 2009 18:14:25 GMT');
is($upload->completed(), 'Fri, 05 Jun 2009 18:14:40 GMT');
is($upload->paused_version(), 1047);

__DATA__
The URL

    http://voltar.org/PerlModules/Net-IMAP-Simple-1.1800.tar.gz

has entered CPAN as

  file: $CPAN/authors/id/J/JE/JETTERO/Net-IMAP-Simple-1.1800.tar.gz
  size: 11608 bytes
   md5: 9518f5e567123f02b8328082df61a4c6

No action is required on your part
Request entered by: JETTERO (Paul Miller)
Request entered on: Fri, 05 Jun 2009 18:14:25 GMT
Request completed:  Fri, 05 Jun 2009 18:14:40 GMT

Thanks,
-- 
paused, v1047
