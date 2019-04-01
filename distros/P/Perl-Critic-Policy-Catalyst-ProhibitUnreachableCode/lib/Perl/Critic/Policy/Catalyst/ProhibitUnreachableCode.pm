package Perl::Critic::Policy::Catalyst::ProhibitUnreachableCode;
use 5.008001;
use strict;
use warnings;
our $VERSION = '0.01';

use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion :classification };
use base 'Perl::Critic::Policy';

Readonly::Array my @CONDITIONALS => qw( if unless foreach while until for );
Readonly::Hash  my %CONDITIONALS => hashify( @CONDITIONALS );

Readonly::Array my @OPERATORS => qw( && || // and or err ? );
Readonly::Hash  my %OPERATORS => hashify( @OPERATORS );

Readonly::Scalar my $DESC => q{Unreachable code};
Readonly::Scalar my $EXPL => q{Consider removing it};

sub supported_parameters {
    return(
        {
            name           => 'context_methods',
            description    => 'Catalyst context methods which terminate execution',
            behavior       => 'string list',
            default_string => '',
            list_always_present_values =>
                [qw( detach redirect_and_detach )],
        },
        {
            name           => 'controller_methods',
            description    => 'Catalyst controller methods which terminate execution',
            behavior       => 'string list',
            default_string => '',
        },
    );
}

sub default_severity { $SEVERITY_HIGH }
sub default_themes   { qw( core bugs certrec catalyst ) }
sub applies_to       { 'PPI::Token::Word' }

sub violates {
    my ($self, $element) = @_;

    return if !is_method_call( $element );

    my $statement = $element->statement();
    return if !$statement;

    my @context_methods = keys %{ $self->{_context_methods} };
    my @controller_methods = keys %{ $self->{_controller_methods} };

    return unless (
        _is_terminating_context_method( $element, \@context_methods ) or
        _is_terminating_controller_method( $element, \@controller_methods )
    );

    for my $child ( $statement->schildren() ) {
        return if $child->isa('PPI::Token::Operator') && exists $OPERATORS{$child};
        return if $child->isa('PPI::Token::Word') && exists $CONDITIONALS{$child};
    }

    return $self->_gather_violations($statement);
}

sub _is_terminating_context_method {
    my ($element, $methods) = @_;

    my $found_method = 0;
    foreach my $method (@$methods) {
        next if $element ne $method;
        $found_method = 1;
        last;
    }
    return 0 if !$found_method;

    my $prev = $element->sprevious_sibling();
    return 0 if !$prev;
    return 0 if $prev ne '->';
    return 0 if !$prev->isa('PPI::Token::Operator');

    $prev = $prev->sprevious_sibling();
    return 0 if !$prev;
    return 0 if $prev ne '$c';
    return 0 if !$prev->isa('PPI::Token::Symbol');

    return 1;
}

sub _is_terminating_controller_method {
    my ($element, $methods) = @_;

    my $found_method = 0;
    foreach my $method (@$methods) {
        next if $element ne $method;
        $found_method = 1;
        last;
    }
    return 0 if !$found_method;

    my $prev = $element->sprevious_sibling();
    return 0 if !$prev;
    return 0 if $prev ne '->';
    return 0 if !$prev->isa('PPI::Token::Operator');

    $prev = $prev->sprevious_sibling();
    return 0 if !$prev;
    return 0 if $prev ne '$self';
    return 0 if !$prev->isa('PPI::Token::Symbol');

    # Save this check for last as its likely the most expensive.
    return 0 if _find_package_name( $element ) !~ m{::Controller::};

    return 1;
}

sub _find_package_name {
    my ($element) = @_;

    my $original = $element;

    while ($element) {
        if ($element->isa('PPI::Statement::Package')) {
            # If this package statements is a block package, meaning: package { # stuff in package }
            # then if we're a descendant of it its our package.
            return $element->namespace() if $element->ancestor_of( $original );

            # If we've hit a non-block package then thats our package.
            my $blocks = $element->find_any('PPI::Structure::Block');
            return $element->namespace() if !$blocks;
        }

        # Keep walking backwards until we match the above logic or we get to
        # the document root (main).
        $element = $element->sprevious_sibling() || $element->parent();
    }

    return 'main';
}

sub _gather_violations {
    my ($self, $statement) = @_;

    my @violations = ();
    while ( $statement = $statement->snext_sibling() ) {
        my @children = $statement->schildren();
        last if @children && $children[0]->isa('PPI::Token::Label');
        next if $statement->isa('PPI::Statement::Sub');
        next if $statement->isa('PPI::Statement::End');
        next if $statement->isa('PPI::Statement::Data');
        next if $statement->isa('PPI::Statement::Package');

        next if $statement->isa('PPI::Statement::Include') &&
            $statement->type() ne 'require';

        next if $statement->isa('PPI::Statement::Variable') &&
            $statement->type() eq 'our';

        push @violations, $self->violation( $DESC, $EXPL, $statement );
    }

    return @violations;
}

1;
__END__

=encoding utf-8

=head1 NAME

Perl::Critic::Policy::Catalyst::ProhibitUnreachableCode -
Don't write code after an unconditional Catalyst detach.

=head1 DESCRIPTION

This module was forked from
L<Perl::Critic::Policy::ControlStructures::ProhibitUnreachableCode>
version C<1.132> and modified to fit.

The primary difference is this module looks for these two
Catalyst specific bits of code as signifying a terminating statement:

    $c->detach();
    $c->redirect_and_detach();

The C<redirect_and_detach> context method is available if you are using
L<Catalyst::Plugin::RedirectAndDetach>.

=head1 PARAMETERS

=head2 context_methods

By default this policy looks for the C<detach> and C<redirect_and_detach>
context methods.  You can specify additional context methods to look for
with the C<context_methods> parameter.  In your C<.perlcriticrc> this
would look something like:

    [Catalyst::ProhibitUnreachableCode]
    context_methods = my_detaching_method my_other_detaching_method

This policy would then consider all of the following lines as
terminating statements:

    $c->detach();
    $c->redirect_and_detach();
    $c->my_detaching_method();
    $c->my_other_detaching_method();

=head2 controller_methods

Sometimes controllers have in-house methods which call C<detach>, you
can specify those:

    [Catalyst::ProhibitUnreachableCode]
    controller_methods = foo bar

Then this policy would look for any package with C<::Controller::> in
its name and would consider the following lines as terminating
statements:

    $self->foo();
    $self->bar();

There are no default methods for this parameter.

=head1 SUPPORT

Please submit bugs and feature requests to the
Perl-Critic-Policy-Catalyst-ProhibitUnreachableCode GitHub issue tracker:

L<https://github.com/bluefeet/Perl-Critic-Policy-Catalyst-ProhibitUnreachableCode/issues>

=head1 AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>
    Peter Guzis <pguzis@cpan.org>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
