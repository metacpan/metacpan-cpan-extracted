#!/usr/bin/perl -s
##
## Persistence::Object::Simple -- Persistence For Perl5 Objects.  
##
## $Date: 1999/10/13 23:08:43 $
## $Revision: 0.47 $
## $State: Exp $
## $Author: root $
##
## Copyright (c) 1998, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

package Persistence::Object::Simple;
use Digest::MD5; 
use Data::Dumper;
use Carp;
use Fcntl;
use vars qw( $VERSION );

( $VERSION )  = '$Revision: 0.92 $' =~ /\s+(\d+\.\d+)\s+/;  #-- Module Version

my $DOPE      = "/tmp";     #-- The default Directory Of Persistent Entities
my $MAXTRIES  = 250;        #-- TTL counter for generating a unique file

sub dope {                  #-- Default DOPE access method

    my ( $self, $dope ) = @_;
    ${ $self->{ __DOPE } } = $dope if $dope;
    ${ $self->{ __DOPE } };

}
                                
sub new {                   #-- Constructor.  Creates and inits a P::O::S 
                            #-- object instance. Binds class data. 

    my ( $class, %args ) = @_; 
    my $self = {}; 
    my $fn = $args{ __Fn };     
    my $exists; 
	$args{ __Create } ||= "";
    if ($args{ __Create } and lc($args{ __Create }) eq "no") {
        $exists = 1; 
    }

    return undef if !(-e $fn) && $exists; 
    unless ( $fn ) { 
        $fn = $class->uniqfile ( $args{ __Dope } || $DOPE, $args{ __Random } );
        return undef unless $fn;
    }

    $self->{ __Fn } = $fn; 
    $self->{ __DOPE } = \$DOPE; 

    
    my $existing = $class->load ( __Fn => $fn );  
    $self = $existing if $existing;              
    for ( keys %args ) { $self->{ $_ } = $args{ $_ } }  

    bless $self, $class; 

} 

sub dumper {                #-- Returns the Data::Dumper object associated 
                            #-- with the instance
    my $self = shift; 

    $self->{ __Dumper } = new Data::Dumper ( [ $self ] ); 
    return $self->{ __Dumper }; 

}

sub commit {                #-- Commits the object to disk.  Works as a class
                            #-- method as well.  
    my ( $self, %args ) = @_; 
    my $class = ref $self || $self;
    my ( $d, $fn );
    $fn = $args{ __Fn }  || $self->{ __Fn }; 

    if ( ref $self ) { 
        $d = $self->{ __Dumper } || $self->dumper () ;
    } else {  # -- Whoa! It's a class method!
        $d = new Data::Dumper ( [ $args{ Data } ] ); 
    } 

    if ( $args{ __Dope } && $fn ) {  # -- change to a new dope
            $fn =~ s:.*/::; 
            $args{ __Dope } =~ s:/$::;
            $fn = $args{ __Dope } . "/$fn"; 
            croak "$fn exists. Can't overwrite." if -e $fn;
    }
 
    unless ( $fn ) {  # -- generate a uniq filename in the
        $args{ __Dope } = $DOPE unless $args{ __Dope }; # -- new dope
        $fn = $class->uniqfile ( $args{ __Dope } );
    }

   
    my $locked_fh = $self->{ __Lock }; 
    seek $locked_fh, 0, 0 if $locked_fh;
    my $fh; 

    # -- delete extra object data and class data-refs if this looks like 
    # -- an object. 
    if ( ref $self ) { 
        for ( keys %$self ) { delete $self->{ $_ } 
            if /^__(?:Dumper|DOPE|Fn|Lock|Create)/ }; 
    }

    unless ( $locked_fh ) { 
        # guard against disallowed characters in filename (basically those 
        # which might mess up the open() call)
        if (($fn) = ($fn =~ /^([^<>|+]+)$/)) {
            open C, ">$fn" || croak "Can't open $fn for writing."; 
            eval { flock C, 2 }; undef $@;
            $fh = *C{ IO }; 
        } else {
            die "Filename '$fn' contains inappropriate characters";
        }
    } 

    print { $locked_fh ? $locked_fh : $fh } 
	defined &Data::Dumper::Dumpxs ? $d->Dumpxs() : $d->Dump(); 
    close $fh if $fh; 

    if ( ref $self ) { 
        $self->{ __Fn } = $fn; 
        $self->{ __Lock } = $locked_fh if $locked_fh; 
    }

    return $fn; 

} 

