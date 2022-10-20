# NAME

RF::Component - Compose RF component circuits and calculate values from objects (L, C, ESR, etc).

# SYNOPSIS

This module builds on [PDL::IO::Touchstone](https://metacpan.org/pod/PDL::IO::Touchstone) by encapsulating data returned by its
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

In most cases, the return value from the [RF::Component](https://metacpan.org/pod/RF::Component) methods are [PDL](https://metacpan.org/pod/PDL)
vectors, typically one value per frequency.  For example, `$pF` as shown above
will be a N-vector of values in picofarads, with one pF value for each
frequency.

# Constructor

The `$self->load` function (below) is typically used to load RF data, but
you may pass it directly to the constructor as follows.  Most of these options 
are valid for `$self->load` as well:

        my $c = RF::Component->new(%opts);

## Required:

- freqs: a PDL vector, one for each frequency in Hz.
- z0\_ref: A value representing the charectaristic impedance at each port.
If port impedances differ, then this may be a vector
- n\_ports: the number of ports represented by the port parameter matrix(es):
- At least one (N,N,M) [PDL](https://metacpan.org/pod/PDL) object where N is the number of ports and M
is the number of frequencies to represent complex port-parameter data:
    - S => pdl(...) - S-Paramters
    - Y => pdl(...) - Y-Paramters
    - Z => pdl(...) - Z-Paramters
    - A => pdl(...) - ABCD-Paramters
    - H => pdl(...) - H-Paramters (not yet implemented)
    - G => pdl(...) - G-Paramters (not yet implemented)
    - T => pdl(...) - T-Paramters (not yet implemented)

## Optional:

- comments - An arrayref of comments read from `load`
- filename - The filename read by `load`
- model - Component model number
- value\_code\_regex - Regular expression to parse the exponent-value code

    Specifies the variable to be assigned and a regular expression to match the
    capacitance code (or other unit): NNX or NRN. X is the exponent, N is a numeric
    value.

    If a capacitor code is 111 then it will calculate 11\*10^1 == 110 pF.  A code of
    1N4 or 14N would be 1.4 or 14.0, respectively. The unit 'pF' in the example is
    excluded from the code.  Example:

            MODEL-(...).s2p

    The above (...) must match the code (or literal) to be placed in the MDF
    variable. 

- value\_literal\_regex - Regular expression to parse the literal value

    The "literal" version is the same as `value_code_regex` but does not calcualte
    the code, it takes the value verbatim.  For example, some inductors specify the
    number of turns in their s2p filename:

            MODEL-([0-9]+)T\.s2p

- value - Component value

    The component value is parsed based on `value_code_regex` or
    `value_literal_regex`

- value\_unit - Unit of the value (pF, nH, etc).

    This is the unit expected in `value` afer parsing `value_code_regex`.
    Supported units: pF|nF|uF|uH|nH|R|Ohm|Ohms

You may also pass the above `new` options to the load call:

        my $cap = $self->load('/path/to/capacitor.s2p', $load_options, %new_options);

# IO Functions

## `RF::Component->load` - Load an RF data file as a component

    $cap = $self->load($filename, $load_options, %new_options);

Arguments:

- $filename: the path to the data file you wish to load
- $load\_options: a hashref of options that get passed to the
[PDL::IO::Touchstone](https://metacpan.org/pod/PDL::IO::Touchstone) `rsnp()` function options.
- %new\_options: a hash of options passed to `RF::Component->new` as
listed above.

This function loads the data based on the file extension, however,
only .sNp touchstone files are supported at this time. See the
[rsnp()](https://metacpan.org/pod/PDL::IO::Touchstone#IO-Functions) documentation in
[PDL::IO::Touchstone](https://metacpan.org/pod/PDL::IO::Touchstone) for specific details about `$options`.

## `RF::Component->load_snp` - Load a Touchstone data file as a component

This is the lower-level function called by `RF::Component->load`.  This function is 
functionally equivalent but does not evaluate the file extension being passed.

    $cap = $self->load_snp($filename, $load_options, %new_options);

# Calculation Functions

Unless otherwise indicated, the return value from these methods are [PDL](https://metacpan.org/pod/PDL)
vectors, typically one value per frequency.  For example, `$pF` as shown above
will be a N-vector of values in picofarads, with one pF value for each
frequency.

## `$z0n = $self->port_z($n)` - Return the complex port impedance vector for each frequency

`$n` is the port number at which to evaluate the input impedance:

In a 2-port, this will provide the input or output impedance as follows:

    $z_in  = $self->port_z(1);
    $z_out = $self->port_z(2);

Note that the port number starts at 1, not zero.  Thus a value of `$n=1` will
evaluate port impedance at `S11`.

Internally this function uses the [IO::PDL::Touchstone](https://metacpan.org/pod/IO::PDL::Touchstone) `s_port_z` function.

## `$C = $self->capacitance` - Return a vector of capacitance for each frequency in Farads (F)

Note that all inductive values are zeroed.

Internally this function uses the [IO::PDL::Touchstone](https://metacpan.org/pod/IO::PDL::Touchstone) `y_capacitance` function.

## `$C = $self->cap_pF` - Return a vector of capacitance it each frequency in picofarads (pF)

Note that all capacitive values are zeroed.

Internally this function uses the [IO::PDL::Touchstone](https://metacpan.org/pod/IO::PDL::Touchstone) `y_cap_pF` function.

## `$L = $self->inductance` - Return a vector of inductance for each frequency in Henrys (H)

Internally this function uses the [IO::PDL::Touchstone](https://metacpan.org/pod/IO::PDL::Touchstone) `y_inductance` function.

## `$L = $self->ind_nH` - Return a vector of inductance for each frequency in nanohenrys (nH)

Internally this function uses the [IO::PDL::Touchstone](https://metacpan.org/pod/IO::PDL::Touchstone) `y_ind_nH` function.

## `$Qc = $self->qfactor_c` - Return the capacitive Q-factor vector for each frequency

Internally this function uses the [IO::PDL::Touchstone](https://metacpan.org/pod/IO::PDL::Touchstone) `y_qfactor_c` function.

## `$Ql = $self->qfactor_l` - Return the inductive Q-factor vector for each frequency

Internally this function uses the [IO::PDL::Touchstone](https://metacpan.org/pod/IO::PDL::Touchstone) `y_qfactor_l` function.

## `$X = $self->reactance` - Return a vector of total reactance for each frequency

Internally this function uses the [IO::PDL::Touchstone](https://metacpan.org/pod/IO::PDL::Touchstone) `y_reactance` function.

## `$Xc = $self->reactance_c` - Return a vector of capacitive reactance for each frequency

Internally this function uses the [IO::PDL::Touchstone](https://metacpan.org/pod/IO::PDL::Touchstone) `y_reactance_c` function.

## `$Xl = $self->reactance_l` - Return a vector of inductive reactance for each frequency

Internally this function uses the [IO::PDL::Touchstone](https://metacpan.org/pod/IO::PDL::Touchstone) `y_reactance_l` function.

## `$R = $self->esr` - An alias for `y_resistance`.

Internally this function uses the [IO::PDL::Touchstone](https://metacpan.org/pod/IO::PDL::Touchstone) `y_esr` function.

## `@srf_list_hz = $self->srf` - Return the component's self-resonant frequencies (SRF)

To calculate SRF, reactance is evaluated at each frequency.  If the next frequency being
evaulated has an opposite sign (ie, going from capacitive to inductive reactance) then
that previous frequency is selected as an SRF.

Return value:

- List context: Return the list of SRF's in ascending order, or an empty list if no SRF is found.
- Scalar context: Return the lowest-frequency SRF, or undef if no SRF is found.

Internally this function uses the [IO::PDL::Touchstone](https://metacpan.org/pod/IO::PDL::Touchstone) `y_srf` function.

## `$f_hz = $self->srf_ideal` - Return the component's first self-resonant frequency

Notice: In almost all cases you will want `$self->srf` instead of `$self->srf_ideal`.

This is included for ideal Y-matrices only and may not be accurate.  While the
equation is a classic SRF calculation (1/(2\*pi\*sqrt(LC)), SRF should scan the
frequency lines as follows: "The SRF is determined to be the frequency at which
the insertion (S21) phase changes from negative through zero to positive."
\[ [https://www.coilcraft.com/getmedia/8ef1bd18-d092-40e8-a3c8-929bec6adfc9/doc363\_measuringsrf.pdf](https://www.coilcraft.com/getmedia/8ef1bd18-d092-40e8-a3c8-929bec6adfc9/doc363_measuringsrf.pdf) \]

Internally this function uses the [IO::PDL::Touchstone](https://metacpan.org/pod/IO::PDL::Touchstone) `y_srf_ideal` function.

## `$n = $self->num_ports` - return the number of ports in this component.

## `$n = $self->num_freqs` - return the number of frequencies in this component.
