package Perl::Dist::WiX::Fragment::Files;

=pod

=head1 NAME

Perl::Dist::WiX::Fragment::Files - A <Fragment> with file handling.

=head1 VERSION

This document describes Perl::Dist::WiX::Fragment::Files version 1.500.

=head1 SYNOPSIS

	my $fragment = Perl::Dist::WiX::Fragment::Files->new(
		id              => 'perl',
		files           => $perl_files_object, # File::List::Object object
		in_merge_module => 0,
		can_overwrite   => 0,
	);

	my $files_object = $fragment->get_files();
	
=head1 DESCRIPTION

This object defines an XML fragment that specifies files for the installer
to include within itself and install on end-user systems.

Usually a fragment is one module, or a C library.

=head1 INTERFACE

=cut

use 5.010;
use Moose;
use MooseX::Types::Moose qw( Bool Str );
use Params::Util qw( _INSTANCE );
use File::Spec::Functions qw( abs2rel splitpath catpath catdir splitdir );
use List::MoreUtils qw( uniq );
use Digest::CRC qw( crc32_base64 crc16_hex );
use Perl::Dist::WiX::Exceptions qw();
use Perl::Dist::WiX::Tag::DirectoryRef qw();
use Perl::Dist::WiX::DirectoryCache qw();
use Perl::Dist::WiX::DirectoryTree qw();
use WiX3::XML::Component qw();
use WiX3::XML::Feature qw();
use WiX3::XML::FeatureRef qw();
use WiX3::XML::File qw();
use WiX3::Exceptions qw();
use File::List::Object qw();
use Win32::Exe 0.13 qw();

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

extends 'WiX3::XML::Fragment';
with 'WiX3::Role::Traceable';

=head1 METHODS

This class inherits from L<WiX3::XML::Fragment|WiX3::XML::Fragment> 
and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new C<Perl::Dist::WiX::Fragment::Files> object.

It inherits all the parameters described in the 
L<< WiX3::XML::Fragment->new()|WiX3::XML::Fragment/new >> 
method documentation, and adds the additional parameters described below.

=head3 can_overwrite

The optional C<can_overwrite> parameter specifies whether files in this 
fragment will be overwritten by files in another fragment.

=cut



has can_overwrite => (
	is      => 'ro',
	isa     => Bool,
	default => 0,
);



=head3 in_merge_module

The optional C<in_merge_module> parameter specifies whether files in this 
fragment will be overwritten by files in another fragment.

=cut



has in_merge_module => (
	is      => 'ro',
	isa     => Bool,
	default => 0,
);



=head3 sub_feature

The optional C<sub_feature> parameter specifies which installation 
feature files in this fragment will be installed with.

=cut



has sub_feature => (
	is      => 'ro',
	isa     => Str,
	default => 'Complete',
);



=head3 files

The required C<files> parameter is the list of files that are in the fragment.

=head2 get_files

Retrieves the list of files.

=cut



has files => (
	is       => 'ro',
	isa      => 'File::List::Object',
	reader   => 'get_files',
	required => 1,
	handles  => {
		'_add_files' => 'add_files',
		'_add_file'  => 'add_file',
		'_subtract'  => 'subtract',
		'_get_files' => 'files',
	},
);




# Private.
has _feature => (
	is       => 'bare',
	isa      => 'Maybe[WiX3::XML::Feature]',
	init_arg => undef,
	lazy     => 1,
	reader   => '_get_feature',
	builder  => '_build_feature',
);

sub _shorten_id {
	my $self   = shift;
	my $longid = shift;

	# Feature/@Id cannot be longer than 38 characters in length.
	if ( 32 < length $longid ) {
		my $id = substr $longid, 0, 28;
		$id .= q{_};
		$id .= uc crc16_hex( $longid . 'Perl::Dist::WiX::PrivateTypes' );
		return $id;
	} else {
		return $longid;
	}
} ## end sub _shorten_id

sub _build_feature {
	my $self = shift;
	if ( not $self->in_merge_module() ) {
		my $feat = WiX3::XML::Feature->new(
			id      => $self->_shorten_id( $self->get_id() ),
			level   => 1,
			display => 'hidden',
		);
		return $feat;
	} else {
		## no critic (ProhibitExplicitReturnUndef)
		return undef;
	}
} ## end sub _build_feature



