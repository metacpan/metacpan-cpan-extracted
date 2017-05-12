use Net::Jabber::Bot;
use XML::Smart;
use utf8;
use strict;

# Simple RSS bot (yjesus@security-projects.com)
# It works fine with Feedburner


my $url = 'http://feeds.boingboing.net/boingboing/iBag' ;

my $username = 'your.gtalk.user';
my $password = 'yourpassword';


my ($last_title, $last_link) = checa();

my $bot = Net::Jabber::Bot->new({
                                 server => 'talk.google.com'
                                , gtalk => 1
                                , conference_server => 'talk.google.com'
                                , port => 5222
                                , username => $username
                                , password => $password
                                , alias => $username
                                , message_callback => \&new_bot_message
                                , background_activity => \&background_checks
                                , loop_sleep_time => 15
                                , process_timeout => 5
                                , ignore_server_messages => 0
                                , ignore_self_messages => 0
                                , out_messages_per_second => 40
                                , max_message_size => 1000
                                , max_messages_per_hour => 100
                            })|| die "ooops\n" ;


my @users = $bot->GetRoster() ;

$bot->Start();

sub new_bot_message {
    my %bot_message_hash = @_;

    my $user = $bot_message_hash{reply_to} ;
    my $message = lc($bot_message_hash{body});


    if ($message =~ m/\bhelp\b/) {
        $bot->SendPersonalMessage($user, "Hi Im a RSS-BOT for Gtalk !!");
    }
}



sub background_checks {
    my ($title, $link) = checa();

    return if ($last_title eq $title)
    foreach my $tosend (@users) {
          
        my $status = $bot->GetStatus($tosend);
          
        if ($status != "unavailable") {
          
            $bot->SendPersonalMessage($tosend, "$title");
            $bot->SendPersonalMessage($tosend, "$link");
        }    
        
    }
    
    $last_title=$title; # Now make the new title recieved the most recent title.
}

sub checa {
    my $XML ;

    eval { $XML = XML::Smart->new($url) };
    if ($@) { return undef }

    $XML = $XML->cut_root ;
    my $title =$XML->{channel}{item}[0]{title}[0] ;
    my $link =$XML->{channel}{item}[0]{link}[0] ;

    utf8::encode($title);
    utf8::encode($link);

    return($title, $link)
}







