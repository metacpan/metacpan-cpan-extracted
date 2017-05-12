package POE::Component::Generic::Child;
# $Id: Child.pm 759 2011-05-18 16:55:01Z fil $

# This is the object that does all the work in the child process

use strict;
use Symbol;
use Carp;

##################################################
# Called from Generic::process_requests
sub new
{
    my( $package, %params ) = @_;
    my $self = bless { %params }, $package;

    $self->{filter} = POE::Filter::Reference->new();

    # there's room for other callbacks
    $self->{callback_defs} = {};
    # sub-objects
    $self->{objects} = {};
    $params{ID} =~ s/[^A-Za-z]+/A/g;
    $self->{object_id} = "$params{ID}OBJ000000";
    $self->init_handles;

    return $self;
}

##################################################
# Setup handles we want to play with
sub init_handles
{
    my( $self ) = @_;

    my $myout = $self->{myout} = gensym;

    # Redirect STDOUT to STDERR, so that badly behaved user code doesn't
    # mess up our communication with the parent
    open $myout, ">&STDOUT" or die "Can't dup STDOUT: $!\n";
    open STDOUT, ">&STDERR" or die "Can't dup STDERR: $!\n";

    # binmode so that Storable refs can make it across
    binmode(STDIN);
    binmode(STDOUT);
    binmode($myout);
    # No buffers for us
    STDOUT->autoflush(1);
    $myout->autoflush(1);

}
 

##################################################
# Main loop.  
# When this method exits, the child will exit.
sub loop
{
    my( $self ) = @_;
    
    $self->status( 'startup' );


    READ:
    while ( my $requests = $self->get_requests ) {
        $self->status( 'request' );
        unless ($self->{obj}) {
            my $req = shift @{$requests};
            unless( ref( $req ) eq 'HASH' and $req->{req} eq 'setup' ) {
                die "First request must be req=>setup";
            }
            # use Data::Denter;
            # warn "setup=", Denter $req;
            $self->OOB_req( $req );
        }
        
        foreach my $req (@{$requests}) {
            # use Data::Denter;
            # warn "req=", Denter $req;
            if( $req->{req} ) {
                $self->OOB_req( $req );
            }
            else {
                $self->request( $req );
            }
        }
        $self->status( 'read' );
    }
    $self->status( 'exit' );
}

##################################################
# Get the next block of requests
# Return :
#   undef() - shutdown child
#   arrayref of request hashes
sub get_requests
{
    my( $self ) = @_;

    my $raw;	
    return unless sysread ( STDIN, $raw, $self->{size} );
    return $self->{filter}->get([$raw]);
}


##################################################
# Update our status
sub status
{
    my $self = shift;
    $self->{debug} and warn join ' ', @_, "\n";
    $0 = join ' ', $self->{proc}, $self->{name}, @_;
    return;    
}

##################################################
# Send a response to the parent
sub reply
{
    my( $self, $resp ) = @_;
    $self->status( 'reply' );
    # use Data::Denter;
    # warn "reply=", Denter $resp;
    my $replies = $self->{filter}->put( [ $resp ] );
    
    my $rv = $self->{myout}->print( join '', @$replies );
    die "STDOUT: $!" unless $rv;
}




##################################################
# Handle a regular request from the parent
sub request
{
    my( $self, $req ) = @_;
    
    my $method = $req->{method};
    $self->{debug} and warn "method=$method";

    if( $req->{callbacks} ) {
        $self->callback_demarshall( $req, $req->{callbacks} );
    }
    if( $req->{postbacks} ) {
        $self->postback_demarshall( $req, $req->{postbacks} );
    }

    # The object we want to work on    
    my $obj = $self->{obj};
    if( $req->{obj} ) {
        $obj = $self->{objects}{ $req->{obj} };
        unless( $obj ) {
            $req->{error} = "Unknown object $req->{obj}";
            $self->{debug} and warn $req->{error};
            $self->reply( $req );
            return;
        }

        if( $method eq 'DESTROY' ) {          # special case
            $self->{debug} and warn "DESTROY for object $req->{obj}";

            delete $self->{objects}{ $req->{obj} };

            # Generic::Object requires DESTROY getting this far.
            # However, if the object can't really handle it, skip out now
            return unless $obj->can( $method );   

            delete $req->{wantarray};       # never
            delete $req->{event};           # ever
        }
    }


    # keeping {args} in req messes up callbacks
    my $args = delete $req->{args};

    eval {
        $self->{debug} and do {
                if( $req->{factory} ) {
                    warn "Calling factory $method on $obj"; 
                }
                else {
                    warn "Calling $method on $obj"; 
                }
            };
        if( $req->{wantarray} ) {
            $req->{result} = [ $obj->$method( @$args ) ];
        } 
        elsif( defined $req->{wantarray} or $req->{factory} ) {
            $req->{result} = [ scalar $obj->$method( @$args ) ];
        }
        elsif( $method eq 'DESTROY' and not $obj->can( $method ) ) {
            # DESTROY is dispacted from Generic::DESTROY.  $obj might not
            # implement it.  If it doesn't, we don't want the error produced
            # by blindly calling it.
        } 
        else {
            $obj->$method( @$args );
        }
    };

    if ($@) {
        $self->{debug} and warn $@;
        $req->{error} = $@;
        delete $req->{result};
    }

    #############
    if( $req->{factory} ) {
        $self->factory_response( $req );
    }

    #############
    if( defined $req->{event} ) {
        $self->reply( $req );
    }
    elsif( $req->{error} ) {
        warn $req->{error};
    }

}

