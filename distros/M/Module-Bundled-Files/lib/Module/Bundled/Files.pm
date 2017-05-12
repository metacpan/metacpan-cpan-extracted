#!/usr/bin/perl -w
package Module::Bundled::Files;

use warnings;
use strict;

use File::Spec::Functions;
use Class::ISA;

=head1 NAME

Module::Bundled::Files - Access files bundled with Module

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS


Access files installed with your module without needing to specify
an install location on the target filesystem.

=head2 Setup

In I<Build.PL>:

  my $build = new Module::Build(...);
  map{$build->add_build_element($_);}
    qw{txt html tmpl};
  # installs all .txt, .html and .tmpl files found in the lib/ tree
  
Create files:

  Build.PL
  lib/
    My/
      Module.pm
      Module/
        index.html
        data.txt
        form.tmpl
  
=head2 Object-Oriented Interface

  use base qw{Module::Bundled::Files};
  
  if($self->mbf_exists('data.txt')){...}
  
  my $filename = $self->mbf_path('data.txt');
  # $filename = '/usr/local/share/perl/5.8.7/My/Module/data.txt';
  open my $fh, '<', $filename or die $@;
  
  my $fh = $self->mbf_open('data.txt');
  while(<$fh>)
  {
    ...
  }
  
  my $data = $self->mbf_read('data.txt');

=head2 Non-Object-Oriented Interface

  use Module::Bundled::Files qw{:all};
  my $object = new Other::Object;

  if(mf_exists($other,'otherfile.txt')){...}

  my $filename = mbf_path($object,'otherfile.txt');

  open my $fh, '<', $filename or die $@;
  
  my $fh = mbf_open($object,'otherfile.txt');
  while(<$fh>)
  {
    ...
  }
  
  my $data = mbf_read($object,'otherfile.txt');
  
=cut

=head1 DESCRIPTION

This module provides an simple method of accessing files that need to be 
bundled with a module.

For example, a module My::Module, which needs to access a seperate file 
I<data.txt>.

In your development directory you would place your I<data.txt> in your 
I<lib/My/Module/> directory.

  lib/
    My/
      Module.pm
      Module/
        data.txt

Using I<add_build_element(...)> in your I<Build.PL> file allows the 
I<data.txt> file to be installed in the same relative location.

The file(s) can then be accessed using the I<mbf_*> functions provided by
this module.

=head1 EXPORT

The following functions can be exported if you will not be using the
Object-Oriented Interface.

  :all
    mbf_validate
    mbf_dir
    mbf_exists
    mbf_path
    mbf_open
    mbf_read

=cut

use base 'Exporter';
our @EXPORT_OK = qw{mbf_validate mbf_dir mbf_exists mbf_path mbf_open mbf_read};
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

=head1 FUNCTIONS

=head2 mbf_validate(FILENAME)

Returns true if the filename does not contain illegal sequences (i.e. '..')

Dies if filename is invalid.

=cut

sub mbf_validate($;$)
{
    my $filename = shift;
    $filename = shift if ref($filename) && $filename->isa('Module::Bundled::Files');
    die "Illegal reference to parent directory in filename '$filename'" 
        if $filename =~ /\.\./;
    return 1;
}

=head2 mbf_dir([MODULE])

Returns the path of the directory where all files would be installed.

The non-OO interface requires an object reference or module name as
the only parameter.

=cut

sub mbf_dir(;$)
{
    my $module = shift;
    $module = ref($module) if ref($module);
    # Convert My::Module into My/Module.pm
    # %INC uses '/' for delimiters, even on Windows
    my $shortpath = join('/',split(/::/,$module)).'.pm';
    die "Short path not generated for $module" unless $shortpath;
    # Find the complete path for the module
    my $fullpath = $INC{$shortpath};
    die "Full path not found in \%INC for '$shortpath'" unless $fullpath;
    # convert the '/' delimiters in %INC to those used by the OS
    $fullpath = catfile(split(m|/|,$fullpath));
    # Strip the .pm to get the directory name
    $fullpath =~ s|\.pm$||;
    return $fullpath;
}

=head2 mbf_exists([MODULE,] FILENAME)

Returns true of the named file has been bundled with the module.

The non-OO interface requires an object reference or module name as
the first parameter.

=cut

sub mbf_exists($;$)
{
    my $module = shift;
    my $filename = shift;
    mbf_validate($module,$filename);
    my $dir = mbf_dir($module);
    my $fullpath = catfile($dir,$filename);
    return stat($fullpath) ? 1 : 0;
}

=head2 mbf_path([MODULE,] FILENAME)

Returns the full path to the named file.  Dies if the file does not exist.

Will look for file in inherited classes (by reading @ISA) if the file is 
not found for the derived class.  @ISA navigation is the same as per Perl
searching for methods.  See L<Class::ISA> for more details.

The non-OO interface requires an object reference or module name as
the first parameter.

=cut

sub mbf_path($;$)
{
    my $module = shift;
    my $filename = shift;
    unless( mbf_exists($module,$filename) )
    {
        my $found = 0;
        my $module_name = ref($module) || $module;
        foreach my $module_isa (Class::ISA::super_path($module_name))
        {
            if( mbf_exists($module_isa,$filename) )
            {
                $module = $module_isa;
                $found++;
                last;
            }
        }
        die "File not found: '$filename' for module '$module_name'"
            unless $found;
    }
    my $dir = mbf_dir($module);
    my $fullpath = catfile($dir,$filename);
    return $fullpath;
}

=head2 mbf_open([MODULE,] FILENAME)

Returns an open file handle for the named file.  Dies if the file does not exist.

The non-OO interface requires an object reference or module name as
the first parameter.

=cut

sub mbf_open($;$)
{
    my $module = shift;
    my $filename = shift;
    my $fullpath = mbf_path($module,$filename);
    open my $fh, '<', $fullpath
        or die "Could not open file '$filename': ".$@;
    return $fh;
}

=head2 mbf_read([MODULE,] FILENAME)

Returns the content of the named file.  Dies if the file does not exist.

The non-OO interface requires an object reference or module name as
the first parameter.

=cut

sub mbf_read($;$)
{
    my $module = shift;
    my $filename = shift;
    my $fh = mbf_open($module,$filename);
    my $content = '';
    local $_;
    while(<$fh>){$content.=$_;}
    return $content;
}

=head1 AUTHOR

Paul Campbell, C<< <kemitix@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-module-bundled-files@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Bundled-Files>.
I will be notified, and then you will automatically be notified of progress on
your bug as I make changes.

#=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Paul Campbell, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Module::Bundled::Files
