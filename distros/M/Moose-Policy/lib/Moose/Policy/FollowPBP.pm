
package Moose::Policy::FollowPBP;

use constant attribute_metaclass => 'Moose::Policy::FollowPBP::Attribute';

package Moose::Policy::FollowPBP::Attribute;
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
            $options->{reader} = 'get_' . $name;
        }
        elsif ($options->{is} eq 'rw') {
            $options->{reader} = 'get_' . $name;
            $options->{writer} = 'set_' . $name;
        }
        delete $options->{is};
    }
};

1;

__END__

=pod

=head1 NAME 

Moose::Policy::FollowPBP - Follow the recomendations in Perl Best Practices

=head1 SYNOPSIS

  package Foo;
  
  use Moose::Policy 'Moose::Policy::FollowPBP';
  use Moose;
  
  has 'bar' => (is => 'rw', default => 'Foo::bar');
  has 'baz' => (is => 'ro', default => 'Foo::baz');
  
  # Foo now has (get, set)_bar methods as well as get_baz

=head1 DEPRECATION NOTICE

B<Moose::Policy is deprecated>.

Use L<MooseX::FollowPBP> instead.

=head1 DESCRIPTION

This meta-policy changes Moose's default accessor-naming behavior to
follow the recommendations found in Damian Conway's book I<Perl Best
Practices>.

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
