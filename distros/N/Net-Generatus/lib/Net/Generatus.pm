package Net::Generatus;

use warnings;
use strict;
use base qw/Net/;
use URI::Escape;
use LWP::UserAgent;
#use Carp;

our $VERSION = '0.40';
#http://search.twitter.com/search.json?q=<query>

sub Status {
    my $self = shift;
	#$self->set_user_agent("Net::Generatus-$VERSION (PERL)");

    my $params = shift || {};

    #grab the params
    my $gender = $params->{'gender'} || 'F';
    my $name = $params->{'name'} || '';
	my $tag = $params->{'tag'} || '';
    
    #build URL
    my $url = 'http://www.generatus.com/AJAXStatus.asp?';

    $url .= 'G=' . URI::Escape::uri_escape($gender); 
    $url .= '&N=' . URI::Escape::uri_escape($name);# if ($name);
    $url .= '&K=' . URI::Escape::uri_escape($tag); # if ($tag);

    #do request
	my $ua = LWP::UserAgent->new();
    #my $req = $self->{ua}->get($url);
	my $response = $ua->post($url); 
	
	my $raw;	
	if ($response->is_success) {
    	 $raw = $response->decoded_content;  # or whatever
 	}
 	else {
     	  die $response->status_line;
 	}

	my @bits = split(/\#\#\#/, $raw);
	my $status = $bits[0];
	chomp $status;	
	return $status;	
}

# sub set_user_agent {
# 	my $self = shift;
# 	my $agent = shift;
# 	$self->{ua}->agent($agent);
# }

1;

=head1 NAME

Net::Generatus - Get random status message from generatus.com

=head1 SYNOPSYS

  use Net::Generatus;
  #get an interesting yet rude status message
  $status = Net::Generatus::Status({tag => 'insults'});


    
=head1 DESCRIPTION

	Pulls a random and potentially witty status message from generatus.com which could be used to update twitter or one of it's clones

=head1 METHODS

=head2 Status

params 
  tag - (optional) select the status message from message with this tag 
  name - (your name, optional, will be prepended to status message)
  gender - either M or F (defaults to F)
returns: string

=head2 EXAMPLE

  #get a insults status message
  $status = Net::Generatus::Status({tag => 'insults'});
 
  $status = Net::Generatus::Status({gender => 'M'});

=head1 AUTHOR

Brenda Wallace <shiny@cpan.org>

(based on Net::Twitter::Search and Net::Twitter::Diff)

=cut
