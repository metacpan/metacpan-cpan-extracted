package VCP::HeadRevsDB;

=head1 NAME

VCP::HeadRevsDB - Persistant storage for id -> (name, rev_id) maps

=head1 SYNOPSIS

    use base qw( VCP::HeadRevsDB );

=head1 DESCRIPTION

By default, most VCP::Dest::* drivers keep track of the head revision
transferred to the destination for each branch of each file.  This
is used by VCP::Source::* drivers when figuring out what revisions
to export in an incremental (or resumed) export..

The intent for this file is to serve as a base class so that individual
sites may write their own HeadRevsDB plugins to, for instance, store this
state in a RDBMS table.  This is not quite offered at this time; we need
to add an option to the appropriate VCP::Dest::* modules to allow the
appropriate HeadRevsDB file to be loaded.

To write your own HeadRevsDB file, see VCP::HeadRevsDB::sdbm.

=for test_script t/01revmapdb.t

=cut

$VERSION = 1 ;

use strict ;

use base "VCP::DB";

sub new {
    shift->SUPER::new( TableName => "head_revs", @_ );
}

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
