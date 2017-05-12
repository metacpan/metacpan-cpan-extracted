package MooseX::Policy::SemiAffordanceAccessor;

use strict;
use warnings;

our $VERSION = '0.02';
our $AUTHORITY = 'cpan:DROLSKY';

use constant attribute_metaclass =>                        ## no critic ProhibitConstantPragma
    'MooseX::Policy::SemiAffordanceAccessor::Attribute';


package MooseX::Policy::SemiAffordanceAccessor::Attribute; ## no critic ProhibitMultiplePackages


use Moose;

extends 'Moose::Meta::Attribute';

before '_process_options' => sub
{
    my $class   = shift;
    my $name    = shift;
    my $options = shift;

    if ( exists $options->{is} &&
         ! ( exists $options->{reader} || exists $options->{writer} ) )
    {
        if ( $options->{is} eq 'ro' )
        {
            $options->{reader} = $name;
        }
        elsif ( $options->{is} eq 'rw' )
        {
            $options->{reader} = $name;

            my $prefix = 'set';
            if ( $name =~ s/^_// )
            {
                $prefix = '_set';
            }

            $options->{writer} = $prefix . q{_} . $name;
        }

        delete $options->{is};
    }
};


1;

__END__

=pod

=head1 NAME

MooseX::Policy::SemiAffordanceAccessor - A policy to name accessors foo() and set_foo()

=head1 SYNOPSIS

    use Moose::Policy 'MooseX::Policy::SemiAffordanceAccessor';
    use Moose;

    # make some attributes

=head1 DESCRIPTION

This class does not provide any methods. Just loading it changes the
default naming policy for the package so that accessors are separated
into get and set methods. The get methods have the same name as the
accessor, while set methods are prefixed with "set_".

If you define an attribute with a leading underscore, then the set
method will start with "_set_".

If you explicitly set a "reader" or "writer" name when creating an
attribute, then this policy skips that attribute.

The name "semi-affordance" comes from David Wheeler's Class::Meta
module.

=head1 AUTHOR

Dave Rolsky, C<< <autarch@urth.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-moosex-policy-semiaffordanceaccessor@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org>.  I will be notified, and
then you'll automatically be notified of progress on your bug as I
make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
