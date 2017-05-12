# -*- perl -*-
# $Id: RobotUA.pm,v 1.12 2004/02/10 15:19:19 langhein Exp $
# derived from: RobotUA.pm,v 1.18 2000/04/09 11:21:11 gisle Exp $


package LWP::Parallel::RobotUA;

use LWP::Parallel::UserAgent qw(:CALLBACK);
require LWP::RobotUA;
@ISA = qw(LWP::Parallel::UserAgent LWP::RobotUA Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/);

@EXPORT = qw(); 
# callback commands
@EXPORT_OK = @LWP::Parallel::UserAgent::EXPORT_OK;
%EXPORT_TAGS = %LWP::Parallel::UserAgent::EXPORT_TAGS;

use LWP::Debug ();
require HTTP::Request;
require HTTP::Response;
use HTTP::Date qw(time2str);
use Carp();

use strict;

=head1 NAME

LWP::Parallel::RobotUA - A class for Parallel Web Robots

=head1 SYNOPSIS

  require LWP::Parallel::RobotUA;
  $ua = new LWP::Parallel::RobotUA 'my-robot/0.1', 'me@foo.com';
  $ua->delay(0.5);  # in minutes!
  ...
  # just use it just like a normal LWP::Parallel::UserAgent
  $ua->register ($request, \&callback, 4096); # or
  $ua->wait ( $timeout ); 

=head1 DESCRIPTION

This class implements a user agent that is suitable for robot
applications.  Robots should be nice to the servers they visit.  They
should consult the F</robots.txt> file to ensure that they are welcomed
and they should not make requests too frequently.

But, before you consider writing a robot take a look at
<URL:http://info.webcrawler.com/mak/projects/robots/robots.html>.

When you use a I<LWP::Parallel::RobotUA> as your user agent, then you do not
really have to think about these things yourself.  Just send requests
as you do when you are using a normal I<LWP::Parallel::UserAgent> and this
special agent will make sure you are nice.

=head1 METHODS

The LWP::Parallel::RobotUA is a sub-class of LWP::Parallel::UserAgent
and LWP::RobotUA and implements a mix of their methods.

In addition to LWP::Parallel::UserAgent, these methods are provided:

=cut

=head2 $ua = LWP::Parallel::RobotUA->new($agent_name, $from, [$rules])

Your robot's name and the mail address of the human responsible for
the robot (i.e. you) are required by the constructor.

Optionally it allows you to specify the I<WWW::RobotRules> object to
use. (See L<WWW::RobotRules::AnyDBM_File> for persistent caching of
robot rules in a local file)

=cut

#' fix emacs syntax parser

sub new {
    my($class,$name,$from,$rules) = @_;

    Carp::croak('LWP::Parallel::RobotUA name required') unless $name;
    Carp::croak('LWP::Parallel::RobotUA from address required') unless $from;

    my $self = new LWP::Parallel::UserAgent;
    $self = bless $self, $class;

    $self->{'delay'}     = 1;   # minutes again (used to be seconds)!!
    $self->{'use_sleep'} = 1;
    $self->{'agent'} = $name;
    $self->{'from'}  = $from;
    # current netloc's we're checking:
    $self->{'checking'} = {};

    if ($rules) {
	$rules->agent($name);
	 $self->{'rules'} = $rules;
    } else {
	$self->{'rules'} = new WWW::RobotRules $name;
    }

    $self;
}

=head2 $ua->delay([$minutes])

Set/Get the minimum delay between requests to the same server.  The
default is 1 minute.

Note: Previous versions of LWP Parallel-Robot used I<Seconds> instead of 
      I<Minutes>! This is now compatible with LWP Robot.

=cut

# reuse LWP::RobotUA::delay here (just needed to clarify usage)

=head2 $ua->host_wait($netloc)

Returns the number of seconds you must wait before you can make a new
request to this server. This method keeps track of all of the robots
connection, and enforces the delay constraint specified via the delay
method above for each server individually.

