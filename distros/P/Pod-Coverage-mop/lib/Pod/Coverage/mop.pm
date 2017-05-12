package Pod::Coverage::mop;

use strict;
use warnings;
use 5.010;
use Carp;

use mop;

our $VERSION = '0.002';

class Pod::Coverage::mop
    extends Pod::Coverage::CountParents {

    use Pod::Coverage::CountParents;
    use Module::Load;

    method new($class: %args) {

        # here we need to put methods defined by consumed roles in
        # trustme, even if the class does not define them itself;
        # DEMOLISH BUILD BUILDARGS go into also_trustme

        my $package = $args{package};
        load $package;
        if (my $meta = mop::meta($package)) {
            # ok.  we can do this
            return $class->next::method(%args);
        }

        # not meta (or not mop anyway).  do everything with the
        # regular class.  if it's not able to cope with the foreign
        # meta, too bad
        return Pod::Coverage::CountParents->new(%args);

    }

    method _get_syms($package) {
        # run around the class meta, get the list of methods -- ignore
        # anything declared as a regular sub in the package -- if it
        # ain't got a meta it ain't one of ours.  attributes are
        # ignored unless they have an accessor, which will be caught
        # as a method
        my @symbols;
        foreach my $method (mop::meta($package)->methods) {
            next if $self->_private_check($method->name);
            next unless $method->locally_defined;
            push @symbols, $method->name;
        }
        return @symbols;
    }

}

__END__
=pod

=head1 NAME

Pod::Coverage::mop -- Pod::Coverage subclass for mop

=head1 SYNOPSIS

  use Test::More;
  
  plan skip_all => 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.' unless $ENV{AUTHOR_TESTING};
  
  eval 'use Test::Pod::Coverage 1.00';
  plan skip_all => 'Test::Pod::Coverage 1.00+ required for testing pod coverage' if $@;
  
  eval 'use Pod::Coverage::mop';
  plan skip_all => 'Pod::Coverage::mop required for testing pod coverage' if $@;
  
  all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::mop' });

=head1 DESCRIPTION

In the spirit of L<Pod::Coverage::Moose>, here is a L<Pod::Coverage>
(actually L<Pod::Coverage::CountParents>) subclass for L<mop>-based
classes.

=head1 ATTRIBUTES

None.

=head1 METHODS

=head2 _get_syms

This is overridden from L<Pod::Coverage::CountParents> to return only
the list of locally defined methods, i.e. those not defined by (other)
roles or superclasses.

=head2 new (constructor)

It takes the same arguments as other L<Pod::Coverage> classes.  If
C<mop::meta> does not return a usable value when called with the
package name, we return a regular L<Pod::Coverage::CountParents>
object instead.

=head1 SEE ALSO

L<Pod::Coverage::CountParents>

=head1 AUTHOR

Fabrice Gabolde <fabrice.gabolde@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Fabrice Gabolde

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
