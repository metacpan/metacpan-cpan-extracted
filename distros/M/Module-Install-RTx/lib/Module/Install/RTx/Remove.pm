package Module::Install::RTx::Remove;

use base 'Exporter';
our @EXPORT = qw/RTxRemove/;

use strict;

=head1 DESCRIPTION

Remove specified files. Intended to remove files
from previously installed versions when upgrading
code in place.

=head1 USAGE

    perl -MModule::Install::RTx::Remove -e "RTxRemove([q(/full/dir/path/file_to_remove)])"

=head1 METHODS

=head2 RTxRemove

Removes specified files.

Accepts: Arrayref of files to remove. Files should have a full
directory path.

=cut

sub RTxRemove {
    my $remove_files = shift;

    # Trying the naive unlink first. If issues are reported,
    # look at ExtUtils::_unlink_or_rename for more cross-platform options.
    foreach my $file (@$remove_files){
        next unless -e $file;
        print "Removing $file\n";
        unlink($file) or warn "Could not unlink $file: $!";
    }
}
