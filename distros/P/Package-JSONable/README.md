# NAME

Package::JSONable - Add TO\_JSON to your packages without the boilerplate

# VERSION

version 0.001

# SYNOPSIS

    package MyModule;
    use Moo;
    

    use Package::JSONable (
        foo => 'Str',
        bar => 'Int',
        baz => 'Bool',
    );
    

    has foo => (
        is      => 'ro',
        default => sub { 'encode me!' },
    );
    

    sub bar {
        return 12345;
    }
    

    sub baz {
        return 1;
    }
    

    sub skipped {
        return 'I wish I could be encoded too :(';
    }

later...

    use JSON qw(encode_json);
    print encode_json(MyModule->new);

prints...

    {
        "foo":"encode me!",
        "bar":12345,
        "baz":true
    }

# DESCRIPTION

This module adds a TO\_JSON method directly to the calling class or object. This
module is designed to work with packages or classes including object systems
like Moose.

## Advanced Usage

The TO\_JSON method will take an optional hash to overwrite the output. For
example you may want to return different JSON for different cases.

    around TO_JSON => sub {
        my ( $orig, $self ) = @_;
        

        if ($self->different_json) {
            

            # Return a different set of metadata with a new spec
            return $orig->(self, (
                foo => 'Str',
                bar => 'Int',
                baz => 'Num',
            )); 
        }
        

        # Return JSON with the originally defined spec
        return $orig->($self);
    }

# WHY

I got tired of thinking about how variables need to be cast to get proper JSON
output. I just wanted a simple way to make my objects serialize to JSON.

# Types

The types are designed to be familiar to Moose users, though they aren't
related in any other way. They are designed to cast method or function return
values to proper JSON.

## Str

    Appends "" to the return value of the given method.

## Int

    Calls int() on the return value of the given method.

## Num

    Adds 0 to the return value of the given method.

## Bool

    Returns JSON::true if the given method returns a true value, JSON::false
    otherwise.

## ArrayRef

    If the given method returns an ARRAY ref then it is passed straight though.
    Otherwise [ $return_value ] is returned.

## HashRef

    If the given method returns an HASH ref then it is passed straight though.
    Otherwise { $return_value } is returned.

## CODE

    Passes the invocant to the sub along with the given method's return value. 

# AUTHOR

Andy Gorman <agorman@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andy Gorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
