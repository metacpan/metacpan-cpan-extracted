use inc::Module::Install;

name 'RDF-Server';
all_from 'lib/RDF/Server.pm';

if( $^O eq 'Win32' or $^O eq 'cygwin' ) {
    print STDERR "\n   RDF::Server isn't developed on or expected to work on Windows\n\n";
    exit 0 if $ENV{'AUTOMATED_TESTING'};
}

##
# offer choices for the following few
##

# for RDFCore interfacing modules
feature 'RDF::Core',
  -default => 0,
  'RDF::Core' => 0.51;

# for JSON formatter
feature 'JSON Formatting',
  -default => 0,
  'JSON::Any' => 1.16;

# for HTTP protocol handler
feature 'HTTP Protocol',
  -default => 0,
  'MooseX::Daemonize' => 0.06,
  'POE::Component::Server::HTTP' => 0.09;

# for FastCGI protocol support
feature 'FastCGI',
  -default => 0,
  'MooseX::Daemonize' => 0.06,
  'FCGI' => 0.67;

###
# Following are basic modules
###

requires 'Moose' => 0.40; # at least 0.25 fails
requires 'Class::MOP' => 0.53;
requires 'Sub::Exporter' => 0.978;
requires 'Sub::Name' => 0.03;
requires 'MooseX::Types' => 0.04;

requires 'HTTP::Status' => 1.28;
requires 'HTTP::Request' => 1.40;
requires 'HTTP::Response' => 1.53;

requires 'DateTime' => 0.42;

requires 'XML::LibXML' => 1.66;

requires 'Log::Log4perl' => 1.15;

###
# for Model
###
requires 'Iterator::Simple' => 0.04;
requires 'Data::UUID' => 1.148;

###
# for Resource
###
requires 'XML::Simple' => 2.18;


build_requires 'Test::More' => 0.72;
build_requires 'Test::Moose' => 0.01;
build_requires 'Path::Class::File';


tests('t/*.t t/*/*.t');
author_tests('xt');

install_script glob('script/*.pl');

auto_install;
WriteAll;
