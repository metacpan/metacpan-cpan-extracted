package Syringe;

use 5.6.1;

use base 'Class::Singleton';
our $VERSION = '0.01';

use Modern::Perl;
use Data::Dumper;
use Log::Log4perl qw(:easy);
use YAML::XS qw(LoadFile);
use Carp;
use Scalar::Util qw(blessed);

use Log::Log4perl qw(get_logger);

my $default_log4perl_conf = q(
    log4perl.rootLogger=DEBUG,Logfile
    log4perl.category.default=WARN,Logfile
    log4perl.appender.Logfile=Log::Log4perl::Appender::File
    log4perl.appender.Logfile.filename=test.log
    log4perl.appender.Logfile.layout=Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Logfile.layout.ConversionPattern=%d %M %m %n
);

#-------------------------------------------------------------------------------


# this only gets called the first time instance() is called
sub _new_instance {
    my ($proto, %params) = @_;

    my $class = ref $proto || $proto;

    if ($params{log4perlconf}) {
        Log::Log4perl::init($params{log4perlconf});
    } else {
        Log::Log4perl::init(\$default_log4perl_conf);
    }

    $params{logger} = get_logger();

    $params{logger}->info("_new_instance called");

    my $self = bless \%params, $class;

    $params{config} = LoadFile($self->{path});

    $self->_compile;

    return $self;
}

#-------------------------------------------------------------------------------

sub logger {
    my $self = shift;
    return $self->{logger};
}

#-------------------------------------------------------------------------------

sub _config {
    my $self = shift;
    return $self->{config};
}

#-------------------------------------------------------------------------------

sub _instantiate {
    my ($self, $config, $service) = @_;    

    $self->logger->info("Start instantiation of $service");

    my $class = $config->{$service}->{class}->{name};
    
    my $dependencies = $config->{$service}->{'dependencies'};

    my %args; 

    for my $dependency_name ( keys %{ $dependencies } ) {
        $self->logger->info("Parsing dependency [$dependency_name]");
        my $value;
        my $dep_service = $dependencies->{$dependency_name}->{'service'};
        my $dep_value   = $dependencies->{$dependency_name}->{'value'};
        my $is_service  = defined $dep_service ? 1 : 0; 

        # look for services first
        if ($is_service) {
            $self->logger->info("[$dependency_name] is service.");

            # check to see if it was loaded into runtime yet
            if (exists $config->{$dep_service}->{'object'}) {
                # set the value to the object in memory
                $value = $config->{$dep_service}->{'object'};
            }
            else {
                # recursive call
                $self->logger->info("[$dependency_name] is not existing service.");
                $value = $self->_instantiate($config, $dep_service);
            }
        } elsif (!$is_service) {
            $self->logger->info("[$dependency_name] is a value.");
            $value = $dep_value;
        }
        
        $args{$dependency_name} = $value;
    }
    
    my $constructor = $config->{$service}->{class}->{constructor} || 'new';

    # instantiate new object
    
    if ($self->logger->is_debug) {
        for my $lib (@INC) {
            $self->logger->debug("\@INC contains [ $lib ]");
        }
    }

    eval "require $class";
    eval "import $class";

    my $object = $class->$constructor(%args);

    if (ref $object eq $class) {
        $self->logger->info("Succes! instantiated service [$service] class [$class]!");
    }
    else {
        $self->logger->fatal("Failed to instantiate service [$service] class [$class]!");
    }

    $config->{$service}->{object} = $object;

    return $object;
}

#-------------------------------------------------------------------------------

sub _compile {
    my $self = shift;
    my $config = $self->_config;
    for my $service ( sort keys %$config) {
        $self->logger->info("Found service named [ $service ]!");

        $self->_instantiate($config, $service);
    }
}

#-------------------------------------------------------------------------------

sub get_class {
    my ($self, $service) = @_;

    $self->logger->debug("called with arg $service"); 

    return $self->_config->{$service}->{class}->{name};
}

#-------------------------------------------------------------------------------

sub get_service {
    my ($self, $service) = @_;

    $self->logger->debug("called with arg $service"); 

    my $config = $self->_config;
        
    my $object = $self->_config->{$service}->{'object'};
    my $ref    = ref $object;
    my $class  = $self->get_class($service);

    $self->logger->debug("Ref of Object returned for $service is $ref");

    if (ref $object ne $class) {
        $self->logger->fatal("Object is not a $class!");
    } 

    return $object;
}

