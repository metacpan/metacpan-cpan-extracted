# ABSTRACT: display a command's help screen

package App::Pinto::Command::help;

use strict;
use warnings;

use base qw(App::Cmd::Command::help);

#-------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#-------------------------------------------------------------------------------
# This is just a thin subclass of App::Cmd::Command::help.  All we have done is
# extend the exeucte() method to mention the "pinto manual" command at the end

sub execute {
    my ( $self, $opts, $args ) = @_;

    my ( $cmd, undef, undef ) = $self->app->prepare_command(@$args);
    my ($cmd_name) = $cmd->command_names;

    my $rv = $self->SUPER::execute( $opts, $args );

    # Only display this if showing help for a specific command.
    print qq{For more information, run "pinto manual $cmd_name"\n} if @{$args};

    return $rv;
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

App::Pinto::Command::help - display a command's help screen

=head1 VERSION

version 0.097

=head1 SYNOPSIS

  pinto help COMMAND

=head1 DESCRIPTION

This command shows a brief help screen for a pinto COMMAND.

=head1 COMMAND ARGUMENTS

The argument to this command is the name of the command you would like help
on.  You can also use the L<manual|App::Pinto::Command::manual> command to get
extended documentation for any command.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
