package SADI::Simple::UnitTest;
{
  $SADI::Simple::UnitTest::VERSION = '0.15';
}

use strict;
use base ("SADI::Simple::Base");

=head1 NAME

SADI::Simple::UnitTest - A module that encapsulates unit test information for sadi services.

=head1 SYNOPSIS

 use SADI::Simple::UnitTest;

 # create a new blank SADI UnitTest object
 my $data = SADI::Simple::UnitTest->new ();

 # create a new primed SADI UnitTest object
 $data = SADI::Simple::UnitTest->new (
     regex  => '(\w+)+',
     xpath  => '/xml/text()',
     input  => '<xml/>',
     output => '<xml/>',
 );

 # get the unit test regex
 my $regex = $data->regex;
 # set the regex statement for this test
 $data->regex($regex);

 # get the unit test xpath statement
 my $xpath = $data->xpath;
 # set the xpath statement for this test
 $data->regex($xpath);

 # get input for this test
 my $input = $data->input;
 # set the input for this test
 $data->input($input);

 # get expected output for this test
 my $output = $data->output;
 # set the expected output for this test
 $data->output($output);

=head1 DESCRIPTION

An object representing a SADI service unit test.

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------
# A list of allowed attribute names. See SADI::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<SADI::Base>. Here just a list of them (additionally
to the attributes from the parent classes)

=over

=item B<input>

The input for this unit test. Input is required, because without it, there can be no test 

=item B<output>

The expected output of this service given the specified input.

=item B<regex>

A regular expression that should match the output of the service given the specified input.

=item B<xpath>

An xpath expression that should yield return results given the specified input.

=back

=cut

{
	my %_allowed = (
		input       => { type => SADI::Base->STRING },
		output      => { type => SADI::Base->STRING },
		regex       => { type => SADI::Base->STRING },
		xpath       => { type => SADI::Base->STRING },
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

	# set any defaults here 

}

1;

__END__
