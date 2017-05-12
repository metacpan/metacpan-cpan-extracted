package Net::OSCAR::ServerCallbacks;
BEGIN {
  $Net::OSCAR::ServerCallbacks::VERSION = '1.928';
}
use strict;
use warnings;
use vars qw($SESSIONS $SCREENNAMES %COOKIES $screenname $connection $snac $conntype $family $subtype $data $reqid $reqdata $session $protobit %data);
sub {

print "$screenname finished signing on.\n";
$connection->{signon_done} = 1;

};

