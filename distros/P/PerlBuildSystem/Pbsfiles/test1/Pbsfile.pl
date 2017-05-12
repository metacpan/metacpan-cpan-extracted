
=head1 I<Pbsfile.pl>

=head2 Description

This Pbsfile is an axample that is distributed with B<PBS>.

=cut

=head1 PBSFILE USER HELP

=head2 I<Pbsfile.pl>

I<Pbsfile.pl> is to be used with the Perl Build System (B<PBS>).

=head2 Description

This I<Pbsfile> come with PBS distribution. It contains some examples of what you can do with I<pbs.pl> and B<PBS>

=cut 

=head2 Top rules

=over 2 

=item * all

=item * exe

=back

=cut

=head2 Uses rules and Config from

=over 2 

=item * Rules/C

=item * Configs/ShellCommands

=item * Configs/gcc

=cut

PbsUse('Rules/C') ; 
PbsUse('Configs/gcc') ;


#-------------------------------------------------------------------------------
=comment

Some  comments that won't apear if --uh is used.

=cut

#~AddRule 'local_test1', ['all' => 'local_test'] ;
#~AddRule [LOCAL], 'local_test2', ['local_test' => '__NO_DEPENDENCIES'] ;
#~AddRule 'local_test3', ['local_test' => 'local_test2', 'local_test1'] ;


=head2 Uses sub I<Pbsfile>

=over 2

=item * ./P2.pl

=cut

sub P1BuildLib
{
PrintInfo("P1 builder called\n") ;
return(0, "P1 builder") ;
}

#~AddRule 'all_lib',['all' => '[path]/[basename]_exe'] ;

AddRule [VIRTUAL], 'all_lib',['all' => 'x.lib:1.0', 'lib.lib', 'this.lib', 'HERE.o:1.01'], BuildOk() ;

#~AddRule 'all_lib', ['all' => qw(lib.lib)] ;

# rules bellow to test graph generation
AddRule 'test', ['all' => 'HERE', 'A'] ;
AddRule [FORCED], 'ho', ['HERE' => undef] ;
AddRule 'hz', ['HERE' => 'x.z'] ;
AddRule 'lz', ['A' => 'x.z'] ;
AddRule 'tz', ['this.lib' => 'HERE', 'lib.z'] ;
AddRule 'az', ['all' => 'lib.h', 'HERE'] ;
#~ AddRule 'cyclic', ['A' => 'all'] ;

#~ AddRule 'test', ['/*.c' => '/[basename].z'] ;

#~ AddRule 'test', ['/all' => '/there.o'] ;
#~ AddRule 'test', ['/*all' => '/there.o'] ;

#~ AddRule 'test', ['a.h' => '/[basename].a.[ext]'] ;

#~AddRule 'test', ['HERE.o' => ['lib.lib' , './P2.pl', 'LIBS2'] ] ;
#~AddRule 'test', ['HERE.o' => ['lib.lib' , './P3.pl', 'LIBS2'] ] ;

AddRule 'sub_pbsfile',
	{
	  NODE_REGEX => 'lib.lib'
	, PBSFILE => 'P2.pl'
	, PACKAGE => 'LIB'
	} ;

RegisterUserCheckSub
(
sub
	{
	my ($full_name, $user_attribute) = @_ ;
	#print "$full_name => $user_attribute\n" ;
	return($_[0]) ; # must return a file name
	}
) ;

AddRule 'sub_pbsfile2',
	{
	  NODE_REGEX         => 'x.lib' 
	, PBSFILE            => 'P2.pl'
	, PACKAGE            => 'LIB'
	#, BUILD_DIRECTORY    => '/bd_P2'
	#, SOURCE_DIRECTORIES => ['/sd_P2_2', '/sd_P2_1']
	} ;

#~AddRule 'lib', ['lib.lib' => qw(:lib.lib_P1)], \&P1BuildLib, ['P1argument'] ;

=head2 Documentations for User Build

Example ...

blah ...

User options:

	-u something to do something
	-u something_else ....

=cut


=head1 Escape out of PBSFILE USER HELP!

=cut
