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

isa_ok($upload, 'Parse::PAUSE::Plugin::UploadedFile');
is($upload->upload(), 'Coat-Persistent-0.104.tar.gz');
is($upload->pathname(), '$CPAN/authors/id/S/SU/SUKRIA/Coat-Persistent-0.104.tar.gz');
is($upload->size(), 24105);
is($upload->md5(), '5f84687ad671b675c6e2936c7b2b3fd7');
is($upload->entered_by(), 'SUKRIA (Alexis Sukrieh)');
is($upload->entered_on(), 'Fri, 05 Jun 2009 17:10:00 GMT');
is($upload->completed(), 'Fri, 05 Jun 2009 17:11:11 GMT');
is($upload->paused_version(), 1047);

__DATA__
The uploaded file

    Coat-Persistent-0.104.tar.gz

has entered CPAN as

  file: $CPAN/authors/id/S/SU/SUKRIA/Coat-Persistent-0.104.tar.gz
  size: 24105 bytes
   md5: 5f84687ad671b675c6e2936c7b2b3fd7

No action is required on your part
Request entered by: SUKRIA (Alexis Sukrieh)
Request entered on: Fri, 05 Jun 2009 17:10:00 GMT
Request completed:  Fri, 05 Jun 2009 17:11:11 GMT

Thanks,
-- 
paused, v1047
