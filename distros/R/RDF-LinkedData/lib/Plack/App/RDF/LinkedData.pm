package Plack::App::RDF::LinkedData;
use strict;
use warnings;
use parent qw( Plack::Component );
use RDF::LinkedData;
use URI::NamespaceMap;
use Plack::Request;
use Try::Tiny;
use Carp;
use Module::Load::Conditional qw[can_load];

=head1 NAME

Plack::App::RDF::LinkedData - A Plack application for running RDF::LinkedData

=head1 VERSION

Version 1.92

=cut

 our $VERSION = '1.92';


=head1 SYNOPSIS

  my $linkeddata = Plack::App::RDF::LinkedData->new();
  $linkeddata->configure($config);
  my $rdf_linkeddata = $linkeddata->to_app;

  builder {
     enable "Head";
	  enable "ContentLength";
	  enable "ConditionalGET";
	  $rdf_linkeddata;
  };

=head1 DESCRIPTION

This module sets up a basic Plack application to use
L<RDF::LinkedData> to serve Linked Data, while making sure it does
follow best practices for doing so. See the README for quick start,
the gory details are here.

=head1 MAKE IT RUN

=head2 Quick setup for a demo

=head3 One-liner

It is possible to make it run with a single command line, e.g.:

  PERLRDF_STORE="Memory;path/to/some/data.ttl" plackup -host localhost script/linked_data.psgi

This will start a server with the default config on localhost on port
5000, so the URIs you're going serve from the file data.ttl will have
to have a base URI C<http://localhost:5000/>.

There is also a C<LOG_ADAPTER> that can be set to any of
L<Log::Any::Adapter> to send logging to the console. If used with
L<Log::Any::Adapter::Screen>, several other environment variables can
be used to further control it.

=head3 Using perlrdf command line tool

A slightly longer example requires L<App::perlrdf>, but sets up a
persistent SQLite-based triple store, parses a file and gets the
server with the default config running:

  export PERLRDF_STORE="DBI;mymodel;DBI:SQLite:database=rdf.db"
  perlrdf make_store
  perlrdf store_load path/to/some/data.ttl
  plackup -host localhost script/linked_data.psgi

=head2 Configuration

To configure the system for production use, create a configuration
file C<rdf_linkeddata.json> that looks something like:

  {
        "base_uri"  : "http://localhost:3000/",
        "store" : {
                   "storetype"  : "Memory",
                   "sources" : [ {
                                "file" : "/path/to/your/data.ttl",
                                "syntax" : "turtle"
                               } ]

                   },
        "endpoint": {
        	"html": {
	                 "resource_links": true
	                }
                    },
        "expires" : "A86400" ,
        "cors": {
                  "origins": "*"
                },
        "void": {
                  "pagetitle": "VoID Description for my dataset"
                },
        "fragments" : { "fragments_path" : "/fragments" }
  }

In your shell set

  export RDF_LINKEDDATA_CONFIG=/to/where/you/put/rdf_linkeddata.json

Then, figure out where your install method installed the
<linked_data.psgi>, script, e.g. by using locate. If it was installed
in C</usr/local/bin>, go:

  plackup /usr/local/bin/linked_data.psgi --host localhost --port 3000

The C<endpoint>-part of the config sets up a SPARQL Endpoint. This requires
the L<RDF::Endpoint> module, which is recommended by this module. To
use it, it needs to have some config, but will use defaults.

It is also possible to set an C<expires> time. This needs
L<Plack::Middleware::Expires> and uses Apache C<mod_expires> syntax,
in the example above, it will set an expires header for all resources
to expire after 1 day of access.

The C<cors>-part of the config enables Cross-Origin Resource
Sharing, which is a W3C Recommendation for relaxing security
constraints to allow data to be shared across domains. In most cases,
this is what you want when you are serving open data, but in some
cases, notably intranets, this should be turned off by removing this
part.

The C<void>-part generates some statistics and a description of the
dataset, using RDF::Generator::Void. It is strongly recommended to
install and run that, but it can take some time to generate, so you
may have to set the detail level.

Finally, C<fragments> add support for Triple Pattern Fragments, a
work-in-progress, It is a more lightweight but less powerful way to
query RDF data than SPARQL. If you have this, it is recommended to
have CORS enabled and required to have at least a minimal VoID setup.

Note that in some environments, for example if the Plack server
is dynamically configured and/or behind a proxy server, the server
may fail to bind to the address you give it as hostname. In this case,
it is wise to allow the server to bind to any public IP address,
i.e. set the host name to 0.0.0.0.

=head2 Details of the implementation

