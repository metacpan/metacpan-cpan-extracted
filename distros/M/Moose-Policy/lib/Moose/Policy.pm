package Moose::Policy;
use Moose 'confess', 'blessed';

our $VERSION   = '0.05';
our $AUTHORITY = 'cpan:STEVAN';

sub import {
    shift;

    my $policy = shift || return;

    unless (Class::MOP::is_class_loaded($policy)) {
        # otherwise require it ...
        eval { Class::MOP::load_class($policy) };
        confess "Could not load policy module '$policy' because : $@"
            if $@;
    }

    my $package = caller();
    $package->can('meta') and
        croak("'$package' already has a meta() method, this is very problematic");

    my $metaclass = 'Moose::Meta::Class';
    $metaclass = $policy->metaclass($package)
        if $policy->can('metaclass');

    my %options;

    # build options out of policy's constants
    $policy->can($_) and $options{"$_"} = $policy->$_($package)
        for (qw(
            attribute_metaclass
            instance_metaclass
            method_metaclass
            ));

    # create a meta object so we can install &meta
    my $meta = $metaclass->initialize($package => %options);
    $meta->add_method('meta' => sub {
        # we must re-initialize so that it works as expected in
        # subclasses, since metaclass instances are singletons, this is
        # not really a big deal anyway.
        $metaclass->initialize((blessed($_[0]) || $_[0]) => %options)
    });
}

1;

__END__

=pod

=head1 NAME

Moose::Policy - Moose-mounted police

=head1 SYNOPSIS

  package Foo;

  use Moose::Policy 'Moose::Policy::FollowPBP';
  use Moose;

  has 'bar' => (is => 'rw', default => 'Foo::bar');
  has 'baz' => (is => 'ro', default => 'Foo::baz');

  # Foo now has (get, set)_bar methods as well as get_baz

=head1 DEPRECATION NOTICE

B<Moose::Policy is deprecated>.

L<MooseX::FollowPBP> replaces the L<Moose::Policy::FollowPBP> module. The
other policies included in this distribution do not yet have standalone MooseX
modules, as of November, 2010.

This module has not passed its tests since Moose 1.05, and will probably not
be fixed.

=head1 DESCRIPTION

This module allows you to specify your project-wide or even company-wide 
Moose meta-policy. 

Most all of Moose's features can be customized through the use of custom 
metaclasses, however fiddling with the metaclasses can be hairy. Moose::Policy 
removes most of that hairiness and makes it possible to cleanly contain 
a set of meta-level customizations in one easy to use module.

This is still an release of this module and it should not be considered to 
be complete by any means. It is very basic implemenation at this point and 
will likely get more feature-full over time, as people request features.
So if you have a suggestion/need/idea, please speak up.

=head2 What is a meta-policy?

A meta-policy is a set of custom Moose metaclasses which can be used to 
implement a number of customizations and restrictions on a particular 
Moose class. 

For instance, L<Moose::Policy::SingleInheritence> enforces that all 
specified Moose classes can only use single inheritance. It does this 
by trapping the call to C<superclasses> on the metaclass and only allowing 
you to assign a single superclass. 

The L<Moose::Policy::FollowPBP> policy changes the default behavior of 
accessors to fit the recomendations found in Perl Best Practices. 

=head1 CAVEATS

=head2 Always load Moose::Policy first.

You B<must> put the following line of code: 

  use Moose::Policy 'My::Policy';

before this line:

  use Moose;

This is because Moose::Policy must be given the opportunity to set the 
custom metaclass before Moose has set it's default metaclass. In fact, if 
you try to set a Moose::Policy and there is a C<meta> method available, 
not only will kittens die, but your program will too.

=head2 Policies are class scoped

You must repeat the policy for each class you want to use it. It is B<not> 
inherited. This may change in the future, probably it will be a Moose::Policy 
itself to allow Moose policies to be inherited.

=head1 THE POLICY

A Policy is set by passing C<Moose::Policy::import()> a package name.  This 
package is then queried for what metaclasses it should use. The possible 
metaclass values are:

=over

=item B<metaclass> 

This defaults to C<Moose::Meta::Class>.

=item B<attribute_metaclass>

=item B<instance_metaclass>

=item B<method_metaclass>

=back

For examples of what a Policy actually looks like see the examples in 
C<Moose::Policy::> and the test suite. More docs to come on this later (probably 
a cookbook or something).

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 FUTURE PLANS

As I said above, this is the first release and it is by no means feature complete. 
There are a number of thoughts on the future direction of this module. Here are 
some random thoughts on that, in no particular order.

=over 4

=item Make set of policy roles

Roles are an excellent way to combine sets of behaviors together into one, and 
custom metaclasses are actually better composed by roles then by inheritence. 
The ideal situation is that this module will provide a set of roles which can be 
used to compose your meta-policy with relative ease.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Eric Wilhelm

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

