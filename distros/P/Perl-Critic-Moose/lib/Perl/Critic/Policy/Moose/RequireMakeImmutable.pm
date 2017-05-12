package Perl::Critic::Policy::Moose::RequireMakeImmutable;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.05';

use Readonly ();

use Perl::Critic::Utils qw< :booleans :severities >;
use Perl::Critic::Utils::PPI qw< is_ppi_generic_statement >;

use base 'Perl::Critic::Policy';

Readonly::Scalar my $DESCRIPTION => 'No call was made to make_immutable().';
Readonly::Scalar my $EXPLANATION =>
    q<Moose can't optimize itself if classes remain mutable.>;

sub supported_parameters {
    return (
        {
            name => 'equivalent_modules',
            description =>
                q<The additional modules to treat as equivalent to "Moose".>,
            default_string             => 'Moose',
            behavior                   => 'string list',
            list_always_present_values => [qw< Moose >],
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM; }
sub default_themes   { return qw( moose performance ); }
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

    my $makes_immutable = $document->find_any(
        sub {
            my ( undef, $element ) = @_;

            return $FALSE if not is_ppi_generic_statement($element);

            my $current_token = $element->schild(0);
            return $FALSE if not $current_token;
            return $FALSE if not $current_token->isa('PPI::Token::Word');
            return $FALSE if $current_token->content() ne '__PACKAGE__';

            $current_token = $current_token->snext_sibling();
            return $FALSE if not $current_token;
            return $FALSE if not $current_token->isa('PPI::Token::Operator');
            return $FALSE if $current_token->content() ne '->';

            $current_token = $current_token->snext_sibling();
            return $FALSE if not $current_token;
            return $FALSE if not $current_token->isa('PPI::Token::Word');
            return $FALSE if $current_token->content() ne 'meta';

            $current_token = $current_token->snext_sibling();
            return $FALSE if not $current_token;
            if ( $current_token->isa('PPI::Structure::List') ) {
                $current_token = $current_token->snext_sibling();
                return $FALSE if not $current_token;
            }

            return $FALSE if not $current_token->isa('PPI::Token::Operator');
            return $FALSE if $current_token->content() ne '->';

            $current_token = $current_token->snext_sibling();
            return $FALSE if not $current_token;
            return $FALSE if not $current_token->isa('PPI::Token::Word');
            return $FALSE if $current_token->content() ne 'make_immutable';

            return $TRUE;
        }
    );

    return if $makes_immutable;
    return $self->violation( $DESCRIPTION, $EXPLANATION, $document );
}

1;

# ABSTRACT: Ensure that you've made your Moose code fast

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Moose::RequireMakeImmutable - Ensure that you've made your Moose code fast

=head1 VERSION

version 1.05

=head1 DESCRIPTION

L<Moose> is very flexible. That flexibility comes at a performance cost. You
can ameliorate some of that cost by telling Moose when you are done putting
your classes together.

Thus, if you C<use Moose>, this policy requires that you do
C<< __PACKAGE__->meta()->make_immutable() >>.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Moose>.

=head1 CONFIGURATION

There is a single option, C<equivalent_modules>. This allows you to specify
modules that should be treated the same as L<Moose> and L<Moose::Role>, if,
say, you were doing something with L<Moose::Exporter>. For example, if you
were to have this in your F<.perlcriticrc> file:

    [Moose::RequireMakeImmutable]
    equivalent_modules = MyCompany::Moose MooseX::NewThing

then the following code would result in a violation:

    package Baz;

    use MyCompany::Moose;

    sub new {
        ...
    }

    # no make_immutable call

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
