#!perl

package t::dbh;

use strict;
use warnings;
use Module::Build;
use Exporter;
use base q(Exporter);

our @EXPORT = qw(test_db);

return 1;

sub test_db {
    my $build = Module::Build->current;
    return unless $build->notes('DBI_DSN');
    return map {
        defined $build->notes($_) ? $build->notes($_) : ''
    } qw(DBI_DSN DBI_USER DBI_PASS);
}