Note: Although it says 'host', it really means 'netloc/server',
i.e. it differentiates between individual servers running on different
ports, even though they might be on the same machine ('host'). This
function is mostly used internally, where RobotUA calls it to find out
when to send the next request to a certain server.

=cut

sub host_wait
{
    my($self, $netloc) = @_;
    return undef unless defined $netloc;
    my $last = $self->{'rules'}->last_visit($netloc);
    if ($last) {
	my $wait = int($self->{'delay'} * 60 - (time - $last));
	$wait = 0 if $wait < 0;
	return $wait;
    }
    return 0;
}

=head2 $ua->as_string

Returns a string that describes the state of the UA.
Mainly useful for debugging.

=cut

sub as_string
{
    my $self = shift;
    my @s;
    push(@s, "Robot: $self->{'agent'} operated by $self->{'from'}  [$self]");
    push(@s, "    Minimum delay: " . int($self->{'delay'}) . " minutes");
    push(@s, "    Rules = $self->{'rules'}");
    join("\n", @s, '');
}


#
# private methods (reimplementations of LWP::Parallel::UserAgent methods)
#

# this method now first checks the robot rules. It will try to
# download the robots.txt file before proceeding with any more
# requests to an unvisited site.
# It will also observe the delay specified in our ->delay method
sub _make_connections_in_order {
    my $self = shift;
    LWP::Debug::trace('()');

    my($failed_connections, $remember_failures, $ordpend_connections, $rules) =
      @{$self}{qw(failed_connections remember_failures 
		  ordpend_connections rules)};

    my ($entry, @queue, %busy);
    # get first entry from pending connections
    while ( $entry = shift @$ordpend_connections ) {

	my $request = $entry->request;
	my $netloc  = eval { local $SIG{__DIE__}; $request->url->host_port; };

        if ( $remember_failures and $failed_connections->{$netloc} ) {
	    my $response = $entry->response;
	    $response->code (&HTTP::Status::RC_INTERNAL_SERVER_ERROR);
	    $response->message ("Server unavailable");
	    # simulate immediate response from server
	    $self->on_failure ($entry->request, $response, $entry);
	    next;
	  }

	push (@queue, $entry), next  if $busy{$netloc};

	# Do we try to access a new server?
	my $allowed = $rules->allowed($request->url);
	# PS: pending Robots.txt requests are always allowed! (hopefully)

	if ($allowed < 0) {
	  LWP::Debug::debug("Host not visited before, or robots.".
			    "txt expired: ($allowed) ".$request->url);
	    my $checking = $self->_checking_robots_txt ($netloc);
	    # let's see if we're already busy checkin' this host
	    if ( $checking > 0 ) {
	      LWP::Debug::debug("Already busy checking here. Request queued");
		push (@queue, $entry);
	    } elsif ( $checking < 0 ) {
		# We already checked here. Seems the robots.txt
		# expired afterall. Pretend we're allowed
	      LWP::Debug::debug("Checked this host before. robots.txt".
				" expired. Assuming access ok");
		$allowed = 1; 
	    } else { 
		# fetch "robots.txt"
		my $robot_url = $request->url->clone;
		$robot_url->path("robots.txt");
		$robot_url->query(undef);
	      LWP::Debug::debug("Requesting $robot_url");

		# make access to robot.txt legal since this might become
		# a recursive call (in case we lack bandwith to connect
		# immediately) 
		$rules->parse($robot_url, ""); 

		my $robot_req = new HTTP::Request 'GET', $robot_url;
		my $response = HTTP::Response->new(0, '<empty response>'); 
		$response->request($robot_req);

		my $robot_entry = new LWP::Parallel::UserAgent::Entry { 
		    request  	=> $robot_req, 
		    response 	=> $response, 
		    size	=> 8192, 
		    redirect_ok => 0,
		    arg 	=> sub {
			# callback function (closure)
			my ($content, $robot_res, $protocol) = @_;
                        my $netloc = eval { local $SIG{__DIE__}; 
                                            $request->url->host_port; };
			# unset flag - we're done checking
			$self->_checking_robots_txt ($netloc, -1);
		        $rules->visit($netloc);

			my $fresh_until = $robot_res->fresh_until;
			if ($robot_res->is_success) {
		          my $c = $robot_res->content;
	                  if ($robot_res->content_type =~ m,^text/, && 
			      $c =~ /Disallow/) {
			    LWP::Debug::debug("Parsing robot rules for ". 
			  		      $netloc);
		            $rules->parse($robot_url, $c, $fresh_until);
	                  }
	                  else {
		            LWP::Debug::debug("Ignoring robots.txt for ".
				              $netloc);
		            $rules->parse($robot_url, "", $fresh_until);
	                  }
			} else {
			  LWP::Debug::debug("No robots.txt file found at " . 
					    $netloc);
			    $rules->parse($robot_url, "", $fresh_until);
			}
		    },
		};
		# immediately try to connect (if bandwith available)
		push (@queue, $robot_entry), $busy{$netloc}++  
		    unless  $self->_check_bandwith($robot_entry);
		# mark this host as being checked
		$self->_checking_robots_txt ($netloc, 1);
		# don't forget to queue the entry that triggered this request
		push (@queue, $entry);
	    }
	} 

	unless ($allowed) {
	    # we're not allowed to connect to this host
	    my $res = new HTTP::Response
		&HTTP::Status::RC_FORBIDDEN, 'Forbidden by robots.txt';
	    $entry->response($res);
	    # silently drop entry here from ordpend_connections
	} elsif ($allowed > 0) {
	    # check robot-wait information to see if we have to wait
	    my $wait = $self->host_wait($netloc);
	    
	    # if so, push on @queue queue
	    if ($wait) {
	      LWP::Debug::trace("Must wait $wait more seconds (sleep is ".
	        ($self->{'use_sleep'} ? 'on' : 'off') . ")");
	      if ($self->{'use_sleep'}) {
	        # well, we don't really use sleep, but lets emulate
		# the standard LWP behavior as closely as possible...
		push (@queue, $entry);
		
		# now we also have to raise a red flag for all
		# remaining entries at this particular
		# host. Otherwise we might block the first x
		# requests to this server, but have finally waited
		# long enough when the x+1 request comes off the
		# queue, and then we would connect to the x+1
		# request before any of the first x requests
		# (which is not what we want!)
		$busy{$netloc}++;
              } else {
	        LWP::Debug::debug("'use_sleep' disabled, generating response");
	        my $res = new HTTP::Response
	          &HTTP::Status::RC_SERVICE_UNAVAILABLE, 'Please, slow down';
	        $res->header('Retry-After', time2str(time + $wait));
	        $entry->response($res);
	      }
	    } else { # check bandwith
		unless ( $self->_check_bandwith($entry) ) {
		    # if _check_bandwith returns a value, it means that
		    # no bandwith is available: push $entry on queue
		    push (@queue, $entry);
		    $busy{$netloc}++;
		} else {
		    $rules->visit($netloc);
		}
	    }
	}
    }
    # the un-connected entries form the new stack
    $self->{'ordpend_connections'} = \@queue;
}

