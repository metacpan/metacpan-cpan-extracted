package Net::RRP::Response;

use strict;
$Net::RRP::Response::VERSION = (split " ", '# 	$Id: Response.pm,v 1.6 2000/08/24 14:46:47 mkul Exp $	')[3];

=head1 NAME

    Net::RRP::Response - the base class for the Net::RRP::Response::* classes

=head1 SYNOPSIS

 use Net::RRP::Response;
 my $response = new Net::RRP::Response ();


=head1 DESCRIPTION

This is a base class of all Response::* classes. Child class must overwrite a getCode method and
setup own constrains for attributes at setAttribute method. Child classes must named 
Net::RRP::Response::nNNN, where NNN is a response number.

=cut

=head2 new

The constructor. You can setup attributes and description. Example:

 use Net::RRP::Response;
 my $response = new Net::RRP::Response ();
 my $otherResponse = new Net::RRP::Response ( attributes  => { qq => 'tt'},
					      description => 'this is a response description' );

=cut

sub new
{
    my $class = shift;
    my %options = @_ ? @_ : ( attributes  => {},
			      description => '' );
    bless { %options }, $class;
}

=head2 newFromException

Construct new response object from exception infomation;

 my $response = newFromException Net::RRP::Response ( new Net::RRP::Exception ( "description", $code ) );

=cut

sub newFromException
{
    my ( $class, $exception ) = @_;
    my $code = $exception->value;
    my $packageName = "Net\:\:RRP\:\:Response\:\:n$code";
    eval "use $packageName;"; die $@ if $@;
    $packageName->new ( description => $exception->text || ' ' );
}

=head2 getCode

This method return a code (number) of response. Must be overwrited at child classes. Example:

 my $responseNumber = $response->getCode;

=cut

sub getCode
{
    die "Must be implemented at child class";
}

=head2 getDescription

Get response description. Example:

 my $description = $response->getDescription();

=cut

sub getDescription
{
    my $this = shift;
    $this->{description};
}

=head2 setDescription

Set response description. Example:

 $response->setDescription ( 'this is a response description' );

=cut

sub setDescription
{
    my ( $this, $description ) = @_;
    my $old = $this->{description};
    $this->{description} = $description;
    $old;
}

=head2 getAttribute

Return a named response attribute. Example:

 my $attribute = $response->getAttribute ( 'name' );

=cut

sub getAttribute
{
    my ( $this, $optionName ) = @_;
    $this->{attributes}->{$optionName}
}

=head2 setAttribute

Setup a named attribute. Example:

 $response->setAttribute ( 'name' => 'value' );

=cut

sub setAttribute
{
    my ( $this, $optionName, $optionValue ) = @_;
    my $old = $this->{attributes}->{$optionName};
    $this->{attributes}->{$optionName} = $optionValue;
    $old;
}

=head2 getAttributes

Get response attributes hash ref. Example:

 my $attributes = $response->getAttributes;
 map { print "$_ = " . $attributes->{$_} } keys %$attributes;

=cut

sub getAttributes
{
    my $this = shift;
    $this->{attributes}
}

1;

=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Response (C) Michael Kulakov, Zenon N.S.P. 2000
                        125124, 19, 1-st Jamskogo polja st,
                        Moscow, Russian Federation

                        mkul@cpan.org

 All rights reserved.

 You may distribute this package under the terms of either the GNU
 General Public License or the Artistic License, as specified in the
 Perl README file.

=head1 SEE ALSO

L<Net::RRP::Entity(3)>, L<Net::RRP::Request(3)>, L<Net::RRP::Codec(3)>, L<Net::RRP::Exception(3)>, RFC 2832

=cut

__END__

