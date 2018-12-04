
# Mojolicious::Plugin::DBIC Example

This is an example application that demonstrates the utility of this
plugin.

## Setup

This example uses [Carton](http://metacpan.org/pod/Carton) to install
its dependencies. To install the dependencies, first install Carton
using `cpan Carton` and then:

    carton install

To generate a new database:

    carton exec ./myapp.pl eval 'app->schema->deploy'

## Running

To run the web application:

    carton exec ./myapp.pl daemon

