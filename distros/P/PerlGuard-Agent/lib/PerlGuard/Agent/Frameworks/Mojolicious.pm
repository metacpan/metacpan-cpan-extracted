package PerlGuard::Agent::Frameworks::Mojolicious;
#use Moo;
use PerlGuard::Agent;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::IOLoop;


BEGIN {
  $PerlGuard::Agent::Frameworks::Mojolicious::VERSION = '1.00';
}

sub register {
    my ($self, $app, $args) = @_;
    $args ||= {};

    my $agent = PerlGuard::Agent->new($args);

    $app->helper(perlguard_agent => sub {
        return $agent;
    });


    $app->hook(after_build_tx => sub {
      my $tx = shift;
      
        unless($tx->{'PerlGuard::Profile'}) {
          my $profile = $agent->create_new_profile();

          $tx->{'PerlGuard::Profile'} //= $profile;

          $profile->start_recording;
        }
        else {
          warn "I think I already have a profile on this TX even though its just been built" if $ENV{'PERLGUARD_AGENT_DEBUG'}
        }      
    });


    $app->hook(after_dispatch => sub {
      my $c = shift;

      return if ($c->stash->{'mojo.static'});

      my $profile = $c->tx->{'PerlGuard::Profile'};
      $profile->finish_recording();
      $profile->http_code( $c->tx->res->code );
      $c->tx->{'PerlGuard::Profile'} = undef;

      #This does not do what I think it does
      if(Mojo::IOLoop->is_running()) {
        Mojo::IOLoop->timer(1 => sub {
          my $loop = shift;
          
          $profile->save;
        });
      }
      else {
        $profile->save;
      }
    });


    $app->hook(before_routes => sub {
      my $c = shift;

      my $stash = $c->stash;
      unless ($stash->{'mojo.static'}) {

        unless($c->tx->{'PerlGuard::Profile'}) {

          warn "In before_routes we didn't have a profile on the transaction already so we had to make it";
          my $profile = $agent->create_new_profile();
          $c->tx->{'PerlGuard::Profile'} //= $profile;

          $profile->start_recording;
        }
        else {
          $c->tx->{'PerlGuard::Profile'}->http_code( $c->tx->res->code );
          $c->tx->{'PerlGuard::Profile'}->url( $c->tx->req->url );
          #$c->stash('PerlGuard::Profile', $c->tx->{'PerlGuard::Profile'});
        }
      }

    });

    $app->hook(around_dispatch => sub {
      my ($next, $c) = @_;

      #$c->stash->{'PerlGuard::Profile'} = $c->tx->{'PerlGuard::Profile'};

      do {
        if($c->tx->{'PerlGuard::Profile'}) {
                local $PerlGuard::Agent::CURRENT_PROFILE_UUID = $c->tx->{'PerlGuard::Profile'}->uuid() unless $c->stash->{'mojo.static'};
                $next->();
        }
        else {
                warn "Perlguard profile was not defined at this point";
                $next->();
        }
      };

    });

    $app->hook(around_action => sub {
      my ($next, $c, $action, $last) = @_;

      unless($c->stash->{'mojo.static'}) {
        my $profile = $c->tx->{'PerlGuard::Profile'};

        unless($profile) {
          #warn "PerlGuard profile was not defined when we expected it to be";
        }
        else {
          $profile->controller( ref($c) );
          $profile->controller_action( $c->stash->{action} );
          $profile->http_code( $c->tx->res->code );

          if( $c->req ) {

            $profile->url( $c->req->url );
            $profile->http_method( $c->req->method );

            if( my $cross_application_tracing_id = $c->req->headers->header("X-PerlGuard-Auto-Track") ) {
              $profile->cross_application_tracing_id($cross_application_tracing_id);
            }
          }

          do {
            local $PerlGuard::Agent::CURRENT_PROFILE_UUID = $c->tx->{'PerlGuard::Profile'}->uuid() unless $c->stash->{'mojo.static'} ;
            return $next->();
          };          

        }

      }

      $next->();
    });

    $app->helper(perlguard_profile => sub {
      my $c = shift;
      return $c->tx->{'PerlGuard::Profile'};
    });

    $agent->detect_monitors();
    $agent->start_monitors();

}


1;