package Plack::Middleware::DirIndex;
$Plack::Middleware::DirIndex::VERSION = '1.00';
# ABSTRACT: Append an index file to request PATH's ending with a /

use parent qw( Plack::Middleware );
use Plack::Util::Accessor qw(dir_index);
use strict;
use warnings;
use 5.006;

=head1 NAME

Plack::Middleware::DirIndex - Middleware to use with Plack::App::Directory and the like

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::App::File;
  use Plack::Middleware::DirIndex;

  my $app = Plack::App::File->new({ root => './htdocs/' })->to_app;

  builder {
        enable "Plack::Middleware::DirIndex", dir_index => 'index.html';
        $app;
  }
  
=head1 DESCRIPTION

If $env->{PATH_INFO} ends with a '/' then we will append the dir_index
value to it (defaults to index.html)

=head1 COPYRIGHT & LICENSE
Copyright (c) 2012 Leo Lapworth. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

sub prepare_app {
    my ($self) = @_;

    $self->dir_index('index.html') unless $self->dir_index;
}

sub call {
    my ( $self, $env ) = @_;

    if ( $env->{PATH_INFO} =~ m{/$} ) {
        $env->{PATH_INFO} .= $self->dir_index();
    }

    return $self->app->($env);
}

1;
