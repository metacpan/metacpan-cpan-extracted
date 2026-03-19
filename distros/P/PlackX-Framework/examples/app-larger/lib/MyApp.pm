#!perl
use v5.36;
package MyApp {
  # We use the framework and turn on optional features
  use PlackX::Framework qw(:Template :URIx);

  # PXF's template module looks for templates in ./template and ./templates
  # by default, but since we might be running this app from a difference
  # working directory, we will explicitly specify it
  use MyApp::Template { INCLUDE_PATH => "$FindBin::Bin/templates" };

  # Some global filters and routes are contained in the modules below;
  # the names of the packages are arbitrary, so long as they import from
  # MyApp::Router
  use MyApp::GlobalFilters;
  use MyApp::Controllers;

  # Set a prefix as an example
  sub uri_prefix { '/example-base' }
}

1;
