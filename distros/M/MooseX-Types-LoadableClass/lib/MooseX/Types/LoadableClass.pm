package MooseX::Types::LoadableClass; # git description: v0.013-12-g14cfc61
# ABSTRACT: ClassName type constraint with coercion to load the class.
# KEYWORDS: moose types constraints class classes role roles module modules

our $VERSION = '0.014';

use strict;
use warnings;
use MooseX::Types -declare => [qw/ ClassName LoadableClass LoadableRole /];
use MooseX::Types::Moose qw(Str RoleName), ClassName => { -as => 'MooseClassName' };
use Module::Runtime qw(is_module_name use_package_optimistically);
use if MooseX::Types->VERSION >= 0.42, 'namespace::autoclean';

subtype LoadableClass,
    as Str,
    where {
        is_module_name($_)
            and use_package_optimistically($_)
            and MooseClassName->check($_)
    };

subtype LoadableRole,
    as Str,
    where {
        is_module_name($_)
            and use_package_optimistically($_)
            and RoleName->check($_)
    };


# back compat
coerce LoadableClass, from Str, via { $_ };

coerce LoadableRole, from Str, via { $_ };

__PACKAGE__->type_storage->{ClassName}
    = __PACKAGE__->type_storage->{LoadableClass};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::LoadableClass - ClassName type constraint with coercion to load the class.

=head1 VERSION

version 0.014

=head1 SYNOPSIS

    package MyClass;
    use Moose;
    use MooseX::Types::LoadableClass qw/ LoadableClass /;

    has foobar_class => (
        is => 'ro',
        required => 1,
        isa => LoadableClass,
    );

    MyClass->new(foobar_class => 'FooBar'); # FooBar.pm is loaded or an
                                            # exception is thrown.

=head1 DESCRIPTION

    use Moose::Util::TypeConstraints;

    my $tc = subtype as ClassName;
    coerce $tc, from Str, via { Class::Load::load_class($_); $_ };

I've written those three lines of code quite a lot of times, in quite
a lot of places.

Now I don't have to.

=for stopwords ClassName

=head1 TYPES EXPORTED

=head2 C<LoadableClass>

A normal class / package.

=head2 C<LoadableRole>

Like C<LoadableClass>, except the loaded package must be a L<Moose::Role>.

=head1 AUTHOR

Tomas Doran <bobtfish@bobtfish.net>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Dagfinn Ilmari Mannsåker Florian Ragwitz Сергей Романов

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Сергей Романов <sromanov@cpan.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
