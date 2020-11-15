package Package::Role::ini;
use strict;
use warnings;
use Path::Class qw{};
use Config::IniFiles qw{};

our $VERSION = '0.07';

=head1 NAME

Package::Role::ini - Perl role for "ini" object the returns a Config::IniFiles object

=head1 SYNOPSIS

Configure INI file

  /etc/my-package.ini
  [section]
  entry=my_value

Package

  package My::Package;
  use base qw{Package::New Package::Role::ini};

  sub my_method {
    my $self  = shift;
    my $value = $self->ini->val('section', 'entry', 'default');
    return $value
  }

=head1 DESCRIPTION

Perl role for "ini" object that returns a Config::IniFiles object against a default INI file name and location

=head1 OBJECT ACCESSORS

=head2 ini

Returns a lazy loaded L<Config::IniFiles> object so that you can read settings from the INI file.

  my $ini = $object->ini; #isa Config::IniFiles

=cut

sub ini {
  my $self = shift;
  unless ($self->{'ini'}) {
    my $file       = $self->ini_file;
    $self->{'ini'} = Config::IniFiles->new(-file=>"$file");
  }
  return $self->{'ini'};
}

=head1 METHODS

=head2 ini_file

Sets or returns the profile INI filename

  my $file = $object->ini_file;
  my $file = $object->ini_file("./my.ini");

Set on construction

  my $object = My::Class->new(ini_file=>"./my.ini");

Default is the object lower case class name replacing :: with - and adding ".ini" extension. In other words, for the package My::Package the default location on Linux would be /etc/my-package.ini.

override in sub class

  sub ini_file {"/path/my.ini"};

=cut

sub ini_file {
  my $self = shift;
  if (@_) {
    $self->{'ini_file'} = shift;
    delete($self->{'ini'}); #delete cached Config::IniFiles
  }
  $self->{'ini_file'} = Path::Class::file($self->ini_path, $self->ini_file_default) unless defined $self->{'ini_file'};
  #Config::IniFiles will catch the error if ini file is not valid.
  return $self->{'ini_file'};
}

=head2 ini_path

Sets and returns the path for the INI file.

  my $path = $object->ini_path;                  #isa Str
  my $path = $object->ini_path("../other/path"); #isa Str

Default: C:\Windows            on Windows-like systems that have Win32 installed
Default: /etc                  on systems that have /etc
Default: Sys::Path->sysconfdir on systems that Sys::Path installed
Default: .                     otherwise

override in sub class

  sub ini_path {"/my/path"};

=cut

sub ini_path {
  my $self        = shift;
  if (@_) {
    $self->{'ini_path'} = shift;
    delete($self->{'ini'}); #delete cached Config::IniFiles
  }
  unless (defined $self->{'ini_path'}) { #both "" and "0" are valid paths
    my $etc = $self->_ini_path_etc;
    if ($^O eq 'MSWin32') {
      local $@;
      eval('use Win32');
      $self->{'ini_path'} = eval('Win32::GetFolderPath(Win32::CSIDL_WINDOWS)') unless $@;
    } elsif (-d $etc and -r $etc) {
      $self->{'ini_path'} = $etc;
    } else {
      local $@;
      eval('use Sys::Path');
      $self->{'ini_path'} = eval('Sys::Path->sysconfdir') unless $@;
    }
    $self->{'ini_path'} = '.' unless defined($self->{'ini_path'}); #fallback is current directory
  }
  return $self->{'ini_path'};
}

sub _ini_path_etc {'/etc'};

=head2 ini_file_default

Default: lc(__PACKAGE__)=~s/::/-/g

=cut

sub ini_file_default {
  my $self = shift;
  if (@_) {
    $self->{'ini_file_default'} = shift;
    delete($self->{'ini'}); #delete cached Config::IniFiles
  }
  unless ($self->{'ini_file_default'}) {
    my $ext                 = $self->ini_file_default_extension;
    my $file                = lc(ref($self));
    $file                   =~ s/::/-/g;
    $file                   = $file . '.' . $ext if defined($ext);
    $self->{'ini_file_default'} =  $file;
  }
  return $self->{'ini_file_default'};
}

=head2 ini_file_default_extension

Default: ini

=cut

sub ini_file_default_extension {
  my $self = shift;
  if (@_) {
    $self->{'ini_file_default_extension'} = shift;
    delete($self->{'ini'}); #delete cached Config::IniFiles
  }
  unless (exists $self->{'ini_file_default_extension'}) {
    $self->{'ini_file_default_extension'} =  'ini';
  }
  return $self->{'ini_file_default_extension'};
}

=head1 SEE ALSO

L<Config::IniFiles>, L<Package::New>

=head1 AUTHOR

Michael R. Davis, mrdvt92

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Michael R. Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
