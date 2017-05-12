package Perl::Dist::WiX::Tag::Directory;

=pod

=head1 NAME

Perl::Dist::WiX::Tag::Directory - <Directory> tag that knows how to search its children.

=head1 VERSION

This document describes Perl::Dist::WiX::Tag::Directory version 1.500.

=head1 SYNOPSIS

	my $dir_tag = Perl::Dist::WiX::Tag::Directory->new(
		id => 'Perl',
		name => 'perl',
		path => 'C:\strawberry\perl',
	);

	# Parameters can be passed as a hash, or a hashref.
	# A hashref is shown.
	my $dir_tag_2 = $dir_tag->add_directory({
		id => 'Vendor',
		name => 'vendor',
		path => 'C:\strawberry\perl\vendor',
	});
	
	my $dir_tag_3 = $dir_tag->get_directory_object('Vendor');

	my $dir_tag_4 = $dir_tag->search_dir({
		path_to_find => 'C:\strawberry\perl\vendor',
		descend => 1,
		exact => 1,
	});
	
=head1 DESCRIPTION

This is an XML tag that refers to a directory that is used in a Perl::Dist::WiX 
based distribution.

=cut

use 5.010;
use Moose;

# CHECK: May or may not need this. Needs to be tested.
# use WiX3::Util::StrictConstructor;
use File::Spec::Functions qw( catpath catdir splitpath splitdir );
use Params::Util qw( _STRING );
use Digest::CRC qw( crc32_base64 );
require Perl::Dist::WiX::Exceptions;

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

extends 'WiX3::XML::Directory';

=head1 METHODS

This class is a L<WiX3::XML::Directory|WiX3::XML::Directory> and 
inherits its API, so only additional API is documented here.

=head2 new

The C<new> constructor takes a series of parameters, validates them
and returns a new B<Perl::Dist::WiX::Tag::Directory> object.

If an error occurs, it throws an exception.

It inherits all the parameters described in the 
L<< WiX3::XML::Directory->new()|WiX3::XML::Directory/new >> method 
documentation.

=head2 add_directories_id

    $dir_obj = $dir_obj->add_directories_id(
		'Perl',    'perl',
		'License', 'licenses',
	);
    #   id          directory

The C<add_directories_id> method adds multiple directories objects as 
children of the current object. 

Each directory object to be created is specified by the id to be used and 
the directory to be referred to, which is a subdirectory of the directory 
referred to by the current tag.

It returns the object that is being operated on, so that methods can be chained.

=cut



sub add_directories_id {
	my ( $self, @params ) = @_;

	# We need id, name pairs passed in.
	if ( @params % 2 != 0 ) {
		PDWiX->throw(
			'Internal Error: Odd number of parameters to add_directories_id'
		);
	}

	# Add each individual id and name.
	my ( $id, $name, $path );
	while ( $#params > 0 ) {
		$id   = shift @params;
		$name = shift @params;
		if ( defined $self->get_path() ) {
			$path = $self->get_path() . q{\\} . $name;
		}
		if ( $name =~ m{\\}ms ) {
			PDWiX->throw( 'Name of directory to add in '
				  . 'add_directories_id had a slash in it.' );
		} else {
			$self->add_directory( {
					id   => $id,
					path => $path,
					name => $name,
				} );
		}
	} ## end while ( $#params > 0 )

	return $self;
} ## end sub add_directories_id



=head2 get_directory_object

get_directory_object returns the C<Perl::Dist::WiX::Tag::Directory> object
with the id that was passed in as the only parameter, as long as it is a 
child tag of this tag, or a grandchild/great-grandchild/etc. of this tag.

If you pass the ID of THIS object in, it gets returned.

An undefined value is returned if no object with that ID could be found. 

=cut

sub get_directory_object {
	my $self = shift;
	my $id   = shift;

	my $self_id = $self->get_directory_id();

	return $self if ( $id eq $self_id );
	my $return;

  SUBDIRECTORY:
	foreach my $object ( $self->get_child_tags() ) {
		next SUBDIRECTORY
		  if not $object->isa('Perl::Dist::WiX::Tag::Directory');
		$return = $object->get_directory_object($id);
		return $return if defined $return;
	}

	## no critic (ProhibitExplicitReturnUndef)
	return undef;
} ## end sub get_directory_object



