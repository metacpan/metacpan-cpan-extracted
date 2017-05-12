use strict;
use warnings;
package MooseX::Daemonize::Pid::File;
# ABSTRACT: PID file management for MooseX::Daemonize

our $VERSION = '0.21';

use Moose;
use Moose::Util::TypeConstraints qw(coerce from via);

use MooseX::Types::Path::Class;
use MooseX::Getopt::OptionTypeMap;
use namespace::autoclean;

# NOTE:
# set up some basic coercions
# that will come in handy
# - SL
coerce 'MooseX::Daemonize::Pid::File'
    => from 'Str'
        => via { MooseX::Daemonize::Pid::File->new( file => $_ ) }
    => from 'ArrayRef'
        => via { MooseX::Daemonize::Pid::File->new( file => $_ ) }
    => from 'Path::Class::File'
        => via { MooseX::Daemonize::Pid::File->new( file => $_ ) };

# NOTE:
# make sure this class plays
# well with MooseX::Getopt
# - SL
MooseX::Getopt::OptionTypeMap->add_option_type_to_map(
    'MooseX::Daemonize::Pid::File' => '=s',
);

extends 'MooseX::Daemonize::Pid';

has '+pid' => (
    default => sub {
        my $self = shift;
        $self->does_file_exist
            ? $self->file->slurp(chomp => 1)
            : $$
    }
);

has 'file' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    coerce   => 1,
    required => 1,
    handles  => [ 'remove' ]
);

sub does_file_exist { -s (shift)->file }

sub write {
    my $self = shift;
    my $fh = $self->file->openw;
    $fh->print($self->pid . "\n");
    $fh->close;
}

override 'is_running' => sub {
    return 0 unless (shift)->does_file_exist;
    super();
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Daemonize::Pid::File - PID file management for MooseX::Daemonize

=head1 VERSION

version 0.21

=head1 DESCRIPTION

This object extends L<MooseX::Daemonize::Pid> to add persistence in a Pidfile.

This class sets up some basic coercion routines for itself so that it can
be created from a I<Str> (a file name), I<ArrayRef> (an array of path components
for a filename) or a I<Path::Class::File> object.

This class registers it's type with L<MooseX::Getopt> as well, and is expected
to be passed on the command line as a string (which will then go through the
coercion routines mentioned above).

=head1 ATTRIBUTES

=over

=item I<pid Int>

This is inherited from L<MooseX:Daemonize::Pid> and extended here to
get it's default value from the Pidfile (if available).

=item I<file Path::Class::File | Str>

=back

=head1 METHODS

=over

=item B<clear_pid>

=item B<has_pid>

Both of these methods are inherited from L<MooseX:Daemonize::Pid> see that
module for more information.

=item B<remove>

This removes the Pidfile.

=item B<write>

This writes the Pidfile.

=item B<does_file_exist>

This checks if the Pidfile exists.

=item B<is_running>

This checks if the Pidfile exists, if it does it checks to see if the process
is running, if the Pidfile doesn't exist, it returns false.

=item meta()

The C<meta()> method from L<Class::MOP::Class>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Daemonize>
(or L<bug-MooseX-Daemonize@rt.cpan.org|mailto:bug-MooseX-Daemonize@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Chris Prather <chris@prather.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
