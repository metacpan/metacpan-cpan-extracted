# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POE-Component-Growl.t'

use warnings;
use strict;

use Test::More tests => 1;
BEGIN { use_ok('POE::Component::Growl') };

use POE;
use POE::Component::Growl;


POE::Component::Growl->spawn(
	Alias 			=> 'MyGrowl',
	AppName 		=> 'POE::Component::Growl Test',
	Notifications 	=> [ 'test 1' ]
);

POE::Session->create(
	inline_states => {
		_start => sub {
			my ($kernel) = $_[KERNEL];
			$kernel->post(
				'MyGrowl',
				'post', {
					name => 'test 1',
					title => 'Congratulations',
					descr => 'POE::Component::Growl is working.',
					stick => 1
				}
			);
		}
	}
);

POE::Kernel->run();

__END__
