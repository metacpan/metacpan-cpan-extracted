package POOF;

use 5.007;
use strict;
use warnings;

use B::Deparse;
use Attribute::Handlers;
use Scalar::Util qw(blessed refaddr);
use Carp qw(croak confess cluck);
use Class::ISA;


use POOF::Properties;
use POOF::DataType;

our $VERSION = '1.4';
our $TRACE = 0;
our $RAISE_EXCEPTION = 'trap';


#-------------------------------------------------------------------------------
use constant PROPERTIES      => { };
use constant PROPERTYINDEX   => { };
use constant METHODS         => { };
use constant GROUPS          => { };
use constant PROPBACKREF     => { };
use constant PROPBACKDOOR    => { };
use constant CLASSES         => { };
use constant METHODDISPATCH  => { };
use constant ENCFQCLASSNAMES => { };
use constant PROCESSEDFILES  => { };


#-------------------------------------------------------------------------------
# access levels
use constant ACCESSLEVEL =>
{
    'Private'   => 0,
    'Protected' => 1,
    'Public'    => 2,
};

#-------------------------------------------------------------------------------
sub new
{
    my $class = shift;
    my %args = @_;
    
    confess "This class cannot be instantiated as a stand along object, it must be inherited instead"
        if $class eq 'POOF';
    
    # define main constructor property definition array
    my @properties = _processParentProperties($class,{});
    
    # deal with self
    foreach my $property (@{ +PROPERTIES->{ $class } })
    {
        if (exists $property->{'name'})
        {
            # add to Properties.pm constructor args
            push(@properties,{
                'class'   => $class,
                'name'    => $property->{'name'},
                'access'  => $property->{'data'}->{'access'},
                'virtual' => $property->{'data'}->{'virtual'},
                'data'    => POOF::DataType->new($property->{'data'}),
                'datadef' => $property->{'data'}
            });
        }
    }
    
    my $obj;
    tie %{$obj}, 'POOF::Properties', \@properties, $class, \&pErrors, \+GROUPS, \+PROPBACKREF, @_;
    bless $obj,$class;
    
    $obj->{'___refobj___'} = $obj;
    
    $RAISE_EXCEPTION = $args{'RaiseException'}
        if exists $args{'RaiseException'} && defined $args{'RaiseException'};
        
    $obj->_init( @_ );

    return $obj;
}

sub _processParentProperties
{
    my $class = shift;
    my $seen = shift;
    my @properties = @_;
    
    # deal with parents
    foreach my $parent (reverse Class::ISA::super_path($class))
    {
        next if $seen->{$parent}++;
        
        # process it's parents first
        @properties = _processParentProperties($parent,$seen,@properties)
            if (exists +PROPERTIES->{ $parent } && $parent ne 'POOF');
        
        # skip any non-defined parent
        next unless exists +PROPERTIES->{ $parent };
        
        # deal with each parent property
        foreach my $property (@{ +PROPERTIES->{ $parent } })
        {
            if (exists $property->{'name'})
            {
                # add to Properties.pm constructor args
                push(@properties,{
                    'class'   => $parent,
                    'name'    => $property->{'name'},
                    'access'  => $property->{'data'}->{'access'},
                    'virtual' => $property->{'data'}->{'virtual'},
                    'data'    => POOF::DataType->new($property->{'data'}),
                    'datadef' => $property->{'data'}
                });
            }
        }
    }
    
    return (@properties);
}

sub _init
{
    my $obj = shift;
    my %args = @_;
    return (@_);
}


#-------------------------------------------------------------------------------
# Error handling

my $ERRORS;
sub pErrors
{
    my $obj = shift;
    my ($k,$e) = @_;
    
    $e->{'description'} = "$e->{'description'}"
        if ref($e);
    
    return
        @_ == 0
            ? scalar keys %{$ERRORS->{ refaddr($obj) }}
            : @_ == 1
                ? delete $ERRORS->{ refaddr($obj) }->{ $k }
                : @_ == 2
                    ? $obj->_AddError($k,$e) 
                    : undef;
}

sub pGetErrors
{
    my $obj = shift;
    return
        ref $ERRORS->{ refaddr($obj) }
            ? $ERRORS->{ refaddr($obj) }
            : { };  
}

sub pAllErrors
{
    my ($obj) = @_;
    return scalar(keys %{$obj->pGetAllErrors});
}

