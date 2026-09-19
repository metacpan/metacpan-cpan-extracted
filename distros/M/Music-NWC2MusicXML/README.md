# NAME

Music::NWC2MusicXML - Convert NoteWorthy Composer 2 `.nwc` score files to MusicXML.

# VERSION

0.001.0

# SYNOPSIS

    # Simple conversion
    use Music::NWC2MusicXML;

    my $converter = Music::NWC2MusicXML->new;
    $converter->convert(
        input  => 'Pilgrim.nwc',
        output => 'Pilgrim.musicxml',
    );

    # Batch conversion
    $converter->batch_convert(
        inputs     => [ glob('*.nwc') ],
        output_dir => 'musicxml',
        overwrite  => 1,
    );

# DESCRIPTION

`Music::NWC2MusicXML` is the top-level facade for the NWC-to-MusicXML conversion
pipeline.  It coordinates three independent stages:

- 1. **NWC binary decoding** (`Music::NWC2MusicXML::NWC`) -- reads the `.nwc`
binary container, verifies the magic signature, decompresses the zlib payload,
and extracts the NWCTXT text representation.
- 2. **NWCTXT parsing** (`Music::NWC2MusicXML::Parser`) -- parses the NWCTXT into
an internal representation (`Music::NWC2MusicXML::Score`).
- 3. **MusicXML generation** (`Music::NWC2MusicXML::MusicXML`) -- serialises the
internal representation to a well-formed UTF-8 MusicXML document.

Each stage is independently testable.  The facade wires them together,
handles batch processing, and routes all diagnostics through a single
`Music::NWC2MusicXML::Diagnostics` instance.

# PRESERVATION PRINCIPLE

The guiding principle of the conversion is:

_Preserve musical meaning rather than graphical appearance._

Priority order: notes and rhythm > voices > measures > articulations >
dynamics > lyrics > structural markings > instrument info > graphical layout.

## new

Construct a converter.

### Purpose

Creates a configured converter instance that can be reused for multiple
conversions without reconstructing the pipeline components each time.

### Arguments

Named parameters:

- `log_level`    -- `quiet`, `normal` (default), `verbose`, `debug`.
- `warnings_fh` -- filehandle for warning output (optional; defaults to
STDERR in the `Diagnostics` object).
- `validate`    -- perform extended consistency checks (boolean, default 0).

### Returns

Blessed `Music::NWC2MusicXML` object.

### Usage Example

    my $c = Music::NWC2MusicXML->new(log_level => 'verbose', validate => 1);

### API SPECIFICATION

#### Input

    log_level    : SCALAR  (optional, default 'normal')
    warnings_fh  : (filehandle, optional)
    validate     : SCALAR  (optional, default 0)

#### Output

    Music::NWC2MusicXML object

### MESSAGES

None.

## convert

Convert a single `.nwc` file to MusicXML.

### Purpose

Main single-file conversion entry point.  Chains decoder -> parser ->
generator, writes the output file, and updates the internal diagnostic counters.

### Arguments

Named parameters:

- `input`     -- path to the `.nwc` input file (required).
- `output`    -- path for the `.musicxml` output file (optional).
Defaults to the input path with the extension replaced by `.musicxml`.
- `overwrite` -- if false (default), skip conversion when the output file
already exists.

### Returns

Scalar string -- the output file path if conversion succeeded, or undef on
failure.

### Side Effects

Writes the output file.  Updates diagnostic counters.
Croaks on fatal errors; non-fatal issues are issued as warnings.

### Usage Example

    my $out = $c->convert(input => 'Pilgrim.nwc', overwrite => 1);

### API SPECIFICATION

#### Input

    input     : SCALAR (path, required)
    output    : SCALAR (path, optional)
    overwrite : boolean (optional, default false)

#### Output

    SCALAR (output path) or undef

### MESSAGES

