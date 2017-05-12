package Scope::Session::Flyweight;

use warnings;
use strict;

our $VERSION = '0.01';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use base qw/Scope::Session::Singleton/;

sub import{
    my ($class,%args ) = @_;
    my ($caller)      = caller 0;
    if( $args{'acquire'} and $caller ne 'main'){
        no strict 'refs';
        push @{"$caller\::ISA"}, 'Scope::Session::Flyweight::_Base';
    }
    $class->SUPER::import;
}

{
    package Scope::Session::Flyweight::_Base;
    sub acquire{
        my ($class,@args) = @_;
        return Scope::Session::Flyweight->acquire( $class => @args );
    }
}
sub acquire {
    my $self = ( blessed $_[0] ) ? shift : shift->instance;
    my ( $target_class, @args ) = @_;
    my $key = _compose_key( $target_class, $target_class->identifier(@args) );
    if ( defined( my $ret = $self->_get_stash($key) ) ) {
        return $ret;
    }
    else {
        my $object = $target_class->new(@args);
        $self->_set_stash( $key => $object );
    }
}

sub _get_stash {
    my ( $self, $key ) = @_;
    return $self->{$key} ;
}

sub _set_stash {
    my ( $self, $key , $obj) = @_;
    $self->{$key} = $obj;
}

sub _compose_key {
    my ( $target_class, $instance_identifier ) = @_;
    Crap::croak( 'no identifier') unless $instance_identifier;
    return sprintf( 'scope-session-flyweight:%s#%s', $target_class, $instance_identifier );
}
1; # End of Scope::Session::Flyweight

__END__

=head1 NAME

Scope::Session::Flyweight - Attach light-weight instance creation for Scope::Session

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

work as factory

    use Scope::Session::Flyweight;
    my $flyweight
        = Scope::Session::Flyweight->acquire( q|Test::Object| => ( id => 10 ) );
    my $flyweight2
        = Scope::Session::Flyweight->acquire( q|Test::Object| => ( id => 10 ) );


work as role

    package Test::Object;
    use Scope::Session::Flyweight acquire => 1;
    sub identifier {
        my ( $class, %args ) = @_;
        return $args{id};
    }
    sub new {
        my ( $class, %args ) = @_;
        return bless {%args} => $class;
    }
    my $flyweight  = Test::Object->acquire( id => 10 );
    my $flyweight2 = Test::Object->acquire( id => 10 );

=head1 METHODS

=head2 acquire

=head1 TARGET CLASS

target class must be implemented following methods.

=head2 indentifier

get constructor options and return object identity string.

=head2 new

create instance

get a same identifier instance

=cut


=head1 AUTHOR

Daichi Hiroki, C<< <hirokidaichi<AT>gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Daichi Hiroki.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