sub pGetAllErrors
{
    my ($obj,$parent) = @_;
    my $errors = {};

    $parent =
        $parent
            ? "$parent-"
            : '';
    
    if ($obj->_Relationship(ref($obj),'POOF::Collection') =~ /^(?:self|child)$/)
    {
        for(my $i=0; $i<=$#{$obj}; $i++)
        {
            # skip non initialized elements of collection
            next unless exists $obj->[$i];
            if ($obj->_Relationship(ref($obj->[$i]),'POOF') =~ /^(?:self|child)$/)
            {
                my $error = $obj->[$i]->pGetAllErrors("$parent$i");
                %{$errors} = (%{$errors},%{$error})
                    if $error;
            }
        }
    }
    else
    {
        foreach my $prop (@{+PROPERTIES->{ ref($obj) }})
        {
            if ($obj->_Relationship(ref($obj->{$prop->{'name'}}),'POOF') =~ /^(?:self|child)$/)
            {
                my $error = $obj->{$prop->{'name'}}->pGetAllErrors("$parent$prop->{'name'}");
                %{$errors} = (%{$errors},%{$error})
                    if $error;
            }
        }
    }
    
    my $myErrors = $obj->pGetErrors;
    map { $errors->{"$parent$_"} = $myErrors->{$_} } keys %{$myErrors};
    return $errors;
}

sub _AddError
{
    my ($obj,$k,$e) = @_;
    unless ($RAISE_EXCEPTION eq 'trap')
    {
        my $error_string = "\nException for " . ref($obj) . "->{'$k'}\n" . "-"x50 . "\n"
            . "\n\tcode = $e->{'code'}"
            . "\n\tvalue = " . (defined $e->{'value'} ? $e->{'value'} : 'undef')
            . "\n\tdescription = $e->{'description'}";
            
        if ($RAISE_EXCEPTION eq 'warn')
        {
            warn $error_string;
        }
        elsif($RAISE_EXCEPTION eq 'print')
        {
            print $error_string;
        }
        elsif($RAISE_EXCEPTION eq 'cluck')
        {
            cluck $error_string ."\n\tstack = ";
        }
        elsif($RAISE_EXCEPTION eq 'confess')
        {
            confess $error_string ."\n\tstack = ";
        }
        elsif($RAISE_EXCEPTION eq 'croak')
        {
            croak $error_string;
        }
        elsif($RAISE_EXCEPTION eq 'die')
        {
            die $error_string;
        }
    }
    
    return $ERRORS->{ refaddr($obj) }->{ $k } = $e;
}

sub pRaiseException
{
    my ($obj,$val) = @_;
    return
        defined $val
            ? $RAISE_EXCEPTION = $val
            : $RAISE_EXCEPTION;
}

#-------------------------------------------------------------------------------
# Group operations

sub pGetPropertiesOfGroups
{
    my $obj = shift;
    my %props;
    @props{ $obj->pGetNamesOfGroup(@_) } = $obj->pGetValuesOfGroup(@_);
    return (%props);
}

sub pGetGroups
{
    my ($obj) = @_;
    return (keys %{ +GROUPS->{ ref $obj } });
}

sub pGetNamesOfGroup
{
    my ($obj,$group) = @_;
    
    return
        defined $group && exists +GROUPS->{ ref $obj }->{ $group }
            ? (@{ +GROUPS->{ ref $obj }->{ $group } })
            : (); 
}

sub pGroup
{
    my ($obj,$group) = @_;
    return $obj->pGetNamesOfGroup($group);
}

sub pGroupEncoded
{
    my ($obj,$group) = @_;
    return (map { $obj->_encodeFullyQualifyClassName . '-' . $_  }  $obj->pGetNamesOfGroup($group));
}

sub pPropertyNamesEncoded
{
    my ($obj,$refObj,@names) = @_;
    my $class = ref $refObj;
    return (map { $obj->_encodeFullyQualifyClassName($refObj) . '-' . $_  }  @names );
}

sub pGetValuesOfGroup
{
    my ($obj,$group) = @_;
    return
        defined $group && $obj->pGetNamesOfGroup($group)
            ? (@{$obj}{ $obj->pGetNamesOfGroup($group) })  
            : ();
}

sub pValidGroupName
{
    my $obj = ref $_[0] ? +shift : undef;
    my ($name) = @_;
    return
        $name !~ /^\s*$/  
            ? 1
            : 0; 
}

#-------------------------------------------------------------------------------


sub pSetPropertyDeeply
{
    my ($obj,$ref,$val,@path) = @_;
    my $level = shift @path;

    if (@path)
    {
        # look ahead to see if this is a collection
        if (ref($ref->{$level}) && $obj->_Relationship($ref->{$level},'POOF::Collection') =~ /^(?:self|child)$/o )
        {
            # it's a collection
            $obj->pSetPropertyDeeply($ref->{$level}->[ shift @path ],$val,@path);
        }
        else
        {
            # no it's not
            $obj->pSetPropertyDeeply($ref->{$level},$val,@path) 
        }
    }
    else
    {
        $ref->{$level} = $val;
    }
}

sub pGetPropertyDeeply
{
    my ($obj,$ref,@path) = @_;
    my $level = shift @path;
    return
        scalar (@path)
            ? ref($ref) eq 'ARRAY' 
                ? $obj->pGetPropertyDeeply($ref->[$level],@path)  
                : $obj->pGetPropertyDeeply($ref->{$level},@path)  
            : ref($ref) eq 'ARRAY'  
                ? $ref->[$level]
                : $ref->{$level};   
}

sub pInstantiate
{
    my ($obj,$prop) = @_;
    return
        $obj->pPropertyDefinition($prop)->{'otype'}->new 
        (
            $obj->pGetPropertiesOfGroups('Application'),
            RaiseException => $POOF::RAISE_EXCEPTION
        );
}

sub pReInstantiateSelf
{ 
    my ($obj,%args) = @_;
    return
        ref($obj)->new(
            $obj->pGetPropertiesOfGroups('Application'),
            %args
        );
}

#-------------------------------------------------------------------------------
# property definitions

sub pPropertyEnumOptions
{
    my ($obj,$propName) = @_;
    confess "There are no properties associated with " . ref($obj)
        unless exists +PROPBACKREF->{ ref($obj) };
    return +PROPBACKREF->{ ref($obj) }->EnumOptions($propName);
}

sub pPropertyDefinition
{
    my ($obj,$propName) = @_;
    confess "There are no properties associated with " . ref($obj)
        unless exists +PROPBACKREF->{ ref($obj) };
    
    return +PROPBACKREF->{ ref($obj) }->Definition($propName);
}

#-------------------------------------------------------------------------------
our $AUTOLOAD;
sub AUTOLOAD
{
        my $obj = shift;
    
        my $name = $AUTOLOAD;
        $name =~ s/.*://;   # strip fully-qualified portion
    
    my $super =
        $AUTOLOAD =~ /\:SUPER\:/o
            ? 1
            : 0;
            
    my $class = ref($obj) || confess "$obj is not an object";

    # TDB: handle super correctly, if the parent does not have the method
    # then try his parent and so on until we hit the top, if no method
    # is found then throw and exeption.
        my $package =
        $super
            ? shift @{[ Class::ISA::super_path( $class ) ]}  
            : $class;
            
    # just return undef if we are dealing with built in methods like DESTROY
    return if $name eq 'DESTROY';

    if ($TRACE)
    {
        no warnings;
        warn qq|$AUTOLOAD for ($package) called from | . (caller(0))[0] . "\n";
        warn qq|$AUTOLOAD for ($package) called from | . (caller(1))[0] . "\n";
        warn qq|$AUTOLOAD for ($package) called from | . (caller(2))[0] . "\n";
        warn qq|$AUTOLOAD for ($package) called from | . (caller(3))[0] . "\n";
        warn qq|$AUTOLOAD for ($package) called from | . (caller(4))[0] . "\n";
        warn "\twith " . scalar(@_) . " parameters\n";
    }
    
    
    # make sure we apply the inheritance rules the first time a class is used.
    $obj->_BuildMethodDispatch( $package )
        unless exists +METHODDISPATCH->{ $package };
    
    confess "$name method does not exist in class $package"
        unless (
            exists +METHODDISPATCH->{ $package }->{ $name }
            and exists +METHODDISPATCH->{ $package }->{ $name }->{'code'}
        );
        
    my $method = +METHODDISPATCH->{ $package }->{ $name }->{'code'};
    my $access = +METHODDISPATCH->{ $package }->{ $name }->{'access'};
 
    $access = 
        exists ACCESSLEVEL->{ $access }
            ? ACCESSLEVEL->{ $access }
            : ACCESSLEVEL->{ 'Public' };
        
    my $context = $obj->_AccessContext;

    confess "Illegal access of method $name"
        unless $access >= $context;
                      
    return &{$method}($obj,@_);
}


sub _BuildMethodDispatch
{
    my $obj = shift;
    my $package = shift;
    
    # get all parents
    my @parents = Class::ISA::super_path($package);
    
    # go through each class on the chain
    foreach my $parent (reverse @parents)
    {
        # non-defined parent will simply get and empty hash
        # and we'll skip to the next parent
        unless (exists +METHODS->{ $parent })
        {
            +METHODDISPATCH->{ $parent } = { };
            next;
        }
        
        # deal with each parent methods
        foreach my $name (keys %{ +METHODS->{ $parent } })
        {
            my $method = +METHODS->{ $parent }->{ $name };
            # skip any private property since they are not accessible
            # from this context, they are only accessible from the class in
            # which they are defined.
            next if $method->{'access'} eq 'Private';
            
            # croak if a method is redefined and it's not marked at virtual
            confess "A non-virtual $name has been redefined in $parent"
                if (exists +METHODDISPATCH->{ $package }->{ $name }
                    and +METHODDISPATCH->{ $package }->{ $name }->{'virtual'} != 1);
            
            # add method to dispatch table
            +METHODDISPATCH->{ $package }->{ $name } = $method;
        }
    }
    
    # deal with each method in this package
    foreach my $name (keys %{ +METHODS->{ $package } })
    {
        my $method = +METHODS->{ $package }->{ $name };
        
        # croak if a method is redefined and it's not marked at virtual
        confess "A non-virtual $name has been redefined in $package"
            if (exists +METHODDISPATCH->{ $package }->{ $name }
                and +METHODDISPATCH->{ $package }->{ $name }->{'virtual'} != 1);
        
        # add method to dispatch table
        +METHODDISPATCH->{ $package }->{ $name } = $method;
    }
}


sub _AccessContext
{
    my ($obj) = @_;
    my $self = ref($obj);
    
    my ($caller) = (caller(1))[0];
    
    my $relationship = $obj->_Relationship($caller,$self);
        
    return
        $relationship eq 'self'
            ? 0                         # 'private' 
            : $relationship eq 'child'
                ? 1                     # 'protected'
                : $relationship eq 'parent'
                    ? 1                 # 'protected' This is wierd shit, but I'm too tired now to fix it.
                    : 2                     # 'public';  
}

sub _CallerContext
{
    my ($obj) = @_;
    $obj->Trace if $TRACE;
    return (caller(1))[0];
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


sub _DumpAccessContext
{
    my $obj  = shift;
    my %caller;

    for(2 .. 5)
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
        $obj->_DumpCaller(\%caller);
    }
}

sub _DumpCore
{
    my ($obj) = @_;
    
    #warn "Dumping Core\n";
    #warn "-"x50 . "\n";
    #warn "METHODS: ",Dumper( +METHODDISPATCH), "\n";
    #warn "PROPERTYINDEX: ",Dumper( +PROPERTYINDEX), "\n";
    #warn "PROPERTIES: ",Dumper( +PROPERTIES), "\n";
}


#-------------------------------------------------------------------------------
# function attribute handlers

sub Method      : ATTR(CODE,BEGIN) { _processFile(@_) }
sub Property    : ATTR(CODE,BEGIN) { _processFile(@_) }
sub Private     : ATTR(CODE,BEGIN) { _processFile(@_) }
sub Protected   : ATTR(CODE,BEGIN) { _processFile(@_) }
sub Public      : ATTR(CODE,BEGIN) { _processFile(@_) }
sub Virtual     : ATTR(CODE,BEGIN) { _processFile(@_) }
sub Doc         : ATTR(CODE,BEGIN) { _processFile(@_) }


sub _processFile
{
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    
    return if $package =~ /POOF::TEMPORARYNAMESPACE/;
                        
    # convert package name to a path
    my ($filename) = map { exists $INC{"$_.pm"} ? $INC{"$_.pm"} : $0 } map { s!::!/!go; $_ } ($package);
    
    # just return if we already processed this file
    return if +PROCESSEDFILES->{$filename}++;

    my $source;
    my $exception;
    
    # read source from file and untaint it
    open(SOURCEFILE,$filename) || confess "Could not open $filename\n";
    {
        local $/ = undef;
        <SOURCEFILE> =~ /(.*)/ms;  # put untainted code in $1
        $source = $1;
    }
    close(SOURCEFILE);
    
    # let's rename the packages so we don't brack perl's inheritance stuff
    $source =~ s/^package\s+/package POOF::TEMPORARYNAMESPACE/g;
    
    # now let's evaluate the source using the same nasty string eval which is
    # the reason we have to jump through hoops here (caramba!).
    {
        # creating block to squelch perl's complaining
        no strict 'refs';
        no warnings 'redefine';
        eval $source;
        if($@)
        {
            $exception = $@;
            my ($error,$file) = split /\(eval \d+\)/, $exception;
            my ($replace,$line) = split /\] line /, $file;
            $exception = qq|$error [$filename]| . ($line ? " line $line" : $replace);
            die $exception;
        }
    }
    
    # split source into packages but keep the keyword package in each piece;
    my @packages = map { "package $_" } split(/^package\s+/,$source);
    
    # process each package one at a time
    foreach my $package (@packages)
    {
        next unless $package =~ m/^package\s+([^\s]+)\s*;/;
        my $tempclass = $1;
        my $class = $tempclass;
        
        $class =~ s/POOF::TEMPORARYNAMESPACE//g;
        
        # identify all properties and methods by steping through each line one at a time
        my @lines = split(/(?:\x0A|\x0D\x0A)/o,$package);
        foreach (@lines)
        {
            s/#.*$//;
            if(/\bsub\b\s*([^\s\{\(\:]+)\s*:\s*([^\{]+)\s*(\{|$)?/o)
            {
                
                chomp();
                my ($sub,$end) = ($1,$3 ? $3 : '');
                my %attrs = map { $_ => 1 } map { _trim($_) } split(/\s+/,$2);
                
                # classify into property or method
                if (exists $attrs{'Method'}) # process method
                {
                    # determine access
                    my $access = _determineAccess(%attrs);
                    # determine virtual
                    my $virtual = _determineVirtual(%attrs);
                        
                    # creating block to squelch perl's complaining
                    {
                        no strict 'refs';
                        no warnings 'redefine';
                        +METHODS->{ $class }->{ $sub }->{'code'} = \&{$class . '::' . $sub};
                    }
                    
                    # handle access
                    +METHODS->{ $class }->{ $sub }->{'access'} = $access;
                    
                    # handle virtual
                    +METHODS->{ $class }->{ $sub }->{'virtual'} = $virtual;
                    
                    ## handle documentation
                    #+METHODS->{ $class }->{ $sub }->{'doc'} = $doc;
                    
                }
                elsif(exists $attrs{'Property'}) # process property
                { 
                    
                    # determine access
                    my $access = _determineAccess(%attrs);
                    # determine virtual
                    my $virtual = _determineVirtual(%attrs);
                    
                    my $objdef;
                    # creating block to squelch perl's complaining
                    {
                        no strict 'refs';
                        no warnings 'redefine';
                        
                        $objdef = 
                            ref(&{$tempclass . '::' . $sub}) eq 'HASH'
                                ? &{$tempclass . '::' . $sub}
                                : { &{$tempclass . '::' . $sub} };
                    }
                    # this should return the hash that defines the property
                    %{$objdef} || confess "Properties must be defined by returning a hash ref with their attributes";
                    
                    unless (exists +PROPERTYINDEX->{ $class }->{ $sub })
                    {
                        push(@{ +PROPERTIES->{ $class } },{ 'name' => $sub });
                        +PROPERTYINDEX->{ $class }->{ $sub } = $#{ +PROPERTIES->{ $class } };
    
                        # handle groups
                        if (exists $objdef->{'groups'} && ref($objdef->{'groups'}) eq 'ARRAY')
                        {
                            foreach my $group (@{$objdef->{'groups'}})
                            {
                                #confess "Invalid group name ($group} used in property $sub"
                                #    unless ValidGroupName($group);
                            }
                        }
                    
                        +PROPERTIES->{ $class }->[ +PROPERTYINDEX->{ $class }->{ $sub } ]->{ 'data' } = { %{$objdef},access => $access, virtual => $virtual };
                    }
                }
                else
                {
                    # just skip, they might be using a non POOF function attribute or a Doc attribute
                    next;
                }
            }
            
        }
            
        {
            no strict 'refs';
            no warnings 'redefine';
            my $table = eval '\\%' . $class . '::';
            foreach my $item (keys %{$table})
            {
                if (exists +PROPERTYINDEX->{ $class }->{ $item } || exists +METHODS->{ $class }->{ $item })
                {
                    *{ $table->{$item} } = undef;
                }
            }
        }
    }
}

sub _determineAccess
{
    my %attrs = @_;
    # go from most secure to least secure
    return 
        exists $attrs{'Private'}
            ? 'Private'  
            : exists $attrs{'Protected'}
                ? 'Protected' 
                : exists $attrs{'Public'}
                    ? 'Public'
                    : 'Protected'; # will default to procted if nothing has been specified 
}

sub _determineVirtual
{
    my %attrs = @_;
    # we make a distinction between properties and methods as they have different defaults
    return
        exists $attrs{'Property'}
            ? exists $attrs{'Virtual'}
                ? 1
                : exists $attrs{'NonVirtual'}
                    ? 0
                    : 0 # Properties default to Virtual
            : exists $attrs{'Method'}
                ? exists $attrs{'Virtual'}
                    ? 1
                    : 0 # Methods default to NonVirtual
                : 0;
}

sub _trim
{
    my ($dat) = @_;
    $dat =~ s/^\s*//go;
    $dat =~ s/\s*$//go;
    return $dat;
}

sub log2file
{
    open(FH,">>/tmp/debug_log") || die "Could not open debug_log to write\n($!)\n";
    print FH join(' ', @_) . "\n";
    close(FH)
}




1;
__END__

=head1 NAME

POOF - Perl extension that provides stronger typing, encapsulation and inheritance.

=head1 SYNOPSIS

    package MyClass;
    
    use base qw(POOF);
    
    # class properties
    sub Name : Property Public
    {
        {
            'type' => 'string',
            'default' => '',
            'regex' => qr/^.{0,128}$/,
        }
    }
    
    sub Age : Property Public
    {
        {
            'type' => 'integer',
            'default' => 0,
            'min' => 0,
            'max' => 120,
        }
    }
    
    sub marritalStatus : Property Private
    {
        {
            'type' => 'string',
            'default' => 'single',
            'regex' => qr/^(?single|married)$/
            'ifilter' => sub
            {
                my $val = shift;
                return lc $val;
            }
        }
    }
    
    sub spouse : Property Private
    {
        {
            'type' => 'string',
            'default' => 'single',
            'regex' => qr/^.{0,64}$/,
            'ifilter' => sub
            {
                my $val = shift;
                return lc $val;
            }
        }
    }
    
    sub opinionAboutPerl6 : Property Protected
    {
        {
            'type' => 'string',
            'default' => 'I am so worried, I don\'t sleep at night.'
        }
    }
      
    # class methods
    sub MarritalStatus : Method Public
    {
        my ($obj,$requester) = @_;
        if ($requester eq 'nefarious looking stranger')
        {
            return 'non of your business';
        }
        else
        {
            return $obj->{'marritalStatus'}
        }
    }
    
    sub GetMarried : Method Public
    {
        my ($obj,$new_spouse) = @_;
        
        $obj->{'spouse'} = $new_spouse;
        
        if ($obj->pErrors)
        {
            my $errors = $obj->pGetErrors;
            if (exists $errors->{'spouse'})
            {
                die "Problems, the marrige is off!! $errors->{'spouse'}\n";
                return 0;
            }
        }
        else
        {
            $obj->{'marritalStatus'} = 'married';
            return 1;
        }
    }
    
    sub OpinionAboutPerl6 : Method Public Virtual
    {
        my ($obj) = @_;
        return "Oh, great, really looking forward to it. It's almost here :)";
    }
    
    sub RealPublicOpinionAboutPerl6 : Method Public
    {
        my ($obj) = @_;
        return $obj->OpinionAboutPerl6;
    }
  
    
=head1 DESCRIPTION

This module attempts to give Perl a more formal OO implementation framework.
Providing a distinction between class properties and methods with three levels
of access (Public, Protected and Private).  It also restricts method overriding
in children classes to those properties or methods marked as "Virtual", in which
case a child class can override the method but only from its own context.  As
far as the parent is concern the overridden method or property still behaves in
the expected way from its perspective.

Take the example above:

Any children of MyClass can override the method "OpinionAboutPerl6" as it is
marked "Virtual":
    
    
    # in child

    sub OpinionAboutPerl6 : Method Public
    {
        my ($obj) = @_;
        return "Dude, it's totally tubular!!";
    }
    

However if the public method "RealPublicOpinionAboutPerl6" it's called then it
would in turn call the "OpinionAboutPerl6" method as it was defined in MyClass,
because from the parents perspective the method never changed.  I believe this
is crucial behavior and it goes along with how the OO principles have been
implemented in other popular languages like Java, C# and C++.

=head1 Playing with objects as if they were pure Perl hashes

The order in which you defined your properties in the class is maintained. So you
can to slice assignments and group operations with these objects as if they where
an ordered hash.

For example:

Copying all properties and their values from $obj1 to $obj2

    %{$obj2} = ${$obj1};
    
    @$obj2{ keys %$obj1 } = @$obj1{ keys %$obj 1 };

Copying all properties and their values that belong to group 'SomeGroup' from
$obj1 to $obj2

    @$obj2{ $obj1->pGroup('SomeGroup') } = @$obj1{ $obj1->pGroup('SomeGroup') };
    
    %$obj2 = map { $_ => $obj1->{ $_ } } $obj1->pGroup('SomeGroup');

Copying all properties and their values that belong to groups 'SomeGroup1' and
'Somegroup2'

    %$obj2 = map { $_ => $obj1->{ $_ } } $obj1->pGroup('SomeGroup1','SomeGroup2');
    
Let's say that we have a hash '%args' which contains parameters from a form
submission and you only want to set those properties that belong to group 'FormStep1'
and disregards all other args.

    @$obj{ $obj->pGroup('FormStep1') } = @args{ $obj->pGroup('FormStep1') };
    
    # now we check for data validation errors
    
    if ($obj->pErrors)
    {
        warn "We have the following errors: ",Dumper($obj->pGetErrors),"\n";
        # now do something with your errors like rendering the form again and
        # showing the user the errors.
    }


=head1 Property declaration

Class properties are defined by use of the "Property" function attribute.
Properties like methods have three levels of access (see. Access Levels) which
are Public, Protected and Private.  In addition to the various access levels
properties can be marked as Virtual, which allows them to be overridden in
sub-clases and gives them visibility through the entire class hierarchy.

=head1 Property

The "Property" keyword is used as a function attribute to declare a class
property.  I<B<Property> and B<Method> are mutually exclusive and should never be
used on the same function.>

Sample usage:

The minimum requirement of a property is be declared with the B<Property>
function attribute and for it to return a valid hash ref describing at
least its basic type.  More about types in the B<type> sub-section.

    sub FirstName : Property
    {
        {
            'type' => 'string'
        }
    }

Here we combine the B<Property> attribute with the B<Public> access modified.
Note that order does not matter when combining POOF function attributes.

    sub Color : Public Property
    {
        {
            'type' => 'enum',
            'options' => [qw(red blue green)]
        }
    }
    
Here we combine the B<Property> attribute with the B<Protected> and B<Virtual>
modifiers.

    sub Height : Property Protected Virtual
    {
        {
            'type' => 'float',
            'min' => 0,
            'max' => 8,
        }
    }
    
WRONG: You should never combine B<Property> with B<Method>.

    sub Bad : Property Method
    {
        {
            'type' => 'boolean'
        }
    }

=head1 Property definition hash

Properties are declared by the B<Property> function attribute and defined by their
definition hash.  The definition has allows for various definitions such as I<type>,
I<default> value, I<min> value, etc.  See the section below for a list of
possible definitions.

=head2 type

As the name implies defines the type of the property.  POOF has several
built in basic types, additionally you can set type to be the namespace (package name)
of the object you intend to store in the property.


For example:

    # Property that will store a DBI object
    sub Dbh
    {
        {
            'type' => 'DBI::db'
        }
    }

If you defined the type to be a namespace (like above) and you try to store an
object other than 'DBI::db' and error code 101 will be generated.

Below is a list of built-in basic types currently supported by POOF:

=over

=over

=item B<string>

Basic string like in C++ and other strong typed languages. Defaults to ''.

=item B<integer>

Basic integer signed integer where the sign is optional with with up to 15
digits and must pass the /^-?[0-9]{1,15}$/ regex. Defaults to 0.

=item B<char>

Basic char as in a single character. Defaults to ''.


=item B<binary>

This will hold anything. Defaults to ''.

=item B<float>

Basic float and must pass /^(?:[0-9]{1,11}|[0-9]{0,11}\.[0-9]{1,11})$/
regex. Defaults to '0.0'.

=item B<boolean>

Basic boolean 1 or 0. Defaults to 0.

=item B<blob>

This will hold anything like the B<binary> type. Defaults to undef.

=item B<enum>

Basic enumerated type, its valid options are defined with the
additional B<options> definition.  See B<options>.


=item B<hash>

Basic Perl hash ref. Defaults to {}.


=item B<array>

Basic Perl array ref. Defaults to [].
    
=item B<code>

Basic Perl code ref. Defaults to undef.
    
=back

=back

=head2 regex

Regular expression that needs to return true for value to be considered valid.

The regular expression should be in the form of:

    sub Color : Property Public
    {
        {
            'type' => 'string',
            'regex' => qr/^(?:red|green|blue)$/i
        }
    }

The B<qr> operator allows the regex to be pre-compiled and you can specify additional
switches like in the case above B<i> for non-case sensitive. 
Data validation failure of B<regex> will result in error code 121.

=head2 null

Defines the property to be nullable and allows it to be set to undef. 
Data validation failure of B<null> will result in error code 111.

=head2 default

The default value this property should return if it has not be set. 

=head2 size

The size as in length or number of characters (Same as B<minsize>). 
Data validation failure of B<size> will result in error code 131.

=head2 minsize

The minimum size or length allowed. 
Data validation failure of B<minsize> will result in error code 132.

=head2 maxsize

The maximum size or length allowed. 
Data validation failure of B<maxsize> will result in error code 133.

=head2 min

The minimum numeric value allowed. 
Data validation failure of B<min> will result in error code 141.

=head2 max

The maximum numeric value allowed. 
Data validation failure of B<max> will result in error code 142.

=head2 format

A format to use on output as you would use in printf or sprintf.

=head2 groups

The optional list of groups the property belongs to.  Although it takes an array
ref for the list it is normally specified in-line as in the example below:

    sub Age : Property Public
    {
        {
            'type' => 'integer',
            'min' => 0,
            'max' => 120,
            'groups' => [qw(PersonalInfo Profile)]
        }
    }
    
In the above example the property "Age" belongs to two groups "PersonalInfo" and
"Profile" and would be return if either of the to groups are called.

For example:

    my @profile_prop_names = $obj->GetNamesOfGroup('PersonalInfo');
    my @personal_prop_names = $obj->GetNamesOfGroup('Profile');

=head2 options

This is used to define all valid elements or options for the enumerated typed
property.

For example:

    sub Relationship : Property Public
    {
        {
            'type' => 'enum',
            'options' => [qw(Parent Self Spouse Children)]
        }
    }

=head2 ifilter

ifilter is a callback hook in the form of code ref that executes when a property
is assigned a value and before we attempt to validate the data.  The code ref
can be an anonymous subroutine defined in-line or a a ref to a named sub-routine. 
The filter gets a reference to the object in which they exists along with the
value that is being set.  The value can be manipulated within the filter and/or
validated by calling die if one desires to reject the value before it's set.

Note that because you have a reference to the object you also have access to other
properties from the filter to both set and get, however you must be careful to no
create an infinite loop by setting or getting values to a property that calls the
same filter.

For example:

    sub FirstName : Property Public Virtual
    {
        {
            'type' => 'string',
            'ifilter' => sub
            {
                my ($obj,$val) = @_;
                if ($val)
                {
                    # remove end of line char if any
                    chomp($val);
                    # trim leading and trailing white spaces
                    $val =~ s/^\s*|\s*$//;
                    # make all chars lower case
                    $val = lc($val);
                    # make first char upper case
                    $val =~ s/^([a-z])/uc($1)/e;
                    # reject it if val contains profanity
                    die "Failed profanity filter"
                        if $obj->ContainsPropfanity($val);
                }
                return $val;
            }
        }
    }
    
Obviously the example above assumes with have a method "ContainsPropfanity" that
will check the contents of $val and returns true if profanity is detected.  See
the section on Errors and Exceptions handling for more information on data validation
violation and handling of die within filters.

=head2 ofilter

This is basically the same as the ifilter except it get executed when the someone
tries to get the value from the property.

For example:

    my $name = $obj->{'FirstName'};


=head1 Method declaration

See B<Method> below.

=head2 Method

Methods are declared using the B<Method> function attribute.  Subroutines marked
with the B<Method> attribute will be deleted from the symbol table right after
compilation and their access will be controlled by the framework.  All three access
modifiers (B<Public>, B<Protected> and B<Private>) work with methods as well as the
B<Virtual> modifier.  See Access Modifiers for more information.

For example:

    sub SayHello : Method Public
    {
        my ($obj) = @_;
        print "Hello world!";
    }

=head1 Access modifiers

These modifiers control access to both methods and properties.  POOF currently
supports B<Public>, B<Protected> and B<Private>.  Some additional modifiers are
in the works so stay tuned.

=head2 Public

Methods and Properties marked as B<Public> can be access by the defining class,
its children and the outside world.  This is very much how standard Perl subroutines
work, therefore using the function attribute B<Public> is merely a formalization.
Method and Properties not marked with any access modifiers will default to B<Public>

=head2 Protected

Methods and Properties marked as B<Protected> will be accessible by the defining
class and its decendants (children, grand children, etc.) but not from outside
the class hierarchy.  

=head2 Private

Methods and Properties marked as B<Private> will be accessible only by the defining
class.  In fact, you can define a B<Private> method in one class, inherit from that
class and define another B<Private> method in the child class and not have a conflict.
Each class will use its version of the method.  Very useful when you want to control
what gets inherited.

=head1 Other declarative modifiers

=head2 Virtual

By default POOF will not allow you override methods or properties in child classes,
only those methods or properties declared as B<Virtual> can be overriden, the only
exception is B<Private> methods or properties that are not inheritable thus really
private, but will alway be accesible by its definer class.

=head1 Utility Methods and Functions

POOF provides a series utility methods and functions listed below, all but B<new>
(the constructor) and B<_init> the instance initialization function are prefixed
with a "p" in order not to pollute your namespace too much.  This allows you to have
your own "Errors" method as the POOF one is called "pErrors" and so son...

Note: Currently some of these methods also exist in POOF without the "p" and I'm
working to removed then in a timely manner.

=head2 new

The standard Perl constructor, a bit of processing is done in the constructor so
you should not override it.  If you need to do things in the constructor override
the B<_init> method instead.  You've been warned :) 

=head2 _init

This is a safe place where you can do things right after the object has been
instantiated.  Things normally done here include processing constructor arguments,
setting of default values, etc..

    sub _init
    {
        my $obj = shift;
        # make sure we call super so it does its thing
        my %args = $obj->SUPER::_init(@_);
        
        # do something here ...
        
        # make sure we return %args to if some inherits from us
        # and they call super to get their args they get what its expected.
        return %args;
    }

=head2 pErrors

Returns and integer representing the number of errors or exceptions currently in
the exception tree.  Whenever data validation on a property fails an exception or
error is stored for the instance in question and the number of such errors can be
retrieved by calling this method.

For example:

file: ColorTest.pm

    package ColorTest;
    use base qw(POOF);
    sub Color : Property Public Virtual
    {
        {
            'type' => 'enum',
            'options' => [qw(red green blue)]
        }
    }
    1;
    

file: test.pl

    #!/usr/bin/perl -w
    
    use strict;
    use ColorTest;
    
    my $obj = ColorTest->new;
    $obj->{'Color'} = 'orange';
    print "We have " . $obj->pErrors . " error\n";
    
The above example should print "We have 1 error";

=head2 pGetErrors

Returns a hash indexed by the name of the property that generated the error,
an error code, a description string for the error and the offending value that
cause the error.

For example:

file: ColorTest.pm

    package ColorTest;
    use base qw(POOF);
    sub Color : Property Public Virtual
    {
        {
            'type' => 'enum',
            'options' => [qw(red green blue)]
        }
    }
    1;
    
file: test.pl

    #!/usr/bin/perl -w
    
    use strict;
    use ColorTest;
    use Data::Dumper;
    
    my $obj = ColorTest->new;
    $obj->{'Color'} = 'orange';
    print "Errors: ",Dumper($obj->pGetErrors);

    # this should print something like this:
    Errors: $VAR1 = {
        'Color' => {
            'value' => 'orange',
            'description' => 'Not a valid options for this enumerated property',
            'code' => 151
        }
    };

=head2 pGetAllErrors

Like B<pGetErrors> above this method returns errors with their property name, code
and description but it does so recursively across any contained objects.

For example:

class Car contains class engine stored in the Engine property.  
    
file: Car.pm

    package Car;
    
    use strict;
    use base qw(POOF);
    use Engine;
    
    sub _init
    {
        my $obj = shift;
        # make sure we call super so it does its thing
        my %args = $obj->SUPER::_init(@_);
        
        $obj->{'Engine'} = Engine->new;
        
        $obj->{'Engine'}->{'State'} = 'stoped';
        
        # make sure we return %args to if some inherits from us
        # and they call super to get their args they get what its expected.
        return %args;
    }
    
    sub Engine : Property Public
    {
        {
            'type' => 'Engine'
        }
    }
    1;
    
file: Engine.pm

    package Engine;
    
    use strict;
    use base qw(POOF);
    
    sub State : Property Public
    {
        {
            'type' => 'enum',
            'options' => ["running","stoped"],
        }
    }
    1;
    
file: test.pl

    #!/usr/bin/perl -w
    
    use strict;
    use Car;
    use Data::Dumper;
    
    my $car = Car->new;
    
    $car->{'Engine'}->{'State'} = 'please stop';
    
    print "Errors: ",Dumper($car->pGetAllErrors);
    
    # should print something like this:
    Errors: $VAR1 = {
        'Engine-State' => {
            'value' => 'please stop',
            'description' => 'Not a valid options for this enumerated property',
            'code' => 151
        }
    };  
    
Note: property names are encoded with a dash to depict the containment level.
In the example above "Engine-State" is "Engine" the name of the property containing
the object and "State" the name of the property containing the error condition.
    
=head2 pGetGroups

Returns a list of all the property groups defined.

    my @groupnames = $obj->pGetGroups;
    
Here we traverse and entire class and create a hash containing property names and
values based on their group membership.

    foreach my $group ($obj->pGetGroups )
    {
        $group_and_members->{ $group } = { $obj->pGetPropertiesOfGroup($group) };
    }
    
or short hand like this
    
    map { $group_and_members->{$_} = { $obj->pGetPropertiesOfGroup($_) } } $obj->pGetGroups;
    

=head2 pGetPropertiesOfGroups

Returns a hash indexed by the property names and containing the properties values.
B<Everything is always returned in the order it was defined. Even though the core
of the POOF object behaves like a hash the order is always maintained.>

on a class with properties that belong to a group called 'SomeGroup' and this group
has members 'prop1', 'prop2' and 'prop3';

    %prop_copy = $obj->pGetPropertiesOfGroups('SomeGroup');
    
same as
    
    @prop_copy{ $obj->pGroup('SomeGroup') } = @$obj{ $obj->pGroup('SomeGroup') };

same as

    @prop_copy{ qw(prop1 prop2 prop3) } = @$obj{ qw(prop1 prop2 prop3) };
    
same as
    
    @prop_copy{ $obj->pGetNamesOfGroup('SomeGroup') } = @$obj{ $obj->pGetValuesOfGroup('SomeGroup') };

same as
    
    @prop_copy{ $obj->pGroup('SomeGroup') } = @$obj{ $obj->pGetValuesOfGroup('SomeGroup') };

same as
    
    forech my $prop ($obj->pGroup('SomeGroup))
    {
        $prop_copy{$prop} = $obj->{$prop};
    }

=head2 pGetNamesOfGroup

Returns the names of the properties belonging to the specified group in the order
in which they were defined.

For example:

    @prop_names = $obj->pGetNamesOfGroup('somegroupname');
    
same as
    
    @prop_names = $obj->pGroup('somegroupname');

=head2 pGroup

Same as pGetNamesOfGroup.  I use this method quite often so I made a shortcut :).

=head2 pGroupEncoded

Same as B<pGetNamesOfGroup> but the names are encoded using the namespace of the
class defining the property.

For example:

in a class named 'MyClasses::ThisClass' with a property named 'MyProp' that
belongs to group 'CoolProperties'

    print $obj->pGetGroupEncoded('CoolProperties');
    
    # should print something like this:
    MyClass-ThisClass-MyProp
    
This is useful in some scenarios, more about this type of stuff some other time.

=head2 pPropertyNamesEncoded

Takes a in a reference of a POOF object and a list of property names and returns
a list of the names encoded as in B<pGroupEncoded>.

=head2 pGetValuesOfGroup

Takes in a group name and returns a list of the values of all the properties
that belong to that group.

For example:

    @$obj2{ $obj1->pGroup('SomeGroup) } = $obj1->pGetValuesOfGroup('SomeGroup');

=head2 pValidGroupName

Takes a group name and returns 1 if it's valid and 0 if it's not.

=head2 pSetPropertyDeeply

Takes in a reference to a POOF object, a value and a list of levels normally
property names. It will use traverse the object model recursively and set the
leaf node to the value.

For example:

    $obj->pSetPropertyDeeply($refObj,'stopped','Engine','State');

same as

    $refObj->{'Engine'}->{'State'} = 'stopped';

This method along with its counterpart below are useful for traversing complex
object structures without having to use eval when generating code automatically
and when using introspection.  The Encoder class uses them to take "-" encoded
properties from form fields to populate your application.  There are three other
POOF modules that I will publish very soon "POOF-Application-Simple",
"POOF-HTML-Form" and "POOF-Webservices" that make use of these facilities.

=head2 pGetPropertyDeeply

This the counterpart to B<pSetPropertyDeeply>, but it gets the value instead.

For example:

    $obj->pGetPropertyDeeply($refObj,'Engine','State');

same as

    my $value = $refObj->{'Engine'}->{'State'};

=head2 pIntantiate

Takes in a property name and returns an new instance of the property's contained
object.  Useful for traversing objects that contain other objects, currently used
by the Encoder class.

=head2 pReInstantitateSelf

Takes in an optional hash to use as constructor arguments and returns a new
instance of itself pre-populated with the args.

=head2 pPropertyEnumOptions

Takes in a property name and returns an array ref with their valid options.
It will blow up calling confess if you pass it a property name that does not
exist.

For example:

    $prop_options = $obj->pPropertyEnumOptions('SomeProp');

same as

    @prop_options = @{ $obj->pPropertyEnumOptions('SomeProp') };
    

=head2 pPropertyDefinition

Takes in a property name and returns the definition hash ref for this property.

    $prop_definition = $obj->pPropertyDefinition('SomeProp');

same as

    %prop_definition = %{ $obj->pPropertyDefinition('SomeProp') };

If you wanted a hash containing the definintions of all the props in class

    %prop_definitions = map { $_ => $obj->pPropertyDefinition($_) } keys %{$obj};

=head1 EXPORT

None.


=head1 TODO

Many, many things, but first we need to finished the documentation and tutorials
of the existing classes.  Beyond that better diagnostics is next on the list.

=head1 SEE ALSO

Although this framework is currently being used in production environments,
I cannot accept responsibility for any damages cause by this framework, use
only at your own risk.

Documentation for this module is a work in progress.  I hope to be able to
dedicate more time and created a more comprehensive set of docs in the near
future.  Anyone interested in helping with the documentation, please contact
me at bmillares@cpan.org.

=head1 Special Thank You

I'd would like to take this opportunity to thank my friends, Buddy Burden,
Alain Avakian, John Callender, Diane Xu, Matthew Silvera and Dave Trischuk for
their support and valuable input which has help shape the direction of this module.

You guys rock!

=head1 AUTHOR

Benny Millares <bmillares@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Benny Millares

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


