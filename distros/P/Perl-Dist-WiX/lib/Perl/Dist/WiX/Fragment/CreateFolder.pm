package Perl::Dist::WiX::Fragment::CreateFolder;

=pod

=head1 NAME

Perl::Dist::WiX::Fragment::CreateFolder - A <Fragment> tag that creates a folder.

=head1 VERSION

This document describes Perl::Dist::WiX::Fragment::CreateFolder version 1.500.

=head1 SYNOPSIS

	my $fragment = Perl::Dist::WiX::Fragment::CreateFolder->new(
		directory_id => 'Cpan',       # Must be the ID of an already existing directory.
		id           => 'CPANFolder', # Used to create the ID of the CreateFolder object
	);

=head1 DESCRIPTION

This object defines a <Fragment> tag that contains the other tags required
in order to create a folder when the MSI is installed.

=cut

use 5.010;
use Moose;
use Params::Util qw( _STRING  );
use MooseX::Types::Moose qw( Str );
use WiX3::XML::CreateFolder;
use WiX3::XML::DirectoryRef;
use WiX3::XML::Component;

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

extends 'WiX3::XML::Fragment';
with 'WiX3::Role::Traceable';

=head1 METHODS

This class inherits from L<WiX3::XML::Fragment|WiX3::XML::Fragment> 
and shares its API.

There are no additional routines added.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new C<Perl::Dist::WiX::Fragment::Environment> object.

It inherits all the parameters described in the 
L<< WiX3::XML::Fragment->new()|WiX3::XML::Fragment/new >> 
method documentation.

It also adds one more required parameter, documented below.

=head3 directory_id

The id of the directory to create.

=cut

has directory_id => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_directory_id',
	required => 1,
);


# Called by Moose::Object->new()
sub BUILDARGS {
	my $class = shift;
	my %args;

	# Process and check arguments.
	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( 0 == @_ % 2 ) {
		%args = @_;
	} else {
		PDWiX->throw( 'Parameters incorrect (not a hashref or a hash)'
			  . ' for ::Fragment::CreateFolder' );
	}

	# ID is required for ::Fragment::CreateFolder.
	if ( not exists $args{'id'} ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '::Fragment::CreateFolder->new'
		);
	}

	return {
		id           => "Create$args{id}",
		directory_id => $args{'directory_id'} };
} ## end sub BUILDARGS



# Called by Moose::Object->new()
sub BUILD {
	my $self = shift;

	# Get the information we need.
	my $id             = $self->get_id();
	my $directory_tree = Perl::Dist::WiX::DirectoryTree->instance();

	my $directory_id = $self->_get_directory_id();
	my $directory_object =
	  $directory_tree->get_directory_object("D_$directory_id");

	# Start creating tags.
	my $tag1 = WiX3::XML::CreateFolder->new();
	my $tag2 = WiX3::XML::Component->new( id => $id );
	my $tag3 =
	  WiX3::XML::DirectoryRef->new( directory_object => $directory_object,
	  );

	# Get all the child tags correctly in the tree.
	$tag2->add_child_tag($tag1);
	$tag3->add_child_tag($tag2);
	$self->add_child_tag($tag3);

	# Announce ourselves.
	$self->trace_line( 2,
		    'Creating directory creation entry for directory '
		  . "id D_$directory_id\n" );

	return;
} ## end sub BUILD


# The fragment is already generated. No need to regenerate.
sub _regenerate { ## no critic(ProhibitUnusedPrivateSubroutines)
	return;
}

# No duplicates will be here to check.
sub _check_duplicates { ## no critic(ProhibitUnusedPrivateSubroutines)
	return;
}

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
