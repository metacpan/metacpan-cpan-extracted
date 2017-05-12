#! /usr/bin/perl
use Modern::Perl;
use autodie;
use Nagios::Plugin::Simple;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use Email::Simple;
use Email::Simple::Creator;
use Try::Tiny;
use YAML;

my %cfg = do {
    if ( @ARGV > 1 ) { @ARGV }
    else { %{ YAML::LoadFile shift } }
};


my $nagios   = Nagios::Plugin::Simple->new;
my $mailhost = Email::Sender::Transport::SMTP->new
    ( map { $_ => $cfg{$_} } qw< host port > )
        or die;

my $msg = "i challenged you the ". `date`;

try {
    my $email = Email::Simple->create
    ( header =>
        [ To      => $cfg{to}
        , From    => $cfg{from}
        , Subject => $msg
    ] , body => $msg );
    sendmail ( $email , { transport => $mailhost } );
} catch {
    $nagios->critical( $_->message )
};

$nagios->ok('sent to the mailing list')

__DATA__

just run

    ./check_email_sender.pl /path/to/conf.yml

when conf.yml can be 

    host: mailhost.example.com
    port: 25 
    to: monitor-recipient@example.com
    from: monitor@example.com 

I really think that every parameter are self-explained. please email me if not. 

You can also pass every param from argv (Thonas said it's a feature):

    ./check_email_sender.pl host mailhost.example.com port 25 to monitor-recipient@example.com from monitor@example.com 

=cut

1;
