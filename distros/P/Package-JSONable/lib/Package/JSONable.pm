# ABSTRACT: Add TO_JSON to your packages without the boilerplate
package Package::JSONable;
{
  $Package::JSONable::VERSION = '0.001';
}

use strict;
use warnings;
use Scalar::Util qw(reftype);
use Carp qw(croak);
use List::MoreUtils qw(none);
use JSON ();

sub import {
    my ( $class, %import_opts ) = @_;

    my ( $target ) = caller;
    
    my $to_json = sub {
        my ( $self, %opts ) = @_;

        $self = $target unless $self;
        
        %opts = %import_opts unless %opts;
        
        my @types = qw/Str Int Num Bool ArrayRef HashRef/;

        my %hash;
        foreach my $method ( keys %opts ) {
            my $type      = $opts{$method};
            my @value     = $self->$method;
            my ( $value ) = @value;
            my $reftype   = reftype $value;
            my $typetype  = reftype $type;

            if ($typetype) {                
                croak sprintf('Invalid type: "%s"', $typetype)
                        if $typetype ne 'CODE';
                
                $hash{$method} = $type->($self, @value);
                next;
            }

            croak sprintf('Invalid type: "%s"', $type)
                    if none { /^$type$/ } @types;
            
            if (!defined $value && $type ne 'Bool') {
                $hash{$method} = $value;
                next;
            }

            if ( $type eq 'Str' ) {
                $hash{$method} = $value . "";
            }
            elsif ( $type eq 'Int' ) {
                $hash{$method} = int $value;
            }
            elsif ( $type eq 'Num' ) {
                $hash{$method} = $value += 0;
            }
            elsif ( $type eq 'ArrayRef' ) {                
                if ($reftype && $reftype eq 'ARRAY') {
                    $hash{$method} = $value;
                }
                else {
                    $hash{$method} = [ @value ];
                }
            }
            elsif ( $type eq 'HashRef' ) {                
                if ($reftype && $reftype eq 'HASH') {
                    $hash{$method} = $value;
                }
                else {
                    $hash{$method} = { @value };
                }
            }
            elsif ( $type eq 'Bool' ) {
                if ( $value ) {
                    $hash{$method} = JSON::true;
                }
                else {
                    $hash{$method} = JSON::false;
                }
            }
        }

        return \%hash;
    };
    
    no strict 'refs';
    *{"${target}::TO_JSON"} = $to_json;
}

1;

__END__

=pod

=head1 NAME

Package::JSONable - Add TO_JSON to your packages without the boilerplate

=head1 VERSION

version 0.001

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This module adds a TO_JSON method directly to the calling class or object. This
module is designed to work with packages or classes including object systems
like Moose.

=head2 Advanced Usage

The TO_JSON method will take an optional hash to overwrite the output. For
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

=head1 WHY

I got tired of thinking about how variables need to be cast to get proper JSON
output. I just wanted a simple way to make my objects serialize to JSON.

=head1 Types

The types are designed to be familiar to Moose users, though they aren't
related in any other way. They are designed to cast method or function return
values to proper JSON.

=head2 Str

    Appends "" to the return value of the given method.

=head2 Int

    Calls int() on the return value of the given method.

=head2 Num

    Adds 0 to the return value of the given method.

=head2 Bool

    Returns JSON::true if the given method returns a true value, JSON::false
    otherwise.

=head2 ArrayRef

    If the given method returns an ARRAY ref then it is passed straight though.
    Otherwise [ $return_value ] is returned.

=head2 HashRef

    If the given method returns an HASH ref then it is passed straight though.
    Otherwise { $return_value } is returned.

=head2 CODE

    Passes the invocant to the sub along with the given method's return value. 

=head1 AUTHOR

Andy Gorman <agorman@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andy Gorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
