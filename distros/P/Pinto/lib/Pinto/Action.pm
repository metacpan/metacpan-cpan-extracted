# ABSTRACT: Base class for all Actions

package Pinto::Action;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Result;
use Pinto::Util qw(throw);
use Pinto::Constants qw($PINTO_LOCK_TYPE_SHARED);

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Plated );

#------------------------------------------------------------------------------

has repo => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    required => 1,
);

has result => (
    is       => 'ro',
    isa      => 'Pinto::Result',
    default  => sub { Pinto::Result->new },
    init_arg => undef,
    lazy     => 1,
);

has lock_type => (
    is       => 'ro',
    isa      => Str,
    default  => $PINTO_LOCK_TYPE_SHARED,
    init_arg => undef,
);

#------------------------------------------------------------------------------

sub BUILD { }

#------------------------------------------------------------------------------

sub execute { throw 'Abstract method' }

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer BenRifkah Fowler Jakob Voss Karen Etheridge Michael
G. Bergsten-Buret Schwern Oleg Gashev Steffen Schwigon Tommy Stanton
Wolfgang Kinkeldei Yanick Boris Champoux hesco popl Däppen Cory G Watson
David Steinbrunner Glenn

=head1 NAME

Pinto::Action - Base class for all Actions

=head1 VERSION

version 0.097

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
