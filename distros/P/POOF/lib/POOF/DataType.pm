package POOF::DataType;

use 5.007;
use strict;
use warnings;
use Carp;
use Class::ISA;

use Scalar::Util 'refaddr';

our $VERSION = '1.0';

#-------------------------------------------------------------------------------

# perl data types
use constant SCALAR_REF => 'SCALAR';
use constant ARRAY_REF  => 'ARRAY';
use constant HASH_REF   => 'HASH';
use constant SOCKET_REF => 'SOCKET';
use constant PIPE_REF   => 'PIPE';
use constant HANDLE_REF => 'HANDLE';
use constant GLOB_REF   => 'GLOB';
use constant CODE_REF   => 'CODE';

# Multi-threading
use constant THREADSAFE => 'threadsafe';

# data primitives
use constant DATATYPES =>
{
    integer =>
    {
        'type'    => 'integer',
        'regex'   => qr/^-?[0-9]{1,15}$/,
        'orm'     => 0,
        'null'    => 0,
        'default' => 0,
    },
    numeric =>
    {
        'type'    => 'string',
        'regex'   => qr/^[0-9]{1,255}$/,
        'orm'     => 0,
        'null'    => 0,
        'default' => 0,
    },
    string =>
    {
        'type'    => 'string',
        'orm'     => 0,
        'null'    => 0,
        'default' => '',
    },
    char =>
    {
        'type'    => 'string',
        'orm'     => 0,
        'null'    => 0,
        'size'    => 1,
        'default' => '',
    },
    binary =>
    {
        'type'    => 'string',
        'orm'     => 0,
        'null'    => 0,
        'default' => '',
    },
    double =>
    {
        'type'    => 'string',
        'orm'     => 0,
        'null'    => 0,
        'default' => '',
    },
    float =>
    {
        'type'    => 'string',
        'regex'   => qr/^(?:[0-9]{1,11}|[0-9]{0,11}\.[0-9]{1,11})$/,
        'orm'     => 0,
        'null'    => 0,
        'default' => '0.0',
    },
    long =>
    {
        'type'    => 'string',
        'orm'     => 0,
        'null'    => 0,
        'default' => '',
    },
    boolean =>
    {
        'type'    => 'integer',
        'orm'     => 0,
        'null'    => 0,
        'default' => 0,
		'size'    => 1,
		'min'     => 0,
		'max'     => 1,
    },
    blob =>
    {
        'type'    => 'blob',
        'orm'     => 0,
        'null'    => 1,
        'default' => undef,
    },
    hash =>
    {
        'type'    => 'hash',
        'orm'     => 0,
        'null'    => 0,
        'default' => {},
        'ptype'   => HASH_REF
    },
    array =>
    {
        'type'    => 'array',
        'orm'     => 0,
        'null'    => 0,
        'default' => [],
        'ptype'   => ARRAY_REF
    },
    enum =>
    {
        'type'    => 'string',
        'orm'     => 0,
        'null'    => 1,
        'default' => undef,
        'options'  => [],
    },
    code =>
    {
        'type'    => 'code',
        'orm'     => 0,
        'null'    => 1,
        'ptype'   => CODE_REF
    }
};

use constant PROPERTIES =>
{
	name 	  => DATATYPES->{'string'},
	otype 	  => DATATYPES->{'string'},
	ptype 	  => DATATYPES->{'string'},
	type 	  => DATATYPES->{'string'},
	regex 	  => DATATYPES->{'string'},
	orm 	  => DATATYPES->{'boolean'},
	null 	  => DATATYPES->{'boolean'},
	default   => DATATYPES->{'string'},
	size 	  => DATATYPES->{'integer'},
	minsize   => DATATYPES->{'integer'},
	maxsize   => DATATYPES->{'integer'},
	precision => DATATYPES->{'integer'},
	min 	  => DATATYPES->{'float'},
	max 	  => DATATYPES->{'float'},
	format    => DATATYPES->{'string'},
	options   => DATATYPES->{'array'},
	ifilter   => DATATYPES->{'code'},
	ofilter   => DATATYPES->{'code'},
};

# class encapsulation core
my $core;
my $errors;

sub new
{
    my ($class, $args) = @_;
    my $obj = { };
    bless $obj, $class;
    
    $obj->_init( $args );
    
    return $obj;
}

