package MooseX::SemiAffordanceAccessor;
# git description: v0.09-8-g87ddfb5
$MooseX::SemiAffordanceAccessor::VERSION = '0.10';

use strict;
use warnings;

use Moose 0.94 ();
use Moose::Exporter;
use Moose::Util::MetaRole;
use MooseX::SemiAffordanceAccessor::Role::Attribute;

my %metaroles = (
    class_metaroles => {
        attribute => ['MooseX::SemiAffordanceAccessor::Role::Attribute'],
    },
);

$metaroles{role_metaroles} = {
    applied_attribute => ['MooseX::SemiAffordanceAccessor::Role::Attribute'],
} if $Moose::VERSION >= 1.9900;

Moose::Exporter->setup_import_methods(%metaroles);

1;

# ABSTRACT: Name your accessors foo() and set_foo()

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::SemiAffordanceAccessor - Name your accessors foo() and set_foo()

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    use Moose;
    use MooseX::SemiAffordanceAccessor;

    # make some attributes

=head1 DESCRIPTION

This module does not provide any methods. Simply loading it changes
the default naming policy for the loading class so that accessors are
separated into get and set methods. The get methods have the same name
as the accessor, while set methods are prefixed with "set_".

If you define an attribute with a leading underscore, then the set
method will start with "_set_".

If you explicitly set a "reader" or "writer" name when creating an
attribute, then that attribute's naming scheme is left unchanged.

The name "semi-affordance" comes from David Wheeler's Class::Meta
module.

=head1 ACCESSORS IN ROLES

Prior to version 1.9900 of L<Moose>, attributes added to a class ended up with
that class's attribute traits. That means that if your class used
C<MooseX::SemiAffordanceAccessor>, any attributes provided by roles you
consumed had the semi-affordance style of accessor.

As of Moose 1.9900, that is no longer the case. Attributes provided by roles
no longer acquire the consuming class's attribute traits. However, with Moose
1.9900+, you can now use C<MooseX::SemiAffordanceAccessor> directly in
roles. Attributes defined by that role will have semi-affordance style
accessors, regardless of what attribute traits the consuming class has.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-moosex-semiaffordanceaccessor@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org>.  I will be notified, and
then you'll automatically be notified of progress on your bug as I
make changes.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
