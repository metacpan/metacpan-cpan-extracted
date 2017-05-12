package PulseAudio::Backend::Utilities;
use strict;
use warnings;
use feature ':5.14';

use Moose::Role;

use PulseAudio::Types qw();

use autodie;
use IPC::Run3;

our $_command_db;

foreach my $name ( qw/card source source_output sink sink_input module client/ ) {
	my $attr = $name . 's';
	my $module = 'PulseAudio::' . ucfirst( lc $name );
	
	has ( $attr, (
		isa       => 'HashRef'
		, is      => 'ro'
		, lazy    => 1
		, traits  => ['Hash']
		, handles  => { sprintf( 'get_%s_by_index', $name ) => 'get' }
		, default => sub {
			my $self = shift;
			my %db;
			while ( my ($idx, $data) = each %{$self->get_raw($name)} ) {
				$db{$idx} = $module->new({ index => $idx, dump => $data, server => $self });
			}
			\%db;
		}
	) );

	__generate_get_by_method($name, $attr);
}

## This is stupid. Sample is referred to as 'cache entrie(s)' in 'pacmd info'
## Also uses name and not index
{
	has 'samples' => (
		isa       => 'HashRef'
		, is      => 'ro'
		, lazy    => 1
		, traits  => ['Hash']
		, handles  => { 'get_sample_by_name' => 'get' }
		, default => sub {
			my $self = shift;
			my %db;
			while ( my ($idx, $data) = each %{$self->get_raw('cache_entrie')} ) {
				$db{$idx} = PulseAudio::Sample->new({ name => $idx, dump => $data, server => $self });
			}
			\%db;
		}
	);

	__generate_get_by_method( 'sample', 'samples' );
}

has 'defaults' => (
	isa       => 'HashRef'
	, is      => 'ro'
	, lazy    => 1
	, default => sub {
		my $self = shift;
		my %db;
		while ( my ($k,$v) = each %{$self->get_raw('default')} ) {
			given ( $k ) {
				when ( qr/sink/ ) {
					$db{sink} = $self->get_sink_by(['name'] => $v);
				}
				when ( qr/source/ ) {
					$db{source} = $self->get_source_by(['name'] => $v);
				}
				default {
					$db{$k} = $v
				}
			}
		}
		\%db;
	}
);

sub _pacmd_help {

	return $_command_db if $_command_db;

	open( my $fh , '-|', 'pacmd', 'help' );
	my %db;

	while ( my $line = $fh->getline ) {
		chomp $line;
		next unless $line =~ /^ \s+ ([a-z-]+) \s+ (.*)/x;
		my ( $name, $desc ) = ( $1, $2 );

		my $alias = $name;
		$alias =~ tr/-/_/;

		## Split for arguments
		my @func_sig;
		if ( $desc =~ /\(args?: (.*)\)/ ) {
			@func_sig = split /, */, $1;
		};

		## Handle the catagory
		## Some commands can be trigger on two modules
		## like play-sample ( sample-name, sink )
		my @cat;
		given ( $name ) {
			when ( qr/(?<!un)load/ )        { @cat = ('load') }
			when ( qr/^list|stat|info/ )    { @cat = ('list') }
			when ( qr/dump|help|shared|describe-|set-log-/ ) {
				@cat = ('unsupported');
			}
			when ( qr/^(?:suspend|exit)$/ ) {
				@cat = ('misc');
			}
			when ( qr/card/ )        { push @cat, 'card'; continue; }
			when ( qr/client/ )      { push @cat, 'client'; continue; }
			when ( qr/module/ )      { push @cat, 'module'; continue; }
			when ( qr/sample/ )      { push @cat, 'sample'; continue; }
			when ( qr/source/ )      {
				push @cat, ( $name =~ qr/output/ ? 'source_output' : 'source' );
				continue;
			}
			when ( qr/sink|play/ )   {
				push @cat, ( $name =~ qr/input/ ? 'sink_input' : 'sink' );
				continue;
			}
			default { die "No category for $name" unless @cat; }
		};

		## Generate the subs for attachment to classes
		my $sub;
		if ( 'list' ~~ @cat ) {
			my $key = $alias;
			if ( $alias =~ qr/list[-_](.*)s/ ) {
				$key = $1;
			}

			$sub = sub {
				my $self = shift;
				my $info = $self->info;
				if ( exists $info->{$key} ) {
					return $info->{$key};
				}
				else {
					Carp::croak "Command [$key] is not supported\n";
				}
			};

		}
		elsif ( @func_sig && $func_sig[0] ~~ qr/index/ ) {
			$sub = sub {
				my ( $self, @args ) = @_;
				unshift @args, $self;
				_coerce_and_test_function_types( \@args, \@func_sig );
				_exec( $name, @args );
				$self;
			}
		}
		elsif ( @func_sig && $func_sig[-1] ~~ qr/index/ ) {
			$sub = sub {
				my ( $self, @args ) = @_;
				push @args, $self;
				_coerce_and_test_function_types( \@args, \@func_sig );
				_exec( $name, @args );
				$self;
			}
		}
		elsif (
			@func_sig == 1 && $func_sig[0] ~~ 'name'
			or ( @cat == 1 and $cat[0] eq 'load' || $cat[0] eq 'misc' )
		) {
			$sub = sub {
				my ( $self, @args ) = @_;
				_coerce_and_test_function_types( \@args, \@func_sig );
				_exec( $name, @args );
				$self;
			};
		}
		elsif ( @cat == 1 && $cat[0] eq 'unsupported' ) {
			$sub = sub { die "[Function $name, alias $alias] Not supported\n" };
		}
		else {
			die "$line [@cat] is not supported, no idea of how to generate method\n"
		}
		
		my $cmd = $db{commands}{$alias} = {
			desc => $desc
			, args => @func_sig?\@func_sig:undef
			, name => $name
			, sub  => $sub
			, alias => $alias
		};
		foreach my $cat ( @cat ) {
			push @{ $db{catagory}{$cat} }, $cmd;
		}

	}

	## Functions to add
	{
		my $cmd = $db{commands}{list_defaults} = {
			desc => 'List defaults'
			, args => undef
			, name => '_list-defaults'
			, sub  => sub { +shift->info->{'default'} }
			, alias => 'list_defaults'
		};
		push @{ $db{catagory}{'list'} }, $cmd;
	}


	$_command_db //= \%db;

}


