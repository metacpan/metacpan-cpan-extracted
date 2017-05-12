package Net::OSCAR::Callbacks;
BEGIN {
  $Net::OSCAR::Callbacks::VERSION = '1.928';
}
use strict;
use warnings;
use vars qw($connection $snac $conntype $family $subtype $data $reqid $reqdata $session $protobit %data);
sub {

# Maximum number of buddies is minimum of this and the "buddylist 3 response" value
if($session->{bl_limits}->{buddies}) {
	if($data{maxbuddies} < $session->{bl_limits}->{buddies}) {
		$session->{bl_limits}->{buddies} = $data{maxbuddies};
	}
} else {
	$session->{bl_limits}->{buddies} = $data{maxbuddies};
}

};
