#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 26;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

use File::Temp;
BEGIN { use_ok( 'Sakai::Nakamura' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Authn' ); }
BEGIN { use_ok( 'Sakai::Nakamura::Content' ); }

# sling object:
my $nakamura = Sakai::Nakamura->new();
isa_ok $nakamura, 'Sakai::Nakamura', 'sling';
$nakamura->{'URL'}     = $sling_host;
$nakamura->{'Verbose'} = $verbose;
$nakamura->{'Log'}     = $log;
# authn object:
my $authn = Sakai::Nakamura::Authn->new( \$nakamura );
isa_ok $authn, 'Sakai::Nakamura::Authn', 'authentication';
ok( $authn->login_user(), "Log in successful" );
# content object:
my $content = Sakai::Nakamura::Content->new( \$authn, $verbose, $log );
isa_ok $content, 'Sakai::Nakamura::Content', 'content';

# Check upload with non-logged in user:
my ( $tmp_content_handle, $tmp_content_name ) = File::Temp::tempfile();
print {$tmp_content_handle} "Test file\n";
throws_ok { $content->upload_file($tmp_content_name) } qr{Content: "$tmp_content_name" upload to /system/pool/createfile failed!}, 'Check upload_file function croaks when not logged in';
unlink($tmp_content_name);

# Recreate objects with user / pass set:
$nakamura->{'User'}    = $super_user;
$nakamura->{'Pass'}    = $super_pass;

# authn object:
$authn = Sakai::Nakamura::Authn->new( \$nakamura );
isa_ok $authn, 'Sakai::Nakamura::Authn', 'authentication';
ok( $authn->login_user(), "Log in successful" );
# content object:
$content = Sakai::Nakamura::Content->new( \$authn, $verbose, $log );
isa_ok $content, 'Sakai::Nakamura::Content', 'content';

# Run tests:
ok( defined $content,
    "Content Test: Sling Content Object successfully created." );

( $tmp_content_handle, $tmp_content_name ) = File::Temp::tempfile();
print {$tmp_content_handle} "Test file\n";
close $tmp_content_handle;
ok( $content->upload_file($tmp_content_name), 'Check upload_file function' );
ok( $content->comment_add('Test comment'), 'Check comment_add function' );
ok( $content->view_copyright(), 'Check view_copyright function' );
ok( $content->view_description(), 'Check view_description function' );
ok( $content->view_tags(), 'Check view_tags function' );
ok( $content->view_title(), 'Check view_title function' );
ok( $content->view_visibility(), 'Check view_visibility function' );
my $upload = "$tmp_content_name\n";
ok( $content->upload_from_file(\$upload,0,1), 'Check upload_from_file function' );
my ( $tmp_content2_handle, $tmp_content2_name ) = File::Temp::tempfile();
$upload .= "$tmp_content2_name\n";
print {$tmp_content2_handle} "Test file\n";
close $tmp_content2_handle;
ok( $content->upload_from_file(\$upload,0,2), 'Check upload_from_file function with two forks' );
unlink($tmp_content_name);
unlink($tmp_content2_name);
throws_ok{ $content->upload_from_file($tmp_content_name,0,1)} qr{Problem opening file: '$tmp_content_name'}, 'Check upload_file function croaks with a missing file';

ok( my $content_config = Sakai::Nakamura::Content->config($nakamura), 'check content config function' );
ok( defined $content_config );
throws_ok { Sakai::Nakamura::Content->run( $nakamura ) } qr/No content config supplied!/, 'Check run function croaks without config';
ok( Sakai::Nakamura::Content->run( $nakamura, $content_config ) );
