!/usr/bin/env perl
#
# RT::Extension::GroupBroadcast
#
# - Send a test email using RT's inbuilt sendmail system.
#

BEGIN {
    use FindBin qw/$Bin/;
    use lib "$Bin/../../../../local/lib", "$Bin/../../../../lib";
}
use strict;
use warnings;
use feature qw/say/;

use File::Basename qw/basename/;
use Encode;
use MIME::Entity;
use RT;
use RT::Interface::Email;
use RT::Interface::CLI qw/CleanEnv/;

sub usage { say("  Usage: ". basename($0) ." <EMAIL>") && exit(1); }

my $email = shift @ARGV or usage();

$|++;
CleanEnv();
RT::LoadConfig();
RT::Init();

send_message_to( To => $email );
exit;


sub send_message_to {
# ----------------------------------------------------------------------------
    my %args = (
        From    => 'noreply@example.com',
        To      => 'devnull@example.com',
        Subject => 'RT::Extension::GroupBroadcast',
        Message => 'This is a test message. Please ignore/delete.',
        @_,
    );

    my $mime = MIME::Entity->build(
        'From'        => Encode::encode_utf8($args{From}),
        'To'          => Encode::encode_utf8($args{To}),
        'Subject'     => Encode::encode_utf8($args{Subject}),
        'Data'        => Encode::encode_utf8($args{Message})
    );
    my $ok = RT::Interface::Email::SendEmail( Entity => $mime );
    say "send-ok?: $ok\n";
}

