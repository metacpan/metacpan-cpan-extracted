package Net::OSCAR::Callbacks;
BEGIN {
  $Net::OSCAR::Callbacks::VERSION = '1.928';
}
use strict;
use warnings;
use vars qw($connection $snac $conntype $family $subtype $data $reqid $reqdata $session $protobit %data);
sub {

$connection->{families} = { map { $_ => 1 } @{$data{families}} };
send_versions($connection, 0);
$connection->proto_send(protobit => "rate_info_request", nopause => 1);

};
