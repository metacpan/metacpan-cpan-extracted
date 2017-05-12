package Sys::CmdMod::Plugin::Nice;
{
  $Sys::CmdMod::Plugin::Nice::VERSION = '0.18';
}
BEGIN {
  $Sys::CmdMod::Plugin::Nice::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: CmdMod Plugin for nice

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

extends 'Sys::CmdMod::Plugin';

has 'niceness' => (
    'is'       => 'rw',
    'isa'      => 'Num',
    'default'  => 19,
);

sub _init_priority { return 10; }

sub BUILD {
    my $self = shift;

    if ( !-x $self->binary() ) {
        die( 'Could not find nice executable at ' . $self->binary() );
    }
}

sub _init_binary {
    my $self = shift;

    return $self->_find_binary('nice');
}

sub cmd {
    my $self = shift;
    my $cmd  = shift;
    return $self->binary() . ' -n ' . $self->niceness() . q{ } . $cmd;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sys::CmdMod::Plugin::Nice - CmdMod Plugin for nice

=head1 NAME

Sys::CmdMod::Plugin::Nice - nice processes

=head1 METHODS

=head2 BUILD

Initialize this module.

=head2 cmd

Prepend the nice invocation.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