=head2 get_feature_ref

Gets a FeatureRef tag referring to the Feature tag used in this fragment.

=cut



sub get_feature_ref {
	my $self    = shift;
	my $feature = $self->_get_feature();

	if ( not defined $feature ) {
		PDWiX->throw(
'Tried to get a feature reference from a fragment that does not have one'
		);
	}

	return WiX3::XML::FeatureRef($feature);
} ## end sub get_feature_ref



# This type of fragment needs regeneration.
sub _regenerate { ## no critic(ProhibitUnusedPrivateSubroutines)
	my $self = shift;
	my @fragment_ids;
	my @files = @{ $self->_get_files() };

	# Announce ourselves.
	my $id = $self->get_id();
	$self->trace_line( 2, "Regenerating $id\n" );

	# Throw an error if there are no files in the fragment.
	if ( 0 == scalar @files ) {
		PDWiX->throw( "Attempted to regenerate empty fragment $id "
			  . '(is the fragment supposed to be empty?)' );
	}

	# Clear up any previous tags that are there.
	$self->clear_child_tags();

	# Add all the files. Store any fragment ID's that need
	# regenerated again.
  FILE:
	foreach my $file (@files) {
		push @fragment_ids, $self->_add_file_to_fragment($file);
	}

	# If we find any fragment ID's that need regenerated,
	# we need regenerated again.
	# Otherwise, add the feature tag to the fragment
	# IF we aren't in a merge module.
	if ( 0 < scalar @fragment_ids ) {
		push @fragment_ids, $id;
	} else {
		if ( not $self->in_merge_module() ) {
			$self->add_child_tag( $self->_get_feature() );
		}
	}

	# Return the list of fragments that need regenerated again.
	my @fragment_ids_sorted = uniq @fragment_ids;
	my $fragments = join q{, }, @fragment_ids_sorted;
	if ( scalar @fragment_ids_sorted ) {
		$self->trace_line( 2, "Needs regenerated again: $fragments\n" );
	}

	return @fragment_ids_sorted;
} ## end sub _regenerate