=head2 search_dir

	my $perl_bin_directory_tag = $directory->search_dir(
		path_to_find => 'C:\strawberry\perl\bin',
		descend => 1,
		exact => 0,
	);

Attempts to find the C<path_to_find> in this directory tag (and in the 
children of this tag, if C<descend> is true.)

If C<exact> is false, this method is allowed to return an object that
defines a subpath of the C<path_to_find>.

C<path_to_find> is required. C<descend> defaults to true, and C<exact>
defaults to false.

=cut



sub search_dir {
	## no critic (ProhibitExplicitReturnUndef)
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
		where     => '::Tag::Directory->search_dir'
	  );
	my $descend = $args{descend} || 1;
	my $exact   = $args{exact}   || 0;
	my $path    = $self->get_path();

	return undef if not defined $path;

	$self->trace_line( 3, "Looking for $path_to_find\n" );
	$self->trace_line( 4, "   in:      $path.\n" );
	$self->trace_line( 5, "   descend: $descend exact: $exact.\n" );

	# If we're at the correct path, exit with success!
	if ( ( defined $path ) && ( $path_to_find eq $path ) ) {

		$self->trace_line( 4, "Found $path.\n" );

		# TARGETDIR has the path attached, but we really
		# want INSTALLDIR to be the correct ID.
		if ( 'TARGETDIR' eq $self->get_directory_id() ) {
			return $self->get_directory_object('INSTALLDIR');
		}
		return $self;
	}

	# Quick exit if required.
	return undef if not $descend;

	# Do we want to continue searching down this direction?
	my $subset = "$path_to_find\\" =~ m{\A\Q$path\E\\}msx;
	if ( not $subset ) {
		$self->trace_line( 4, "Not a subset in: $path.\n" );
		$self->trace_line( 5, "  To find: $path_to_find.\n" );
		return undef;
	} else {
		$self->trace_line( 4, "Subset of $path_to_find in $path.\n" );
	}

	# Check each of our branches.
	my @tags = $self->get_child_tags();
	my $answer;

#	print "** Number of child tags: " . scalar @tags . "\n";

  TAG:
	foreach my $tag (@tags) {
		next TAG if not $tag->isa('Perl::Dist::WiX::Tag::Directory');

		$answer = $tag->search_dir( \%args );
		if ( defined $answer ) {
			return $answer;
		}
	}

	# If we get here, we did not find a lower directory.
	$self->trace_line( 4, "Did not find lower directory than $path.\n" );
	if ($exact) {
		$self->trace_line( 5, "Returning undef.\n" );
		return undef;
	} else {
		$self->trace_line( 5, "Returning object for $path.\n" );
		return $self;
	}
} ## end sub search_dir

sub _add_directory_recursive
{ ## no critic(ProhibitUnusedPrivateSubroutines)
	my $self         = shift;
	my $path_to_find = shift;
	my $dir_to_add   = shift;

	# Should not happen, but checking to make sure we bottom out,
	# rather than going into infinite recursion.
	if ( length $path_to_find < 4 ) {
		## no critic (ProhibitExplicitReturnUndef)
		return undef;
	}

	my $path_to_add = $path_to_find . q{\\} . $dir_to_add;
	my $directory   = $self->search_dir(
		path_to_find => $path_to_find,
		descend      => 1,
		exact        => 1,
	);

	if ( defined $directory ) {
		return $directory->add_directory(
			name => $dir_to_add,
			id   => crc32_base64($path_to_add),
			path => $path_to_add,
		);
	} else {
		my ( $volume, $dirs, undef ) = splitpath( $path_to_find, 1 );
		my @dirs              = splitdir($dirs);
		my $dir_to_add_down   = pop @dirs;
		my $path_to_find_down = catdir( $volume, @dirs );
		my $dir =
		  $self->_add_directory_recursive( $path_to_find_down,
			$dir_to_add_down );

		if ( !defined $dir ) {
			PDWiX->throw(
"Could not create directory $path_to_find_down\\$dir_to_add_down"
			);
		}
		return $dir->add_directory(
			name => $dir_to_add,
			id   => crc32_base64($path_to_add),
			path => $path_to_add,
		);

	} ## end else [ if ( defined $directory)]
} ## end sub _add_directory_recursive

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

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://wix.sourceforge.net/manual-wix3/wix_xsd_directory.htm>,

=head1 COPYRIGHT

Copyright 2009 - 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