# this method now first checks the robot rules. It will try to
# download the robots.txt file before proceeding with any more
# requests to an unvisited site.
# It will also observe the delay specified in our ->delay method
sub _make_connections_unordered {
    my $self = shift;
    LWP::Debug::trace('()');
		      
    my($pending_connections, $failed_connections, $remember_failures, $rules) =
      @{$self}{qw(pending_connections failed_connections 
		  remember_failures rules)};

    my ($entry, $queue, $netloc);

    my %delete;
    # check every host in sequence (use 'each' for better performance)
  SERVER:
    while (($netloc, $queue) = each %$pending_connections) {
	
        # since we shouldn't alter the hash itself while iterating through it
        # via 'each', we'll make a note here for each netloc that has an
        # empty queue, so that we can explicitly delete them afterwards:
        unless (@$queue) {
	  LWP::Debug::debug("Marking empty queue for '$netloc' for deletion");
	    $delete{$netloc}++;
	    next SERVER;
        }
	
        # check if we already tried to connect to this location, and failed
        if ( $remember_failures and $failed_connections->{$netloc} ) {
	  LWP::Debug::debug("Removing all ". scalar @$queue . 
			    " entries for unreachable host '$netloc'");
	    while ( $entry = shift @$queue ) {
		my $response = $entry->response;
		$response->code (&HTTP::Status::RC_INTERNAL_SERVER_ERROR);
		$response->message ("Server unavailable");
		# simulate immediate response from server
		$self->on_failure ($entry->request, $response, $entry);
	    }
	    # make sure we delete this netloc-entry later
	  LWP::Debug::debug("Marking empty queue for '$netloc' for deletion");
	    $delete{$netloc}++;
	    next SERVER;
        }
	
        # get first entry from pending connections at this host
        while ( $entry = shift @$queue ) {
	    my $request = $entry->request;
	    
	    # Do we try to access a new server?
	    my $allowed = $rules->allowed($request->url);
	    # PS: pending Robots.txt requests are always allowed! (hopefully)
	    
	    if ($allowed < 0) {
	      LWP::Debug::debug("Host not visited before, or robots.".
				"txt expired: ".$request->url);
		my $checking = $self->_checking_robots_txt 
		    ($request->url->host_port);
		# let's see if we're already busy checkin' this host
		if ( $checking > 0 ) {
		    # if so, don't register yet another robots.txt request!
		  LWP::Debug::debug("Already busy checking here. ".
				    "Request queued");
		    unshift (@$queue, $entry);
		    next SERVER;
		} elsif ( $checking < 0 ) {
		    # We already checked here. Seems the robots.txt
		    # expired afterall. Pretend we're allowed
		  LWP::Debug::debug("Checked this host before. ".
				    "robots.txt expired. Assuming access ok");
		    $allowed = 1; 
		} else { 
		    # queue the entry that triggered this request
		    unshift (@$queue, $entry);
		    # fetch "robots.txt" (i.e. create & issue robot request)
		    my $robot_url = $request->url->clone;
		    $robot_url->path("robots.txt");
		    $robot_url->query(undef);
		  LWP::Debug::debug("Requesting $robot_url");
		    
		    # make access to robot.txt legal since this might become
		    # a recursive call (in case we lack bandwith to connect
		    # immediately) 
		    $rules->parse($robot_url, ""); 
		    
		    my $robot_req = new HTTP::Request 'GET', $robot_url;
		    my $response = HTTP::Response->new(0, '<empty response>'); 
		    $response->request($robot_req);
		    
		    my $robot_entry = new LWP::Parallel::UserAgent::Entry { 
			request  	=> $robot_req, 
			response 	=> $response, 
			size	=> 8192, 
			redirect_ok => 0,
			arg 	=> sub {
			    # callback function (closure)
			    my ($content, $robot_res, $protocol) = @_;
                            my $netloc = eval { local $SIG{__DIE__}; 
                                                $request->url->host_port; };
			    # unset flag - we're done checking
			    $self->_checking_robots_txt ($netloc, -1);
		            $rules->visit($netloc);
			    
			    my $fresh_until = $robot_res->fresh_until;
			    if ($robot_res->is_success) {
			      my $c = $content; # thanks to Vlad Ciubotariu
	                      if ($robot_res->content_type =~ m,^text/, && 
			          $c =~ /Disallow/) {
			        LWP::Debug::debug("Parsing robot rules for ". 
				  		  $netloc);
		                $rules->parse($robot_url, $c, $fresh_until);
	                      }
	                      else {
		                LWP::Debug::debug("Ignoring robots.txt for ".
				                  $netloc);
		                $rules->parse($robot_url, "", $fresh_until);
	                      }
			    } else {
			      LWP::Debug::debug("No robots.txt file found at ".
						$netloc);
				$rules->parse($robot_url, "", $fresh_until);
			    }
			},
		    };
		    # mark this host as being checked
		    $self->_checking_robots_txt ($request->url->host_port, 1);
		    # immediately try to connect (if bandwith available)
		    unless ( $self->_check_bandwith($robot_entry) ) {
			unshift (@$queue, $robot_entry);
		    }
		    # we can move to the next server either way, since
		    # we'll have to wait for the results of the
		    # robot.txt request anyways
		    next SERVER;
		}
	    } 
	    
	    unless ($allowed) {
		# we're not allowed to connect to this host
		my $res = new HTTP::Response
		    &HTTP::Status::RC_FORBIDDEN, 'Forbidden by robots.txt';
		$entry->response($res);
		# silently drop entry here from pending_connections
	    } elsif ($allowed > 0) {
		my $netloc = eval { local $SIG{__DIE__}; 
                                    $request->url->host_port; }; # LWP 5.60
		
		# check robot-wait information to see if we have to wait
		my $wait = $self->host_wait($netloc);
		
		# if so, push on @$queue queue
		if ($wait) {
	          LWP::Debug::trace("Must wait $wait more seconds (sleep is ".
	            ($self->{'use_sleep'} ? 'on' : 'off') . ")");
	          if ($self->{'use_sleep'}) {
		    unshift (@$queue, $entry);
		    next SERVER;
		  } else {
                    LWP::Debug::debug("'use_sleep' disabled");
	            my $res = new HTTP::Response
	             &HTTP::Status::RC_SERVICE_UNAVAILABLE, 'Please, slow down';
	            $res->header('Retry-After', time2str(time + $wait));
	            $entry->response($res);
	          }
		} else { # check bandwith
		    unless ( $self->_check_bandwith($entry) ) {
			# if _check_bandwith returns undef, it means that
			# no bandwith is available: push $entry on queue
		      LWP::Debug::debug("Not enough bandwidth for ".
					"request to $netloc");
			unshift (@$queue, $entry);
			next SERVER;
		    } else {
			# make sure we update the time of our last
			# visit to this site properly
			$rules->visit($netloc);
		    }
		}
	    }
	  LWP::Debug::debug("Queue for $netloc contains ". 
			    scalar @$queue . " pending connections");
	    $delete{$netloc}++ unless scalar @$queue;
	}
    }
    # clean up: (we do this outside of the loop since we're not
    # suppose to alter an associative array (hash) while iterating
    # through it using 'each')
    foreach (keys %delete) { 
      LWP::Debug::debug("Deleting queue for '$_'");
	delete $self->{'pending_connections'}->{$_} 
    }
}


# request-slots available at host (checks for robots lock)
sub _req_available { 
    my ( $self, $url ) = @_;
    # check if blocked
    if ( $self->_checking_robots_txt($url->host_port) ) {
	return 0;
    } else {
	# else use superclass method
	$self->SUPER::_req_available($url);
    }
};


#
# new private methods
#

# sets/get robot lock for given host.
sub _checking_robots_txt {
    my ($self, $netloc, $lock) = @_;
    local $^W = 0; # prevent warnings here;

    $self->{'checking'}->{$netloc} = 0
      unless defined ($self->{'checking'}->{$netloc});

    if (defined $lock) {
	$self->{'checking'}->{$netloc} = $lock;
    } else {
	$self->{'checking'}->{$netloc};
    }
}

=head1 SEE ALSO

L<LWP::Parallel::UserAgent>, L<LWP::RobotUA>, L<WWW::RobotRules>

=head1 COPYRIGHT

Copyright 1997-2004 Marc Langheinrich E<lt>marclang@cpan.org>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;

