#!/usr/bin/perl

=head1 000-use.t

Nginx::Module::Gallery

=cut

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests => 5;

require_ok 'Nginx';
require_ok 'Digest::MD5';
require_ok 'Mojo::Template';
require_ok 'MIME::Base64';
require_ok 'MIME::Types';
require_ok 'File::Path';
require_ok 'Image::Magick';
