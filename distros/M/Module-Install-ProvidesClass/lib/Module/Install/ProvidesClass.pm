package Module::Install::ProvidesClass;

use strict;
use warnings;
use Module::Install::Base;


BEGIN {
  our @ISA = qw(Module::Install::Base);
  our $ISCORE  = 1;
  our $VERSION = '1.000000';
}

sub _get_no_index {
  my ($self) = @_;

  my $meta;
  {
    # dump_meta does stupid munging/defaults of the Meta values >_<
    no warnings 'redefine';
    local *YAML::Tiny::Dump = sub {
      $meta = shift;
    };
    $self->admin->dump_meta;
  }
  return $meta->{no_index} || { };
}

sub _get_dir {
  $_[0]->_top->{base};
}

sub auto_provides_class {
  my ($self, @keywords) = @_;

  return $self unless $self->is_admin;

  @keywords = ('class','role') unless @keywords;

  require Class::Discover;

  my $no_index = $self->_get_no_index;

  my $dir = $self->_get_dir;

  my $classes = Class::Discover->discover_classes({
    no_index => $no_index,
    dir => $dir,
    keywords => \@keywords
  });

  for (@$classes) {
    my ($class,$info) = each (%$_);
    delete $info->{type};
    $self->provides( $class => $info ) 
  }
}

1;

=head1 NAME

Module::Install::ProvidesClass - provides detection in META.yml for 'class' keyword

=head1 SYNOPSIS

 use inc::Module::Install 0.79;

 all_from 'lib/My/Module/Which/Uses/MooseXDeclare';

 auto_provides_class;
 WriteAll;

=head1 DESCRIPTION

This class is designed to populate the C<provides> field of META.yml files so
that the CPAN indexer will pay attention to the existance of your classes,
rather than blithely ignoring them. It does this for Module::Install based
C<Makefile.PL> files. If you use Module::Build then look at L<Class::Discover>
which does all the effort of searching for the classes.

=head1 USAGE.

Simply add the following lines to your Makefile.PL before the C<WriteAll;>:

 auto_provides_class;

Its that simple. By default we look for 'class' and 'role' keywords. If you are
using something that provides packages using a different keyword, such as
L<CatalystX::Declare> then you can pass a list of keywords to look for to
C<auto_provides_class>:

 auto_provides_class(qw/
   class
   role
   application
   controller
   controller_role
   view
   model
 /);

Make sure you include 'class' and 'role' if you are still using them.

The version parsing is basically the same as what M::I's C<< ->version_form >>
does, so should hopefully work as well as it does.

This module attempts to be author side only, hopefully it does it correctly, but
Module::Install is scary at times.

=head1 SEE ALSO

L<MooseX::Declare> for the main reason for this module to exist.

L<Class::Discover> for the version extraction logic.

=head1 AUTHOR

Copyright (C) Ash Berlin C<< <ash@cpan.org> >>, 2009-2010.

=head1 LICENSE 

Licensed under the same terms as Perl itself.

