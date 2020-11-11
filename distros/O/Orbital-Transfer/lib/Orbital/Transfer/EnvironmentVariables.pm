use Modern::Perl;
package Orbital::Transfer::EnvironmentVariables;
# ABSTRACT: Environment variables
$Orbital::Transfer::EnvironmentVariables::VERSION = '0.001';
use Mu;
use Orbital::Transfer::Common::Setup;
use Orbital::Transfer::Common::Types qw(InstanceOf ArrayRef Maybe Str);
use Config;

has parent => (
	is => 'ro',
	predicate => 1, # has_parent
	isa => InstanceOf['Orbital::Transfer::EnvironmentVariables'],
);

has _commands => (
	is => 'ro',
	isa => ArrayRef,
	handles_via => 'Array',
	default => sub { [] },
);

method _add_command( (Maybe[Str]) $variable, $data, $code ) {
	push @{ $self->_commands }, {
		var => $variable,
		cmd => (caller(1))[3],
		data => $data,
		code => $code,
	};
}

method prepend_path_list( (Str) $variable, (ArrayRef) $paths = [] ) {
	$self->_add_command( $variable, $paths, fun( $env, $hash ) {
		join $Config{path_sep}, @$paths, $env ? $env : ()
	});
}

method append_path_list( (Str) $variable, (ArrayRef) $paths = [] ) {
	$self->_add_command( $variable, $paths, fun( $env, $hash ) {
		join $Config{path_sep}, ( $env ? $env : () ), @$paths
	});
}

method prepend_string( (Str) $variable, (Str) $string = '' ) {
	$self->_add_command( $variable, $string, fun( $env, $hash ) {
		$string . $env
	});
}

method append_string( (Str) $variable, (Str) $string = '' ) {
	$self->_add_command( $variable, $string, fun( $env, $hash ) {
		$env . $string
	});
}

method set_string( (Str) $variable, (Str) $string = '' ) {
	$self->_add_command( $variable, $string, fun( $env, $hash ) {
		$string
	});
}

method add_environment( (InstanceOf['Orbital::Transfer::EnvironmentVariables']) $env_vars) {
	$self->_add_command( undef, $env_vars, fun( $env, $hash ) {
		$self->_add_environment( $env_vars, $hash );
	});
};

method _add_environment( $env_vars, $hash ) {
	if( $env_vars->has_parent ) {
		$self->_add_environment($env_vars->parent, $hash);
	}
	$self->_run_commands( $env_vars->_commands, $hash );
}

method _run_commands( $commands, $env ) {
	for my $command ( @$commands ) {
		if( defined $command->{var} ) {
			$env->{ $command->{var} } = $command->{code}->(
				$env->{ $command->{var} } // '',
				$env );
		} else {
			$command->{code}->( undef, $env );

		}
	}
}

method environment_hash() {
	my $env = {};
	if( $self->has_parent ) {
		$env = $self->parent->environment_hash;
	} else {
		# use whatever the current global/local %ENV is
		$env = { %ENV };
	}

	$self->_run_commands( $self->_commands, $env );

	$env;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::Transfer::EnvironmentVariables - Environment variables

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
