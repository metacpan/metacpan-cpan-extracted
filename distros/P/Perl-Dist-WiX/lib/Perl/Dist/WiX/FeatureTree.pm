package Perl::Dist::WiX::FeatureTree;

=pod

=head1 NAME

Perl::Dist::WiX::FeatureTree - Tree of <Feature> tag objects.

=head1 VERSION

This document describes Perl::Dist::WiX::FeatureTree version 1.500.

=head1 SYNOPSIS

	my $tree = Perl::Dist::WiX::FeatureTree->new(
		parent => $dist,
	);
	
	my $xml = $tree->as_string();

=head1 DESCRIPTION

This module contains the feature tree for a distribution.

Currently, this implements a "feature tree" with one feature.  Multiple
features will be implemented during the October 2010 release cycle.

=cut

use 5.010;
use Moose 0.90;
use WiX3::XML::Feature qw();
use namespace::clean -except => 'meta';

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

=head1 INTERFACE

=head2 new

	my $tree = Perl::Dist::WiX::FeatureTree->new(
		parent => $dist,
	);

The C<new> method creates a new feature tree object for the
L<Perl::Dist::WiX|Perl::Dist::WiX> object passed as its C<parent> parameter.
	
=cut	



has parent => (
	is       => 'ro',
	isa      => 'Perl::Dist::WiX',
	weak_ref => 1,
	handles  => {
		'_app_ver_name'   => 'app_ver_name',
		'_feature_tree'   => 'msi_feature_tree',
		'_get_components' => 'get_component_array',
		'_trace_line'     => 'trace_line',
	},
);



has _features => (
	traits   => ['Array'],
	is       => 'ro',
	isa      => 'ArrayRef[WiX3::XML::Feature]',
	default  => sub { [] },
	init_arg => undef,
	handles  => {
		'_push_feature'      => 'push',
		'_count_features'    => 'count',
		'_get_feature'       => 'get',
		'_get_feature_array' => 'elements',
	},
);



sub BUILD {
	my $self = shift;
	my $feat;

	# Start the tree.
	$self->_trace_line( 0, "Creating feature tree...\n" );
	if ( defined $self->_feature_tree() ) {
		PDWiX->throw( 'Complex feature tree not implemented in '
			  . "Perl::Dist::WiX $VERSION." );
	} else {
		$feat = WiX3::XML::Feature->new(
			id          => 'Complete',
			title       => $self->_app_ver_name(),
			description => 'The complete package.',
			level       => 1,
		);
		$feat->add_child_tag( $self->_get_components() );
		$self->_push_feature($feat);
	}

	return;
} ## end sub BUILD



=head2 as_string

	my $xml = $tree->as_string();

The C<as_string> method returns XML representing this feature tree 
object for use in the main .msi.

=cut



sub as_string {
	my $self = shift;

	# Get the strings for each of our branches.
	my $spaces = q{    };              # Indent 4 spaces.
	my $answer = $spaces;
	foreach my $feature ( $self->_get_feature_array() ) {
		$answer .= $feature->as_string();
	}

	chomp $answer;
#<<<
	$answer =~ s{\n}                   # match a newline 
				{\n$spaces}gxms;       # and add spaces after it.
									   # (i.e. the beginning of the line.)
#>>>

	return $answer;
} ## end sub as_string



=head2 as_string_msm

	my $xml = $tree->as_string_msm();

The C<as_string> method returns XML representing this feature tree 
object for use in merge modules.

=cut



sub as_string_msm {
	my $self = shift;

	# Get the strings for each of our branches.
	my $spaces = q{    };              # Indent 4 spaces.
	my $answer = $spaces;
	foreach my $feature ( $self->_get_feature_array() ) {

		# We just want the children for this one, as
		# a merge module does not really use <Feature> tags.
		$answer .= $feature->as_string_children();
	}

	chomp $answer;
#<<<
	$answer =~ s{\n}                   # match a newline 
				{\n$spaces}gxms;       # and add spaces after it.
									   # (i.e. the beginning of the line.)
#>>>

	return $answer;
} ## end sub as_string_msm



=head2 add_merge_module

	$self->add_merge_module($mm)

This routine adds a merge module reference to the feature tree.

The C<$mm> parameter is the 
L<Perl::Dist::WiX::Tag::MergeModule|Perl::Dist::WiX::Tag::MergeModule> 
object to add a reference of.

=cut



sub add_merge_module {
	my $self  = shift;
	my $mm    = shift;
	my $index = shift || 0;

	my $feature = $self->_get_feature($index);
	$feature->add_child_tag( $mm->get_merge_reference() );

	return;
}

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
