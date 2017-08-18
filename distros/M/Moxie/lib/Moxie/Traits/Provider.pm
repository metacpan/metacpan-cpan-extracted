package Moxie::Traits::Provider;
# ABSTRACT: built in traits

use v5.22;
use warnings;
use experimental qw[
    signatures
    postderef
];

use Method::Traits ':for_providers';

use Carp                   ();
use B::CompilerPhase::Hook (); # multi-phase programming
use Sub::Util              ();
use PadWalker              (); # for generating lexical accessors

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

sub init_args ( $meta, $method, %init_args ) : OverwritesMethod {

    my $class_name  = $meta->name;
    my $method_name = $method->name;

    Carp::croak('The `init_arg` trait can only be applied to BUILDARGS')
        if $method_name ne 'BUILDARGS';

    if ( %init_args ) {

        my @all       = sort keys %init_args;
        my @required  = grep !/\?$/, @all;

        my $max_arity = 2 * scalar @all;
        my $min_arity = 2 * scalar @required;

        # use Data::Dumper;
        # warn Dumper {
        #     class     => $meta->name,
        #     all       => \@all,
        #     required  => \@required,
        #     min_arity => $min_arity,
        #     max_arity => $max_arity,
        # };

        $meta->add_method('BUILDARGS' => sub ($self, @args) {

            my $arity = scalar @args;

            Carp::croak('Constructor for ('.$class_name.') expected '
                . (($max_arity == $min_arity)
                    ? ($min_arity)
                    : ('between '.$min_arity.' and '.$max_arity))
                . ' arguments, got ('.$arity.')')
                if $arity < $min_arity || $arity > $max_arity;

            my $proto = $self->UNIVERSAL::Object::BUILDARGS( @args );

            my @missing;
            # make sure all the expected parameters exist ...
            foreach my $param ( @required ) {
                push @missing => $param unless exists $proto->{ $param };
            }

            Carp::croak('Constructor for ('.$class_name.') missing (`'.(join '`, `' => @missing).'`) parameters, got (`'.(join '`, `' => sort keys $proto->%*).'`), expected (`'.(join '`, `' => @all).'`)')
                if @missing;

            my (%final, %super);

            # do any kind of slot assignment shuffling needed ....
            foreach my $param ( @all ) {

                my $from = $param =~ s/\?$//r; #/
                my $to   = $init_args{ $param };

                if ( $to =~ /^super\((.*)\)$/ ) {
                    $super{ $1 } = delete $proto->{ $from }
                         if $proto->{ $from };
                }
                else {
                    # now grab the slot by the correct name ...
                    $final{ $to } = delete $proto->{ $from }
                        if $proto->{ $from };
                }
            }

            # inherit keys ...
            if ( keys %super ) {
                my $super_proto = $self->next::method( %super );
                %final = ( $super_proto->%*, %final );
            }

            if ( keys $proto->%* ) {
                Carp::croak('Constructor for ('.$class_name.') got unrecognized parameters (`'.(join '`, `' => keys $proto->%*).'`)');
            }

            # use Data::Dumper;
            # warn Dumper +{
            #     proto => $proto,
            #     final => \%final,
            #     super => \%super,
            #     meta  => {
            #         class     => $meta->name,
            #         all       => \@all,
            #         required  => \@required,
            #         min_arity => $min_arity,
            #         max_arity => $max_arity,
            #     }
            # };

            return \%final;
        });
    }
    else {
        $meta->add_method('BUILDARGS' => sub ($self, @args) {
            Carp::croak('Constructor for ('.$class_name.') expected 0 arguments, got ('.(scalar @args).')')
                if @args;
            return $self->UNIVERSAL::Object::BUILDARGS();
        });
    }
}

sub ro ( $meta, $method, @args ) : OverwritesMethod {

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        $slot_name = shift @args;
    }
    else {
        if ( $method_name =~ /^get_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::croak('Unable to build `ro` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub {
        Carp::croak("Cannot assign to `$slot_name`, it is a readonly") if scalar @_ != 1;
        $_[0]->{ $slot_name };
    });
}

sub rw ( $meta, $method, @args ) : OverwritesMethod {

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        $slot_name = shift @args;
    }
    else {
        $slot_name = $method_name;
    }

    Carp::croak('Unable to build `rw` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because class is immutable.')
        if ($meta->name)->isa('Moxie::Object::Immutable');

    Carp::croak('Unable to build `rw` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub {
        $_[0]->{ $slot_name } = $_[1] if scalar( @_ ) > 1;
        $_[0]->{ $slot_name };
    });
}

sub wo ( $meta, $method, @args ) : OverwritesMethod {

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        $slot_name = shift @args;
    }
    else {
        if ( $method_name =~ /^set_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::croak('Unable to build `wo` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because class is immutable.')
        if ($meta->name)->isa('Moxie::Object::Immutable');

    Carp::croak('Unable to build `wo` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub {
        Carp::croak("You must supply a value to write to `$slot_name`") if scalar(@_) < 1;
        $_[0]->{ $slot_name } = $_[1];
    });
}

