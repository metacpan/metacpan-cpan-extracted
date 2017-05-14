# ABSTRACT: report statistics about the repository

package App::Pinto::Command::statistics;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

# TODO: Add a --stack option, just like the "list" command.

#------------------------------------------------------------------------------

sub command_names { return qw( statistics stats ) }

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error('Multiple arguments are not allowed')
        if @{$args} > 1;

    $opts->{stack} = $args->[0]
        if $args->[0];

    return 1;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

App::Pinto::Command::statistics - report statistics about the repository

=head1 VERSION

version 0.097

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT statistics [STACK]

=head1 DESCRIPTION

!! THIS COMMAND IS EXPERIMENTAL !!

This command reports some statistics about the repository.

=head1 COMMAND ARGUMENTS

The argument is the name of the stack you wish to see the statistics for. If
you do not specify a stack, then the default stack will be used.

=head1 COMMAND OPTIONS

None.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
