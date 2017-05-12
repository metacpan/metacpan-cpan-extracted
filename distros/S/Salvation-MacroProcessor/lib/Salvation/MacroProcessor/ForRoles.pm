use strict;

package Salvation::MacroProcessor::ForRoles;

use Moose::Role;
use Moose::Exporter ();
use Moose::Util::MetaRole ();

use Salvation::MacroProcessor ();


Moose::Exporter -> setup_import_methods( with_meta => [ 'smp_add_description', 'smp_add_share', 'smp_add_alias', 'smp_add_connector', 'smp_import_descriptions', 'smp_import_shares' ] );


sub init_meta
{
	my ( undef, %args ) = @_;

	Moose::Role -> init_meta( %args );

	return &Moose::Util::MetaRole::apply_metaroles(
		for             => $args{ 'for_class' },
		role_metaroles  => {
			role => [ 'Salvation::MacroProcessor::Meta::Role' ]
		}
	);
}

sub smp_add_description
{
	return &Salvation::MacroProcessor::smp_add_description( @_ );
}

sub smp_add_share
{
	return &Salvation::MacroProcessor::smp_add_share( @_ );
}

sub smp_add_alias
{
	return &Salvation::MacroProcessor::smp_add_alias( @_ );
}

sub smp_add_connector
{
	return &Salvation::MacroProcessor::smp_add_connector( @_ );
}

sub smp_import_descriptions
{
	return &Salvation::MacroProcessor::smp_import_descriptions( @_ );
}

sub smp_import_shares
{
	return &Salvation::MacroProcessor::smp_import_shares( @_ );
}


no Moose::Role;

-1;

__END__

# ABSTRACT: L<Salvation::MacroProcessor> to use within roles (see L<Moose::Manual::Roles> for info about roles)

=pod

=head1 NAME

Salvation::MacroProcessor::ForRoles - L<Salvation::MacroProcessor> to use within roles (see L<Moose::Manual::Roles> for info about roles)

=head1 DESCRIPTION

=head2 Example usage

 package MyRole;

 use Moose::Role;

 use Salvation::MacroProcessor::ForRoles;

 no Moose::Role;

=head1 REQUIRES

L<Moose> 

=head1 FUNCTIONS

See L<Salvation::MacroProcessor> for more info as both are exporting the same functions.

=cut

