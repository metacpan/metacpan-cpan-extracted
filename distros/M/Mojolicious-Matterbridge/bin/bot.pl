#!perl
use strict;
use warnings;
use Mojolicious::Matterbridge;

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

# This is basically an Infobot in 40 lines of Perl
my %knowledge;

my $bot_name = "mybot";

sub handle_message( $msg ) {
    my @result;

    # query
    if(    $msg->text =~ /^(Who|what|where|when)\s+(is|are)\s+(.*?)$/i
        or $msg->text =~ /^()()(.*?)\?+$/i ) {
        my ($query, undef, $topic) = ($1,$2,$3);
        if( my $definition = $knowledge{ $topic }) {
            push @result, $msg->reply( "$topic $definition", username => $bot_name );
        };
    # replace
    } elsif( $msg->text =~ /^No,\s+(.*?)\s+((?:is|are)\s+.*)$/i ) {
        my ($topic, $definition) = (lc $1,$2);
        $knowledge{ $topic } = $definition;
        push @result, $msg->reply( "OK, $topic $definition" );

    # learn
    } elsif( $msg->text =~ /^(.*?)\s+((?:is|are)\s+.*)$/i ) {
        my ($topic, $definition) = (lc $1,$2,$3);
        if( not exists $knowledge{ $topic }) {
            $knowledge{ $topic } = $definition;
            push @result, $msg->reply( "OK, $topic $definition", username => $bot_name );
            print sprintf "Learned topic '%s' (%s)\n", $topic, $definition;

        } else {
            push @result, $msg->reply( "No, $topic $knowledge{$topic}", username => $bot_name );
        };
    } else {
        # Missing are "forget" and "<action>" and "<reply>"
        # See also: Bot::IRC::Infobot
        #print sprintf "Ignoring '%s'\n", $msg->text;
    };
    return @result;
}

my $client = Mojolicious::Matterbridge->new(
    url => 'http://localhost:4242/api/',
);

$client->on('message' => sub( $c, $message ) {
    print sprintf "<%s> %s\n", $message->username, $message->text;
    eval {
        $client->send( $_ ) for handle_message( $message );
    };
    warn $@ if $@;
});
$client->connect();

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
