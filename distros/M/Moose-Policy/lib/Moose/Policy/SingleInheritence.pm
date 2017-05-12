
package Moose::Policy::SingleInheritence;

use constant metaclass => 'Moose::Policy::SingleInheritence::MetaClass';

package Moose::Policy::SingleInheritence::MetaClass;
use Moose;

extends 'Moose::Meta::Class';

before 'superclasses' => sub {
    my ($self, @superclasses) = @_;
    confess 'Moose::Policy::SingleInheritence in effect for ' . 
             $self->name . ', only single inheritence is allowed'
         if scalar @superclasses > 1;
};

1;

__END__

=pod

=head1 NAME 

Moose::Policy::SingleInheritence - Why would you ever need more than one?

=head1 SYNOPSIS

  package Foo;
  
  use Moose::Policy 'Moose::Policy::SingleInheritence';
  use Moose;
  
  package Bar;
  
  use Moose::Policy 'Moose::Policy::SingleInheritence';
  use Moose;
  
  package Foo::Bar;
  
  use Moose::Policy 'Moose::Policy::SingleInheritence';
  use Moose;
  
  extends 'Foo', 'Bar';  # BOOM!!!!

=head1 DEPRECATION NOTICE

B<Moose::Policy is deprecated>.

=head1 DESCRIPTION

This module restricts Moose's C<extends> keyword so that you can only assign 
a single superclass. 

This is mostly an example of how you can restrict behavior with meta-policies 
in addition to extending and/or customising them. However, sometimes enforcing 
a policy like this can be a good thing.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
