package Perl::Achievements::Command::init;
BEGIN {
  $Perl::Achievements::Command::init::AUTHORITY = 'cpan:YANICK';
}
{
  $Perl::Achievements::Command::init::VERSION = '0.4.0';
}
# ABSTRACT: initializes the perl-achievements environment

use 5.10.0;


use 5.10.0;

use strict;
use warnings;

use Path::Class qw/ file /;

use Moose;

extends 'Perl::Achievements::Command';

sub execute {
    my $self = shift;

    $self->initialize_environment;

    say $self->rc, ' created';

    say "you might want to edit ", file( $self->rc, 'config' ), 
        " with your name and information";
}


1;

__END__
=pod

=head1 NAME

Perl::Achievements::Command::init - initializes the perl-achievements environment

=head1 VERSION

version 0.4.0

=head1 SYNOPSIS

    perl-achievement init [ --rc $dir ]

=head1 DESCRIPTION

Creates the directory where the configuration and the state
of C<perl-achievements> will be kept. 

If the directory is not explicitly given via the argument I<--rc> , defaults to 
(if defined) the environment variable I<PERL_ACHIEVEMENTS_HOME>,
or I<$HOME/.perl_achievements>.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

