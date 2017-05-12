#
# DESCRIPTION
#   PerlORM - Object relational mapper (ORM) for Perl. PerlORM is Perl
#   library that implements object-relational mapping. Its features are
#   much similar to those of Java's Hibernate library, but interface is
#   much different and easier to use.
#
# AUTHOR
#   Alexey V. Akimov <akimov_alexey@sourceforge.net>
#
# COPYRIGHT
#   Copyright (C) 2005-2006 Alexey V. Akimov
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Lesser General Public
#   License as published by the Free Software Foundation; either
#   version 2.1 of the License, or (at your option) any later version.
#   
#   This library is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   Lesser General Public License for more details.
#   
#   You should have received a copy of the GNU Lesser General Public
#   License along with this library; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

package ORM::Metaprop;

$VERSION=0.81;

use Carp;
use ORM;
use ORM::Tjoin;
use base 'ORM::Expr';

my %CLASS2METACLASS = ();
my %METACLASS2CLASS = ();

##
## CONSTRUCTORS
## 

## use: $prop = $class->new( expr=>ORM::Expr );
##
sub new
{
    my $class = shift;
    my %arg   = @_;
    my $self;

    if( $class eq 'ORM::Metaprop' )
    {
        $self = $arg{expr};
    }
    elsif( $arg{expr} )
    {
        $self =
        {
            expr       => $arg{expr},
            tjoin      => $arg{expr}->_tjoin->copy,
            prop_class => $class->_metaclass2class( $class ),
        };

        bless $self, $class;
    }

    return $self;
}

## use: $prop = $class->_new
## (
##     prop       => STRING,
##     prop_class => STRING,
## )
##
## prop_class:
##  The class that 'prop' property belongs to.
##
## prop:
## 
##  prop              =~ ( '->' DIRECT_PROPERTY | '-<' REVERSE_PROPERTY )+
##  REVERSE_PROPERTY  =~ REFERRING_CLASS '.' CLASS_PROPERTY '.' ALIAS
## 
##  DIRECT_PROPERTY   - property of the target class
##  REVERSE_PROPERTY  - property of third class that refers to target class
##  REFERRING_CLASS   - class that refers to target class by one of its properties
##  CLASS_PROPERTY    - property name of the instance of the referring class
##  ALIAS             - alpha-numeric string, aliasing allows to use different 
##                      referring objects of the same type
##
sub _new
{
    my $class = shift;
    my %arg   = @_;
    my @prop  = $class->_parse_prop_str( str=>$arg{prop} );
    my $self;
    my $error;

    if( $prop[0]{type} eq '>' )
    {
        $self = $class->_new_flat( class=>$arg{prop_class}, prop=>$prop[0]{name} );
    }

    if( defined $self )
    {
        for( my $i=1; $i<@prop; $i++ )
        {
            if( $prop[$i]{type} eq '>' )
            {
                unless( $self->_expand( prop=>$prop[$i]{name} ) )
                {
                    $self = undef;
                    last;
                }
            }
            else
            {
                $self = undef;
                last;
            }
        }
    }

    return $self;
}

## use: $prop = $class->_new_flat
## (
##     class => STRING,
##     prop  => STRING||undef,
## )
##
## class:
##  The class that 'prop' property belongs to.
##
## prop:
##  Direct property of the class.
##  If this argument is omitted then 'id' is assumed.
##
sub _new_flat
{
    my $class = shift;
    my %arg   = @_;
    my $self;

    if( ! $arg{prop} || $arg{class}->_has_prop( $arg{prop} ) )
    {
        $self->{prop}           = $arg{prop};
        $self->{prop_class}     = $arg{prop} ? $arg{class}->_prop_class( $arg{prop} ) : $arg{class};
        $self->{prop_ref_class} = $arg{prop} ? $arg{class}->_prop_is_ref( $arg{prop} ) : $arg{class};
        $self->{last_tjoin}     = ORM::Tjoin->new( class=>$arg{class}, prop=>$arg{prop} );
        $self->{tjoin}          = $self->{last_tjoin};

        bless $self, $class;
        $self->_rebless;
    }
    else
    {
        croak "'$arg{prop}' is neither a property of '$arg{class}' nor described in '$class' or parents"
    }

    return $self;
}

