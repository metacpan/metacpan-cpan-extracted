package Module::Filename;
use strict;
use warnings;
use base qw{Exporter};
use Path::Class qw{file};

our $VERSION = '0.02';
our @EXPORT_OK = qw(module_filename);

=head1 NAME

Module::Filename - Provides an object oriented, cross platform interface for getting a module's filename

=head1 SYNOPSIS

  use Module::Filename;
  my $filename=Module::Filename->new->filename("Test::More"); #isa Path::Class::File

  use Module::Filename qw{module_filename};
  my $filename=module_filename("Test::More");                 #isa Path::Class::File

=head1 DESCRIPTION

This module returns the filename as a L<Path::Class::File> object.  It does not load any packages as it scans.  It simply scans @INC looking for a module of the same name as the package passed.

=head1 USAGE

  use Module::Filename;
  my $filename=Module::Filename->new->filename("Test::More"); #isa Path::Class::File
  print "Test::More can be found at $filename\n";

=head1 CONSTRUCTOR

=head2 new

  my $mf=Module::Filename->new();

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=head2 initialize

You can inherit the filename method in your package.

  use base qw{Module::Filename};
  sub initialize{do_something_else()};

=cut

sub initialize {
  my $self = shift();
  %$self=@_;
}

=head2 filename

Returns a L<Path::Class::File> object for the first filename that matches the module in the @INC path array.

  my $filename=Module::Filename->new->filename("Test::More"); #isa Path::Class::File
  print "Filename: $filename\n";

=cut

sub filename {
  my $self=shift;
  return module_filename(@_);
}

=head1 FUNCTIONS

=head2 module_filename

Returns a L<Path::Class::File> object for the first filename that matches the module in the @INC path array.

  my $filname=module_filename("Test::More"); #isa Path::Class::File
  print "Filename: $filename\n";

=cut


sub module_filename {
  die("Error: Module name required.") unless @_;
  my $module=shift;
  my $file=file(split("::", $module.".pm"));
  my $return=undef;
  foreach my $path (@INC) {
    next unless defined $path;
    next if ref($path);
    my $filename=file($path,  $file);
    if (-f $filename) {
     $return=$filename;
     last; #return the first match in @INC
    }
  }
  return $return;
}


=head1 LIMITATIONS

The algorithm does not scan inside module files for provided packages.

=head1 BUGS

Submit to RT and email author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  STOP, LLC
  domain=>michaelrdavis,tld=>com,account=>perl
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

Module::Filename predates L<Module::Path> by almost 4 years but it appears more people prefer L<Module::Path> over Module::Filename as it does not have the dependency on L<Path::Class>.  After the reviews on L<http://neilb.org/reviews/module-path.html>. I added the functional API to Module::Filename.  So, your decision is simply an object/non-object decision.   The operations with the file system that both packages perform outweigh the performance of the object creation in Module::Filename.  So, any performance penalty should not be measurable.  Since Module::Filename does not need three extra file test operations that Module::Path 0.18 performs on each @INC directory, Module::Filename may actually be faster than L<Module::Path> for most applications.

=head2 Similar Capabilities

L<Module::Path>, L<perlvar> %INC, L<pmpath>, L<Module::Info> constructor=>new_from_module, method=>file, L<Module::InstalledVersion> property=>"dir", L<Module::Locate> method=>locate, L<Module::Util> method=>find_installed

=head2 Comparison

CPAN modules for getting a module's path L<http://neilb.org/reviews/module-path.html>

=cut

1;
