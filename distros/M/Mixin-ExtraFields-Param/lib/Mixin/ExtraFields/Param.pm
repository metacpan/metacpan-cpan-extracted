use warnings;
use strict;
package Mixin::ExtraFields::Param;
# ABSTRACT: make your class provide a familiar "param" method
$Mixin::ExtraFields::Param::VERSION = '0.021';
use Mixin::ExtraFields 0.002 ();
use parent qw(Mixin::ExtraFields);

use Carp ();

# =head1 SYNOPSIS
#
#   package Widget::Parametric;
#   use Mixin::ExtraFields::Param -fields => { driver => 'HashGuts' };;
#
#   ...
#
#   my $widget = Widget::Parametric->new({ flavor => 'vanilla' });
#
#   printf "%s: %s\n", $_, $widget->param($_) for $widget->param;
#
# =head1 DESCRIPTION
#
# This module mixes in to your class to provide a C<param> method like the ones
# provided by L<CGI>, L<CGI::Application>, and other classes.  It uses
# Mixin::ExtraFields, which means it can use any Mixin::ExtraFields driver to
# store your data.
#
# By default, the methods provided are:
#
# =for :list
# * param
# * exists_param
# * delete_param
#
# These methods are imported by the C<fields> group, which must be requested.  If
# a C<moniker> argument is supplied, the moniker is used instead of "param".  For
# more information, see L<Mixin::ExtraFields>.
#
# =cut

sub default_moniker { 'param' }

sub methods { qw(param exists delete) }

sub method_name {
  my ($self, $method, $moniker) = @_;

  return $moniker if $method eq 'param';
  return $self->SUPER::method_name($method, $moniker);
}

sub build_method {
  my ($self, $method_name, $arg) = @_;

  return $self->_build_param_method($arg) if $method_name eq 'param';
  return $self->SUPER::build_method($method_name, $arg);
}

# =method param
#
#  my @params = $object->param;        # get names of existing params
#
#  my $value = $object->param('name'); # get value of a param
#
#  my $value = $object->param(name => $value); # set a param's value
#
#  my @values = $object->param(n1 => $v1, n2 => $v2, ...); # set many values
#
# This method sets or retrieves parameters.
#
# =cut

sub _build_param_method {
  my ($self, $arg) = @_;

  my $id_method = $arg->{id_method};
  my $driver    = $arg->{driver};

  my $names_method = $self->driver_method_name('get_all_names');
  my $get_method   = $self->driver_method_name('get');
  my $set_method   = $self->driver_method_name('set');

  sub {
    my $self = shift;
    my $id   = $self->$$id_method;

    # If called as ->param, return all names.
    return $$driver->$names_method($self, $id) unless @_;

    # If given a hashref, as first arg, operate on its contents.  In the
    # future, we might want to complain if we get a hashref /and/ further
    # arguments.
    @_ = %{$_[0]} if @_ == 1 and ref $_[0] eq 'HASH';

    Carp::croak "invalid call to param: odd, non-one number of params"
      if @_ > 1 and @_ % 2 == 1;

    # If called as ->param($name), return the value
    return $$driver->$get_method($self, $id, $_[0]) if @_ == 1;

    # Otherwise we're doing... BULK ASSIGNMENT!
    my @assigned;
    while (@_) {
      # We don't put @_ into a hash because we guarantee processing (and more
      # importantly return) order. -- rjbs, 2006-03-14
      my ($key, $value) = splice @_, 0, 2;
      $$driver->$set_method($self, $id, $key => $value);
      push @assigned, $value;
    }
    return wantarray ? @assigned : $assigned[0];
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mixin::ExtraFields::Param - make your class provide a familiar "param" method

=head1 VERSION

version 0.021

=head1 SYNOPSIS

  package Widget::Parametric;
  use Mixin::ExtraFields::Param -fields => { driver => 'HashGuts' };;

  ...

  my $widget = Widget::Parametric->new({ flavor => 'vanilla' });

  printf "%s: %s\n", $_, $widget->param($_) for $widget->param;

=head1 DESCRIPTION

This module mixes in to your class to provide a C<param> method like the ones
provided by L<CGI>, L<CGI::Application>, and other classes.  It uses
Mixin::ExtraFields, which means it can use any Mixin::ExtraFields driver to
store your data.

By default, the methods provided are:

=over 4

=item *

param

=item *

exists_param

=item *

delete_param

=back

These methods are imported by the C<fields> group, which must be requested.  If
a C<moniker> argument is supplied, the moniker is used instead of "param".  For
more information, see L<Mixin::ExtraFields>.

=head1 METHODS

=head2 param

 my @params = $object->param;        # get names of existing params

 my $value = $object->param('name'); # get value of a param

 my $value = $object->param(name => $value); # set a param's value

 my @values = $object->param(n1 => $v1, n2 => $v2, ...); # set many values

This method sets or retrieves parameters.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
