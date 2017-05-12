package RDF::Server;

use Moose;

use RDF::Server::Types qw( Handler Protocol Interface Semantic Formatter );
use Sub::Exporter;
use Sub::Name 'subname';
use Class::MOP ();
use MooseX::Types::Moose qw( ArrayRef );
use Storable ();

use 5.008;  # we have odd test failures on 5.6.2 that don't show up on 5.8+

our $VERSION='0.08';

has 'handler' => (
    is => 'rw',
    isa => Handler,
    required => 1,
    coerce => 1
);

has default_renderer => (
    is => 'rw',
    isa => 'Str',
    default => 'RDF'
);

# we put behaviors here that we want for everything in the namespace

{
    sub _load_class {
        my( $class ) = @_;
        return(
            $class
            && eval { Class::MOP::load_class($class) }
            && Class::MOP::is_class_loaded($class)
        );
    }

    sub _mapped_class {
        my($prefix, $is_type, $message, $c) = @_;
        my $class;
        if( substr($c, 0, 1) eq '+' ) {
            $class = substr($c, 1);
        }
        else {
            $class = $prefix . '::' . $c;
        }

        if( not _load_class($class) || !$is_type -> ($class) ) {
            confess $class . ' ' . $message;
        }
        else {
            return $class;
        }
    };

    sub _map_classes {
        my($parent_class, $prefix, $is_type, $message, $c) = @_;

        Moose::Util::apply_all_roles($parent_class -> meta,
            _mapped_class($prefix, $is_type, $message, $c)
        );
    };

    sub import {
        my $CALLER = caller();

        my @addons = @_;
        shift @addons;
        @_ = ($_[0]);

        my %exports = (
            'protocol' => sub {
                my $class = $CALLER;
                return subname 'RDF::Server::protocol' => sub ($) {
                    _map_classes($class, 'RDF::Server::Protocol', \&is_Protocol, 'does not fill the RDF::Server::Protocol role', @_);
                };
            },
            'interface' => sub {
                my $class = $CALLER;
                return subname 'RDF::Server::interface' => sub ($) {
                    _map_classes($class, 'RDF::Server::Interface', \&is_Interface, 'does not fill the RDF::Server::Interface role', @_);
                };
            },
            'semantic' => sub {
                my $class = $CALLER;
                return subname 'RDF::Server::semantic' => sub ($) {
                    _map_classes($class, 'RDF::Server::Semantic', \&is_Semantic, 'does not fill the RDF::Server::Semantic role', @_);
                };
            },

            'render' => sub {
                my $class = $CALLER;
                return subname 'RDF::Server::render' => sub ($$) {
                    my($extension, $as) = @_;
                    $class -> set_renderer( $extension, $as);
                }
            },
        );

        my $exporter = Sub::Exporter::build_exporter({
            exports => \%exports,
            groups => { default => [':all'] }
        });


        strict -> import;
        warnings -> import;

        return if $CALLER eq 'main';

        Moose -> import( { into => $CALLER } );

        $CALLER -> meta -> superclasses( __PACKAGE__ );

        my $class;

        foreach my $addon (@addons) {
            # Path: RDF::Server::Protocol, R:S::Interface
            #       MooseX::


            if( substr($addon, 0, 1) eq '+' && _load_class( substr($addon,1) ) ) {
                $class = substr($addon, 1);
            }
            elsif( _load_class('RDF::Server::Protocol::' . $addon) ) {
                $class = 'RDF::Server::Protocol::' . $addon;
            }
            elsif( _load_class('RDF::Server::Interface::' . $addon) ) {
                $class = 'RDF::Server::Interface::' . $addon;
            }
            elsif( _load_class('RDF::Server::Semantic::' . $addon) ) {
                $class = 'RDF::Server::Semantic::' . $addon;
            }
            elsif( _load_class('MooseX::' . $addon) ) {
                $class = 'MooseX::' . $addon;
            }
            elsif( _load_class($addon) ) {
                $class = $addon;
            }
            else {
                confess "Unable to find $class";
                next;
            }
            Moose::Util::apply_all_roles($CALLER -> meta, $class);
        }

        goto &$exporter;
    }
}

