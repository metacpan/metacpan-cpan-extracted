package RF::Component;
our $VERSION = '1.003';


use strict;
use warnings;
use Carp;
use PDL::IO::Touchstone qw/:ALL/;
use 5.010;

our @PARAM_TYPES = qw/S Y Z H G T A/;
our %valid_opts = map { $_ => 1 } (
			@PARAM_TYPES, 
			qw/
				freqs
				z0_ref
				n_ports
				comments
				output_fmt
				orig_f_unit
				filename
				model
				value
				value_unit
				value_code_regex
				value_literal_regex
			/
		);

sub new
{
	my ($class, %args) = @_;

	#############################################
	# Compatibility cleanup from rsnp_hash values
	#

	# Name the matrix S, Z, Y, etc. based on its type:
	$args{delete $args{param_type}} = delete $args{m};

	# We don't need this, always Hz
	delete $args{funit};

	#########################
	# Required arg validation
	#
	
	foreach (keys %args)
	{
		croak "$class: invalid class option: $_ => $args{$_}" if !defined($valid_opts{$_});
	}

	my $self = bless(\%args, $class);

	if (defined($self->{value}) && ($self->{value_code_regex} || $self->{value_literal_regex}))
	{
		croak "Cannot define both value and value_(code|literal)_regex";
	}

	my @available_params = $self->_available_params;
	if (!@available_params)
	{
		croak "At least one port-parameter matrix must be provided: " . join(' ', @PARAM_TYPES);
	}

	$args{n_ports} = PDL::IO::Touchstone::n_ports($self->{$available_params[0]});

	croak "n_ports: Port count is required." if (!defined($self->{n_ports}));

	croak "z0_ref: Port impedance references are required." if (!defined($self->{z0_ref}));

	if (ref $self->{z0_ref} eq 'PDL')
	{
		my $z0 = $self->{z0_ref};
		my @dims = $z0->dims;
		if ($z0->nelem != $self->{n_ports}
			|| @dims > 1
			|| $dims[0] != $self->{n_ports})
		{
			croak "z0_ref: PDL's must be single-dimension n_port-length vectors"
		}
	}
	elsif (ref $self->{z0_ref})
	{
		croak "Unknown type for z0_ref: " . ref($self->{z0_ref});
	}
	elsif ($self->{z0_ref} <= 0)
	{
		croak "Invalid value for z0_ref: $self->{z0_ref}";
	}

	#########################
	# Optional arg validation
	#

	# Assume the part "model" is the filemodel without the .sNp suffix:
	if (defined $self->{filename})
	{
		my $model = $self->{filename};
		$model =~ s!^.*/|\.s\d+p$!!ig;
		$self->{model} //= $model;
	}

	#########################
	# Component value parsing
	#

	if (defined($self->{value_unit}) && $self->{value_unit} !~ /^[fpnumkMGTPE]?[FHR]$/)
	{
		croak "invalid unit: expected sU where 's' is an si prefix (fpnumkMGTPE) and U is (F)arad, (H)enry, or (R) for ohms";
	}

	if (defined($self->{model}) && $self->{value_code_regex} && !$self->{value_literal_regex})
	{
		$self->{value} = _parse_model_value_code($self->{model},
			$self->{value_code_regex},
			$self->{value_unit});
	}
	elsif (defined($self->{model}) && $self->{value_literal_regex} && !$self->{value_code_regex})
	{
		$self->{value} = _parse_model_value_literal($self->{model}, $self->{value_literal_regex});
	}
	elsif (!defined($self->{model}) && ($self->{value_literal_regex} || $self->{value_code_regex}))
	{
		croak "model number must be defined if you pass value_literal_regex or value_code_regex"
	}
	elsif (defined($self->{model}) && $self->{value_literal_regex} && $self->{value_code_regex})
	{
		croak "value_literal_regex and value_code_regex are mutually exclusive, use only one.";
	}
	else {} # model can be passed without a regex, but then value cannot be defined.


	if (defined($self->{value}) && $self->{value} !~ /^\d+\.?\d*|\d*\.?\d+$/)
	{
		croak("component value is not numeric: $self->{value}");
	}

	if ((defined($self->{value}) && !defined($self->{value_unit})) || 
		(!defined($self->{value}) && defined($self->{value_unit})))
	{
		croak "value must be defined when value_unit is defined, and vice-versa.";
	}

	return $self;
}

