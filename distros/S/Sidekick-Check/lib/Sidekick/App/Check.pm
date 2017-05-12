#!/usr/bin/perl
package Sidekick::App::Check;
{
  $Sidekick::App::Check::VERSION = '0.0.1';
}

use v5.10;

use strict;
use warnings;
use mro;

use Sidekick::Check;

use Log::Log4perl qw(:nowarn);

my $logger = Log::Log4perl->get_logger();

sub check {
    my $self   = shift;
    my $method = shift
        || return 'Sidekick::Check';

    return Sidekick::Check->$method( @_ );
}

1;
# ABSTRACT: Sidekick::App's interface for Sidekick::Check
# vim:ts=4:sw=4:syn=perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Sidekick::App::Check - Sidekick::App's interface for Sidekick::Check

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    use parent qw(
            Sidekick::App
            Sidekick::App::Check
            ...
        );

=head1 DESCRIPTION

Adds a check method to a Sidekick::App.

=head1 AUTHOR

André Rivotti Casimiro <rivotti@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by André Rivotti Casimiro.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
