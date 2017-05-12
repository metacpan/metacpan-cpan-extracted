=head1 NAME

Template::TAL::Provider::Disk - find template files on disk

=head1 SYNOPSIS

  my $provider = Template::TAL::Provider::Disk->new->include_path( "./templates" );
  my $ttt = $provider->get_template("foo.tal");
  
=head1 DESCRIPTION

A Template::TAL::Provider that creates template objects from files on disk.

Given a list of include paths, it will search them in order, looking for a
named template, then return it in a L<Template::TAL::Template> object.

This is the default provider and an instance will be created for each
Template::TAL object unless an alternative provider is specified, meaning
you very rarely have to use this class directly.

=cut

package Template::TAL::Provider::Disk;
use warnings;
use strict;
use Carp qw( croak );
use File::Spec::Functions;
use base qw( Template::TAL::Provider );
use Cwd qw( abs_path );
use Template::TAL::Template;

=head1 METHODS

=over

=item include_path

When called with no argument returns an arrayref of the search paths.  May
be called with an argument, either a simple string or an arrayref, to set
a new search path / new search paths respectivly and return self.

=cut

sub include_path {
  my $self = shift;
  
  unless (@_) {
    return $self->{include_path} ||= [];
  }
  
  # shallow copy to avoid unforseen modification
  $self->{include_path} = [
    ref($_[0]) eq 'ARRAY' ? @{ $_[0] } : ($_[0])
  ];

  return $self;
}

=item get_template( name )

searches the include path for files of the given name, and returns the first
found as a Template::TAL::Template object. Will die if it can't find a
template file with the given name or is unable to open the named file.

=cut

sub get_template {
  my ($self, $name) = @_;
  for my $path (@{ $self->include_path }) {
    my $filename = catfile( $path, $name );

    if ( -f $filename ) {
      my $abs = abs_path( $filename );
      croak("not loading $filename from outside include path")
        unless $abs =~ /^\Q$path/;
      
      return Template::TAL::Template->new->filename( $filename );
    }
  }
  croak("no template '$name' found");
}

=back

=head1 COPYRIGHT

Written by Tom Insam, Copyright 2005 Fotango Ltd. All Rights Reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 BUGS

Please see L<Template::TAL> for details of how to report bugs.

Note that currently, this explicitly doesn't do any caching.  We rely on
the operating system to do that for us.

=head1 SEE ALSO

L<Template::TAL>, L<Template::TAL::Provider>

=cut

1;
