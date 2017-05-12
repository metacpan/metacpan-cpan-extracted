package POOF::Properties::Array;

use 5.007;
use strict;
use warnings;

use Carp qw(croak confess);
use base qw(POOF::Properties);

use POOF::DataType;

our $VERSION = '1.0';

my %DEFINITION;

use constant ACCESSLEVEL =>
{
    'Private'        => 0,
    'Protected'      => 1,
    'Public'         => 2,
};

use constant PUBLIC => '@@__POOF::Properties::Public__@@';
use constant DUMMY => '@@__POOF::Properties::DUMMY__@@';

my $GROUPS;
my $REFOBJ;

our $DEBUG = 0;

# CONSTRUCTOR
sub TIEARRAY
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
    my ($obj,$def,$self,$exceptionHandlerRef,$propertiesRef,$propBackDoor) = @_;
    
    $obj->{'self'} =
        $self
            ? $self
            : ref($obj);
            
    $obj->{'exceptionHandler'} = $exceptionHandlerRef
        if $exceptionHandlerRef;
        
    $$propertiesRef->{ $obj->{'self'} } = $obj;

    # make sure all keys are lower case
    %{$obj->{'def'}} = map { lc($_) => $def->{ $_ } } keys %{$def};
    
    my $access =
        exists $obj->{'def'}->{'access'} && defined $obj->{'def'}->{'access'}
            ? $obj->{'def'}->{'access'}
            : '';
    
    $obj->{'def'}->{'access'} =
        $access
            ? exists +ACCESSLEVEL->{ $access } 
                ? +ACCESSLEVEL->{ $access }   
                : confess "Unkown access type: $access" 
            : $obj->{'def'}->{'name'} eq DUMMY
                ? +ACCESSLEVEL->{'Private'} 
                : +ACCESSLEVEL->{'Public'};
    

    $obj->CLEAR;
    
    return @_;
}

sub RefObj
{
    my ($obj,$ref) = @_;
    $obj->{'___refobj___'} = $ref;
}

#-------------------------------------------------------------------------------
# property definitions

sub Definition
{
    my $obj = +shift->_enforcement;
    #----------------------------------
    return $obj->{'def'};
}

#-------------------------------------------------------------------------------
# hash functionality bindings

sub CLEAR
{
    my $obj = +shift->_enforcement;
    #----------------------------------
    return $obj->{'ARRAY'} = [ ]; 
}

sub EXISTS
{
    my $obj = +shift->_enforcement;
    #----------------------------------
    return exists $obj->{'ARRAY'}->[ +shift ]; 
}

sub FETCH
{
    my $obj = +shift->_enforcement;
    #----------------------------------
    my ($i) = @_;
    $obj->STORE
    (
        $i,$obj->{'def'}->{'otype'}->new
        (
            %{$obj->{'def'}->{'args'}}
        )
    ) unless(exists $obj->{'ARRAY'}->[$i]);
    return $obj->{'ARRAY'}->[$i];
}

sub FETCHSIZE
{
    my $obj = +shift->_enforcement;
    #----------------------------------
    return scalar @{$obj->{'ARRAY'}};
}

sub DELETE
{
    my $obj = +shift->_enforcement;
    #----------------------------------
    return delete $obj->{'ARRAY'}->[ +shift ]; 
}

sub STORE
{
    my $obj = +shift->_enforcement;
    #----------------------------------
    my ($i,$v) = @_;
    
    # enforce maxsize
    if (defined $obj->{'def'}->{'maxsize'} && $obj->{'def'}->{'maxsize'})
    {
        if ($i + 1 > $obj->{'def'}->{'maxsize'})
        {
            # generate error
            &{$obj->{'exceptionHandler'}}
            (
                $obj->{'___refobj___'},
                $obj->{'def'}->{'name'},
                {
                    'code' => 133,
                    'description' => "maxsize test failed",
                    'value' => $v
                }
            ) if defined $obj->{'exceptionHandler'};
            return;
        }
    }
    
    # only allow store if $v is of the right class
    unless ($obj->_relationship($v,$obj->{'def'}->{'otype'}) =~ /^(?:self|child)$/o)
    {
        # generate error
        &{$obj->{'exceptionHandler'}}
        (
            $obj->{'___refobj___'},
            $obj->{'def'}->{'name'},
            {
                'code' => 173,
                'description' => "element index $i: is not of a valid type",
                'value' => $v
            }
        ) if defined $obj->{'exceptionHandler'};
        return;
    }
    
    return $obj->{'ARRAY'}->[ $i ] = $v;
}
  
