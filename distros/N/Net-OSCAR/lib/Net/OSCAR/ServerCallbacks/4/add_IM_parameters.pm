package Net::OSCAR::ServerCallbacks;
BEGIN {
  $Net::OSCAR::ServerCallbacks::VERSION = '1.928';
}
use strict;
use warnings;
use vars qw($SESSIONS $SCREENNAMES %COOKIES $screenname $connection $snac $conntype $family $subtype $data $reqid $reqdata $session $protobit %data);
sub {

$connection->proto_send(protobit => "IM_parameter_response", reqid => $reqid, protodata => {channel => $data{channel}});

};

