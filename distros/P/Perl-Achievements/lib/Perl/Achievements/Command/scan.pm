package Perl::Achievements::Command::scan;
BEGIN {
  $Perl::Achievements::Command::scan::AUTHORITY = 'cpan:YANICK';
}
{
  $Perl::Achievements::Command::scan::VERSION = '0.4.0';
}
# ABSTRACT: inspects scripts/modules for achievements

use 5.10.0;


use strict;
use warnings;

use Moose;

extends 'Perl::Achievements::Command';

sub execute {
    my ( $self, undef, $args ) = @_;

    for ( @$args ) {
        $self->log_debug( "scanning '$_'..." );
        $self->scan( $_ );
    }
}

1;

__END__
=pod

=head1 NAME

Perl::Achievements::Command::scan - inspects scripts/modules for achievements

=head1 VERSION

version 0.4.0

=head1 SYNOPSIS

    perl-achievement scan <files...>

=head1 DESCRIPTION

Inspects the given files for achievements.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

