package Module::Build::Mojolicious;

use strict;
use warnings;

our $VERSION = '0.03';
$VERSION = eval $VERSION;

use File::Spec;
use Module::Build;
our @ISA = 'Module::Build';

our $Clean_Install = 0;

sub import {
  my $class = shift;
  my %args = ref $_[0] ? %{ shift() } : @_;

  if (defined $args{clean_install}) {
    $Clean_Install = $args{clean_install};
  }

  if ($Clean_Install) {
    require Module::Build::CleanInstall;
    @ISA = 'Module::Build::CleanInstall';
  } 
}

sub share_dir {
  my $self = shift;
  my $share_dir = $self->SUPER::share_dir(@_);

  unless ( $self->notes( 'mojolicious_added' ) ) {

    my $path = File::Spec->catdir( 
      $self->base_dir, 'lib', split( /::/, $self->module_name ), 'files'
    );

    return $share_dir unless -d $path;

    push @{ $share_dir->{dist} }, $path;
    $self->SUPER::share_dir($share_dir);
    $self->notes( mojolicious_file_path => $path );
    $self->notes( mojolicious_added     => 1     );

  }

  return $share_dir;
}

1;

=head1 NAME

Module::Build::Mojolicious

=head1 SYNOPSIS

 # Build.PL
 use Module::Build::Mojolicious clean_install => 1;
 my $builder = Module::Build::Mojolicious->new(
   configure_requires => {
     'Module::Build::Mojolicious' => 0,
     'Module::Build' => 0.38,
   },
   ...
 );
 $builder->create_build_script;

=head1 DESCRIPTION

A subclass of L<Module::Build> for use with L<Mojolicious>. See L<Mojolicious::Plugin::InstallablePaths> for more documentation.

Note that you should add it to the C<configure_requires> key as you should for any module used in a C<Build.PL> file.

=head1 OPTIONS

If imported with the option C<< clean_install => 1 >>, L<Module::Build::CleanInstall> will be inserted into the inheritance tree at import time. This module ensures that old files are removed before upgrading an already installed module. The author recommends this option be enabled.

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojolicious-Plugin-InstallablePaths>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