sub _add_file_to_fragment {
	my $self      = shift;
	my $file_path = shift;
	my $tree      = Perl::Dist::WiX::DirectoryTree->instance();

	$self->trace_line( 3, "Adding file $file_path\n" );

	# return () or any fragments that need regeneration
	# retrieved from the cache.
	my ( $directory_final, @fragment_ids );

	# We need to look for our directory entry in order to
	# add our file.
	my ( $volume, $dirs, $file ) = splitpath( $file_path, 0 );
	my $path_to_find = catdir( $volume, $dirs );

	my @child_tags       = $self->get_child_tags();
	my $child_tags_count = scalar @child_tags;

# Step 1: Search in our own directories exactly.
#  SUCCESS: Create component and file.

	my $i_step1     = 0;
	my $found_step1 = 0;
	my $directory_step1;
	my $tag_step1;
  STEP1:

	while ( $i_step1 < $child_tags_count and not $found_step1 ) {

		# Get the next tag to search.
		$tag_step1 = $child_tags[$i_step1];
		$i_step1++;

		# Skip any odd tags that may have gotten in.
		next STEP1
		  if not( (      $tag_step1->isa('Perl::Dist::WiX::Tag::Directory')
					  or
					  $tag_step1->isa('Perl::Dist::WiX::Tag::DirectoryRef')
				  ) );

		# Search for the directory.
		$directory_step1 = $tag_step1->search_dir(
			path_to_find => $path_to_find,
			descend      => 1,
			exact        => 1,
		);

		if ( defined $directory_step1 ) {

			# We're successful, so possibly say so, and then add the file.
			$self->trace_line( 4,
				"Directory search for step 1 successful.\n" );
			$found_step1 = 1;
			$self->_add_file_component( $directory_step1, $file_path );

			return ();
		}
	} ## end while ( $i_step1 < $child_tags_count...)


# Step 2: Search in the directory tree exactly.
#  SUCCESS: Create a reference, create component and file.

  STEP2:
	my $directory_step2 = $tree->search_dir(
		path_to_find => $path_to_find,
		descend      => 1,
		exact        => 1,
	);

	if ( defined $directory_step2 ) {

		# We're successful, so possibly say so, and then
		# add a directory reference and the file.
		$self->trace_line( 4, "Directory search for step 2 successful.\n" );
		my $directory_ref_step2 =
		  Perl::Dist::WiX::Tag::DirectoryRef->new(
			directory_object => $directory_step2 );
		$self->add_child_tag($directory_ref_step2);
		$self->_add_file_component( $directory_ref_step2, $file_path );

		return ();
	} ## end if ( defined $directory_step2)

# Step 3: Search in our own directories non-exactly.
#  SUCCESS: Create directories, create component and file.
#  NOTE: Check if directories are in cache, and if so, add to
#    directory tree and regenerate.

	my $i_step3     = 0;
	my $found_step3 = 0;
	my $directory_step3;
	my $tag_step3;
  STEP3:

	while ( $i_step3 < $child_tags_count and not $found_step3 ) {

		# Get the next tag to search.
		$tag_step3 = $child_tags[$i_step3];
		$i_step3++;

		# Skip any odd tags that may have gotten in.
		next STEP3
		  if not( (      $tag_step3->isa('Perl::Dist::WiX::Tag::Directory')
					  or
					  $tag_step3->isa('Perl::Dist::WiX::Tag::DirectoryRef')
				  ) );

		# Search for the directory.
		$directory_step3 = $tag_step3->search_dir(
			path_to_find => $path_to_find,
			descend      => 1,
			exact        => 0,
		);

		if ( defined $directory_step3 ) {

			# We're successful, so possibly say so.
			$self->trace_line( 4,
				"Directory search for step 3 successful.\n" );
			$found_step3 = 1;

			# Check and see if this is in the directory tree.
			my $directory_treecheck = $tree->search_dir(
				path_to_find => $directory_step3->get_path(),
				descend      => 1,
				exact        => 1,
			);

			if ( defined $directory_treecheck ) {

				# Say that we found a tree entry.
				$self->trace_line( 4,
					"Directory search for step 3 successful.\n" );

				# Add directory reference (as this is in the main tree),
				# then directories and the file.
				my $directory_ref_step3 =
				  Perl::Dist::WiX::Tag::DirectoryRef->new(
					directory_object => $directory_treecheck );
				$self->add_child_tag($directory_ref_step3);
				( $directory_final, @fragment_ids ) =
				  $self->_add_directory_recursive( $directory_ref_step3,
					$path_to_find );
				$self->_add_file_component( $directory_final, $file_path );
			} else {

				# Add the directories and the file.
				( $directory_final, @fragment_ids ) =
				  $self->_add_directory_recursive( $directory_step3,
					$path_to_find );
				$self->_add_file_component( $directory_final, $file_path );
			}

			# Return any fragments that need regenerated.
			return @fragment_ids;
		} ## end if ( defined $directory_step3)
	} ## end while ( $i_step3 < $child_tags_count...)


# Step 4: Search in the directory tree non-exactly.
#  SUCCESS: Create a reference, create directories below it,
#    create component and file.
#  NOTE: Same as Step 3.
#  FAIL: Throw error.

  STEP4:
	my $directory_step4 = $tree->search_dir(
		path_to_find => $path_to_find,
		descend      => 1,
		exact        => 0,
	);

	if ( defined $directory_step4 ) {

		# We're successful, so possibly say so, and then
		# add the directory reference, the directories
		# required, and the file.
		$self->trace_line( 4, "Directory search for step 4 successful.\n" );
		my $directory_ref_step4 =
		  Perl::Dist::WiX::Tag::DirectoryRef->new(
			directory_object => $directory_step4 );
		$self->add_child_tag($directory_ref_step4);
		( $directory_final, @fragment_ids ) =
		  $self->_add_directory_recursive( $directory_ref_step4,
			$path_to_find );
		$self->_add_file_component( $directory_final, $file_path );

		# Return any fragments that need regenerated.
		return @fragment_ids;
	} ## end if ( defined $directory_step4)

	# Throw an error at this point, because we've been unsuccessful.
	PDWiX->throw("Could not add $file_path");
	return ();
} ## end sub _add_file_to_fragment



