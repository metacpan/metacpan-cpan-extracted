package POOF::Properties;

use 5.007;
use strict;
use warnings;

use Carp qw(croak confess);
use Class::ISA;

use POOF::DataType;

our $VERSION = '1.0';

use constant ACCESSLEVEL =>
{
    'Private'        => 0,
    'Protected'      => 1,
    'Public'         => 2,
};

use constant PUBLIC => '@@__POOF::Properties::Public__@@';
use constant DUMMY => '@@__POOF::Properties::DUMMY__@@';

my $GROUPS;

our $DEBUG = 0;

# CONSTRUCTOR
sub TIEHASH
{
    my $class = shift;
    my $obj = {};
    bless $obj, $class;
    $obj->_init(@_);
    return $obj;
}

#-------------------------------------------------------------------------------
# Protected Methods go here

sub _init
{
    my ($obj,$args,$self,$exceptionHandlerRef,$groupHandlerRef,$propertiesRef) = @_;
    
    $obj->{'self'} =
        $self
            ? $self
            : ref($obj);
            
    $obj->{'exceptionHandler'} = $exceptionHandlerRef
        if $exceptionHandlerRef;
        
    $GROUPS = $groupHandlerRef;
    
    $$propertiesRef->{ $obj->{'self'} } = $obj;

    $obj->_initializeHash;

    # let's setup the property definitions
    my @defs =
        ref $args eq 'ARRAY'
            ? @{$args}
            : ref $args eq 'HASH'
                ? ($args)
                : undef;
    
    $obj->_buildDispatch(@defs);
    
    return $args;
}