has 'info' => (
	isa       => 'HashRef'
	, is      => 'ro'
	, traits  => ['Hash']
	, handles => {
		'get_raw' => 'get'
	}
	, default => sub {
		my $self = shift;
		open( my $fh , '-|', 'pacmd', 'info' );

		my %db;
		while ( my $line = $fh->getline ) {
			chomp $line;
			state ( $idx, $cat, $last_key );
			state @tree_pos;

			## handles the defaults
			if ( $line =~ qr/Default ([^:]+?): (.+)/ ) {
				my ($k, $v) = ($1, $2);
				s/^"|^\s+|\s+$|"$//g for grep defined, $k, $v;

				$db{default}{$k} = $v;
			}
			## picks up lines like '22 module(s) loaded.'
			elsif ( $line =~ qr/^(\d+) \s+ (.+?) s? \(s\) .* \.$/x ) {
				undef @tree_pos;
				$cat = $2;
				$cat =~ tr/ /_/;
				$db{$cat} = undef if $1 == 0;
			}
			## index line, needed for all descriptions
			elsif ( $line =~ qr/^\ {2} [ *]+? (?:index|name): \s* <? ([^>]+) >?/x ) {
				$idx = $1;
			}
			## data line
			elsif ( $line =~ qr/^(\t+) ([^\s][^:=]+) \s* [:=] \s* <? ([^>]+)? /x ) {
				my ($k, $v) = ($2, $3);
				s/^"|^\s+|\s+$|"$//g for grep defined, $k, $v;
				
				$#tree_pos = ( (length $1) - 1 );
				$tree_pos[ -1 ] = { key => $k, value => $v };

				if ( $v ) {
					if ( @tree_pos == 1 ) {
						$db{$cat}{$idx}{$k} = $v;
					}
					else {
						my $x = \%{ $db{$cat}{$idx} };
						my $level = 0;
						while ( $level + 1 < @tree_pos ) {
							$x = \%{ $x->{ $tree_pos[$level++]->{key} } };
						}
						$x->{$k} = $v;
					}
					$last_key = $k;
				}
			}
			## hanging data, this means effectively that it is of a fixed width format	
			elsif ( $line =~ qr/^ \t+ \s* ([^\s].*)/x ){
				my $data = $1 =~ s/^\s+|\s+$//g;
				my $x = \%{ $db{$cat}{$idx} };
				my $level = 0;
				while ( $level + 1 < @tree_pos ) {
					$x = \%{ $x->{ $tree_pos[$level++]->{key} } };
				}
				if ( ref $x->{$last_key} eq 'ARRAY' ) {
					push @{ $x->{$last_key} }, $1
				}
				else {
					$x->{$last_key} = [ $x->{$last_key}, $1 ];
				}
			}
			elsif ( $line =~ /\w/ && $line ~~ qr/memory|cache|welcome/i ) {
				push @{$db{stat}} , $line;
			}
			elsif ( $line =~ /\w/ && $line !~ qr/memory|cache|welcome/i ) {
				warn "Unexpected line $line\n";
			}
			
		}

		close $fh;

		return \%db;
	}
);

