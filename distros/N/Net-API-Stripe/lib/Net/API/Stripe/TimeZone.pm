##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/TimeZone.pm
## Version 0.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::TimeZone;
BEGIN
{
	use strict;
	use DateTime::TimeZone;
	use overload ('""'     => 'name',
				  '=='     => sub { _obj_eq(@_) },
				  '!='     => sub { !_obj_eq(@_) },
				  fallback => 1,
				 );
	our( $VERSION ) = '0.1';
};

sub new
{
	my $this = shift( @_ );
	my $class = ref( $this ) || $this;
	my $init = shift( @_ );
	my $value = shift( @_ );
	my $tz = DateTime::TimeZone->new( name => $value, @_ );
	my $self = { tz => $tz };
	return( bless( $self => $class ) );
}

sub name { return( shift->{tz}->name ); }

sub _obj_eq 
{
    ##return overload::StrVal( $_[0] ) eq overload::StrVal( $_[1] );
    no overloading;
    my $self = shift( @_ );
    my $other = shift( @_ );
    return( 0 ) if( !ref( $other ) || !$other->isa( 'Net::API::Stripe::TimeZone' ) );
    my $name = $self->{tz}->name;
    my $name2 = $other->{tz}->name;
    return( 0 ) if( $name ne $name2 );
    use overloading;
    return( 1 );
}

AUTOLOAD
{
	my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
	my $self = shift( @_ );
	return( $self->{tz}->$method( @_ ) );
};

DESTROY {};

1;

__END__

