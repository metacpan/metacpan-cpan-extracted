=for PBS =head1 PBSFILE HELP

=head2 Simple Java build two classes example

=head2 Targets

=over 2 

=item * all

=back

=for PBS STOP

=cut

#-------------------------------------------------------------------------------

=head1 COOKBOOK FOR JAVA

We let PBS know that B<.java> files are considered source code.

=cut

#-------------------------------------------------------------------------------

ExcludeFromDigestGeneration('java-files' => qr/\.java$/);

#-------------------------------------------------------------------------------

my @classes = qw(Main.class Print.class) ;

=head1 Rules

=head2 all

We declare a rule to match the I<all> target. This is a conveniance rule
as we could build all classes directly from the command line.

=cut

AddRule [VIRTUAL], 'all', ['all' => @classes] => BuildOk() ;

=head2 classes

Rule I<classes> matches any taget that ends with B<.class> and declares a dependency
to a matching B<.java> file.

The I<javac> command is passed the path of the file to build and the B<.java> file.

=cut

AddRule 'classes', ['*/*.class' => '*.java']
    , 'javac -d %FILE_TO_BUILD_PATH %DEPENDENCY_LIST'; 
    