sub _objectInstanceID { refaddr( $_[0] ) }

sub _init
{
    my ($obj,$args) = @_;
	my $oid = $obj->_objectInstanceID;

    # If we are supplied a hashref as arguments to the constructions let's
    # populate the object's core hash with those properties
    if (ref($args) eq HASH_REF && exists $args->{'type'} && $args->{'type'})
    {
        # if a dtype property matches a default data type, let's prepopulate
        # with the default values and then apply the custom values supplied
        # with the args.
        (%{$core->{ $oid }}) =
            exists DATATYPES->{ $args->{'type'} }
                ? (defined $core->{ $oid } ? %{$core->{ $oid }} : (), %{ +DATATYPES->{ $args->{'type'} } }, %{$args}) 
                : (defined $core->{ $oid } ? %{$core->{ $oid }} : (), %{$args}); 
                
        return $args;
    }
    else
    {
        croak "Cowardly refused to instantiate a data type without a type definition\n";
    }
}

sub name 	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub value 	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub type 	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub ptype 	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub otype 	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub regex 	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub orm 	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub null 	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub default { @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub size 	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub minsize	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub maxsize	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub min 	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub max 	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub format 	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub options	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub ifilter	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }
sub ofilter	{ @_ == 2 ? $_[0]->Property( $_[1] ) : $_[0]->Property }


sub Property
{
	$_[0]->Private;
	my $obj = shift;
    my ($dat) = @_;
	
    # gathering info on how the caller was called
    my ($package,$method,$args,$wantarray) = (caller(1))[0,3,4,5];

	# extract property name or bail
	my $property =
		$method =~ /::([^:]+)$/o
			? $1
			: croak "Can't determine the property name\n";
			
    if (defined $wantarray)
    {
		$obj->_setValue($property,$dat) if @_;
		# we must get the property value
		return $obj->_getValue($property);
    }
    else
    {
		# property was called in void context, lets set its value if provided
		return $obj->_setValue($property,$dat);
    }
}

sub _setValue
{
	$_[0]->Private;
	my ($obj,$property,$dat) = @_;
	
	my $oid = $obj->_objectInstanceID;
	
	# let's validate against the property definition
	if ($obj->_valid($property,$dat))
	{
		$core->{ $oid }->{ $property } = $dat;
		delete $errors->{ $oid }->{ $property } if exists $errors->{ $oid }->{ $property };
		return $obj;
	}
	# if we made it here is bacause validation failed and we are
	# returning undef because we are not in a void context
	# the caller should check the $obj->pGetErrors to see the actual
	# error message.
	return;
}

sub _getValue
{
	$_[0]->Private;
	my ($obj,$property) = @_;
	my $oid = $obj->_objectInstanceID;
	
	return
		defined $core->{ $oid }->{ $property }
			? defined $core->{ $oid }->{'format'}      
				? sprintf $core->{ $oid }->{'format'}, $core->{ $oid }->{ $property }    
				: $core->{ $oid }->{ $property }    
			: defined $core->{ $oid }->{'format'}   
				? sprintf $core->{ $oid }->{'format'}, $core->{ $oid }->{'default'} 
				: $core->{ $oid }->{'default'};    
}

