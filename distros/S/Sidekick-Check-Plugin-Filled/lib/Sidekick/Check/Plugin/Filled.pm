#!/usr/bin/perl
package Sidekick::Check::Plugin::Filled;
{
  $Sidekick::Check::Plugin::Filled::VERSION = '0.0.1';
}

use strict;
use warnings;

sub check { return length $_[1] || 0 }

1;
# ABSTRACT: Check if a given value is filled
# vim:ts=4:sw=4:syn=perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Sidekick::Check::Plugin::Filled - Check if a given value is filled

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    $ok     = Sidekick::Check::Plugin::Filled->check( $value );

    my $sc  = Sidekick::Check->new();
    $ok     = $sc->is_filled( $value );
    @errors = $sc->errors( $value, 'filled' );

=head1 DESCRIPTION

Check if a given value is filled.

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
