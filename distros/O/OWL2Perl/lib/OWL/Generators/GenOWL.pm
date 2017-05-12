#-----------------------------------------------------------------
# OWL::Generators::GenOWL
# Author: Edward Kawas <edward.kawas@gmail.com>
#
# For copyright and disclaimer see below.
#
# $Id: GenOWL.pm,v 1.15 2010-01-07 21:51:51 ubuntu Exp $
#-----------------------------------------------------------------
package OWL::Generators::GenOWL;
use OWL::Utils;
use OWL::Data::Def::ObjectProperty;
use OWL::Base;
use base qw( OWL::Base );
use FindBin qw( $Bin );
use lib $Bin;
use Template;
use File::Spec;
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.15 $ =~ /: (\d+)\.(\d+)/;

#-----------------------------------------------------------------
# A list of allowed attribute names. See OWL::Base for details.
#-----------------------------------------------------------------
{
	my %_allowed = ( outdir => undef );

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
	$self->outdir( $OWLCFG::GENERATORS_OUTDIR
				   || OWL::Utils->find_file( $Bin, 'generated' ) );
}

#-----------------------------------------------------------------
# generate_object_property
#-----------------------------------------------------------------
sub generate_object_property {
	my ( $self, @args ) = @_;
	my %args = (    # some default values
		impl_outdir => (
			  $OWLCFG::GENERATORS_OUTDIR || OWL::Utils->find_file( $Bin, 'generated' )
		),
		impl_prefix => 'OWL::Data::Property',
		force_over  => 0,
		static_impl => 0,

		# other args, with no default values
		# outcode       => ref SCALAR
		# and the real parameters
		@args
	);
	my $property = $args{property};
	$self->_check_outcode(%args);
	my $outdir = File::Spec->rel2abs( $args{impl_outdir} );

	# generate from template
	my $tt = Template->new( ABSOLUTE => 1 );
	my $input = OWL::Utils->find_file( $Bin, 'OWL', 'Generators', 'templates',
										'owl-object-property.tt' );
	my $name = $property->name();
	$LOG->debug("\tGenerating object property for $name\n");
	my $module_name = $property->module_name();

	# create implementation specific object
	my $impl = { package => $module_name, };
	if ( $args{outcode} ) {
		$tt->process(
					  $input,
					  {
						 obj         => $property,
					  },
					  $args{outcode}
		) || $LOG->logdie( $tt->error() );
	} else {
		my $outfile =
		  File::Spec->catfile( $outdir, split( /::/, $impl->{package} ) ) . '.pm';

		# do not overwrite an existing file (there may be already
		# a real implementation code)
		if ( -f $outfile and !$args{force_over} ) {
			$LOG->logwarn(   "Implementation '$outfile' already exists. "
						   . "It will *not* be re-generated. Safety reasons.\n" );
            return;
		}
		$tt->process(
					  $input,
					  {
						 obj         => $property,
					  },
					  $outfile
		) || $LOG->logdie( $tt->error() );
		$LOG->debug("Created $outfile\n");
	}
}

#-----------------------------------------------------------------
# generate_class
#-----------------------------------------------------------------
sub generate_class {
    my ( $self, @args ) = @_;
    my %args = (    # some default values
        impl_outdir => (
              $OWLCFG::GENERATORS_OUTDIR || OWL::Utils->find_file( $Bin, 'generated' )
        ),
        force_over  => 0,
        static_impl => 0,

        # other args, with no default values
        # outcode       => ref SCALAR
        # and the real parameters
        @args
    );
    my $property = $args{class};
    $self->_check_outcode(%args);
    my $outdir = File::Spec->rel2abs( $args{impl_outdir} );

    # generate from template
    my $tt = Template->new( ABSOLUTE => 1 );
    my $input = OWL::Utils->find_file( $Bin, 'OWL', 'Generators', 'templates',
                                        'owl-class.tt' );
    my $name = $property->name();
    $LOG->debug("\tGenerating module for owl class $name\n");
    my $module_name = $property->module_name();

    # create implementation specific object
    my $impl = { package => $module_name, };
    if ( $args{outcode} ) {
        $tt->process(
                      $input,
                      {
                         obj         => $property,
                      },
                      $args{outcode}
        ) || $LOG->logdie( $tt->error() );
    } else {
        my $outfile =
          File::Spec->catfile( $outdir, split( /::/, $impl->{package} ) ) . '.pm';

        # do not overwrite an existing file (there may be already
        # a real implementation code)
        if ( -f $outfile and !$args{force_over} ) {
            $LOG->logwarn(   "Implementation '$outfile' already exists. "
                           . "It will *not* be re-generated. Safety reasons.\n" );
            return;
        }
        $tt->process(
                      $input,
                      {
                         obj         => $property,
                      },
                      $outfile
        ) || $LOG->logdie( $tt->error() );
        $LOG->info("Created $outfile\n");
    }
}

