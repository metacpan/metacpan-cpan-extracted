package Net::AS2::PSGI::File;

use strict;
use warnings;
use autodie qw(:file :filesys);

our $VERSION = '1.0001'; # VERSION

=head1 NAME

Net::AS2::PSGI::File - Base class for managing files in the AS2 PSGI application

=head1 CONSTRUCTOR

=over 4

=item $file = $class->new($message_id, $logger)

Returns an object for handling files used with the AS2 PSGI
application.

=cut

sub new {
    my ($class, $message_id, $logger) = @_;

    my $self = bless { logger => $logger }, $class;

    $self->message_id($message_id);

    return $self;
}

=back

=head1 METHODS

=over 4

=item $message_id = $self->message_id( $id )

Set, if given C<$id>, or get the current message_id.

=cut

sub message_id {
    my ($self, $message_id) = @_;

    if ($message_id) {
        $self->{message_id} = $message_id;

        $message_id =~ s{[^-@.a-zA-Z0-9]}{_}g;
        $self->{message_filename} = $message_id;
    }

    return $self->{message_id};
}

=item $file = $self->file( $dir, $ext )

Return suitable file name in the given directory, C<dir>, using the
associated message id and optional extension, C<ext>.

=cut

sub file {
    my ($self, $dir, $ext) = @_;

    $ext //= '';

    return sprintf('%s/%s%s', $dir, $self->{message_filename}, $ext);
}

=item $self->logger( $level, $text )

Outputs a message to the PSGI logger at the given level, if a PSGI
logger has been defined.

The full message output format is set to the logger with the given
C<level>:

 <message_id> : text

=cut

sub logger {
    my ($self, $level, $text) = @_;

    my $logger = $self->{logger} or return;

    my $message_id = $self->message_id;

    $logger->({ level => $level, message => sprintf('<%s> : %s', $message_id, $text) });

    return;
}

=item $self->write( $file, $content )

Writes C<$content> to C<$file>.

=cut

sub write { ## no critic (ProhibitBuiltinHomonyms)
    my ($self, $file, $content) = @_;

    $content //= '';

    open my $fh, '>', $file;
    print $fh $content;
    close $fh;

    return;
}

=back

=cut

1;
