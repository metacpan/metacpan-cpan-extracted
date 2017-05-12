package PerlGuard::Agent::Frameworks::CGIApplication;
use base 'Exporter';

use PerlGuard::Agent;

BEGIN {
  $PerlGuard::Agent::Frameworks::CGIApplication::VERSION = '1.00';
}

@EXPORT = qw(
  perlguard_config
  perlguard_agent
);

# register a callback to the standard CGI::Application hooks
#   one of 'init', 'prerun', 'postrun', 'teardown' or 'load_tmpl'

sub perlguard_config {
  my $self = shift;
  my $config = shift;

  $self->{'PerlGuard::Agent::Frameworks::CGIApplication::perlguard_config'} = $config;
}

sub perlguard_agent {
  my $self = shift;

  if (not defined($self->{'PerlGuard::Agent::Frameworks::CGIApplication::perlguard_agent'})) {
    my $agent = PerlGuard::Agent->new( $self->{'PerlGuard::Agent::Frameworks::CGIApplication::perlguard_config'} );

    $agent->detect_monitors();
    $agent->start_monitors();

    #warn "Creating fresh perlguard agent";

    $self->{'PerlGuard::Agent::Frameworks::CGIApplication::perlguard_agent'} = $agent;
  }

  return $self->{'PerlGuard::Agent::Frameworks::CGIApplication::perlguard_agent'};
}

sub import {
  my $c = scalar(caller);

  $c->add_callback('init', sub {

  });

  $c->add_callback('prerun', sub {
    my $controller_instance = shift;

    #warn "Creating new profile";
    $controller_instance->{'PerlGuard::Profile'} = &perlguard_agent($controller_instance)->create_new_profile();
    $controller_instance->{'PerlGuard::Profile'}->start_recording();
    $PerlGuard::Agent::CURRENT_PROFILE_UUID = $controller_instance->{'PerlGuard::Profile'}->uuid();
  });

  $c->add_callback('postrun', sub {
    my $controller_instance = shift;
    my $profile = $controller_instance->{'PerlGuard::Profile'};

    # my $handle;
    # open ($handle,'>>','/tmp/cgiapp') or die("Cant open /tmp/cgiapp");
   
    # print $handle "\n\n\n==============\n\n\n";


    # use Data::Dumper;
    # print $handle Dumper $controller_instance->query;
    # print $handle "\n" . $controller_instance->query->self_url;
    # print $handle "\n" . $controller_instance->query->request_method;
    # print $handle "\n" . ref($controller_instance);
    # print $handle "\n" . $controller_instance->get_current_runmode;


    $profile->url( $controller_instance->query->self_url );
    $profile->http_method( $controller_instance->query->request_method );
    $profile->controller( ref($controller_instance) );

    #For paul lets update the controller action to include the HTTP method
    $profile->controller_action( $controller_instance->get_current_runmode . "_" . uc($controller_instance->query->request_method) );


    if( my $cross_application_tracing_id = $controller_instance->query->http("X-PerlGuard-Auto-Track") ) {
      $profile->cross_application_tracing_id($cross_application_tracing_id);
    }

    $profile->finish_recording();
    $controller_instance->{'PerlGuard::Profile'} = undef;
    $profile->save;
  });

  $c->add_callback('teardown', sub {

  });    

  goto &Exporter::import
}

