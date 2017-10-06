#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

use Perl::PrereqScanner;

my $catalyst_controller_module_content = <<'END_OF_TEXT';
package MyApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
END_OF_TEXT

my $scanner = Perl::PrereqScanner->new( { extra_scanners => [qw(Catalyst)] } );
my $prereqs = $scanner->scan_string($catalyst_controller_module_content);
my @modules = sort $prereqs->required_modules;

is_deeply(
    \@modules,
    [
        sort qw(
          Catalyst::Action::RenderView
          Catalyst::Controller
          Moose
          namespace::autoclean
          )
    ],
    "scan a Catalyst controller module code"
);

done_testing;
