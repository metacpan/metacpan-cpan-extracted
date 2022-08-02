package Plack::App::ServiceStatus;

# ABSTRACT: Check and report status of various services needed by your app

our $VERSION = '0.906'; # VERSION

use 5.018;
use strict;
use warnings;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw(app version checks));

use Try::Tiny;
use Plack::Response;
use JSON::MaybeXS;
use Module::Runtime qw(use_module);
use Log::Any qw($log);

my $startup = time();

sub new {
    my ( $class, %args ) = @_;
    my $app = delete $args{app};
    my $version = delete $args{version};
    my @checks;
    while ( my ( $key, $value ) = each %args ) {
        my $module;
        if ( $key =~ /^\+/ ) {
            $module = $key;
            $module =~ s/^\+//;
        }
        else {
            $module = 'Plack::App::ServiceStatus::' . $key;
        }
        try {
            use_module($module);
            push(
                @checks,
                {   class => $module,
                    name  => $key,
                    args  => $value
                }
            );
        }
        catch {
            $log->errorf( "%s: cannot init %s: %s", __PACKAGE__, $module,
                $_ );
        };
    }

    return bless {
        app    => $app,
        version => $version,
        checks => \@checks
    }, $class;
}

sub to_app {
    my $self = shift;

    my $app = sub {
        my $env = shift;

        my $json = {
            app        => $self->app,
            started_at => $startup,
            uptime     => time() - $startup,
        };
        $json->{version} = $self->version,

        my @results = (
            {   name   => $self->app,
                status => 'ok',
            }
        );

        foreach my $check ( @{ $self->checks } ) {
            my ( $status, $message ) = try {
                return $check->{class}->check( $check->{args} );
            }
            catch {
                return 'nok', "$_";
            };
            my $result = {
                name   => $check->{name},
                status => $status,
            };
            $result->{message} = $message if ($message);

            push( @results, $result );
        }
        $json->{checks} = \@results;

        return Plack::Response->new( 200,
            [ 'Content-Type', 'application/json' ],
            encode_json($json) )->finalize;
    };
    return $app;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::ServiceStatus - Check and report status of various services needed by your app

=head1 VERSION

version 0.906

=head1 SYNOPSIS

  # using Plack::Builder with Plack::App::URLMap
  use Plack::Builder;
  use Plack::App::ServiceStatus;

  my $status_app = Plack::App::ServiceStatus->new(
      app           => 'your app',
      version       => '1.42',
      DBIC          => [ $schema, 'select 1' ],
      Elasticsearch => $es, # instance of Search::Elasticsearch
  );

  builder {
    mount "/_status" => $status_app;
    mount "/" => $your_app;
  };


  # using OX
  router as {
      mount '/_status' => 'Plack::App::ServiceStatus' => (
          app                     => literal(__PACKAGE__),
          Redis                   => 'redis',
          '+MyApp::ServiceStatus' => {
                foo => literal("foo")
          },
      );
      route '/some/endpoint' => 'some_controller.some_action';
      # ...
  };


  # checking the status
  curl http://localhost:3000/_status | json_pp
  {
     "app" : "Your app",
     "version": "1.42",
     "started_at" : 1465823638,
     "uptime" : 42,
     "checks" : [
        {
           "status" : "ok",
           "name" : "Your app"
        },
        {
           "name" : "Elasticsearch",
           "status" : "ok"
        },
        {
           "name" : "DBIC",
           "status" : "ok"
        }
     ]
  }

=head1 DESCRIPTION

C<Plack::App::ServiceStatus> implements a small
L<Plack|https://metacpan.org/pod/Plack> application that you can use
to get some status info about your application and the services needed by
it.

You can then use some monitoring software to periodically check if
your app is running and has access to all needed services.

=head2 Checks

The following checks are currently available:

=over

=item * L<Plack::App::ServiceStatus::DBI> - (raw DBI C<$dbh>)

=item * L<Plack::App::ServiceStatus::DBIxConnector> - when using C<DBIx::Connector> to connect to a DB

=item * L<Plack::App::ServiceStatus::DBIC> - when you're using C<DBIx::Class>

=item * L<Plack::App::ServiceStatus::Redis>

=item * L<Plack::App::ServiceStatus::Elasticsearch>

=item * L<Plack::App::ServiceStatus::NetStomp>

=back

Each check consists of a C<name> and a C<status>. The status can be
C<ok> or C<nok>. A check might also contain a C<message>, which should
be some description of the error or problem if the status is C<nok>.

Each check has to implement a method named C<check> which will be
called with name of the class and the arguments you specified when
setting up C<Plack::App::ServiceStatus>. C<check> has to return either
the string C<ok>, or the string C<nok> and a string containing an
explanation.

You can add your own checks by specifying a name starting with a C<+>
sign, for example C<+My::App::SomeStatusCheck>. Or send me a pull
request to include your check in this distribution, or just release it
yourself!

=head2 Weirdness

The slightly strange way C<Plack::App::ServiceStatus> is initiated is caused
by the way L<OX|https://metacpan.org/pod/OX> works.

C<Plack::App::ServiceStatus> is B<not> implemented as a middleware on
purpose. While middlewares are great for a lot of use cases, I think
that here an embedded app is the better fit.

=head1 TODO

=over

=item * tests

=item * make sure the app is only initiated once when running in OX

=back

=head1 THANKS

Thanks to

=over

=item *

L<validad.com|http://www.validad.com/> for funding the
development of this code.

=item * <Manfred Stock|https://github.com/mstock> for adding
Net::Stomp and a Icinga/Nagios check script.

=back

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2022 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
