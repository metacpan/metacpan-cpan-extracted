package VCP::FilesDB;

=head1 NAME

VCP::FilesDB - Persistant storage for path -> state

=head1 SYNOPSIS

    use base qw( VCP::FilesDB );

=head1 DESCRIPTION

VCP::Dest::cvs needs to record what it's seen for each file as its seen it
so that it can decide whether a file is new or not.

=for test_script t/01revmapdb.t

=cut

$VERSION = 1 ;

use strict ;

use base "VCP::DB";

sub new {
    shift->SUPER::new( TableName => "dest_files", @_ );
}

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