##################################################
# Convert callbacks into coderefs
sub callback_demarshall
{
    my( $self, $req, $cdef ) = @_;
    
    foreach my $cb ( @$cdef ) {
        unless( $req->{args}[ $cb->{pos} ] eq $cb->{CBid} ) {
            die "Argument at position $cb->{pos} isn't $cb->{CBid}";
        }
    
        $req->{args}[ $cb->{pos} ] = sub {
            $self->reply( {
                  response => 'callback',
                  RID	   => $req->{RID},
                  pos      => $cb->{pos},
                  result   => [ @_ ]
              } );
        };
    }
}

##################################################
# Convert postbacks into a coderef
sub postback_demarshall
{
    my( $self, $req, $pdef ) = @_;
    
    foreach my $pb ( @$pdef ) {
        unless( $req->{args}[ $pb->{pos} ] eq $pb->{PBid} ) {
            die "Argument at position $pb->{pos} isn't $pb->{PBid}";
        }
    
        my $PBid    = $pb->{PBid};
        my $session = $pb->{session};
        my $event   = $pb->{event};

        $req->{args}[ $pb->{pos} ] = sub {
                            $self->reply( {
                                    response => 'postback',
                                    PBid     => $PBid,
                                    session  => $session,
                                    event    => $event,
                                    result   => [ @_ ]
                                } );
                        };
    }
}

##################################################
# Modify the response from a factory method
sub factory_response
{
    my( $self, $req ) = @_;

    my $OBJid = $self->{object_id}++;

    $self->{objects}{ $OBJid } = $req->{result}[0];
    my $package = ref $self->{objects}{ $OBJid };

    Carp::confess "Didn't return an object for $OBJid" unless $req->{result}[0];

    $self->{debug} and 
        warn "factory_response package=$package $OBJid=$self->{objects}{ $OBJid }";

    $req->{result}[0] = {
            package => $package,
            debug   => $self->{debug},
            methods => [ POE::Component::Generic->__package_methods( $package ) 
                       ],
            OBJid   => $OBJid
    };
}

##################################################
# Out-of-band request 
sub OOB_req
{
    my( $self, $req ) = @_;

    $self->status( 'OOB' );

    my $method = $req->{req};
    if( $method eq 'setup' ) {
        $self->OOB_setup( $req );
    }
    else {
        warn "Unknown OOB request $method";
    }
}

##################################################
# First request from parent
#   Create the object, configure the child process
sub OOB_setup
{
    my( $self, $req ) = @_;
    
    foreach my $f ( qw( name size debug verbose ) ) {
        next unless exists $req->{$f};
        $self->{$f} = $req->{$f};
        $self->{debug} and warn "Setting $f=$self->{$f}";
    }
    
    $self->{debug} and warn "build object $req->{package}";
    $self->{obj} = object_build( $req->{package}, $req->{args} );

    $self->{debug} and warn "Child PID is $$\n";

    $self->{debug} and 
        warn "object=$self->{obj}";
    $self->reply( { PID=>$$, response=>'new' } );
}





##################################################
# Create an object of a given class
sub object_build
{
    my( $package, $args ) = @_;
    my $ctor = package_load( $package );
    die "Can't find constructor for package $package" unless $ctor;
    return $package->can($ctor)->( $package, @$args );
}


##################################################
# Load the user package.  Also used by PoCo::Generic
sub package_load
{
    my( $package ) = @_;
    my $ctor = find_ctor( $package );
    return $ctor if $ctor;		# package already loaded
    eval "use $package";
    die $@ if $@;
    return find_ctor( $package );
}

##################################################
# Find an object constructor.
sub find_ctor
{
    my( $package ) = @_;
    foreach my $ctor ( qw( new spawn create ) ) {
        return $ctor if $package->can( $ctor );
    }
    return;
}


1;

__END__

=head1 NAME

POE::Component::Generic::Child - Child process handling

=head1 SYNOPSIS

    # Do not use POE::Component::Generic::Child directly.
    # Let POE::Component::Generic do it for you

=head1 DESCRIPTION

POE::Component::Generic::Child handles the child process for
L<POE::Component::Generic>.  

You might want to sub-class it if you want advanced interaction with your
object.

It is currently undocumented.  Consult the source code.


=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

Based on work by David Davis E<lt>xantus@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<POE::Component::Generic>.

=head1 RATING

Please rate this module. 
L<http://cpanratings.perl.org/rate/?distribution=POE-Component-Generic>

=head1 BUGS

Probably.  Report them here:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE%3A%3AComponent%3A%3AGeneric>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008,2011 by Philip Gwyn;

Copyright 2005 by David Davis and Teknikill Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

