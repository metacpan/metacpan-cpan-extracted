package Net::RRP::Entity;

use strict;
use Net::RRP::Exception::MissingRequiredAttribute;
use Net::RRP::Toolkit;

$Net::RRP::Entity::VERSION = '0.02';

=head1 NAME

Net::RRP::Entity - rrp entity abstraction class

=head1 SYNOPSIS

 use Net::RRP::Entity;
 my $entity = new Net::RRP::Entity();

=head1 DESCRIPTION

This is a base class for all Entity::* classes.

=cut

=head2 new

This is a constructor. Example:

 use Net::RRP::Entity;
 my $entity = new Net::RRP::Entity();
 my $entity1 = new Net::RRP::Entity( key => [ 'value' ] );

=cut

sub new
{
    my $class = shift;
    bless { attributes => Net::RRP::Toolkit::lowerKeys ( { @_ } ) }, $class;
}

=head2 getName

Return a *real* name of this entity. You must overwrite this method at child class. Example:

 my $entityName = $entity->getName();
 print STDERR "EntityName is $entityName\n";

=cut

sub getName
{
    die "Must be implemented at child class";
}

=head2 setAttribute

Setup attribte with name $attributeName to a $attributeValue. $attributeValue must be a array ref. Example:

 $entity->setAttribute ( $attributeName, $attributeValue );
 $entity->setAttribute ( 'DomainName', [ 'test.ru' ] );
 $entity->setAttribute ( 'NameServer', [ 'ns1.ttt.ru', 'ns2.qqq.ru' ] );

=cut

sub setAttribute
{
    my ( $this, $attributeName, $attributeValue ) = @_;
    $attributeName = lc ( $attributeName );
    my $old = $this->{attributes}->{$attributeName};
    $this->{attributes}->{$attributeName} = $attributeValue;
    $old;
}

=head2 getAttribute

Return a value of $attributeName attribute. Example:

 print STDERR $entity->getAttribute ( 'NameServer' )->[ 0 ];

Can throw Net::RRP::Exception::MissingRequiredAttribute exception

=cut

sub getAttribute
{
    my ( $this, $attributeName ) = @_;
    $this->{attributes}->{ lc ( $attributeName ) } || throw Net::RRP::Exception::MissingRequiredAttribute();
}

=head2 getAttributes

Return the hash ref of the all entity attributes. Example:

 my $attributes = $entity->getAttributes();
 foreach my $attributeName ( keys %$attributes )
 {
      print $attributeName . ' ' . $attributes->{ $$attributeName }->[ 0 ];
 }

=cut

sub getAttributes
{
    my $this = shift;
    $this->{attributes};
}

=head2 getPrimaryAttributeValue

return a "primary" attribute value

=cut

sub getPrimaryAttributeValue
{
    my $this = shift;
    $this->getAttribute ( $this->getName . 'Name' );
}

1;

=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Entity (C) Michael Kulakov, Zenon N.S.P. 2000
                      125124, 19, 1-st Jamskogo polja st,
                      Moscow, Russian Federation

                      mkul@cpan.org

 All rights reserved.

 You may distribute this package under the terms of either the GNU
 General Public License or the Artistic License, as specified in the
 Perl README file.

=head1 SEE ALSO

L<Net::RRP::Request(3)>, L<Net::RRP::Response(3)>, L<Net::RRP::Codec(3)>, RFC 2832,
L<Net::RRP::Exception::MissingRequiredAttribute(3)>

=cut

__END__

