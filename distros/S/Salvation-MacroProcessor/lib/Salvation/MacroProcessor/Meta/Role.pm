use strict;

package Salvation::MacroProcessor::Meta::Role;

use Moose::Role;

use Carp::Assert 'assert';
use Scalar::Util 'blessed';
use Module::Load 'load';
use List::MoreUtils 'uniq';

use constant
{
	DBCF_UUID => 'd1293527-1ae9-426c-8d3c-daf827ca0ef9'
};


__PACKAGE__ -> meta() -> add_method( &DBCF_UUID => sub{ 1 } );


has 'smp_descriptions'	=> ( is => 'rw', isa => 'HashRef', default => sub{ {} }, traits => [ 'Hash' ], handles => { __smp_get_all_descriptions => 'values', __smp_get_all_descriptions_names => 'keys' } );

has 'smp_hook'		=> ( is => 'ro', isa => 'Maybe[Salvation::MacroProcessor::Hooks]', lazy => 1, builder => '__build_smp_hook' );

has 'smp_shares'	=> ( is => 'rw', isa => 'HashRef', default => sub{ {} }, traits => [ 'Hash' ], handles => { __smp_get_all_shares => 'kv', __smp_get_all_shares_names => 'keys' } );

has 'smp_aliases'	=> ( is => 'rw', isa => 'HashRef', default => sub{ {} }, traits => [ 'Hash' ], handles => { __smp_get_all_aliases => 'kv', __smp_get_all_aliases_names => 'keys' } );

has 'smp_connectors'	=> ( is => 'rw', isa => 'HashRef', default => sub{ {} } );

has 'smp_imported_descriptions'	=> ( is => 'rw', isa => 'HashRef', default => sub{ {} }, traits => [ 'Hash' ], handles => { __smp_get_all_imported_descriptions => 'values', __smp_get_all_imported_descriptions_names => 'keys' } );

has 'smp_imported_shares'	=> ( is => 'rw', isa => 'HashRef', default => sub{ {} }, traits => [ 'Hash' ], handles => { __smp_get_all_imported_shares => 'kv', __smp_get_all_imported_shares_names => 'keys' } );


sub smp_add_description
{
	my ( $self, $description ) = @_;

	assert( ( blessed( $description ) and $description -> isa( 'Salvation::MacroProcessor::MethodDescription' ) ), sprintf( 'Bad description: "%s"', $description ) );

	my $method = $description -> method();

	assert( not( exists $self -> smp_descriptions() -> { $method } ), sprintf( 'Description of method "%s" for class "%s" is already present', $method, $self -> name() ) );

	assert( not( exists $self -> smp_aliases() -> { $method } ), sprintf( 'Could not add description for method "%s" of class "%s": class already has an alias with same name which is for method "%s"', $method, $self -> name(), ( $self -> smp_aliases() -> { $method } or '' ) ) );

	$self -> smp_descriptions() -> { $method } = $description;

	return 1;
}

sub smp_import_descriptions
{
	my ( $self, $data ) = @_;

	assert( ( ref( $data ) eq 'HASH' ), sprintf( 'Bad import spec: "%s"', $data ) );

	my ( $class, $prefix, $list, $connector ) = delete @$data{ 'class', 'prefix', 'list', 'connector' };

	{
		my @keys = keys %$data;

		assert( ( scalar( @keys ) == 0 ), sprintf( 'Unknown parameters: %s', join( ', ', map{ sprintf( '"%s"', $_ ) } @keys ) ) );
	}

	assert( $class -> isa( 'Moose::Object' ), sprintf( '"%s" is not a Moose::Object-derived class', $class ) );

	{
		my $meta = $class -> meta();

		assert( ( blessed( $meta ) and ( $meta -> isa( 'Moose::Meta::Class' ) or $meta -> isa( 'Moose::Meta::Role' ) ) ), sprintf( 'Unknown metaclass of "%s": "%s"', $class, $meta ) );
		assert( $meta -> can( DBCF_UUID ), sprintf( '"%s" has no MacroProcessor support', $class ) );
	}

	if( defined $list )
	{
		assert( ( ref( $list ) eq 'ARRAY' ), sprintf( 'Bad import list: "%s"', $list ) );

	} else
	{
		my $meta = $class -> meta();

		$list = [ uniq( $meta -> smp_get_all_descriptions_names(), $meta -> smp_get_all_imported_descriptions_names(), $meta -> smp_get_all_aliases_names() ) ];
	}

	assert( ( $connector and not( ref $connector ) ), sprintf( 'Bad connector: "%s"', $connector ) );

	my $data_list = $self -> smp_imported_descriptions();

	assert( scalar( @$list ), sprintf( 'Nothing to import from "%s" to "%s"', $class, $self -> name() ) );

	foreach my $description ( @$list )
	{
		$data_list -> { ( $prefix ? sprintf( '%s%s', $prefix, $description ) : $description ) } = {

			class     => $class,
			connector => $connector,

			( $prefix ? (
				prefix => $prefix,
				orig   => $description
			) : () )
		};
	}

	return 1;
}

