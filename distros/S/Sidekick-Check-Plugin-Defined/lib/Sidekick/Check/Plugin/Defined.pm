#!/usr/bin/perl
package Sidekick::Check::Plugin::Defined;
{
  $Sidekick::Check::Plugin::Defined::VERSION = '0.0.1';
}

use strict;
use warnings;

sub check { return defined $_[1] || 0 }

1;
# ABSTRACT: Check if a given value is defined
# vim:ts=4:sw=4:syn=perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Sidekick::Check::Plugin::Defined - Check if a given value is defined

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    $ok     = Sidekick::Check::Plugin::Defined->check( $value );

    my $sc  = Sidekick::Check->new();
    $ok     = $sc->is_defined( $value );
    @errors = $sc->errors( $value, 'defined' );

=head1 DESCRIPTION

Check if a given value is defined.

=head1 SEE ALSO

=over 4

=item *

L<Sidekick::Check>

=back

=head1 AUTHOR

André Rivotti Casimiro <rivotti@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by André Rivotti Casimiro.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
