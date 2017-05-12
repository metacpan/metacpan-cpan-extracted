package Pollux::Action;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: action objects for Pollux stores
$Pollux::Action::VERSION = '0.0.2';

use strict;
use warnings;

use List::MoreUtils qw/ zip /;
use Const::Fast;

use Moo;

use MooseX::MungeHas 'is_ro';

use experimental 'postderef';

use overload 
    '""' => sub { $_[0]->type },
    '&{}' => sub {
        my $self = shift;
        return sub {
            const my $r, { type => $self->type,
                $self->has_fields ? zip $self->fields->@*, @_ : ()
            };
            $r;
        }
    },
    '~~' => sub {
        my( $self, $other ) = @_;

        no warnings 'uninitialized';
        return $self->type eq ( ref $other ? $other->{type} : $other );
    },
    fallback => 1;


has type => (
    required => 1,
);

has fields => (
    predicate => 1,
);

sub BUILDARGS {
    my $class = shift;

    my %args;
    $args{type} = uc shift;

    $args{fields} = [ @_ ] if @_;

    return \%args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pollux::Action - action objects for Pollux stores

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use Pollux::Action;

    my $AddTodo = Pollux::Action->new( 'ADD_TODO', 'text' );

    # later on...
    $store->dispatch( $AddTodo->( 'do stuff' ) );

=head1 DESCRIPTION

Creates an action object generator  out of an
action name and a list of fields. 

The objects overload a few operators to ease combiner
comparisons: 

    # create the action generator
    my $AddTodo = Pollux::Action->new( 'ADD_TODO', 'text' );

    my $do_stuff = $AddTodo->( 'do stuff' );

    # stringification resolves to the action type
    print "$do_stuff";  # prints 'ADD_TODO'

    # turned into a hashref if deferenced
    my %x = %$do_stuff; # => { type => 'ADD_TODO', text => 'do stuff ' }

    # smart-matching compare the type between two actions
    print "matching" if $do_stuff ~~ $AddTodo->(); # prints 'matching'

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
