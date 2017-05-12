#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/t/65-rpc-serialized-authz-handler-acl.t $
# $LastChangedRevision: 1635 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 17;

use File::Temp 'tempfile';

use_ok('RPC::Serialized::AuthzHandler::ACL');

eval { RPC::Serialized::AuthzHandler::ACL->new() };
isa_ok( $@, 'RPC::Serialized::X::Application' );
is( $@->message, 'ACL path not specified' );

eval { RPC::Serialized::AuthzHandler::ACL->new("/no/such/file") };
isa_ok( $@, 'RPC::Serialized::X::System' );
like( $@->message, qr{^Open .no.such.file failed:} );

my ( $fh, $path ) = tempfile( UNLINK => 1 );
$fh->print(<<'EOT');
some garbage
EOT
$fh->close();

eval { RPC::Serialized::AuthzHandler::ACL->new($path) };
isa_ok( $@, 'RPC::Serialized::X::Application' );
is( $@->message, "Failed to parse ACLs at '$path' line 1" );

( $fh, $path ) = tempfile( UNLINK => 1 );
$fh->print(<<'EOT');
# A comment; next line intentionally blank

deny info by ray on foo
allow info by ray on ALL # line-end comment
deny update by ray on ALL
# another comment
allow ALL by root on ALL
EOT
$fh->close();

my $ah = RPC::Serialized::AuthzHandler::ACL->new($path);
isa_ok( $ah, 'RPC::Serialized::AuthzHandler::ACL' );
isa_ok( $ah, 'RPC::Serialized::AuthzHandler' );
ok( $ah->check_authz( 'ray',     'info',       'bar' ) );
ok( not $ah->check_authz( 'ray', 'info',       'foo' ) );
ok( not $ah->check_authz( 'foo', 'info',       'bar' ) );
ok( not $ah->check_authz( 'ray', 'update',     'bar' ) );
ok( not $ah->check_authz( 'ray', 'update',     'foo' ) );
ok( $ah->check_authz( 'root',    'update',     'foo' ) );
ok( $ah->check_authz( 'root',    'info',       'bar' ) );
ok( not $ah->check_authz( 'ray', 'nosucnfunc', 'foo' ) );