sub STORESIZE
{
    my $obj = +shift->_enforcement;
    #----------------------------------
    my ($newsize) = @_;
    
    # enforce maxsize
    if (defined $obj->{'def'}->{'maxsize'} && $obj->{'def'}->{'maxsize'})
    {
        if ($newsize + 1 > $obj->{'def'}->{'maxsize'})
        {
            # generate error
            &{$obj->{'exceptionHandler'}}
            (
                $obj->{'___refobj___'},
                $obj->{'def'}->{'name'},
                {
                    'code' => 133,
                    'description' => "maxsize test failed",
                    'value' => ''
                }
            ) if defined $obj->{'exceptionHandler'};
            return;
        }
    }
    
    
    my $diff = $newsize - @{$obj->{'ARRAY'}};
    
    unless ($diff == 0)
    {
        return
            $diff > 0
                ? $obj->{'ARRAY'}->[ $diff .. $newsize ] = map { undef } ($diff .. $newsize) 
                : map { $obj->POP } ( 0 .. (scalar(@{$obj->{'ARRAY'}}) - $newsize) - 2 ); 
    }
    return;
}
  
sub PUSH
{
    my $obj = +shift->_enforcement;
    #----------------------------------
    return push(@{$obj->{'ARRAY'}},@_);
}
  
sub POP
{
    my $obj = +shift->_enforcement;
    #----------------------------------
    return pop @{+shift->_enforcement->{'ARRAY'}};
}

sub SHIFT
{
    my $obj = +shift->_enforcement;
    #----------------------------------
    return shift @{$obj->{'ARRAY'}};
}

sub UNSHIFT
{
    my $obj = +shift->_enforcement;
    #----------------------------------
    my @list = @_;
    my $size = scalar @list;
    
    # make room for our list
    @{$obj->{'ARRAY'}}[ $size .. $#{$obj->{'ARRAY'}} + $size ] = @{$obj->{'ARRAY'}};
      
    return map { $obj->STORE($_,$list[$_]) } (0 .. $#list);
}

sub SPLICE
{
    my $obj = +shift->_enforcement;
    #----------------------------------
    my $offset = shift || 0;
    my $length = shift || $obj->FETCHSIZE - $offset;
    my @list = ();

    if ( @_ )
    {
        tie @list, __PACKAGE__;
        @list   = @_;
    }
        
    return splice @{$obj->{'ARRAY'}}, $offset, $length, @list;
}

sub EXTEND
{
    my $obj = +shift->_enforcement;
    #----------------------------------
    return $obj->STORESIZE( +shift );
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

sub _classOrChild
{
    my ($obj,$level) = @_;
    my $caller = (caller($level || 2))[0];
    
    my $relationship = $obj->_relationship($caller,$obj);

    return
        $relationship eq 'self'
            ? 1                         # 'private'  
            : $relationship eq 'child'
                ? 1                     # 'protected' 
                : $relationship eq 'parent'
                    ? 1                 # parent has visibility into children
                    : 0                 # 'public';
    
}

sub _enforcement
{
    my $obj = shift;
    # enforce encapsulation
    confess "Access violation"
        unless $obj->{'def'}->{'access'} >= $obj->_callerContext(@_) || $obj->_classOrChild(@_);
    return $obj;
}
  

1;
__END__

=head1 NAME

POOF::Properties::Array - Utility class used by POOF::Collection.

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