sub load { 

    my ( $class, %args ) = @_; 

    return undef unless -e $args{ __Fn };
    
    open C, $args{ __Fn } || croak "Couldn't open $args{ __Fn }."; 
    eval { flock C, 2 }; undef $@;

    local $/ = undef; # slurp mode
    my $objectfile = <C>; 
    close C; 

    # untaint the input meaningfully
    if ($objectfile =~ /^(\$VAR1 = bless[^;]+;)$/s) {
        my $object = eval "$1";
        croak "$args{ __Fn } is corrupt. Object loading aborted." if $@; 

        $object->{ __Fn } = $args{ __Fn } if ref $object eq 'HASH';
        return $object; 
    } elsif ($objectfile =~ /^$/) {
        return undef;
    } else {
        croak "Tainted data from $args{__Fn} looks unsafe. Object loading aborted.";
    }
}

sub expire { 

    my ( $self ) = @_; 
    my $fn = $self->{ __Fn };
    return 1 if unlink $fn; 

} 

sub move { 

    my ( $self, %args ) = @_; 
    my   $class = ref $self; 

    $self->expire (); 
    $self->{ __Fn } = undef if $args{ __Fnalter };
    my $fn = $self->commit ( %args ); 

    my $moved = $class->new ( __Fn => $fn ); 
    $self = $moved; 

}

sub lock { 

    my ( $self ) = @_; 

    my $fn = $self->{ __Fn }; 
	$self->commit unless -e $fn; 
    open ( F, "+<$fn" ) || croak "Couldn't open $fn for locking. Commit first!"; 
    eval { flock F, 2 }; undef $@;
    $self->{ __Lock } = *F{ IO }; 

}

sub unlock { 

    my ( $self ) = @_; 
    my $F = $self->{ __Lock }; close $F; 
    undef $self->{ __Lock };
    
}

sub uniqfile { 

    my ( $class, $dir, $random ) = @_; 
    my $fn; my $counter; 

    do { 
        $fn = Digest::MD5::md5_hex( "@{[time]}.@{[int rand 2**8]}.$random" ); 
        ($fn) = ($fn =~ m!([^/<>|;]+)!);
        $counter++ ;
    }
    until sysopen ( C, "$dir/$fn" , O_RDWR|O_EXCL|O_CREAT ) 
        or $counter > $MAXTRIES;

    close C; 
    return undef if $counter > $MAXTRIES;
    return "$dir/$fn";
}

'True Value';

__END__



=head1 NAME

Persistence::Object::Simple - Object Persistence with Data::Dumper. 

=head1 SYNOPSIS

  use Persistence::Object::Simple; 
  my $perobj = new Persistence::Object::Simple ( __Fn   => $path ); 
  my $perobj = new Persistence::Object::Simple ( __Dope => $directory ); 
  my $perobj = new Persistence::Object; 
  my $perobj->commit (); 


=head1 DESCRIPTION

P::O::S provides persistence functionality to its objects.  Object definitions
are stored as stringified perl data structures, generated with Data::Dumper,
that are amenable to manual editing and external processing from outside the
class interface.

Persistence is achieved with a blessed hash container that holds the object
data. The container can store objects that employ non-hash structures as
well. See L<"Inheriting Persistence::Object::Simple">, L<"Class Methods"> and
the persistent list class example (examples/Plist.pm).

=head1 CONSTRUCTOR 

=over 4

=item B<new()>

Creates a new Persistent Object or retrieves an existing object definition.
Takes a hash argument with following possible keys:

=over 8

=item B<__Fn> 

Pathname of the file that contains the persistent object definition. __Fn is
treated as the object identifier and required at object retrieval.

=item B<__Dope> 

The Directory of Persistent Entities.  P::O::S generates a unique filename 
to store object data in the specified directory.  The object identifier is 
the complete pathname of the object's persistent image and is placed in the 
__Fn instance variable.  This argument is ignored when __Fn is provided.

=item B<__Create>

A boolean attribute that can either take a "Yes" or a "No" value. It informs
the method whether to create an object image if one doesn't already exist.
__Create is "yes" by default.

=item B<__Random> 

Random string used as input for computing the unique object name. This
should be used when unpredictable object names are required for security
reasons. The random string can be generated with Crypt::Random, a module
which provides cryptographically secure random numbers.

=back 

=back 

=over 4

=item 

When new() is called without any arguments it uses a unique file in the 
default DOPE, "/tmp", to store the object definition. The default DOPE
can be altered with the dope() method. 

 $po = new Persistence::Object::Simple 
       ( __Fn => "/tmp/codd/suse5.2.codd" ); 

 # -- generates a unique filename  in /tmp/codd
 $po  = new Persistence::Object::Simple
       ( __Dope => "/tmp/codd" );     
 print $po->{ __Fn }; 

 # -- generates a unique filename in defalt dope (/tmp)
 $po  = new Persistence::Object::Simple; 
 print $po->{ __Fn }; 

