# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

package Pootle::Resource;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);

=head2 Pootle::Resource

Parent class of Pootle::Resource::*

=cut

1;