sub smp_add_share
{
	my ( $self, $name, $code ) = @_;

	assert( defined( $name ) and not( ref( $name ) ) );
	assert( ref( $code ) eq 'CODE' );

	assert( not( exists $self -> smp_shares() -> { $name } ), sprintf( 'Share "%s" for class "%s" is already defined', $name, $self -> name() ) );

	$self -> smp_shares() -> { $name } = $code;

	return 1;
}

sub smp_import_shares
{
	my ( $self, $data ) = @_;

	assert( ( ref( $data ) eq 'HASH' ), sprintf( 'Bad import spec: "%s"', $data ) );

	my ( $class, $prefix, $list ) = delete @$data{ 'class', 'prefix', 'list' };

	{
		my @keys = keys %$data;

		assert( ( scalar( @keys ) == 0 ), sprintf( 'Unknown parameters: %s', join( ', ', map{ sprintf( '"%s"', $_ ) } @keys ) ) );
	}

	assert( $class -> isa( 'Moose::Object' ), sprintf( '"%s" is not a Moose::Object-derived class', $class ) );

	{
		my $meta = $class -> meta();

		assert( ( blessed( $meta ) and ( $meta -> isa( 'Moose::Meta::Class' ) or $meta -> isa( 'Moose::Meta::Role' ) ) ), sprintf( 'Unknown metaclass of "%s": "%s"', $class, $meta ) );
		assert( $meta -> can( DBCF_UUID ), sprintf( '"%s" has no MacroProcessor support', $class ) );
	}

	if( defined $list )
	{
		assert( ( ref( $list ) eq 'ARRAY' ), sprintf( 'Bad import list: "%s"', $list ) );

	} else
	{
		my $meta = $class -> meta();

		$list = [ uniq( $meta -> smp_get_all_shares_names(), $meta -> smp_get_all_imported_shares_names() ) ];
	}

	my $data_list = $self -> smp_imported_shares();

	foreach my $share ( @$list )
	{
		$data_list -> { ( $prefix ? sprintf( '%s%s', $prefix, $share ) : $share ) } = {

			class  => $class,

			( $prefix ? (
				prefix => $prefix,
				orig   => $share
			) : () )
		};
	}

	return 1;
}

sub smp_add_connector
{
	my ( $self, $connector ) = @_;

	assert( ( blessed( $connector ) and $connector -> isa( 'Salvation::MacroProcessor::Connector' ) ), sprintf( 'Bad connector: "%s"', $connector ) );

	my $name = $connector -> name();

	assert( not( exists $self -> smp_connectors() -> { $name } ), sprintf( 'Connector "%s" for class "%s" is already defined', $name, $self -> name() ) );

	$self -> smp_connectors() -> { $name } = $connector;

	return 1;
}

sub smp_add_alias
{
	my ( $self, $alias, $name ) = @_;

	assert( defined( $alias ) and not( ref( $alias ) ) );
	assert( defined( $name ) and not( ref( $name ) ) );

	assert( not( exists $self -> smp_descriptions() -> { $alias } ), sprintf( 'Class "%s" already has description for method "%s" which you want to be the alias for "%s"', $self -> name(), $alias, $name ) );

	assert( not( exists $self -> smp_aliases() -> { $alias } ), sprintf( 'Class "%s" already has an alias "%s" which is for method "%s"', $self -> name(), $alias, ( $self -> smp_aliases() -> { $alias } or '' ) ) );

	assert( ( exists( $self -> smp_descriptions() -> { $name } ) or exists( $self -> smp_imported_descriptions() -> { $name } ) ), sprintf( 'Could not add alias "%s" for method "%s" of class "%s": you have no description for this method', $alias, $name, $self -> name() ) );

	$self -> smp_aliases() -> { $alias } = $name;

	return 1;
}