#-------------------------------------------------------------------------------

sub register_service {
    my ($self, $service_identifier, $service) = @_;

    $self->logger->info("called with service identifier [$service_identifier]");


    my $class = blessed $service;

    if (!$class) {
        $self->logger->error("Failed to pass an object!");
        croak("You must pass a blessed object!");
    }

    my $config = $self->_config;

    if (exists $config->{$service_identifier}->{'object'}) {
        $self->logger->error("Service identifier [$service_identifier] already exists!");
        croak("You are trying to register a service with an existing name!");
    }

    $config->{$service_identifier}->{'class'}->{name} = $class;
    $config->{$service_identifier}->{'object'} = $service;

    return 1;
}

#-------------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Syringe

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Syringe;

    my $container = Syringe->instance( path => $path_to_yaml_config );

    # get an object that is fully instantiated with all dependencies WITHOUT having
    # to have 'use' dependecies in the class files themselves. 
    my $object = $container->get_service("SomeUniqueIdentifier");

    $object->do_stuff();

=head1 DESCRIPTION

Syringe is a lightweight implementation of a Dependency Injection Container with
built in Log::Log4perl logging.  This implementation uses constructor injection and
also implements a registry via the B<get_service> method.

=head1 YAML CONFIG FILE

Syringe takes a simple YAML file for configuration. The format is:

    ServiceName:
      class:
        name: "Service::Class::Foo"
      dependencies:
        param1:
          value: value1
        param2:
          value: value2
        param3:
          service: AServiceIdentifier
    AServiceIdentifier:
      class:
        name: "Service::Class::Bar"
      dependencies:
        somenumber:
          value: 1000 
        somestring:
          value: "This is a string"

In the example snippet above, "ServiceName" is a unique identifier string of a
"service". A "service" in this context is an instantiated object at runtime.

The depenedencies section lists all the arguments that have to be passed to
the object inorder to instantiate it. It is assumed that parameters are being
passed to the constructer in hash format. And it is assumed that the constructor
method is 'new'. If it is not, you should write a facade class around the
one you want to instantiate.

Services can list other services at dependencies by using the 'service:'
identifier like so:

        param3:
          service: AServiceIdentifier

The container will format a hash to pass to the constructor of the service like so:

    Service::Class::Foo->new(
            param1 => "value1",
            param2 => "value2",
            param3 => $AServiceIdentifierObj
    );

Where $AServiceIdentifierObj is an instance of the AServiceIdentifier service
class.

=head1 EXAMPLE CLASSES

