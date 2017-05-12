#-----------------------------------------------------------------
# OWL::Data::Object
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Object.pm,v 1.2 2010-01-07 21:46:39 ubuntu Exp $
#-----------------------------------------------------------------

package OWL::Data::Object;
use base ("OWL::Base");
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

OWL::Data::Object

=head1 SYNOPSIS

 use OWL::Data::Object;

 # create an object with a namespace of NCBI_gi and id 545454
 my $data = OWL::Data::Object->new (namespace=>"NCBI_gi", id=>"545454");

 # set/get an article name for this data object
 $data->name ('myObject');
 print $data->name;

 # set/get an id for this data object
 $data->id ('myID');
 print $data->id;

 # check if this data object is a primitive type
 print "a primitive" if $data->primitive;
 print "not a primitive" if not $data->primitive;

 # get a formatted string representation of this data object
 print $data->toString;

=head1 DESCRIPTION

An object representing an owl object (usually consisting of a namespace and id)

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)
 Martin Senger (martin.senger [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------
# A list of allowed attribute names. See OWL::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<OWL::Base>. Here just a list of them:

=over

=item B<namespace>

=item B<id>

=item B<name>

An article name for this datatype. Note that the article name depends
on the context where this object is used.


=item B<primitive>

A boolean property indicating if this data type is a primitive owl
type or not.

=back

=cut

{
    my %_allowed =
	(
	 id                  => undef,
	 namespace           => undef,
     primitive           => {type => OWL::Base->BOOLEAN},
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------

=head1 SUBROUTINES

=cut

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->id ('');
    $self->namespace ('');
    $self->primitive ('no');
}


# return the same value as given (but others may override it - eg,
# Boolean changes here 1 to 'true'

sub _express_value {
    shift;
    shift;
}


1;
__END__
