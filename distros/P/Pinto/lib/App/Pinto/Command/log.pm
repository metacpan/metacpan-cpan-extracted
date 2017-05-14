# ABSTRACT: show the revision logs of a stack

package App::Pinto::Command::log;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

sub command_names { return qw(log history) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return ( [ 'stack|s=s' => 'Show history for this stack' ], );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error('Multiple arguments are not allowed') if @{$args} > 1;

    $opts->{stack} = $args->[0] if $args->[0];

    return 1;
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

App::Pinto::Command::log - show the revision logs of a stack

=head1 VERSION

version 0.097

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT log [STACK] [OPTIONS]

=head1 DESCRIPTION

!! THIS COMMAND IS EXPERIMENTAL !!

This command shows the commit logs for the stack.  To see the precise
changes in any particular commit, use the L<App::Pinto::Command::show>
command.

=head1 COMMAND ARGUMENTS

As an alternative to the C<--stack> option, you can specify it as
an argument.  So the following examples are equivalent:

  pinto --root REPOSITORY_ROOT log --stack=dev
  pinto --root REPOSITORY_ROOT log dev

A C<stack> argument will override anything specified with the
C<--stack> option. If the stack is not specified using neither 
argument nor option, then the logs of the default stack will 
be shown.

=head1 COMMAND OPTIONS

=over 4

=item --stack NAME

=item -s NAME

Show the logs of the stack with the given NAME.  Defaults to the name
of whichever stack is currently marked as the default stack.  Use the
L<stacks|App::Pinto::Command::stack> command to see the stacks in the
repository.

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
