#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 10;
use Encode qw(decode encode);

BEGIN {
    require_ok 'Test::Compile';

    require_ok 'Mojolicious';
    require_ok 'DateTime';
    require_ok 'DateTime::Format::DateParse';
    require_ok 'Mail::RFC822::Address';
    require_ok 'Digest::MD5';

    use_ok 'Mojolicious';
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::Vparam';
}

cmp_ok(
     version->new($Mojolicious::VERSION), '>=', version->new(2.23),
    'Mojolicious version >= 2.23'
);


=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut
