##########################################################################
#
# Pots::SharedAccessor
#
# Thread shared safe accessor class
#
##########################################################################
package Pots::SharedAccessor;

##########################################################################
#
# Modules
#
##########################################################################
use threads;
use threads::shared;

##########################################################################
#
# Global variables
#
##########################################################################

##########################################################################
#
# Private methods
#
##########################################################################
sub _mk_accessors {
    my($self, $maker, @fields) = @_;
    my $class = ref $self || $self;

    # So we don't have to do lots of lookups inside the loop.
    $maker = $self->can($maker) unless ref $maker;

    foreach my $field (@fields) {
        if ( $field eq 'DESTROY' ) {
            require Carp;
            &Carp::carp("Having a data accessor named DESTROY  in ".
                            "'$class' is unwise.");
        }

        my $accessor = $self->$maker($field);

        {
            no strict 'refs';

            *{$class."\:\:$field"}  = $accessor
                unless defined &{$class."\:\:$field"};
        }
    }
}

sub make_shared_accessor {
    my($class, $field) = @_;
    $class = ref($class) || $class;

    return sub {
        my $self = shift;
        my $val : shared;

        {
            lock(%{$self});

            if (@_) {
                $self->{$field} = (@_ == 1 ? $_[0] : [@_]);
            }

            $val = $self->{$field};
            return $val;
        }
    };
}

sub make_accessor {
    my($class, $field) = @_;
    $class = ref($class) || $class;

    return sub {
        my $self = shift;
        my $val;

        if (@_) {
            $self->{$field} = (@_ == 1 ? $_[0] : [@_]);
        }

        $val = $self->{$field};
        return $val;
    };
}

##########################################################################
#
# Public methods
#
##########################################################################
sub mk_accessors {
    my $class = shift;

    $class->_mk_accessors('make_accessor', @_);
}

sub mk_shared_accessors {
    my $class = shift;

    $class->_mk_accessors('make_shared_accessor', @_);
}

1; #this line is important and will help the module return a true value
__END__

=head1 NAME

Pots::SharedAccessor - Perl ObjectThreads shared thread-safe accessors

=head1 SYNOPSIS

    package MyPackage;

    use base qw(Pots::SharedObject Pots::SharedAccessor);

    MyPackage->mk_shared_accessors(qw(field1 field2));

    sub new {
        my $class = shift;

        my $self = $class->SUPER::new();

        $self->field1(0);
        $self->field2(1);

        return $self
    }

    package main;

    my $o = MyPackage->new();

    sub thread_proc {
        printf "field1 = %d, field2 = %d\n",
            $o->field1(), $o->field2();
        sleep(5);
        printf "field1 = %d, field2 = %d\n",
            $o->field1(), $o->field2();
    }

    my $th = threads->new("thread_proc");
    $o->field1(5);
    $o->field2(42);

=head1 DESCRIPTION

This pseudo-class allows you to use shared thread safe accessors in your
shared objects.

=head1 METHODS

=over

=item mk_shared_accessors(@fields)

This will create the accessor methods for field names in "@fields".
These accessors methods can be called from other threads.

=back

=head1 ACKNOWLEDGMENTS

This module is HEAVILY based on Michael G Schwern's C<Class::Accessor>. It has
been revamped to include the shared behavior.

=head1 AUTHOR and COPYRIGHT

Remy Chibois E<lt>rchibois at free.frE<gt>

Copyright (c) 2004 Remy Chibois. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
