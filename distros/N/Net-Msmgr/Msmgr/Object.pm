#
# $Id: Object.pm,v 0.16 2003/08/07 00:01:59 lawrence Exp $
# 

package Net::Msmgr::Object;
use 5.006;
use strict;
use warnings;

use Carp;
our $AUTOLOAD;

sub _fields { return () } ; 

sub AUTOLOAD
{
    my $self = shift;
    my $type = ref($self) or croak "$self is not an ojbect";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    unless (exists$self->{_permitted}->{$name} )
    {
	croak "Cannot access `$name' field in class $type";
    }

    if (@_)
    {
	return $self->{$name} = shift;
    }
    else
    {
	return $self->{$name}
    }
}

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless({}, $class);

    if ($class eq 'Object')
    {
	croak "Do not instantiate an object.  Derive from it.";
    }

    my @fields = $self->_fields;
    while (@fields)
    {
	my ($k, $v) = splice(@fields, 0, 2);
	$self->{_permitted}->{$k} = $v;
	$self->{$k} = $v;
    }
    while (@_)
    {
	my ($k, $v) = splice(@_,0,2);
	$self->$k($v);
    }
    return $self;

}

sub DESTROY {};

1;


#
# $Log: Object.pm,v $
# Revision 0.16  2003/08/07 00:01:59  lawrence
# Initial Release
#
#


