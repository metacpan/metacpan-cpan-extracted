# ABSTRACT: show the full manual for a command

package App::Pinto::Command::manual;

use strict;
use warnings;

use Pod::Usage qw(pod2usage);

use base qw(App::Pinto::Command);

#-------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#-------------------------------------------------------------------------------

sub command_names { return qw( manual man --man ) }

#-----------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error("Must specify a command") if @{$args} != 1;

    return 1;
}

#-------------------------------------------------------------------------------
# This was stolen from App::Cmd::Command::help

sub execute {
    my ( $self, $opts, $args ) = @_;

    my ( $cmd, undef, undef ) = $self->app->prepare_command(@$args);

    my $class = ref $cmd;

    # An invalid command name was specified, so the fallback command class 
    # was returned.  Rather than showing the (unhelpful) manual for 
    # App::Cmd::Command::commands, we will just bail out and let App::Cmd
    # show the usual 'unrecognized command' message.
    return 1 if $class eq 'App::Cmd::Command::commands';

    ( my $relative_path = $class ) =~ s< :: ></>xmsg;
    $relative_path .= '.pm';

    my $absolute_path = $INC{$relative_path}
        or die "No manual available for $class\n";

    pod2usage( -verbose => 2, -input => $absolute_path, -exitval => 0 );

    return 1;
}

#-------------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer BenRifkah Fowler Jakob Voss Karen Etheridge Michael
G. Bergsten-Buret Schwern Oleg Gashev Steffen Schwigon Tommy Stanton
Wolfgang Kinkeldei Yanick Boris Champoux hesco popl Däppen Cory G Watson
David Steinbrunner Glenn

=head1 NAME

App::Pinto::Command::manual - show the full manual for a command

=head1 VERSION

version 0.097

=head1 SYNOPSIS

  pinto manual COMMAND

=head1 DESCRIPTION

This command shows the complete user manual for a pinto COMMAND.

=head1 COMMAND ARGUMENTS

The argument to this command is the name of the command for which you would
like to see the manual.  You can also use the L<help|App::Pinto::Command::help> 
command to get a brief summary of the command.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
