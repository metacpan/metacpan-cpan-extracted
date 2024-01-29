package Net::AS2::PSGI::StateHandler;

use strict;
use warnings;
use autodie;
our $VERSION = '1.0001'; # VERSION

=head1 NAME

Net::AS2::PSGI::FileHandler - Provides methods to handle files being sent and received

=cut

use parent 'Net::AS2::PSGI::File';

=head1 METHODS

=over 4

=item $self->file( $dir, $ext )

Return the state file in the given directory, <$dir>.

An optional additional extension may be given, C<$ext>.

=cut

sub file {
    my ($self, $dir, $ext) = @_;

    $ext //= '';

    return $self->SUPER::file($dir, '.state' . $ext);

}

=item $file = $self->save( $content, $dir, $ext )

Write C<$content> to state file with extension C<$ext> in directory, C<$dir>.

Returns the state file path.

=cut

sub save {
    my ($self, $content, $dir, $ext) = @_;

    my $file = $self->file($dir, $ext);

    $self->logger(debug => "Overwriting state file $file") if -f $file;

    $self->write($file, $content);

    $self->logger(debug => "Wrote state file $file");

    return $file;
}

=item $file = $self->move( $file, $dir, $ext, $text )

Move C<$file> to directory, C<$dir>, adding an optional extension C<$ext>.

Debuging level C<$text> is output to the logger, if defined.

Returns the path the file was moved to.

=cut

sub move {
    my ($self, $file, $dir, $ext, $text) = @_;

    $ext //= '';

    my $to = $self->file($dir, $ext);

    $self->logger(warn => "File already exists: $to $text") if -f $to;

    rename $file, $to;

    $self->logger(debug => "Moved state file to $to $text");

    return $to;
}


=item $content = $self->retrieve( $file, $text )

Read state file, C<$file>, returning its content.

Debuging level C<$text> is output to the logger, if defined.

=cut

sub retrieve {
    my ($self, $file, $text) = @_;

    $self->logger(debug => "About to read " . (-r $file ? 'readable' : 'not readable') . " file $file");

    local $/ = undef;

    open my $fh, '<', $file;
    my $content = scalar(<$fh>);
    close $fh;

    $self->logger(debug => $text);

    return $content;
}

=back

=cut

1;
