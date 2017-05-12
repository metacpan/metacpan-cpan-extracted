use 5.008002;

use strict qw(vars subs);
use Config;
use ExtUtils::MakeMaker;
require EV::MakeMaker;

WriteMakefile(
    
	'CONFIGURE_REQUIRES' => {
		'EV' => 0
	},

	'CONFIGURE' => sub {
		return {EV::MakeMaker::ev_args(
		depend => {
			   "Wslay.c" => "libwslay/wslay_queue.c libwslay/wslay_event.c libwslay/wslay_net.c libwslay/wslay_stack.c libwslay/includes/wslay/wslay.h libwslay/wslay_event.h libwslay/wslay_frame.c libwslay/wslay_frame.h libwslay/wslay_net.h libwslay/wslay_stack.h libwslay/wslay_queue.h",
			},
			INC       => "-Ilibwslay -Ilibwslay/includes", 
			# DEFINE    => "$DEFINE",
			NAME => "Net::WebSocket::EV",
			# LIBS => [$LIBS],
			VERSION_FROM => "EV.pm",
				
		
		)};
	},
  
  
);


