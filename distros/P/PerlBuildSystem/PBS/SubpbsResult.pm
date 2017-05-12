
package PBS::SubpbsResult ;

use strict ;
use warnings ;

=head1 NAME

PBS::SubpbsResult - Support for hierarchical projects

=head1 SYNOPSIS

  use PBS::SubpbsResult ;

 my $subpbs_result = new PBS::SubpbsResult($file_name) ;
 my @search_paths = @{ $subpbs_result->GetLibrarySearchPaths()} ;

=head1 DESCRIPTION

Pbs strives to let you build hierarchical projects, this module simplifies the task of returning sub module information
to the module parent. This module is amainly used in Builders.

This module lets you create files which hold the information. Below are two examples.

=head2 linker information

Say you have module A which has a link dependency on module B. Module B needs to be linked with and extra library.
A and B are build in different project (a subpbs for B exists).

When linking your project,  you need to know at the top level what B needs to be linked with. To avoid putting knowledge
of B's dependencies  in the build of A, we would like the link information to be returned in a generic way to A.

Module B build result, when invoked from A's build is a '.subpbs_result' file.

 # make A depend on B's build result
 AddRule 'module B', ['A.o' => 'some_A_file.o', 'B.subpbs_result'], \&Build_A ;
 
 # Build B in a subpbs
 AddSubpbRule('B.subpbs_result', 'somepbs_file.pl')
 
 sub Build_A
 {
 use PBS::SubpbsResult ;
 ...
 
 my @objects_to_link ;
 my @libs ;
 my @other_specific_information ;
 my $very_special_information ;
 
 for my $dependency (@dependencies)
	{
	if($dependency =~ /\.subpbs_result/)
		{
		my $subpbs_result = new PBS::SubpbsResult($dependency) ;
		
		push @objects_to_link, GetObjects($subpbs_result) ;
		push @libs, GetLibraries($subpbs_result) ;
		
		push @other_specific_information = GetOtherSpecificInformation($subpbs_result) ;
		$very_special_information = GetVerySpecialInformation($subpbs_result)[0] ;
		}
	}
 ...
 }
 
 # in somepbs_file.pl
 
 my @libraries = ('some_lib', 'some_other_lib') ;
 my @other_specific_information = ('specific1', 'specific2') ;
 my $very_special_information = 1 ;
 
 AddRule 'B.subpbs_result', ['B.subpbs_result' => 'b1.o', 'b2.o', 'C.subpbs_result'], \&BuildSubpbsResult ;
 
 sub BuildSubpbsResult
 {
 ...
 
 use PBS::SubpbsResult ;
 my $subpbs_result = new PBS::SubpbsResult() ;
 
 for my $dependency (@dependencies)
	{
	if($dependency =~ /\.subpbs_result$/)
		{
		$subpbs_result->Append($dependency) ;
		}
	else
		{
		$subpbs_result->AddObjects({NAME =>$dependency, MD5 => $md5}) ;
		}
	}
 
 $subpbs_result->AddLibraries(@libraries) ;
 $subpbs_result->AddWithMd5('other_specific_information', @other_specific_information) ;
 $subpbs_result->Add('very_special_information', $very_special_information) ;
 
 $subpbs_result->Write($dependent) ;
 }
 

=head2 speeding sub module archives creation

We (Anders and I) had a project, which had a top-down hierarchy, though of building archives at all the sub levels and 
merge the archives while going up the levels. We soon find out that 'ar' didn't merge archives so we had to unpack the 
sub levels archives before archiving them again. That took very long time! We stopped using 'ar' and instead uses a pbs_result
file where the archive was replaced with a list of file links.

=head1 MEMBER FUNCTIONS

=cut

require Exporter ;

#~ don't "use AutoLoader;" we define our own

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;

our $VERSION = '0.02' ;

use Data::Dumper ;
use Data::TreeDumper ;

#-------------------------------------------------------------------------------

sub new
{
=head2 new

Create a new SubpbsResult object. an optional setup argument can be passed to i<new>

=cut

my ($package, $setup_data)  = @_ ;

my $this = {} ;
bless($this, $package) ;

$this->Read($setup_data)  if defined $setup_data ;

return($this) ;
}

#-------------------------------------------------------------------------------

