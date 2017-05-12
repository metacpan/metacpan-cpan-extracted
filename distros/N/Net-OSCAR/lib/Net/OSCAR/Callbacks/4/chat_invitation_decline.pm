package Net::OSCAR::Callbacks;
BEGIN {
  $Net::OSCAR::Callbacks::VERSION = '1.928';
}
use strict;
use warnings;
use vars qw($connection $snac $conntype $family $subtype $data $reqid $reqdata $session $protobit %data);
sub {

#$session->callback_rendezvous_reject($data{cookie});
delete $session->{rv_proposals}->{$data{cookie}};

};
