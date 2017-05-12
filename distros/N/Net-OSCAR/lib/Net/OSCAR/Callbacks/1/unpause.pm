package Net::OSCAR::Callbacks;
BEGIN {
  $Net::OSCAR::Callbacks::VERSION = '1.928';
}
use strict;
use warnings;
use vars qw($connection $snac $conntype $family $subtype $data $reqid $reqdata $session $protobit %data);
sub {

$connection->log_print(OSCAR_DBG_WARN, "Migration cancelled by server!");
$connection->unpause();
$connection->loglevel(delete $connection->{__old_loglevel});

};