sub _buildDispatch
{
    my $obj = shift;
    my @definitions = @_;
    
    # create the dispatch table for each class context
    my $class = $obj->{'self'};
    
    # ancestors don't have any visibility into the child
    # child can see ancestors public and protected properties
    # child can only override virtual properties of it's ancestors
    $obj->{'dispatch'}->{$class} = { };

    my $dispatch = $obj->{'dispatch'}->{$class};
    
    foreach my $def (@definitions)
    {
        # make sure all keys are lower case
        %{$def} = map { lc($_) => $def->{ $_ } } keys %{$def};
    
        # let's grab the stuff
        my ($name,$data,$datadef,$access,$definer,$virtual) = @$def{ qw(name data datadef access class virtual) };   
        
        # default to 0 on virtual
        $virtual ||= 0;    
            
        # make sure the values are lower case when applicable
        $access = ucfirst(lc($access));
        
        # if not access was defined we'll default to public
        $access =
            $access
                ? exists ACCESSLEVEL->{ $access } 
                    ? ACCESSLEVEL->{ $access }   
                    : confess "Unkown access type: $access" 
                : $name eq DUMMY
                    ? ACCESSLEVEL->{'Private'}
                    : ACCESSLEVEL->{'Public'};
                    
        # complain if there is no valid POOF::DataTypes object in the definition
        confess "There is an invalid data object in this definition\n"
            unless $obj->_relationship($data,'POOF::DataType') =~ /^(?:self|child)$/;
    
        # take care of illegal redefinitions of non-virtuals
        confess qq|Illegal attempt to redefined the non-virtual property "$name" in class "$dispatch->{ $name }->{'class'}" by "$definer"\n|
            if
            (
                exists $dispatch->{ $name }
                && $dispatch->{ $name }->{'virtual'} != 1
                && $dispatch->{ $name }->{'access'} != 0
            );
        
         # handle group stuff
        # first remove this property from all groups for this class
        foreach my $group (keys %{$$GROUPS->{ $class }})
        {
            @{$$GROUPS->{ $class }->{ $group }} =
            (
                grep
                {
                    $_ ne $name
                }
                @{$$GROUPS->{ $class }->{ $group }}
            );
        }
        
        foreach my $group (@{$datadef->{'groups'}})
        {
            $$GROUPS->{ $class }->{ $group } = []
                unless exists $$GROUPS->{ $class }->{ $group };
                
            # only add it the first time it's seen and this should keep the right order
            unless (grep { $name eq $_ } @{$$GROUPS->{ $class }->{ $group }})
            {
                push (@{$$GROUPS->{ $class }->{ $group }},$name)
            }
        }
        
        my ($i0,$i1,$i2) =
            $access == 0
                ? exists $dispatch->{ $definer }->{ $name }
                    ? @{$dispatch->{ $definer }->{ $name }}{ qw(index0 index1 index2) }
                    : ()
                : exists $dispatch->{ $name }
                    ? @{$dispatch->{ $name }}{ qw(index0 index1 index2) }
                    : ();
            
        # handling the private caller context (basically anything that made it this far
        # should be in the context as it should be accesible from self
        if ($i0)
        {
            # we are redefining a property
            $obj->{'key'}->[0]->[$i0] = $name;
            $obj->{'val'}->[0]->[$i0] = $data;
        }
        else
        {
            # new property
            push(@{ $obj->{'key'}->[0] }, $name);
            push(@{ $obj->{'val'}->[0] }, $data);
        
            # grabbing the index value to store with prop in dispatch
            $i0 = $#{ $obj->{'key'}->[0] };
        }
        
        # handling the protected caller context
        if ($access > 0)
        {
            if ($i1)
            {
                # we are redefining a property
                $obj->{'key'}->[1]->[$i1] = $name;
                $obj->{'val'}->[1]->[$i1] = $data;
            }
            else
            {
                # new property
                push(@{ $obj->{'key'}->[1] }, $name);
                push(@{ $obj->{'val'}->[1] }, $data);
            
                # grabbing the index value to store with prop in dispatch
                $i1 = $#{ $obj->{'key'}->[1] };
            }
        }
        
        # handling the public caller context
        if ($access > 1)
        {
            if ($i2)
            {
                # we are redefining a property
                $obj->{'key'}->[2]->[$i2] = $name;
                $obj->{'val'}->[2]->[$i2] = $data;
            }
            else
            {
                # new property
                push(@{ $obj->{'key'}->[2] }, $name);
                push(@{ $obj->{'val'}->[2] }, $data);
            
                # grabbing the index value to store with prop in dispatch
                $i2 = $#{ $obj->{'key'}->[2] };
            }
        }

        # finally we can add the property to this class context index
        if ($access == 0)
        {
            $obj->{'dispatch'}->{ $definer }->{ $name } = 
            {
                'class'   => $definer,
                'name'    => $name,
                'access'  => $access,
                'datadef' => $datadef,
                'data'    => $data,
                'virtual' => $virtual,
                'index0'  => $i0,
                'index1'  => $i1,
                'index2'  => $i2,
            };
        }
        else
        {
            $dispatch->{ $name } = 
            {
                'class'   => $definer,
                'name'    => $name,
                'access'  => $access,
                'datadef' => $datadef,
                'data'    => $data,
                'virtual' => $virtual,
                'index0'  => $i0,
                'index1'  => $i1,
                'index2'  => $i2,
            };
        }
    }
}

#-------------------------------------------------------------------------------
# property definitions
sub _dispatch
{
    my ($obj,$k) = @_;
    
    my $callerContext = $obj->_callerContext;
    my $caller = (caller(1))[0];
    my $self = $obj->{'self'};
    
    # ugly hack that needs to be fix
    defined $caller && $caller =~ s/POOF::TEMPORARYNAMESPACE//o;
    
    my $dispatch =
        $callerContext < 0
            ? # caller is parent.  Parent can access it's privates
              # plus public and protected from child 
              exists $obj->{'dispatch'}->{ $caller }->{ $k }
                ? # caller has a private with this name let's give it to it 
                  $obj->{'dispatch'}->{ $caller }
                : # caller does not have a private with this name let's see if
                  # we have a property with this name
                  exists $obj->{'dispatch'}->{ $self }->{ $k }
                    ? # let's see if the property is not private
                      $obj->{'dispatch'}->{ $self }->{ $k }->{'access'} > 0 
                        ? # property is not private let's give it to caller
                          $obj->{'dispatch'}->{ $self }
                        : # property is private so let's not give him anything
                          { }
                    : # self does not have what caller is looking for, just give
                      # back self context and we'll give access violation below
                      $obj->{'dispatch'}->{ $self }
            : # caller is not parent so normal rules apply, just get dispatch
              # for self and control access below
             $obj->{'dispatch'}->{ $self };
             
    # thow an exception if the property does not exist
    confess qq|Property "$k" does not exist|
        unless exists $dispatch->{ $k }; 
    
    # thow an exception if the caller cannot access the property
    confess "Access violation"
        unless $dispatch->{ $k }->{'access'} >= $callerContext;
        
    return $dispatch;
}