In this example, we define classes and interfaces (Roles in Moose) to model
cars, engines, transmissions and transmission interface (how to shift). In
the EXAMPLE YAML CONFIGURATION section below, we will be taking this
and 'wiring' our runtime objects together by declaring relationships and
dependencies in the YAML file. Any dependencies will be "injected" into
the appropriate objects that depend on them.

    use MooseX::Declare;

    class RA::UnitTest::6SpeedShifter with RA::UnitTest::ShifterInterface {
        has 'pattern' => (
            isa      => 'Str',
            is       => 'ro',
            required => 1,
        );

        method up_shift {
            return 1;
        }

        method down_shift {
            return 1;
        }

        method reverse_shift {
            return 1;
        }

        method put_in_neutral {
            return 1;
        }
    }

    class RA::UnitTest::Car with RA::UnitTest::CarInterface {
        has 'been_raced_on_track' => (
            isa      => 'Bool',
            is       => 'ro',
            required => 1,
            default  => 0,
        );

        method warranty {
            if ($self->been_raced_on_track) {
                return "I'm sorry, you're warranty is void.";
            }
            else {
                return "I'm sorry, most likely you're warranty is void anyways.";
            }
        }
    }

    role RA::UnitTest::CarInterface {
        has 'make'   => (
            isa      => 'Str',
            is       => 'ro',
            required => 1
        );

        has 'model'   => (
            isa      => 'Str',
            is       => 'ro',
            required => 1
        );

        has 'year'   => (
            isa      => 'Int',
            is       => 'ro',
            required => 1
        );

        has 'engine'   => (
            does     => 'RA::UnitTest::EngineInterface',
            is       => 'ro',
            required => 1
        );

        has 'transmission'   => (
            does     => 'RA::UnitTest::TransmissionInterface',
            is       => 'ro',
            required => 1
        );

        method start_engine {
            $self->engine->start;
        }

        method stop_engine {
            $self->engine->stop;
        }
    }

    class RA::UnitTest::Engine with RA::UnitTest::EngineInterface {
        method start_sound {
            print "Kchhh vroooooOOOOMmmm..\n";
        }

        method stop_sound {
            print "Bupp bupp";
        }

        method idle_sound {
            print "Bup bup baa bup bup baa bup bup baa bup bup baa.\n";
        }

        method catastrophic_failure_sound {
            print "KAAAAA BOOOOOOOOOOOOOOOOOOOOOOOOMMMMMMMMM!!!!!!\n";
        }
    }

    role RA::UnitTest::EngineInterface {
        requires qw(
            start_sound
            stop_sound
            idle_sound
            catastrophic_failure_sound
        );

        has 'make'   => (
            isa      => 'Str',
            is       => 'ro',
            required => 1
        );

        has 'model'   => (
            isa      => 'Str',
            is       => 'ro',
            required => 1
        );

        has 'year'   => (
            isa      => 'Int',
            is       => 'ro',
            required => 1
        );

        has 'displacement'   => (
            isa      => 'Int',
            is       => 'ro',
            required => 1
        );

        has 'cylinders'   => (
            isa      => 'Int',
            is       => 'ro',
            required => 1
        );

        has 'horsepower'   => (
            isa      => 'Int',
            is       => 'ro',
            required => 1
        );

        method start {
            $self->start_sound();
            return 1;
        }

        method idle {
            $self->idle_sound();
            return 1;
        }

        method stop {
            $self->stop_sound();
            return 1;
        }

        method catastrophic_failure {
            $self->catastrophic_failure_sound();
            return 1;
        }
    }

    role RA::UnitTest::ShifterInterface {
        requires qw(up_shift down_shift reverse_shift put_in_neutral);
    }


    class RA::UnitTest::Transmission with RA::UnitTest::TransmissionInterface {

    }

    role RA::UnitTest::TransmissionInterface {
        has 'make'   => (
            isa      => 'Str',
            is       => 'ro',
            required => 1
        );

        has 'model'   => (
            isa      => 'Str',
            is       => 'ro',
            required => 1
        );

        has 'interface'   => (
            does     => 'RA::UnitTest::ShifterInterface',
            is       => 'ro',
            required => 1
        );

        has 'current_gear'   => (
            isa      => 'Int',
            is       => 'rw',
            required => 1,
            default  => 0, # neutral
        );

        has 'forward_gears'   => (
            isa      => 'Int',
            is       => 'ro',
            required => 1,
        );

        has 'reverse_gears'   => (
            isa      => 'Int',
            is       => 'ro',
            required => 1,
        );

        method upshift {
            if ($self->current_gear == $self->forward_gears) {
                return;
            }
            else {
                $self->current_gear($self->current_gear + 1);
            }
        }

        method downshift {
            if ($self->current_gear < 1) {
                return;
            }
            else {
                $self->current_gear($self->current_gear - 1);
            }
        }

        method put_in_neutral {
            $self->current_gear(0);
        }

        method put_in_reverse {
            if ($self->current_gear < 1) {
                $self->current_gear(-1);
            } else {
                print "CRUNCHHHH!\n";
            }
        }
    }


=head1 EXAMPLE YAML CONFIGURATION

