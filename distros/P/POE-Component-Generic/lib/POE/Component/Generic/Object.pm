package POE::Component::Generic::Object;
# $Id: Object.pm 762 2011-05-18 19:34:32Z fil $

use strict;

use POE;
use POE::Component::Generic;

use Scalar::Util qw( blessed reftype );
use Carp qw(carp croak);
use vars qw($AUTOLOAD);

use strict;

our $VERSION = '0.1400';

##################################################
# Create the object
# $obj_def was sent from Generic::Child->request
# $session_id and $package_map come from Generic
sub new 
{
    my( $package, $obj_def, $session_id, $package_map ) = @_;

    my $self = bless { 
            OBJid       => $obj_def->{OBJid},
            session_id  => $session_id,
            package     => $obj_def->{package}
        }, $package;

    $self->__package_map( $package_map, $obj_def->{methods} );

    return $self;
}

##################################################
# $package_map comes from Generic->new
# $methods came from the child
sub __package_map
{
    my( $self, $package_map, $methods ) = @_;

    unless( $package_map ) {
        my $c = $package_map = {};
        foreach my $method ( @$methods ) {
            my( $package, $m ) = 
                POE::Component::Generic->__method_map( $method );
            next unless $m;
            $c->{$m} = $self->{package};
        }
    }
    $self->{package_map} = $package_map;
}

##################################################
sub AUTOLOAD 
{
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    croak "$method not an object method" unless blessed $self;    
    unless( $method =~ /[^A-Z]/ ) {
        croak qq( Can't locate object method "$method" via package ") 
                .ref( $self ). qq("); #"
    }
    
    my $hash = shift;
    unless( reftype($hash) eq 'HASH' ) {
        croak "First argument to $method must be a hashref";
    }

    unless( $self->{package_map}{ $method } ) {
        croak qq(Can't locate object method "$method" via package ")
              .ref( $self ). qq("); #"
    }
    $hash->{wantarray} = wantarray() unless (defined($hash->{wantarray}));

    warn "autoload method $method" if ($self->{debug});
    

    $self->__request( $method, $hash, @_ );
}

##################################################
# Add our arguements to the hash
sub __request
{
    my( $self, $method, $hash ) = @_;

    unless( $self->{package_map}{ $method } or $method eq 'DESTROY' ) {
        croak "Unknown method $method for package $self->{package}";
    }

    $hash->{obj}     = $self->object_id;
    $hash->{package} = $self->{package};

    # use ->call() so that $generic->method() happens in order
    return $poe_kernel->call( $self->session_id => '__request2', 
                                @_[1 .. $#_] );
}



############################################################################
# Object methods

sub session_id
{
    shift->{session_id};
}

sub object_id
{
    shift->{OBJid};
}

sub yield 
{
    my $self = shift;
    if( 'HASH' eq (reftype( $_[2] )||'') ) { croak "Second argument must be a hashref" }
    return $self->__request( @_ );
}

sub call 
{
    my $self = shift;
    if( 'HASH' eq (reftype( $_[2] )||'') ) { croak "Second argument must be a hashref" }
    return $self->__request( @_);
}

sub DESTROY 
{
    if (UNIVERSAL::isa($_[0],__PACKAGE__)) {
        $_[0]->__request( 'DESTROY', {} );
    }
}

1;

__END__

=head1 NAME

POE::Component::Generic::Object - A POE component that provides non-blocking access to a blocking object.

=head1 SYNOPSIS

    use POE::Component::Generic;

    my $generic = POE::Component::Generic->new( 
                    package=>'Builder', 
                    factories=>['build'] );

    $generic->build( {event=>'created_foo'}, 'foo' );

    # Note that this happens in a child process
    sub Builder::build {
        my( $package, $arg ) = @_;
        return bless { something=>$arg }, 'Other::Package';
    }

    # in the event "created_foo"
    # Note that this happens in the parent process
    sub create_foo {
        my( $resp, $foo ) = @_[ARG0, ARG1];
        die $resp->{error} if $resp->{error}

        # $foo is a proxy object to what Builder::build returned
        my $objID = $foo->object_id;        # Unique ID of the object

        $foo->vibble( {}, @args );          # call a method on the object foo
        $foo->yield( 'vibble', {}, @args ); # same as above   
        $foo->call( 'vibble', {}, @args );  # same as above   

        $generic->vibble( {obj=>$objID}, @args );   # same as above
    }


=head1 DESCRIPTION

L<POE::Component::Generic::Object> is a proxy object for objects that were
created by factory methods in the child process


=head1 METHODS

=head2 object_id

Returns a object ID for the object.  This ID is unique to a given
L<POE::Component::Generic> component but might not be unique across 
L<POE::Component::Generic> components.

=head2 session_id

Returns the session ID of the session that handles this object.  Currently
this corresponse to the parent 
L<POE::Component::Generic> component, so it's not very useful.  Eventually
each proxy object will get its own session.

=head2 DESTROY

If you let the proxy object go out of scope, the object in the child will 
be destroyed.

THIS COULD BE SUPRISING.  

Especially if you do something like:

    my( $resp, $obj ) = @_[ ARG0, ARG1 ];
    die $resp->{error} if $resp->{error};
    $obj = $obj->object_id;        # bang, no more sub-object.

However, it does allow you to control when the object will be reaped by the 
child process.


=head1 METHOD CALLS

There are 3 ways of calling methods on the object.

All methods need a data hashref to specify the response event. This data
hash is discussed in the L</INPUT> section.

=head2 yield

This method provides an alternative object based means of asynchronisly
calling methods on the object. First argument is the method to call, second
is the data hashref, following arguments are sent as arguments to the
resultant method call.

  $poco->yield( open => { event => 'result' }, "localhost" );

=head2 call

This method provides an alternative object based means of synchronisly
calling methods on the object. First argument is the method to call, second
is the data hashref, following arguments are sent as arguments to the
resultant method call.


  $poco->call( open => { event => 'result' }, "localhost" );



=head2 Psuedo-method

All methods of the object can be called, but the first param must be the
data hashref as noted below in the L</INPUT> section below.

For example:
    
    $poco->open( { event => 'opened' }, "localhost" );




=head1 INPUT

Input works the same way as L<POE::Component::Generic/INPUT>, except
that the C<obj> field defaults to the current object.


=head1 OUTPUT

Input works the same way as L<POE::Component::Generic/OUTPUT>.




=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

Based on work by David Davis E<lt>xantus@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>

=head1 RATING

Please rate this module.
L<http://cpanratings.perl.org/rate/?distribution=POE-Component-Generic>

=head1 BUGS

Probably.  Report them here:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE%3A%3AComponent%3A%3AGeneric>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008, 2011 by Philip Gwyn;

Copyright 2005 by David Davis and Teknikill Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

