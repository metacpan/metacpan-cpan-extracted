use strict;
use warnings;

use RT::Extension::DynamicWebPath::Test tests => undef;

plan skip_all => 'This test only works for RT_TEST_WEB_HANDLER=apache+fcgid'
  unless ( $ENV{RT_TEST_WEB_HANDLER} // '' ) eq 'apache+fcgid';

RT->Config->Set(
    'DynamicWebPath' => (
        '' => {
            WebRemoteUserAuth    => 1,
            WebFallbackToRTLogin => 0,
        },
        '/rt' => {
            WebRemoteUserAuth    => 0,
            WebFallbackToRTLogin => 1,
        }
    ),
);

my $autoreply = RT::Template->new( RT->SystemUser );
$autoreply->Load('Autoreply in HTML');
my ( $ret, $msg ) = $autoreply->SetContent( $autoreply->Content . <<'EOF' );
{RT->Config->Get("WebURL")}Ticket/Display.html?id={$Ticket->id}
EOF
ok( $ret, $msg );

{
    my ( $url, $m ) = RT::Extension::DynamicWebPath::Test->started_ok( basic_auth => 'anon' );

    # REMOTE_USER of root
    $m->auth("root");

    # Automatically logged in as root without Login page
    $m->get_ok($url);
    ok $m->logged_in_as("root"), "Logged in as root";
    $m->follow_link_ok( { text => 'Users', id => 'admin-users' } );
    $m->follow_link_ok( { text => 'root' } );
    is( $m->uri->path, '/Admin/Users/Modify.html', 'User link matches empty WebPath' );

    # Drop credentials
    $m->auth('');

    $m->get($url);
    is $m->status, 403, "403 Forbidden from RT";

    $m->get( $url . '/?user=root;pass=password' );
    is $m->status, 403, "403 Forbidden from RT";

    $m->get_ok( $url . '/rt' );
    $m->content_like( qr/Login/, "Login form" );
    $m->get_ok( $url . '/rt/?user=root;pass=password' );
    ok $m->logged_in_as("root"), "Logged in as root";

    $m->follow_link_ok( { text => 'Users', id => 'admin-users' } );
    $m->follow_link_ok( { text => 'root' } );
    is( $m->uri->path, '/rt/Admin/Users/Modify.html', 'User link matches WebPath /rt' );

    my $text = <<EOF;
From: root\@localhost
To: rt\@@{[RT->Config->Get('rtname')]}
Subject: This is a test of new ticket creation

Test email
EOF

    my ( $status, $id ) = RT::Extension::DynamicWebPath::Test->send_via_mailgate_and_http($text);
    is( $status >> 8, 0, "The mail gateway exited normally" );
    ok( $id, "Created ticket" );

    my $tick = RT::Extension::DynamicWebPath::Test->last_ticket;
    isa_ok( $tick, 'RT::Ticket' );
    is( $tick->Id, $id, "correct ticket id" );
    is( $tick->Subject, 'This is a test of new ticket creation', "Created the ticket" );

    my @mails = RT::Extension::DynamicWebPath::Test->fetch_caught_mails;
    is( scalar @mails, 1, 'Got one email' );
    like( $mails[0], qr!$url/Ticket/Display\.html!, 'WebURL in emails is /' );

    $m->no_warnings_ok;
}

done_testing;
