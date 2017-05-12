#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 5;
use Encode qw(decode encode);

BEGIN {
    require_ok 'Mojolicious';
    require_ok 'DateTime';
    require_ok 'DateTime::Format::DateParse';
    require_ok 'Test::Compile';
}

ok $Mojolicious::VERSION >= 2.23,       'Mojolicious version >= 2.23';


=head1 AUTHORS

Dmitry E. Oboukhov <unera@debian.org>,
Roman V. Nikolaev <rshadow@rambler.ru>

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