sub _valid
{
	$_[0]->Private;
	my ($obj,$property,$dat) = @_;
	my $oid = $obj->_objectInstanceID;

	my $definition =
		$property eq 'value' || $property eq 'default'
			? $core->{ $oid } 
			: PROPERTIES->{$property};
            


	# check null
	if (exists $definition->{'null'} && defined $definition->{'null'})
	{
		unless(defined $dat)
		{
			# if it can be null and it is null just return 1
			return 1 if $definition->{'null'} == 1;

			# otherwise, complain that is null and return undef
			$errors->{ $oid }->{ $property } = 
            {
                'code' => 111,
                'description' => 'NULL test failed',
                'value' => defined $dat ? $dat : undef
            };
			return;
		}
	}
	
    # check type
    if
	(
		(
			   exists $definition->{'type'}
			&& !(exists +DATATYPES->{ $definition->{'type'} })
			&& defined $dat
			&& $obj->_Relationship(ref($dat),$definition->{'type'}) !~ /^(?:self|child)$/
		)
		or
		(
			   exists $definition->{'ptype'}
			&& ref($dat) ne $definition->{'ptype'}
		)
	)
    {
        $errors->{ $oid }->{ $property } = 
        {
            'code' => 101,
            'description' => 'type test failed',
            'value' => defined $dat ? $dat : undef
        };
        return;
    }
    
    # check enum
    if (defined $dat && $definition->{'type'} eq 'enum')
    {
        if (grep { $_ eq $dat } @{$definition->{'options'}})
        {
            return 1;
        }
        else
        {
			$errors->{ $oid }->{ $property } = 
            {
                'code' => 151,
                'description' => 'Not a valid options for this enumerated property',
                'value' => defined $dat ? $dat : undef
            };
			return;
        }
    }
	
	# check regex
	if (exists $definition->{'regex'} && defined $definition->{'regex'})
	{
		unless($dat =~ $definition->{'regex'})
		{
			$errors->{ $oid }->{ $property } = 
            {
                'code' => 121,
                'description' => 'regex test failed',
                'value' => defined $dat ? $dat : undef
            };
			return;
		}
	}
	
	# check size
	if (exists $definition->{'size'} && defined $definition->{'size'})
	{
		unless(length($dat) <= ($definition->{'size'} || 0) )
		{
			$errors->{ $oid }->{ $property } = 
            {
                'code' => 131,
                'description' => 'size test failed',
                'value' => defined $dat ? $dat : undef
            };
			return;
		}
	}
	# check min size
	if (exists $definition->{'minsize'} && defined $definition->{'minsize'})
	{
		unless(length($dat) >= ($definition->{'minsize'} || 0) )
		{
			$errors->{ $oid }->{ $property } = 
            {
                'code' => 132,
                'description' => 'minsize test failed',
                'value' => defined $dat ? $dat : undef
            };
			return;
		}
	}
	
	# check max size
	if (exists $definition->{'maxsize'} && defined $definition->{'maxsize'})
	{
		unless(length($dat) <= ($definition->{'maxsize'} || 0) )
		{
			$errors->{ $oid }->{ $property } = 
            {
                'code' => 133,
                'description' => 'maxsize test failed',
                'value' => defined $dat ? $dat : undef
            };
			return;
		}
	}
	
	# check min
	if (exists $definition->{'min'} && defined $definition->{'min'})
	{
		unless($dat >= ($definition->{'min'} || 0) )
		{
			$errors->{ $oid }->{ $property } = 
            {
                'code' => 141,
                'description' => 'Min test failed',
                'value' => defined $dat ? $dat : undef
            };
			return;
		}
	}
	
	# check max
	if (exists $definition->{'max'} && defined $definition->{'max'})
	{
		unless($dat <= ($definition->{'max'} || 0) )
		{
			$errors->{ $oid }->{ $property } = 
            {
                'code' => 142,
                'description' => 'Max test failed',
                'value' => defined $dat ? $dat : undef
            };
			return;
		}
	}
    
	return 1;
}

sub Private
{	
	croak "Illegal access of a private method\n"
		unless ((caller(0))[0] eq ref($_[0])) && ((caller(1))[0] eq ref($_[0]));
}

sub pErrors
{
	my ($obj) = @_;
	return @{ [ keys %{$errors->{ $obj->_objectInstanceID }} ] } || 0;
}

sub pGetErrors
{
	my ($obj) = @_;
	return $errors->{ $obj->_objectInstanceID } || { };
}

sub _Relationship
{
    my $obj = shift;
    my ($class1,$class2) = map { $_ ? ref $_ ? ref $_ : $_ : '' } @_;

    return 'self' if $class1 eq $class2;

    my %family1 = map { $_ => 1 } Class::ISA::super_path( $class1 );
    my %family2 = map { $_ => 1 } Class::ISA::super_path( $class2 );

    return
        exists $family1{ $class2 }
            ? 'child'
            : exists $family2{ $class1 } 
                ? 'parent' 
                : 'unrelated';
}

# we must cleanup and force this instance to undef
sub DESTROY
{
	delete $core->{ $_[0]->_objectInstanceID };
}

1;
__END__

=head1 NAME

POOF::DataType - Provides data type validation and enforcement to POOF.

=head1 SYNOPSIS

It is not meant to be used directly.
  
=head1 SEE ALSO

POOF man page.

=head1 AUTHOR

Benny Millares <bmillares@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Benny Millares

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
