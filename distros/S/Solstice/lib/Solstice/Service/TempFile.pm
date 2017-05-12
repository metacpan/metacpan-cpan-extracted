package Solstice::Service::TempFile;

# $Id: Memory.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::Service::Memory - For storing information that will last the lifetime of the mod_perl thread.

=head1 SYNOPSIS

  use base qw(Solstice::Service::Memory);

  sub new {
    my $obj = shift;
    return $obj->SUPER::new(@_);
  }

=head1 DESCRIPTION

Creates an API for subclasses to use to manage and make available persisted global data. 

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service::Memory);

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

our $data_store = {};

use constant TMP_PATH   => "/tmp/";

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new()

Creates a new Solstice::Service::Memory object.

=cut

sub new {
    my $obj = shift;
    return $obj->SUPER::new(@_);
}

sub getFilePath {
    my $self = shift;
    my $path = $self->getConfigService()->getDataRoot().TMP_PATH;
    $self->_dirCheck($path);
    $path .= "solstice_temp_".$$.rand();
    
    #tuck this path away so we can clean it up later
    my $tmp_files = $self->getValue('tmp_files') || [];
    push @$tmp_files, $path;
    $self->setValue('tmp_files', $tmp_files);
    
    return $path;
}

sub getFileHandle {
    my $self = shift;
    my $path = $self->getFilePath();
    open(my $file_handle, ">", "$path") or die "Could not open temp file: $@";
    return $file_handle;
}

#cleanup all files for this request
sub cleanupFiles {
    my $self = shift;
    my $files = $self->getValue('tmp_files');

    return unless $files;
    
    foreach my $file (@$files) {
        unlink($file);
    }

    #cleanout files in memory
    $self->setValue('tmp_files', undef);
}

#cleanup all temp files older then x hours
sub cleanupOldFiles {
    my $self = shift;
    my $path = $self->getConfigService()->getDataRoot().TMP_PATH;

    return unless -d $path;

    my @files = split(/\s/, `ls $path`);
    
    foreach my $file (@files){
        my $mtime = (stat $path.$file)[9];
        my $seconds = time - $mtime;
        next unless $seconds > 60*60*5;
        unlink($path.$file);
    }

}

=back

=head2 Private Methods

=over 4

=cut

1;
__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $



=cut

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
