package MooseX::DIC;

our $VERSION = '0.3.2';

use MooseX::DIC::ContainerFactory;
use MooseX::DIC::Injected
    ;    # We load this here to have the trait available further on.

require Exporter;
@ISA       = qw/Exporter/;
@EXPORT_OK = qw/build_container/;

sub build_container {
    my %options   = @_;

	ContainerConfigurationException->throw(
		message => 'scan_path is a mandatory parameter')
		unless exists $options{scan_path};
	$options{environment} = $options{environment} || 'default';

	my $container_factory = MooseX::DIC::ContainerFactory->new(
		scan_path => $options{scan_path},
		environment => $options{environment}
	); 

    return $container_factory->build_container;
}

1;

=encoding UTF-8

=head1 NAME

MooseX::DIC - A dependency injector container for Moose

=head1 DESCRIPTION

Full documentation on the L<MooseX::DIC Webpage|http://docs.moosex-dic.org>.

MooseX::DIC is a dependency injection container tailored to L<Moose>, living in a full OOP environment and greatly
inspired by Java DIC frameworks like L<Spring|https://docs.spring.io/spring/docs/current/spring-framework-reference/html/beans.html>
or L<CDI|http://docs.oracle.com/javaee/6/tutorial/doc/gjbnr.html>.

The goal of this library is to provide an easy to use DI container with automatic wiring of dependencies via constructor 
by class type (ideally by Role/Interface).

The configuration is performed either by the use of L<Marker roles|https://en.wikipedia.org/wiki/Marker_interface_pattern> and
a specific trait on attributes that have to be injected, or by use of a very terse and composable yaml config file, using sensible
defaults to cover 90% of the use cases to minimize boilerplate.

