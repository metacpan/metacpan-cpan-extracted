package Perl::Dist::WiX::DirectoryTree;

=pod

=head1 NAME

Perl::Dist::WiX::DirectoryTree - Base directory tree for Perl::Dist::WiX.

=head1 VERSION

This document describes Perl::Dist::WiX::DirectoryTree version 1.500.

=head1 SYNOPSIS

	$tree = Perl::Dist::WiX::DirectoryTree->instance();
	
	# See each method for examples.

=head1 DESCRIPTION

This is an object that represents the main directory tree for the 
installer.  This tree contains all directories being created that
are referenced in more than one fragment, and all directories that
need to have specific IDs.

=cut

use 5.010;

#use metaclass (
#	base_class  => 'MooseX::Singleton::Object',
#	metaclass   => 'MooseX::Singleton::Meta::Class',
#	error_class => 'WiX3::Util::Error',
#);
use MooseX::Singleton;
use Params::Util qw( _IDENTIFIER _STRING _INSTANCE );
use File::Spec::Functions qw( catdir catpath splitdir splitpath );
use MooseX::Types::Moose qw( Str HashRef );
use MooseX::Types::Path::Class qw( Dir );
use Perl::Dist::WiX::Types qw( DirectoryTag );
use Perl::Dist::WiX::Tag::Directory;
use WiX3::Exceptions;
use Scalar::Util qw(weaken);
use namespace::clean -except => 'meta';

our $VERSION = '1.500';
$VERSION =~ s/_//sm;

with 'WiX3::Role::Traceable';

=head1 METHODS

=head2 new

	my $tree = Perl::Dist::WiX::DirectoryTree->new(
		app_dir => 'C:\strawberry',
		app_name => 'Strawberry Perl'
	);

Creates new directory tree object and creates the 'root' of the tree.

Note that this object is a L<MooseX::Singleton|MooseX::Singleton> object,
so that you can retrieve the object at any time using the 
C<instance()> method.

=cut

# This is private, but retrievable by 'get_root'.
has _root => (
	is       => 'bare',
	isa      => DirectoryTag,
	reader   => 'get_root',
	required => 1,
	handles  => {
		'get_directory_object'     => 'get_directory_object',
		'_add_directory_recursive' => '_add_directory_recursive',
		'_indent'                  => 'indent',
	},
);


# This is private.
has _cache => (
	traits   => ['Hash'],
	is       => 'ro',
	isa      => HashRef [DirectoryTag],
	init_arg => undef,
	default  => sub { {} },
	handles  => {
		'_get_cache_entry' => 'get',
		'_is_in_cache'     => 'exists',
	},
);


sub _add_to_cache {
	my $self = shift;
	my ( $key, $value );
	while ( 0 < scalar @_ ) {
		$key   = shift;
		$value = shift;
		weaken( $self->_cache()->{$key} = $value );
	}
	return;
}


=head3 app_dir

This is set to the distribution's image_dir (where the distribution is
going to be installed by default.) 

=cut


has app_dir => (
	is       => 'ro',
	isa      => Dir,
	reader   => '_get_app_dir',
	required => 1,
	coerce   => 1,
);


=head3 app_name

This is set to the name of the distribution, and is used to set the
name of the Start Menu directory containing the distribution's icons.

=cut

has app_name => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_app_name',
	required => 1,
);

#####################################################################
# Constructor for DirectoryTree
#
# Parameters: [pairs]

sub BUILDARGS {
	my $class = shift;
	my %args;

	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( 0 == @_ % 2 ) {
		%args = (@_);
	} else {
		PDWiX->throw(
'Parameters incorrect (not a hashref or a hash) for DirectoryTree'
		);
	}

	my $app_dir = $args{'app_dir'}
	  or PDWiX::Parameter->throw(
		parameter => 'app_dir',
		where     => 'Perl::Dist::WiX::DirectoryTree->new'
	  );

	if ( exists $args{_root} ) {

		# If we're recreating, the assumption is that
		# we know what we're doing.
		return \%args;
	} else {

		# Create the root directory object.
		my $root = Perl::Dist::WiX::Tag::Directory->new(
			id       => 'TARGETDIR',
			name     => 'SourceDir',
			path     => "$app_dir",
			noprefix => 1,
		);

		return {
			_root => $root,
			%args
		};
	} ## end else [ if ( exists $args{_root...})]
} ## end sub BUILDARGS

=head2 instance

	my $tree = Perl::Dist::WiX::DirectoryTree->instance();
	
