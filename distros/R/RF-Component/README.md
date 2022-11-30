# NAME

RF::Component - Compose RF component circuits and calculate values from objects (L, C, ESR, etc).

# SYNOPSIS

This module builds on [PDL::IO::Touchstone](https://metacpan.org/pod/PDL::IO::Touchstone) by encapsulating data returned by its
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

In most cases, the return value from the [RF::Component](https://metacpan.org/pod/RF::Component) methods are [PDL](https://metacpan.org/pod/PDL)
vectors, typically one value per frequency.  For example, `$pF` as shown above
will be a N-vector of values in picofarads, with one pF value for each
frequency.

# Constructor

The `RF::Component->load` function (below) is typically used to load RF data, but
you may pass it directly to the constructor as follows.  Most of these options 
are valid for `RF::Component->load` as well:

        my $c = RF::Component->new(%opts);

## Required:

- `freqs`: a PDL vector, one for each frequency in Hz.
- `z0_ref`: A value representing the charectaristic impedance at each port.
If port impedances differ, then this may be a vector
- `n_ports`: the number of ports represented by the port parameter matrix(es):
- At least one (N,N,M) [PDL](https://metacpan.org/pod/PDL) element where N is the number of ports and M
is the number of frequencies to represent complex port-parameter data:
    - S => pdl(...) - S-Paramters
    - Y => pdl(...) - Y-Paramters
    - Z => pdl(...) - Z-Paramters
    - A => pdl(...) - ABCD-Paramters
    - H => pdl(...) - H-Paramters (not yet implemented)
    - G => pdl(...) - G-Paramters (not yet implemented)
    - T => pdl(...) - T-Paramters (not yet implemented)

## Optional:

- `comments`: An arrayref of comments read from `load`
- `filename`: The filename read by `load`
- `output_fmt`: The .sNp output format: one of DB, MA, or RI

    This is the format originally read in by `$self->load`.

    - DB: dB,phase formatted
    - MA: magnitude,phase formatted
    - RI: real,imag formatted

- `orig_f_unit`: The original frequency unit from the .sNp file

    This is the frequency format originally read in by `$self->load`:
    kHz, MHz, GHz, THz, ...

- `filename`: The filename read by `load`
- `model`: Component model number
- `value_code_regex`: Regular expression to parse the exponent-value code

    Specifies the variable to be assigned and a regular expression to match the
    capacitance code (or other unit): NNX or NRN. X is the exponent, N is a numeric
    value.

    If a capacitor code is 111 then it will calculate 11\*10^1 == 110 pF.  A code of
    1N4 or 14N would be 1.4 or 14.0, respectively. The unit 'pF' in the example is
    excluded from the code.  Example:

            MODEL-(...).s2p

    The above (...) must match the code (or literal) to be placed in the MDF
    variable. 

- `value_literal_regex`: Regular expression to parse the literal value

    The "literal" version is the same as `value_code_regex` but does not calcualte
    the code, it takes the value verbatim.  For example, some inductors specify the
    number of turns in their s2p filename:

            MODEL-([0-9]+)T\.s2p

- `value`: Component value

    The component value is parsed based on `value_code_regex` or
    `value_literal_regex`

- `value_unit`: Unit of the value (pF, nH, etc).

    This is the unit expected in `value` afer parsing `value_code_regex`.
    Supported units: pF|nF|uF|uH|nH|R|Ohm|Ohms

- `vars`: A hashref of variable=value.

    This is an opaque variables structure.  Currently it is used for vars defined
    in an MDIF file.

You may also pass the above `new` options to the load call:

        my $cap = RF::Component->load('/path/to/capacitor.s2p', %options);

# IO Functions

## `RF::Component->load` - Load an RF data file as a component

    $cap = RF::Component->load($filename, %new_options);

Arguments:

- $filename: the path to the data file you wish to load
- %new\_options: a hash of options passed to `RF::Component->new` as
listed above, except the option `load_options`:

    `load()` supports the special option `load_options`.  If `load_options` is
    specified then it is passed to the loading function such as
    `PDL::IO::Touchstone::rsnp()`.

This function loads the data based on the file extension, however,
only .sNp touchstone files are supported at this time. See the
[rsnp()](https://metacpan.org/pod/PDL::IO::Touchstone#IO-Functions) documentation in
[PDL::IO::Touchstone](https://metacpan.org/pod/PDL::IO::Touchstone) for specific details about `$options`.

## `RF::Component->load_snp` - Load a Touchstone data file as a component

This is the lower-level function called by `RF::Component->load`.  This
function is functionally equivalent but does not evaluate the file extension
being passed before calling `PDL::IO::Touchstone::rsnp()`:

    $cap = RF::Component->load_snp($filename, %new_options);

## `RF::Component->save` - Write the component to a data file

    $cap->save('cap.s2p', %options);

This function will match based on the output file extension and call the
appropriate save\_\* function below.  The `%options` hash will depend on the
desired file output type.

## `RF::Component->save_snp` - Write the component to a Touchstone data file

    $cap->save_snp('cap.s2p', %options);

- `param_type`: Supported paramter type: S, Y, Z, A

    Notice: While A can be specified to write ABCD-formatted parameters, the ABCD
    matrix is not officially supported by the Touchstone spec.

- `output_f_unit`: The .sNp file's frequency unit.

    This defaults to Hz, but supports SI units such as: KHZ, MHz, GHz, ...

- `output_fmt`: See above, same as in `new()`.

## `RF::Component->save_snp_fh` - Write the component to a file descriptor

Same as `save_snp` but writes to a file handle:

    $cap->save_snp_fh(*STDOUT, %options);

# Calculation Functions

Unless otherwise indicated, the return value from these methods are [PDL](https://metacpan.org/pod/PDL)
vectors, typically one value per frequency.  For example, `$pF` as shown above
will be a N-vector of values in picofarads, with one pF value for each
frequency.

## `$self->at($f_Hz)` - Frequency extrapolation (object cloning)

It is importatant to easily choose which frequencies will be used for
calculations because the functions below return vectors with values at each
frequency for the calculation provided.  In many cases you will want to load a
Touchstone data file at all frequencies and then use `$obj->at($f_Hz)` to
reduce or extrapolate to a different frequency or set of freqencies.

Each call to `$obj->at($f_Hz)` will return a new `RF::Component` object
as follows:

        $cap = RF::Component->load('my.s2p');

        # Picofarads at 100 MHz (100e6 Hz).
        $pF = $cap->at(100e6)->capacitance * 1e12;

        # Reactance at 100 MHz and 200 MHz:
        $X = $cap->at('100e6, 200e6')->reactance;

        # ESR at 1-10 GHz with 20 samples (500 MHz each):
        $esr = $cap->at('1e9 - 10e9  x20');

        # ESR at 1-10 GHz stepping 500 MHz with 20 samples
        # (same as the previous above, but different notation)
        $esr = $cap->at('1e9 += 500e6  x20');

Notes:

- Each resulting value is a PDL vector containing one value per evaluated
frequency.
- Internally the `$obj->at($f_Hz)` function uses
[PDL::IO::Touchstone](https://metacpan.org/pod/PDL::IO::Touchstone)'s `m_interpolate` function so you can use any syntax
available to `m_interpolate`.
- The `$obj->at($f_Hz)` call caches the resulting interpolated
object to prevent repeated extrapolation at the same frequency set.  Because of this
the `$obj->at($f_Hz)` call only supports scalar ranges either using a single
frequency or the quoted range feature shown above and in
[PDL::IO::Touchstone](https://metacpan.org/pod/PDL::IO::Touchstone)'s `m_interpolate` function.
- If no range is specified then the original object is returned:

            return $self if !length($range);

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

# Parameter Matrix and Vector Functions

## `$n = $self->freqs` - return a PDL vector of each frequency.

## `$self->S($i, $j)` - Access the S-parameter matrix or index slices.

If `$i` and `$j` are specified, then return a PDL vector `S_i,j` index slice
at each frequency. The vector will contain one value for each frequency.  For
example:

        my $S11 = $self->S(1,1);

If you omit `$i` and `$j` then this returns a (N,N,M) [piddle](https://metacpan.org/pod/PDL) where N is the
number of ports and M is the number of frequencies.

## `$self->Y($i, $j)` - Access the Y-parameter matrix or index slices.

Same as `$self->S($i, $j)`, but for a Y-paramater matrix, see above.  Even
if a Y-parameter data file was not loaded, Y-parameters will be calculated for
you.

## `$self->Z($i, $j)` - Access the Z-parameter matrix or index slices.

Same as `$self->S($i, $j)`, but for a Z-paramater matrix, see above.  Even
if a Z-parameter data file was not loaded, Z-parameters will be calculated for
you.

## `$self->ABCD($i, $j)` - Access the ABCD-parameter matrix or index slices.

Same as `$self->S($i, $j)`, but for a ABCD-paramater matrix, see above.  Even
if a ABCD-parameter data file was not loaded, ABCD-parameters will be calculated for
you.

## `$self->A()` - Return the A vector from the ABCD matrix.

Same as `$self->ABCD(1,1)`, returns a vector for A values at each frequency.

## `$self->B()` - Return the B vector from the ABCD matrix.

Same as `$self->ABCD(1,2)`, returns a vector for B values at each frequency.

## `$self->C()` - Return the C vector from the ABCD matrix.

Same as `$self->ABCD(2,1)`, returns a vector for C values at each frequency.

## `$self->D()` - Return the D vector from the ABCD matrix.

Same as `$self->ABCD(2,2)`, returns a vector for D values at each frequency.

# Helper Functions

## `$n = $self->num_ports` - return the number of ports in this component.

## `$n = $self->num_freqs` - return the number of frequencies in this component.

## `@wsnp_list = $self->get_wsnp_list(%opts)` - return a list for passing to `wsnp()`

Options:

- `param_type` - One of S, Y, or Z.  The matrix returned in the list
will be converted to the requested type (or an error will be thrown).
- `output_f_unit` - Same as [wsnp](https://metacpan.org/pod/PDL::IO::Touchstone)'s `$to_hz` value
- `output_fmt` - Same as [wsnp](https://metacpan.org/pod/PDL::IO::Touchstone)'s `$fmt` value

The get\_wsnp\_list method returns a list compatible with
[PDL::IO::Touchstone](https://metacpan.org/pod/PDL::IO::Touchstone)'s `wsnp($filename, @wsnp_list)` function, which writes
a .sNp file.  It is also the list format used internally for MDIFs in
[RF::Component::Multi](https://metacpan.org/pod/RF::Component::Multi).

# SEE ALSO

- [PDL::IO::Touchstone](https://metacpan.org/pod/PDL::IO::Touchstone) - The lower-level framework used by [RF::Component](https://metacpan.org/pod/RF::Component)
- [RF::Component::Multi](https://metacpan.org/pod/RF::Component::Multi) - A list-encapsulation of [RF::Component](https://metacpan.org/pod/RF::Component) to provide vectorized operations
on multiple components.  This allows you to open MDIF files in a classful-way.
- [PDL::IO::MDIF](https://metacpan.org/pod/PDL::IO::MDIF) - Load MDIF files
- Touchstone specification: [https://ibis.org/connector/touchstone\_spec11.pdf](https://ibis.org/connector/touchstone_spec11.pdf)

# AUTHOR

Originally written at eWheeler, Inc. dba Linux Global Eric Wheeler to
transform .s2p files and build MDF files to optimize with Microwave Office
for amplifer impedance matches.

# COPYRIGHT

Copyright (C) 2022 eWheeler, Inc. [https://www.linuxglobal.com/](https://www.linuxglobal.com/)

This module is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

This module is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this module. If not, see &lt;http://www.gnu.org/licenses/>.