Here is the example YAML configuration that refers to the classes we defined
in the section above. We define two cars here. One is a factory 2007 Chevrolet
Z06 (StockCar) and one is a heavily modified Z06 (FastNFuriousCar).

    StockCar:
      class:
        name: "RA::UnitTest::Car"
      dependencies:
        make:
          value: "Chevrolet"
        model:
          value: "Z06"
        year:
          value: 2007
        engine:
          service: "LS7Engine"
        transmission:
          service: "TremecT56Transmission"
    FastNFuriousCar:
      class:
        name: "RA::UnitTest::Car"
      dependencies:
        make:
          value: "VIN BENZINE"
        model:
          value: "Z006"
        year:
          value: 2012
        engine:
          service: "RidiculouslyModdedLS7Engine"
        transmission:
          service: "TremecT56Transmission"
    LS7Engine:
      class:
        name: "RA::UnitTest::Engine"
      dependencies:
        make:
          value: "GM"
        year:
          value: "2007"
        model:
          value: "LS7"
        displacement:
          value: 7000
        cylinders: 
          value: 8
        horsepower:
          value: 505
    TremecT56Transmission:
      class: 
        name: "RA::UnitTest::Transmission"
      dependencies:
        make:
          value: "Tremec"
        model:
          value: "T56"
        interface:
          service: "Standard6SpeedHPattern"
        forward_gears:
          value: 6 
        reverse_gears:
          value: 1
    Standard6SpeedHPattern:
      class:
        name: "RA::UnitTest::6SpeedShifter"
      dependencies:
        pattern:
          value: "H"
    RidiculouslyModdedLS7Engine:
      class:
        name: "RA::UnitTest::Engine"
      dependencies:
        make:
          value: "Ridiculous Engines R' Us" 
        year:
          value: 2012
        model: 
          value: "LS200"
        displacement:
          value: 14000
        cylinders: 
          value: 16 
        horsepower:
          value: 2000 

=head1 USING THE CONTAINER

    use Modern::Perl;
    use Test::More;
    use Test::Moose;
    use Test::Exception;
    use Data::Dumper;
    use Cwd 'abs_path';
    use File::Spec;
    use FindBin qw($Bin);

    use lib "$Bin/lib";

    my $abs_path = abs_path($0);

    my ( $volume, $directories, $file ) = File::Spec->splitpath($abs_path);

    my $test_yaml_path = File::Spec->catfile( $directories, 'ra-di-container.yml' );

    ok( -f $test_yaml_path, "test yaml file [ $test_yaml_path ] exists!" );

    use_ok('Syringe');

    my $container = Syringe->instance( path => $test_yaml_path );

    cmp_ok( $container->get_class('StockCar'), 'eq', 'RA::UnitTest::Car', 'get_class' );

    my $car = $container->get_service('StockCar');

    isa_ok( $car, 'RA::UnitTest::Car', 'get_service' );
    does_ok($car, 'RA::UnitTest::CarInterface');
    cmp_ok($car->make,  'eq', 'Chevrolet', 'car correct make');
    cmp_ok($car->model, 'eq', 'Z06', 'car correct model');
    cmp_ok($car->year,  '==', 2007, 'car correct year');

    my $engine = $car->engine;

    isa_ok($engine, 'RA::UnitTest::Engine'); 
    does_ok($engine, 'RA::UnitTest::EngineInterface');
    cmp_ok($engine->make, 'eq', 'GM', 'engine make correct');
    cmp_ok($engine->model, 'eq', 'LS7', 'engine model correct');
    cmp_ok($engine->year, '==', 2007, 'engine year correct');
    cmp_ok($engine->horsepower, '==', 505, 'engine horsepower correct');
    cmp_ok($engine->displacement, '==', 7000, 'engine displacement correct');
    cmp_ok($engine->cylinders, '==', 8, 'engine cylinders correct');

    my $transmission = $car->transmission;

    isa_ok($transmission, 'RA::UnitTest::Transmission');
    does_ok($transmission, 'RA::UnitTest::TransmissionInterface');
    cmp_ok($transmission->make, 'eq', 'Tremec', 'transmission make correct');
    cmp_ok($transmission->model, 'eq', 'T56', 'transmission model correct');

    my $interface = $transmission->interface;
    isa_ok($interface, 'RA::UnitTest::6SpeedShifter');
    does_ok($interface, 'RA::UnitTest::ShifterInterface');
    cmp_ok($interface->pattern, 'eq', 'H', 'transmission interface is correct');

    #-------------------------------------------------------------------------------
    # test that the FastNFuriousCar actualy got instantiated correctly with all
    # of it's dependencies injected.
    #-------------------------------------------------------------------------------

    $car = $container->get_service('FastNFuriousCar');

    isa_ok( $car, 'RA::UnitTest::Car', 'get_service' );
    does_ok($car, 'RA::UnitTest::CarInterface');
    cmp_ok($car->make,  'eq', 'VIN BENZINE', 'car correct make');
    cmp_ok($car->model, 'eq', 'Z006', 'car correct model');
    cmp_ok($car->year,  '==', 2012, 'car correct year');

    $engine = $car->engine;

    isa_ok($engine, 'RA::UnitTest::Engine'); 
    does_ok($engine, 'RA::UnitTest::EngineInterface');
    cmp_ok($engine->make, 'eq', "Ridiculous Engines R' Us", 'engine make correct');
    cmp_ok($engine->model, 'eq', 'LS200', 'engine model correct');
    cmp_ok($engine->year, '==', 2012, 'engine year correct');
    cmp_ok($engine->horsepower, '==', 2000, 'engine horsepower correct');
    cmp_ok($engine->displacement, '==', 14000, 'engine displacement correct');
    cmp_ok($engine->cylinders, '==', 16, 'engine cylinders correct');

    $transmission = $car->transmission;

    isa_ok($transmission, 'RA::UnitTest::Transmission');
    does_ok($transmission, 'RA::UnitTest::TransmissionInterface');
    cmp_ok($transmission->make, 'eq', 'Tremec', 'transmission make correct');
    cmp_ok($transmission->model, 'eq', 'T56', 'transmission model correct');

    $interface = $transmission->interface;
    isa_ok($interface, 'RA::UnitTest::6SpeedShifter');
    does_ok($interface, 'RA::UnitTest::ShifterInterface');
    cmp_ok($interface->pattern, 'eq', 'H', 'transmission interface is correct');

    done_testing();

