package Net::RRP::Request;

use strict;
use Net::RRP::Exception::MissingCommandOption;
use Net::RRP::Exception::MissingRequiredEntity;
$Net::RRP::Request::VERSION = (split " ", '# 	$Id: Request.pm,v 1.4 2000/09/11 15:34:14 mkul Exp $	')[3];

=head1 NAME

Net::RRP::Request - rrp request abstraction class

=head1 SYNOPSIS

 use Net::RRP::Request;
 my $request = new Net::RRP::Request;

=head1 DESCRIPTION

This is a base class for all Request::* classes.

=cut

=head2 new

The constructor. You can pass entity && options attributes to this method. Example:

 my $request = new Net::RRP::Request ( entity  => new Net::RRP::Entity ( .... ),
                                       options => { key => 'value' } );
 my $request1 = new Net::RRP::Request ( );

=cut

sub new
{
    my ( $class, %params ) = @_;
    bless { %params }, $class;
}

=head2 getName

Return a *real* name of this request. You must overwrite this method at child class. Example:

 my $requestName = $request->getName();
 print STDERR "EntityName is $requestName\n";

=cut

sub getName
{
    die "Must be implemented at child class";
}

=head2 setEntity

Setup the rrp entity for this request. Example:

 $request->setEntity ( new Net::RRP::Entity ( ... ) );

=cut

sub setEntity
{
    my ( $this, $entity ) = @_;
    my $old = $this->{entity};
    $this->{entity} = $entity;
    $old;
}

=head2 getEntity

Return a entity of this request. Example:

 my $entity = $request->getEntity();

Can throw Net::RRP::Exception::MissingRequiredEntity exception

=cut

sub getEntity
{
    my $this = shift;
    $this->{entity} || throw Net::RRP::Exception::MissingRequiredEntity();
}

=head2 getOption

Return a request option by $optionName. Example:

 print $request->getOption ( $optionName ); 
 print $request->getOption ( 'ttt' ); # no '-' here

Can throw Net::RRP::Exception::MissingCommandOption() exception.

=cut

sub getOption
{
    my ( $this, $optionName ) = @_;
    $this->{options}->{ lc ( $optionName ) } || throw Net::RRP::Exception::MissingCommandOption();
}

=head2 setOption

Set $optionName rrp request option to the $optionValue. Example:

 $request->setOption ( $optionName =>  $optionValue );
 $request->setOption ( tt => 'qq' );

=cut

sub setOption
{
    my ( $this, $optionName, $optionValue ) = @_;
    $optionName = lc ( $optionName );
    my $old = $this->{options}->{$optionName};
    $this->{options}->{$optionName} = $optionValue;
    $old;
}

=head2 getOptions

Return a hash ref to the request options. Example:

 my $options = $request->gtOptions();
 map { print "$_ = " . $options->{$_} } keys %$options;

=cut

sub getOptions
{
    my $this = shift;
    $this->{options}
}

=head2 isSuccessResponse

Return a true if response is successfull.

 my $protocol = new Net::RRP::Protocol ( .... );
 my $request  = new Net::RRP::Request::Add ( .... );
 $protocol->sendRequest ( $request );
 my $response = $protocol->getResponse ();
 die "error" unless $request->isSuccessResponse ( $response );

=cut

sub isSuccessResponse
{
    my ( $this, $response ) = @_;
    return 0 unless $response;
    return { 200 => 1, 220 => 1 }->{ $response->getCode() };
}

1;


=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Request (C) Michael Kulakov, Zenon N.S.P. 2000
                       125124, 19, 1-st Jamskogo polja st,
                       Moscow, Russian Federation

                       mkul@cpan.org

 All rights reserved.

 You may distribute this package under the terms of either the GNU
 General Public License or the Artistic License, as specified in the
 Perl README file.

=head1 SEE ALSO

L<Net::RRP::Entity(3)>, L<Net::RRP::Response(3)>, L<Net::RRP::Codec(3)>, RFC 2832,
L<Net::RRP::Exception::MissingCommandOption(3)>, L<Net::RRP::Exception::MissingRequiredEntity(3)>

=cut

__END__