sub load
{
	my ($class, $filename, %newopts) = @_;

	croak "usage: ".__PACKAGE__."->load(...)" if ref $class;

	my $self;
	if ($filename =~ /\.s\d+p/i)
	{
		$self = $class->load_snp($filename, %newopts)
	}
	else
	{
		croak("$filename: unknown file extension");
	}

	$self->{filename} = $filename;

	return $self;
}

sub load_snp
{
	my ($class, $filename, %newopts) = @_;

	my $opts = delete $newopts{load_options};

	croak "units: RF::Component requires an internal representation of Hz" if ($opts->{units} && lc($opts->{units}) ne 'hz');

	my %args = rsnp_hash($filename, $opts);

	return $class->new(
		%newopts,
		%args
		);
}

sub save
{
	my ($self, $filename, %args) = @_;

	if ($filename =~ /\.s\d+p/i)
	{
		$self->save_snp($filename, %args)
	}
	else
	{
		croak("$filename: unknown file extension");
	}
}

sub save_snp
{
	my ($self, $filename, %args) = @_;

	my ($f, $param_type, $z0, $comments, $fmt, $output_f_unit)
		= @{$self}{qw/freqs param_type z0_ref comments output_fmt orig_f_unit/};

	$param_type = $args{param_type} if $args{param_type};
	$param_type //= 'S';
	my $m = $self->_X_param($param_type);

	$output_f_unit = $args{output_f_unit} if $args{output_f_unit};
	$fmt = $args{output_fmt} if $args{output_fmt};

	return wsnp($filename, $f, $m, $param_type, $z0, $comments, $fmt, 'Hz', $output_f_unit);
}

sub freqs { return shift->{freqs} }

sub S { return shift->_X_param('S', @_) }
sub Y { return shift->_X_param('Y', @_) }
sub Z { return shift->_X_param('Z', @_) }
sub ABCD { return shift->_X_param('A', @_) }

sub A { return shift->ABCD(1,1) }
sub B { return shift->ABCD(1,2) }
sub C { return shift->ABCD(2,1) }
sub D { return shift->ABCD(2,2) }

# Takes a port# (not an array index), so $component->z0(1) is the impedance at port1.
sub z0_ref
{
	my ($self, $port) = @_;

	return $self->{z0_ref} if !defined $port;

	croak "per-port impedances is not supported."

	# Supporting per-port impedances requires PDL::IO::Touchstone functions
	# like s_to_y($S, $z0) to support different port impedances.  Internally
	# the functions do support this, but the calling convention expects a
	# scalar so this is not easy to implement out-of-the-box.

	#my $z = pos_vec($self->{z0_ref}, $port, $port);
	#croak "z0 is not defined for port $port" if (!defined $z);
	#return $z;
}

sub num_ports { return shift->{n_ports}; }
sub num_freqs { return shift->{freqs}->nelem; }

sub model { return shift->{model}; }

sub value { return shift->{value}; }
sub value_unit { return shift->{value_unit}; }