sub smp_find_description_by_name
{
	my ( $self, $name ) = @_;

	if( my $name = $self -> smp_aliases() -> { $name } )
	{
		return $self -> smp_find_description_by_name( $name );
	}

	if( exists( ( my $list = $self -> smp_descriptions() ) -> { $name } ) )
	{
		return $list -> { $name };
	}

	if( $self -> can( 'calculate_all_roles' ) and not $self -> isa( 'Moose::Meta::Role' ) )
	{
		foreach my $role ( $self -> calculate_all_roles() )
		{
			next if $role -> isa( 'Moose::Meta::Role::Composite' );
			next if $role -> is_anon_role();

			if( $role -> can( DBCF_UUID ) )
			{
				if( my $name = $role -> smp_aliases() -> { $name } )
				{
					return $self -> smp_find_description_by_name( $name );
				}

				if( my $role_description = $role -> smp_find_description_by_name( $name ) )
				{
					if( $self -> isa( 'Moose::Meta::Class' ) )
					{
						my %overrides = ();

						unless( $role_description -> __imported() )
						{
							$overrides{ 'associated_meta' } = $self;
						}

						# following block looks like a crutch
						if( ( my $connector_chain = $role_description -> connector_chain() ) -> [ 0 ] )
						{
							my @connector_chain = @$connector_chain;
							my $last_link       = pop @connector_chain;

							push @connector_chain, [ $self -> name(), pop( @$last_link ) ];

							$overrides{ 'connector_chain' } = \@connector_chain;
						}

						my $description = $role_description -> clone( %overrides );

						$self -> smp_add_description( $description );

						return $description;

					} else
					{
						return $role_description;
					}
				}
			}
		}
	}

	if( $self -> can( 'linearized_isa' ) )
	{
		( undef, my @isa ) = $self -> linearized_isa();

		foreach my $class ( @isa )
		{
			if( ( my $meta = $class -> meta() ) -> can( DBCF_UUID ) )
			{
				if( my $ancestor_description = $meta -> smp_find_description_by_name( $name ) )
				{
					my $description = $ancestor_description -> clone(
						associated_meta            => $self,
						previously_associated_meta => $meta
					);

					$self -> smp_add_description( $description );

					return $description;
				}
			}
		}
	}

	if( exists( ( my $list = $self -> smp_imported_descriptions() ) -> { $name } ) )
	{
		my $data = $list -> { $name };

		my $class     = $data -> { 'class' };
		my $prefix    = $data -> { 'prefix' };
		my $orig      = ( $data -> { 'orig' } or $name );
		my $connector = $data -> { 'connector' };

		my $foreign_description = $class -> meta() -> smp_find_description_by_name( $orig );

		assert( $foreign_description, sprintf( 'Could not import description for method "%s" from class "%s" for description "%s" of class "%s": no description defined', $orig, $class, $name, $self -> name() ) );

		my %overrides = (
			connector_chain => [ @{ $foreign_description -> connector_chain() }, [ $self -> name(), $connector ] ],
			orig_method     => $foreign_description -> orig_method(),
			imported        => 1
		);

		if( $prefix )
		{
			$overrides{ 'method' } = $name;

			foreach my $key ( ( 'required_shares', 'required_filters', 'excludes_filters' ) )
			{
				my $method = sprintf( '__%s', $key );

				$overrides{ $key } = [ map{ sprintf( '%s%s', $prefix, $_ ) } @{ $foreign_description -> $method() } ];
			}
		}

		my $description = $foreign_description -> clone( %overrides );

		$self -> smp_add_description( $description );

		return $description;
	}

	return undef;
}

