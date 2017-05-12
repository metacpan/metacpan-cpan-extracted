#!/usr/bin/perl

package MooseX::Compile::CLI;
use Moose;

extends qw(MooseX::App::Cmd);

our $VERSION = "0.01";

__PACKAGE__

__END__

=pod

=head1 NAME

MooseX::Compile::CLI - Command line interface for MooseX::Compile

=head1 SYNOPSIS

    > mxcompile help

    > mxcompile compile

    > mxcompile clean

=head1 TODO

=over 4

=item *

Add an C<inspect> command that helps you look at C<.mopc> files.

=back

=head1 SEE ALSO

L<MooseX::Compile>, L<MooseX::App::Cmd>

=head1 VERSION CONTROL

L<http://code2.0beta.co.uk/moose/svn/MooseX-Compile-CLI/trunk>

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

    Copyright (c) 2008 Infinity Interactive, Yuval Kogman. All rights reserved
    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

=cut
