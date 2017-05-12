#!/usr/bin/perl -w

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use lib qw( ../blib ../lib );

use strict;
use Getopt::Long;
use Pod::Usage;
use POE qw( Component::XUL );
use XUL::Node;
use XUL::Node::Application;

use base 'XUL::Node::Application';

my $PORT = 8077;
my $ROOT = '/usr/local/xul-node';
my $HELP = 0;

GetOptions( 
	'port=i' => \$PORT,
	'root=s' => \$ROOT,
	'help'   => \$HELP,
) or pod2usage(2); 

pod2usage(1) if $HELP;

$|++;

	POE::Session->create(
		args => [ $PORT, $ROOT ],
		inline_states => {
			_start => sub {
				my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

				POE::Component::XUL->spawn({
					port => $_[ARG0],
					root => $_[ARG1],
					apps => {
						# a callback
						Test => $session->callback("client_start"),
					},
					opts => {
						disable_others => 1, # disable use of other apps in the root
					},
				});

				print "Browse to http://localhost:$_[ARG0]/start.xul?Test\n";
			},
			client_start => sub {
				my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

				my $sess = $_[ARG1]->[1]->{session};

				print "[$sess] client started\n";
				my @request = splice(@_,ARG0);

			#	require Data::Dumper;
			#	print Data::Dumper->Dump([\@request]);
				
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
				
			#	my @request = splice(@_,ARG0);
			#	require Data::Dumper;
			#	print Data::Dumper->Dump([\@request]);
				
				my $sess = $event->{session};
				
				print "[$sess] user picked #".($event->{selectedIndex}+1)."\n";
				# example of doing 2 or more things in request
				# set the label text and make it change colors
				my @colors = ('red','blue','green','yellow','white','black');
				return $heap->{label}->value("you selected #".($event->{selectedIndex}+1)).
					$heap->{label}->style('color:'.$colors[(int(rand($#colors)))]);		
			},
		},
	);

$poe_kernel->run();

exit 0;

=head1 NAME

poe-xul.pl - start XUL-Node HTTP server with POE session handling

=head1 SYNOPSIS

poe-xul.pl [options]

Options:

  --port   Port (default is 8077)
  --root   Document root (default is /usr/local/xul-node)
  --help   Show this message

=cut
1;