=head1 SO WHY IS THIS USEFUL?!

Dependency Injection is useful for the following reasons:


=head2 1. No hardcoded dependencies in the class code.

Since there are no use statements, you don't have to hunt through your code to
find them when you change classes you are using. A common example would be an
ORM or XML parser.

=head2 2. You can easily plug in or inject mocked classes with no negative effects.

Take the example about the cars from above. Those are basically test classes. 
One could easily write a class that consumes the RA::UnitTest::Engine role that
is actually connected to a real engine and inject it into the car class.

With DI, it's very easy to plug'n play code dependencies with minimal code changes.
All the changes are done in the configuration file.

=head3 3. If you program to interfaces, it's very easy to change implementations.

=head1 CONSTRUCTOR

=head2 instance

 my $container = Syringe->instance( path         => $yaml_config_file,
                                    log4perlconf => $path_to_conf );

The constructor is 'instance' because this is a singleton class. You must 
pass the B<path> parameter which should contain the path to the yaml config
file. The B<log4perlconf> parameter is optional. If you don't pass one, the 
default configuration will be used (see logger below).

=head1 METHODS

=head2 logger

 my $log4perl = $container->logger;

If you don't pass in B<log4perlconf> parameter to the constructor, the
following default configuration will be used for Log::Log4perl.

    log4perl.rootLogger=DEBUG,Logfile
    log4perl.category.default=WARN,Logfile
    log4perl.appender.Logfile=Log::Log4perl::Appender::File
    log4perl.appender.Logfile.filename=test.log
    log4perl.appender.Logfile.layout=Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Logfile.layout.ConversionPattern=%d %M %m %n

=head2 get_service

 my $object = $container->get_service("ServiceUniqueIdentifier");

Returns an instance of the class associated with a given service.

=head2 get_class

 my $class = $container->get_class("ServiceUniqueIdentifier");

Returns the class that the service is mapped to.

=head2 register_service

 my $mongodb = MongoDB::Connection->new(host => 'localhost', port => 27017); 
 $container->register_service("MongoDB", $mongodb);

Allows you to add services at runtime. Dependencies will not be handled for you.
You must pass a fully instantiated object. 

If you want the dependencies automatically handled for you, use the YAML file.

=head1 OTHER PERL IOC/DI IMPLEMENTATIONS

Check out IOC and Bread::Board

=head1 MORE INFORMATION ABOUT IOC

http://martinfowler.com/articles/injection.html

=head1 AUTHOR

Rick Apichairuk, C<< <rick.apichairuk at gmail.com> >>

=head1 COPYRIGHT

Copyright (C) 2012 by Rick Apichairuk

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


