package Mock::Quick::Object;
use strict;
use warnings;

use Mock::Quick::Util;
use Mock::Quick::Object::Control;
use Carp ();
use Scalar::Util ();

our $AUTOLOAD;

class_meth new => sub {
    my $class = shift;
    my %proto = @_;
    return bless \%proto, $class;
};

sub AUTOLOAD {
    # Do not shift this, we need it when we use goto &$sub
    my ($self) = @_;
    my ( $package, $sub ) = ( $AUTOLOAD =~ m/^(.+)::([^:]+)$/ );
    $AUTOLOAD = undef;

    Carp::croak "Can't locate object method \"$sub\" via package \"$package\""
        unless Scalar::Util::blessed( $self );

    my $code = $self->can( $sub );
    Carp::croak "Can't locate object method \"$sub\" in this instance"
        unless $code;

    goto &$code;
};

alt_meth can => (
    class => sub { no warnings 'misc'; goto &UNIVERSAL::can },
    obj => sub {
        my ( $self, $name ) = @_;

        my $control = Mock::Quick::Object::Control->new( $self );
        return if $control->strict && !exists $self->{$name};

        my $sub;
        {
            no warnings 'misc';
            $sub = UNIVERSAL::can( $self, $name );
        }
        $sub ||= sub {
            unshift @_ => ( shift( @_ ), $name );
            goto &call;
        };
        inject( Scalar::Util::blessed( $self ), $name, $sub );
        return $sub;
    },
);

# http://perldoc.perl.org/perlobj.html#Default-UNIVERSAL-methods
# DOES is equivalent to isa by default
sub isa     { no warnings 'misc'; goto &UNIVERSAL::isa     }
sub DOES    { goto &isa                                    }
sub VERSION { no warnings 'misc'; goto &UNIVERSAL::VERSION }

obj_meth DESTROY => sub {
    my $self = shift;
    Mock::Quick::Object::Control->new( $self )->_clean;
    unshift @_ => ( $self, 'DESTROY' );
    goto &call;
};

purge_util();

1;

__END__

=head1 NAME

Mock::Quick::Object - Object mocking for Mock::Quick

=head1 DESCRIPTION

Provides object mocking. See L<Mock::Quick> for a better interface.

=head1 SYNOPSIS

    use Mock::Quick::Object;
    use Mock::Quick::Method;

    my $obj = Mock::Quick::Object->new(
        foo => 'bar',            # define attribute
        do_it => qmeth { ... },  # define method
        ...
    );

    is( $obj->foo, 'bar' );
    $obj->foo( 'baz' );
    is( $obj->foo, 'baz' );

    $obj->do_it();

    # define the new attribute automatically
    $obj->bar( 'xxx' );

    # define a new method on the fly
    $obj->baz( Mock::Quick::Method->new( sub { ... });

    # remove an attribute or method
    $obj->baz( \$Mock::Quick::Util::CLEAR );

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Mock-Quick is free software; Standard perl licence.

Mock-Quick is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the license for more details.
