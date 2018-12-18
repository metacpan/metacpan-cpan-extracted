package Perl::Critic::Policy::Reneeb::Capitalization;

# ABSTRACT: NamingConventions::Capitalization plus the ability to exempt "Full qualified package names"

use strict;
use warnings;

use base 'Perl::Critic::Policy::NamingConventions::Capitalization';

our $VERSION = '2.02';

sub supported_parameters {
    my ($self) = @_;

    my @params = $self->SUPER::supported_parameters();

    push @params, {
        name           => 'full_qualified_package_exemptions',
        description    => 'Package names that are exempt from capitalization rules.  The values here are regexes that will be surrounded by \A and \z.',
        default_string => 'main',
        behavior       => 'string list',
    };

    return @params;
}

sub initialize_if_enabled {
    my ($self, $config) = @_;

    my $return = $self->SUPER::initialize_if_enabled( $config );

    my $option = $self->{_full_qualified_package_exemptions};

    my $configuration_exceptions =
        Perl::Critic::Exception::AggregateConfiguration->new();

    for my $pattern ( sort keys %{$option} ) {
        my $regex;
        eval { $regex = qr{ \A $pattern \z }xms; }
            or do {
                $configuration_exceptions->add_exception(
                    Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue->new(
                        policy          => $self,
                        option_name     => '_full_qualified_package_exemptions',
                        option_value    => $pattern,
                        message_suffix  =>
                            "is not a valid regular expression: $@",
                    )
                );
            };
    }

    if ( $configuration_exceptions->has_exceptions ) {
        $configuration_exceptions->throw;
    }

    return $return;
}

sub _package_capitalization {
    my ($self, $elem) = @_;
 
    my $namespace = $elem->namespace();
    my $option    = $self->{_full_qualified_package_exemptions};

    for my $pattern ( sort keys %{$option} ) {
        return if $namespace =~ m{\A $pattern \z}xms;
    }
 
    return $self->SUPER::_package_capitalization( $elem );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Reneeb::Capitalization - NamingConventions::Capitalization plus the ability to exempt "Full qualified package names"

=head1 VERSION

version 2.02

=head1 METHODS

=head2 supported_parameters

Same parameters as for L<Perl::Critic::Policy::NamingConventions::Capitalization> plus
C<full_qualified_package_exemptions>.

=head2 initialize_if_enabled

Checks the parameters

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
