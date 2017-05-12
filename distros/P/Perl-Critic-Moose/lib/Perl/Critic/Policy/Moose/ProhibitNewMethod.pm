package Perl::Critic::Policy::Moose::ProhibitNewMethod;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.05';

use Readonly ();

use Perl::Critic::Utils qw< :booleans :severities >;
use Perl::Critic::Utils::PPI qw< is_ppi_generic_statement >;

use base 'Perl::Critic::Policy';

Readonly::Scalar my $DESCRIPTION =>
    q<"new" method/subroutine declared in a Moose class.>;
Readonly::Scalar my $EXPLANATION =>
    q<Use BUILDARGS and BUILD instead of writing your own constructor.>;

sub supported_parameters {
    return (
        {
            name => 'equivalent_modules',
            description =>
                q<The additional modules to treat as equivalent to "Moose", "Moose::Role", or "MooseX::Role::Parameterized".>,
            default_string => 'Moose Moose::Role MooseX::Role::Parameterized',
            behavior       => 'string list',
            list_always_present_values =>
                [qw< Moose Moose::Role MooseX::Role::Parameterized >],
        },
    );
}

sub default_severity { return $SEVERITY_HIGH; }
sub default_themes   { return qw< moose bugs >; }
sub applies_to       { return 'PPI::Document' }

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;

    return $self->_is_interesting_document($document);
}

sub _is_interesting_document {
    my ( $self, $document ) = @_;

    foreach my $module ( keys %{ $self->{_equivalent_modules} } ) {
        return $TRUE if $document->uses_module($module);
    }

    return $FALSE;
}

sub violates {
    my ( $self, undef, $document ) = @_;

    my @violations;
    foreach my $namespace ( $document->namespaces() ) {
    SUBDOCUMENT:
        foreach my $subdocument (
            $document->subdocuments_for_namespace($namespace) ) {
            next SUBDOCUMENT
                if not $self->_is_interesting_document($subdocument);

            if ( my $destructor
                = $subdocument->find_first( \&_is_constructor ) ) {
                push
                    @violations,
                    $self->violation(
                    $DESCRIPTION, $EXPLANATION,
                    $destructor
                    );
            }
        }
    }

    return @violations;
}

sub _is_constructor {
    my ( undef, $element ) = @_;

    return $FALSE if not $element->isa('PPI::Statement::Sub');

    return $element->name() eq 'new';
}

1;

# ABSTRACT: Don't override Moose's standard constructors.

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Moose::ProhibitNewMethod - Don't override Moose's standard constructors.

=head1 VERSION

version 1.05

=head1 DESCRIPTION

Overriding C<new()> on a L<Moose> class causes a number of problems, including
speed issues and problems with order of invocation of constructors when
multiple inheritance is involved. Use C<BUILDARGS()> and C<BUILD()> instead.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Moose>.

=head1 CONFIGURATION

There is a single option, C<equivalent_modules>. This allows you to specify
modules that should be treated the same as L<Moose> and L<Moose::Role>, if,
say, you were doing something with L<Moose::Exporter>. For example, if you
were to have this in your F<.perlcriticrc> file:

    [Moose::ProhibitNewMethod]
    equivalent_modules = MyCompany::Moose MooseX::NewThing

then the following code would result in a violation:

    package Baz;

    use MyCompany::Moose;

    sub new {
        ...
    }

=head1 SEE ALSO

=over 4

=item * L<Moose::Manual::Construction>

=item * L<Moose::Manual::BestPractices>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Critic-Moose>
(or L<bug-perl-critic-moose@rt.cpan.org|mailto:bug-perl-critic-moose@rt.cpan.org>).

I am also usually active on IRC as 'drolsky' on C<irc://irc.perl.org>.

=head1 AUTHORS

=over 4

=item *

Elliot Shank <perl@galumph.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 - 2016 by Elliot Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
