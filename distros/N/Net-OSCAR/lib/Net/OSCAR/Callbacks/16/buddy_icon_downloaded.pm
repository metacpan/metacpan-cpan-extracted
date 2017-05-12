package Net::OSCAR::Callbacks;
BEGIN {
  $Net::OSCAR::Callbacks::VERSION = '1.928';
}
use strict;
use warnings;
use vars qw($connection $snac $conntype $family $subtype $data $reqid $reqdata $session $protobit %data);
sub {

my $screenname = $data{screenname};
my $user_info = $session->{userinfo}->{$screenname} ||= {};
$user_info->{icon_checksum} = $data{checksum};
$user_info->{icon} = $data{icon};
$session->callback_buddy_icon_downloaded($user_info->{screenname}, $data{icon});

};
