package Statocles::Store::File;
our $VERSION = '0.088';
# ABSTRACT: (DEPRECATED) A store made up of plain files

use Statocles::Base 'Class';
use Statocles::Util qw( derp );
extends 'Statocles::Store';

derp "Statocles::Store::File is deprecated and will be removed in v1.000. Please use Statocles::Store instead.";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Store::File - (DEPRECATED) A store made up of plain files

=head1 VERSION

version 0.088

=head1 DESCRIPTION

This store was removed and its functionality put completely into L<Statocles::Store>.
This module is deprecated and will be removed at the 2.0 release according to the
deprecation policy L<Statocles::Help::Policy>. See L<Statocles::Help::Upgrading>
for how to upgrade.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
