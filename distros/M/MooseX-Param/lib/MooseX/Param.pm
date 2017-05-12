
package MooseX::Param;
use Moose::Role;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:STEVAN';

has 'params' => (
    is       => 'rw',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => 'init_params',
);

sub init_params { +{} }

sub param {
    my $self = shift;
    
    # if they want the list of keys ...
    return keys %{$self->params}  if scalar @_ == 0;
    
    # if they want to fetch a particular key ...    
    return $self->params->{$_[0]} if scalar @_ == 1;
    
    ((scalar @_ % 2) == 0)
        || confess "parameter assignment must be an even numbered list";
    
    my %new = @_;
    while (my ($key, $value) = each %new) {
        $self->params->{$key} = $value;
    }
    
    return;
}

1;

__END__

=pod

=head1 NAME

MooseX::Param - Simple role to provide a standard param method

=head1 SYNOPSIS

  package My::Template::System;
  use Moose;
  
  with 'MooseX::Param';
  
  # ...
  
  my $template = My::Template::System->new(
      params => { 
          foo => 10,
          bar => 20,
          baz => 30,
      }
  );
  
  # fetching params
  $template->param('foo'); # 10
  
  # getting list of params
  $template->param(); # foo, bar, baz
  
  # setting params
  $template->param(foo => 30, bar => 100);
  
=head1 DESCRIPTION

This is a very simple Moose role which provides a L<CGI> like C<param> method.

I found that I had written this code over and over and over and over again, 
and each time it was the same. So I thought, why not put it in a role? 

=head1 ATTRIBUTES

=over 4

=item I<params>

This role provides a C<params> attribute which has a read-only accessor, 
and a HashRef type constraint. It also adds a builder method (see 
C<init_params> method below) to properly initalize it.

=back

=head1 METHODS

=over 4

=item B<params>

Return the HASH ref in which the parameters are stored.

=item B<param>

This is your standard L<CGI> style C<param> method. If passed no arguments, 
it will return a list of param names. If passed a single name argument it will 
return the param associated with that name. If passed a key value pair (or set 
of key value pairs) it will assign them into the params.

=item I<init_params>

This is the I<params> attribute C<builder> option, so it is called the 
params are initialized. 

B<NOTE:> You can override this by defining your own version in your class, 
because local class methods beat role methods in composition.

=item B<meta>

Returns the role metaclass.

=back

=head1 SIMILAR MODULES

The C<param> method can be found in several other modules, such as L<CGI>, 
L<CGI::Application> and L<HTML::Template> to name a few. This is such a 
common Perl idiom that I felt it really deserved it's own role (if for 
nothing more than I was sick of re-writing and copy-pasting it all the 
time). 

There are also a few modules which attempt to solve the same problem as 
this module. Those are:

=over 4

=item L<Class::Param>

This module is much more ambitious than mine, and provides much deeper 
functionality. For most of my purposes, this module would have been 
overkill, but if you need really sophisticated param handling and the 
ability to provide several different APIs (tied, etc), this module is
probably the way to go.

=item L<Mixin::ExtraFields::Param>

This module is very similar to mine, but for a different framework. It
works with the L<Mixin::ExtraFields> framework.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut