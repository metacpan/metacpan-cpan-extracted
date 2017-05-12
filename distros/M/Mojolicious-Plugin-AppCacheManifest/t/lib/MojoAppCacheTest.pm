package MojoAppCacheTest;

use strict;
use warnings;

use base qw( Mojolicious );

sub development_mode
{
	my $self = shift;

	$self->static->paths->[0] = $self->home->rel_dir( "public" );
}

sub startup
{
	my $self = shift;

	#$self->log->level( "fatal" );

	$self->plugin( "AppCacheManifest" );
}

1;
