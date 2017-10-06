#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

use Perl::PrereqScanner;

my $catalyst_app_module_content = <<'END_OF_TEXT';

package MyApp;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
    +Fully::Qualified::Plugin::Name
/;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'MyApp',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
);

# Start the application
__PACKAGE__->setup('Foo', -SomethingElse);
__PACKAGE__->setup_plugins('Bar', qw/~Baz Qux/);

1;
END_OF_TEXT

my $scanner = Perl::PrereqScanner->new( { extra_scanners => [qw(Catalyst)] } );
my $prereqs = $scanner->scan_string($catalyst_app_module_content);
my @modules = sort $prereqs->required_modules;

is_deeply(
    \@modules,
    [
        sort qw(
          Catalyst
          Catalyst::Runtime
          Moose
          namespace::autoclean
          Catalyst::Plugin::ConfigLoader
          Catalyst::Plugin::Static::Simple
          Catalyst::Plugin::Foo
          Catalyst::Plugin::Bar
          Catalyst::Plugin::Qux
          MyApp::Plugin::Baz
          Fully::Qualified::Plugin::Name
          )
    ],
    "scan a Catalyst app module code"
);

done_testing;
