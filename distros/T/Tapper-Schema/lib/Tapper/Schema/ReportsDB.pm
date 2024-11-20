package Tapper::Schema::ReportsDB;
our $AUTHORITY = 'cpan:TAPPER';

use 5.010;

use strict;
use warnings;

# Only increment this version here on schema changes.
# For everything else increment Tapper/Schema.pm.
our $VERSION = '4.001002';

# avoid these warnings
#   Subroutine initialize redefined at /2home/ss5/perl510/lib/site_perl/5.10.0/Class/C3.pm line 70.
#   Subroutine uninitialize redefined at /2home/ss5/perl510/lib/site_perl/5.10.0/Class/C3.pm line 88.
#   Subroutine reinitialize redefined at /2home/ss5/perl510/lib/site_perl/5.10.0/Class/C3.pm line 101.
# by forcing correct load order.
BEGIN {
        use Class::C3;
        use MRO::Compat;
}

use parent 'DBIx::Class::Schema';

our $NULL  = 'NULL';
our $DELIM = ' | ';

__PACKAGE__->load_components(qw/+DBIx::Class::Schema::Versioned/);
__PACKAGE__->upgrade_directory('./lib/auto/Tapper/Schema/');
__PACKAGE__->backup_directory('./lib/auto/Tapper/Schema/');
__PACKAGE__->load_namespaces;


sub backup
{
        #say STDERR "(TODO: Implement backup method.)";
        1;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::ReportsDB

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

__END__

# ------------------------------------------------------------

# Create subdir
mkdir -p reportdb/upgrades reportdb/backups

# dump current SQL
# no *not* provide arg4 with previous version number
perl -Ilib -MTapper::Schema::ReportsDB -MTapper::Model=model -e 'model("ReportsDB")->create_ddl_dir([qw/MySQL SQLite Pg/], undef, "reportdb/upgrades/")'


# change Schema and Version number

#    tapper-db-deploy makeschemadiffs --db=ReportsDB --fromversion=2.010013 --upgradedir=./
#    tapper-db-deploy upgrade         --db=ReportsDB

# create diff from requested old to current version
# create version erzeugen (now ith arg4)
perl -Ilib -MTapper::Schema::ReportsDB -e 'Tapper::Schema::ReportsDB->connect("DBI:SQLite:foo")->create_ddl_dir([qw/MySQL SQLite Pg/], undef, "upgrades/", "2.010012") or die'

# Upgrade currently connected old Schema to current version
# For this the earlier created diffs in upgrade_directory() are used and
# Backups are put into backup_directory()
perl -I. -MReportDB -e 'my $s = ReportDB->connect("DBI:SQLite:foo"); $s->upgrade or die'