sub _copy
{
    my $self = shift;
    my $copy;

    if( $self->_calculated )
    {
        $copy =
        {
            expr       => $self->{expr},
            tjoin      => $self->{tjoin}->copy,
            prop_class => $self->{prop_class},
        };
    }
    else
    {
        $copy =
        {
            incomplete     => $self->{incomplete},
            prop           => $self->{prop},
            tjoin          => $self->{tjoin}->copy,
            prop_class     => $self->{prop_class},
            prop_ref_class => $self->{prop_ref_class},
        };
        $copy->{last_tjoin} = $copy->{tjoin}->corresponding_node( $self->{tjoin} );
    }

    return bless $copy, ref $self;
}

##
## PROPERTIES
##

sub _prop
{
    my $self = shift;
    my $copy = $self->_copy;

    $copy->_expand( @_ );
    return $copy;
}

sub _rev
{
    my $self = shift;
    my $copy = $self->_copy;

    $copy->_rev_expand( @_ );
    return $copy;
}

sub _arb
{
    my $self = shift;
    my $copy = $self->_copy;

    $copy->_arb_expand( @_ );
    return $copy;
}

sub AUTOLOAD
{
    my $self = shift;

    if( ref $self )
    {
        $self->_prop( substr( $AUTOLOAD, rindex( $AUTOLOAD, '::' )+2 ), @_ );
    }
    else
    {
        croak "Undefined static method called: $AUTOLOAD";
    }
}

sub _calculated     { shift->{expr}; }
sub _tjoin          { shift->{tjoin}; }
sub _prop_ref_class { shift->{prop_ref_class}; }
sub _prop_class     { shift->{prop_class}; }

## use: $sql_str = $prop->_sql_str( tjoin => ORM::Tjoin )
##
sub _sql_str
{
    my $self = shift;
    my %arg  = @_;
    my $str;

    if( $self->_calculated )
    {
        $str = $self->_calculated->_sql_str( tjoin=>$arg{tjoin} );
    }
    else
    {
        my $node = $arg{tjoin}->corresponding_node( $self->{tjoin} );
        $str     = $node && $node->full_field_name( $self->{prop}||'id' );
    }

    return $str;
}

##
## METHODS
##

## use: $metaprop->_expand( STRING );
##
## Extends $metaprop meta-property to be 'prop' meta-property of $metaprop.
##
sub _expand
{
    my $self = shift;
    my $prop = shift;
    my %arg  = @_;

    if( $prop eq 'class' && $self->_prop_ref_class && $self->_prop_ref_class->_is_sealed )
    {
        my $const = ORM::Const->new( $self->_prop_ref_class );
        %{$self}  = %{$const};
        bless $self, ref $const;
    }
    else
    {
        if( !$self->{prop_ref_class} )
        {
            croak "Class '$self->{prop_class}' is not expandable";
        }
        elsif( !$self->{prop_ref_class}->_has_prop( $prop ) )
        {
            croak "Class '$self->{prop_ref_class}' has no property '$prop'";
        }
        else
        {
            if( $self->{prop} )
            {
                my $tjoin = ORM::Tjoin->new( class=>$self->{prop_ref_class}, prop=>$prop );
                $self->{last_tjoin}->link( $self->{prop} => $tjoin );
                $self->{last_tjoin} = $tjoin;
            }
            else
            {
                $self->{last_tjoin}->use_prop( $prop );
            }

            my $new_class;
            my $new_ref_class;

            if( $arg{cast} )
            {
                if( UNIVERSAL::isa( $arg{cast}, $self->{prop_ref_class}->_prop_class( $prop ) ) )
                {
                    $new_class     = $arg{cast};
                    $new_ref_class = $arg{cast};
                }
                else
                {
                    croak "Can't cast class '".$self->{prop_ref_class}->_prop_class( $prop )."' to '$arg{cast}'";
                }
            }
            else
            {
                $new_class     = $self->{prop_ref_class}->_prop_class( $prop );
                $new_ref_class = $self->{prop_ref_class}->_prop_is_ref( $prop );
            }

            $self->{prop}           = $prop;
            $self->{prop_class}     = $new_class;
            $self->{prop_ref_class} = $new_ref_class;

            $self->_rebless;
        }
    }
}

sub _rev_expand
{
    my $self      = shift;
    my $rev_class = shift;
    my $rev_prop  = shift;
    my $cond      = shift;

    if( !$self->{prop_ref_class} )
    {
        croak "Class '$self->{prop_class}' is not expandable";
    }
    elsif( !$self->{prop_ref_class}->_has_rev_ref( $rev_class, $rev_prop ) )
    {
        croak "There is no property '$rev_prop' of class '$rev_class' referring to '$self->{prop_class}'";
    }
    else
    {
        $self->_arb_expand( 'id' => $rev_class, $rev_prop, $cond );
    }
}

