# NAME

PDL::IO::Touchstone 

# DESCRIPTION

A simple interface for reading and writing RF Touchstone files (also known as
".sNp" files).  Touchstone files contain complex-valued RF sample data for a
device or RF component with some number of ports. The data is (typically)
measured by a vector network analyzer under stringent test conditions.

The resulting files are usually provided by manufacturers so RF design
engineers can estimate signal behavior at various frequencies in their circuit
designs.  Examples of RF components include capacitors, inductors, resistors,
filters, power splitters, etc.

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
This is because while `PDL::IO::Touchstone` knows how to convert between RA,
MA, and DB formats, it does not manipulate the matrix to convert between
parameter types (or impedances).

## `rsnp($filename, $options)` - Read touchstone file

### Arguments: 

- $filename - the file to read
- $options - A hashref of options.

    Currently only 'units' is supported, which may specify one of Hz, KHz, MHz,
    GHz, or THz.  The resulting `$f` vector will be scaled to the frequency format
    you specify.  If you do not specify a format then `$f` will be scaled to Hz
    such that a value of 1e6 in the `$f` vector is equal to 1 MHz.

### Return values

The first set of parameters (`$f`, `$m`, `$param_type`, `$z0`) are required to properly
utilize the data loaded by `rsnp()`:

- `$f` - A (M,1) vector piddle of input frequencies where `M` is the
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

# SEE ALSO

- Touchstone specification: [https://ibis.org/connector/touchstone\_spec11.pdf](https://ibis.org/connector/touchstone_spec11.pdf)
- Building MDF files from multiple S2P files: [https://youtu.be/q1ixcb\_mgeM](https://youtu.be/q1ixcb_mgeM), [https://github.com/KJ7NLL/mdf/](https://github.com/KJ7NLL/mdf/)
- Optimizing amplifer impedance match circuits with MDF files: [https://youtu.be/nx2jy7EHzxw](https://youtu.be/nx2jy7EHzxw)
- MDF file format: [https://awrcorp.com/download/faq/english/docs/users\_guide/data\_file\_formats.html#i489154](https://awrcorp.com/download/faq/english/docs/users_guide/data_file_formats.html#i489154)

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