sub smp_find_share_by_name
{
	my ( $self, $name ) = @_;

	if( exists( ( my $list = $self -> smp_shares() ) -> { $name } ) )
	{
		return $list -> { $name };
	}

	if( $self -> can( 'calculate_all_roles' ) and not $self -> isa( 'Moose::Meta::Role' ) )
	{
		foreach my $role ( $self -> calculate_all_roles() )
		{
			next if $role -> isa( 'Moose::Meta::Role::Composite' );
			next if $role -> is_anon_role();

			if( $role -> can( DBCF_UUID ) )
			{
				if( my $role_share = $role -> smp_find_share_by_name( $name ) )
				{
					$self -> smp_add_share( $name => $role_share ) if $self -> isa( 'Moose::Meta::Class' );

					return $role_share;
				}
			}
		}
	}

	if( $self -> can( 'linearized_isa' ) )
	{
		( undef, my @isa ) = $self -> linearized_isa();

		foreach my $class ( @isa )
		{
			if( ( my $meta = $class -> meta() ) -> can( DBCF_UUID ) )
			{
				if( my $share = $meta -> smp_find_share_by_name( $name ) )
				{
					$self -> smp_add_share( $name => $share );

					return $share;
				}
			}
		}
	}

	if( exists( ( my $list = $self -> smp_imported_shares() ) -> { $name } ) )
	{
		my $data = $list -> { $name };

		my $class  = $data -> { 'class' };
		my $orig   = ( $data -> { 'orig' } or $name );

		my $foreign_share = $class -> meta() -> smp_find_share_by_name( $orig );

		assert( $foreign_share, sprintf( 'Could not import share "%s" from class "%s" for share "%s" of class "%s": no share defined', $orig, $class, $name, $self -> name() ) );

		$self -> smp_add_share( $name, $foreign_share );

		return $foreign_share;
	}

	return undef;
}

sub smp_find_connector_by_name
{
	my ( $self, $name ) = @_;

	if( exists( ( my $list = $self -> smp_connectors() ) -> { $name } ) )
	{
		return $list -> { $name };
	}

	if( $self -> can( 'calculate_all_roles' ) and not $self -> isa( 'Moose::Meta::Role' ) )
	{
		foreach my $role ( $self -> calculate_all_roles() )
		{
			next if $role -> isa( 'Moose::Meta::Role::Composite' );
			next if $role -> is_anon_role();

			if( $role -> can( DBCF_UUID ) )
			{
				if( my $role_connector = $role -> smp_find_connector_by_name( $name ) )
				{
					if( $self -> isa( 'Moose::Meta::Class' ) )
					{
						my $connector = $role_connector -> clone( associated_meta => $self );

						$self -> smp_add_connector( $connector );

						return $connector;

					} else
					{
						return $role_connector;
					}
				}
			}
		}
	}

	if( $self -> can( 'linearized_isa' ) )
	{
		( undef, my @isa ) = $self -> linearized_isa();

		foreach my $class ( @isa )
		{
			if( ( my $meta = $class -> meta() ) -> can( DBCF_UUID ) )
			{
				if( my $ancestor_connector = $meta -> smp_find_connector_by_name( $name ) )
				{
					my $connector = $ancestor_connector -> clone(
						associated_meta            => $self,
						previously_associated_meta => $meta
					);

					$self -> smp_add_connector( $connector );

					return $connector;
				}
			}
		}
	}

	return undef;
}

sub smp_find_share_import_spec_by_name
{
	my ( $self, $name ) = @_;

	if( exists( ( my $list = $self -> smp_imported_shares() ) -> { $name } ) )
	{
		return $list -> { $name };
	}

	if( $self -> can( 'calculate_all_roles' ) and not $self -> isa( 'Moose::Meta::Role' ) )
	{
		foreach my $role ( $self -> calculate_all_roles() )
		{
			next if $role -> isa( 'Moose::Meta::Role::Composite' );
			next if $role -> is_anon_role();

			if( $role -> can( DBCF_UUID ) )
			{
				if( my $role_spec = $role -> smp_find_share_import_spec_by_name( $name ) )
				{
					return $role_spec;
				}
			}
		}
	}

	if( $self -> can( 'linearized_isa' ) )
	{
		( undef, my @isa ) = $self -> linearized_isa();

		foreach my $class ( @isa )
		{
			if( ( my $meta = $class -> meta() ) -> can( DBCF_UUID ) )
			{
				if( my $spec = $meta -> smp_find_share_import_spec_by_name( $name ) )
				{
					return $spec;
				}
			}
		}
	}

	return undef;
}