sub get_default_sink {
	my $self = shift;
	$self->defaults->{sink};
}

sub get_default_source {
	my $self = shift;
	$self->defaults->{source};
}


sub _exec {
	say "EXEC: @_" if $ENV{DEBUG};

	my ($out, $err);
	IPC::Run3::run3( ['pacmd', @_], \undef, \$out, \$err ) or die;

	if ( $ENV{DEBUG} ) {
		tr/\r\n>//d for $out, $err;
		say "\t STDOUT: $out";
		say "\t STDERR: $err";
	}

	die $err if $err;

}

## A simple helper function that takes an arguments, and an array of types and
## tries to coerce the arguments to the types.
sub _coerce_and_test_function_types {
	my ( $argRef, $typeRef ) = @_;
	
	warn 'Not enough arguments passed'
		if scalar @$argRef != scalar @$typeRef
	;
	
	my $count = 0;
	for ( @$argRef ) {
		given ( $typeRef->[$count] ) {
			when ( qr/index|sink|source/ ) {
				$argRef->[$count] = PulseAudio::Types::to_PA_Index($argRef->[$count])
					unless PulseAudio::Types::is_PA_Index($argRef->[$count])
				;
			}
			when ( 'name' ) {
				$argRef->[$count] = PulseAudio::Types::to_PA_Name($argRef->[$count])
					unless PulseAudio::Types::is_PA_Name($argRef->[$count])
				;
			}
			when ( 'volume' ) {
				$argRef->[$count] = PulseAudio::Types::to_PA_Volume($argRef->[$count])
					unless PulseAudio::Types::is_PA_Volume($argRef->[$count])
				;
			}
			when ( 'bool' ) {
				$argRef->[$count] = PulseAudio::Types::to_PA_Bool($argRef->[$count])
					unless PulseAudio::Types::is_PA_Bool($argRef->[$count])
				;
			}
			when ( 'arguments' ) {
				Carp::croak 'Invalid argument, not a string'
					unless MooseX::Types::Moose::is_Str($argRef->[$count])
				;
				die;
			}
		};
		$count++;
	}

}

foreach my $cmd ( @{_commands()} ) {
	__PACKAGE__->meta->add_method( $cmd->{alias} => $cmd->{sub} );
}

sub _commands {
	[
		@{ _pacmd_help->{catagory}{list} }
		, @{ _pacmd_help->{catagory}{load} }
		, @{ _pacmd_help->{catagory}{misc} }
		, @{ _pacmd_help->{catagory}{unsupported} }
	]
}

sub __generate_get_by_method {
	my ($name, $attr) = @_;
	
	my $method_name = sprintf( 'get_%s_by', $name );

	## This gets invoked like $pa->get_sink_by( [name] => 'foo' );
	## Should permit $pa->get_sink_by( [name] => 'foo', [bar] => 'baz' );
	__PACKAGE__->meta->add_method(
		$method_name
		, sub {
			my $self = shift;
			OBJ: foreach my $obj ( values %{$self->$attr} ) {
				my @args = @_;
				while ( my ( $loc, $value ) = splice ( @args, 0, 2 ) ) {
					my $v;
					$v = $obj->_dump;
					$v = $v->{$_} for @$loc;
					next OBJ unless $v ~~ $value;
				}
				return $obj;
			}
			Carp::croak "No object found in call to $method_name\n";
		}
	);

}

use PulseAudio::Card;
use PulseAudio::Client;
use PulseAudio::Sink;
use PulseAudio::SinkInput;
use PulseAudio::Source;
use PulseAudio::SourceOutput;
use PulseAudio::Module;
use PulseAudio::Sample;

1;

__END__

=head1 NAME

PulseAudio::Backend::Utilities - A backend module for the PulseAudio

=head1 DESCRIPTION

This module serves to provide the functionality of the backend utilities. It has two parsers:

=over 4

=item B<pacmd help>

It generates appropriate methods and function signatures for the different object types that this module provides. This determines what the objects can do.

The result of the parsing is accessable by the B<__pacmd_help> function.

=item B<pacmd info>

It provides the data that is used to initialize the appropriate objects for your system, and further provides the data returned with the L<Commands/LISTING> commands.

The result of this parsing is stored in the B<info> attribute.

=back

This module provides all of the attributes and the guts for L<PulseAudio>.