# This is called by _add_file_to_fragment, which is called from
# regenerate().
sub _add_directory_recursive {
	my $self             = shift;
	my $tag              = shift;
	my $dir              = shift;
	my $cache            = Perl::Dist::WiX::DirectoryCache->instance();
	my $tree             = Perl::Dist::WiX::DirectoryTree->instance();
	my $directory_object = $tag;
	my @fragment_ids     = ();

	# Get the directories to add.
	my $dirs_to_add = abs2rel( $dir, $tag->get_path() );
	my @dirs_to_add = splitdir($dirs_to_add);
	while ( $dirs_to_add[0] eq q{} ) {
		shift @dirs_to_add;
	}

	my $path;
	foreach my $dir_to_add (@dirs_to_add) {

		$path = catdir( $directory_object->get_path(), $dir_to_add );

		# Create the object.
		$directory_object = $directory_object->add_directory(
			name => $dir_to_add,
			id   => crc32_base64($path),
			path => $path,
		);

		# Check if it's in the cache. If not, add it, and if so,
		# return the fact that it was there.
		if ( $cache->exists_in_cache($directory_object) ) {
			$tree->add_directory($path);
			my $id = $cache->get_previous_fragment($directory_object);
			push @fragment_ids, $id;
			$self->trace_line( 5,
"Adding directory $path to directory tree (previously in $id).\n"
			);
		} else {
			$cache->add_to_cache( $directory_object, $self );
			$self->trace_line( 5, "Adding directory $path to cache.\n" );
		}
	} ## end foreach my $dir_to_add (@dirs_to_add)

	return ( $directory_object, uniq @fragment_ids );
} ## end sub _add_directory_recursive

# This is called by _add_file_to_fragment, which is called from
# regenerate().
sub _add_file_component {
	my $self = shift;
	my $tag  = shift;
	my $file = shift;

# We need a shorter ID than a GUID. CRC32's do that.
# it does NOT have to be cryptographically perfect,
# it just has to TRY and be unique over a set of 10,000
# file names and compoments or so.

	# Reverse the extension to start the ID with.
	my $revext;
	my ( undef, undef, $filename ) = splitpath($file);
	$filename = reverse scalar $filename;
	($revext) = $filename =~ m{\A(.*?)[.]}msx;

	if ( not defined $revext ) {
		$revext = 'Z';
	}

	# Generate the ID.
	my $component_id = "${revext}_";
	$component_id .= crc32_base64($file);
	$component_id =~ s{[+]}{_}ms;
	$component_id =~ s{/}{-}ms;

	# Create the component tag.
	my @feature_param = ();
	if ( defined $self->_get_feature() ) {
		@feature_param =
		  ( feature => 'Feat_' . $self->_get_feature()->get_id() );
	}
	my $component_tag = WiX3::XML::Component->new(
		path => $file,
		id   => $component_id,
		@feature_param
	);

	# Create the file tag.
	my $file_tag;
	if (( -r $file )
		and (  ( $file =~ m{[.] dll\z}smx )
			or ( $file =~ m{[.] exe\z}smx ) ) )
	{

		# Check for version information on a .dll or .exe,
		# because if it exists, we need the language from it
		# when we create the tag.
		my $language;
		my $exe = Win32::Exe->new($file);
		my $vi;
		{

			# Win32::Exe prints an annoying warning here. Ignore it.
			local $SIG{__WARN__} = sub { };
			$vi = $exe->version_info();
		}

		if ( defined $vi ) {
			$vi->get('OriginalFilename'); # To load the variable used below.
			$language = hex substr $vi->{'cur_trans'}, 0, 4;
			$file_tag = WiX3::XML::File->new(
				source          => $file,
				id              => $component_id,
				defaultlanguage => $language,
			);
		} else {
			$file_tag = WiX3::XML::File->new(
				source => $file,
				id     => $component_id,
			);
		}
	} else {

		# If the file doesn't exist, it gets caught later.
		$file_tag = WiX3::XML::File->new(
			source => $file,
			id     => $component_id,
		);
	}

	# Add the tags into our "tag tree"
	$component_tag->add_child_tag($file_tag);
	$tag->add_child_tag($component_tag);

	return 1;
} ## end sub _add_file_component