=back

=cut

=head1 METHODS

=over 4

=item B<commit()> 

Commits the object to disk.  Like new() it takes __Fn and __Dope arguments, 
but __Dope takes precedence.  When a __Dope is provided, the directory
portion of the object filename is ignored and the object is stored in the 
specified directory. 

    $perobj->commit (); 
    $perobj->commit (  __Fn   => $foo ); 
    $perobj->commit (  __Dope => $bar ); 



Commit() can also store non-object data refs. See L<"Class Methods">. 

=item B<expire()> 

Irrevocably destructs the object.  Removes the persistent entry from the DOPE. 

    $perobj->expire (); 

If you want to keep a backup of the object before destroying it, 
use commit() to store in a different location. Undefing $obj->{ __Fn } 
before writing to the disk will force commit() to store the object in a 
unique file in the specified DOPE. 

    $perobj->{ __Fn } = undef; 
    $perobj->commit ( __Dope => "/tmp/dead" ); 
    $perobj->expire (); 

=item B<move()> 

Moves the object to a different DOPE. 

    $perobj->move ( __Dope => "/some/place/else" ); 

Specifying __Fnalter attribute will force move() to drop the existing file
name and generate a new one in specified directory. This can be useful when
backing up objects that may have the same filename. 
    
    $perobj-> ( __Dope => 'queues/backup', 
                __Fnalter => 1 ); 

=item B<lock()> 

Gets an exclusive lock.  The owner of the lock can commit() without 
unlocking.  

    $perobj->lock (); 

=item  B<unlock()>

Releases the lock. 

    $perobj->unlock ();

=item B<dumper()> 

Returns the Data::Dumper instance bound to the object.  Should be called before
commit() to change Data::Dumper behavior.

    my $dd = $perobj->dumper (); 
    $dd->purity (1); 
    $dd->terse  (1);  # -- smaller dumps. 
    $perobj->commit (); 

See L<Data::Dumper>. 

=item B<load()> 

Class method that retrieves and builds the object.  Takes a filename argument. 
Don't call this directly, use new () for object retrieval. 
 
    Persistence::Object::Simple->load ( 
        __Fn => '/tmp/dope/myobject' 
    ); 


=back

=head1 Inheriting Persistence::Object::Simple

In most cases you would want to inherit this module.  It does not provide 
instance data methods so the object data functionality must be entirely 
provided by the inheriting module. Moreover, if you use your objects to 
store refs to class data, you'd need to bind and detach these refs at load() 
and commit().  Otherwise, you'll end up with a separate copy of class data 
with every object which will eventually break your code.  See L<perlobj>, 
L<perlbot>, and L<perltoot>, on why you should use objects to access 
class data. 

Persistence::Database inherits this module to provide a transparently 
persistent database class.  It overrides new(), load() and commit() 
methods.  There is no class data to bind/detach, but load() and commit() 
are overridden to serve as examples/templates for derived classes.  
Data instance methods, AUTOLOADed at runtime, automatically commit() 
when data is stored in Instance Variables.  For more details, Read The 
Fine Sources.  

=head1 Class Methods

load() and commit() can be used for storing non-object references.  commit() 
and load() can be invoked as class methods with a "Data" argument.   
Some examples: 

 # generates a unique filename in /tmp 
 my $fn = Persistence::Object::Simple->commit (
     __Dope => "/tmp", Data => $x );

 @list = 0..100; 
 Persistence::Object::Simple->commit 
  ( __Fn => '/tmp/datarefs/numbers', 
    Data => \@list; 
  ); 

 $list = Persistence::Object::Simple->load 
  ( __Fn => '/tmp/datarefs/numbers' ); 

 $" = "\n"; print "@$list"; 

=head1 SEE ALSO 

Data::Dumper(3), 
Persistence::User(3), 
perl(1).

=head1 AUTHOR

Vipul Ved Prakash, <mail@vipul.net>

=head1 COPYRIGHT 

Copyright (c) 1998, Vipul Ved Prakash. All rights reserved. This code is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 CONTRIBUTORS 

=over 4

=item * 

Mike Blazer <blazer@mail.nevalink.ru> helped with the Win32 Port.

=item * 

Holger Heimann <hh@it-sec.de> helped with debugging.

=item *

Kirrily 'Skud' Robert, <skud@infotrope.net> patched P::O::S to be taint-friendly.

=back

=cut
 
