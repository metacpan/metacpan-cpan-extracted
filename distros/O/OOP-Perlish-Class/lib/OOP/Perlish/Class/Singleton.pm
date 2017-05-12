#!/usr/bin/perl
use warnings;
use strict;
{

    package OOP::Perlish::Class::Singleton;
    use OOP::Perlish::Class;
    use Scalar::Util qw(blessed);

    use base qw(OOP::Perlish::Class);

    sub _magic_constructor_arg_handler_singleton(@)
    {
        my ( $self, $opts ) = @_;

        my $key = 'return';
        my $singleton;

        ### Handle some magical arguments used for internal purposes
        if( !exists( $opts->{_____oop_perlish_class__initialize_singleton} ) ) {
            $singleton = $self->_singleton( %{$opts} );
            return ( $key, [$singleton] );
        }
        else {
            delete( $opts->{_____oop_perlish_class__initialize_singleton} );
        }
        return;

    }

    sub _singleton(@)
    {
        my ($proto, %opts) = @_;
        my $class = ref($proto) || $proto;

        no strict 'refs';
        my $singleton = ${ $class . '::_SINGLETONREF' };
        use strict 'refs';
        if( defined($singleton) && ref($singleton) && blessed($singleton) ) {
            $singleton->debug( 'Singleton of ' . $class . ' already initialized; NOT reinitialized!!' ) if( scalar keys %opts );
            return $singleton;
        }
        else {
            $singleton = $class->new( %opts, _____oop_perlish_class__initialize_singleton => 1 );
            no strict 'refs';
            ${ $class . '::_SINGLETONREF' } = $singleton;
            use strict 'refs';
            return $singleton;
        }

        return;
    }
}
1;

__END__

=head1 NAME

OOP::Perlish::Class::Singleton

=head1 DESCRIPTION

Create a singleton class. Only one instance of this class will ever exist, no matter how many times a call is made to OOP::Perlish::Class::Singleton->new(); 
The first call will create the instance, and all subsequent calls will receive references to that first instance.

Note that all arguments passed to the constructor after initial object instantiation will be ignored. This can produce 
circumstances where the behavior of the singleton not what was expected in certain portions of code. For this reason,
Singletons should usually be stateless and/or read-only, and not have required accessors.

=head1 DIAGNOSTICS

This module will $self->debug() diagnostics; run with instance, class, or global debugging enabled (as described in OOP::Perlish::Class) in development.

=over

=item 'Singleton of ' . $class . ' already initialized; NOT reinitialized!!'

This means that more than one call to OOP::Perlish::Class::Singleton->new(%args) was made with arguments, and the arguments were ignored the second time.

=back

=head1 NAME

=head1 VERSION

=head1 SYNOPSIS

=head1 EXPORT

=head1 FUNCTIONS

=head1 AUTHOR

=head1 BUGS

=head1 SUPPORT

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE
