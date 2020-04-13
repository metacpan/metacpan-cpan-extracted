##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/TimeZone.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
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

=encoding utf8

=head1 NAME

Net::API::Stripe::TimeZone - A Time Zone Object

=head1 SYNOPSIS

    # or one can pass just 'local' just like for DateTime::TineZone
    my $tz = $stripe->account->settings->dashboard->timezone( 'Asia/Tokyo' );
    print( $tz->name, "\n" );
    # Asia/Tokyo
    print( "Time zone is $tz\n" );
    # produces: Time zone is Asia/Tokyo
    
    my $tz2 = $stripe->account->settings->dashboard->timezone( 'local' );
    print( "$tz is same as $tz2? ", $tz eq $tz2 ? 'yes' : 'no', "\n" );

=head1 VERSION

    0.1

=head1 DESCRIPTION

This is a wrapper around L<DateTime::TimeZone> to provide stringification. L<Net::API::Stripe::TimeZone> does not inherit from L<DateTime::TimeZone> but all method of L<DateTime::TimeZone> are accessible via the module B<AUTOLOAD>

=head1 CONSTRUCTOR

=over 4

=item B<new>( hash init, timezone )

Creates a new L<Net::API::Stripe::TimeZone> object.

=back

=head1 METHODS

=over 4

=item B<name>

This is read only. It returns the current value of the time zone.

=back

For all other methods, see the manual page of L<DateTime::TimeZone>

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<DateTime::TimeZone>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