sub Definition
{
    my ($obj,$k) = @_;
    my $p = $obj->_dispatch($k)->{ $k };

    return 
    {
        'min'       => $p->{'data'}->min,
        'max'       => $p->{'data'}->max,
        'size'      => $p->{'data'}->size,
        'maxsize'   => $p->{'data'}->maxsize,
        'minsize'   => $p->{'data'}->minsize,
        'null'      => $p->{'data'}->null,
        'default'   => $p->{'data'}->default,
        'ptype'     => $p->{'data'}->ptype,
        'otype'     => $p->{'data'}->otype,
        'type'      => $p->{'data'}->type,
        'format'    => $p->{'data'}->format,
        'orm'       => $p->{'data'}->orm,
        'regex'     => $p->{'data'}->regex,
        'options'   => $p->{'data'}->type eq 'enum' ? $p->{'data'}->options : [],
    };
}


sub EnumOptions
{
    my ($obj,$k) = @_;
    my $p = $obj->_dispatch($k)->{ $k };
    
    return
        $p->{'data'}->type eq 'enum'
            ? $p->{'data'}->options
            : confess "Property is not of enum type and has no options";
    
}

#-------------------------------------------------------------------------------
# hash functionality bindings
sub CLEAR
{
#    my $obj = shift;
#    my $accessContext = $obj->_accessContext;
    
    # clean is simply going to undef the values of the
    # properties that are withing the scope of the access context
    #croak "Properties cannot be deleted at runtime";
}

sub EXISTS
{
    my ($obj,$k) = @_;
    
    my $callerContext = $obj->_callerContext;
    my $caller = (caller(0))[0];
    
    # ugly hack that needs to be fix
    defined $caller && $caller =~ s/POOF::TEMPORARYNAMESPACE//o; 
    
    my $dispatch =
        $callerContext < 0
            ? exists $obj->{'dispatch'}->{ $caller }->{ $k }   
                ? $obj->{'dispatch'}->{ $caller }    
                : { }    
            : $obj->{'dispatch'}->{ $obj->{'self'} }; 
            
    return
        exists $dispatch->{ $k } 
        && $dispatch->{ $k }->{'access'} >= $callerContext
            ? 1
            : undef; 
}


sub FETCH
{
    my ($obj,$k) = @_;
    my $p = $obj->_dispatch($k)->{ $k };
    
    my $d = $p->{'data'};
    my $v = $d->value;
    
    # let's apply the ifilter if defined
    if (defined $d->ofilter && ref($d->ofilter) eq 'CODE')
    {
        eval
        {
            $v = &{$d->ofilter}($obj->{'___refobj___'},$v);
        };
        if ($@)
        {
            # generate error
            &{$obj->{'exceptionHandler'}}
            (
                $obj->{'___refobj___'},
                $k,
                {
                    'code' => 172,
                    'description' => $@,
                    'value' => $v
                }
            ) if defined $obj->{'exceptionHandler'};
            return;
        }
    }
    
    return $v;
}

sub DELETE
{
    my ($obj,$k) = @_;
    confess "Properties cannot be deleted at runtime";
}

sub STORE
{
    my ($obj,$k,$v) = @_;
    
    if ($k eq '___refobj___')
    {
        $obj->{$k} = $v;
        return;
    };
    
    my $p = $obj->_dispatch($k)->{ $k };
    my $d = $p->{'data'};
    
    # let's apply the ifilter if defined
    if (defined $d->ifilter && ref $d->ifilter eq 'CODE')
    {
        eval
        {
            $v = &{$d->ifilter}($obj->{'___refobj___'},$v)
        };
        if ($@)
        {
            # generate error
            &{$obj->{'exceptionHandler'}}
            (
                $obj->{'___refobj___'},
                $k,
                {
                    'code' => 171,
                    'description' => $@,
                    'value' => $v
                }
            ) if defined $obj->{'exceptionHandler'};
            return;
        }
    }
    
    $d->value( $v );
    
    # handle any possible errors
    if ($d->pErrors)
    {
        &{$obj->{'exceptionHandler'}}($obj->{'___refobj___'},$k,$d->pGetErrors->{'value'})
            if defined $obj->{'exceptionHandler'};

        return;
    }
    else
    {
        &{$obj->{'exceptionHandler'}}($obj->{'___refobj___'},$k)
            if defined $obj->{'exceptionHandler'};
        
        return $v;
    }
}
  
