package Silki::Controller::Root;
{
  $Silki::Controller::Root::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Moose;

BEGIN { extends 'Silki::Controller::Base' }

__PACKAGE__->config( namespace => q{} );

sub robots_txt : Path('/robots.txt') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $c->response()->content_type('text/plain');
    $c->response()->body("User-agent: *\nDisallow: /\n");
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Controller class for the root of the URI namespace

__END__
=pod

=head1 NAME

Silki::Controller::Root - Controller class for the root of the URI namespace

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

