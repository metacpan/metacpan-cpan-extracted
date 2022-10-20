package RF::Component;
$VERSION = 1.001;


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

	if (!$self->_available_params)
	{
		croak "At least one port-parameter matrix must be provided: " . join(' ', @PARAM_TYPES);
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
	my ($class, $filename, $opts, %newopts) = @_;

	my $self;
	if ($filename =~ /\.s\d+p/)
	{
		$self = $class->load_snp($filename, $opts, %newopts)
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
	my ($class, $filename, $opts, %newopts) = @_;

	my %args;

	@args{qw/f m param_type z0/} = rsnp($filename, $opts);

	return $class->new(
		%newopts,
		freqs => $args{f},
		uc($args{param_type}) => $args{m},
		n_ports => PDL::IO::Touchstone::n_ports($args{m}),
		z0_ref => $args{z0});
}

sub S
{
	my ($self, $i, $j) = @_;

	my $S = $self->_sparam;

	return pos_vec($S, $i, $j) if ($i && $j);
	return $S;
}

sub Y
{
	my ($self, $i, $j) = @_;

	my $Y = $self->_yparam;

	return pos_vec($Y, $i, $j) if ($i && $j);
	return $Y;
}

sub Z
{
	my ($self, $i, $j) = @_;

	my $Z = $self->_zparam;

	return pos_vec($Z, $i, $j) if ($i && $j);
	return $Z;
}

sub ABCD
{
	my ($self, $i, $j) = @_;

	my $ABCD = $self->_aparam;

	return pos_vec($ABCD, $i, $j) if ($i && $j);
	return $ABCD;
}

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
sub  port_z            {  my $self = shift;   s_port_z(               $self->_sparam, $self->{z0_ref}, @_)  }
sub  inductance        {  my $self = shift;   y_inductance(           $self->_yparam, $self->{freqs},  @_)  }
sub  ind_nH            {  my $self = shift;   y_ind_nH(               $self->_yparam, $self->{freqs},  @_)  }
sub  resistance        {  my $self = shift;   y_resistance(           $self->_yparam,  @_)  }
sub  esr               {  my $self = shift;   y_esr(                  $self->_yparam,  @_)  }
sub  capacitance       {  my $self = shift;   y_capacitance(          $self->_yparam, $self->{freqs},  @_)  }
sub  cap_pF            {  my $self = shift;   y_cap_pF(               $self->_yparam, $self->{freqs},  @_)  }
sub  qfactor_l         {  my $self = shift;   y_qfactor_l(            $self->_yparam, $self->{freqs},  @_)  }
sub  qfactor_c         {  my $self = shift;   y_qfactor_c(            $self->_yparam, $self->{freqs},  @_)  }
sub  reactance_l       {  my $self = shift;   y_reactance_l(          $self->_yparam, $self->{freqs},  @_)  }
sub  reactance_c       {  my $self = shift;   y_reactance_c(          $self->_yparam, $self->{freqs},  @_)  }
sub  reactance         {  my $self = shift;   y_reactance(            $self->_yparam, $self->{freqs},  @_)  }
sub  srf               {  my $self = shift;   y_srf(                  $self->_yparam, $self->{freqs},  @_)  }
sub  srf_ideal         {  my $self = shift;   y_srf_ideal(            $self->_yparam, $self->{freqs},  @_)  }
sub  is_lossless       {  my $self = shift;   abcd_is_lossless(       $self->_aparam,  @_)  }
sub  is_symmetrical    {  my $self = shift;   abcd_is_symmetrical(    $self->_aparam,  @_)  }
sub  is_reciprocal     {  my $self = shift;   abcd_is_reciprocal(     $self->_aparam,  @_)  }
sub  is_open_circuit   {  my $self = shift;   abcd_is_open_circuit(   $self->_aparam,  @_)  }
sub  is_short_circuit  {  my $self = shift;   abcd_is_short_circuit(  $self->_aparam,  @_)  }

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

sub _sparam
{
	my $self = shift;

	my $S = $self->{S};

	$S //= abcd_to_s($self->{A}, $self->z0_ref) if defined($self->{A});
	$S //= y_to_s($self->{Y}, $self->z0_ref) if defined($self->{Y});
	$S //= z_to_s($self->{Z}, $self->z0_ref) if defined($self->{Z});

	$self->{S} //= $S;

	return $S if (defined $S);

	my $params = $self->_available_params || '(none)';
	croak("S-parameter from available matrix is not implemented.  Available matrix types: $params");
}

sub _yparam
{
	my $self = shift;

	$self->{Y} //= s_to_y($self->_sparam, $self->z0_ref);

	return $self->{Y} if (defined($self->{Y}));

	my $params = $self->_available_params || '(none)';
	croak("Y-parameter from available matrix is not implemented.  Available matrix types: $params");
}

sub _zparam
{
	my $self = shift;

	$self->{Z} //= s_to_z($self->_sparam, $self->z0_ref);

	return $self->{Z} if (defined($self->{Z}));

	my $params = $self->_available_params || '(none)';
	croak("Z-parameter from available matrix is not implemented.  Available matrix types: $params");
}

sub _aparam
{
	my $self = shift;

	$self->{A} //= s_to_abcd($self->_sparam, $self->z0_ref);

	return $self->{A} if (defined($self->{A}));

	my $params = $self->_available_params || '(none)';
	croak("ABCD-parameter from available matrix is not implemented.  Available matrix types: $params");
}

# return S, A, etc... based on which are defined.
sub _available_params
{
	my $self = shift;

	my @params = map { defined $_ } @$self{@PARAM_TYPES};

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


1;

__END__

=head1 NAME

RF::Component - Compose RF component circuits and calculate values from objects (L, C, ESR, etc).

=head1 SYNOPSIS

This module builds on L<PDL::IO::Touchstone> by encapsulating data returned by its
methods into an object for easy use:

	my $cap = $self->load('/path/to/capacitor.s2p', $options);
	my $wilky = $self->load('/path/to/wilkinson.s3p', $options);

	# port 1 input impedances
	my $z_in = $cap->port_z(1);

	# Capacitance in pF:
	my $pF = $cap->capacitance() * 1e12

	my $S11 = $cap->S(1,1);
	my $Y21 = $cap->Y(2,1);
	my $Z33 = $wilky->Z(3,3);

In most cases, the return value from the L<RF::Component> methods are L<PDL>
vectors, typically one value per frequency.  For example, C<$pF> as shown above
will be a N-vector of values in picofarads, with one pF value for each
frequency.

=head1 Constructor

The C<$self-E<gt>load> function (below) is typically used to load RF data, but
you may pass it directly to the constructor as follows.  Most of these options 
are valid for C<$self-E<gt>load> as well:

	my $c = RF::Component->new(%opts);

=head2 Required:

=over 4

=item * freqs: a PDL vector, one for each frequency in Hz.

=item * z0_ref: A value representing the charectaristic impedance at each port.
If port impedances differ, then this may be a vector

=item * n_ports: the number of ports represented by the port parameter matrix(es):

=item * At least one (N,N,M) L<PDL> object where N is the number of ports and M
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

=item * comments - An arrayref of comments read from C<load>

=item * filename - The filename read by C<load>

=item * model - Component model number

=item * value_code_regex - Regular expression to parse the exponent-value code

Specifies the variable to be assigned and a regular expression to match the
capacitance code (or other unit): NNX or NRN. X is the exponent, N is a numeric
value.

If a capacitor code is 111 then it will calculate 11*10^1 == 110 pF.  A code of
1N4 or 14N would be 1.4 or 14.0, respectively. The unit 'pF' in the example is
excluded from the code.  Example:

	MODEL-(...).s2p

The above (...) must match the code (or literal) to be placed in the MDF
variable. 

=item * value_literal_regex - Regular expression to parse the literal value

The "literal" version is the same as C<value_code_regex> but does not calcualte
the code, it takes the value verbatim.  For example, some inductors specify the
number of turns in their s2p filename:

        MODEL-([0-9]+)T\.s2p

=item * value - Component value

The component value is parsed based on C<value_code_regex> or
C<value_literal_regex>

=item * value_unit - Unit of the value (pF, nH, etc).

This is the unit expected in C<value> afer parsing C<value_code_regex>.
Supported units: pF|nF|uF|uH|nH|R|Ohm|Ohms

=back

You may also pass the above C<new> options to the load call:

	my $cap = $self->load('/path/to/capacitor.s2p', $load_options, %new_options);


=head1 IO Functions

=head2 C<RF::Component-E<gt>load> - Load an RF data file as a component

    $cap = $self->load($filename, $load_options, %new_options);

Arguments:

=over 4

=item * $filename: the path to the data file you wish to load

=item * $load_options: a hashref of options that get passed to the
L<PDL::IO::Touchstone> C<rsnp()> function options.

=item * %new_options: a hash of options passed to C<RF::Component-E<gt>new> as
listed above.

=back

This function loads the data based on the file extension, however,
only .sNp touchstone files are supported at this time. See the
L<rsnp()|PDL::IO::Touchstone/"IO Functions"> documentation in
L<PDL::IO::Touchstone> for specific details about C<$options>.


=head2 C<RF::Component-E<gt>load_snp> - Load a Touchstone data file as a component

This is the lower-level function called by C<RF::Component-E<gt>load>.  This function is 
functionally equivalent but does not evaluate the file extension being passed.

    $cap = $self->load_snp($filename, $load_options, %new_options);


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


=head2 C<$n = $self-E<gt>num_ports> - return the number of ports in this component.

=head2 C<$n = $self-E<gt>num_freqs> - return the number of frequencies in this component.