sub Append
{
=head2 Append

This function can be passed a SubpbsResult or the name of a file containing a SubpbsResult
serialization (Done with Data::Dumper).

=cut

my ($this, $setup_data)  = @_ ;

if(ref $setup_data eq ref $this)
	{
	# append SubpbsResult object
	die "unimplemented!" ;
	}
elsif(ref $setup_data eq '')
	{
	my ($this, $file_name)  = @_ ;

	my $new_this = do $file_name or die "Couldn't evaluate SubpbsResult file '$file_name'\nFile error: $!\nCompilation error: $@\n" ;

	#~ print DumpTree $new_this, 'new this' ;
	die "not a SubpbsResult object in file '$file_name'" unless(ref $new_this eq ref $this) ;
	
	for my $class (keys %$new_this)
		{
		$this->Add($class,  @{$new_this->{$class}}) ;
		}
	}
else
	{
	die "Invalid setup data!" ;
	}
}

#-------------------------------------------------------------------------------

sub Add
{
=head2 Add

Adds an entry to the object. The entry class is created if it doesn't exist.

Arguments:

=over 2

=item * entry class, a string

=item * entry, a perl scalar,  a simple scalar or a reference.

=back

=cut

#~ print DumpTree \@_, 'Add arguments' ;

my ($this, $class, @entries)  = @_ ;

unless(ref $class eq '')
	{
	my ($package, $file_name, $line) = caller() ;
	die "unexpected class name @ $file_name, $line" ;
	}

push @{$this->{$class}}, @entries ;
}

#-------------------------------------------------------------------------------

sub Get
{
=head2 Get

Returns the list of values added in the class.

Arguments:

=over 2

=item * entry class, a string

=back

=cut

#~ print DumpTree \@_, 'Get arguments' ;

my ($this, $class)  = @_ ;

if(@_ > 2)
	{
	my ($package, $file_name, $line) = caller() ;
	die "unexpected amount of arguments @ $file_name, $line" ;
	}

unless(ref $class eq '')
	{
	my ($package, $file_name, $line) = caller() ;
	die "unexpected class name @ $file_name, $line" ;
	}

if(exists $this->{$class})
	{
	return($this->{$class}) ;
	}
else
	{
	# could warn here!
	return([]) ;
	}
}

#-------------------------------------------------------------------------------

sub Read
{
=head2 Read

Deserialized the object from a file.

Arguments:

=over 2

=item * file name

=back

=cut

my ($this, $file_name)  = @_ ;

my $new_this = do $file_name or die "Couldn't evaluate SubpbsResult file '$file_name'\nFile error: $!\nCompilation error: $@\n" ;

#~ print DumpTree $new_this, 'new this' ;
die "not a SubpbsResult object in file '$file_name'" unless(ref $new_this eq ref $this) ;

# buddhist re-incarnation
%{$this} = %{$new_this} ;
}

#-------------------------------------------------------------------------------

sub Write
{
=head2 Write

Serialized the object to a file.

Arguments:

=over 2

=item * file name

=back

=cut

my ($this, $file_name)  = @_ ;

open(FILE, ">", $file_name) or die qq[Can't open $file_name: $!] ;

local $Data::Dumper::Purity = 1 ;
local $Data::Dumper::Indent = 1 ;
local $Data::Dumper::Sortkeys = undef ;

print FILE Data::Dumper->Dump([$VERSION], ['version']) ;
print FILE "\n" ;
print FILE Data::Dumper->Dump([$this], ['result']) ;
print FILE "\n\n" ;

close(FILE) ;
}

#-------------------------------------------------------------------------------

sub DESTROY{}

#-------------------------------------------------------------------------------

sub AUTOLOAD 
{
no strict ;

#~ $|++ ;	
#~ print "AUTOLOADING $AUTOLOAD!!!!\n" ;

if($AUTOLOAD =~ /::Add(.+)$/)
	{
	my $class_name = $1 ;
	my $name = "Add$1" ;
	*$name = sub {my ($this, @entries)  = @_ ; return $this->Add($class_name, @entries)} ;

	goto &$name ;
	}
elsif($AUTOLOAD =~ /::Get(.+)$/)
	{
	my $class_name = $1 ;
	my $name = "Get$1" ;
	*$name = sub {my ($this)  = @_ ; return $this->Get($class_name)} ;

	goto &$name ;
	}
else
	{
	die "can't generate function $AutoLoader::AUTOLOAD!\n" ;
	}
}

#-------------------------------------------------------------------------------
1 ;


=head1 EXPORT

Nothing.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=cut