no Moose;

sub formatter {
    my( $self, $extension ) = @_;

    my $class = $self -> meta -> name;
    my $r;

    no strict 'refs';

    if( defined $extension ) {
        $r = ${"${class}::FORMATTERS"}{$extension};

        return $r if defined $r;
    }

    $r = $self -> default_renderer;
    if( _load_class("RDF::Server::Formatter::$r") ) {
        return "RDF::Server::Formatter::$r";
    }
    elsif( _load_class($r) ) {
        return $r;
    }
    else {
        throw RDF::Server::Exception::NotFound;
    }
}

sub set_renderer {
    my($self, $extension, $as) = @_;

    my $class = $self -> meta -> name;

    my $formatter;
    $extension = [ $extension ] unless is_ArrayRef( $extension );
    if( _load_class( "RDF::Server::Formatter::$as" ) ) {
        $formatter = "RDF::Server::Formatter::$as";
    }
    elsif( _load_class($as) ) {
        $formatter = $as;
    }
    if( is_Formatter( $formatter ) ) {
        no strict 'refs';
        @{$class . '::FORMATTERS'}{@$extension} = $formatter;
    }
    elsif( $formatter ) {
        confess "$formatter does not fill the RDF::Server::Formatter role";
    }
    else {
        confess "Unable to load $as";
    }
};


{
my $built_class = 1;
sub build_from_config {
    my $super = shift;

    $super = $super -> meta -> name;
    my %c = %{ Storable::dclone(+{ @_ }) };

    # $c -> {protocol,interface,semantic}
    # $c -> {with} -> [ ]
    # $c -> {renders} -> { }
    my $class = 'RDF::Server::Class::__ANON__::SERIAL::' . ($built_class++);

    my %config = (
        superclasses => [ $super ]
    );

    $c{interface} ||= 'REST';
    $c{protocol} ||= 'Embedded';
    $c{semantic} ||= 'Atom';

    $config{roles} = (delete $c{with})||[];

    push @{$config{roles}}, _mapped_class('RDF::Server::Interface', \&is_Interface, 'does not fill the RDF::Server::Interface role', delete $c{interface});
    push @{$config{roles}}, _mapped_class('RDF::Server::Protocol', \&is_Protocol, 'does not fill the RDF::Server::Protocol role', delete $c{protocol});
    push @{$config{roles}}, _mapped_class('RDF::Server::Semantic', \&is_Semantic, 'does not fill the RDF::Server::Semantic role', delete $c{semantic});

    #use Data::Dumper;
    #print STDERR Data::Dumper -> Dump([ \%config ]);

    my $meta = Moose::Meta::Class -> create( $class => %config );

#    Moose::Util::apply_all_roles($class -> meta, @{delete $c{with}})
#        if $c{with};

    # now manage renderings
    $class -> set_renderer( $_ => $c{renderers}->{$_} )
        foreach ( keys %{ $c{renderers} } );

    delete $c{renderers};

    $class -> meta -> add_around_method_modifier( 'new', sub {
        my($method, $class, %config) = @_;

        $class -> $method(%c, %config);
    } );

    return $class;
}
}
1;

__END__

=pod

=for readme stop

=head1 NAME

RDF::Server - toolkit for building RDF servers

=head1 SYNOPSIS

Build your own package:

 package My::Server;

 use RDF::Server;
 with 'MooseX::Getopt';

 interface 'REST';
 protocol  'HTTP';
 semantic  'Atom';   
                
 render xml => 'Atom';
 render rss => 'RDF';
            
 # Run server (if daemonizable):
                        
 my $daemon = My::Server -> new( ... );
     
 $daemon -> run();

