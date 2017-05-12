package MooseX::AlwaysCoerce; # git description: v0.22-7-gf255031
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Automatically enable coercions for Moose attributes
# KEYWORDS: Moose extension type constraint coerce coercion

our $VERSION = '0.23';

use strict;
use warnings;

use namespace::autoclean 0.12;
use MooseX::ClassAttribute 0.24 ();
use Moose::Exporter;
use Moose::Util::MetaRole;

Moose::Exporter->setup_import_methods;

#pod =pod
#pod
#pod =for stopwords coercions
#pod
#pod =head1 SYNOPSIS
#pod
#pod     package MyClass;
#pod
#pod     use Moose;
#pod     use MooseX::AlwaysCoerce;
#pod     use MyTypeLib 'SomeType';
#pod
#pod     has foo => (is => 'rw', isa => SomeType); # coerce => 1 automatically added
#pod
#pod     # same, MooseX::ClassAttribute is automatically applied
#pod     class_has bar => (is => 'rw', isa => SomeType);
#pod
#pod =head1 DESCRIPTION
#pod
#pod Have you ever spent an hour or more trying to figure out "Hey, why did my
#pod coercion not run?" only to find out that you forgot C<< coerce => 1 >> ?
#pod
#pod Just load this module in your L<Moose> class and C<< coerce => 1 >> will be
#pod enabled for every attribute and class attribute automatically.
#pod
#pod Use C<< coerce => 0 >> to disable a coercion explicitly.
#pod
#pod =cut

{
    package # hide from PAUSE
        MooseX::AlwaysCoerce::Role::Meta::Attribute;
    use namespace::autoclean;
    use Moose::Role;

    around should_coerce => sub {
        my $orig = shift;
        my $self = shift;

        my $current_val = $self->$orig(@_);

        return $current_val if defined $current_val;

        return 1 if $self->type_constraint && $self->type_constraint->has_coercion;
        return 0;
    };

    package # hide from PAUSE
        MooseX::AlwaysCoerce::Role::Meta::Class;
    use namespace::autoclean;
    use Moose::Role;
    use Moose::Util::TypeConstraints ();

    around add_class_attribute => sub {
        my $next = shift;
        my $self = shift;
        my ($what, %opts) = @_;

        if (exists $opts{isa}) {
            my $type = Moose::Util::TypeConstraints::find_or_parse_type_constraint($opts{isa});
            $opts{coerce} = 1 if not exists $opts{coerce} and $type->has_coercion;
        }

        $self->$next($what, %opts);
    };
}

my (undef, undef, $init_meta) = Moose::Exporter->build_import_methods(

    install => [ qw(import unimport) ],

    class_metaroles => {
        attribute   => ['MooseX::AlwaysCoerce::Role::Meta::Attribute'],
        class       => ['MooseX::AlwaysCoerce::Role::Meta::Class'],
    },

    role_metaroles => {
        (Moose->VERSION >= 1.9900
            ? (applied_attribute => ['MooseX::AlwaysCoerce::Role::Meta::Attribute'])
            : ()),
        role                => ['MooseX::AlwaysCoerce::Role::Meta::Class'],
    }
);

sub init_meta {
    my ($class, %options) = @_;
    my $for_class = $options{for_class};

    MooseX::ClassAttribute->import({ into => $for_class });

    # call generated method to do the rest of the work.
    goto $init_meta;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AlwaysCoerce - Automatically enable coercions for Moose attributes

=head1 VERSION

version 0.23

=head1 SYNOPSIS

    package MyClass;

    use Moose;
    use MooseX::AlwaysCoerce;
    use MyTypeLib 'SomeType';

    has foo => (is => 'rw', isa => SomeType); # coerce => 1 automatically added

    # same, MooseX::ClassAttribute is automatically applied
    class_has bar => (is => 'rw', isa => SomeType);

=head1 DESCRIPTION

Have you ever spent an hour or more trying to figure out "Hey, why did my
coercion not run?" only to find out that you forgot C<< coerce => 1 >> ?

Just load this module in your L<Moose> class and C<< coerce => 1 >> will be
enabled for every attribute and class attribute automatically.

Use C<< coerce => 0 >> to disable a coercion explicitly.

=for stopwords coercions

=for Pod::Coverage init_meta

=head1 ACKNOWLEDGEMENTS

My own stupidity, for inspiring me to write this module.

=for stopwords Rolsky

Dave Rolsky, for telling me how to do it the L<Moose> way.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-AlwaysCoerce>
(or L<bug-MooseX-AlwaysCoerce@rt.cpan.org|mailto:bug-MooseX-AlwaysCoerce@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Rafael Kitover <rkitover@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Jesse Luehrs Michael G. Schwern

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Michael G. Schwern <schwern@pobox.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Rafael Kitover <rkitover@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