sub predicate ( $meta, $method, @args ) : OverwritesMethod {

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        $slot_name = shift @args;
    }
    else {
        if ( $method_name =~ /^has_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::croak('Unable to build predicate for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub { defined $_[0]->{ $slot_name } } );
}

sub clearer ( $meta, $method, @args ) : OverwritesMethod {

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        $slot_name = shift @args;
    }
    else {
        if ( $method_name =~ /^clear_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::croak('Unable to build `clearer` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because class is immutable.')
        if ($meta->name)->isa('Moxie::Object::Immutable');

    Carp::croak('Unable to build `clearer` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub { undef $_[0]->{ $slot_name } } );
}

sub handles ( $meta, $method, @args ) : OverwritesMethod {

    my $method_name = $method->name;

    my ($slot_name, $delegate) = ($args[0] =~ /^(.*)\-\>(.*)$/);

    Carp::croak('Delegation spec must be in the pattern `slot->method`, not '.$args[0])
        unless $slot_name && $delegate;

    Carp::croak('Unable to build delegation method for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub {
        $_[0]->{ $slot_name }->$delegate( @_[ 1 .. $#_ ] );
    });
}

sub private ( $meta, $method, @args ) {

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        $slot_name = shift @args;
    }
    else {
        $slot_name = $method_name;
    }

    Carp::croak('Unable to build private accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    # NOTE:
    # These are lexical accessors ...

    # we should not be able to find it in the symbol table ...
    if ( $meta->has_method( $method_name ) || $meta->has_method_alias( $method_name ) || $meta->requires_method( $method_name ) ) {
        Carp::croak('Unable to install private (lexical) accessor for slot('.$slot_name.') named ('
            .$method_name.') because we found a conflicting non-lexical method of that name. '
            .'Private methods must be defined before any public methods of the same name.');
    }
    else {
        # set the prototype here so that the compiler sees
        # this as early as possible ...
        Sub::Util::set_prototype( '', $method->body );

        # at this point we can assume that we have a lexical
        # method which we need to transform, and in order to
        # do that we need to look at all the methods in this
        # class and find all the ones who 'close over' the
        # lexical method and then re-write their lexical pad
        # to use the accessor method that I will generate.

        # NOTE:
        # we need to delay this until the UNITCHECK phase
        # because we need all the methods of this class to
        # have been compiled, at this moment, they are not.
        B::CompilerPhase::Hook::enqueue_UNITCHECK {

            # now see if this class is immutable or not, it will
            # determine the type of accessor we generate ...
            my $class_is_immutable = ($meta->name)->isa('Moxie::Object::Immutable');

            # now check the class local methods ....
            foreach my $m ( $meta->methods ) {
                # get a HASH of the things the method closes over
                my $closed_over = PadWalker::closed_over( $m->body );

                #warn Data::Dumper::Dumper({
                #    class       => $meta->name,
                #    method      => $m->name,
                #    closed_over => $closed_over,
                #    looking_for => $method_name,
                #});

                # XXX:
                # Consider using something like Text::Levenshtein
                # to check for typos in the accessor usage.
                # - SL

                # if the private method is used, then it will be
                # here with a prepended `&` sigil ...
                if ( exists $closed_over->{ '&' . $method_name } ) {
                    # now we know that we have someone using the
                    # lexical method inside the method body, so
                    # we need to generate our accessor accordingly

                    # XXX:
                    # The DB::args stuff below is fragile because it
                    # is susceptible to alteration of @_ in the
                    # method that calls these accessors. Perhaps this
                    # can be fixed with XS, but for now we are going
                    # to assume people aren't doing this since they
                    # *should* be using the signatures that we enable
                    # for them.
                    # - SL

                    my $accessor;
                    if ( $class_is_immutable ) {
                        # NOTE:
                        # if the class is immutable, perl will sometimes
                        # complain about accessing a read-only value in
                        # a way it is not comfortable, and this can be
                        # annoying. However, since we actually told perl
                        # that we want to be immutable, there actually is
                        # no need to generate the lvalue accessor when
                        # we can make a read-only one.
                        # - SL
                        $accessor = sub {
                            package DB; @DB::args = (); my () = caller(1);
                            my ($self) = @DB::args;
                            $self->{ $slot_name };
                        };
                    }
                    else {
                        $accessor = sub : lvalue {
                            package DB; @DB::args = (); my () = caller(1);
                            my ($self) = @DB::args;
                            $self->{ $slot_name };
                        };
                    }

                    # then this is as simple as assigning the HASH key
                    $closed_over->{ '&' . $method_name } = $accessor;

                    # okay, now restore the closed over vars
                    # with our new addition...
                    PadWalker::set_closed_over( $m->body, $closed_over );
                }
            }
        };
    }

}

1;

__END__

=pod

=head1 NAME

Moxie::Traits::Provider - built in traits

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This is a L<Method::Traits> provider module which L<Moxie> enables by
default. These are documented in the L<METHOD TRAITS> section of the
L<Moxie> documentation.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