sub _check_duplicates { ## no critic(ProhibitUnusedPrivateSubroutines)
	my $self     = shift;
	my $filelist = shift;

	# Don't worry about it if we aren't allowed to overwrite.
	if ( not $self->can_overwrite() ) {
		return $self;
	}

	# Check that our parameter is valid.
	if ( not defined _INSTANCE( $filelist, 'File::List::Object' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'filelist',
			where => 'Perl::Dist::WiX::Fragment::Files->_check_duplicates',
		);
		return 0;
	}

	# Subtract the filelist from our contents.
	$self->_subtract($filelist);
	return $self;
} ## end sub _check_duplicates



# Passes this call off to the Feature tag contained within this
# tag if we are not in a merge module.
around 'get_componentref_array' => sub {
	my $orig = shift;
	my $self = shift;

	if ( $self->in_merge_module() ) {
		return $self->$orig();
	} else {
		return $self->_get_feature()->get_componentref_array();
	}
};



=head2 add_file, add_files

    $fragment->add_files(@files);
	$fragment->add_file($file);

Adds file(s) to the current fragment.

This must be done before C<Perl::Dist::WiX->regenerate_fragments()> is 
called.

=cut



sub _fix_slashes {
	my $file = shift;

	# Fix the file if it needs fixed.
	my $file_fixed = $file;
	$file_fixed =~ s{/}{\\}gms;

	return $file_fixed || $file;
}

sub add_file {
	my $self = shift;

	# Fix all files that need fixed before adding them.
	my @files = map { _fix_slashes($_) } @_;

	# Pass it on to the filelist object.
	return $self->_add_file(@files);
}

sub add_files {
	my $self = shift;

	# Fix all files that need fixed before adding them.
	my @files = map { _fix_slashes($_) } @_;

	# Pass it on to the filelist object.
	return $self->_add_files(@files);
}



=head2 find_file_id, find_file

	$file_tag_id = $fragment_tag->find_file_id($file);

Finds the ID of the file tag for the filename passed in.

Returns C<undef> if no file tag could be found.
	
This must be done before C<Perl::Dist::WiX->regenerate_fragments()> is 
called.

=cut



sub find_file_id {
	my $self     = shift;
	my $filename = shift;

	# Start our recursive call chain.
	return $self->_find_file_recursive( $filename, $self );
}

sub find_file {
	my $self     = shift;
	my $filename = shift;

	print
	  "WARNING: find_file deprecated. Replace by call to find_file_id.\n";
	my $d = Devel::StackTrace->new();
	print $d->frame(1)->as_string();
	print "\n";
	print $d->frame(2)->as_string();
	print "\n\n";

	# Start our recursive call chain.
	return $self->_find_file_recursive( $filename, $self );
} ## end sub find_file

# Called by find_file.
sub _find_file_recursive {
	my $self     = shift;
	my $filename = shift;
	my $tag      = shift;

	# Get the children to search through.
	my @children = $tag->get_child_tags();

	## no critic(ProhibitExplicitReturnUndef)
	my $answer;
	my $i = 0;
	while ( ( not defined $answer ) and ( $i < scalar @children ) ) {
		if ( 'WiX3::XML::File' eq ref $children[$i] ) {

			# Check if this file is the one we want.
			if ( $children[$i]->_get_source() eq $filename ) {
				return 'F_' . $children[$i]->get_id();
			} else {
				return undef;
			}
		} elsif (
			$children[$i]->does('WiX3::XML::Role::TagAllowsChildTags') )
		{

			# Keep going down this way, because there could be more
			# child tags to check, and return if we find anything.
			$answer =
			  $self->_find_file_recursive( $filename, $children[$i] );
			return $answer if defined $answer;
		} else {

			# This child can't have children, so stop going this way.
			return undef;
		}

		# Keep searching.
		$i++;
	} ## end while ( ( not defined $answer...))

	# No such luck. It's not here.
	return undef;
} ## end sub _find_file_recursive

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>

=head1 COPYRIGHT

Copyright 2009 - 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