sub __build_smp_hook
{
	my $self = shift;

	if( $self -> can( 'linearized_isa' ) )
	{
		foreach my $class ( $self -> linearized_isa() )
		{
			my $pkg = sprintf( 'Salvation::MacroProcessor::Hooks::%s', $class );

			if( eval{ load $pkg; 1; } )
			{
				return $pkg -> new();
			}
		}
	}

	return undef;
}

{
	my $what = 'aliases';

	sub smp_get_all_aliases_names
	{
		return shift -> __smp_get_all_names( $what );
	}

	sub smp_get_all_aliases
	{
		my $self = shift;

		return $self -> smp_uniq_descriptions( $self -> __smp_get_all( $what ) );
	}

	sub smp_uniq_aliases
	{
		my ( undef, @rest ) = @_;

		my %seen = ();

		return grep{ ! $seen{ $_ -> [ 0 ] } ++ } @rest;
	}
}

{
	my $what = 'descriptions';

	sub smp_get_all_descriptions_names
	{
		return shift -> __smp_get_all_names( $what );
	}

	sub smp_get_all_imported_descriptions_names
	{
		return shift -> __smp_get_all_imported_names( $what );
	}

	sub smp_get_all_descriptions
	{
		my $self = shift;

		return $self -> smp_uniq_descriptions( $self -> __smp_get_all( $what ) );
	}

	sub smp_get_all_imported_descriptions
	{
		my $self = shift;

		return $self -> smp_uniq_descriptions( $self -> __smp_get_all_imported( $what ) );
	}

	sub smp_uniq_descriptions
	{
		my ( undef, @rest ) = @_;

		my %seen = ();

		return grep{ ! $seen{ $_ -> method() } ++ } @rest;
	}
}

{
	my $what = 'shares';

	sub smp_get_all_shares_names
	{
		return shift -> __smp_get_all_names( $what );
	}

	sub smp_get_all_imported_shares_names
	{
		return shift -> __smp_get_all_imported_names( $what );
	}

	sub smp_get_all_shares
	{
		my $self = shift;

		return $self -> smp_uniq_shares( $self -> __smp_get_all( $what ) );
	}

	sub smp_get_all_imported_shares
	{
		my $self = shift;

		return $self -> smp_uniq_shares( $self -> __smp_get_all_imported( $what ) );
	}

	sub smp_uniq_shares
	{
		my ( undef, @rest ) = @_;

		my %seen = ();

		return grep{ ! $seen{ $_ -> [ 0 ] } ++ } @rest;
	}
}

{
	my $what = 'imported';

	sub __smp_get_all_imported
	{
		return shift -> __smp_get_all( sprintf( '%s_%s', $what, shift ) );
	}

	sub __smp_get_all_imported_names
	{
		return shift -> __smp_get_all_names( sprintf( '%s_%s', $what, shift ) );
	}
}

sub __smp_get_all_names
{
	return uniq( shift -> __smp_get_all( sprintf( '%s_names', shift ) ) );
}

sub __smp_get_all
{
	my $self        = shift;
	my $orig_method = sprintf( 'smp_get_all_%s', shift );
	my $method      = sprintf( '__%s', $orig_method );
	my @output      = $self -> $method();

	if( $self -> can( 'calculate_all_roles' ) and not $self -> isa( 'Moose::Meta::Role' ) )
	{
		foreach my $role ( $self -> calculate_all_roles() )
		{
			next if $role -> isa( 'Moose::Meta::Role::Composite' );
			next if $role -> is_anon_role();

			if( $role -> can( DBCF_UUID ) )
			{
				push @output, $role -> $orig_method();
			}
		}
	}

	if( $self -> can( 'linearized_isa' ) )
	{
		( undef, my @isa ) = $self -> linearized_isa();

		foreach my $class ( @isa )
		{
			if( ( my $meta = $class -> meta() ) -> can( DBCF_UUID ) )
			{
				push @output, $meta -> $orig_method();
			}
		}
	}

	return @output;
}


