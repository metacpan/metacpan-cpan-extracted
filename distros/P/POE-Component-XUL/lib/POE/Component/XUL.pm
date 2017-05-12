package POE::Component::XUL;

use XUL::Node;
use XUL::Node::Server;
use POE qw(Session XUL::SessionManager XUL::Session);
use Carp qw(croak);

our $VERSION = '0.02';

sub spawn {
	my ($class, $args) = @_;

	$args->{port} = $args->{port} || '8077';
	$args->{root} = $args->{root} || '/usr/local/xul-node';
	$args->{apps} = {} if (!defined $args->{apps});
	$args->{opts} = {} if (!defined $args->{opts});

	unless (ref($args->{apps}) eq 'HASH') {
		croak "apps parameter must be a hash ref";
	}
	unless (ref($args->{opts}) eq 'HASH') {
		croak "opts parameter must be a hash ref";
	}
	foreach (keys %{$args->{apps}}) {
		if (ref($args->{apps}->{$_}) ne 'CODE') {
			croak "apps parameter $_ must be a code reference (callback or sub)";
		}
	}

	POE::Session->create(
		heap => $args,
		package_states => [
			eval { __PACKAGE__ } => [ qw( _start session_timeout ) ],
		],
	);
}

sub _start {
	my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

	$kernel->alias_set('poe_xul');
			
	# new server obj, with a friendlier session manager
	$heap->{server}  = bless({
		session_manager => POE::XUL::SessionManager->new(apps => $heap->{apps}, opts => $heap->{opts}),
		disable_root => $heap->{disable_root},
	}, 'XUL::Node::Server');

	$heap->{server}->create_http_server_component($heap->{port},$heap->{root});
	$heap->{server}->{session_timer} = XUL::Node::Server::SessionTimer->new(
		$session->callback('session_timeout')
	);
}

sub session_timeout {
	my ($kernel, $heap, $sn) = (@_[KERNEL, HEAP], $_[ARG1]->[0]);
	if (defined($heap->{session_timeout}) && ref($heap->{session_timeout}) eq 'CODE') {
		#no strict 'refs';
		$heap->{session_timeout}->(splice(@_,ARG0));
		#use strict 'refs';
	}
	$heap->{server}->timeout_session($sn);
}

1;

__END__

=head1 NAME

POE::Component::XUL - Easier use of XUL::Node when using POE

=head1 DESCRIPTION

POE::Component::XUL uses POE::XUL::SessionManager and POE::XUL::Session
in a slightly different way to allow poe callbacks to your session for
XUL application calls.

=head2 SYNOPSIS

	use POE qw( Component::XUL );
	use XUL::Node;
	use XUL::Node::Application;

	use base 'XUL::Node::Application';

	POE::Session->create(
		inline_states => {
			_start => sub {
				my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

				POE::Component::XUL->spawn({
					port => 8001,
					root => '/usr/local/xul-node',
					apps => {
						# a callback
						Test => $session->callback("client_start"),
						# or a sub
						Test2 => sub {
							# code for app Test2 here
							# see client_start below
						},
					},
				});
			},
			client_start => sub {
				my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
				# the label object is kept in the heap to use it on callbacks
				return Window(
					VBox(FILL, $heap->{label} = Label(value => 'select item from list'),
						ListBox(FILL,
							(map { ListItem(label => "item #$_") } 1..10),
							Select => $session->callback('listbox_select')
						),
					),
				);
			},
			listbox_select => sub {
				my ($kernel, $heap, $session, $event) = (@_[KERNEL, HEAP, SESSION], $_[ARG1]->[0]);
				print "[".$event->{session}."] picked #".($event->{selectedIndex}+1)."\n";
				# example of doing 2 or more things in request
				# set the label text and make it change colors
				my @colors = ('red','blue','green','yellow','white','black');
				return $heap->{label}->value("you selected #".($event->{selectedIndex}+1)).
					$heap->{label}->style('color:'.$colors[(int(rand($#colors)))]);		
			},
		},
	);

	$poe_kernel->run();

=head1 DESCRIPTION

POE::Component::XUL allows you to use poe callbacks in your XUL::Node apps.
In its current state, XUL::Node doesn't give you a way to use POE easily in
your apps, but with this component you will have the control you need.

=head1 AUTHOR

David Davis, E<lt>xantus@cpan.orgE<gt>

=head1 THANKS

Rocco Caputo, for pushing me. :)

=head1 SEE ALSO

perl(1), L<XUL::Node>, L<XUL::Node::Application>.

=cut

__END__
	
	# TODO fix this
	
	opts {	# options passed to POE::XUL::Session objects
		disable_others => 1, # disable use of other apps in the root
	},
