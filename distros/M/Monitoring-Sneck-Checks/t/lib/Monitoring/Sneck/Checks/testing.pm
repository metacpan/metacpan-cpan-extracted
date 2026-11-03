package Monitoring::Sneck::Checks::testing;

# A check for testing the runner, doing whatever its args say.

use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

sub option_spec {
	return (
		'code=s', 'out=s',   'err=s',   'print=s',     'warn=s', 'die=s',
		'run=s@', 'sleep=s', 'value=s', 'warning|w=s', 'critical|c=s'
	);
}

sub defaults { return { code => 0 } }

sub ranges { return ( 'warning', 'critical' ) }

sub check {
	my ($self) = @_;

	$self->out( $self->opt('out') . "\n" ) if defined( $self->opt('out') );
	$self->err( $self->opt('err') . "\n" ) if defined( $self->opt('err') );
	print $self->opt('print')              if defined( $self->opt('print') );
	warn( $self->opt('warn') . "\n" )      if defined( $self->opt('warn') );
	die( $self->opt('die') . "\n" )        if defined( $self->opt('die') );
	if ( defined( $self->opt('run') ) ) {
		my ( $exit, $output ) = $self->run_command( @{ $self->opt('run') } );
		$self->out( 'exit ' . $exit . "\n" . $output );
	}
	select( undef, undef, undef, $self->opt('sleep') ) if defined( $self->opt('sleep') );
	if ( defined( $self->opt('value') ) ) {
		$self->perfdata(
			label    => 'value',
			value    => $self->opt('value'),
			warning  => $self->opt('warning'),
			critical => $self->opt('critical')
		);
		return $self->finish(
			$self->threshold_status( $self->opt('value'), $self->opt('warning'), $self->opt('critical') ),
			'value is ' . $self->opt('value') );
	} ## end if ( defined( $self->opt('value') ) )

	return $self->opt('code') eq 'undef' ? undef : $self->opt('code');
} ## end sub check

1;
