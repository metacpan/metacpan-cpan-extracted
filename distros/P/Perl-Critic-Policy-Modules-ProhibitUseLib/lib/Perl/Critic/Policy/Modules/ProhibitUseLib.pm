package Perl::Critic::Policy::Modules::ProhibitUseLib;
$Perl::Critic::Policy::Modules::ProhibitUseLib::VERSION = '0.004';

# ABSTRACT: Prohibit 'use lib' in modules

use strict;
use warnings;

use base 'Perl::Critic::Policy::logicLAB::ProhibitUseLib';

sub default_themes { return qw(portability) }

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;

    return $document->is_module();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Modules::ProhibitUseLib - Prohibit 'use lib' in modules

=head1 VERSION

version 0.004

=head1 DESCRIPTION

L<Perl::Critic::Policy::logicLAB::ProhibitUseLib> prohibits the use of C<use lib> in all files. This policy limits this to only modules.

This policy is a derivation of
L<Perl::Critic::Policy::logicLAB::ProhibitUseLib>, see it's documentation for
more information.

This policy puts itself into the C<portability> theme.

=head1 CONFIGURATION

There is no configuration option available for this policy.

=head1 AFFILIATION

This is a standalone policy not part of a larger PerlCritic Policies group.

=head1 SEE ALSO

=over 4

=item *

L<Perl::Critic::Policy::logicLAB::ProhibitUseLib>

=back

=head1 AUTHOR

Gregor Goldbach <glauschwuffel@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gregor Goldbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
