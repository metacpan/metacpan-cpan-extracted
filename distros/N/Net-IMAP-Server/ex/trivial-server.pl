#!/usr/bin/perl
use Net::IMAP::Server;

package Demo::IMAP::Auth;
$INC{'Demo/IMAP/Auth.pm'} = 1;
use base 'Net::IMAP::Server::DefaultAuth';

sub auth_plain {
    my ( $self, $user, $pass ) = @_;

    # XXX DO AUTH CHECK
    $self->user($user);
    return 1;
}

package Demo::IMAP::Model;
$INC{'Demo/IMAP/Model.pm'} = 1;
use base 'Net::IMAP::Server::DefaultModel';

sub init {
    my $self = shift;
    $self->root( Demo::IMAP::Mailbox->new() );
    $self->root->add_child( name => "INBOX" );
}

package Demo::IMAP::Mailbox;
use base qw/Net::IMAP::Server::Mailbox/;

my $data = <<'EOF';
From: jesse@example.com
To: user@example.com
Subject: This is a test message!

Hello. I am executive assistant to the director of
Bear Stearns, a failed investment Bank.  I have 
access to USD6,000,000. ...
EOF

my $msg = Net::IMAP::Server::Message->new($data);

sub load_data {
    my $self = shift;
    $self->add_message($msg);
}

my %ports = ( port => 143, ssl_port => 993 );
$ports{$_} *= 10 for grep {$> > 0} keys %ports;

Net::IMAP::Server->new(
    auth_class  => "Demo::IMAP::Auth",
    model_class => "Demo::IMAP::Model",
    user        => 'nobody',
    %ports,
)->run();