sub comments { return @{ shift->{comments} // [] }; }

# Passthrough calls from PDL::IO::Touchstone:
sub  port_z            {  my $self = shift;   s_port_z(               $self->S, $self->{z0_ref}, @_)  }
sub  inductance        {  my $self = shift;   y_inductance(           $self->Y, $self->{freqs},  @_)  }
sub  ind_nH            {  my $self = shift;   y_ind_nH(               $self->Y, $self->{freqs},  @_)  }
sub  resistance        {  my $self = shift;   y_resistance(           $self->Y,  @_)  }
sub  esr               {  my $self = shift;   y_esr(                  $self->Y,  @_)  }
sub  capacitance       {  my $self = shift;   y_capacitance(          $self->Y, $self->{freqs},  @_)  }
sub  cap_pF            {  my $self = shift;   y_cap_pF(               $self->Y, $self->{freqs},  @_)  }
sub  qfactor_l         {  my $self = shift;   y_qfactor_l(            $self->Y, $self->{freqs},  @_)  }
sub  qfactor_c         {  my $self = shift;   y_qfactor_c(            $self->Y, $self->{freqs},  @_)  }
sub  reactance_l       {  my $self = shift;   y_reactance_l(          $self->Y, $self->{freqs},  @_)  }
sub  reactance_c       {  my $self = shift;   y_reactance_c(          $self->Y, $self->{freqs},  @_)  }
sub  reactance         {  my $self = shift;   y_reactance(            $self->Y, $self->{freqs},  @_)  }
sub  srf               {  my $self = shift;   y_srf(                  $self->Y, $self->{freqs},  @_)  }
sub  srf_ideal         {  my $self = shift;   y_srf_ideal(            $self->Y, $self->{freqs},  @_)  }
sub  is_lossless       {  my $self = shift;   abcd_is_lossless(       $self->ABCD,  @_)  }
sub  is_symmetrical    {  my $self = shift;   abcd_is_symmetrical(    $self->ABCD,  @_)  }
sub  is_reciprocal     {  my $self = shift;   abcd_is_reciprocal(     $self->ABCD,  @_)  }
sub  is_open_circuit   {  my $self = shift;   abcd_is_open_circuit(   $self->ABCD,  @_)  }
sub  is_short_circuit  {  my $self = shift;   abcd_is_short_circuit(  $self->ABCD,  @_)  }

sub interpolate
{
	my ($self, $args) = @_;

	my $f = $self->{freqs};
	my %clone = %$self;
	foreach my $t ($self->_available_params)
	{
		$clone{$t} = m_interpolate($f, $self->{$t}, $args);
	}

	return __PACKAGE__->new(%clone);
}

# return S, A, etc... based on which are defined.
sub _available_params
{
	my $self = shift;

	my @params = grep { defined $self->{$_} } @PARAM_TYPES;

	return @params if (wantarray);

	return join(' ', @params);
}

sub _parse_model_value_code
{
	my ($model, $regex, $unit) = @_;

	# The return of this function will scale the value to these well-known
	# unit types: pF|nF|uF|uH|nH|R|Ohm|Ohms
	# See industry naming conventions:
	#
	# - https://www.ttelectronics.com/TTElectronics/media/ProductFiles/ApplicationNotes/TN003-Methods-for-Coding-Resistor-Values-in-Part-Numbers.pdf
	# - https://electronics.stackexchange.com/questions/624513/inductor-and-capacitor-3-digit-exponent-value-codes-is-there-a-standard

	my %scale;
	if (lc($unit) eq 'pf') {
		$scale{R} = 1;
		$scale{N} = 1e3;
	}
	elsif (lc($unit) eq 'nf') {
		$scale{R} = 1e-3;
		$scale{N} = 1;
	}
	elsif (lc($unit) eq 'uf') {
		$scale{R} = 1e-6;
		$scale{N} = 1e-3;
	}
	elsif (lc($unit) eq 'uh') {
		$scale{R} = 1;
		$scale{N} = 1e-3;
	}
	elsif (lc($unit) eq 'nh') {
		$scale{R} = 1e3;
		$scale{N} = 1;
	}
	elsif (lc($unit) eq 'r' || lc($unit) =~ /ohms?/) {
		$scale{R} = 1;
		$scale{L} = 1e-3;
	}
	else
	{
		croak("unknown base unit for component (pF|nF|uF|uH|nH|R|Ohm|Ohms): $unit");
	}

	my $val;
	if ($model =~ /$regex/i && $1)
	{
		$val = $1;
	}
	else
	{
		carp "value_code_regex does not match: $model !~ $regex";
		return undef;
	}

	# Decimal point: 1R3 = 1.3 Ohms, 1N3 = 1.3 nH, etc.
	if ( $val =~ s/([A-Z])/./i )
	{
		my $scale = $1;
		croak "Undefined scaling type $scale for value: $val" if (!defined($scale{$scale}));

		# These are strings, so put leading/trailing zeros at the decimal:
		$val =~ s/^\./0./;
		$val =~ s/\.$/.0/;

		# Could be a string, so make it a float:
		$val *= $scale{$scale};
	}
	elsif ( $val =~ s/^(\d+)(\d)$/$1/ )
	{
		# "R" is always the base-unit scaler, so we have to multiply it in case
		# there is no alpha "decimal" point:
		$val = $1 * (10 ** $2) * $scale{R};
	}
	else
	{
		croak("$model: Value code could not be determined: '$val'");
	}

	return $val;
}

sub _parse_model_value_literal
{
	my ($model, $regex) = @_;
	my $val;

	if ( $model =~ /$regex/i && $1 )
	{
		$val = $1;
	}

	return $val;
}

sub _X_param
{
	my ($self, $X, $i, $j) = @_;

	my $m;

	# Try to find an S-matrix:
	my $S = $self->{S};
	if (!defined($S))
	{
		$S //= abcd_to_s($self->{A}, $self->z0_ref) if defined($self->{A});
		$S //= y_to_s($self->{Y}, $self->z0_ref) if defined($self->{Y});
		$S //= z_to_s($self->{Z}, $self->z0_ref) if defined($self->{Z});

		$self->{S} = $S;
	}

	# Set $m from the object if we have it, otherwise try to create $m from
	# $S.  This will fail if S is undefined.
	#
	# There is room for optimization here if you often convert directly
	# from, for example, Y to ABCD.  If this is the case then write a new
	# y_to_abcd function in PDL::IO::Touchstone and add a special for when
	# $X eq 'Y'.  However, the most common conversion is probably from S:
	$m = $self->{$X};
	if (!defined($m) && defined($S))
	{
		my $f;

		# Note that at this point here: $X ne 'S':

		$f = \&s_to_abcd if ($X eq 'A' || $X eq 'ABCD');
		$f = \&s_to_y if ($X eq 'Y');
		$f = \&s_to_z if ($X eq 'Z');

		croak "unknown (or unimplemented) RF parameter type: $X" if (!$f);

		# Convert based on the function above:
		$m = $f->($S, $self->z0_ref);

		$self->{$X} = $m;
	}

	if (!defined($m))
	{
		my $params = $self->_available_params || '(none)';
		croak("$X-parameter from available matrix is not implemented.  Available matrix types: $params");
	}

	return pos_vec($m, $i, $j) if ($i && $j);
	return $m;
}


1;

__END__

=head1 NAME

RF::Component - Compose RF component circuits and calculate values from objects (L, C, ESR, etc).

=head1 SYNOPSIS

This module builds on L<PDL::IO::Touchstone> by encapsulating data returned by its
methods into an object for easy use:

	my $cap = RF::Component->load('/path/to/capacitor.s2p', $options);
	my $wilky = RF::Component->load('/path/to/wilkinson.s3p', $options);

	# port 1 input impedances
	my $z_in = $cap->port_z(1);

	# Capacitance in pF:
	my $pF = $cap->capacitance() * 1e12

	my $S11 = $cap->S(1,1);
	my $Y21 = $cap->Y(2,1);
	my $Z33 = $wilky->Z(3,3);

	# Write a Y-parameter .s2p in mag/angle format::
	$cap->save("cap-y.s2p", param_type => 'Y', output_fmt => 'MA');

In most cases, the return value from the L<RF::Component> methods are L<PDL>
vectors, typically one value per frequency.  For example, C<$pF> as shown above
will be a N-vector of values in picofarads, with one pF value for each
frequency.

=head1 Constructor

The C<RF::Component-E<gt>load> function (below) is typically used to load RF data, but
you may pass it directly to the constructor as follows.  Most of these options 
are valid for C<RF::Component-E<gt>load> as well:

	my $c = RF::Component->new(%opts);

=head2 Required:

=over 4

=item * C<freqs>: a PDL vector, one for each frequency in Hz.

=item * C<z0_ref>: A value representing the charectaristic impedance at each port.
If port impedances differ, then this may be a vector

=item * C<n_ports>: the number of ports represented by the port parameter matrix(es):

=item * At least one (N,N,M) L<PDL> element where N is the number of ports and M
is the number of frequencies to represent complex port-parameter data:

=over 4

=item S => pdl(...) - S-Paramters

=item Y => pdl(...) - Y-Paramters

=item Z => pdl(...) - Z-Paramters

=item A => pdl(...) - ABCD-Paramters

=item H => pdl(...) - H-Paramters (not yet implemented)

=item G => pdl(...) - G-Paramters (not yet implemented)

=item T => pdl(...) - T-Paramters (not yet implemented)

=back

=back

=head2 Optional:

=over 4

=item * C<comments>: An arrayref of comments read from C<load>

=item * C<filename>: The filename read by C<load>

=item * C<output_fmt>: The .sNp output format: one of DB, MA, or RI

This is the format originally read in by C<$self-E<gt>load>.

=over 4

=item DB: dB,phase formatted

=item MA: magnitude,phase formatted

=item RI: real,imag formatted

=back

=item * C<orig_f_unit>: The original frequency unit from the .sNp file

This is the frequency format originally read in by C<$self-E<gt>load>:
kHz, MHz, GHz, THz, ...

=item * C<filename>: The filename read by C<load>

=item * C<model>: Component model number

=item * C<value_code_regex>: Regular expression to parse the exponent-value code

Specifies the variable to be assigned and a regular expression to match the
capacitance code (or other unit): NNX or NRN. X is the exponent, N is a numeric
value.

If a capacitor code is 111 then it will calculate 11*10^1 == 110 pF.  A code of
1N4 or 14N would be 1.4 or 14.0, respectively. The unit 'pF' in the example is
excluded from the code.  Example:

	MODEL-(...).s2p

The above (...) must match the code (or literal) to be placed in the MDF
variable. 

=item * C<value_literal_regex>: Regular expression to parse the literal value

The "literal" version is the same as C<value_code_regex> but does not calcualte
the code, it takes the value verbatim.  For example, some inductors specify the
number of turns in their s2p filename:

        MODEL-([0-9]+)T\.s2p

=item * C<value>: Component value

The component value is parsed based on C<value_code_regex> or
C<value_literal_regex>

=item * C<value_unit>: Unit of the value (pF, nH, etc).

This is the unit expected in C<value> afer parsing C<value_code_regex>.
Supported units: pF|nF|uF|uH|nH|R|Ohm|Ohms

=back

You may also pass the above C<new> options to the load call:

	my $cap = RF::Component->load('/path/to/capacitor.s2p', %options);


=head1 IO Functions

=head2 C<RF::Component-E<gt>load> - Load an RF data file as a component

    $cap = RF::Component->load($filename, %new_options);

Arguments:

=over 4

=item * $filename: the path to the data file you wish to load

=item * %new_options: a hash of options passed to C<RF::Component-E<gt>new> as
listed above, except the option C<load_options>:

C<load()> supports the special option C<load_options>.  If C<load_options> is
specified then it is passed to the loading function such as
C<PDL::IO::Touchstone::rsnp()>.

=back

This function loads the data based on the file extension, however,
only .sNp touchstone files are supported at this time. See the
L<rsnp()|PDL::IO::Touchstone/"IO Functions"> documentation in
L<PDL::IO::Touchstone> for specific details about C<$options>.


=head2 C<RF::Component-E<gt>load_snp> - Load a Touchstone data file as a component

This is the lower-level function called by C<RF::Component-E<gt>load>.  This
function is functionally equivalent but does not evaluate the file extension
being passed before calling C<PDL::IO::Touchstone::rsnp()>:

    $cap = RF::Component->load_snp($filename, %new_options);

=head2 C<RF::Component-E<gt>save> - Write the component to a data file

    $cap->save('cap.s2p', %options);

This function will match based on the output file extension and call the
appropriate save_* function below.  The C<%options> hash will depend on the
desired file output type.

=head2 C<RF::Component-E<gt>save_snp> - Write the component to a Touchstone data file

    $cap->save_snp('cap.s2p', %options);

=over 4

=item * C<param_type>: Supported paramter type: S, Y, Z, A

Notice: While A can be specified to write ABCD-formatted parameters, the ABCD
matrix is not officially supported by the Touchstone spec.

=item * C<output_f_unit>: The .sNp file's frequency unit.

This defaults to Hz, but supports SI units such as: KHZ, MHz, GHz, ...

=item * C<output_fmt>: See above, same as in C<new()>.

=back

=head1 Calculation Functions

Unless otherwise indicated, the return value from these methods are L<PDL>
vectors, typically one value per frequency.  For example, C<$pF> as shown above
will be a N-vector of values in picofarads, with one pF value for each
frequency.

=head2 C<$z0n = $self-E<gt>port_z($n)> - Return the complex port impedance vector for each frequency

C<$n> is the port number at which to evaluate the input impedance:

In a 2-port, this will provide the input or output impedance as follows:

    $z_in  = $self->port_z(1);
    $z_out = $self->port_z(2);

Note that the port number starts at 1, not zero.  Thus a value of C<$n=1> will
evaluate port impedance at C<S11>.

Internally this function uses the L<IO::PDL::Touchstone> C<s_port_z> function.


=head2 C<$C = $self-E<gt>capacitance> - Return a vector of capacitance for each frequency in Farads (F)

Note that all inductive values are zeroed.

Internally this function uses the L<IO::PDL::Touchstone> C<y_capacitance> function.


=head2 C<$C = $self-E<gt>cap_pF> - Return a vector of capacitance it each frequency in picofarads (pF)

Note that all capacitive values are zeroed.

Internally this function uses the L<IO::PDL::Touchstone> C<y_cap_pF> function.


=head2 C<$L = $self-E<gt>inductance> - Return a vector of inductance for each frequency in Henrys (H)

Internally this function uses the L<IO::PDL::Touchstone> C<y_inductance> function.


=head2 C<$L = $self-E<gt>ind_nH> - Return a vector of inductance for each frequency in nanohenrys (nH)

Internally this function uses the L<IO::PDL::Touchstone> C<y_ind_nH> function.


=head2 C<$Qc = $self-E<gt>qfactor_c> - Return the capacitive Q-factor vector for each frequency

Internally this function uses the L<IO::PDL::Touchstone> C<y_qfactor_c> function.


=head2 C<$Ql = $self-E<gt>qfactor_l> - Return the inductive Q-factor vector for each frequency

Internally this function uses the L<IO::PDL::Touchstone> C<y_qfactor_l> function.


=head2 C<$X = $self-E<gt>reactance> - Return a vector of total reactance for each frequency

Internally this function uses the L<IO::PDL::Touchstone> C<y_reactance> function.


=head2 C<$Xc = $self-E<gt>reactance_c> - Return a vector of capacitive reactance for each frequency

Internally this function uses the L<IO::PDL::Touchstone> C<y_reactance_c> function.


=head2 C<$Xl = $self-E<gt>reactance_l> - Return a vector of inductive reactance for each frequency

Internally this function uses the L<IO::PDL::Touchstone> C<y_reactance_l> function.


=head2 C<$R = $self-E<gt>esr> - An alias for C<y_resistance>.

Internally this function uses the L<IO::PDL::Touchstone> C<y_esr> function.


=head2 C<@srf_list_hz = $self-E<gt>srf> - Return the component's self-resonant frequencies (SRF)

To calculate SRF, reactance is evaluated at each frequency.  If the next frequency being
evaulated has an opposite sign (ie, going from capacitive to inductive reactance) then
that previous frequency is selected as an SRF.

Return value:

=over 4

=item * List context: Return the list of SRF's in ascending order, or an empty list if no SRF is found.

=item * Scalar context: Return the lowest-frequency SRF, or undef if no SRF is found.

=back

Internally this function uses the L<IO::PDL::Touchstone> C<y_srf> function.


=head2 C<$f_hz = $self-E<gt>srf_ideal> - Return the component's first self-resonant frequency

Notice: In almost all cases you will want C<$self-E<gt>srf> instead of C<$self-E<gt>srf_ideal>.

This is included for ideal Y-matrices only and may not be accurate.  While the
equation is a classic SRF calculation (1/(2*pi*sqrt(LC)), SRF should scan the
frequency lines as follows: "The SRF is determined to be the frequency at which
the insertion (S21) phase changes from negative through zero to positive."
[ L<https://www.coilcraft.com/getmedia/8ef1bd18-d092-40e8-a3c8-929bec6adfc9/doc363_measuringsrf.pdf> ]

Internally this function uses the L<IO::PDL::Touchstone> C<y_srf_ideal> function.

=head1 Helper Functions

=head2 C<$n = $self-E<gt>num_ports> - return the number of ports in this component.

=head2 C<$n = $self-E<gt>num_freqs> - return the number of frequencies in this component.

=head1 SEE ALSO

=over 4

=item L<PDL::IO::Touchstone> - The lower-level framework used by L<RF::Component>

=item L<RF::Component::Multi> - A list-encapsulation of L<RF::Component> to provide vectorized operations
on multiple components.

=item Touchstone specification: L<https://ibis.org/connector/touchstone_spec11.pdf>

=back

=head1 AUTHOR

Originally written at eWheeler, Inc. dba Linux Global Eric Wheeler to
transform .s2p files and build MDF files to optimize with Microwave Office
for amplifer impedance matches.


=head1 COPYRIGHT

Copyright (C) 2022 eWheeler, Inc. L<https://www.linuxglobal.com/>

This module is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

This module is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this module. If not, see <http://www.gnu.org/licenses/>.