#-----------------------------------------------------------------
# generate_datatype_property
#-----------------------------------------------------------------
sub generate_datatype_property {
    my ( $self, @args ) = @_;
    my %args = (    # some default values
        impl_outdir => (
              $OWLCFG::GENERATORS_OUTDIR || OWL::Utils->find_file( $Bin, 'generated' )
        ),
        impl_prefix => 'OWL::Data::Property',
        force_over  => 0,
        static_impl => 0,

        # other args, with no default values
        # outcode       => ref SCALAR
        # and the real parameters
        @args
    );
    my $property = $args{property};
    $self->_check_outcode(%args);
    my $outdir = File::Spec->rel2abs( $args{impl_outdir} );

    # generate from template
    my $tt = Template->new( ABSOLUTE => 1 );
    my $input = OWL::Utils->find_file( $Bin, 'OWL', 'Generators', 'templates',
                                        'owl-datatype-property.tt' );
    my $name = $property->name();
    $LOG->debug("\tGenerating datatype property for $name\n");
    my $module_name = $property->module_name();

    # create implementation specific object
     my $impl = { package => $module_name, };
    if ( $args{outcode} ) {
        $tt->process(
                      $input,
                      {
                         obj         => $property,
                      },
                      $args{outcode}
        ) || $LOG->logdie( $tt->error() );
    } else {
        my $outfile =
          File::Spec->catfile( $outdir, split( /::/, $impl->{package} ) ) . '.pm';

        # do not overwrite an existing file (there may be already
        # a real implementation code)
        if ( -f $outfile and !$args{force_over} ) {
            $LOG->logwarn(   "Implementation '$outfile' already exists. "
                           . "It will *not* be re-generated. Safety reasons.\n" );
            return;
        }
        $tt->process(
                      $input,
                      {
                         obj         => $property,
                      },
                      $outfile
        ) || $LOG->logdie( $tt->error() );
        $LOG->debug("Created $outfile\n");
    }
}

#-----------------------------------------------------------------
# _check_outcode
#    throws an exception if %args has an 'outcode' of a wrong type
#-----------------------------------------------------------------
sub _check_outcode {
	my ( $self, %args ) = @_;
	$self->throw("Parameter 'outcode' should be a reference to a SCALAR.")
	  if $args{outcode} and ref( $args{outcode} ) ne 'SCALAR';
}
1;
__END__

=head1 NAME

OWL::Generators::GenOWL - generator of OWL modules

=head1 SYNOPSIS

 use OWL::Generators::GenOWL;

=head1 DESCRIPTION

A generator of OWL modules. This module contains the 'guts' of what is needed to generate PERL modules from OWL entities. 

=head1 AUTHORS, COPYRIGHT, DISCLAIMER

Edward Kawas (edward.kawas [at] gmail [dot] com)

Copyright (c) 2010 Edward Kawas. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided "as is" without warranty of any kind.

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<OWL::Base>. Here just a list of them:

=over

=item B<outdir> A directory where to create generated code.

=back

=head1 SUBROUTINES

=over

=item generate_object_property

=back

=cut