## use: $node->_arb_expand( $prop => $exp_class, $exp_prop, $additional_condition );
##
sub _arb_expand
{
    my $self      = shift;
    my $prop      = shift;
    my $exp_class = shift;
    my $exp_prop  = shift;
    my $cond      = shift;

    if( !$self->{prop_ref_class} )
    {
        croak "Class '$self->{prop_class}' is not expandable";
    }
    elsif( !$self->{prop_ref_class}->_has_prop( $prop ) )
    {
        croak "Class '$self->{prop_ref_class}' has no property '$prop'";
    }
    elsif( !$exp_class->_has_prop( $exp_prop ) )
    {
        croak "Target class '$exp_class' has no property '$exp_prop'";
    }
    else
    {
        if( $self->{prop} )
        {
            my $tjoin = ORM::Tjoin->new( class=>$self->{prop_ref_class} );
            $self->{last_tjoin}->link( $self->{prop} => $tjoin );
            $self->{last_tjoin} = $tjoin;
            $self->{prop} = undef;
        }

        my $tjoin = ORM::Tjoin->new( class=>$exp_class, left_prop=>$exp_prop, cond=>$cond );
        $self->{last_tjoin}->link( $prop => $tjoin );
        $self->{last_tjoin} = $tjoin;

        $self->{prop_class}     = $exp_class;
        $self->{prop_ref_class} = $exp_class;

        $self->_rebless;
    }
}

## use: @prop = $prop->_parse_prop_str( str=>STRING );
##
## Each element of resulting array is hash, containing fields:
##
##   type:  '>' - direct or '<' - reverse property
##   name:  name of the property
##   class: (only makes sence for reverse properties) referring class
##   alias: (only makes sence for reverse properties) alias
##
sub _parse_prop_str
{
    my $self  = shift;
    my %arg   = @_;
    my $str   = $arg{str};
    my @struct;

    ## Parse prop string
    if( substr( $str, 0, 1 ) eq '-' )
    {
        $str    = substr $str, 1;
        @struct = split /\-/, $str;
        for( my $i=0; $i<@struct; $i++ )
        {
            my %prop;

            %prop       = ();
            $prop{type} = substr $struct[$i], 0, 1;

            if( $prop{type} eq '>' )
            {
                $prop{name} = substr $struct[$i], 1;
            }
            elsif( $prop{type} eq '<' )
            {
                ( $prop{class}, $prop{name}, $prop{alias} ) =
                    split /\./, substr $struct[$i], 1;
            }

            $struct[$i] = \%prop;
        }
    }
    else
    {
        @struct = ( { type=>'>', name=>$str } );
    }

    return @struct;
}

sub _class2metaclass
{
    my $self  = shift;
    my $class = shift;
    my $meta;
    my $path;

    if( exists $CLASS2METACLASS{$class} )
    {
        $meta = $CLASS2METACLASS{$class};
    }
    else
    {
        $meta =  "ORM::Meta::$class";
        $path =  $meta.'.pm';
        $path =~ s(::)(/)g;

        unless( $INC{$path} || eval "require $meta" )
        {
            $meta = 'ORM::Metaprop';
        }

        $CLASS2METACLASS{$class} = $meta;
        $METACLASS2CLASS{$meta}  = $class;
    }

    return $meta;
}

sub _metaclass2class
{
    my $self = shift;
    my $meta = shift;
    my $class;
    my $path;

    if( exists $METACLASS2CLASS{$meta} )
    {
        $class = $METACLASS2CLASS{$meta};
    }
    else
    {
        $class =  substr $meta, 11;
        $path  =  $class.'.pm';
        $path  =~ s(::)(/)g;

        if( $INC{$path} || eval "require $class" )
        {
            $CLASS2METACLASS{$class} = $meta;
            $METACLASS2CLASS{$meta}  = $class;
        }
        else
        {
            croak "Can't autoload class '$class'";
        }
    }

    return $class;
}

sub _rebless
{
    my $self = shift;
    my $class;

    if( $self->{prop_ref_class} )
    {
        $class = $self->{prop_ref_class}->metaprop_class;
    }
    elsif( $self->{prop_class} )
    {
        $class = $self->_class2metaclass( $self->{prop_class} );
    }
    else
    {
        $class = 'ORM::Metaprop';
    }

    bless $self, $class;
}

sub DESTROY
{
}

1;
