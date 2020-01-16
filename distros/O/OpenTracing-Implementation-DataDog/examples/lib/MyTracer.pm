package MyTracer;

use strict;
use warnings;


use lib '../../lib';
use OpenTracing::GlobalTracer;

# use OpenTracing::Implementation (DataDog =>
#     default_context => {
#         service_name => $0,
#         resource_name => 'unknown',
#     },
# );

use OpenTracing::Implementation;

OpenTracing::Implementation->set ( DataDog =>
    default_context => {
        service_name => $0,
        resource_name => 'unknown',
    },
);




# my $tracer = Tracer->new(
#     default_context => {
#         service_name => $0,
#         resource_name => 'unknown',
#     },
# );
# 
# OpenTracing::GlobalTracer->set_global_tracer( $tracer );


1;