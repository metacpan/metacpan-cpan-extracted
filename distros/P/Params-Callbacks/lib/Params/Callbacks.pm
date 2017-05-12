use strict;
use warnings;

package Params::Callbacks;
our $VERSION = '2.0.31'; # VERSION
# ABSTRACT: Enable subroutines to accept optional blocking callbacks easily
use Exporter ();
use Scalar::Util ( 'blessed' );
use namespace::clean;
use constant CALLBACK_CLASS => 'Params::Callbacks::Callback';
use Message::String << 'EOF';
CRIT_BAD_CALLBACK_LIST First argument must be a %s object
EOF

our @ISA         = ( 'Exporter' );
our @EXPORT_OK   = ( 'callbacks', 'callback' );
our %EXPORT_TAGS = ( all => \@EXPORT_OK, ALL => \@EXPORT_OK );

sub new
{
    my ( $class, @params ) = @_;
    # Recycle a callback chain if that's what was passed
    if ( blessed( $params[-1] ) && $params[-1]->isa( __PACKAGE__ ) ) {
        my $callback_chain = pop @params;
        return $callback_chain, @params;
    }
    # Build a new callback chain.
    my @callbacks;
    while (    @params
            && blessed( $params[-1] )
            && $params[-1]->isa( CALLBACK_CLASS ) )
    {
        unshift @callbacks, pop @params;
    }
    return bless( \@callbacks, $class ), @params;
}

sub transform
{
    my ( $callbacks, @data ) = @_;
    CRIT_BAD_CALLBACK_LIST( __PACKAGE__ )
        unless ref( $callbacks ) && $callbacks->isa( __PACKAGE__ );
    for my $callback ( @$callbacks ) {
        last unless @data;
        @data = map { $callback->( $_ ) } @data;
    }
    return @data;
}

sub smart_transform
{
    # Transform the data (use same @_)
    my @data = &transform;
    # If only a single element exists in @data then return *that* element
    # when in scalar context; don't return an element count. At all other
    # times, subject @data to normal array semantics.
    return @data if wantarray;
    return scalar( @data ) if @data != 1;
    return $data[0];
}

sub callbacks
{
    return __PACKAGE__->new( @_ );
}

sub callback (&;@)
{
    my ( $callback, @params ) = @_;
    return bless( $callback, CALLBACK_CLASS ), @params;
}

1;

=pod

=encoding utf-8

=head1 NAME

Params::Callbacks - Enable subroutines to accept blocking callbacks easily

=head1 VERSION

version 2.0.31

=head1 SYNOPSIS

    use Params::Callbacks 'callbacks', 'callback';  # Or use ':all' tag
    use Data::Dumper;

    $Data::Dumper::Indent = 0;
    $Data::Dumper::Terse  = 1;

    sub foo
    {
        my ( $callbacks, @params ) = &callbacks;
        # If &callbacks makes the hairs
        # on your neck standp, then use
        # a cleaner alternative:
        #
        # - callbacks(@_), or ...
        # - Params::Callbacks->new(@_)

        return $callbacks->transform(@params);
    }

    # No callbacks; no change to result!
    my @result_1 = foo( 0, 1, 2, 3 );
    print Dumper( [@result_1] ), "\n";  # [0,1,2,3]

    # With callback, result is transformed before being returned!
    my @result_2 = foo( 0, 1, 2, 3, callback { 0 + 2 ** $_ } );
    print Dumper( [@result_2] ), "\n";  # [1,2,4,8]

    # With multiple callbacks, result is transformed in multiple stages
    my @result_3 = foo( 0, 1, 2, 3, callback { 0 + 2 ** $_ }
                                    callback { 0 + 10 * $_ });
    print Dumper( [@result_3] ), "\n";  # [10,20,40,80];

=head1 DESCRIPTION

Use this module to enable a function or method to accept optional blocking
callbacks. 

Perhaps you would like to keep your implementation lightweight, while 
providing the caller with an opportunity to modify its result before it 
is finally returned to the calling scope.

Callbacks are a fabulous for two reasons:

=over

=item * They reduce the need by the implementer to produce reams of speculative,
kitchen-sink code, helping to keep functions and methods lightweight and focussed
upon doing what is important.

=item * They reduce the need by the caller to litter the calling scope with 
lexical cruft that will never be used again. All of that can be localised within 
a transformative callback, to be disposed of at the end of its scope.

=back

=head2 How callbacks are identified and processed

Callbacks are passed to your function by placing them at the end of the call's
argument list. This module provides you with a means to identify and separate any
callbacks from your function's arguments. It also provides dispatchers that will
pass the return value into the callback chain and capture the result, ready to
pass it back up to the caller.

Callbacks work simply enough. Like any function, they accept input in C<@_>
and their output is returned explicitly or as the result of their terminal
expression. When chaining together multiple callbacks, the dispatcher takes
the function's return value and passes it to the first callback; the output
from that callback is then passed to the following callback, and so on until
their are no more callbacks to process the value. The result of the final
callback is returned to the program ready to be returned to the caller.

