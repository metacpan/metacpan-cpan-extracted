#!/usr/bin/env perl
use Test2::Bundle::Extended;

{
    package Foo;
    use Moo;
    with 'MooX::BuildArgsHooks';
    
    has bar => (is=>'ro');
    
    around NORMALIZE_BUILDARGS => sub{
        my ($orig, $class, @args) = @_;
        @args = $class->$orig( @args );
        return( bar=>$args[0] ) if @args==1 and ref($args[0]) ne 'HASH';
        return @args;
    };
    
    around TRANSFORM_BUILDARGS => sub{
        my ($orig, $class, $args) = @_;
        $args = $class->$orig( $args );
        $args->{bar} = ($args->{bar}||0) + 10;
        return $args;
    };
    
    around FINALIZE_BUILDARGS => sub{
        my ($orig, $class, $args) = @_;
        $args = $class->$orig( $args );
        $args->{bar}++;
        return $args;
    };
}

is(
    Foo->new( 3 )->bar(),
    14,
);

done_testing;
