package OAuthDemo;

=head1 SYNOPSIS

This code is, to a great degree, shamelessly lifted from example/twitter in
the Net::OAuth::Simple library.

=cut

use Net::FreshBooks::API::OAuth;

use Moose;
with 'MooseX::Getopt';

has 'account_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'consumer_key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'consumer_secret' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

use Data::Dump qw( dump );
use Devel::SimpleTrace;
use Find::Lib 'lib';
use Modern::Perl;
use JSON::Any;

binmode STDOUT, ":utf8";

sub run {

    my $self = shift;

    # Get the tokens from the command line
    my %tokens = (
        account_name    => $self->account_name,
        consumer_key    => $self->consumer_key,
        consumer_secret => $self->consumer_secret,
    );

    my $app = Net::FreshBooks::API::OAuth->new( %tokens );

    # Check to see we have a consumer key and secret
    unless ( $app->consumer_key && $app->consumer_secret ) {
        die "You must go get a consumer key and secret from App\n";
    }

    # If the app is authorized (i.e has an access token and secret)
    # Then look at a restricted resourse
    #get_dms( $app ) if $app->authorized;

    # right, we need to get their access stuff
    print "STEP 1: REQUEST FreshBooks AUTHORIZATION FOR THIS APP\n";
    print "\tURL : "
        . $app->get_authorization_url( callback => 'oob' ) . "\n";
    print "\n-- Please go to the above URL and authorize the app";
    print "\n-- It will give you a code. Please type it here: ";
    my $verifier = <STDIN>;
    print "\n";
    chomp( $verifier );
    $verifier =~ s!(^\s*|\s*$)!!g;
    $app->verifier( $verifier );

    my ( $access_token, $access_token_secret ) = $app->request_access_token();

    print "You have now authorized this app.\n";
    print "Your access token and secret are:\n\n";
    print "access_token=$access_token\n";
    print "access_token_secret=$access_token_secret\n";
    print "\n";
    print
        "You should note these down\n\n";
}

1;