sub FIRSTKEY
{
    my ($obj) = @_;
    my $caller = (caller(0))[0];
    my $callerContext = $obj->_callerContext(1);
    
    # ugly hack that needs to be fix
    defined $caller && $caller =~ s/POOF::TEMPORARYNAMESPACE//o;

    # the FIRSTKEY and NEXTKEY functions will return different stuff depending
    # on access.  If it is called in a private context than any key can be
    # returned, however if it is not in private context, then only the keys
    # to public properties can be returned.
        
    $obj->{'cnt'}->{ $caller } = 0;
    return $obj->_getNextKey($caller,$callerContext);
}

sub NEXTKEY
{
    my ($obj) = @_;
    my $k = $obj->_getNextKey((caller(0))[0],$obj->_callerContext(1));
    return unless defined $k;
    return $k;
}

sub _getNextKey
{
    my ($obj,$caller,$callerContext) = @_;
    my $access = $callerContext > 0 ? $callerContext : 0;
    
    # ugly hack that needs to be fix
    defined $caller && $caller =~ s/POOF::TEMPORARYNAMESPACE//o;
    
    my $k;
    while( $obj->{'cnt'}->{ $caller } <= $#{ $obj->{'key'}->[ $access ] } )
    {
        my $pk = $obj->{'key'}->[ $access ]->[ $obj->{'cnt'}->{ $caller }++ ];
        
        my $dispatch =
            $callerContext < 0
                ? exists $obj->{'dispatch'}->{ $caller }->{ $pk } 
                    ? $obj->{'dispatch'}->{ $caller } 
                    : { } 
                : $obj->{'dispatch'}->{ $obj->{'self'} };
        
        if (exists $dispatch->{ $pk } && $dispatch->{ $pk }->{'access'} >= $callerContext)
        {
            $k = $pk;
            last;
        }
    }
    
    return $k; 
}

  
#-------------------------------------------------------------------------------
# private Methods

sub Trace
{
    my $obj = shift;
    my %caller;
    @caller{ qw(
        0-package
        1-filename
        2-line
        3-subr
        4-has_args
        5-wantarray
        6-evaltext
        7-is_required
        8-hints
        9-bitmask
    ) } = caller(1);
    
    warn "$caller{'3-subr'}\n\t\tcalled from line [ $caller{'2-line'} ] in ($caller{'0-package'}) $caller{'1-filename'}\n";
}

sub _dumpAccessContext
{
    my $obj  = shift;
    my $start = 0;
    my %caller;

    for($start .. 5)
    {
        @caller{ qw(
            0-package
            1-filename
            2-line
            3-subr
            4-has_args
            5-wantarray
            6-evaltext
            7-is_required
            8-hints
            9-bitmask
        ) } = caller($_);

        last unless defined $caller{'0-package'};
        
        warn "\ncaller $_\n" . "-"x50 . "\n";
        $obj->_dumpCaller(\%caller);
    }
}

sub _dumpCaller
{
    my $obj = shift;
    my $caller = shift;
    warn "\n" . (
        join "\n", map
        {
            sprintf "\t%-15s = %-15s", $_,
                defined $caller->{$_}
                    ? $caller->{$_}
                    : 'undef'
        } sort keys %$caller) . "\n\n";
}

sub _callerContext
{
    my ($obj,$level) = @_;
    my $caller = (caller($level || 2))[0];
    
    # ugly hack that needs to be fix
    defined $caller && $caller =~ s/POOF::TEMPORARYNAMESPACE//o;
    
    my $relationship = $obj->_relationship($caller,$obj->{'self'});
    
    return
        $relationship eq 'self'
            ? 0                         # 'private' 
            : $relationship eq 'child'
                ? 1                     # 'protected'
                : $relationship eq 'parent'
                    ? -1                 # parent has not visibility into children
                    : 2                 # 'public';
                    
}

sub _relationship
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


sub _initializeHash
{
    my ($obj) = @_;
}
  

1;
__END__

=head1 NAME

POOF::Properties - Utility class used by POOF.

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
