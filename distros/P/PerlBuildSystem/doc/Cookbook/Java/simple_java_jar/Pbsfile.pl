=for PBS =head1 PBSFILE HELP

=head2 Simple Java build classes and add them to a jar file

=head2 Targets

=over 2 

=item * all

=back

=for PBS STOP

=cut

#-------------------------------------------------------------------------------

=head1 COOKBOOK FOR JAVA

We let PBS know that B<.java> and B<.txt> files are considered source code.

=cut

#-------------------------------------------------------------------------------

ExcludeFromDigestGeneration('java-files' => qr/\.java$/);
ExcludeFromDigestGeneration('manifest' => qr/\.txt$/);

#-------------------------------------------------------------------------------

my @classes = qw(Main.class Print.class) ;

=head1 Rules

=head2 all

We declare a rule to match the I<all> target. This is a conveniance rule
as we could build all classes directly from the command line.

=cut

AddRule [VIRTUAL], 'all', ['all' => 'classes.jar'] 
	=> BuildOk() ;

=head2 jar-dist

Rule I<jar-dist> matches a target named B<classes.jar> and declares a dependency
to a matching B<.class> file and B<Manifest.txt> file.

=cut

AddRule 'jar-dist', [ 'classes.jar' => @classes, 'Manifest.txt' ] , \&BuildJar;
    
=head2 classes

Rule I<classes> matches any taget that ends with B<.class> and declares a dependency
to a matching B<.java> file.

The I<javac> command is passed the path of the file to build and the B<.java> file.

=cut

AddRule 'classes', ['*/*.class' => '*.java']
    => 'javac -d %FILE_TO_BUILD_PATH %DEPENDENCY_LIST'; 
    
#-------------------------------------------------------------------------------

sub BuildJar
{
	my ($config, $file_to_build, $dependencies) = @_ ;
	my $dependency_list = "";
	my $manifest        = "";

	#
	# Go through dependencies and exclude any .txt file i.e the
	# Manifest.txt file
	#
	for my $dependency (@$dependencies) 
	{
		if ($dependency =~ /\.txt$/)
		{
			$manifest = $dependency;
		}
		else
		{
			$dependency_list .= $dependency . " ";
		}
	}

	#
	# Build the command line to build the jar file
	#
	my $cmdline = "jar cmvf $manifest $file_to_build $dependency_list";
	RunShellCommands($cmdline);
	return(1, "OK BuildJar") ;
}



