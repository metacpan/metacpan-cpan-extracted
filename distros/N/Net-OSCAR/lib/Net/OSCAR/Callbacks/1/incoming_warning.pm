package Net::OSCAR::Callbacks;
BEGIN {
  $Net::OSCAR::Callbacks::VERSION = '1.928';
}
use strict;
use warnings;
use vars qw($connection $snac $conntype $family $subtype $data $reqid $reqdata $session $protobit %data);
sub {

$session->callback_evil($data{new_level} / 10, Net::OSCAR::Screenname->new(\$data{screenname}) || undef);

};