no Moose::Role;

-1;

__END__

# ABSTRACT: L<Salvation::MacroProcessor>'s role for metaclasses

=pod

=head1 NAME

Salvation::MacroProcessor::Meta::Role - L<Salvation::MacroProcessor>'s role for metaclasses

=head1 REQUIRES

L<List::MoreUtils> 

L<Module::Load> 

L<Scalar::Util> 

L<Carp::Assert> 

L<Moose> 

=head1 METHODS

=head2 smp_add_alias

 $meta -> smp_add_alias( $alias, $name );

Backend for L<Salvation::MacroProcessor>C<::smp_add_alias>.

=head2 smp_add_connector

 $meta -> smp_add_connector( $connector );

Backend for L<Salvation::MacroProcessor>C<::smp_add_connector>.

C<$connector> is a L<Salvation::MacroProcessor::Connector> instance.

=head2 smp_add_description

 $meta -> smp_add_description( $description );

Backend for L<Salvation::MacroProcessor>C<::smp_add_description>.

C<$description> is a L<Salvation::MacroProcessor::MethodDescription> instance.

=head2 smp_add_share

 $meta -> smp_add_share( $name, $code );

Backend for L<Salvation::MacroProcessor>C<::smp_add_share>.

=head2 smp_import_descriptions

 $meta -> smp_import_descriptions( {
 	class => $class,
	prefix => $prefix,
	list => $list,
	connector => $connector
 } );

Backend for L<Salvation::MacroProcessor>C<::smp_import_descriptions>.

=head2 smp_import_shares

 $meta -> smp_import_shares( {
 	class => $class,
	prefix => $prefix,
	list => $list
 } );

Backend for L<Salvation::MacroProcessor>C<::smp_import_shares>.

=head2 smp_find_connector_by_name

 $meta -> smp_find_connector_by_name( $name );

C<$name> is a string.

Finds and returns L<Salvation::MacroProcessor::Connector> instance, or C<undef> if nothing is found.

Looks firstly at current class, secondly at its roles and thirdly at class's ancestors, if any.

=head2 smp_find_description_by_name

 $meta -> smp_find_description_by_name( $name );

C<$name> is a string.

Finds and returns L<Salvation::MacroProcessor::MethodDescription> instance, or C<undef> if nothing is found.

Looks firstly at aliases of current class, secondly at descriptions of current class, thirdly at roles of current class, fourthly at ancestors of current class, and fifthly at imported descriptions (ones which have been imported here) of current class, if any.

=head2 smp_find_share_by_name

 $meta -> smp_find_share_by_name( $name );

C<$name> is a string.

Finds and returns C<CodeRef>, or C<undef> if nothing is found.

Looks firstly at current class, secondly at its roles, thirdly at its ancestors and fourthly at imported shares (ones which have been imported here) of current class, if any.

=head2 smp_find_share_import_spec_by_name

 $meta -> smp_find_share_import_spec_by_name( $name );

C<$name> is a string.

=head2 smp_get_all_aliases

 $meta -> smp_get_all_aliases();

=head2 smp_get_all_aliases_names

 $meta -> smp_get_all_aliases_names();

=head2 smp_get_all_descriptions

 $meta -> smp_get_all_descriptions();

=head2 smp_get_all_descriptions_names

 $meta -> smp_get_all_descriptions_names();

=head2 smp_get_all_imported_descriptions

 $meta -> smp_get_all_imported_descriptions();

=head2 smp_get_all_imported_descriptions_names

 $meta -> smp_get_all_imported_descriptions_names();

=head2 smp_get_all_imported_shares

 $meta -> smp_get_all_imported_shares();

=head2 smp_get_all_imported_shares_names

 $meta -> smp_get_all_imported_shares_names();

=head2 smp_get_all_shares

 $meta -> smp_get_all_shares();

=head2 smp_get_all_shares_names

 $meta -> smp_get_all_shares_names();

=head2 smp_uniq_aliases

 $meta -> smp_uniq_aliases();

=head2 smp_uniq_descriptions

 $meta -> smp_uniq_descriptions();

=head2 smp_uniq_shares

 $meta -> smp_uniq_shares();

=cut

