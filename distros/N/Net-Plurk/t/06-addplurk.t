#!perl -T
use utf8;
use Env qw(CONSUMER_KEY CONSUMER_SECRET ACCESS_TOKEN ACCESS_TOKEN_SECRET);
use Test::More;
if ($CONSUMER_KEY and $CONSUMER_SECRET 
    and $ACCESS_TOKEN and $ACCESS_TOKEN_SECRET) {
} else {
    plan skip_all =>
    "You must set the following environment variables: \n".
    "CONSUMER_KEY/CONSUMER_SECRET\n".
    "ACCESS_TOKEN/ACCESS_TOKEN_SECRET\n";
}

BEGIN {
	use Net::Plurk;
	use Net::Plurk::Plurk;
        use List::Util 'shuffle';
	my $p = Net::Plurk->new(consumer_key => $CONSUMER_KEY, consumer_secret => $CONSUMER_SECRET);
	$p->authorize(token => $ACCESS_TOKEN, token_secret => $ACCESS_TOKEN_SECRET);
        my @langs = shuffle ('en','pt_BR','cn','ca','el','dk','de','es','sv','nb','hi','ro','hr','fr','ru','it','ja','he','hu','ne','th','ta_fp','in','pl','ar','fi','tr_ch','tr','ga','sk','uk','fa');
        my $plurk_msg =  eval {
            use HTTP::Lite;
            use JSON::Any;
            $http = new HTTP::Lite;
            $http->request("http://more.handlino.com/sentences.json");
            my $j = JSON::Any->new();
            $json = $j->from_json( $http->body());
            $json->{sentences}[0];
        } || "Hello World!!!";
        my $plurk = $p->add_plurk($plurk_msg, "says", lang => $langs[0]);
        if (defined $plurk) {
            isa_ok ($plurk, Net::Plurk::Plurk);
            is($plurk->content, $plurk_msg);
        } else {
            is($p->errormsg, 'anti-flood-same-content');
            diag("The same content flooding"); 
        }
        done_testing();
}

diag( "Testing Net::Plurk add new plurk" );
