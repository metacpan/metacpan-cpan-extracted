
package Moose::Policy::JavaAccessors;

use constant attribute_metaclass => 'Moose::Policy::JavaAccessors::Attribute';

package Moose::Policy::JavaAccessors::Attribute;
use Moose;

extends 'Moose::Meta::Attribute';

before '_process_options' => sub {
    my ($class, $name, $options) = @_;
    # NOTE:
    # If is has been specified, and 
    # we don't have a reader or writer
    # Of couse this is an odd case, but
    # we better test for it anyway.
    if (exists $options->{is} && !(exists $options->{reader} || exists $options->{writer})) {
        if ($options->{is} eq 'ro') {
            $options->{reader} = 'get' . ucfirst($name);
        }
        elsif ($options->{is} eq 'rw') {
            $options->{reader} = 'get' . ucfirst($name);
            $options->{writer} = 'set' . ucfirst($name);
        }
        delete $options->{is};
    }
};

1;

__END__

=pod

=head1 NAME 

Moose::Policy::JavaAccessors - BeCause EveryOne Loves CamelCase

=head1 SYNOPSIS
  
  package Foo;
  
  use Moose::Policy 'Moose::Policy::JavaAccessors';
  use Moose;
  
  has 'bar' => (is => 'rw', default => 'Foo::bar');
  has 'baz' => (is => 'ro', default => 'Foo::baz');
  
  # Foo now has (get, set)Bar methods as well as getBaz

=head1 DEPRECATION NOTICE

B<Moose::Policy is deprecated>.

=head1 DESCRIPTION

This meta-policy changes the behavior of Moose's default behavior in 
regard to  accessors to follow Java convention and use CamelCase.

=head1 CAVEAT

This does a very niave conversion to CamelCase, basically it just 
runs C<ucfirst> on the attribute name. Since I don't use CamelCase 
(at least not anymore), this is good enough. If you really want to 
use this, and need a more sophisicated conversion, patches welcome :)

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
