#-----------------------------------------------------------------
# OWL::Data::Def::OWLClass
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: OWLClass.pm,v 1.22 2010-01-07 21:48:08 ubuntu Exp $
#-----------------------------------------------------------------
package OWL::Data::Def::OWLClass;
use base qw( OWL::Base );
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.24 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

OWL::Data::Def::OWLClass - definition of an owl class

=head1 SYNOPSIS

 use OWL::Data::Def::OWLClass;

 # create a new data type
 my $class = new OWL::Data::Def::OWLClass
    ( name        => 'MySequenceClass',
      type        => 'http://some.domain.com/classes#MySequenceClass',
      parent      => 'http://some.domain.com/classes#MySequenceClassParent',
    );

 # get the name of this owl class
 print $class->name;


=cut

=head1 DESCRIPTION

A container representing an OWL class definition

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

A name of this owl class

=item B<parent>

A parent for this owl class ... defaults to OWL::Data::OWL::Class

=item B<type>

The type of this owl class

=back

=cut

{
	my %_allowed = (
		name => {
			# name set when you set the type!
			type => OWL::Base->STRING,
		},
		parent => {
			type => OWL::Base->STRING,
			post => sub {
				my ($self) = shift;
				my $name = @{$self->parent}[-1];
				return unless defined $name;
#				$name = 'OWL::Data::OWL::Class' unless defined $name;
				if ($name eq 'OWL::Data::OWL::Class') {
					# add to parents array
                    $self->add_module_parent($name);
				} else {
				    # add to parents array
				    $self->add_module_parent($self->owlClass2module( $self->uri2package($name) ));
				}
			},
			is_array => 1,
		},
		type => {
			type => OWL::Base->STRING,
			post => sub {
				my ($self) = shift;
				my $package = $self->uri2package($self->type);
				$self->{module_name} = $self->owlClass2module($package);
				# extract our name and set it
				my $name = $1 if $package =~ m|\:\:(\w+)$|gi;
				$name = $package unless $name; 
				$self->name($name);
				# bnodes are typed differently than URI nodes
				$self->{type} = "" if $package =~ m/^genid/ig;
			  }
		},
		# HashOfHash: property_name => {keys: object, range, name, module}
		has_value_property => {type => 'HASH', is_array => 1 },
		object_properties =>
		  { type => 'OWL::Data::Def::ObjectProperty', is_array => 1 },
		datatype_properties =>
		  { type => 'OWL::Data::Def::DatatypeProperty', is_array => 1 },

# used internally  (but cannot start with underscore - Template would ignore them)
        # the full package name for this class
		module_name   => undef,
		# the full package names for parents
		module_parent => { type => OWL::Base->STRING, is_array => 1 },
		# HashOfHash: property_name => {keys: name, max, min}
        cardinality_constraints => {type => 'HASH', is_array => 0 },
        # hash: key: onProperty, value: hash of restrictionURI strings as module names as keys with the value of 1
        values_from_property => {type => 'HASH' },
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
	$self->add_parent('OWL::Data::OWL::Class');
	# initialize empty hash for cardinality_constraints
	$self->cardinality_constraints(\());
	$self->values_from_property(\());
}
1;
__END__
