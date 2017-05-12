#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/t/45-rpc-serialized-acl-group-gdbm-file.t $
# $LastChangedRevision: 1363 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 15;

use File::Temp 'tempfile';
use URI::file;

SKIP: {
skip( "Cannot load GDBM_File", 15 )
    unless eval{ require GDBM_File };

use_ok( 'RPC::Serialized::ACL::Group::GDBM_File');
can_ok( 'RPC::Serialized::ACL::Group::GDBM_File', 'new' );
can_ok( 'RPC::Serialized::ACL::Group::GDBM_File', 'path' );
can_ok( 'RPC::Serialized::ACL::Group::GDBM_File', 'hash' );
can_ok( 'RPC::Serialized::ACL::Group::GDBM_File', 'is_member' );
can_ok( 'RPC::Serialized::ACL::Group::GDBM_File', 'match' );

my @members = qw(foo bar baz);
my $uri;
{
    my ( $fh, $path ) = tempfile( UNLINK => 1 );
    $fh->close();
    my %h;
    tie( %h, 'GDBM_File', $path, &GDBM_File::GDBM_NEWDB, 0644 )
        or die "Failed to tie GDBM file: $!";
    $h{$_} = 1 foreach @members;
    untie(%h) or die "Failed to untie GDBM file: $!";
    $uri = URI::file->new($path);
}

my $group = RPC::Serialized::ACL::Group::GDBM_File->new($uri);
isa_ok( $group, 'RPC::Serialized::ACL::Group::GDBM_File' );
isa_ok( $group, 'RPC::Serialized::ACL::Group::File' );
isa_ok( $group, 'RPC::Serialized::ACL::Group' );
is( $group->path, $uri->file );
isa_ok( $group->hash, 'HASH' );
foreach my $m (@members) {
    ok( $group->is_member($m) );
}
ok( not $group->is_member('quux') );

}
