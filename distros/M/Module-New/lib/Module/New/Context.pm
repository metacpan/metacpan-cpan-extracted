package Module::New::Context;

use strict;
use warnings;
use Carp;

use Module::New::Loader;
use Module::New::Log;
use Sub::Install 'reinstall_sub';
use Time::Piece;

foreach my $accessor (qw( template date path loader files )) {
  reinstall_sub({
    as   => $accessor,
    code => sub { shift->{$accessor} },
  });
}

sub new {
  my $class = shift;

  my $loader = Module::New::Loader->new(@_);
  my $self = bless { loader => $loader }, $class;

  foreach my $name (qw( License Template )) {
    $self->{lc $name} = $loader->load_class($name);
  }

  foreach my $name (qw( Config Path Files )) {
    $self->{lc $name} = $loader->load($name);
  }

  $self->{date} = Time::Piece->new;

  $self;
}

sub config {
  my $self = shift;
  return $self->{config} unless @_;
  return $self->{config}->get(@_) if @_ == 1;
  $self->{config}->set(@_);
}

sub license {
  my ($self, $type, $args) = @_;
  $type ||= $self->config('license') || 'perl';
  $args ||= {};
  $args->{holder} ||= $self->config('author');
  $args->{year} ||= $self->date->year;
  $self->{license}->object( $type, $args );
}

sub distname {
  my $self = shift;

  if ( @_ ) {
    my $module = my $dist = shift;
    $dist   =~ s/::/\-/g;
    $module =~ s/\-/::/g;

    croak "$dist looks weird" if $dist =~ tr/A-Za-z0-9_\-//cd;

    my $distid = lc $dist;
       $distid =~ s/\-/_/g;

    $self->{distname} = $dist;
    $self->{distid}   = $distid;
    $self->module( $module );
  }

  $self->{distname};
}

sub module {
  my $self = shift;

  if ( @_ ) {
    $self->{module} = shift;
    my $path = $self->{module};
       $path =~ s|::|\/|g;
    my $id   = lc $path;
       $id   =~ s|/|_|g;
    $self->mainfile("lib/$path.pm");
    $self->modulepath($path);
    $self->moduleid($id);
  }
  $self->{module};
}

sub mainfile {
  my $self = shift;
  if ( @_ ) {
    $self->{mainfile} = shift;
  }
  $self->{mainfile};
}

sub maindir {
  my $self = shift;
  my $dir = $self->{mainfile};
     $dir =~ s/\.pm$//;
  return $dir;
}

sub modulepath {
  my $self = shift;
  if ( @_ ) {
    $self->{modulepath} = shift;
  }
  $self->{modulepath};
}

sub moduleid {
  my $self = shift;
  if ( @_ ) {
    $self->{moduleid} = shift;
  }
  $self->{moduleid};
}

sub modulebase {
  my $self = shift;
  my ($name) = $self->{module} =~ /(\w+)$/;
  return $name;
}

sub distid {
  my $self = shift;
  if ( @_ ) {
    $self->{distid} = shift;
  }
  $self->{distid};
}

sub repository {
  my $self = shift;
  if ( @_ ) {
    $self->{repository} = shift;
  }
  $self->{repository} || '';
}

*dist_name   = \&distname;
*dist_id     = \&distid;
*main_file   = \&mainfile;
*main_dir    = \&maindir;
*module_path = \&modulepath;
*module_id   = \&moduleid;
*module_base = \&modulebase;

1;

__END__

=head1 NAME

Module::New::Context

=head1 SYNOPSIS

  my $context = Module::New->context;
  my $value = $context->config('foo');
  my $distribution = $context->distname;  # Some-Distribution-Name
  $context->module('Some::Module::Name');

=head1 DESCRIPTION

This is used to hold various information on a distribution/module.

=head1 METHODS

=head2 new

creates an object.

=head2 config

returns a ::Config object if there's no argument, and returns an appropriate config value with an argument. If you pass more arguments, you can update the configuration temporarily (if you want to keep the values permanently, use C<-E<gt>config-E<gt>save(@_)> instead).

=head2 license

takes a license name (and an optional hash reference for Software::License) and returns a Software::License object (perl license by default).

=head2 distname, dist_name

holds a distribution name you passed to the command.

=head2 distid, dist_id

holds a distribution id, which is the lowercased distribution name, replaced hyphens with underscores.

=head2 module

holds a main module name you passed to the command (or the one converted from a distribution name).

=head2 mainfile, main_file

holds a main module file path.

=head2 maindir, main_dir

holds a main module directory path.

=head2 moduleid, module_id

holds a main module id, which is the lowercased module name, replaced double colons with underscores.

=head2 modulepath, module_path

holds a main module directory path, without prepending "lib".

=head2 modulebase, module_base

holds a basename of the main module, without ".pm".

=head2 repository

holds a repository url.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
