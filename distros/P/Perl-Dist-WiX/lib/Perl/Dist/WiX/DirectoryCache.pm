package Perl::Dist::WiX::DirectoryCache;

=pod

=head1 NAME

Perl::Dist::WiX::DirectoryCache - Cache of <Directory> tag objects.

=head1 VERSION

This document describes Perl::Dist::WiX::DirectoryCache version 1.500.

=head1 SYNOPSIS

	# Since this is a singleton, ->instance() retrieves the cache object
	# (creating the cache object if needed)
	my $cache = Perl::Dist::WiX::DirectoryCache->instance();
	
	$cache->add_to_cache($directory_object, $fragment_object);
	
	my $exists = $cache->exists_in_cache($directory_object);
	
	my $fragment_id = $cache->get_previous_fragment($directory_object);

	$cache->delete_cache_entry($directory_object);

=head1 DESCRIPTION

This object is a singleton designed to cache objects representing all 
directories to be created by a C<Perl::Dist::WiX>-based installer.

The cache is used during the C<regenerate_fragments> task so that a 
directory (defined by a 
L<Perl::Dist::WiX::Tag::Directory|Perl::Dist::WiX::Tag::Directory> 
object) is only defined once, no matter how many fragments it is used
in. (There can be as many references to a directory, defined by 
L<Perl::Dist::WiX::Tag::DirectoryRef|Perl::Dist::WiX::Tag::DirectoryRef> 
objects, as required.)

=cut

use 5.010;
use Moose 0.90;
use MooseX::Singleton;
use WiX3::XML::Directory qw();
use Params::Util qw( _INSTANCE );
use namespace::clean -except => 'meta';

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

# This is where the cache is actually stored.
has _cache => (
	traits   => ['Hash'],
	is       => 'bare',
	isa      => 'HashRef[Str]',
	default  => sub { {} },
	init_arg => undef,
	handles  => {
		'_set_cache_entry'    => 'set',
		'_get_cache_entry'    => 'get',
		'_exists_cache_entry' => 'exists',
		'_delete_cache_entry' => 'delete',
		'clear_cache'         => 'clear',
	},
);

=head1 INTERFACE

=head2 instance

Returns the cache object. (Use this instead of C<new()>.)

=head2 add_to_cache

	$cache->add_to_cache($directory_object, $fragment_object);
	This method adds the directory object to the cache, and references the
fact that it is being created in the fragment object.
	
=cut

sub add_to_cache {
	my $self      = shift;
	my $directory = shift || undef;
	my $fragment  = shift || undef;

	if ( not _INSTANCE( $directory, 'WiX3::XML::Directory' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'directory: Not a WiX3::XML::Directory object',
			where     => '::DirectoryCache->add_to_cache'
		);
	}

	if ( $self->_get_cache_entry( $directory->get_id() ) ) {
		PDWiX::Parameter->throw(
			parameter => 'directory: Already added to cache',
			where     => '::DirectoryCache->add_to_cache'
		);
	}

	$self->_set_cache_entry( $directory->get_id(), $fragment->get_id() );

	return;
} ## end sub add_to_cache



=head2 exists_in_cache

	my $exists = $cache->exists_in_cache($directory_object);
	
This method returns a true value if a directory object representing the 
same directory is already in the cache. Otherwise, it returns a false 
value.
	
=cut



sub exists_in_cache {
	my $self = shift;
	my $directory = shift || undef;

	if ( not _INSTANCE( $directory, 'WiX3::XML::Directory' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'directory: Not a WiX3::XML::Directory object',
			where     => '::DirectoryCache->exists_in_cache'
		);
	}

	return $self->_exists_cache_entry( $directory->get_id() );
} ## end sub exists_in_cache



=head2 get_previous_fragment

	my $fragment_id = $cache->get_previous_fragment($directory_object);
	
This method returns the ID of the fragment that's already creating this 
directory.  If there is no fragment already creating this directory, 
this method returns an undefined value.
	
=cut



sub get_previous_fragment {
	my $self = shift;
	my $directory = shift || undef;

	if ( not _INSTANCE( $directory, 'WiX3::XML::Directory' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'directory: Not a WiX3::XML::Directory object',
			where     => '::DirectoryCache->get_previous_fragment'
		);
	}

	return $self->_get_cache_entry( $directory->get_id() );
} ## end sub get_previous_fragment



=head2 delete_cache_entry

	$cache->delete_cache_entry($directory_object);
	
This method removes the ID of the fragment that's already assigned to
this directory in the cache.

This method is used when a directory that two or more fragments want to 
create is added to the 
L<directory tree object|Perl::Dist::WiX::DirectoryTree> instead.
	
=cut



sub delete_cache_entry {
	my $self = shift;
	my $directory = shift || undef;

	if ( not _INSTANCE( $directory, 'WiX3::XML::Directory' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'directory: Not a WiX3::XML::Directory object',
			where     => '::DirectoryCache->delete_cache_entry'
		);
	}

	return $self->_delete_cache_entry( $directory->get_id() );
} ## end sub delete_cache_entry



=head2 delete_cache_entry

	$cache->clear_cache();

This clears the cache for a new build.

=cut



no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