Returns the previously created directory tree. 

=head2 get_root

	my $directory_object = $tree->get_root();
	
Gets the L<Perl::Dist::WiX::Tag::Directory|Perl::Dist::WiX::Tag::Directory> 
object at the root of the tree.
	
=head2 as_string

	my $string = $tree->as_string();
	
This method returns an XML representation of the directory tree.

=cut

sub as_string {
	my $self = shift;

	my $string = $self->get_root()->as_string();

	return $string ne q{} ? $self->_indent( 4, $string ) : q{};
}

=head2 initialize_tree

	$tree->initialize_tree($perl_version, $bits, $gcc_version);

Adds a basic directory structure to the directory tree object.

=cut

sub initialize_tree {
	my $self = shift;
	my $ver  = shift;
	my $bits = shift || 32;
	my $gcc  = shift || 3;

	$self->trace_line( 2, "Initializing directory tree.\n" );

	# Create starting directories.
	my $branch = $self->get_root()->add_directory( {
			id       => 'INSTALLDIR',
			noprefix => 1,
			path     => $self->_get_app_dir()->stringify(),
		} );
	my $app_menu = $self->get_root()->add_directory( {
			id       => 'ProgramMenuFolder',
			noprefix => 1,
		}
	  )->add_directory( {
			id   => 'App_Menu',
			name => $self->_get_app_name(),
		} );

#<<<
	$app_menu->add_directories_id(
		'App_Menu_Tools',    'Tools',
		'App_Menu_Websites', 'Related Websites',
	);

	$branch->add_directories_id(
		'Perl',      'perl',
		'Toolchain', 'c',
		'License',   'licenses',
		'Cpan',      'cpan',
		'Win32',     'win32',
		'Cpanplus',  'cpanplus',
	);
#>>>

	my $perl = $self->get_directory_object('D_Perl');
	$perl->add_directories_id( 'PerlSite', 'site' );

	my $perlsite = $self->get_directory_object('D_PerlSite');
	$perlsite->add_directories_id( 'PerlSiteBin', 'bin' );
	$perlsite->add_directories_id( 'PerlSiteLib', 'lib' );

	my $cpan = $self->get_directory_object('D_Cpan');
	$cpan->add_directories_id( 'CpanSources', 'sources' );

	my @list = qw(
	  c\\bin
	  c\\include
	  c\\lib
	  c\\libexec
	  c\\mingw32
	  c\\share
	  perl\\bin
	  perl\\lib\\auto
	  perl\\site\\lib\\auto
	  perl\\vendor\\lib\\auto\\share\\dist
	  perl\\vendor\\lib\\auto\\share\\module
	);

# We have to get every possibility of directories immediately under
# the 'c' directory, or linking errors occur, as c is found first in later files.
	if ( 64 == $bits ) {
		push @list, 'c\\lib64';
		push @list, 'c\\x86_64-w64-mingw32';
	}

	foreach my $dir (@list) {
		$self->add_directory(
			$self->_get_app_dir()->subdir($dir)->stringify() );
	}

	return $self;
} ## end sub initialize_tree



=head2 initialize_short_tree

	$tree->initialize_short_tree();

Adds a basic directory structure to the directory tree object.

This is used when including a merge module that already 
contains a L<Perl::Dist::WiX|Perl::Dist::WiX>-based perl
distribution.

=cut



sub initialize_short_tree {
	my $self = shift;

	$self->trace_line( 2, "Initializing short directory tree.\n" );

	# Create starting directories.
	my $branch = $self->get_root()->add_directory( {
			id       => 'INSTALLDIR',
			noprefix => 1,
			path     => $self->_get_app_dir()->stringify(),
		} );
	my $app_menu = $self->get_root()->add_directory( {
			id       => 'ProgramMenuFolder',
			noprefix => 1,
		}
	  )->add_directory( {
			id   => 'App_Menu',
			name => $self->_get_app_name(),
		} );

#<<<
	$app_menu->add_directories_id(
		'App_Menu_Tools',    'Tools',
		'App_Menu_Websites', 'Related Websites',
	);

	$branch->add_directories_id(
		'Win32',     'win32',
		'Perl',      'perl',
	);
#>>>

	# This is so that the binaries to make icons of can be found.
	$self->add_directory( catdir( $self->_get_app_dir(), 'perl\\bin' ) );

	return $self;
} ## end sub initialize_short_tree

=head2 add_directory

	$tree->add_directory($directory);

