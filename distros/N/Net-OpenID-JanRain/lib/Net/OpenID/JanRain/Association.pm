package Net::OpenID::JanRain::Association;

# for equality testing.  Below and above must be the same
my $CLASSNAME = "Net::OpenID::JanRain::Association";
# vi:ts=4:sw=4

use warnings;
use strict;

use Carp;

use Net::OpenID::JanRain::Util qw( kvToHash hashToPairs pairsToKV fromBase64 toBase64);
use Net::OpenID::JanRain::CryptUtil qw( hmacSha1 );

# This is a HMAC-SHA1 specific value.
my $SIG_LENGTH = 20;

# The ordering and name of keys as stored by serialize
# Note that if you change this you must change sub serialize below
my @assoc_keys = (
        'version',
        'handle',
        'secret',
        'issued',
        'lifetime',
        'assoc_type',
        );

########################################################################
# fromExpiresIn
# This is an alternate constructor used by the OpenID consumer
# library to create associations.  OpenIDStore implementations
# shouldn't use this constructor.
# Like new, but uses the current time as the issue date
sub fromExpiresIn {
	my $caller = shift;
	my ($expires_in, $handle, $secret, $assoc_type) = @_;
    my $class = ref($caller) || $caller;
    my $issued = time;
	my $self = {handle => $handle,
                secret => $secret,
                issued => $issued,
                lifetime => $expires_in,
                assoc_type => $assoc_type};
    bless($self, $class);
} # end fromExpiresIn
########################################################################
# new
# Create a new association object with the given:
# handle: an identifying string, provided by the server
# secret: the shared secret, a string provided by the server
# issued: the time when the association was issued, in seconds since the epoch
# lifetime: after this many seconds since issued, association is invalid
# assoc_type: the 'type' of association. currently only 'HMAC-SHA1' is valid.
sub new {
	my $caller = shift;
	my ($handle, $secret, $issued, $lifetime, $assoc_type) = @_;
	my $class = ref($caller) || $caller;
	my $self = {handle => $handle,
                secret => $secret,
                issued => $issued,
                lifetime => $lifetime,
                assoc_type => $assoc_type};
	bless($self, $class);
} # end new
########################################################################
# expiresIn
# if we are expired return 0, otherwise the number of seconds we have left
sub expiresIn {
	my $self = shift;
    my $timeleft = $self->{issued} + $self->{lifetime} - time;
    return 0 if $timeleft < 0;
    return $timeleft;
} # end expiresIn
########################################################################
# equals
# Check to see if we are the same association as another object
sub equals {
	my $self = shift;
	my ($other) = @_;
    return ($other->isa($CLASSNAME)
            and $self->{handle} eq $other->{handle}
            and $self->{secret} eq $other->{secret}
            and $self->{issued} eq $other->{issued}
            and $self->{lifetime} eq $other->{lifetime}
            and $self->{assoc_type} eq $other->{assoc_type});
} # end equals
########################################################################
# serialize
# return a newline separated key:value string containing the object data
# XXX: If the contents of the association object change, this function
# must also change.  Possibly use hashToPairs and pairsToKV instead
sub serialize {
	my $self = shift;

    my $enc_secret = toBase64($self->{secret});
	my $assoc_s =   "version:2\n".
                    "handle:$self->{handle}\n".
                    "secret:$enc_secret\n".
                    "issued:$self->{issued}\n".
                    "lifetime:$self->{lifetime}\n".
                    "assoc_type:$self->{assoc_type}\n";

    return $assoc_s;
} # end serialize
########################################################################
# deserialize
# This is a constructor that builds an association object from
# a newline separated key:value string
sub deserialize {
	my $caller = shift;
	my ($assoc_s) = @_;
    my $class = ref($caller) || $caller;
    
    my $assoc = kvToHash($assoc_s);

    my $key;
    #check for validity
    foreach $key (@assoc_keys) {
        return undef unless $assoc->{$key};
    }

    return undef if $assoc->{'version'} != 2;

    $assoc->{secret} = fromBase64($assoc->{secret});

    bless($assoc, $class);
} # end deserialize
########################################################################
# sign
# Sign a list of key,value pairs with our association key.
# takes a list of pairs, returns a string.
sub signPairs {
    my $self = shift;
    my ($pairs) = @_;

    carp "Association type '$self->{assoc_type}' cannot sign." 
            unless $self->{assoc_type} eq 'HMAC-SHA1';

    my $kv = pairsToKV($pairs);
    carp "Got no kvform to sign" unless $kv;
 
    return hmacSha1($self->{secret}, $kv);
}
    
# Sign stuff with our association key
# 1st arg is a hash ref, i.e. an http query
# 2nd arg is a list containing keys of the hash.  Sign the values in the hash
# at these keys: convert to a (k:v\n)+ string and sign the string with the
# association secret.
sub signHash {
    my $self = shift;
    my $args = shift;
    my $sign_list = shift;
    my $prefix = shift;

    return toBase64($self->signPairs(hashToPairs($args, $sign_list, $prefix)));
}   

sub addSignature {
    my $self = shift;
    my $args = shift;
    my $sign_list = shift;
    my $prefix = shift || '';
    #args must be a hash ref
    $args->{$prefix.'signed'} = join (',', @$sign_list);
    $args->{$prefix.'sig'} = $self->signHash($args, $sign_list, $prefix);
    return $args;
}

sub handle {
    my $self = shift;
    return $self->{handle};
}

sub assoc_type {
    my $self = shift;
    return $self->{assoc_type};
}

sub secret {
    my $self = shift;
    return $self->{secret};
}

1;
