# NAME

PDL::IO::Touchstone - Read and manipulate Touchstone .s2p (and .sNp) files.

# DESCRIPTION

A simple interface for reading and writing RF Touchstone files (also known as
".sNp" files).  Touchstone files contain complex-valued RF sample data for a
device or RF component with some number of ports. The data is (typically)
measured by a vector network analyzer under stringent test conditions.

The resulting files are usually provided by manufacturers so RF design
engineers can estimate signal behavior at various frequencies in their circuit
designs.  Examples of RF components include capacitors, inductors, resistors,
filters, power splitters, etc.

This `PDL::IO::Touchstone` module is very low-level and returns lots of
variables to keep track of.  Instead, I recommend that you use [RF::Component](https://metacpan.org/pod/RF::Component)
module for an object-oriented approach which encapsulates the data returned by
`rsnp()` and will, most likely, simplify your RF component implementation.

# SYNOPSIS

        use PDL::IO::Touchstone;

        # Read input matrix:
        ($f, $m, $param_type, $z0, $comments, $fmt, $funit, $orig_f_unit) =
                rsnp('input-file.s2p', { units => 'MHz' });


        # Write output file:
        wsnp('output-file.s2p',
                $f, $m, $param_type, $z0, $comments, $fmt, $from_hz, $to_hz);

You can reproduce the same output file from an input as follows:

        @data = rsnp('input-file.s2p');
        wsnp('output-file.s2p', @data);

You may convert between output formats or frequency scale by changing the
`$fmt` and `$to_hz` fields when writing:

        @data = rsnp('input-file.s2p');
        $data[5] = 'DB'; # $fmt
        $data[7] = 'MHz' # $to_hz in wsnp() or $orig_f_unit from rsnp().
        wsnp('output-file.s2p', @data);

Note that you may change neither `$param_type` nor `$z0` unless you have done
your own matrix transform from one parameter type (or impedance) to another.
This is because while `wsnp` knows how to convert between RA,
MA, and DB formats, it does not manipulate the matrix to convert between
parameter types (or impedances).  Use the `P_to_Q()` functions below to transform between matrix types.

# IO Functions

## `rsnp($filename, $options)` - Read touchstone file

### Arguments:

- $filename - the file to read
- $options - A hashref of options:
    - units: Hz, KHz, MHz, GHz, or THz.

        Units may specify one of Hz, KHz, MHz, GHz, or THz.  The resulting `$f` vector
        will be scaled to the frequency format you specify.  If you do not specify a
        format then `$f` will be scaled to Hz such that a value of 1e6 in the `$f`
        vector is equal to 1 MHz.

    - freq\_min\_hz, freq\_max\_hz, freq\_count: see `m_interpolate()`

        If these options are passed then the matrix (`$m`) and frequency (`$f`) PDLs
        returned by `rsnp()` will have been interpolated by `m_interpolate()`.

### Return values

The first set of parameters (`$f`, `$m`, `$param_type`, `$z0`) are required to properly
utilize the data loaded by `rsnp()`:

- `$f` - A (M) vector piddle of input frequencies where `M` is the
number of frequencies.
- `$m` - A (N,N,M) piddle of X-parameter matrices where `N` is the number
of ports and `M` is the number of frequencies.

    These matrixes have been converted from their 2-part RI/MA/DB input format and
    are ready to perform computation.  Matrix values (S11, etc) use PDL's
    native complex values.

- `$param_type` - one of S, Y, Z, H, G, T, or A that indicates the
matrix parameter type.

    Note that T and A are not officially supported Touchstone formats, but you can
    still load them with this module (but it is up to you to know how to use them).

- `$z0` - The characteristic impedance reference used to collect the measurements.

The remaining parameters (`$comments`, `$fmt`, `$funit`) are useful only if you wish to
re-create the original file format by calling `wsnp()`:

- `$comments` - An ARRAY-ref of full-line comments provided at the top of the input file.
- `$fmt` - The format of the input file, one of:
    - `RI` - Real/imaginary format
    - `MA` - Magnitude/angle format
    - `DB` - dB/angle format
- `$funit` - The frequency unit used by the `$f` vector

    The `$funit` value is typically 'Hz' unless you overrode the frequency scaling unit with `$options` in your
    call to `rsnp()`.  If you specified a unit the `$funit` will use that unit so a call to `wsnp()` will
    re-create the original touchstone file.

- `$orig_funit` - The frequency unit used by the original input file.

## `rsnp_fh($fh, $options)` - Read touchstone file

This is the same as `rsnp` except that it takes a file handle instead of a
filename.  Additionally, `$options` accepts the following additional values:

- `filename` - the original filename to facilitate more verbose error output.
- `EOF_REGEX` - a regular expression that, when matched, will cause `rsnp_fh` to stop reading data.

    This is used by [PDL::IO::MDIF](https://metacpan.org/pod/PDL::IO::MDIF) when loading multiple touchstone files from a single MDIF file.

## `wsnp($filename, $f, $m, $param_type, $z0, $comments, $fmt, $from_hz, $to_hz)`

### Arguments

Except for `$filename` (the output file), the arguments to `wsnp()` are the
same as those returned by `rsnp()`.

When writing it is up to you to maintain consistency between the output format
and the data being represented.  Except for complex value representation in
`$fmt` and frequency scale in `$f`, this `PDL::IO::Touchstone` module will
not make any mathematical transform on the matrix data.

Changing `$to_hz` will modify the frequency format in the resultant Touchstone
file, but the represented data will remain correct because Touchstone knows how
to scale frequencies.

Roughly speaking this should create an identical file to the input:

        wsnp('output.s2p', rsnp('input.s2p'));

However, there are a few output differences that may occur:

- Floating point rounding during complex format conversion
- Same-line "suffix comments" are stripped
- The order of comments and the "# format" line may be changed.
`wsnp()` will write comments before the "# format" line.
- Whitespace may differ in the output.  Touchstone specifies any whitespace as a
field delimiter and this module uses tabs as delimiters when writing output data.

## `wsnp_fh($fh, $f, $m, $param_type, $z0, $comments, $fmt, $from_hz, $to_hz)`

Same as `wsnp()` except that it takes a file handle instead of a filename.
Internally `wsnp()` uses `wsnp_fh()` and `wsnp_fh()` can be useful for
building MDF files, however MDF files are much more complicated and outside of
this module's scope.  Consult the ["SEE ALSO"](#see-also) section for more about MDFs and optimizing circuits.

# S-Parameter Conversion Functions

- Each matrix below is in the (N,N,M) format where N is the number of ports and M
is the number of frequencies.
- The value of `$z0` in the conversion functions may be complex-valued and
is represented as either:
    - - A perl scalar value: all ports have same impedance
    - - A 0-dim pdl like pdl( 5+2\*i() ): all ports have same impedance
    - - A 1-dim single-element pdl like pdl( \[5+2\*i()\] ): all ports have same impedance
    - - A 1-dim pdl representing the charectaristic impedance at each port: ports may have different impedances

## `$Y = s_to_y($S, $z0)`: Convert S-paramters to Y-parameters.

- `$S`: The S-paramter matrix
- `$z0`: Charectaristic impedance (see above).
- `$Y`: The resultant Y-paramter matrix

## `$S = y_to_s($Y, $z0)`: Convert Y-paramters to S-parameters.

- `$Y`: The Y-paramter matrix
- `$z0`: Charectaristic impedance (see above).
- `$S`: The resultant S-paramter matrix

## `$Z = s_to_z($S, $z0)`: Convert S-paramters to Z-parameters.

- `$S`: The S-paramter matrix
- `$z0`: Charectaristic impedance (see above).
- `$Z`: The resultant Z-paramter matrix

## `$S = z_to_s($Z, $z0)`: Convert Z-paramters to S-parameters.

- `$Z`: The Z-paramter matrix
- `$z0`: Charectaristic impedance (see above).
- `$S`: The resultant S-paramter matrix

## `$ABCD = s_to_abcd($S, $z0)`: Convert S-paramters to ABCD-parameters.

- `$S`: The S-paramter matrix
- `$z0`: Charectaristic impedance (see above).
- `$ABCD`: The resultant ABCD-paramter matrix

## `$S = abcd_to_s($ABCD, $z0)`: Convert ABCD-paramters to S-parameters.

- `$ABCD`: The ABCD-paramter matrix
- `$z0`: Charectaristic impedance (see above).
- `$S`: The resultant S-paramter matrix

# S-Paramter Calculaction Functions

All functions prefixed with "s\_" require an S-parameter matrix.

## `$z0n = s_port_z($S, $z0, $n)` - Return the complex port impedance vector for each frequency

- - `$S`: S paramter matrix
- - `$z0`: vector of \_reference\_ impedances at each port (from `rsnp`)
- - `$n`: the port we want.

In a 2-port, this will provide the input or output impedance as follows:

    $z_in  = s_port_z($S, 50, 1);
    $z_out = s_port_z($S, 50, 2);

Note that `$z_in` and `$z_out` are the PDL vectors for the input or output
impedance at each frequency in `$f`.  (NB, `$f` is not actually needed for
the calculation.)

# Y-Paramter Calculaction Functions

All functions prefixed with "y\_" require a Y-parameter matrix.

These functions are intended for use with 2-port matrices---but if you know
what you are doing they may work for higher-order matrices as well.

Unless otherwise indicated:

- `$Y` is a set Y-parameter matrices (one for each frequency), either  loaded directly from
a Y-formatted .s2p file or converted via `s_to_y` or similar functions.
- `$f_hz` is a vector of frequencies in Hz (one for each Y-matrix in
`$Y`); `$f_hz` is assumed to be sorted in ascending order and correspond to
each Mth element in `$Y` of dimension N,N,M where N is the number of ports and
M is the number of sample frequencies.

## `$C = y_capacitance($Y, $f_hz)` - Return a vector of capacitance for each frequency in Farads (F)

## `$C = y_cap_pF($Y, $f_hz)` - Return a vector of capacitance it each frequency in picofarads (pF)

## `$L = y_inductance($Y, $f_hz)` - Return a vector of inductance for each frequency in Henrys (H)

## `$L = y_ind_nH($Y, $f_hz)` - Return a vector of inductance for each frequency in nanohenrys (nH)

## `$Qc = y_qfactor_c($Y, $f_hz)` - Return the capacitive Q-factor vector for each frequency

Note that all inductive values are zeroed.

## `$Ql = y_qfactor_l($Y, $f_hz)` - Return the inductive Q-factor vector for each frequency

Note that all capacitive values are zeroed.

## `$X = y_reactance($Y, $f_hz)` - Return a vector of total reactance for each frequency

This is the same as (Xl - Xc).

## `$Xc = y_reactance_c($Y, $f_hz)` - Return a vector of capacitive reactance for each frequency

## `$Xl = y_reactance_l($Y, $f_hz)` - Return a vector of inductive reactance for each frequency

## `$R = y_resistance($Y)` - Return the equivalent series resistance (ESR) in Ohms

## `$R = y_esr($Y, $f_hz)` - An alias for `y_resistance`.

## `@srf_list_hz = y_srf($Y, $f_hz)` - Return the component's self-resonant frequencies (SRF)

To calculate SRF, reactance is evaluated at each frequency.  If the next frequency being
evaulated has an opposite sign (ie, going from capacitive to inductive reactance) then
that previous frequency is selected as an SRF.

Return value:

- List context: Return the list of SRF's in ascending order, or an empty list if no SRF is found.
- Scalar context: Return the lowest-frequency SRF, or undef if no SRF is found.

## `$f_hz = y_srf_ideal($Y, $f_hz)` - Return the component's first self-resonant frequency

Notice: In almost all cases you will want `y_srf` instead of `y_srf_ideal`.

This is included for ideal Y-matrices only and may not be accurate.  While the
equation is a classic SRF calculation (1/(2\*pi\*sqrt(LC)), SRF should scan the
frequency lines as follows: "The SRF is determined to be the frequency at which
the insertion (S21) phase changes from negative through zero to positive."
\[ [https://www.coilcraft.com/getmedia/8ef1bd18-d092-40e8-a3c8-929bec6adfc9/doc363\_measuringsrf.pdf](https://www.coilcraft.com/getmedia/8ef1bd18-d092-40e8-a3c8-929bec6adfc9/doc363_measuringsrf.pdf) \]

# Circuit Composition

## `$Y_pp = y_parallel($Y1, $Y2, [...])` - Compose a parallel circuit

For example, if `$Y1` and `$Y2` represent a 100pF capacitor, then `$Y_pp` will
represent a ~200pF capacitor. Parameters and return value must be
Y matrices converted by a function like `s_to_y`.

## `$ABCD_ss = abcd_series($ABCD1, $ABCD2, [...])` - Compose a series circuit

For example, if `$ABCD1` and `$ABCD2` represent a 100pF capacitor, then
`$ABCD_ss` will represent a ~50pF capacitor.  Parameters and return value must be
ABCD matrices converted by a function like `s_to_abcd`.

# Helper Functions

## `$n = n_ports($S)` - return the number of ports represented by the matrix.

Given any matrix (N,N,M) formatted matrix, this function will return N.

## `($f_new, $m_new) = m_interpolate($f, $m, $args)` - Interpolate `$m` to a different frequency set

This function rescales the X-parameter matrix (`$m`) and frequency set (`$f`)
to fit the requested frequency bounds.  This example will return the
interpolated `$S_new` and `$f_new` with 10 frequency samples from 100 to 1000
MHz (inclusive):

    ($f_new, $S_new) = m_interpolate($f, $S,
        { freq_min_hz => 100e6, freq_max_hz => 1000e6, freq_count => 10,
          quiet => 1 # optional
        } )

This function returns `$f` and `$m` without interpolation if no `$args` are passed.

- freq\_min\_hz: the minimum frequency at which to interpolate
- freq\_max\_hz: the maximum frequency at which to interpolate
- freq\_count: the total number of frequencies sampled.

    If `freq_count` is `1` then only `freq_min_hz` is returned.

- quiet: suppress warnings when interpolating beyond the available frequency range

## `$max_diff = f_uniformity($f)` - Return maximum frequency deviation.

Return the maximum difference between an ideal uniformally-spaced frequency set
and the frequency set provided.  This is used internally by `f_is_uniform()`.
For example:

    0.0 == f_uniformity(pdl [ 1, 2, 3  , 4 ]);
    0.5 == f_uniformity(pdl [ 1, 2, 2.5, 4 ]);

## `$bool = f_is_uniform($f, $tolerance_hz)` - Return true if the frequency set is uniform

Return true if the provided frequency set is uniform within a Hz value.
We assume `$f` is provided in Hz, so adjust `$tolerance_hz` accordingly if
$f is in a different unit.

## `@vecs = m_to_pos_vecs($m)` - Convert N,N,M piddle to row-ordered index slices.

Converts a NxNxM pdl where M is the number of frequency samples to a
N^2-length list of M-sized vectors, each representing a row-ordered position
in the NxN matrix.  ROW ORDERED!  @sivoais on irc.perl.org/#pdl calls these
"index slices".

This enables mutiplying vector positions for things like 2-port S-to-T
conversion.

For example:

        my ($S11, $S12, $S21, $S22) = m_to_pos_vecs($S)

        $T11 = -$S->det / $S21
        $T12 = ...
        $T21 = ...
        $T22 = ...

See also the inverse `pos_vecs_to_m` function.

## `$m = pos_vecs_to_m(@vecs)` - Convert row-ordered index slices to an N,N,M piddle.

This is the inverse of `m_to_pos_vecs`, here is the identity transform:

        $m = pos_vecs_to_m(m_to_pos_vecs($m))

For example, re-compose $T from the `m_to_pos_vecs` example.

        $T = pos_vecs_to_m($T11, $T12, $T21, $T22)

## `%h = rsnp_hash(rsnp(...))` - Create a named hash from the return values of rsnp

It is sometimes more familiar and readable to work with a hash of names instead
of an index of arrays.  This function converts the return value of `rsnp` into
a hash with the following fields.  The `[n]` values are the array index order
into the list that `rsnp` returns.

    %h = rsnp_hash(rsnp($filename, ...));

    %h = rsnp_hash(rsnp_fh($filehandle, ...));

- \[0\] freqs
- \[1\] m
- \[2\] param\_type
- \[3\] z0\_ref
- \[4\] comments
- \[5\] output\_fmt
- \[6\] funit
- \[7\] orig\_f\_unit

# SEE ALSO

- [PDL::IO::MDIF](https://metacpan.org/pod/PDL::IO::MDIF) - A [PDL](https://metacpan.org/pod/PDL) IO module to load Measurement Data Interchange Format (\*.mdf) files.
- [RF::Component](https://metacpan.org/pod/RF::Component) - An object-oriented encapsulation of `PDL::IO::Touchstone`.
- Touchstone specification: [https://ibis.org/connector/touchstone\_spec11.pdf](https://ibis.org/connector/touchstone_spec11.pdf)
- S-parameter matrix transform equations: [http://qucs.sourceforge.net/tech/node98.html](http://qucs.sourceforge.net/tech/node98.html)
- Building MDIF/MDF files from multiple S2P files: [https://youtu.be/q1ixcb\_mgeM](https://youtu.be/q1ixcb_mgeM), [https://github.com/KJ7NLL/mdf/](https://github.com/KJ7NLL/mdf/)
- Optimizing amplifer impedance match circuits with MDF files: [https://youtu.be/nx2jy7EHzxw](https://youtu.be/nx2jy7EHzxw)
- MDIF file format: [https://awrcorp.com/download/faq/english/docs/users\_guide/data\_file\_formats.html#i489154](https://awrcorp.com/download/faq/english/docs/users_guide/data_file_formats.html#i489154)
- "Conversions Between S, Z, Y, h, ABCD, and T Parameters which are Valid
for Complex Source and Load Impedances" March 1994 IEEE Transactions on
Microwave Theory and Techniques 42(2):205 - 211 [https://www.researchgate.net/publication/3118645](https://www.researchgate.net/publication/3118645)

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