Build your server class at run-time:

 use RDF::Server ();

 my $class = RDF::Server -> build_from_config({
     interface => 'REST',
     protocol => 'HTTP',
     semantic => 'Atom',
     renderers => { 
         xml => 'Atom',
         rss => 'RDF'
     },
     with => [qw(
         MooseX::Getopt
     )]
 });

 my $daemon = $class -> new( ... );

 $daemon -> run();

=for readme continue

=begin readme

                             RDF::Server 0.08

                      toolkit for building RDF servers

=head1 INSTALLATION

Installation follows standard Perl CPAN module installation steps:

 cpan> install RDF::Server

or, if not using the CPAN tool, then from within the unpacked distribution:

 % perl Makefile.PL
 % make
 % make test
 % make install

=end readme

=head1 DESCRIPTION

RDF::Server provides a flexible framework with which you can design
your own RDF service.  By dividing itself into several areas of responsibility,
the framework allows you to mix and match any capabilities you need to create
the service that fits your RDF data and how you need to access it.

=begin readme

The C<rdf-server> script is installed as an easy-to-use way of building and
running an RDF::Server service.  Some sample configuration files are in the
C<examples> directory of the RDF::Server distribution.

=end readme
            
The framework identifies four areas of responsibility:
            
=head2 Protocol
        
The protocol modules manage the outward facing part of the framework and
translating the requested operation into an HTTP::Request object that is
understood by any of the interface modules.  Conversely, it translates the
resulting HTTP::Response object into the form required by the environment
in which the server is operating.  
    
For example, the Embedded protocol provides a Perl API that can be used
by other modules without having to frame operations in terms of HTTP requests
and responses.
        
The methods expected of protocol modules are defined in
L<RDF::Server::Protocol>.  The outward-facing API is dependent on
the environment the server is expected to operate within.
                
Available protocols in the standard distribution:
L<RDF::Server::Protocol::Embedded>,
L<RDF::Server::Protocol::HTTP>.
    
=head2 Interface

The interface modules define how the HTTP requests are translated into
operations on various handlers that manage different aspects of the RDF
triple store.   

=head2 Semantic

The semantic modules define the meaning attached to and information 
contained in the various documents and the heirarchy of resources 
available through the interface modules.  Most of the content handlers 
are attached to a particular semantic.

The available semantics are:
L<RDF::Server::Semantic::Atom>,
L<RDF::Server::Semantic::RDF>.

=head2 Formatters

The same information can be rendered in several different formats.  The
format modules manage this rendering.

The available formatters are:
L<RDF::Server::Formatter::Atom>,
L<RDF::Server::Formatter::JSON>,
L<RDF::Server::Formatter::RDF>.

=for readme stop

=head1 SERVER CONFIGURATION

An RDF::Server server is configured in a two-step process.  The initial
configuration determins the fundamental behavior of the server by bringing
together the appropriate protocol, interface, and semantic roles.  The
second phase then configures the various information needed for these
roles to perform.

The initial configuration can be done either as a Perl package and 
read at compile time or built at run time using a static method.  The
run time option can be as flexible as the Perl package method, but
you will need to use roles to extend server functionality.

=head2 Building a Package

When you use RDF::Server in a package other than main, it will have
Moose import into the package and set itself as the package's superclass.
It will also import the various class methods detailed below.

As shown in the synopsis:

 package My::Server;

 use RDF::Server;
 with 'MooseX::Getopt';

 interface 'REST';
 protocol  'HTTP';
 semantic  'Atom';

 render xml => 'Atom';
 render rss => 'RDF';

This sets up the various roles needed to create a complete server.

With the addition of a run time option for configuring this information,
rendering information can also be set at run time after the class has been
defined, using the C<set_renderer> method.

=head2 Building from Configuration

If you use RDF::Server but don't allow its import method to be called, then
you can use its static methods to build a class at run time based on a
configuration file or other information determined at run time.

As shown in the synopsis:

 use RDF::Server ();

 my $class = RDF::Server -> build_from_config(
     interface => 'REST',
     protocol => 'HTTP',  
     semantic => 'Atom',
     renderers => {
         xml => 'Atom',
         rss => 'RDF'
     },
     with => [qw(
         MooseX::Getopt
     )],
     port => '8000',
 );

