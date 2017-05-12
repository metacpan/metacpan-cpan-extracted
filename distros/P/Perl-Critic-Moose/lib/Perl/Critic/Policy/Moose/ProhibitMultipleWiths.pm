package Perl::Critic::Policy::Moose::ProhibitMultipleWiths;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.05';

use Readonly ();

use Perl::Critic::Utils qw< :booleans :severities $EMPTY >;
use Perl::Critic::Utils::PPI qw< is_ppi_generic_statement >;

use base 'Perl::Critic::Policy';

Readonly::Scalar my $DESCRIPTION => 'Multiple calls to with() were made.';
Readonly::Scalar my $EXPLANATION =>
    q<Roles cannot protect against name conflicts if they are not composed.>;

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
sub default_themes   { return qw( bugs moose roles ); }
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

            my $with_statements = $subdocument->find( \&_is_with_statement );

            next SUBDOCUMENT if not $with_statements;
            next SUBDOCUMENT if @{$with_statements} < 2;

            my $second_with = $with_statements->[1];
            push
                @violations,
                $self->violation( $DESCRIPTION, $EXPLANATION, $second_with );
        }
    }

    return @violations;
}

sub _is_with_statement {
    my ( undef, $element ) = @_;

    return $FALSE if not is_ppi_generic_statement($element);

    my $current_token = $element->schild(0);
    return $FALSE if not $current_token;
    return $FALSE if not $current_token->isa('PPI::Token::Word');
    return $FALSE if $current_token->content() ne 'with';

    return $TRUE;
}

1;

# ABSTRACT: Require role composition

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Moose::ProhibitMultipleWiths - Require role composition

=head1 VERSION

version 1.05

=head1 DESCRIPTION

L<Moose::Role>s are, among other things, the answer to name conflicts plaguing
multiple inheritance and mix-ins. However, to enjoy this protection, you must
compose your roles together. Roles do not generate conflicts if they are
consumed individually.

Pass all of your roles to a single L<with|Moose/with> statement.

    # ok
    package Foo;

    use Moose::Role;

    with qw< Bar Baz >;

    # not ok
    package Foo;

    use Moose::Role;

    with 'Bar';
    with 'Baz';

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Moose>.

=head1 CONFIGURATION

There is a single option, C<equivalent_modules>. This allows you to specify
modules that should be treated the same as L<Moose> and L<Moose::Role>, if,
say, you were doing something with L<Moose::Exporter>. For example, if you
were to have this in your F<.perlcriticrc> file:

    [Moose::ProhibitMultipleWiths]
    equivalent_modules = MyCompany::Moose MooseX::NewThing

then the following code would result in a violation:

    package Baz;

    use MyCompany::Moose;

    with 'Bing';
    with 'Bong';

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