This server is a minimal Plack-script that should be sufficient for
most linked data usages, and serve as a an example for most others.

A minimal example of the required config file is provided above. There
is are longer examples in the distribution, which is used to run
tests. In the config file, there is a C<store> parameter, which must
contain the L<RDF::Trine::Store> config hashref. It may also have a
C<base_uri> URI and a C<namespace> hashref which may contain prefix -
URI mappings to be used in serializations. Certain namespace, namely
RDF, VoID, Hydra, DC Terms and XML Schema are added by the module and
do not need to be declared.


Note that this is a server that can only serve URIs of hosts you
control, it is not a general purpose Linked Data manipulation tool,
nor is it an implementation of Linked Data Platform or the Linked Data
API.

The configuration is done using L<Config::ZOMG> and all its features
can be used. Importantly, you can set the C<RDF_LINKEDDATA_CONFIG>
environment variable to point to the config file you want to use. See
also L<Catalyst::Plugin::ConfigLoader> for more information on how to
use this config system.

=head2 Behaviour

The following documentation is adapted from RDF::LinkedData::Apache,
which preceded this module.

=over 4 

=item * C<http://host.name/rdf/example>

Will return an HTTP 303 redirect based on the value of the request's
Accept header. If the Accept header contains a recognized RDF media
type or there is no Accept header, the redirect will be to
C<http://host.name/rdf/example/data>, otherwise to
C<http://host.name/rdf/example/page>. If the URI has a foaf:homepage
or foaf:page predicate, the redirect will in the latter case instead
use the first encountered object URI.

=item * C<http://host.name/rdf/example/data>

Will return a bounded description of the C<http://host.name/rdf/example>
resource in an RDF serialization based on the Accept header. If the Accept
header does not contain a recognized media type, RDF/XML will be returned.

=item * C<http://host.name/rdf/example/page>

Will return an HTML description of the C<http://host.name/rdf/example>
resource including RDFa markup, or, if the URI has a foaf:homepage or
foaf:page predicate, a 301 redirect to that object.

=back

If the RDF resource for which data is requested is not the subject of any RDF
triples in the underlying triplestore, the /page and /data redirects will not take
place, and a HTTP 404 (Not Found) will be returned.

The HTML description of resources will be enhanced by having metadata
about the predicate of RDF triples loaded into the same
triplestore. Currently, only a C<rdfs:label>-predicate will be used
for a title, as in this version, generation of HTML is done by
L<RDF::RDFa::Generator>.

=head2 Endpoint Usage

As stated earlier, this module can set up a SPARQL Endpoint for the
data using L<RDF::Endpoint>. Often, that's what you want, but if you
don't want your users to have that kind of power, or you're worried it
may overload your system, you may turn it off by simply having no
C<endpoint> section in your config. To use it, you just need to have
an C<endpoint> section with something in it, it doesn't really matter
what, as it will use defaults for everything that isn't set.

L<RDF::Endpoint> is recommended by this module, but as it is optional,
you may have to install it separately. It has many configuration
options, please see its documentation for details.

You may also need to set the C<RDF_ENDPOINT_SHAREDIR> variable to
wherever the endpoint shared files are installed to. These are some
CSS and Javascript files that enhance the user experience. They are
not strictly necessary, but it sure makes it pretty! L<RDF::Endpoint>
should do the right thing, though, so it shouldn't be necessary.

Finally, note that while L<RDF::Endpoint> can serve these files for
you, this module doesn't help you do that. That's mostly because this
author thinks you should serve them using some other parts of the
deployment stack. For example, to use Apache, put this in your Apache
config in the appropriate C<VirtualHost> section:


  Alias /js/ /path/to/share/www/js/
  Alias /favicon.ico /path/to/share/www/favicon.ico
  Alias /css/ /path/to/share/www/css/

=head2 VoID Generator Usage

Like a SPARQL Endpoint, this is something most users would want. In
fact, it is an even stronger recommendation than an endpoint. To
enable it, you must have L<RDF::Generator::Void> installed, and just
anything in the config file to enable it, like in the SYNOPSIS example.

You can set several things in the config, the property attributes of
L<RDF::Generator::Void> can all be set there somehow. You can also set
C<pagetitle>, which sets the title for the RDFa page that can be
generated. Moreover, you can set titles in several languages for the
dataset using C<titles> as the key, pointing to an arrayref with
titles, where each title is a two element arrayref, where the first
element is the title itself and the second is the language for that
title.

Please refer to the L<RDF::Generator::Void> for more details about
what can be set, and the C<rdf_linkeddata_void.json> test config in
the distribution for example.

