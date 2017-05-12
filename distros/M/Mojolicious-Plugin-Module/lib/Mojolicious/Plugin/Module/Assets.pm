package Mojolicious::Plugin::Module::Assets;
use Mojo::Base -base;
use Mojo::Util qw/decamelize/;
use File::Copy::Recursive qw/dircopy/;
use FindBin;
use Carp;

sub init {
  my ($self, $app) = @_;
  # Does not support Mojolicious Lite.
  return if $app->isa('Mojolicious::Lite');
  my $app_path = $app->home;
  while (my($name, $mod) = each %{ $app->module->modules }) {
    my $path = $mod->config->{path};
    dircopy("$path/assets", "$app_path/public/assets") or
      croak("Can't copy $path/assets to $app_path/public") if -d "$path/assets";
  }
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::Module::Assets - work with assets.

=head1 OVERVIEW

If your module has some static files, which should be able from C<public> directory, use C<assets>
folder. On each application startup assets will be added to C<./public/assets> of your
application (does not work with Mojolicious::Lite).

=head1 SEE ALSO

L<Mojolicious::Plugin::Module::Abstract>, L<Mojolicious::Plugin::Module::Manager>,
L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut