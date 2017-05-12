package Object::Destroyer;

# See POD at end for details

use 5.006;
use strict;
use Carp         ();
##use Scalar::Util ();

use vars qw{$VERSION};
BEGIN {
    $VERSION = '2.01';
}

if ( eval { require Scalar::Util } ) {
    Scalar::Util->import('blessed');    
} else {
    *blessed = sub {
        my $ref = ref($_[0]);
        return $ref 
            if $ref &&  ($ref ne 'SCALAR') && ($ref ne 'ARRAY') && 
                        ($ref ne 'HASH') && ($ref ne 'CODE') &&
                        ($ref ne 'REF') && ($ref ne 'GLOB') &&
                        ($ref ne 'LVALUE');
        return;
    }
}

sub new {
    if ( ref $_[0] ) {
        # This is a method called on an existing
        # Destroyer, and should actually be passed through
        # to the encased object via the AUTOLOAD
        $Object::Destroyer::AUTOLOAD = '::new';
        goto &AUTOLOAD;
    }

    # *ahem*... where were we...
    my $destroyer = shift;
    my $ref = shift || ''; 
    my $self = {};
    
    if ( ref($ref) eq 'CODE' ) {
        ##
        ## Object::Destroyer->new( sub {...} )
        ##
        $self->{code} = $ref;
    } elsif ( my $class = blessed($ref) ) {
        ##
        ## Object::Destroyer->new( $object, 'optional_method' )
        ##
        my $method = shift || 'DESTROY';
        Carp::croak("Second argument to constructor must be a method name")
            if ref($method);
        Carp::croak("Object::Destroyer requires that $class has a $method method")
            unless $class->can($method); 
        $self->{object} = $ref;
        $self->{method} = $method;
    } else {
        ##
        ## And what is this?
        ##
        Carp::croak("You should pass an object or code reference to constructor");
    }
    Carp::croak("Extra arguments to constructor") if @_;

    return bless $self, $destroyer;
}

