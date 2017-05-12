package SmokeRunner::Multi::DBI;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: DBI helpers for SmokeRunner::Multi
$SmokeRunner::Multi::DBI::VERSION = '0.21';
use strict;
use warnings;

use DBD::SQLite;
use DBI;
use File::Spec;
use SmokeRunner::Multi::Config;


{
    my $dbh;
    sub handle
    {
        return $dbh if $dbh;

        my $config = SmokeRunner::Multi::Config->instance();

        my $db_file = File::Spec->catfile( $config->root_dir(),
            'smokerunner.sqlite' );

        $dbh = DBI->connect( "dbi:SQLite:dbname=$db_file", '', '',
                             { RaiseError => 1 } );

        _create_database($dbh)
            unless -s $db_file;

        return $dbh;
    }
}

{
    my $ddl = <<'EOF';
CREATE TABLE TestSet (
   name            TEXT     NOT NULL PRIMARY KEY,
   last_run_time   INTEGER  NOT NULL DEFAULT 0,
   is_prioritized  INTEGER  NOT NULL DEFAULT 0
);
EOF

    sub _create_database
    {
        my $dbh = shift;

        $dbh->do($ddl);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SmokeRunner::Multi::DBI - DBI helpers for SmokeRunner::Multi

=head1 VERSION

version 0.21

=head1 SYNOPSIS

  my $dbh = SmokeRunner::Multi::DBI::handle();

=head1 DESCRIPTION

This module is used to create a SQLite database for
C<SmokeRunner::Multi>.

=head2 Database Schema

The schema consists of a single table, "TestSet", which is used to
store information about test sets that is not available by examining
them on the filesystem. Specifically, it stores their last run time,
and a flag indicating whether a set is prioritized.

=head1 FUNCTIONS

This class has one public function:

=head2 SmokeRunner::Multi::DBI::handle()

This returns a new DBI handle connected to the SQLite database found
in the root directory defined in the config file.

If the database does not yet exist, it will be created.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-smokerunner-multi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 LiveText, Inc., All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by LiveText, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
