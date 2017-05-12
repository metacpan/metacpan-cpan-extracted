package Mojolicious::Plugin::Module::Manager;
use Mojo::Base -base;
use Mojo::Util qw/camelize decamelize/;
use YAML;
use Carp 'croak';
use Module::Load;
use FindBin;

has modules => sub {{}};
has mod_dir => '';
has 'app';

sub init {
  my ($self, $app, $conf) = @_;
  my $path = $app->home;
  my $conf_dir = $conf->{conf_dir};
  $self->mod_dir($conf->{mod_dir});
  $self->app($app);
  
  open(my $fh, "$path/$conf_dir/application.yaml") or
    croak "Can't find '$path/$conf_dir/application.yaml'";
  local $/;
  my ($app_conf) = Load(<$fh>);
  close $fh;
  
  $self->add($_) for @{ $app_conf->{modules} };
  
  $app->helper(module => sub { $self });
}

sub add {
  my ($self, $name, $module) = @_;
  croak "Trying to reload module \"$name\"!\n" if exists $self->modules->{$name};
  return $self->modules->{$name} = $module if $module;
  
  my $dir = $self->app->home;
  my $path = decamelize $name;
  $path =~ s/-/\//;
  $path = $dir.'/'.$self->mod_dir.'/'.$path;
  
  @::INC = ("$path/lib", @::INC);
  load $name;
  
  my $mod = $name->new;
  $mod->init($self->app, $path);
  $self->modules->{$name} = $mod;
}

sub get {
  my ($self, $name) = @_;
  return exists $self->modules->{$name} ? $self->modules->{$name} : undef;
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::Module::Manager - module manager for Mojolicious.

=head1 OVERVIEW

Module manager contains modules and provides methods for access.

=head2 Methods

=head3 init($self, $app, $conf)

=over

=item $app

Mojolicious application.

=item $conf

Keys: C<conf_dir> - directory with C<application.yaml>, C<mod_dir> - directory with modules.

=back

=head3 add($self, $name, $module)

=over

=item $name

Module name (package).

=item $module

Module object or undef.

=back

=head3 get($self, $name)

=over

=item $name

Module name (package).

=back

=head1 SEE ALSO

L<Mojolicious::Plugin::Module>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
