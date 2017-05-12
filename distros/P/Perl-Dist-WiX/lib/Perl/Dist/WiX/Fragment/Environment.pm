package Perl::Dist::WiX::Fragment::Environment;

=pod

=head1 NAME

Perl::Dist::WiX::Fragment::Environment - A <Fragment> tag with environment variable handling.

=head1 VERSION

This document describes Perl::Dist::WiX::Fragment::Environment version 1.500.

=head1 SYNOPSIS

	my $fragment = Perl::Dist::WiX::Fragment::Environment->new(
		id => 'Environment',
	);

	# If there is only one parameter, it is considered to be the id.
	my $fragment2 = Perl::Dist::WiX::Fragment::Environment->new('Environment');

	$fragment->add_entry(
		id     => "Env_STRAWBERRY",
		name   => 'STRAWBERRY',
		value  => '1',
		action => 'set',
		part   => 'all',
	);
	
	my $count = $fragment->get_entries_count();
	
=head1 DESCRIPTION

This module implements the fragment that adds, deletes, and appends 
the environment variables required in a distribution.

=cut

use 5.010;
use Moose;
require Perl::Dist::WiX::DirectoryTree;
require WiX3::XML::Environment;
require WiX3::XML::Component;
require WiX3::XML::DirectoryRef;

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

extends 'WiX3::XML::Fragment';
with 'WiX3::Role::Traceable';

=head1 METHODS

This class inherits from L<WiX3::XML::Fragment|WiX3::XML::Fragment> 
and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new C<Perl::Dist::WiX::Fragment::Environment> object.

It inherits all the parameters described in the 
L<< WiX3::XML::Fragment->new()|WiX3::XML::Fragment/new >> 
method documentation.

If C<new> has only one parameter, it is considered the ID to use for 
the fragment.

=cut

# _component is the (one) component that this fragment contains.
# It's easiest just to keep track of it as an attribute
# than to have to search for it each time.
has _component => (
	is       => 'bare',
	isa      => 'WiX3::XML::Component',
	reader   => '_get_component',
	required => 1,
);

sub BUILDARGS {
	my $class = shift;
	my %args;

	# Process the arguments.
	## no critic(CascadingIfElse)
	if ( @_ == 1 && !ref $_[0] ) {
		$args{'id'} = $_[0];
	} elsif ( 0 == @_ ) {
		$args{'id'} = 'Environment';
	} elsif ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( 0 == @_ % 2 ) {
		%args = (@_);
	} else {
		PDWiX->throw(
'Parameters incorrect (not a hashref, hash, or id) for ::Fragment::Environment'
		);
	}

	# Default the ID to 'Environment'.
	my $id;
	if ( not exists $args{'id'} ) {
		$id = 'Environment';
	} else {
		$id = $args{'id'};
	}

	# Create the component and attach it to this fragment.
	my $tag1 = WiX3::XML::Component->new( id => $id );
	return {
		id         => $id,
		_component => $tag1,
	};
} ## end sub BUILDARGS

sub BUILD {
	my $self = shift;

	# Add the component to a reference to the root directory.
	my $tag2 =
	  WiX3::XML::DirectoryRef->new( directory_object =>
		  Perl::Dist::WiX::DirectoryTree->instance()->get_root(), );
	$tag2->add_child_tag( $self->_get_component() );

	# Add the root directory as a child of this fragment.
	$self->add_child_tag($tag2);
	$self->trace_line( 3, "Creating environment fragment.\n" );

	return;
} ## end sub BUILD



=head2 add_entry

  $fragment_tag = $fragment_tag->add_entry(...);

The C<add_entry> method creates an <Environment> tag (a 
L<WiX3::XML::Environment|WiX3::XML::Environment> object) and adds it
as a child of the component this fragment contains.

It takes all parameters that
L<< WiX3::XML::Environment->new()|WiX3::XML::Environment/new >>
takes.

=cut



sub add_entry {
	my $self = shift;

	$self->_get_component()
	  ->add_child_tag( WiX3::XML::Environment->new(@_) );

	return $self;
}



=head2 get_entries_count

    $count = $fragment_tag->get_entries_count();

The C<get_entries_count> method returns the number of <Environment> tags
that this fragment contains.

=cut



sub get_entries_count {
	my $self = shift;

	return $self->_get_component()->count_child_tags();

}


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