| Code               | Meaning                              | Resolution                    |
|--------------------|--------------------------------------|-------------------------------|
| error\_no\_input     | `input` parameter missing           | Provide input path            |
| error\_file\_not\_found| Input file does not exist           | Check path                    |
| error\_decode       | NWC decoding stage failed            | See error detail              |
| error\_parse        | NWCTXT parsing stage failed          | See error detail              |
| error\_generate     | MusicXML generation failed           | See error detail              |
| error\_write        | Cannot write output file             | Check permissions / disk space|

## batch\_convert

Convert multiple `.nwc` files, optionally into a separate output directory.

### Purpose

Processes a list of input files in sequence.  Failures on individual files
are caught and counted; conversion continues with remaining files.
A summary is printed at the end.

### Arguments

Named parameters:

- `inputs`     -- arrayref of input file paths (required).
- `output_dir` -- directory for output files (optional; defaults to each
file's own directory).
- `overwrite`  -- overwrite existing output files (boolean, default 0).
- `recursive`  -- preserve relative directory structure under
`output_dir` (boolean, default 0).
- `base_dir`   -- base directory stripped when computing relative paths
for recursive mode (optional).

### Returns

Hashref: `{ processed => N, successful => N, warnings => N, failed => N }`.

### Side Effects

Writes output files.  Prints a summary to STDERR.
Does not croak on per-file failures.

### Usage Example

    $c->batch_convert(
        inputs     => [ glob('scores/**/*.nwc') ],
        output_dir => 'musicxml',
        recursive  => 1,
        base_dir   => 'scores',
        overwrite  => 1,
    );

### API SPECIFICATION

#### Input

    inputs     : ARRAYREF of SCALAR paths (required)
    output_dir : SCALAR (optional)
    overwrite  : SCALAR bool (optional, default 0)
    recursive  : SCALAR bool (optional, default 0)
    base_dir   : SCALAR (optional)

#### Output

    HASHREF { processed:int, successful:int, warnings:int, failed:int }

## diagnostics

Return the `Music::NWC2MusicXML::Diagnostics` instance.

# DIAGNOSTICS

### MESSAGES

| Code                 | Meaning                             | Resolution                        |
|----------------------|-------------------------------------|-----------------------------------|
| error\_no\_input       | input parameter missing             | Provide input path                |
| error\_file\_not\_found | Input file absent                   | Check path and permissions        |
| error\_decode         | NWC decoding stage failed           | See embedded error                |
| error\_parse          | NWCTXT parsing stage failed         | See embedded error                |
| error\_generate       | MusicXML generation failed          | See embedded error                |
| error\_write          | Cannot write output                 | Check disk space and permissions  |
| error\_mkdir          | Cannot create output directory      | Check parent directory permissions|

# LIMITATIONS

- Parallel batch processing is not implemented; files are converted sequentially.
- MusicXML validation against the official DTD/XSD is not performed
internally; use an external validator with `--validate`.
- Tuplet time-modification and multi-voice `RestChord` records are not yet
emitted (Phase 4 items).

# DEPENDENCIES

[Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) is used to allow callers to pre-configure converter
defaults at the class level (e.g. `Music::NWC2MusicXML->configure(log_level => 'verbose')`).
This means a consuming application can set defaults once and `new` will
honour them without repeating the arguments on each call.

# SEE ALSO

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/Music-NWC2MusicXML/coverage/)

# FORMAL SPECIFICATION

## new

    [ConverterInit]
      log_level   : LogLevel
      validate    : Boolean
      diagnostics : Diagnostics
      nwc_decoder : NWCDecoder
      parser      : Parser
      generator   : Generator

    (placeholder -- populate with Z calculus as implementation matures)

## convert

    [Convert]
      input?  : FileName
      output? : FileName
      ----------
      result! : FileName | Undef

    (placeholder)

## batchconvert

    [BatchConvert]
      inputs?     : seq FileName
      output_dir? : DirName
      ----------
      summary!    : BatchSummary

    (placeholder)

# AUTHOR

Nigel Horne `<njh@nigelhorne.com>`

# LICENSE

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