As a convenience, a callback also receives a copy of the input value in C<$_>.

If an empty list is returned then the value is discarded and the callback
chain is terminated for that value.

=head2 Creating and passing callbacks into a function

    ##################################
    # We define our MyModule.pm file #
    ##################################

    package MyModule;
    use Exporter;
    use Params::Callbacks 'callbacks';
    use namespace::clean;
    use Params::Callbacks 'callback';
    our @EXPORT = 'callback';
    our @EXPORT_OK = 'awesome';
    our @ISA = 'Exporter';

    sub awesome {
        my ( $callbacks, @names ) = &callbacks;
        return $callbacks->transform(@names);
    }

    1;

    #############################
    # Meanwhile, back in main:: #
    #############################

    # No callbacks ...
    #
    use MyModule 'awesome';
    my @team = awesome('Imran', 'Merlyn', 'Iain');
    print "$_\n" for @team;
    #
    # Imran
    # Merlyn
    # Iain
    #
    # (Not so awesome.)


    # With a callback ...
    #
    use MyModule 'awesome';
    my @team = awesome('Imran', 'Merlyn', 'Iain', callback {
        "$_, you're awesome!"
    });
    print "$_\n" for @team;
    #
    # Imran, you're awesome!
    # Merlyn, you're awesome!
    # Iain, you're awesome!
    #
    # (This time with added awesome!)


    # With two callbacks ...
    #
    use MyModule 'awesome';
    my @team = awesome('Imran', 'Merlyn', 'Iain', callback {
        "$_, you're awesome!"
    } # Comma is optional here.
    callback {
        print "$_[0]\n";
        return $_[0];
    });
    #
    # Imran, you're awesome!
    # Merlyn, you're awesome!
    # Iain, you're awesome!
    #
    # (Moar awesome!)

=head1 METHODS

=head2 new

Takes a list of scalar values, strips away any trailing callbacks and returns
a new list containing a blessed array reference (the callback chain) followed
by any values from the original list that weren't callbacks.

A typical use case would be processing a function's argument list C<@_>:

    sub my_function
    {
        ( $callbacks, @params ) = Params::Callbacks->new(@_);
        ...
    }

It is also possible to pass in a pre-prepared callback chain instead of
individual callbacks, in which case that value will be returned as the callback
chain, without inspecting the list for individual callbacks E<mdash> this behaviour
is useful when the ability to efficiently forward callbacks onto a more deeply
nested call is required.

The output list is packaged in such a way as to make parsing the argument list
as easy as possible.

=head2 transform

Transform a result set by passing it through all the stages of the callbacks
pipeline. The transformation terminates if the result set is reduced to
nothing, and an empty result set is returned.

Empty or not, this method always returns a list.

=head2 smart_transform

Transform a result set by passing it through all the stages of the callbacks
pipeline. The transformation terminates if the result set is reduced to
nothing, and an empty result set is returned.

Empty or not, this method always returns a list if a list was wanted.

If a scalar is required, a scalar is returned. If the result set contains a
single element then the value of that element will be returned, otherwise a
count of the number of elements is returned.

=head1 EXPORTS

Nothing is exported by default.

The following functions are exported individually upon request; they may all be
imported at once using the import tags C<:all> and C<:ALL>.

=head2 callbacks

Takes a list of scalar values, strips away any trailing callbacks and returns
a new list containing a blessed array reference (the callback chain) followed
by any values from the original list that weren't callbacks. The typical
imagined use case is in processing a function's argument list C<@_>:

    sub my_function
    {
        ( $callbacks, @params ) = callbacks(@_);
        ...
    }

    sub my_function
    {
        ( $callbacks, @params ) = &callbacks;
        ...
    }

It is also possible to pass in a pre-prepared callback chain instead of
individual callbacks, in which case this function will return that value
as its own callback chain, without inspecting the list for individual
callbacks. This behaviour is useful when forwarding callbacks onto a
more deeply nested call.

The output list is packaged in such a way as to make parsing the argument list
as easy as possible.

=head2 callback

A simple piece of syntactic sugar that announces a callback. The code
reference it precedes is blessed as a C<Params::Callbacks::Callback>
object, disambiguating it from unblessed subs that are being passed as
standard arguments.

Multiple callbacks may be chained together with or without comma
separators:

    callback { ... }, callback { ... }, callback { ... }    # Valid
    callback { ... }  callback { ... }  callback { ... }    # Valid, too!

=head1 REPOSITORY

=over 2

=item * L<http://search.cpan.org/dist/Params-Callbacks/lib/Params/Callbacks.pm>

=item * L<https://github.com/cpanic/Params-Callbacks>

=back

=head1 BUG REPORTS

Please report any bugs to L<http://rt.cpan.org/>

=head1 AUTHOR

Iain Campbell <cpanic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2015 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