By adding an C<add_void> config key, you can make pass a file to the
generator so that arbitrary RDF can be added to the VoID
description. It will check the last modification time of the file and
only update the VoID description if it has been modified. This is
useful since as much of the VoID description is expensive to
compute. To use it, the configuration would in JSON look something
like this:

	"add_void": { "file": "/data/add.ttl", "syntax": "turtle" }

where C<file> is the full path to RDF that should be added and
C<syntax> is needed by the parser to parse it.

Normally, the VoID description is cached in RAM and the store ETag is
checked on every request to see if the description must be
regenerated. If you use the C<add_void> feature, you can force
regeneration on the next request by touching the file.

=head2 Read-write support

Some recent effort has gone into experimental write support, which for
this module has the implications that a boolean option
C<writes_enabled> that configures the application for writes. This is
also meant as security, unless set to true, writes will never be
performed. To support writes, a C<class> option can be set with a
class name, which can be instantiated to replace
L<RDF::LinkedData>. See L<RDF::LinkedData::RWHypermedia> for more on
this.

=head1 FEEDBACK WANTED

Please contact the author if this documentation is unclear. It is
really very simple to get it running, so if it appears difficult, this
documentation is most likely to blame.



=head1 METHODS

You would most likely not need to call these yourself, but rather use
the C<linked_data.psgi> script supplied with the distribution.

=over

=item C<< configure >>

This is the only method you would call manually, as it can be used to
pass a hashref with configuration to the application.

=cut

sub configure {
	my $self = shift;
	$self->{config} = shift;
	return $self;
}


=item C<< prepare_app >>

Will be called by Plack to set the application up.

=item C<< call >>

Will be called by Plack to process the request.

=cut


sub prepare_app {
	my $self = shift;
	my $config = $self->{config};
	if (defined $config->{'class'}) {
	  my $class = $config->{'class'};
	  unless (can_load( modules => { $class => 0 })) {
		 croak "Configured $class cannot be loaded, is it installed?";
	  }
	  try {
		 $self->{linkeddata} = $class->new($config);
	  } catch {
		 croak "Application cannot use $class as configured.";
	  };
	  croak "Configured $class not a subclass of RDF::LinkedData" unless ($self->{linkeddata}->isa('RDF::LinkedData'));
	} else {
	  $self->{linkeddata} = RDF::LinkedData->new($config);
	}
	$self->{linkeddata}->namespaces(URI::NamespaceMap->new($config->{namespaces})) if ($config->{namespaces});
	# Ensure that certain namespaces are always declared
	$self->{linkeddata}->guess_namespaces('rdf', 'dc', 'xsd', 'void');
	$self->{linkeddata}->add_namespace_mapping(hydra => 'http://www.w3.org/ns/hydra/core#');
}

sub call {
	my($self, $env) = @_;
	my $req = Plack::Request->new($env);
	my $uri = $req->uri;
	my $ld = $self->{linkeddata};

	# Never return 405 here if writes are enabled by config, only do it if there isn't a read operation and writes are not enabled
	my $does_read_operation = $self->does_read_operation($req);
	$ld->does_read_operation($does_read_operation);
	unless ($does_read_operation || $self->{config}->{writes_enabled}) {
		return [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ];
	}

	if (($uri->path eq '/.well-known/void') && ($ld->has_void)) {
		return [ 302, [ 'Location', $ld->base_uri . '/' ], [ '' ] ];
	}

	if ($uri->as_iri =~ m!^(.+?)/?(page|data|controls)$!) {
	  $uri = URI->new($1);
	  $ld->type($2);
	} else {
	  $ld->type('');
	}
	$ld->request($req);
	return $ld->response($uri)->finalize;
}

=item C<< auth_required ( $request ) >>

A method that returns true if the current request will require authorization.

=cut

sub auth_required {
	my ($self, $req) = @_;
	return ($self->{config}->{writes_enabled} && (! $self->does_read_operation($req)));
}

=item C<< does_read_operation ( $request ) >>

A method that will return true if the current request is a pure read operation.

=cut

sub does_read_operation {
	my ($self, $req) = @_;
	my $uri = $req->uri;
	my $endpoint_path;
	my $ld = $self->{linkeddata}; # Might be a performance problem
	if ($ld->has_endpoint) {
	  $endpoint_path = $ld->endpoint_config->{endpoint_path};
	}
	return (($req->method eq 'GET') || ($req->method eq 'HEAD')
			  || (($req->method eq 'POST') && defined($endpoint_path) && ($uri =~ m|$endpoint_path$|)))
}

1;


=back

=head1 AUTHOR

Kjetil Kjernsmo, C<< <kjetilk@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kjetil Kjernsmo

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