The C<build_from_config> static method will construct a class with the
appropriate roles based on the configuration information passed in.  

Any information that isn't associated with the C<interface>, C<protocol>, 
C<semantic>, C<renderers>, or C<with> keys is cached and serves as the
default values when an object of the class is instantiated.  In the above
example, the default port is changed to 8000 instead of the usual default
of 8080.

=head1 STATIC METHODS

=over 4

=item new

=item build_from_config

=item set_renderer ($extension, $class)

Each class has a class-global mapping of resource extension to 
rendering class.  In addition to allowing renderers to be set at
compile time via the C<render> method, this method can be called at
run time to modify the mapping.

=back

=head1 CLASS METHODS

In addition to the methods exported by Moose, several helper methods 
are exported when you C<use> RDF::Server.  These can be used to easily
specify the interface or protocol role if the name is ambiguous.

By default, these helpers will search for the appropriate class by 
prepending the appropriate C<RDF::Server::> namespace.  You may 
override this by prepending C<+> to the class name.

The class will be applied to your class as a role.  The helper will also
make sure that the class provides the appropriate role.

=over 4

=item interface

The interface defines how HTTP requests are mapped to actions on resources.

Available interfaces: REST.

=item protocol

The protocol is how the RDF server communicates with the world.

Available protocols: Embedded, HTTP.  FCGI is experimental.
(Apache2 is on the TODO list.)

=item semantic

The server semantic determines how the RDF stores are structured and 
presented in documents by managing how the handler is configured.

Available semantics: Atom, RDF.

=item render

The interface maps file types to formatters using the mappings defined by the
C<render> method.

=back

=head1 OBJECT METHODS

=over 4

=item formatter

This will return the formatter for a particular file format as defined by the
C<render> method.

=back

=head1 CONFIGURATION

=over 4

=item default_rendering

This determines the default file format when none is provided.  The file format
should map to a formatter defined by the C<render> method in the class
definition.

=item handler

This object is used by the interface to find the proper handler for a
request.  This object must inherit from RDF::Server::Handler.

The server semantic can redefine the handler type and provide a way to 
configure the handler from a configuration file or Perl data structure.

=back

=for readme continue

=head1 NAMESPACE DESIGN

The RDF::Server namespace is divided into these broad areas:

=over 4

=item Protocol

Modules in RDF::Server::Protocol provide the interface with the world.  Examples
include HTTP, Apache/mod_perl, and FastCGI.

=item Interface

RDF::Server::Interface modules determine the type of URI and HTTP method 
management that is used.  RDF::Server comes with a REST interface.

=item Semantic

RDF::Server::Semantic modules manage the configuration and interpretation 
of URIs once the Interface module has passed the request on.  RDF::Server 
comes with an Atom semantic of URI heirarchies and configuration.

=item Formatter

RDF::Server::Formatter modules translate the internal data structures to
particular document types.  The formatter for a request is selected by the
Interface module.

=item Model

RDF::Server::Model modules interface between the Semantic and Formatter 
modules and the backend triple store.

=item Resource

RDF::Server::Resource modules represent particular resources and associated 
data within a triple store.

=back

=for readme stop

=head1 SEE ALSO

L<Moose>,
L<RDF::Server::Formatter>,
L<RDF::Server::Interface>,
L<RDF::Server::Model>,
L<RDF::Server::Protocol>,
L<RDF::Server::Resource>,
L<RDF::Server::Semantic>.

=for readme continue

=head1 BUGS

There are bugs.  The test suite only covers a little over 90% of the code.
Bugs may be reported on rt.cpan.org or by e-mailing bug-RDF-Server at
rt.cpan.org.

=head1 AUTHOR
        
James Smith, C<< <jsmith@cpan.org> >>
            
=head1 LICENSE
            
Copyright (c) 2008  Texas A&M University.
            
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut

