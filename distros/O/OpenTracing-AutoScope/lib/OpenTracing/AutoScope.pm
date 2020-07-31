package OpenTracing::AutoScope;

use strict;
use warnings;

our $VERSION = 'v0.105.0';



use OpenTracing::GlobalTracer;

use Scope::Context;


# start_guarded_span
#
# This class-method will take an optional list of key/value pairs (same as
# start_active_span) which should be an even sized list.
# If not, we asume there is a given operation name.
#
sub start_guarded_span {
    my $class          = shift;
    my $operation_name = scalar @_ % 2 ? shift : _context_sub_name( );
    my %options        = @_;
    
    my $scope = OpenTracing::GlobalTracer
        ->get_global_tracer->start_active_span( $operation_name, %options );
    
    # use a closure, so we can carry over $scope until the end of the scope
    # where this coderef will be 'reaped'
    #
    Scope::Context->up->reap( sub { $scope->close } );
    
    return
}



# _context_sub_name
#
# Returns the sub_name of our caller (caller of `start_guarded_span`)
sub _context_sub_name { Scope::Context->up->up->sub_name }



1;
