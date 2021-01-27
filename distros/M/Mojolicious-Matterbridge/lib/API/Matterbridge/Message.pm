package API::Matterbridge::Message;
use strict;
use warnings;
use Moo 2;
use JSON 'decode_json';

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.01';

# This is just a hash-with-(currently no)-methods

has [
  "text",
  "channel",
  "username",
  "userid",
  "avatar",
  "account",
  "event",
  "protocol",
  "gateway",
  "parent_id",
  "timestamp",
  "id",
  "Extra",
 ] => (
    is => 'ro',
);

sub from_bytes( $class, $bytes ) {
    return $class->new( decode_json($bytes))
}

sub reply( $msg, $text, %options ) {
    my %reply = (
        gateway => $msg->gateway,
        text => $text,
        %options
    );
    return (ref $msg)->new(\%reply)
}

1;
