use strict;

package Salvation::CLI;

use File::Spec ();
use File::Path '&make_path';

use Getopt::Std '&getopts';

{
	my %opts = ();

	&getopts( 'dS:s:h:v:', \%opts );

	if( $opts{ 'd' } )
	{
		if( my $sys = $opts{ 'S' } )
		{
			&deploy_system( $sys );

			if( my $srvs = [ split( /,/, $opts{ 's' } ) ] )
			{
				foreach my $srv ( @$srvs )
				{
					&deploy_service( $srv, $sys );

					if( ( my $type = $opts{ 'h' } ) and ( my $value = $opts{ 'v' } ) )
					{
						&deploy_hook( $srv, $sys, $type, $value );
					}
				}
			}
		}
	}
}

exit 0;

sub deploy_system
{
	my $pkg = shift;

	return &write_module( $pkg, sprintf( <<RAWPERL
use strict;

package %s;

use Moose;

extends 'Salvation::System';

no Moose;

-1;

RAWPERL
	, $pkg ) );
}

sub deploy_service
{
	my ( $service, $system ) = @_;

	my $pkg = sprintf( '%s::Services::%s',
			   $system,
			   $service );

	return ( &write_module( $pkg, sprintf( <<RAWPERL
use strict;

package %s;

use Moose;

extends 'Salvation::Service';

no Moose;

-1;

RAWPERL
	, $pkg ) )

	and &deploy_model( $service, $system )
	and &deploy_view( $service, $system )
	and &deploy_controller( $service, $system )
	and &deploy_op( $service, $system )
	and &deploy_dataset( $service, $system ) );
}

sub deploy_model
{
	my $pkg = sprintf( '%s::Services::%s::Defaults::M', pop, shift );

	return &write_module( $pkg, sprintf( <<RAWPERL
use strict;

package %s;

use Moose;

extends 'Salvation::Service::Model';

no Moose;

-1;

RAWPERL
	, $pkg ) );
}

sub deploy_view
{
	my $pkg = sprintf( '%s::Services::%s::Defaults::V', pop, shift );

	return &write_module( $pkg, sprintf( <<RAWPERL
use strict;

package %s;

use Moose;

extends 'Salvation::Service::View';

sub main
{
	return [
	];
}

no Moose;

-1;

RAWPERL
	, $pkg ) );
}

sub deploy_controller
{
	my $pkg = sprintf( '%s::Services::%s::Defaults::C', pop, shift );

	return &write_module( $pkg, sprintf( <<RAWPERL
use strict;

package %s;

use Moose;

extends 'Salvation::Service::Controller';

no Moose;

-1;

RAWPERL
	, $pkg ) );
}

sub deploy_op
{
	my $pkg = sprintf( '%s::Services::%s::Defaults::OutputProcessor', pop, shift );

	return &write_module( $pkg, sprintf( <<RAWPERL
use strict;

package %s;

use Moose;

extends 'Salvation::Service::OutputProcessor';

no Moose;

-1;

RAWPERL
	, $pkg ) );
}

sub deploy_dataset
{
	my $pkg = sprintf( '%s::Services::%s::DataSet', pop, shift );

	return &write_module( $pkg, sprintf( <<RAWPERL
use strict;

package %s;

use Moose;

extends 'Salvation::Service::DataSet';

sub main
{
	return [ 'dummy' ];
}

no Moose;

-1;

RAWPERL
	, $pkg ) );
}

sub deploy_hook
{
	my ( $service, $system, $type, $value ) = @_;

	my $new_service = sprintf( '%s::Hooks::%s::%s',
				   $service,
				   $type,
				   $value );

	my $pkg = sprintf( '%s::Services::%s',
			   $system,
			   $new_service );

	return ( &write_module( $pkg, sprintf( <<RAWPERL
use strict;

package %s;

use Moose;

extends 'Salvation::Service::Hook';

no Moose;

-1;

RAWPERL
	, $pkg ) )

	and &deploy_model( $new_service, $system )
	and &deploy_view( $new_service, $system )
	and &deploy_controller( $new_service, $system )
	and &deploy_op( $new_service, $system ) );
}

sub write_module
{
	my ( $pkg, $text ) = @_;

	my $info = &parse_pkg( $pkg );

	unless( -e $info -> { 'path' } )
	{
		&make_path( $info -> { 'dir' }, { mode => 0755 } );

		if( open( my $fh, '>', $info -> { 'path' } ) )
		{
			binmode( $fh, ':utf8' );

			if( flock( $fh, 2 ) )
			{
				print $fh $text . "\n";
				print STDOUT $info -> { 'path' } . "\n";
			}

			close( $fh );
		}
	}

	return 1;
}

sub parse_pkg
{
	my @arr = ( '.', split( /\:\:/, shift ) );

	my $out = {
		file => sprintf( '%s.pm', pop( @arr ) ),
		dir  => File::Spec -> catdir( @arr )
	};

	$out -> { 'path' } = File::Spec -> catfile( map{ $out -> { $_ } } ( 'dir', 'file' ) );

	return $out;
}

-1;

# ABSTRACT: Salvation CLI tool

=pod

=head1 NAME

Salvation::CLI - Salvation CLI tool

=head1 SYNOPSIS

 salvation.pl -d -S 'YourSystem'
 salvation.pl -d -S 'YourSystem' -s 'SomeService'
 salvation.pl -d -S 'YourSystem' -s 'SomeService' -h 'SomeTypeForHook' -v 'SomeValueForHook'
 salvation.pl -d -S 'YourSystem' -s 'SomeService,OtherService' -h 'SomeTypeForHook' -v 'SomeValueForHook'

=head1 DESCRIPTION

Command line tool which helps with generation of Salvation project files and directory tree.

=head1 ARGUMENTS

=head2 -d

Represents your intent to deploy a project.

Generates files and directory tree.

=head2 -S

Specifies the name of system affected.

=head2 -s

Specifies the name of service affected.

=head2 -h

Specifies the name of type of hook affected.

=head2 -v

Specifies the value of hook affected.

=cut

