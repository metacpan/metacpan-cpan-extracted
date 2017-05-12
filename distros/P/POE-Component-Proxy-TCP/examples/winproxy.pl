#!/usr/bin/perl
# Simple Tk windows proxy client built on POE::Component::Proxy::TCP.

# Andrew Purshottam Oct 2003

# To do:
# - catch interrupt and recovery gracefully from shutdowns
# - recover from remote server and client crashes
# - (speculative) support multiple connections by generating extra 
#   request/response window pairs (maybe side by side, and with
#   kill checkbox for the pair. This might be easy or impossible dependingon what
#   toolkit gives.)
# - label output from different connections somehow.

use warnings;
use strict;
use diagnostics;
use Getopt::Std;
use Tk;
use Tk::ProgressBar;    
sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use POE;
use POE::Filter::Stream;
use POE::Filter::Line;
use POE::Component::Proxy::TCP;
use Data::Dumper;
use POSIX;

$|++;  

# Command line arg processing
my $debug_flag = 1;             
my $remote_server_host = "localhost";
my $remote_server_port = 80;
my $local_server_port = 8080;
my %argv;
getopt("dlrshw", \%argv);
$debug_flag = $argv{'d'} unless !exists($argv{'d'});
$remote_server_port = $argv{'r'} unless !exists($argv{'r'});
$local_server_port = $argv{'l'} unless !exists($argv{'l'});
$remote_server_host = $argv{'s'} unless !exists($argv{'s'});

# Create UI session which when started brings up the main frame window
# and listens for events to put text in request and response view 
#scrolling text boxes.
my $ui_session = POE::Session->create
  ( inline_states =>
    { _start => \&ui_start,
      ev_post_string => \&ui_post_string_to_widget,
      ev_clear => \&ui_clear,
    }
  );

# Server side of proxy, clients connect to this, and this in turn
# connects to a remote server.
my $proxy_component = POE::Component::Proxy::TCP->new
  ( Alias => "ProxyServerSessionAlias",
    Port               => $local_server_port,
    OrigPort           => $remote_server_port,
    OrigAddress        => $remote_server_host,

    DataFromClient    => sub {
      my $s = shift; 
      $poe_kernel->post($ui_session, "ev_post_string", 
			$s, "to_orig_server_text_widget");  
      print "**from client $s\n"; 
      
    },

    # In addition to passing data from original server to client,
    # also show the data in a text window.
    DataFromServer    => sub {
      my $s = shift; 
      $poe_kernel->post($ui_session, "ev_post_string", 
			$s, "from_orig_server_text_widget");  
      print "**from server $s\n"; 
    },
    #ClientFilter       =>POE::Filter::Line->new(OutputLiteral => "\n\r")
  );


# 
# Event loop.
#

# Run the program until it is exited.
$poe_kernel->run();
exit 0;

# 
# Event handlers.
#

# Set up main Tk window
sub ui_start {
  my ( $kernel, $session, $heap ) = @_[ KERNEL, SESSION, HEAP ];

  $poe_main_window->Label( -text => "HTTP Progress Monitor",
			   -justify => 'left',
			 )->pack(-expand => 1, -fill => 'x');

  $poe_main_window->Button
    ( -text => "Clear",
      -command => $session->postback("ev_clear")
    )->pack;

  $poe_main_window->Label( -text => "Requests to Server." )->pack;
  my $to_orig_server_text_widget = $heap->{to_orig_server_text_widget} 
    = $poe_main_window->Scrolled(qw/Text -height 6 -scrollbars e/ ); 
  $to_orig_server_text_widget->insert('end', "\n\n\n");
  $to_orig_server_text_widget->pack(-side => 'top', -fill => 'both', -expand => 1); 
  
  $poe_main_window->Label( -text => "Replies from Server." )->pack;
  my $from_orig_server_text_widget = $heap->{from_orig_server_text_widget} 
    = $poe_main_window->Scrolled(qw/Text -height 6 -scrollbars e/ ); 
  $from_orig_server_text_widget->insert('end', "\n\n\n");
  $from_orig_server_text_widget->pack(-side => 'top', -fill => 'both', -expand => 1); 
}

# Handle the "ev_post_string" event by appendiong sytring to appropriate 
# widget window.
sub ui_post_string_to_widget {
  my ( $kernel, $heap, $string, $widget_name ) = @_[ KERNEL, HEAP, ARG0, ARG1 ];
  if (defined($heap->{$widget_name})) {
    append_line_to_widget($string, $heap->{$widget_name});
 
  }
}

# XXX probably this should get squished in above.
sub append_line_to_widget {
  my $line = shift;
  my $widget = shift;
  $widget->insert('end', $line . "\n"); 
  $widget->yview('end');
}

# Clear text windows and progress meter.
sub ui_clear {
  my ( $kernel, $session, $heap ) = @_[ KERNEL, SESSION, HEAP ];
  my $from_orig_server_text_widget = $heap->{from_orig_server_text_widget};
  $from_orig_server_text_widget->delete('1.0', 'end');
  my $to_orig_server_text_widget = $heap->{to_orig_server_text_widget};
  $to_orig_server_text_widget->delete('1.0', 'end');
}
