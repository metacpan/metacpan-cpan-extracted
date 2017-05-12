package VCP::MainBranchIdDB;

=head1 NAME

VCP::MainBranchIdDB - Persistant storage for tracking which branch_ids are the main CVS dev branch for each file.

=head1 SYNOPSIS

    use base qw( VCP::MainBranchIdDB );

=head1 DESCRIPTION

Some repositories branch in file name space (p4, vss), others in
revision number space (cvs).  Those that branch in revision space have
an inherent concept of a file's main branch in its revision number,
while those that branch in name space do not have an inherent idea of
the main branch of a file that can be discerned without going back and
checking the first revision of each file.  In other words, these
repositories always have a branch_id, event for the main branch of
a file.

It's up to the destination repository to track which branch of each file
it considers to be the main development branch.

Note that "" is a perfectly valid branch_id that often indicates the
main development branch.  This is SCM (and VCP::Source::*) specific,
but occurs in cvs and is expected to occur in any SCMs that branch in
revision space and have the empty prefix as the branch prefix for the
main development branch.

NOTE: unlike RevMapDB and HeadRevsDB, this DB is not modelling
information per source repository; it is modelling information per
destination repository.  So the key is destination-side and does not
include the source_repo_id.

TODO: allow the user to indicate this using a VCP::Filter::* module.

=for test_script t/02revmapdb.t

=cut

$VERSION = 1 ;

use strict ;
require Carp;

## TODO: Make the base class pluggable
use base "VCP::DB";

sub new {
    shift->SUPER::new( TableName => "dest_main_branch_id", @_ );
}


#sub get {
#    my VCP::MainBranchIdDB $self = shift;
#    my ( $key ) = @_;
#
#    my @v = $self->SUPER::get( $key );
#
#    Carp::confess "vcp: no MainBranchIdDB entry for ",
#        join( ";", @$key ),
#        "\n"
#        unless @v;
#
#    return @v;
#}


sub set {
    my VCP::MainBranchIdDB $self = shift;
    my ( $key ) = @_;

    warn "vcp: overwriting MainBranchIdDB entry for ",
       join( ";", @$key ),
       ".  Stale vcp_state in ",
       $self->store_loc, "?\n"
      if $self->exists( $key );

    $self->SUPER::set( @_ );
}

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
