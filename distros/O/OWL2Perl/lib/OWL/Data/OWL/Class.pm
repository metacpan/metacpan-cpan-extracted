#-----------------------------------------------------------------
# OWL::Data::OWL::Class
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: Class.pm,v 1.11 2010-02-10 23:19:11 ubuntu Exp $
#-----------------------------------------------------------------
package OWL::Data::OWL::Class;
use base ("OWL::Base");
use strict;
use URI;

# imports
use RDF::Core::Statement;
use RDF::Core::Model;
use RDF::Core::Storage::Memory;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.13 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

OWL::Data::OWL::Class

=head1 SYNOPSIS

 use OWL::Data::OWL::Class;

 # create an owl class 
 my $data = OWL::Data::OWL::Class->new ();


=head1 DESCRIPTION

An object representing an OWL class

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------
# A list of allowed attribute names. See OWL::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<OWL::Base>. Here just a list of them:

=over

=item B<label> an optional RDF label for this class

=item B<type> a URI that describes the type of this class

=item B<value> a URI to an individual of this class (same as uri, e.g. if you set this, you set value too)

=item B<uri> a URI to an individual of this class (same as value, e.g. if you set this, you set uri too)

=item B<strict> a boolean value that determines whether or not to enforce class constraints. Default is false.

=back

=cut

{
	my %_allowed = (
	   # the RDFS label for this node
	   label  => { type => OWL::Base->STRING },
	   type  => { type => OWL::Base->STRING },
		# value and uri are synonyms here
		value => {
			type => OWL::Base->STRING,
			post => sub {
				my $self = shift;
				$self->{uri} = $self->value;
				# set the id portion of the ID
                $self->ID($self->{value});
			  }
		},
		# value and uri are synonyms here
		uri => {
			type => OWL::Base->STRING,
			post => sub {
				my $self = shift;
				$self->{value} = $self->uri;
				# set the id portion of the ID
				$self->ID($self->{value});
			  }
		},
		ID => {
			type => OWL::Base->STRING,
            post => sub {
                my $self = shift;
                my $id = undef;
                # id is either text after leftmost :
                $id = $1 if ($self->{ID} =~ m|.*/\w+:(.*)$|gi);
                # or item after #
                $id = $1 if not defined $id and ($self->{ID} =~ m|#(.*)$|gi);
                # or item after /
                $id = $1 if not defined $id and ($self->{ID} =~ m|.*/(.*)$|gi);
                $id = $1 if not defined $id and ($self->{ID} =~ m|^\s*([[:alnum:]]+)\s*$|gi);
                $self->{ID} = $id;
              }
		},
		strict => {type => OWL::Base->BOOLEAN,},
		# used internally / set during _get_statements
		subject => { type => 'RDF::Core::Resource' },
		model   => { type => 'RDF::Core::Model' },
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
	$self->strict(0);
	$self->model(new RDF::Core::Model( Storage => new RDF::Core::Storage::Memory ));
}

#-------------------------------------------------------------------
# get an RDF::Core::Enumerator object or undef if there are no statements
#-------------------------------------------------------------------
sub _get_statements {
	return undef;
}

#-------------------------------------------------------------------
# returns a hash reference with possible keys: datatypes, objects
#-------------------------------------------------------------------
sub __properties {
	return {};
}

=head2 clear_statements

clear_statements: clears statements from class; however, this does not remove properties.

=cut

sub clear_statements {
    my ($self) = shift;
    $self->model(new RDF::Core::Model( Storage => new RDF::Core::Storage::Memory ));
}



1;
__END__
