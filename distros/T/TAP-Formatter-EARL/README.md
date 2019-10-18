# NAME

TAP::Formatter::EARL - Formatting TAP output using the Evaluation and Report Language

# SYNOPSIS

Use on the command line:

    prove --formatter TAP::Formatter::EARL -l

# DESCRIPTION

This is a formatter for TAP-based test results to output them using
the [Evaluation and Report
Language](https://www.w3.org/TR/EARL10-Guide/), which is a vocabulary
based on the Resource Description Framework (RDF) to describe test
results, so that they can be shared, for example as part of an audit.

This module has a number of attributes, but they are all optional, as
they have reasonable defaults. Many of them can be set using
environment variables. It further extends [TAP::Formatter::Console](https://metacpan.org/pod/TAP::Formatter::Console).

## Attributes

- `model`

    An [Attean](https://metacpan.org/pod/Attean) mutable model that will contain the generated RDF
    triples. A temporary model is used by default.

- `ns`

    A [URI::NamespaceMap](https://metacpan.org/pod/URI::NamespaceMap) object. This can be used internally in
    programming with prefixes, and to abbreviate using the given prefixes
    in serializations. It is initialized by default with the prefixes used
    internally.

- `graph_name`

    An [Attean::IRI](https://metacpan.org/pod/Attean::IRI) to use as graph name for all triples. In normal
    operations, the formatter will not use the graph name, and so the
    default is set to `http://example.test/graph`. Normal coercions
    apply.

    It can be set using the environment variable `EARL_GRAPH_NAME`.

- `base`

    An [Attean::IRI](https://metacpan.org/pod/Attean::IRI) to use as the base URI for relative URIs in the
    serialized output. The default is no base. Normal coercions apply.

    It can be set using the environment variable `EARL_BASE`.

- `software_prefix`,  `assertion_prefix`, `result_prefix`

    Prefixes for URIs of the script running the test, the assertion that a
    certain result has been found, and the result itself, respectively.

    They accept a [URI::Namespace](https://metacpan.org/pod/URI::Namespace) object. They have relative URIs as
    defaults. These will not be set as a prefix in the serializer. Normal
    coercions apply.

    They can be set using environment variables, `EARL_SOFTWARE_PREFIX`,
    `EARL_ASSERTION_PREFIX` and `EARL_RESULT_PREFIX`, respectively.

## Methods

These methods are specialised implementations of methods in the
superclass [TAP::Formatter::Base](https://metacpan.org/pod/TAP::Formatter::Base).

- `open_test`

    This is called to create a new test session. It first describes the
    software used in RDF before calling [TAP::Formatter::EARL::Session](https://metacpan.org/pod/TAP::Formatter::EARL::Session).

- `summary`

    Serializes the model to Turtle and prints it to STDOUT.

# TODO

This is a rudimentary first release, it will only make use of data
parsed from each individual test result.

EARL reports can be extended to become a part of an extensive Linked
Data cloud. It can also link to tests as formulated by
e.g. [Test::FITesque::RDF](https://metacpan.org/pod/Test::FITesque::RDF).

# BUGS

Please report any bugs to
[https://github.com/kjetilk/p5-tap-formatter-earl/issues](https://github.com/kjetilk/p5-tap-formatter-earl/issues).

# SEE ALSO

# AUTHOR

Kjetil Kjernsmo <kjetilk@cpan.org>.

# COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Inrupt Inc

This is free software, licensed under:

    The MIT (X11) License

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
