package Redis::OpenTracing;

use strict;
use warnings;

use syntax 'maybe';

our $VERSION = 'v0.3.0';

use Moo;
use Types::Standard qw/HashRef Maybe Object Str Value is_Str/;

use OpenTracing::GlobalTracer;
use Scalar::Util 'blessed';
use Carp qw/croak/ ;

has 'redis' => (
    is => 'ro',
    isa => Object, # beyond current scope to detect if it is a Redis like client
    required => 1,
);



has '_redis_client_class_name' => (
    is => 'lazy',
    isa => Str,
);

sub _build__redis_client_class_name {
    blessed( shift->redis )
};



sub _operation_name {
    my ( $self, $method_name ) = @_;
    
    return $self->_redis_client_class_name . '::' . $method_name;
}



has 'tags' => (
    is => 'ro',
    isa => HashRef[Value],
    default => sub { {} }, # an empty HashRef
);



our $AUTOLOAD; # keep 'use strict' happy

sub AUTOLOAD {
    my ($self) = @_;
    
    my $method_call    = do { $_ = $AUTOLOAD; s/.*:://; $_ };
    my $component_name = $self->_redis_client_class_name( );
    my $db_statement   = uc($method_call);
    my $operation_name = $self->_operation_name( $method_call );
    
    my $method_wrap = sub {
        my $self = shift;
        my $scope = _global_tracer_start_active_span(
            $operation_name,
            tags => {
                'component'     => $component_name,
                
                %{ $self->tags( ) },
                
                'db.statement'  => $db_statement,
                'db.type'       => 'redis',
                'span.kind'     => 'client',
                
            },
        );
        
        my $result;
        my $wantarray = wantarray();
        
        my $ok = eval {
            if ($wantarray) {
                $result = [ $self->redis->$method_call(@_) ];
            } else {
                $result = $self->redis->$method_call(@_);
            };
            1;
        };
        my $error = $@;
        
        if ( $ok ) {
            $scope->close()
        } else {
            $scope->get_span()->add_tags(
                generate_error_tags( $db_statement, $error )
            );
            $scope->close();
            croak $error;
        }
        
        return $wantarray ? @$result : $result;
    };
    
    # Save this method for future calls
    no strict 'refs';
    *$AUTOLOAD = $method_wrap;
    
    goto $method_wrap;
}



sub _global_tracer_start_active_span {
    my $operation_name = shift;
    my @args = @_;
    
    return OpenTracing::GlobalTracer->get_global_tracer()->start_active_span(
        $operation_name,
        @args,
    );
}



sub generate_error_tags {
    my ( $db_statement, $error ) = @_;
    
    my $error_message = $error;
    chomp $error_message;
    
    my $error_kind = "REDIS_EXCEPTION";
#   my $error_kind = sprintf("REDIS_EXCEPTION_%s",
#       $db_statement,
#   );
#   
    return (
        'error'      => 1,
        'message'    => $error_message,
        'error.kind' => $error_kind,
    );
}



sub DESTROY { } # we don't want this to be dispatched



1;
