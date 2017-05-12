package Perl::Critic::Policy::Moose::RequireCleanNamespace;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.05';

use Readonly ();

use Perl::Critic::Utils qw< :booleans :severities $PERIOD >;

use base 'Perl::Critic::Policy';

Readonly::Scalar my $EXPLANATION =>
    q<Don't leave things used for implementation in your interface.>;

sub supported_parameters {
    return (
        {
            name        => 'modules',
            description => 'The modules that need to be unimported.',
            default_string =>
                'Moose Moose::Role Moose::Util::TypeConstraints MooseX::Role::Parameterized',
            behavior => 'string list',
        },
        {
            name           => 'cleaners',
            description    => 'Modules that clean imports.',
            default_string => 'namespace::autoclean',
            behavior       => 'string list',
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM; }
sub default_themes   { return qw( moose maintenance ); }
sub applies_to       { return 'PPI::Document' }

sub violates {
    my ( $self, undef, $document ) = @_;

    my %modules = ( use => {}, require => {}, no => {} );
    my $includes = $document->find('PPI::Statement::Include');
    return if not $includes;

    for my $include ( @{$includes} ) {

        # skip if nothing imported
        if ( $include->type eq 'use' ) {
            my $lists = $include->find('PPI::Structure::List');
            next if $lists and not grep { $_->children > 0 } @{$lists};
        }

        $modules{ $include->type }->{ $include->module } = 1;
    }

    return if grep { $modules{use}{$_} } keys %{ $self->{_cleaners} };

    my $modules_to_unimport = $self->{_modules};
    my @used_but_not_unimported
        = grep { $modules_to_unimport->{$_} and not $modules{no}->{$_} }
        keys %{ $modules{use} };

    return if not @used_but_not_unimported;

    return $self->violation(
              q<Didn't unimport >
            . ( join q<, >, sort @used_but_not_unimported )
            . $PERIOD,
        $EXPLANATION,
        $document,
    );
}

1;

# ABSTRACT: Require removing implementation details from you packages.

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Moose::RequireCleanNamespace - Require removing implementation details from you packages.

=head1 VERSION

version 1.05

=head1 DESCRIPTION

Anything in your namespace is part of your interface. The L<Moose> sugar is an
implementation detail and not part of what you want to support as part of your
functionality, especially if you may change your implementation to not use
Moose in the future. Thus, this policy requires you to say C<no Moose;> or
C<no Moose::Role;>, etc. as appropriate for modules you C<use>.

=for stopwords unimport

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Moose>.

=head1 CONFIGURATION

By default, this module will complain if you C<use> L<Moose>, L<Moose::Role>,
or C<Moose::Util::TypeConstraints> but don't unimport them. You can set the
modules looked for using the C<modules> option.

    [Moose::RequireCleanNamespace]
    modules = Moose Moose::Role Moose::Util::TypeConstraints MooseX::My::New::Sugar

This module also knows that L<namespace::autoclean> will clean out imports. If
you'd like to allow other modules to be recognized as namespace cleaners, you
can set the C<cleaners> option.

    [Moose::RequireCleanNamespace]
    cleaners = My::Cleaner

If you use C<use> a module with an empty import list, then this module knows
that nothing needs to be cleaned, and will ignore that particular import.

=head1 SEE ALSO

L<Moose::Manual::BestPractices>

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
