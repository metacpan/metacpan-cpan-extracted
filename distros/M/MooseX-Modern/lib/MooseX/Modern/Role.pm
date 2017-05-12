package MooseX::Modern::Role;
$MooseX::Modern::Role::VERSION = '0.0200';
use Moose::Role                   ();
use Moose::Exporter;
use Moose::Util::TypeConstraints  ();
use MooseX::AttributeShortcuts    ();
use MooseX::HasDefaults::RO       ();

use namespace::autoclean          ();

Moose::Exporter->setup_import_methods(also => ['Moose::Role']);

sub init_meta {
    my $class  = shift;
    my $caller = scalar caller();
    my %params = @_;
    my $for_class = $params{for_class};

    Moose::Role->init_meta(@_);
    Moose::Util::TypeConstraints->import({ into => $for_class });
    MooseX::AttributeShortcuts->init_meta(@_);
    MooseX::HasDefaults::RO->import({ into => $caller });

    namespace::autoclean->import( -cleanee => $for_class );
}

1;

# ABSTRACT: Precision roles for Modern Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Modern::Role - Precision roles for Modern Perl

=head1 VERSION

version 0.0200

=head1 SYNOPSIS

    use MooseX::Modern::Role;

    # Your role here

=head1 DESCRIPTION

MooseX::Modern::Role provides the best practices of L<Moose::Role> in a single, user-friendly import.

The following modules will be automatically loaded into your class:

=over

=item L<Moose::Role> – Postmodern object system for roles

=item L<Moose::Util::TypeConstraints> – Type constraint system

=item L<MooseX::AttributeShortcuts> – Shorthand for common attribute options

=item L<MooseX::HasDefaults::RO> – Default to read-only attributes

=item L<namespace::autoclean> – Clean imports in class namespace

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/aanari/MooseX-Modern/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Ali Anari <ali@anari.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ali Anari.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
