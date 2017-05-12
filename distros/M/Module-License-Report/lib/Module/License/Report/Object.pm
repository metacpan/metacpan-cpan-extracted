package Module::License::Report::Object;

use strict;
use warnings;
use overload q{""} => 'name';

our $VERSION = '0.02';

=head1 NAME 

Module::License::Report::Object - Encapsulation of license information

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

    use Module::License::Report::Object;
    
    my $license = Module::License::Report::Object->new({...});
    print $license;                     # 'perl'
    print $license->source_file();      # 'META.yml'
    print $license->confidence();       # '100'
    print $license->package_version();  # '0.01'

=head1 DESCRIPTION

This module is intended for use with Module::License::Report.  You
likely will never need to use the C<new()> method, but the others will
likely be useful.

=head1 FUNCTIONS

=over

=item $pkg->new({...})

Creates a new license instance.  This is intended for internal use by
Module::License::Report::CPANPLUSModule.

=cut

sub new
{
   my $pkg         = shift;
   my $params_hash = shift;

   return bless {%$params_hash}, $pkg;
}

=item $license->name()

Returns the name of the license.  This name is of the form used by Module::Build.
See L<http://search.cpan.org/~kwilliams/Module-Build/lib/Module/Build/Authoring.pod#license> for the full list.

This method is called when C<$license> is used in string context.

=cut

sub name
{
   my $self = shift;
   return $self->{name};
}

=item $license->confidence()

Returns a confidence in the license as a number between 100 (high) and
0 (low).  These confidences are subjective, and reflect how direct
the determination of the license was, versus how many heuristics were
used.  For example, a license specified in C<META.yml> has a very high
confidence, while a string like C<under the same license as Perl
itself> parsed from README is given lower confidence.

=cut

sub confidence
{
   my $self = shift;
   return $self->{confidence};
}

=item $license->source_file()

Returns the name of the file which specified the license, relative to
the distribution folder.  This might be C<undef> if the license came
from the CPAN DSLIP parameter.

For example: C<META.yml>, C<README.txt>, C<lib/Foo/Bar.pm>.

=cut

sub source_file
{
   my $self = shift;
   return $self->{source_file};
}

=item $license->source_filepath()

Like C<source_file()>, but returns an absolute path.

=cut

sub source_filepath
{
   my $self = shift;
   return if (!defined $self->{source_file});
   return File::Spec->catfile($self->{module}->extract_dir(), $self->{source_file});
}

=item $license->source_name()

Returns a machine-readable keyword that describes the source of the
license.  If more than one source was used, they are comma-separated.
The list of keywords is: C<META.yml>, C<DSLIP>, C<Module>, C<POD>,
and C<LicenseFile>.

=cut

sub source_name
{
   my $self = shift;
   return $self->{source_name};
}

=item $license->source_description()

Returns a human-readable version of C<source_name()>.

=cut

sub source_description
{
   my $self = shift;
   return $self->{source_desc};
}

=item $license->module_name()

Returns the name of the module that started the license search.  So,
if the license of package Foo-Bar is C<perl>, this value could be any
of C<Foo::Bar>, C<Foo::Bar::Baz>, C<Foo::Bar::Quux>, etc.

=cut

sub module_name
{
   my $self = shift;
   return $self->{module}->name();
}

=item $license->package_name()

Returns the CPAN package name for the distribution.  For example,
C<Foo-Bar>.

=cut

sub package_name
{
   my $self = shift;
   return $self->{module}->package_name();
}

=item $license->package_version()

Returns the version number of the CPAN package that was used to determine the license.  For example,
C<0.12.03_01>.

=cut

sub package_version
{
   my $self = shift;
   return $self->{module}->package_version();
}

=item $license->package_dir()

Returns the directory name of the extracted distribution.  This is
typically a subdirectory of C<.cpanplus> somewhere.

=cut

sub package_dir
{
   my $self = shift;
   return $self->{module}->extract_dir();
}

1;
__END__

=back

=head1 SEE ALSO

Module::License::Report

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan
