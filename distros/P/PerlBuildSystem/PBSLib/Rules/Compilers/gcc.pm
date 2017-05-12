=head2 Utility functions

=over 2

=item * LinkWith

          This function I<returns> a builder for default linking with the libraries
        specified as arguments. The arguments are a list of library I<names> to include
        in linking (without suffix) -- to link with e.g. the system math library, libm.a,
        specify 'libm'. Again, note that this is a function that I<returns> a builder,
        not a builder in itself -- it should be called with arguments rather as passed
        as a builder reference.

        Example:

          AddRule 'mytool', [ '%TARGET_PATH/mytool' => 'mytool.objects' ], LinkWith('libm');


=back

=cut

use File::Slurp;
use Devel::Depend::Cpp 0.03 ;

#-------------------------------------------------------------------------------

use PBS::SubpbsResult ;

sub LinkWith
{
my $extra_libraries = join(' ', @_);

my $sub = sub
	{
	my ($config, $file_to_build, $dependency_list) = @_ ;
	
	my $object_files = '';
	
	for my $dependency (@$dependency_list)
		{
		next if ($dependency =~ /\.so$/);
		
		if($dependency =~ /\.objects$/)
			{
			my $subpbs_result = new PBS::SubpbsResult($dependency ) ;
			
			$object_files .= join("\n", GetFiles($subpbs_result)) . "\n" ;
			
			my @search_paths = @{ $subpbs_result->GetLibrarySearchPaths()} ;
			$extra_libraries .= '  /L' .  join('  /L' , @search_paths) if @search_paths ;
			
			# libs are normal dependencies
			#~ my @libraries = GetLibraries($subpbs_result) ;
			#~ $extra_libraries .= ' ' .  join(' ' ,  @libraries) if @libraries ;
			}
		else
			{
			$object_files .= "$dependency\n";
			}
		}
		
	my $link_command_file = "$file_to_build.link";
	write_file($link_command_file, $object_files) ;
	
	RunShellCommands("$config->{CC} $config->{CFLAGS} -o $file_to_build $link_command_file $extra_libraries $config->{LDFLAGS}");
	} ;
	
return($sub) ;
}

sub GetFiles
{
# extract files from fileAndMd5 class

my ($subpbs_result) = @_ ;

return
	(
	map{$_->{FILE}} @{ $subpbs_result->GetFileAndMd5()}
	) ;
}

#-------------------------------------------------------------------------------
1 ;


__END__
