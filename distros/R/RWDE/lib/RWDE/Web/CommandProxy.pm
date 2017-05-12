package RWDE::Web::CommandProxy;

use strict;
use warnings;

# Proxy object for getting the specific functionality of a particular object

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 550 $ =~ /(\d+)/;

use Error qw(:try);

use RWDE::AbstractFactory;
use RWDE::Configuration;
use RWDE::Exceptions;
use RWDE::Web::Helper;
use RWDE::Web::TemplateAdapter;

use base qw(RWDE::Proxy);

sub execute {
  my ($self, $params) = @_;

  my $req = $$params{req}
    or throw RWDE::DevelException({ info => 'No request to process specified' });

  # create auxiliary object to facilitate passing of the data between layers
  my $helper = new RWDE::Web::Helper;

  # The commands might need the request object for logging/redirection purposes
  $helper->set_stash({ req => $req });

  # put elements in the helper for easy access by Command layer
  my $formdata = $req->get_formdata();
  $helper->set_stash({ formdata => $formdata });

  # get the params from the request that will decide on method invocation and params
  # the uri (the part after the host name) will determine the class called
  my $uri = $req->get_uri();

  $helper->set_stash({ uri => $uri });

  # store the current state of the https connection in the stash
  if ($req->is_https()) {
    $helper->set_stash({ https              => 1 });
    $helper->set_stash({ FullServiceAddress => RWDE::Configuration->ServiceSSLAddress });
  }
  else {
    $helper->set_stash({ FullServiceAddress => RWDE::Configuration->ServiceAddress });
  }

  # Placing the Service configuration hash for Templates to access. This leaves a few redundant
  # fields that are injected manually now, will cleanup as the rest is refactored as the templates
  # will have to use the format Configuration.Debug rather then Debug
  $helper->set_stash({ Configuration => RWDE::Configuration->get_instance() });

  #every possible page controller and template should be able to identify which host they are running on
  #and if they are currently in debug mode - we shouldn't have to do this for each default controller
  $helper->set_stash({ Debug       => RWDE::Configuration->Debug });
  $helper->set_stash({ ServerName  => $req->get_req->server_name });
  $helper->set_stash({ ServiceHost => RWDE::Configuration->ServiceHost });

  # The template needs to insert ServiceAddress for SSL protected forms
  $helper->set_stash({ ServiceAddress    => RWDE::Configuration->ServiceAddress });
  $helper->set_stash({ ServiceSSLAddress => RWDE::Configuration->ServiceSSLAddress });

  my $class = $req->get_class({ helper => $helper });

  try {
    my $command = RWDE::AbstractFactory->instantiate({ class => $class, helper => $helper });

    if (not defined $req->{forward}) {
      $command->execute($formdata);
    }

    if (not defined $req->{header}) {
      $req->print_header({ pagetype => $helper->get_pagetype()});
    }

    # we have to check again for forward, as $command->execute might have issued a forward
    if (not defined $req->{forward}) {
      RWDE::Web::TemplateAdapter->render({ helper => $helper });
    }

  }

  catch Error with {
    my $ex = shift;

    warn $ex;

    $helper->set_stash({ info => $ex });

    # Set the appropriate error page (devel or customer)
    $self->invoke({ class => 'Command::default', function => 'execute', helper => $helper });

    RWDE::PostMaster->send_report_message(
      {
        info     => $ex,
        record   => $req->get_record() . "\nReferrer: " . $req->get_referer(),    #both the request and the referrer
        formdata => $formdata,
        uri      => $uri,
        class    => $class,
        session  => $helper->get_session,
      }
    );

    if (not defined $req->{header}) {
      $req->print_header({ pagetype => $helper->get_pagetype()});
    }

    RWDE::Web::TemplateAdapter->render({ helper => $helper });
  };

  return ();
}

1;
