# ABSTRACT: permanently delete a stack

package App::Pinto::Command::kill;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

sub command_names { return qw(kill) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return ( [ 'force' => 'Kill even if stack is locked' ], );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error('Must specify exactly one stack')
        if @{$args} != 1;

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ( $self, $opts, $args ) = @_;

    my $result = $self->pinto->run( $self->action_name, %{$opts}, stack => $args->[0] );

    return $result->exit_status;
}

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

App::Pinto::Command::kill - permanently delete a stack

=head1 VERSION

version 0.097

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT kill [OPTIONS] STACK

=head1 DESCRIPTION

This command permanently deletes a stack.  Once a stack is killed, there 
is no direct way to get it back.  However, any distributions that were 
registered on the stack will still remain in the repository.

=head1 COMMAND ARGUMENTS

The required argument is the name of the stack you wish to kill.
Stack names must be alphanumeric plus hyphens and underscores, and
are not case-sensitive.

=head1 COMMAND OPTIONS

=over 4

=item --force

Kill the stack even if it is currently locked.  Normally, locked
stacks cannot be deleted.  Take care when deleting a locked stack
as it usually means the stack is important to someone.

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