One of the principal tenets of the library is that while code may be poluted by the use of DIC roles and traits, it
should work without a running container. The classes are fully functional without the dependency injection, the library
is just a convenient way to wire dependencies (this is mainly accomplished by forbidding non L<constructor injection|https://en.wikipedia.org/wiki/Dependency_injection#Constructor_injection>).

This library is designed to be used on long-running processes where startup time is not a concern (within reason, of
course). The container will scan all configured paths to look for services to inject and classes that need injection.

There is a great amount of flexibility to account for testing environments, non-moose libraries, alternative
implementations of services, etc, although none of it is needed for a simple usage.

=head1 SYNOPSIS

A service is injectable if it consumes the Role L<MooseX::DIC::Injectable>, which is a parameterized role.

	package MyApp::LDAPAuthService;
	
	use Moose;
	with 'MyApp::AuthService';
	
	with 'MooseX::DIC::Injectable' => {
		implements  => 'MyApp::AuthService',
		qualifiers  => [ 'LDAP' ],
		environment => 'test',
		scope       => 'singleton'
	};

	has ldap => (is => 'ro', does => 'LDAP' );

	1;

We can see that this service is both an injectable service and consumes another injectable service,LDAP. We register a
class as injectable into the container registry by consuming the L<MooseX::DIC::Injectable> role, and we get injected
dependencies automatically if the container can find them.

None of the parameters of the L<MooseX::DIC::Injectable> role are mandatory, they have defaults or can be inferred.
On the example above, the role/interface the LDAPAuthService was implementing could be inferred from the
C<with 'MyApp::AuthService'> previous line.

To use this service:

	package MyApp::LoginController;
	
	use Moose;

	has auth_service => ( is=>'ro', does => 'MyApp::AuthService' );

	sub do_login {
		my ($self,$request) = @_;
		
		if($self->auth_service->login($request->username,$request->password)) {
			print 'this is fine';
		}
	}

	1; 

The dependency will have been injected automatically as long as the Logincontroller
was created by the container.

=head1 Starting the Container

When starting your application, the container must be launched to start it's 
scanning. You can tell the container which folders to scan in search of injectable
services or of wiring files (or both!). 
This operation is slow as it has to scan every file under the specified folders, 
which means you will usually only use one container per application.

To start the container:

  #!/usr/bin/env perl
  use strict;
  use warning;

  use MooseX::DIC 'build_container';
  use MyApp::Launcher;

  # This may take some time depending on your lib size
  my $container = build_container( scan_path => [ 'lib' ] );

  # The launcher is a fully injected service, with all dependencies
  # provided by the container.
  my $app = $container->get_service 'MyApp::Launcher';
  $app->start;

  exit 0;

As in the rest of dependency injection containers: Once the root object of your
application is created by the container, the rest of object  will have been fetched 
automatically.

=head1 Advanced use cases

=head2 Scopes

=head3 Service scope

Although the vast majority of services we want to inject are by their stateless nature candidates to be singletons, we
may want for our service to be instantiated every time they are requested. For example, an http agent could be
instantiated once per service.

    package MyApp::LWPHTTPAgent;

    use LWP::UserAgent;

    use Moose;
    with 'MyApp::HTTPAgent';
    with 'MooseX::DIC::Injectable' => { scope => 'request' };

    has ua => ( is => 'ro', isa => 'LWP::UserAgent', default => sub { LWP::UserAgent->new; } );

    sub request {
        $self->ua->request(shift);
    }

    1;

This service declares that it can be injected on attributes that need an object that does 'MyApp::HTTPAgent' and that
each time it is called, it will be created anew. To use it:

    package MyApp::RESTUserService;

    use Moose;
    with 'MyApp::UserService';

    has http_client => ( is => 'ro', does => 'MyApp::HTTPAgent' );

    sub persist {
        my ($self,$user) = @_;

        # A new instance is created here and lives for as long as
        # the RESTUserService lives.
        $self->http_client->request(...);
    }

Two types of scope are available for services:

=over 4

=item singleton

The default scope, the registry will only keep one copy of the service and will inject it into every attribute it is
requested.

Make sure the service is stateless or you will run into race conditions.

=item request

Each time the service is requested, a new instance of it will be created. Useful for stateful services.

=back

=head3 Injection scope

For services which are request scoped, the requester can also ask the injection container to create a new service each
time the accessor is used, for stateful services that should only live once per use. For example, we may be interested
in using an http user agent that somehow keeps some states between callings and if used for different purposes would be
corrupted.

    package MyApp::RESTUserService;

    use Moose;
    with 'MyApp::UserService';

    has http_client => ( is => 'ro', does => 'MyApp::HTTPAgent', scope => 'request', traits => [ 'Injected' ] );

    sub persist {
        my ($self,$user) = @_;

        # A new instance of MyApp::LWPHTTPAgent is created here
        $self->http_client->request(...);

        # Yet another instance of MyApp::LWPHTTPAgent is created again
        $self->http_client->request(...);

        # If we want to keep the same instance for a series of calls, reference it.
        my $ua = $self->http_client;
        $ua->request(...);
        $ua->request(...);
    }

Please take note of the new trait we've used for the injected attribute. When we only want singleton services to be injected,
there's no need to configure the attribute. But when we want to apply a configuration on how the attribute must be 
injected, then we must use the L<MooseX::DIC::Injected> trait on the attribute which allows to specify scope and qualifiers for the
injection.

There are two scopes available for the injection scope:

=over 4

=item object

The default scope. For request scoped services, the service is instantiated once per object.

=item request

For request scoped services, if the injection scope is request too, an accessor is created that will fetch a new
instance of the service each time it is called.

=back

The injection scope only makes sense for request scoped services, since singleton services will only be instantiated
once.

It is a configuration error to ask for a singleton scoped service into a request-scoped injection point, and the
container will generate an exception when it encounters this situation (in the spirit of detecting errors as soon as
possible).

=head2 Qualifiers (TBD)

=head3 Qualifiers usage

Sometimes, we want a Role/Interface to be implemented by many classes and to let the caller specify which one it wants.

While this would seem to oppose the very idea of letting a container to give you objects, in fact it doesn't, and gives
a great deal of flexibility while still allowing the container to choose the best implementator for your caller and
initialize it.

Qualifiers let a service specify with a more fine-grained precision how they implement an interface, so that callers can
choose them based on those qualifiers.

For example, we can have two implementators of an HTTPAgent service:

    package MyApp::LWPHTTPAgent;

    use Moose;
    with 'MyApp::HTTPAgent';

    with 'MooseX::DIC::Injectable' => { qualifiers => [ 'sync' ] };

    sub request {
        # returns the response
    }


    package MyApp::AsyncHTTPAgent;
    use Moose;
    with 'MyApp::HTTPAgent';

    with 'MooseX::DIC::Injectable' => { qualifiers => [ 'async' ] };

    sub request {
        # returns a Promise with the response
    }

    package MyApp::RESTUserService;

    use Moose;
    use MooseX::DIC;

    has http_client => ( is => 'ro', does => 'MyApp::HTTPAgent', qualifiers => [ 'async' ], injected);

    sub persist {
        # This service knows it can expect a Promise result
        # from the http agent, since it asked for the async version.
        return $self->http_client->request(...)
            ->then(sub {
                ...
            })
            ->catch(sub {
                ...
            });
    }

It is a configuration error to have two implementators of the same service living in the same L<environment|/Environments>
without at least one of them having a qualifier, and the container will generate an exception when it encounters that
situation.

Take note of the B<injected> keyword. It's sugar syntax to avoid using the trait. Although by using it, you tie your code
more tightly to the MooseX::DIC framework.

=head3 Qualifiers match resolution

When there are competing implementators for the same caller, which have different qualifiers, the resolution is based
on the following rule: The longest most precise qualifier match is returned

If the caller requests for qualifiers 'a','b' and 'c', given the following service implementations:

=over 4

=item Impl1 => qualifiers 'a','d'

=item Impl2 => qualifiers 'b', 'c'

=item Impl3 => qualifiers 'a'

=back

The implementator Impl2 will be selected, since it has the greater number of matching qualifiers.

If no exact qualifier match is found, the next best match is selected. Example:

Given a caller that requests a Service with qualifiers 'a', 'b', and 'c'. For the following implementations:

=over 4

=item Impl1 => qualifiers 'a'

=item Impl2 => no qualifiers

=back

The Impl1 will be selected even though it doesn't match all caller qualifiers.

Given a caller that requests a Service with qualifiers and only one implementator with no qualifiers, the implementator
will still be selected.

Given a caller that requests a Service with qualifier 'a', for the following implementations:

=over 4

=item Impl1 => qualifier 'b'

=item Impl2 => qualifier 'c'

=item Impl3 => no qualifiers

=back

One of the three implementations (always randomly) will be returned, since they are all equal matches. The random
selection will be enforced to avoid library clients shooting themselves on the foot by relying on a specific selection
when there are equal matches.

Following the last example, if a client specifically wants an implementation with no qualifiers it can specify it by
setting the qualifier parameter of the attribute to empty array:

    package MyApp::ExampleController;

    use Moose;
    use MooseX::DIC;

    has service => ( is => 'ro', does => 'ServiceRole', qualifiers => [], injected );

=head2 Environments

Sometimes, we want the wiring of services to depend on a runtime environment. To this end, we use the concept of
environments.

By default (that is, if no environment is declared by an C<MooseX::DIC::Injectable> service) all services live inside the 'default'
environment. But we can do more. Let's consider the following services:

    package MyApp::UserRepository;

    use Moose::Role;


    package MyApp::UserRepository::Database;

    use Moose;
    with 'MyApp::UserRepository';

    with 'MooseX::DIC::Injectable' => { environment => 'production' };


    package MyApp::UserRepository::InMemory;

    use Moose;
    with 'MyApp::UserRepository';

    with 'MooseX::DIC::Injectable' => { environment => 'test' };

With the following caller:

    package MyApp::UserController;

    use Moose;

    has repository => (is => 'ro', does => 'MyApp::UserRepository' );

    sub do_something {
        my ($self,$user) = @_;
        $self->repository->persist($user);
    }

These implementations live in different environments and they won't see each other. The selection of one or the other
will depend on which environment we launch the container in, as in:

    #!/usr/bin/env perl
    use strict;
    use warning;

	use MooseX::DIC 'build_container';

	my $container = build_container ( scan_path => 'lib', environment => 'test' );

	# In the test environment, the UserController class will have received
	# The InMemory user repository.
	my $user_controller = $container->get_service 'MyApp::UserController'

When the container doesn't find a service in a given environment, it will fall back to the default environment. If it
doesn't find a service there, it will throw an exception.

=head1 Configuration by YAML

While you can configure the services and the attribute injection points by use of the 
C<MooseX::DIC::Injectable> and C<MooseX::DIC::Injected> roles directly on your code, you may want to
configure the container with an external YAML config file.

This way, you can avoid tainting your code with infrastructure concerns. Everything that you can 
configure with the marker interfaces, you can do with the yaml config file.

Example:

	# moosex-dic-wiring.yml
	include:
	  - included_config_file.yml
	mappings:
	  MyApp::LoginService:
		MyApp::LoginService::LDAP:
		  qualifiers:
		    - ldap
		  dependencies:
		    ldap:
			  scope: request
		MyApp::LoginService::Database:
		  qualifiers:
		    - database
		MyApp::LoginService::InMemory:
		  environment: test
	  MyApp::LDAP:
        MyApp::LDAP:
		  scope: request
		  builder: factory
	  MyApp::HTTPClient:
	    MyApp::HTTPClient::LWP:
		  builder: factory
		  scope: request
		  qualifiers: 
		    - sync
		MyApp::HTTPClient::Mojo:
		  builder: factory
		  scope: request
		  qualifiers:
		    - async

Only what is different from the defaults needs to be configured. A wiring config file could be reduced to:

	# moosex-dic-wiring.yml
	mappings:
	    MyApp::LoginService: MyApp::LoginService::Database
		MyApp::LDAP: MyApp::LDAP
		MyApp::HTTPClient: MyApp::HTTPClient::LWP

If there's only a single mapping between an interface and it's implementation, and it's a Moose singleton 
stateless service.

=head1 AUTHOR

    Loïc Prieto Dehennault
    CPAN ID: LPRIETO
    CAPSiDE
    loic.prieto@capside.com

=head1 SEE ALSO

L<https://metacpan.org/pod/Moose>

L<http://docs.oracle.com/javaee/6/tutorial/doc/giwhl.html>

L<https://spring.io/>

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/loic-prieto/moosex-dic>

Please report bugs to: L<https://github.com/loic-prieto/moosex-dic/issues>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2017 by CAPSiDE

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.
