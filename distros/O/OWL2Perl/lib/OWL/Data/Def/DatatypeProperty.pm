#-----------------------------------------------------------------
# OWL::Data::Def::DatatypeProperty
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: DatatypeProperty.pm,v 1.8 2010-01-07 21:48:08 ubuntu Exp $
#-----------------------------------------------------------------
package OWL::Data::Def::DatatypeProperty;
use base qw( OWL::Base );
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.8 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

OWL::Data::Def::DatatypeProperty - definition of an owl datatype property

=head1 SYNOPSIS

 use OWL::Data::Def::DatatypeProperty;

 # create a new data type
 my $datatype = new OWL::Data::Def::DatatypeProperty
    ( name        => 'MySequenceProperty',
      domain      => 'http://some.domain.com/MySequenceDomain',
      uri         => 'http://some.domain.com/MySequenceProperty',
      range       => 'http://some.domain.com/MySequence',
      parent      => 'http://some.domain.com/MySequencePropertyParent',
    );

 # get the name of this datatype property
 print $datatype->name;


=cut

=head1 DESCRIPTION

A container representing an OWL datatype property definition

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------
# A list of allowed attribute names. See OWL::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<OWL::Base>. Here just a list of them:

=over

=item B<name>

A name of this datatype property

=item B<parent>

A parent for this datatype property ... defaults to OWL::Data::OWL::DatatypeProperty

=item B<domain>

The domain of this datatype property

=item B<range>

The range of this datatype property

=item B<uri>

The uri of this datatype property

=back

=cut

{
	my %_allowed = (
		uri => {
			type => OWL::Base->STRING,
			post => sub {
				my ($self) = shift;
				my $package =
				  $self->oProperty2module( $self->uri2package( $self->uri ) );
				$self->{module_name} = $package;

				# extract our name and set it
				my $name = $1 if $package =~ m|\:\:(\w+)$|gi;
				$name = $package unless $name;
				$self->{name} = $name;
			  }
		},
		parent => {
			type => OWL::Base->STRING,
			post => sub {
				my ($self) = shift;
				my $name = $self->parent;
				$self->{module_parent} =
				  $self->oProperty2module(
										 $self->uri2package( $self->{parent} ) )
				  unless $self->{parent} eq 'OWL::Data::OWL::DatatypeProperty';
				$self->{module_parent} = $self->{parent}
				  if $self->{parent} eq 'OWL::Data::OWL::DatatypeProperty';
			},
		},
		domain => { type => OWL::Base->STRING, },
		name   => {
			type => OWL::Base->STRING,
			post => sub {
				my ($self) = shift;
				my $package =
				  $self->oProperty2module( $self->uri2package( $self->{name} ) );
				# extract our name and set it
				my $name = $1 if $package =~ m|\:\:(\w+)$|gi;
				$name = $package unless $name;
				$self->{name} = $name;
			  }
		},
		range => { type => OWL::Base->STRING, },

# used internally  (but cannot start with underscore - Template would ignore them)
		module_name   => undef,
		module_parent => undef,
	);

	sub _accessible {
		my ( $self, $attr ) = @_;
		exists $_allowed{$attr} or $self->SUPER::_accessible($attr);
	}

	sub _attr_prop {
		my ( $self, $attr_name, $prop_name ) = @_;
		my $attr = $_allowed{$attr_name};
		return ref($attr) ? $attr->{$prop_name} : $attr if $attr;
		return $self->SUPER::_attr_prop( $attr_name, $prop_name );
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
	$self->parent('OWL::Data::OWL::DatatypeProperty');
}
1;
__END__
