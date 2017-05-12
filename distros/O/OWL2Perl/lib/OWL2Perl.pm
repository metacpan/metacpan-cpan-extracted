#-----------------------------------------------------------------
# OWL2Perl
# Author: Edward Kawas
# For copyright and disclaimer see below.
#
# $Id: OWL2Perl.pm,v 1.36 2010-03-09 18:04:43 ubuntu Exp $
#-----------------------------------------------------------------
package OWL2Perl;
use strict 'vars';

# add versioning to this module
use vars qw{$VERSION};

BEGIN {
	use vars qw{@ISA @EXPORT @EXPORT_OK};
	$VERSION           = 1.00;
	*OWL2Perl::VERSION = *VERSION;
}

use FindBin qw( $Bin );
use lib $Bin;

use OWL::Base;
use base qw/OWL::Base/;

use OWL::Data::Def::ObjectProperty;
use OWL::Data::Def::DatatypeProperty;
use OWL::Data::Def::OWLClass;
use OWL::Generators::GenOWL;
use OWL::Utils;

use ODO::Parser::XML;
use ODO::Graph::Simple;
use ODO::Ontology::OWL::Lite;
use ODO::Graph::Simple;
use ODO::Node;
use ODO::Ontology::OWL::Lite::Restriction;

#-----------------------------------------------------------------
# A list of allowed attribute names. See OWL::Base for details.
#-----------------------------------------------------------------
{
	my %_allowed = (
		outdir         => { type => OWL::Base->STRING, 
			post=> sub {
				my $self = shift;
				# if $dir is undefined, make it the default
				my $dir = $self->{outdir};
				$self->{outdir} = $OWLCFG::GENERATORS_OUTDIR || 
				    OWL::Utils->find_file( $Bin, 'generated')
				  unless defined $dir;
			}},
		force          => { type => OWL::Base->BOOLEAN },
		follow_imports => { type => OWL::Base->BOOLEAN },

		# private
		_imports_added => undef,
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
# init
#-----------------------------------------------------------------
sub init {
	my ($self) = shift;
	$self->SUPER::init();

	# defaults for some variables ...
	$self->force(0);
	$self->outdir($OWLCFG::GENERATORS_OUTDIR || OWL::Utils->find_file( $Bin, 'generated'));
	$self->follow_imports(0);
	$self->{_imports_added} = ();
}

###################################################################
# consumes an OWL::Ontology::Lite object and an optional scalar ref
# If $code given, no code written to output directory, otherwise
# code written to scalar.
###################################################################
sub generate_datatypes {
	my ( $self, $lite, $code ) = @_;

	# process the object properties
	$LOG->info("\tProcessing object properties");
	my $oProps = $self->_process_object_properties( $lite, $code );

	# process the datatype properties
	$LOG->info("\tProcessing datatype properties");
	my $dProps = $self->_process_datatype_properties( $lite, $code );

	# process the owl classes
	$LOG->info("\tProcessing owl classes");
	$self->_process_classes( $lite->classMap, $oProps, $dProps, $code );
}

# private sub
sub _process_object_properties {
	my ( $self, $lite, $code ) = @_;
	my %objectProperties = %{ $lite->objectPropertyMap };
	my %oProperties;
	foreach my $key ( keys %objectProperties ) {
		my $object = $objectProperties{$key};
		next
		  unless defined $object->{'object'}
			  and UNIVERSAL::isa( $object->{'object'}, 'ODO::Node::Resource' );
		my $property = new OWL::Data::Def::ObjectProperty;

		# set the uri / uri sets the name too
		$property->uri($key);
		if ( defined $object->{'domain'} and @{ $object->{'domain'} } > 0 ) {
			my $range = shift @{ $object->{'domain'} };
			$property->domain($range);
		}
		if ( defined $object->{'range'} and @{ $object->{'range'} } ) {
			my $range = shift @{ $object->{'range'} };
			$property->range($range);
		}
		if ( defined $object->{'inheritance'}
			 and @{ $object->{'inheritance'} } > 0 )
		{
			my $parent = $object->{'inheritance'}->[0] || '';
			if ( UNIVERSAL::isa( $parent, 'ODO::Node::Resource' ) ) {
				$parent = $parent->value;
			}
			$parent = 'OWL::Data::OWL::ObjectProperty'
			  if $parent eq
				  'http://www.w3.org/1999/02/22-rdf-syntax-ns#Property';
			$property->parent($parent);
		}
		my $generator = OWL::Generators::GenOWL->new();
		if ( defined $code ) {
			$generator->generate_object_property(
												  property   => $property,
												  outcode    => $code,
												  force_over => $self->force(),
			);
		} else {
			$generator->generate_object_property(
												  property    => $property,
												  force_over  => $self->force(),
												  impl_outdir => $self->outdir()
			) if $self->outdir();
			$generator->generate_object_property(
												  property   => $property,
												  force_over => $self->force(),
			) unless $self->outdir();
		}
		$oProperties{$key} = $property;
	}
	return \%oProperties;
}

#private sub
sub _process_datatype_properties {
	my ( $self, $lite, $code ) = @_;
	my %objectProperties = %{ $lite->datatypePropertyMap };
	my %dProperties;
	foreach my $key ( keys %objectProperties ) {
		my $object = $objectProperties{$key};
		next
		  unless defined $object->{'object'}
			  and UNIVERSAL::isa( $object->{'object'}, 'ODO::Node::Resource' );
		my $property = new OWL::Data::Def::DatatypeProperty;

		# set the uri / uri sets the name automatically
		$property->uri($key);
		if ( defined $object->{'domain'} and @{ $object->{'domain'} } > 0 ) {
			my $range = shift @{ $object->{'domain'} };
			$property->domain($range);
		}
		if ( defined $object->{'range'} and @{ $object->{'range'} } ) {
			my $range = shift @{ $object->{'range'} };
			$property->range($range);
		}
		if ( defined $object->{'inheritance'}
			 and @{ $object->{'inheritance'} } > 0 )
		{
			my $parent = $object->{'inheritance'}->[0] || '';
			if ( UNIVERSAL::isa( $parent, 'ODO::Node::Resource' ) ) {
				$parent = $parent->value;
			}
			$parent = 'OWL::Data::OWL::DatatypeProperty'
			  if $parent eq
				  'http://www.w3.org/1999/02/22-rdf-syntax-ns#Property';
			$property->parent($parent);
		}
		my $generator = OWL::Generators::GenOWL->new();
		if ( defined $code ) {
			$generator->generate_datatype_property(
													property   => $property,
													outcode    => $code,
													force_over => $self->force(),
			);
		} else {
			$generator->generate_datatype_property(
												  property    => $property,
												  force_over  => $self->force(),
												  impl_outdir => $self->outdir()
			) if $self->outdir();
			$generator->generate_datatype_property(
													property   => $property,
													force_over => $self->force(),
			) unless $self->outdir();
		}
		$dProperties{$key} = $property;
	}
	return \%dProperties;
}

# private sub
sub _process_classes {
	my ( $self, $lite, $oProps, $dProps, $code ) = @_;

	# $lite, oProps and dProps are hash refs ...
	my %classes = %{ $lite };
	#my %classes = %{ $lite->classMap };
	my %dProperties;
	foreach my $key ( keys %classes ) {
		my $object = $classes{$key};
		# we only process ODO Nodes
		next
		  unless defined $object->{'object'}
			  and UNIVERSAL::isa( $object->{'object'}, 'ODO::Node::Resource' );
		my $class = new OWL::Data::Def::OWLClass;
		# dont want to add the same property multiple times for a class
		my %added_properties;

		# set the uri / this also sets the name
		$class->type($key);

		# process inheritance
		if ( defined $object->{'inheritance'}
			 and @{ $object->{'inheritance'} } > 0 )
		{
			foreach my $parent ( @{ $object->{'inheritance'} } ) {
				$class->add_parent($parent);
			}
		}

		# process equivalent classes - either string or ODO::EquivalentClass
		if ( defined $object->{'equivalent'}
			 and @{ $object->{'equivalent'} } > 0 )
		{
			foreach my $equivalent ( @{ $object->{'equivalent'} } ) {
				if (
					 UNIVERSAL::isa(
						  $equivalent,
						  'ODO::Ontology::OWL::Lite::Fragments::EquivalentClass'
					 )
				  )
				{

					#   perl object
					my $key = $equivalent->{'restrictionURI'};
					if (     defined $classes{$key}
						 and defined $classes{$key}->{'object'} )
					{

						# add to parents ... this $key will be auto generated
						$class->add_parent($key);
					} else {

						# suck in the restrictions
						if ( $dProps->{ $equivalent->{'onProperty'} } ) {
							my $dp = $dProps->{ $equivalent->{'onProperty'} };
							# FIXME
							$class->add_datatype_properties($dp);
						} elsif ( $oProps->{ $equivalent->{'onProperty'} } ) {
                            my $op = $oProps->{ $equivalent->{'onProperty'} };
                            # FIXME
                            $class->add_object_properties($op);
                        } else {
							# is this a Bnode with a someValuesFrom clause in it?
							# construct a new bnode object and add a restriction to
							# then add this bnode class to $class parent 
							
							# check for some things first
							next unless defined $equivalent->{'restrictionURI'};
							next unless defined $equivalent->{'someValuesFrom'} 
							     and ( defined $classes{$equivalent->{'someValuesFrom'}} and defined $classes{$equivalent->{'someValuesFrom'}}->{'object'} );
							# should do the following, but sometimes the item is a url ...
							# next unless $oProps->{ $equivalent->{'onProperty'} } or $dProps->{ $equivalent->{'onProperty'} };
							
							# construct our hash
							my $bnode_hash;
							$bnode_hash->{object} = new ODO::Node::Blank($equivalent->{'restrictionURI'});
							$bnode_hash->{equivalent} = [];
							$bnode_hash->{restrictions} = [];
							$bnode_hash->{inheritance} = [];
							my %bnode_intersection;
							$bnode_intersection{classes} = [];
							my $propertyName = $equivalent->{'onProperty'};
							$propertyName = $1 if $propertyName =~ m/\w+[#\/]+(\w+)$/ or $propertyName =~ m/\w+[#\/]+(\w+)$/;
							$bnode_intersection{restrictions} = [
							     ODO::Ontology::OWL::Lite::Restriction->new(
							         onProperty=>$equivalent->{'onProperty'},
							         restrictionURI=>$equivalent->{'someValuesFrom'},
							         propertyName=> $propertyName,
							     )
							];
							$bnode_hash->{intersections} = \%bnode_intersection;
							# generate an impl for this bnode
							$self->_process_classes({$equivalent->{'restrictionURI'} => $bnode_hash}, $oProps, $dProps, $code);
							$class->add_parent($equivalent->{'restrictionURI'});
						}
					}
				} else {

					# string
					my $key = $equivalent;
					if (     defined $classes{$key}
						 and defined $classes{$key}->{'object'} )
					{

						# add to parents ... this $key will be auto generated
						$class->add_parent($key);
					} else {

						# suck in the restrictions
						$LOG->warn("equivalent(else->else):->$key\n");
						foreach my $restrict ( @{ $object->{'restrictions'} } )
						{
							next if defined $added_properties{$restrict->{'onProperty'}};
							$added_properties{$restrict->{'onProperty'}} = 1;
							if ( $dProps->{ $restrict->{'onProperty'} } ) {
								my $dp = $dProps->{ $restrict->{'onProperty'} };
								$class->add_datatype_properties($dp);
							} else {
								my $op = $oProps->{ $restrict->{'onProperty'} };
								$class->add_object_properties($op);
							}
						}
					}
				}
			}
		}

# process intersections - read in the equivalent classes and suck out their attributes ... put them on this class
		if ( defined $object->{'intersections'}
			 and @{ $object->{'intersections'}->{'classes'} } > 0
			 or @{ $object->{'intersections'}->{'restrictions'} } > 0 )
		{
			foreach
			  my $restrict ( @{ $object->{'intersections'}->{'restrictions'} } )
			{
				# TODO if the restriction is a someValuesFrom, then:
				# add the onProperty to object/datatype_properties
				# stop processing
				if (defined $restrict->{'onProperty'} ){ #and not defined $added_properties{$restrict->{'onProperty'}}) {
					# check if $restrict->{'hasValue'} ? add the hasValue to class : process restriction
	                if (defined $restrict->{'hasValue'}) {
	                    # add hasValue: extract the value, 
	                    my $o = OWL::Utils->trim($restrict->{'hasValue'});
	                    my $p = $restrict->{'onProperty'};
	                    my $range = $restrict->{'range'};
	                    my %hv_hash;
	                    $hv_hash{object} = $o;
	                    $hv_hash{range} = $range;
	                    $hv_hash{name} = $restrict->{'propertyName'};
	                    if ( $dProps->{ $restrict->{'onProperty'} } ) {
	                    	$hv_hash{module} = $self->oProperty2module( $self->uri2package( $p ) );
	                    } else {
		                    $hv_hash{module} = $self->oProperty2module( $self->uri2package( $range ) ) if $range;
		                    $hv_hash{module} = 'OWL::Data::OWL::Class' unless $range;	
	                    }
	                    $class->add_has_value_property(\%hv_hash);
	                    # no next, because we use the has_value stuff to init our stuff
	                }
					if ( $dProps->{ $restrict->{'onProperty'} } ) {
						my $dp = $dProps->{ $restrict->{'onProperty'} };
						# extract any cardinality constraints
						if ( defined $restrict->{'minCardinality'} or defined $restrict->{'maxCardinality'}) {
							my $min = $restrict->{'minCardinality'} || '0';
							my $max = $restrict->{'maxCardinality'} || undef;
							my $hash;
							$hash->{min} = $min if defined $min;
							$hash->{max} = $max if defined $max;
							$hash->{name} = $restrict->{'propertyName'};
							my $hoh = $class->cardinality_constraints();
							$hoh->{$restrict->{'propertyName'}} = $hash;
							$class->cardinality_constraints($hoh);
						}
	
						# add someValuesFrom, allValuesFrom to inheritance
						$class->add_datatype_properties($dp) unless defined $added_properties{$restrict->{'onProperty'}};
					} elsif ($oProps->{ $restrict->{'onProperty'} }) {
						my $op = $oProps->{ $restrict->{'onProperty'} };
	                    # extract any cardinality constraints
	                    if (defined $restrict->{'minCardinality'} or defined $restrict->{'maxCardinality'}) {
	                        my $min = $restrict->{'minCardinality'} || '0';
	                        my $max =$restrict->{'maxCardinality'} || undef;
	                        my $hash;
	                        $hash->{min} = $min if defined $min;
	                        $hash->{max} = $max if defined $max;
	                        $hash->{name} = $restrict->{'propertyName'};
	                        my $hoh = $class->cardinality_constraints();
	                        $hoh->{$restrict->{'propertyName'}} = $hash;
	                        $class->cardinality_constraints($hoh);
	                    }
	                    # add the valuesFrom to values_from_properties
	                    if (defined $restrict->{'someValuesFrom'} and defined $restrict->{'propertyName'}) {
	                        my $pname = $restrict->{'propertyName'};
	                        my $svf = $self->owlClass2module( $self->uri2package($restrict->{'someValuesFrom'}) );
	                        my $vfp_hash = $class->values_from_property() || ();
	                        if (exists $vfp_hash->{$pname}) {
	                            $vfp_hash->{$pname} = {%{$vfp_hash->{$pname}}, "$svf" => 1};
	                            $class->values_from_property($vfp_hash);
	                        } else {
	                            $vfp_hash->{$pname} = {$svf => 1};
	                            $class->values_from_property($vfp_hash);
	                        }
	                    }
	                    $class->add_object_properties($op) unless defined $added_properties{$restrict->{'onProperty'}};
					} else {
						$LOG->warn(sprintf("Trying to use property, '%s', but it was not imported in your ontology!", $restrict->{'onProperty'}));
					}
					$added_properties{$restrict->{'onProperty'}} = 1;
				} else {
					# just a bnode? check if it exists
					$class->add_parent($restrict->{restrictionURI}) if defined $classes{$restrict->{restrictionURI}};
				}
				
			}
			foreach my $iClass ( @{ $object->{'intersections'}->{'classes'} } )
			{
				$class->add_parent($iClass);
			}
		}

# process unions - read in the equivalent classes and suck out their attributes ... put them on this class
        if ( defined $object->{'unions'}
             and @{ $object->{'unions'}->{'classes'} } > 0
             or @{ $object->{'unions'}->{'restrictions'} } > 0 )
        {
            foreach
              my $restrict ( @{ $object->{'unions'}->{'restrictions'} } )
            {
            	# TODO if the restriction is a someValuesFrom, then:
                # add the onProperty to object/datatype_properties
                # stop processing
                next unless defined $restrict->{'onProperty'};
                # next if defined $added_properties{$restrict->{'onProperty'}};

                # check if $restrict->{'hasValue'} ? add the hasValue to class : process restriction
                if (defined $restrict->{'hasValue'}) {
                    # add hasValue: extract the value, 
                    my $o = OWL::Utils->trim($restrict->{'hasValue'});
                    my $p = $restrict->{'onProperty'};
                    my $range = $restrict->{'range'};
                    my %hv_hash;
                    $hv_hash{object} = $o;
                    $hv_hash{range} = $range;
                    $hv_hash{name} = $restrict->{'propertyName'};
                    if ( $dProps->{ $restrict->{'onProperty'} } ) {
                        $hv_hash{module} = $self->oProperty2module( $self->uri2package( $p ) );
                    } else {
                        $hv_hash{module} = $self->oProperty2module( $self->uri2package( $range ) ) if $range;
                        $hv_hash{module} = 'OWL::Data::OWL::Class' unless $range;   
                    }
                    
                    $class->add_has_value_property(\%hv_hash);
                    # no next, because we use the has_value stuff to init our stuff
                }
                if ( $dProps->{ $restrict->{'onProperty'} } ) {
                    my $dp = $dProps->{ $restrict->{'onProperty'} };
                    # extract any cardinality constraints
                    if ( defined $restrict->{'minCardinality'} or defined $restrict->{'maxCardinality'}) {
                        my $min = $restrict->{'minCardinality'} || '0';
                        my $max = $restrict->{'maxCardinality'} || undef;
                        my $hash;
                        $hash->{min} = $min if defined $min;
                        $hash->{max} = $max if defined $max;
                        $hash->{name} = $restrict->{'propertyName'};
                        my $hoh = $class->cardinality_constraints();
                        $hoh->{$restrict->{'propertyName'}} = $hash;
                        $class->cardinality_constraints($hoh);
                    }

                    $class->add_datatype_properties($dp) unless defined $added_properties{$restrict->{'onProperty'}};
                } elsif ($oProps->{ $restrict->{'onProperty'} }) {
                    my $op = $oProps->{ $restrict->{'onProperty'} };
                    # extract any cardinality constraints
                    if (defined $restrict->{'minCardinality'} or defined $restrict->{'maxCardinality'}) {
                        my $min = $restrict->{'minCardinality'} || '0';
                        my $max =$restrict->{'maxCardinality'} || undef;
                        my $hash;
                        $hash->{min} = $min if defined $min;
                        $hash->{max} = $max if defined $max;
                        $hash->{name} = $restrict->{'propertyName'};
                        my $hoh = $class->cardinality_constraints();
                        $hoh->{$restrict->{'propertyName'}} = $hash;
                        $class->cardinality_constraints($hoh);
                    }
                    # add the valuesFrom to values_from_properties
                    if (defined $restrict->{'someValuesFrom'} and defined $restrict->{'propertyName'}) {
                            my $pname = $restrict->{'propertyName'};
                            my $svf = $self->owlClass2module( $self->uri2package($restrict->{'someValuesFrom'}) );
                            my $vfp_hash = $class->values_from_property() || ();
                            if (exists $vfp_hash->{$pname}) {
                                $vfp_hash->{$pname} = {%{$vfp_hash->{$pname}}, "$svf" => 1};
                                $class->values_from_property($vfp_hash);
                            } else {
                                $vfp_hash->{$pname} = {$svf => 1};
                                $class->values_from_property($vfp_hash);
                            }
                    }
                    $class->add_object_properties($op) unless defined $added_properties{$restrict->{'onProperty'}};
                } else {
                    $LOG->warn(sprintf("Trying to use property, '%s', but it was not imported in your ontology!", $restrict->{'onProperty'}));
                }
                $added_properties{$restrict->{'onProperty'}} = 1;
            }
            foreach my $iClass ( @{ $object->{'unions'}->{'classes'} } )
            {
                $class->add_parent($iClass);
            }
        }

		# process the restriction
		if ( defined $object->{'restrictions'}
			 and @{ $object->{'restrictions'} } )
		{
			foreach my $restrict ( @{ $object->{'restrictions'} } ) {
				next unless defined $restrict->{'onProperty'};
				#next if defined $added_properties{$restrict->{'onProperty'}};
				# check if $restrict->{'hasValue'} ? add the hasValue to class : process restriction
				if (defined $restrict->{'hasValue'}) {
					# add hasValue: extract the value, 
                    my $o = OWL::Utils->trim($restrict->{'hasValue'});
                    my $p = $restrict->{'onProperty'};
                    my $range = $restrict->{'range'};
                    my %hv_hash;
                    $hv_hash{object} = $o;
                    $hv_hash{range} = $range;
                    $hv_hash{name} = $restrict->{'propertyName'};
                    if ( $dProps->{ $restrict->{'onProperty'} } ) {
                        $hv_hash{module} = $self->oProperty2module( $self->uri2package( $p ) );
                    } else {
                        $hv_hash{module} = $self->oProperty2module( $self->uri2package( $range ) ) if $range;
                        $hv_hash{module} = 'OWL::Data::OWL::Class' unless $range;   
                    }
                                        
                    $class->add_has_value_property(\%hv_hash);
                    # no next, because we use the has_value stuff to init our stuff
				}
				if ( $dProps->{ $restrict->{'onProperty'} } ) {
					my $dp = $dProps->{ $restrict->{'onProperty'} };
					# FIXME
					# extract any cardinality constraints
                    if ( defined $restrict->{'minCardinality'} or defined $restrict->{'maxCardinality'}) {
                        my $min = $restrict->{'minCardinality'} || '0';
                        my $max = $restrict->{'maxCardinality'} || undef;
                        my $hash;
                        $hash->{min} = $min if defined $min;
                        $hash->{max} = $max if defined $max;
                        $hash->{name} = $restrict->{'propertyName'};
                        my $hoh = $class->cardinality_constraints();
                        $hoh->{$restrict->{'propertyName'}} = $hash;
                        $class->cardinality_constraints($hoh);
                    }
					$class->add_datatype_properties($dp) unless defined $added_properties{$restrict->{'onProperty'}};
				} elsif ( $oProps->{ $restrict->{'onProperty'} } ) {
					my $op = $oProps->{ $restrict->{'onProperty'} };
					# FIXME
					# extract any cardinality constraints
                    if (defined $restrict->{'minCardinality'} or defined $restrict->{'maxCardinality'}) {
                        my $min = $restrict->{'minCardinality'} || '0';
                        my $max = $restrict->{'maxCardinality'} || undef;
                        my $hash;
                        $hash->{min} = $min if defined $min;
                        $hash->{max} = $max if defined $max;
                        $hash->{name} = $restrict->{'propertyName'};
                        my $hoh = $class->cardinality_constraints();
                        $hoh->{$restrict->{'propertyName'}} = $hash;
                        $class->cardinality_constraints($hoh);
                    }
					$class->add_object_properties($op) unless defined $added_properties{$restrict->{'onProperty'}};
				} elsif ( $oProps->{ $restrict->{'restrictionURI'} } ) {

					# FIXME hack ...
					my $op = $oProps->{ $restrict->{'restrictionURI'} };
					$class->add_parent($op)
					  if defined $classes{ $restrict->{'restrictionURI'} };
				}
				$added_properties{$restrict->{'onProperty'}} = 1;
			}
		}
		
#use Data::Dumper; $LOG->info(Dumper($class)) if defined $class->values_from_property();

		my $generator = OWL::Generators::GenOWL->new();
		if ( defined $code ) {
			$generator->generate_class(
										class      => $class,
										outcode    => $code,
										force_over => $self->force(),
			);
		} else {
			$generator->generate_class(
										class       => $class,
										force_over  => $self->force(),
										impl_outdir => $self->outdir()
			) if $self->outdir();
			$generator->generate_class(
										class      => $class,
										force_over => $self->force(),
			) unless $self->outdir();
		}
	}
}

############################################################
# consumes an array ref of URLs and a base_uri (optional;  # 
# defaults to the currently processed URL) and returns the # 
# ODO::Ontology::OWL::Lite object                          #
############################################################

sub process_owl {
	my ( $self, $urls, $base_uris ) = @_;
	# initialize $base_uris if it is not already
	$base_uris = [] unless defined $base_uris;
	my $counter = -1;
	my $GRAPH_schema      = ODO::Graph::Simple->Memory();
    my $GRAPH_source_data = ODO::Graph::Simple->Memory();
	for my $url (@$urls) {
		$counter++;
		next unless defined $url;
		$LOG->info( 'Obtaining OWL ontology from: ' . $url );
	
		# if passed a file, make it a file url
		if (-e $url and -f $url) {
			$url = "file://$url";
		}
	
		my $owl;
		eval {
			$LOG->info('Downloading OWL file');
			$owl = OWL::Utils::getHttpRequestByURL($url);
		};
		$self->throw("Error obtaining ontology ('$url'): $@") if $@;
		# parse the owl document
		my ( $statements, $imports ) =
	      ODO::Parser::XML->parse(
	         $owl,
	         base_uri   => defined $base_uris->[$counter]? $base_uris->[$counter] : $url,
	         sax_parser => defined $OWLCFG::XML_PARSER ? $OWLCFG::XML_PARSER : undef
	    );
	
		$GRAPH_schema->add($statements);
		$self->{_imports_added}{$url} = 1;
	
		# process imports
		if ( $self->follow_imports() ) {
			foreach my $i (@$imports) {
				$i =~ s/#*$//gi;
	
				# skip imports we have already processed
				next if $self->{_imports_added}{$i};
				$self->_process_import( $GRAPH_schema, $i );
			}
		}
	}

	# create the 'stuff'
	$LOG->info('Aggregating ontologies ...');
	my $SCHEMA =
	  ODO::Ontology::OWL::Lite->new(
									 graph        => $GRAPH_source_data,
									 schema_graph => $GRAPH_schema,
									 schemaName   => '',
									 verbose      => $LOG->is_info()
	);
	return $SCHEMA;  
}

# private sub
sub _process_import {
	my ( $self, $GRAPH_schema, $import ) = @_;
	$import =~ s/#*$//gi;
	$LOG->info("\tProcessing import $import");
	my $owl = OWL::Utils::getHttpRequestByURL($import);
	my ( $statements, $imports ) =
	  ODO::Parser::XML->parse(
		 $owl,
		 base_uri   => $import,
		 sax_parser => defined $OWLCFG::XML_PARSER ? $OWLCFG::XML_PARSER : undef
	  );
	$GRAPH_schema->add($statements);
	foreach my $i (@$imports) {
		$i =~ s/#*$//gi;

		# skip imports we have already processed
		next if $self->{_imports_added}{$i};
		$self->{_imports_added}{$i} = 1;
		$self->_process_import( $GRAPH_schema, $i );
	}
}
1;

__END__

=head1 NAME

OWL2Perl - Perl extension for the automatic generation of perl modules from OWL classes

=cut

=head1 SYNOPSIS

 # to get started, run the install script (do this only once, upon initial install)
 owl2perl-install.pl

 # load the OWL2Perl module
 use OWL2Perl;

 # instantiate an OWL2Perl module
 # we will output to /tmp/ and follow ontology imports
 my $owl2perl = OWL2Perl->new(
    outdir => '/tmp/',
    follow_imports => 1,
 );

 # get the output directory
 my $outdir = $owl2perl->outdir();

 # set the output directory
 $owl2perl->outdir($outdir);

 # do we follow imports?
 print 'following imports', "\n" if $owl2perl->follow_imports();

 # parse an OWL document that we will generate modules for
 # we will parse the URL: http://sadiframework.org/ontologies/records.owl
 my $ontology_url = 'http://sadiframework.org/ontologies/records.owl';

 # this may take minutes to complete
 my $ontology = $owl2perl->process_owl([$ontology_url]);

 # generate the actual Perl modules
 $owl2perl->generate_datatypes($ontology);

 # generate the actual Perl modules (for print to STDOUT)
 my $out = '';
 $owl2perl->generate_datatypes($ontology, \$out);
 print STDOUT $out;

=cut

=head1 DESCRIPTION

A module to aid in the genesis of Perl modules that represent OWL entities in
OWL ontologies.

=head2 Upgrading from a version prior to Version 0.97

For those of you upgrading from a version prior to version 0.97, you B<will> need to 
regenerate your modules for any OWL ontologies that you use. This latest version of
OWL2Perl utilizes new methods for serializing OWL/RDF and is not compatible with previous
versions. The generated modules themselves should still behave as expected and should not
have changed too much (except for the additional perldoc in each generated class).

=head2 Upgrading from a version prior to Version 0.96

For those of you upgrading from a version prior to version 0.96, you may need to 
regenerate your modules for any OWL ontologies that you use. 

Not every one will need to regenerate their source code. Only those of you that
use owl:hasValue and owl:maxCardinality property restrictions. Even if you use
these constructs, you dont have to regenerate your source code unless you want
OWL2Perl to catch those instances where you may provide I<too many> property 
restrictions or where you don't explicitly provide the I<hasValue> restriction.

=cut

=head2 OWL2Perl Installation

Assuming that you have already installed this package, the very first thing
that you should do is run the script C<owl2perl-install.pl>.

This script will do the following:

=over 4

=item Check your system for prerequisite modules

=item Run you through the configuration of the OWL2Perl module

=item Create the logging and generator configuration files

=back

Once the installation process is complete you can generate Perl modules for 
your ontology!

=cut

=head2 Bits and Pieces

=head3 Requirements

The following modules (all available from CPAN) are required for the proper
function of this module:

=over 4

=item Carp

=item File::Spec    

=item File::Path

=item File::HomeDir

=item File::ShareDir

=item Config::Simple

=item Log::Log4perl

A great port of the Log4j and enables logging in OWL2Perl

=item HTTP::Date  

=item Template

This wonderful module is used to construct the templates for our OWL entities.

=item Params::Util

=item Scalar::List::Utils (also known as Scalar::Util)

There may be a problem obtaining the latest version of this module on windows.
The most recent available version (on PPM) for windows is suffice to get this 
working.

=item Class::Inspector

=item Unicode::String

=item IO::String

=item RDF::Core

This module is used to serialize the OWL entities as RDF/XML.

=item LS

=item HTTP::Request

=item LWP

=item PLUTO

This groundbreaking module is used to parse OWL documents.

=item URI

=back

=cut

=head3 Scripts

=head4 owl2perl-install.pl

The install script is installed at module install time and is available from
any command prompt. You should run this script the very first time you install
this module on your system and you can run it anytime later. The files that are
already created will not be overwritten - unless you want them to be!

A typical outcome of running this script is shown below:

=begin html

<pre>
C:\Users\Eddie\Documents&gt;owl2perl-install
Welcome! Preparing stage for OWL2Perl ...
------------------------------------------------------
OK. Module Carp is installed.
OK. Module File::Spec is installed.
OK. Module Config::Simple is installed.
OK. Module File::HomeDir is installed.
OK. Module File::ShareDir is installed.
OK. Module Log::Log4perl is installed.
OK. Module HTTP::Date is installed.
OK. Module Template is installed.
OK. Module Params::Util is installed.
OK. Module Class::Inspector is installed.
OK. Module Unicode::String is installed.
OK. Module IO::String is installed.
OK. Module RDF::Core is installed.
OK. Module Term::ReadLine is installed.

Installing in C:\Users\Eddie\Perl-OWL2Perl <br/>
Created install directory &#39;C:\Users\Eddie\Perl-OWL2Perl&#39;.<br/>
Logging property file created: &#39;C:/Users/Eddie/Perl-OWL2Perl/log4perl.properties&#39;.<br/>
Created generated &#39;C:/Users/Eddie/Perl-OWL2Perl/generated&#39;.<br/>
Configuration file created: &#39;C:\Users\Eddie\Perl-OWL2Perl\owl2perl-config.cfg&#39;.<br/>
Done.<br/>
C:\Users\Eddie\Documents&gt;
</pre>

=end html

On windows, the script is available on your PATH as C<owl2perl-install> with
no B<.pl> extension.

=cut

=head4 owl2perl-generate-modules.pl

This script is a simple way for you to generate Perl modules representing your
OWL entities.

Running the script without parameters provides you with details on how to use
this particular script:

=begin html

<pre>
C:\Users\Eddie\Documents&gt;owl2perl-generate-modules
Subroutine XML::Namespace::rdf redefined at C:/Perl/site/lib/XML/Namespace.pm line 54.
Generate perl modules from OWL files.
Usage: [-vdsib] [-o outdir] owl-class-file
       [-vdsi] [-o outdir] -u owl-class-url<br />
    -u ... owl is from url
    -s ... show generated code on STDOUT
           (no file is created, disabled when no data type name given)<br />
    -b ... option to specify the base uri for the owl document (you will be prompted)<br />
    -i ... follow owl import statements<br />
    -v ... verbose
    -d ... debug
    -h ... help<br />
Note: This script requires that the PERL module ODO, from IBM Semantic Layered
      Research Platform be installed on your workstation! ODO is available on CPAN
      as PLUTO.<br /><br />
C:\Users\Eddie\Documents&gt;
</pre>

=end html

As you can see, this helper script helps you generate the Perl modules from OWL
documents. 

An obvious question to ask at this point, is 'Where are these modules
generated'?

You can always determine this after generation by looking into your LOG file;
the generator has verbose output using the INFO level which means that it is
almost always logged. But if you want to know in advance, here are the rules:

=over 4

=item generators.outdir

This parameter in the configuration file, if defined, is the location of the
directory where the Perl modules are created.

=item 'generated' directory

If there is no generators.outdir defined in the configuration file, then the
generator tries to locate an existing directory named 'generated' anywhere in
the @INC (a set of directories used by Perl to locate its modules).

=item When all else fails

the generator creates a new directory 'generated' in the 'current' directory.

=back

B<Usage>:

C<owl2perl-generate-modules.pl [-vdsib] [-o outdir] owl-class-file>

C<owl2perl-generate-modules.pl [-vdsib] [-o outdir] -u owl-class-url>

There are many command line switches available to those of you running this
script:

=over 4

=item -u 

owl is from url

=item -s

show generated code on STDOUT (no file is created)

=item -b

specify the base uri for the owl document (you will be prompted for it)

=item -i

follow owl import statements

=item -v

verbose

=item -d

debug

=item -h

show help

=back

=cut

=cut

=cut

=cut

=head1 Getting Started

The very first thing that you need to do upon initial installation of this 
module is to run the script C<owl2perl-install.pl> that comes bundled with 
this module. This script is available on your PATH upon installation of this
module. 

You will only need to run this script once (unless we tell you 
otherwise). This script ensures that the correct dependencies are available on
your machine. As well, the script sets up a directory in your home directory 
under the name Perl-OWL2Perl/ and places some configuration files in it. These
configuration files help you specify the XML parser that should be used, places
to save generated files, and much more.

To generate Perl modules representing OWL classes from your ontology, you can 
do 1 of 2 things! Use the 

=over 4

=item owl2perl-generate-modules.pl script 

This script is included with this distribution and placed on your PATH upon 
installation of this module, or

=item OWL2Perl

Use this module and programmatically do what owl2perl-generate-modules.pl does.

=back

Regardless of the method that you choose, the outcome is the (hopefully) same;
create a set of modules that can be integrated into your perl project that
represent OWL entities in your ontology!

For a quick overview of what the owl2perl-generate-modules.pl script can do,
please take a look at the html document that can be found at
doc/working_with_datatypes.html. This file contains a quick overview that can
get you started quite quickly.

=cut

=head1 Subroutines

=head2 new()

Instantiate an OWL2Perl object.

Inputs:

=over 4

=item outdir (optional)

The output directory for our generated Perl modules. This parameter over-rides
the one in the OWL2Perl configuration file (generated when you ran 
owl2perl-install.pl after installing the module).

=item force (optional)

Boolean, 0 or 1 to determine whether or not we should over-write pre-existing 
generated files of the same name. The default is 0.

=item follow_imports (optional)

Boolean, 0 or 1 to determine whether or not owl:import statements should be 
followed during the C<process_owl>. The default is 0, e.g. not to follow.

=back

=cut

=head2 process_owl($url_array_ref, $baseuri_array_ref)

The subroutine, C<generate_datatypes>, consumes an L<ODO::Ontology::OWL::Lite> 
object and can be hard to set up by yourself. The subroutine C<process_owl>
is here to help you out.

Inputs: 

=over 4

=item $url_array_ref 

an array reference of URLs or absolute file locations for the ontology to be 
parsed.

=item $baseuri_array_ref 

an array reference of base URIs for your ontology (optional). If a URL is 
specified, then the current base URI is that URL unless you specify one 
yourself. Please not that if your ontology specifies a base URI, then this
parameter is ignored.

=back

Outputs:

=over 4

=item an C<ODO::Ontology::OWL::Lite> object created by parsing the input URL.

=back

=cut

=head2 generate_datatypes($ontology, $scalar_ref)

This subroutine produces the Perl modules representing OWL entities parsed by 
L<PLUTO>. The generated modules will either be saved to disk or represented by
$scalar_ref, depending on whether you setup an output directory and if you 
passed in a scalar_ref.

Inputs:

=over 4

=item $ontology 

an C<ODO::Ontology::OWL::Lite> object created from your ontology.

=item $scalar_ref 

an optional reference to a scalar to hold the generated code.

=back

Outputs: Nothing... well, like I said earlier, either the modules are written
to disk or the passed in scalar reference will contain the modules as a string.

=cut

=head1 COPYRIGHT

Copyright (c) 2010, Edward Kawas
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.
    * Neither the name of the University of British Columbia nor the names of 
      its contributors may be used to endorse or promote products derived from 
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.

=cut
