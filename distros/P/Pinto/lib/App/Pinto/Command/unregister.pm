# ABSTRACT: remove packages from a stack

package App::Pinto::Command::unregister;

use strict;
use warnings;

#------------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#-----------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return (
        [ 'dry-run'               => 'Do not commit any changes' ],
        [ 'force'                 => 'Remove packages even if pinned' ],
        [ 'message|m=s'           => 'Message to describe the change' ],
        [ 'stack|s=s'             => 'Remove packages from this stack' ],
        [ 'use-default-message|M' => 'Use the generated message' ],
    );
}

#------------------------------------------------------------------------------

sub args_attribute { return 'targets' }

#------------------------------------------------------------------------------

sub args_from_stdin { return 1 }

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

App::Pinto::Command::unregister - remove packages from a stack

=head1 VERSION

version 0.097

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT unregister [OPTIONS] TARGET ...

=head1 DESCRIPTION

!! THIS COMMAND IS EXPERIMENTAL !!

This command unregisters packages from a stack, so that they no longer
appear in its index.  However, the archives that contain the packages
will remain in the repository.  When unregistering, all the sister 
packages in the same distribution are also unregistered.

To permanently remove an archive from the repository, use the
L<delete|App::Pinto::Command::delete> command. To re-register packages
on a stack, use the L<register|App::Pinto::Command::register> command.

=head1 COMMAND ARGUMENTS

Arguments are the targets that you want to unregister.  Targets can be
specified as packages (with or without version number) or distributions.  
For example:

  Foo::Bar                                 # Unregisters any version of Foo::Bar
  Foo::Bar~1.2                             # Unregisters Foo::Bar 1.2 or higher
  SHAKESPEARE/King-Lear-1.2.tar.gz         # Unregisters a specific distribuion

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --dry-run

Go through all the motions, but do not actually commit any changes to
the repository.  Use this option to see how the command would potentially
impact the stack.

=item --force

Unregister packages even if they are pinned to the stack.  Take care when
unregistering pinned packages, as it usually means that particular package
is important to someone.

=item --message=TEXT

=item -m TEXT

Use TEXT as the revision history log message.  If you do not use the
C<--message> option or the C<--use-default-message> option, then you
will be prompted to enter the message via your text editor.  Use the
C<EDITOR> or C<VISUAL> environment variables to control which editor
is used.  A log message is not required whenever the C<--dry-run>
option is set, or if the action did not yield any changes to the
repository.

=item --stack=NAME

Unregisters the targets from the stack with the given NAME.  Defaults 
to the name of whichever stack is currently marked as the default stack.
Use the L<stacks|App::Pinto::Command::stacks> command to see the
stacks in the repository.

=item --use-default-message

=item -M

Use the default value for the revision history log message.  Pinto
will generate a semi-informative log message just based on the command
and its arguments.  If you set an explicit message with C<--message>,
the C<--use-default-message> option will be silently ignored.

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
