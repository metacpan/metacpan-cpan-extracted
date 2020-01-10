package OpenTracing::Implementation;

use strict;
use warnings;


our $VERSION = '0.02';

=head1 NAME

OpenTracing::Implementation - Use OpenTracing with a specific implementation

=head1 SYNOPSIS

    use OpenTracing::Implementation qw/YourBackend/;

Or if you like

    use OpenTracing::Implementation;

And one can always do a manual bootstrap

    OpenTracing::Implementation->bootstrap_global_tracer( '+My::Implementation',
        option_one => 'foo',
        option_two => 'bar',
    );



=cut

#use lib qw(/Users/tvanhoesel/Repositories/Perceptyx/perl-opentracing-implementation-datadog/lib);

use Carp;

use OpenTracing::GlobalTracer;


use Module::Load;

sub import {
    my $package = shift;
    my $implementation_name = shift || $ENV{OPENTRACING_IMPLEMENTATION}
        or return;
    my @implementation_args = @_;
    
    __PACKAGE__->bootstrap_global_tracer(
        $implementation_name => @implementation_args
    )
}



sub bootstrap_global_tracer {
    my $package = shift;
    my $implementation_name = shift;
    my @implementation_args = @_;
    
    my $implementation_class =
        __PACKAGE__->_get_implementation_class( $implementation_name );
    
    carp "Loading implementation $implementation_class"
        if $ENV{OPENTRACING_DEBUG};
    
    load $implementation_class;
    
    my $tracer = $implementation_class->bootstrap( @implementation_args);
    
    OpenTracing::GlobalTracer->set_global_tracer( $tracer );
    
    return OpenTracing::GlobalTracer->get_global_tracer
}



sub _get_implementation_class {
    my $class = shift;
    my $implementation_name = shift;
    
    my $implementation_class = substr( $implementation_name, 0, 1) eq '+' ?
        substr( $implementation_name, 1 )
        :
        'OpenTracing::Implementation::' . $implementation_name;
    
    return $implementation_class
}



=head1 AUTHOR

Theo van Hoesel <tvanhoesel@perceptyx.com>

=head1 COPYRIGHT AND LICENSE

'OpenTracing Implementation' is Copyright (C) 2020, Perceptyx Inc

This package is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.



1;
