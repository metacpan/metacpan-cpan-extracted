package Padre::Plugin::ParserTool::Dialog;

use 5.008;
use strict;
use warnings;
use Params::Util                   ();
use Padre::Plugin::ParserTool::FBP ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin::ParserTool::FBP';

use constant {
	WHITE => Wx::Colour->new('#FFFFFF'),
	GREEN => Wx::Colour->new('#CCFFCC'),
	RED   => Wx::Colour->new('#FFCCCC'),
};





######################################################################
# Padre::Plugin::ParserTool::FPB Methods

sub refresh {
	my $self = shift;

	# Reset all dialog colours
	$self->module->SetBackgroundColour(WHITE);
	$self->function->SetBackgroundColour(WHITE);
	$self->dumper->SetBackgroundColour(WHITE);
	$self->output->SetBackgroundColour(WHITE);

	# Check the module
	my $module = $self->module->GetValue;
	unless ( Params::Util::_CLASS($module) ) {
		$self->module->SetBackgroundColour(RED);
		return $self->fail("Missing or invalid module '$module'");
	}

	# Load the module
	SCOPE: {
		local $@;
		eval "require $module";
		if ($@) {
			$self->module->SetBackgroundColour(RED);
			return $self->fail("Failed to load '$module': $@");
		}
		$self->module->SetBackgroundColour(GREEN);
	}

	# Call the code
	local $@;
	my $code = $self->function->GetValue;
	my $rv   = do {
		local $_ = $self->input->GetValue;
		eval $code;
	};
	if ($@) {
		$self->function->SetBackgroundColour(RED);
		return $self->fail("Failed to execute '$code': $@");
	}
	$self->function->SetBackgroundColour(GREEN);

	# Serialize the output
	local $@;
	my $dumper = $self->{dumper}->GetStringSelection;
	my $output = '';
	my $error  = '';
	if ( $dumper eq 'Stringify' ) {
		$output = eval { defined $rv ? "$rv" : 'undef'; };
		$error = "Exception during stringification: $@" if $@;

	} elsif ( $dumper eq 'Data::Dumper' ) {
		eval {
			require Data::Dumper;
			$output = Data::Dumper::Dumper($rv);
		};
		$error = "Exception during Data::Dumper: $@" if $@;

	} elsif ( $dumper eq 'Devel::Dumpvar' ) {
		eval {
			require Devel::Dumpvar;
			$output = Devel::Dumpvar->new(
				to => 'return',
			)->dump($rv);
		};
		$error = "Exception during Devel::Dumpvar: $@" if $@;

	} elsif ( $dumper eq 'PPI::Dumper' ) {
		eval {
			unless ( Params::Util::_INSTANCE( $rv, 'PPI::Element' ) )
			{
				die "Not a PPI::Element object";
			}
			require PPI::Dumper;
			$output = PPI::Dumper->new($rv)->string;
		};
		$error = "Exception during PPI::Dumper: $@" if $@;

	} else {
		$error = "Unknown or unsupported dumper '$dumper'";
	}
	if ($error) {
		$self->dumper->SetBackgroundColour(RED);
		return $self->fail($error);
	}

	# Print the output
	$self->dumper->SetBackgroundColour(GREEN);
	$self->output->SetValue($output);

	return 1;
}

sub fail {
	my $self = shift;
	$self->output->SetBackgroundColour(RED);
	$self->output->SetValue(shift);
}

1;
