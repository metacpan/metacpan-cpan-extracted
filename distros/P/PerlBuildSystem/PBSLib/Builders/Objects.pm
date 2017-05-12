=head1 PBSFILE USER HELP

=head2 I<Objects.pm>


=cut

=head2 Top rules

=over 2

=item * None defined -- this is a library module.

=back

=head2 Utility functions

=over 2

=item * CreateObjectsFile

          This function is a builder for .objects files and creates a file containing
        all the object-file dependencies of the current directory. Any .objects files
        specified as a dependency to the .objects file being built will be expanded;
        that is, a .objects file contains all of the object file dependencies of the
        current directory and all subdirectories it depends on.

          These files are used to quickly find all the dependencies of a (sub)directory
        for inclusion in e.g. linking.

        Example:

          AddRule 'my.objects', [ 
                                  '%TARGET_PATH/my.objects' =>   'subdir/other.objects'
                                                               , 'cool_stuff.o'
                                                               , 'more_stuff.o'
                                ]
          => \&CreateObjectsFile ;

=cut

use File::Slurp;

#-------------------------------------------------------------------------------

use PBS::SubpbsResult ;

sub CreateObjectsFile
{
#~ use Data::TreeDumper ;
#~ PrintInfo DumpTree \@_ ;
my ($config, $file_to_build, $dependencies) = @_ ;
my $object_files = '';

my $subpbs_result = new PBS::SubpbsResult() ;

for my $dependency (@$dependencies)
	{
	if($dependency =~ /\.objects$/)
		{
		$subpbs_result->Append($dependency) ;
		}
	else
		{
		my $md5 = GetFileMD5($dependency) ;
		$subpbs_result->AddFileAndMd5({FILE => $dependency, MD5 => $md5}) ;
		}
	}

$subpbs_result->AddLibrarySearchPaths(@{$config->{LIBRARIES_SEARCH_PATHS}}) ;

$subpbs_result->Write($file_to_build)
}

#-------------------------------------------------------------------------------
1 ;