Adds a directory to the tree, including all directories required along 
the way.
	
=cut

sub add_directory {
	my $self = shift;
	my $dir  = shift;

	if ( not defined _STRING($dir) ) {
		PDWiX::Parameter->throw(
			parameter => 'dir',
			where     => '::DirectoryTree->add_directory'
		);
	}

	$self->trace_line( 3, "Adding directory with path $dir to tree.\n" );

	# Does the directory already exist?
	# If so, short-circuit.
	return 1
	  if (
		$self->search_dir(
			path_to_find => $dir,
			descend      => 1,
			exact        => 1,
		) );

	my ( $volume, $dirs, undef ) = splitpath( $dir, 1 );
	my @dirs         = splitdir($dirs);
	my $dir_to_add   = pop @dirs;
	my $path_to_find = catdir( $volume, @dirs );

	$self->trace_line( 5,
"  Adding directory recursively: $path_to_find, $dir_to_add to tree.\n"
	);
	my $dir_out =
	  $self->_add_directory_recursive( $path_to_find, $dir_to_add );

	return defined $dir_out ? 1 : 0;
} ## end sub add_directory



=head2 add_root_directory

	$self->add_root_directory('Id', 'directory');

Adds a directory entry with the ID and directory name given
immediately under the main installation directory.
	
=cut



sub add_root_directory {
	my $self = shift;
	my $id   = shift;
	my $dir  = shift;

	my $branch = $self->get_directory_object('INSTALLDIR');
	return $branch->add_directories_id( $id, $dir );
}



=head2 add_merge_module

	$tree->add_merge_module('C:\strawberry', $mergemodule_object);

This method inserts a merge module (referred to by a 
L<Perl::Dist::WiX::Tag::MergeModule|Perl::Dist::WiX::Tag::MergeModule> 
object) into the directory tree at the specified directory.

=cut



sub add_merge_module {
	my $self = shift;
	my $dir  = shift;
	my $mm   = shift;

	my $directory_object = $self->search_dir( path_to_find => $dir );
	if ( not defined $directory_object ) {
		PDWiX->throw("Could not find object for directory $dir");
	}

	if ( not defined _INSTANCE( $mm, 'Perl::Dist::WiX::Tag::MergeModule' ) )
	{
		PDWiX->throw(
			'Second parameter not Perl::Dist::WiX::Tag::MergeModule object'
		);
	}

	$directory_object->add_child_tag($mm);

	return 1;
} ## end sub add_merge_module



=head2 search_dir

Calls L<Perl::Dist::WiX::Directory's search_dir routine|Perl::Dist::WiX::Directory/search_dir>
on the root directory with the parameters given.

Checks a cache of successful searches if descend and exact are both 1.

=cut



sub search_dir {
	my $self = shift;

	my %args;

	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( @_ % 2 == 0 ) {
		%args = @_;
	} else {
		PDWiX->throw('Invalid number of arguments to search_dir');
	}

	# Set defaults for parameters.
	my $path_to_find = _STRING( $args{'path_to_find'} )
	  || PDWiX::Parameter->throw(
		parameter => 'path_to_find',
		where     => '::DirectoryTree->search_dir'
	  );
	my $descend = $args{descend} || 1;
	my $exact   = $args{exact}   || 0;

	if ( ( 1 == $descend ) and ( 1 == $exact ) ) {

		# Check cache, return what's in it if needed.
		if ( $self->_is_in_cache($path_to_find) ) {
			$self->trace_line( 3,
				"Found $path_to_find in directory tree cache.\n" );
			return $self->_get_cache_entry($path_to_find);
		}
	}

	my $dir = $self->get_root()->search_dir(@_);

	if ( ( defined $dir ) and ( 1 == $descend ) and ( 1 == $exact ) ) {
		$self->_add_to_cache( $path_to_find, $dir );
	}

	return $dir;
} ## end sub search_dir

__PACKAGE__->meta->make_immutable;

1;

__END__

head2 get_directory_object

Calls L<Perl::Dist::WiX::Directory's get_directory_object routine|Perl::Dist::WiX::Directory/get_directory_object>
on the root directory with the parameters given.

=head1 DIAGNOSTICS

See Perl::Dist::WiX's L<DIAGNOSTICS section|Perl::Dist::WiX/DIAGNOSTICS> for 
details, as all diagnostics from this module are listed there.

=head1 SUPPORT

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist|Perl::Dist>, L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT

Copyright 2009 - 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