# Hand off general method calls to the encased object.
# Rather than just doing a $self->{object}->$method(@_), which
# would leave us in the call stack, find the actual subroutine
# that will be executed, and goto that directly.
sub AUTOLOAD {
    my $self = shift;
    
    my ($method) = $Object::Destroyer::AUTOLOAD =~ /^.*::(.*)$/;
    if (my $object = $self->{object}) {
        if (my $function = $object->can($method)) {
            ##
            ## Rearrange stack - instead of 
            ## $object_destroy->method(@params)
            ## make it look like
            ## $underlying_object->method(@params)
            ##
            unshift @_, $object;
            goto &$function;
        } elsif ( $object->can("AUTOLOAD") ) {
            ##
            ## We can't just goto to AUTOLOAD method in unknown
            ## package (it may be in base class of $object).
            ## We have to preserve the method's name.
            ## 
            if (wantarray) {
                ## List context
                return $object->$method(@_);
            } elsif ( defined wantarray ) {
                ## Scalar context
                return scalar $object->$method(@_);
            } else {
                ## Void context
                $object->$method(@_);
            }
        } else {
            ##
            ## Probably this is a caller's error
            ##
            my $package = ref $self->{object};
            Carp::croak(qq[Can't locate object method "$method" via package "$package"]);
        }
    }
    
    ##
    ## No object at all. Either we have a $coderef instead of object
    ## or DESTROY has been called already. 
    ##
    Carp::croak("Can't locate object to call method '$method'");
}

sub dismiss{
    $_[0]->{dismissed} = 1;
}

##
## Use our automatically triggered DESTROY to call the
## non-automatically triggered clean-up method of the encased object
##
sub DESTROY {
    my $self = shift;

    if ( $self->{dismissed} ) {
        ## do nothing
    } elsif ( $self->{code} ) {
        $self->{code}->();
    } elsif ( my $object = $self->{object} ) {
        my $method = $self->{method};
        $object->$method();
    }

    %$self = ();
}

##
## Catch a couple of specific cases that would be handled by UNIVERSAL
## before our AUTOLOAD got a chance to dispatch it.
##
## We are both 'Object::Destroyer' (or it's derived class)
## and underlying object's class
##
sub isa { 
    my $self  = shift;
    my $class = shift;

    return  $class eq __PACKAGE__ ||
        ($self->{object} && $self->{object}->isa($class));
}

sub can { 
    my $self = shift;
    return $self->{object}->can(@_) if $self->{object}; 
}

1;

__END__

=pod

=head1 NAME

Object::Destroyer - Make objects with circular references DESTROY normally

=head1 SYNOPSIS

  use Object::Destroyer;
  
  ## Use a standalone destroyer to release something 
  ## when it falls out of scope
  BLOCK: 
  {
      my $tree = HTML::TreeBuilder->new_from_file('somefile.html');
      my $sentry = Object::Destroyer->new( $tree, 'delete' );
      ## Here you can safely die, return, call last BLOCK or next BLOCK.
      ## The tree will be deleted automatically
  }

  ## Use it to break circular references
  {
      my $var;
      $var = \$var;
      my $sentry =  Object::Destroyer->new( sub {undef $var} );
      ## No more memory leaks!
      ## $var will be released when $sentry leaves the block
  }

  ## Destroyer can be used as a nearly transparent wrapper
  ## that will pass on method calls normally.
  {
      my $Mess = Big::Custy::Mess->new;
      print $Mess->hello;
  }
  
  package Big::Crusty::Mess;
  sub new {
      my $self = bless {}, shift;
      $self->populate;
      return Object::Destroyer->new( $self, 'release' );
  }
  sub hello { "Hello World!" }
  sub release { ...actual code to clean-up the memory... }

=head1 DESCRIPTION

One of the biggest problem with working with large, nested object trees is
implementing a way for a child node to see its parent. The easiest way to
do this is to add a reference to the child back to its parent.

This results in a "circular" reference, where A refers to B refers to A.
Unfortunately, the garbage collector perl uses during runtime is not capable
of knowing whether or not something ELSE is referring to these circular
references.

In practical terms, this means that object trees in lexically scoped 
variable ( e.g. C<my $Object = Tree-E<gt>new> ) will not be cleaned up when
they fall out of scope, like normal variables. This results in a memory leak
for the life of the process, which is a bad thing when using mod_perl or 
other processes that live for a long time.

Object::Destroyer allows for the creation of "Destroy" handles. The handle is
"attached" to the circular relationship, but is not a part of it. When the
destroy handle falls out of scope, it will be cleaned up correctly, and while
being cleaned up, it will also force the data structure it is attached to to be 
destroyed as well. 
Object::Destroyer can call a specified release method on an object 
(or method DESTROY by default). 
Alternatively, it can execute an arbitrary user code passed to constructor as a code reference.

=head2 Use as a Standalone Handle

The simplest way to use the class is to create a standalone destroyer,
preferably in the same lexical content. ( i.e. immediately after creating
the object to be destroyed)

  sub plagiarise {
    # Parse in a large nested document
    my $filename = shift;
    my $document = My::XML::Tree->open($filename);
  
    # Create the Object::Destroyer to clean it up as needed
    my $sentry = Object::Destroyer->new( $document, 'release' );
  
    # Continue with the Document as normal
    if ($document->author == $me) {
        # Normally this would have leaked the document
        return new Error("You already own the Document");
    }
    
    $document->change_author($me);
    $document->save;

    # We don't have to $Document->DESTROY here
    return 1;
  }

When the C<$sentry> falls out of scope at the end of the sub, it will force
the cirularly linked C<$Document> to be cleaned up at the same time, rather
than being forced to manually call C<$Document-<gt>release> at each and every
location that the sub could possible return.

Using the Object::Destroy object to force garbage collection to work
properly allows you to neatly sidestep the inadequecies of the perl garbage
collector and work the way you normally would, even with big objects.

=head2 Use to clean-up data structures

If a data structure with circular refereces has no method to release memory, 
you can create an C<Object::Destroyer> object that will do the job. 
Pass a code reference (most probably created by an anonymous subrotine block) 
to the constructor of the sentry object, and this code will be called
upon leaving the scope.

  {
     $params{other}        = \%other_params;
     $other_params{params} = \%params;

     my $sentry = Object::Destroyer->new( sub {undef $params{other}} );
     ##
     ## From now on, memory of %params will be 
     ## safely released when block is exited.
     ##

     ... code with return, next or last ...
          
  }

=head2 Use as a Transparent Wrapper

For situations where a class is always going to produce circular references,
you may wish to build this improved clean up directly into the class itself,
and with a few exceptions everything will just work the same.

Take the following example class

  package My::Tree;
  
  use strict;
  use Object::Destroyer;
  
  sub new {
      my $self = bless {}, shift;
      $self->init; ## assume that circular references are made

      ## Return the Object::Destroyer, with ourself inside it
      my $wrapper = Object::Destroyer->new( $self, 'release' );
      return $wrapper;
  }
  
  sub release {
    my $self = shift;
    foreach (values %$self) {
        $_->DESTROY if ref $_ eq 'My::Tree::Node';
    }
    %$self = ();
  }

We might use the class in something like this

  sub process_file {
      # Create a new tree
      my $tree = My::Tree->new( source => shift );
  
      # Process the Tree
      if ($tree->comments) {
          $tree->remove_comments or return;
      } 
      else {
          return 1; # Nothing to do
      }
  
      my $filename = $tree->param('target') or return;
      $tree->write($filename) or return;
  
      return 1;
  }

We were able to work with the data, and at no point did we know that we were
working with a Object::Destroyer object, rather than the My::Tree object itself.

=head2 Resource Usage

To implement the transparency, there is a slight CPU penalty when a method is
called on the wrapper to allow it to pass the method through to the encased
object correctly, and without appearing in the caller() information. Once the
method is called on the underlying object, you can make further method calls
with no penalty and access the internals of the object normally.

=head2 Problems with Wrappers and ref or UNIVERSAL::isa

Although it may ACT exactly like what's inside it, is isn't really it. Calling
C<ref $wrapper> or C<blessed $wrapper> will return C<'Object::Destroyer'>, and
not the class of the object inside it.

Likewise, calling C<UNIVERSAL::isa( $wrapper, 'My::Tree' )> or
C<UNIVERSAL::can( $wrapper, 'param' )> directly as functions will also not work.
The two alternatives to this are to either use C<$Wrapper-E<gt>isa> or
C<$wrapper-E<gt>can>, which will be caught and treated normally, or simple
don't use a wrapper and just use the standalone cleaners.

=head1 METHODS

=over

=item new

  my $sentry = Object::Destroyer->new( $object );
  my $sentry = Object::Destroyer->new( $object, 'method_name' );
  my $sentry = Object::Destroyer->new( $code_reference );

The C<new> constructor takes as arguments either a single blessed object with 
an optional name of the method to be called, or a refernce to code to be executed.
If the method name is not specified, the C<DESTROY> method is assumed.
The constructor will die if the object passed to it does not have the specified method.

=item DESTROY

  $sentry->DESTROY;
  undef $sentry;

If you wish, you may explicitly DESTROY the Destroyer at any time you wish.
This will also DESTROY the encased object at the same. This can allow for
legacy cases relating to Wrappers, where a user expects to have to manually
DESTROY an object even though it is not needed. The DESTROY call will be 
accepted and dealt with as it is called on the encased object.

=item dismiss

  $sentry->dismiss;

If you have changed your mind and you don't want Destroyer object to do 
its job, dismiss it. You may continue to use it as a wrapper, though. 

=back

=head1 SEE ALSO

Another option for dealing with circular references are C<weak references> 
(stable since Perl 5.8.0, see L<Scalar::Util>). See also L<GTop::Mem> 
and L<Devel::Monitor> for monitoring memory leaks.
The latter module contains a discussion on object desing with weak references. 

For lexically scoped resource management, see also L<Scope::Guard>, 
L<Sub::ScopeFinalizer> and L<Hook::Scope>.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Destroyer>

For other issues, or commercial enhancement or support, contact the Adam Kennedy.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Igor Gariev E<lt>gariev@hotmail.comE<gt>

=head1 COPYRIGHT

Copyright 2004 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
