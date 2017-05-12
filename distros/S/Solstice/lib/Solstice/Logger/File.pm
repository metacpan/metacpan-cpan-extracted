package Solstice::Logger::File;

# $Id: File.pm 2393 2005-07-18 17:12:40Z jlaney $

=head1 NAME

Solstice::Logger::File - Dispatches a log message to a file.

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Logger);

use Solstice::Model::LogMessage;

use Fcntl qw(:DEFAULT :flock);

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 1 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=item writeLog($message)

=cut

sub writeLog {
    my $self = shift;
    my $message = shift;

    return FALSE unless (defined $message && defined $message->getContent());

    my $content = '';

    if (my $username = $message->getUsername()) {
        $content .= $username.' ';
    }
    if (my $acting_username = $message->getActingUsername()) {
        $content .= $acting_username.' ';
    }
    if (my $datetime = $message->getDateTime()) {
        # We only log a date if a DateTime obj is defined, but we're 
        # not using the DateTime object itself, due to a bug in 
        # Solstice::DateTime (no day_of_week data available)
        $content .= '['.(scalar localtime).'] ';
    }
    if (my $model = $message->getModel()) {
        $content .= $message->getModel().' ';
    }
    if (my $model_id = $message->getModelID()) {
        $content .= '('.$model_id.') ';
    }
    $content .= $message->getContent();
  
    return $self->_writeToFile($self->_getFilePath($message), $content);
}

=back

=head2 Private Methods

=over 4

=cut

=item _getFilePath($message)

=cut

sub _getFilePath {
    my $self = shift;
    my $message = shift;

    return unless ($message->getNamespace() && $message->getLogName());

    my $file_path = $self->getConfigService()->getDataRoot().'/';
    $self->_dirCheck($file_path);
    $file_path .= lc($message->getNamespace()).'/';
    $self->_dirCheck($file_path);
    $file_path .= $message->getLogName();

    return $file_path;
}

=item _writeToFile($file, $message)

=cut

sub _writeToFile {
    my $self = shift;
    my $file_path = shift;
    my $message = shift;

    return FALSE unless defined $file_path;
    
    $message =~ s/\n/\\n/g;
    $message .= "\n";

    open(my $LOG, '>>', $file_path)
        or die "Cannot open '$file_path': $!\n";
    flock($LOG, LOCK_EX)
        or die "Cannot lock '$file_path' for writing: $!\n";
    seek($LOG, 0, 2)
        or die "Cannot seek to end of '$file_path': $!\n";
    print $LOG $message
        or die "Cannot write to '$file_path': $!\n";
    close($LOG);

    return TRUE;
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Logger|Solstice::Logger>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

Version $Revision: 3177 $

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut

