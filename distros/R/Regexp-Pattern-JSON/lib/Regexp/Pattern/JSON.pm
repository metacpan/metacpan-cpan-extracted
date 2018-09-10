package Regexp::Pattern::JSON;

our $DATE = '2018-09-10'; # DATE
our $VERSION = '0.003'; # VERSION

our %RE;

$RE{number} = {
    summary => 'Match a JSON number literal',
    pat => qr{(?:
  (
    -?
    (?: 0 | [1-9][0-9]* )
    (?: \. [0-9]+ )?
    (?: [eE] [-+]? [0-9]+ )?
  )
    )}x,
    examples => [
        {str=>'12', matches=>1},
        {str=>'-34', matches=>1},
        {str=>'1.23', matches=>1},
        {str=>'-1.23e2', matches=>1},
    ],
};

$RE{string} = {
    summary => 'Match a JSON string literal',
    pat => qr{(?:
    "
    (?:
        [^\\"]+
    |
        \\ [0-7]{1,3}
    |
        \\ x [0-9A-Fa-f]{1,2}
    |
        \\ ["\\/bfnrt]
    #|
    #    \\ u [0-9a-fA-f]{4}
    )*
    "
    )}xms,
    examples => [
        {str=>q(""), matches=>1},
        {str=>q(''), matches=>0, summary=>"Single quotes are not string delimiters"},
        {str=>q("\\n"), matches=>1},
        {str=>q("contains \\" double quote"), matches=>1},
    ],
};

our $define = qr{

(?(DEFINE)

(?<OBJECT>
  \{\s*
    (?:
        (?&KV)
        \s*
        (?:,\s* (?&KV))*
    )?
    \s*
  \}
)

(?<KV>
  (?&STRING)
  \s*
  (?::\s* (?&VALUE))
)

(?<ARRAY>
  \[\s*
  (?:
      (?&VALUE)
      (?:\s*,\s* (?&VALUE))*
  )?
  \s*
  \]
)

(?<VALUE>
  \s*
  (?:
      (?&STRING)
  |
      (?&NUMBER)
  |
      (?&OBJECT)
  |
      (?&ARRAY)
  |
      true
  |
      false
  |
      null
  )
  \s*
)

(?<STRING> $RE{string}{pat})

(?<NUMBER> $RE{number}{pat})

) # DEFINE

}xms;

$RE{array} = {
    summary => 'Match a JSON array',
    pat => qr{(?:
    (?&ARRAY)
$define
    )}xms,
    examples => [
        {str=>q([]), matches=>1},
        {str=>q([1, true, "abc"]), matches=>1},
        {str=>q([1), matches=>0, summary=>"Missing closing bracket"},
    ],
};

$RE{object} = {
    summary => 'Match a JSON object (a.k.a. hash/dictionary)',
    pat => qr{(?:
    (?&OBJECT)
$define
    )}xms,
    examples => [
        {str=>q({}), matches=>1},
        {str=>q({"a":1}), matches=>1},
        {str=>q({"a":1), matches=>0, summary=>"Missing closing curly bracket"},
        {str=>q({a: 1}), matches=>0, summary=>"Unquoted key"},
    ],
};

$RE{value} = {
    summary => 'Match a JSON value',
    pat => qr{(?:
    (?&VALUE)
$define
    )}xms,
    examples => [
        {str=>q(true), matches=>1},
        {str=>q([]), matches=>1},
        {str=>q({}), matches=>1},
        {str=>q(-1), matches=>1},
        {str=>q(""), matches=>1},
    ],
};

1;
# ABSTRACT: Regexp patterns to match JSON

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::JSON - Regexp patterns to match JSON

=head1 VERSION

This document describes version 0.003 of Regexp::Pattern::JSON (from Perl distribution Regexp-Pattern-JSON), released on 2018-09-10.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("JSON::array");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * array

Match a JSON array.

Examples:

 "[]" =~ re("JSON::array");  # matches

 "[1, true, \"abc\"]" =~ re("JSON::array");  # matches

 # Missing closing bracket
 "[1" =~ re("JSON::array");  # doesn't match

=item * number

Match a JSON number literal.

Examples:

 12 =~ re("JSON::number");  # matches

 -34 =~ re("JSON::number");  # matches

 1.23 =~ re("JSON::number");  # matches

 "-1.23e2" =~ re("JSON::number");  # matches

=item * object

Match a JSON object (a.k.a. hash/dictionary).

Examples:

 "{}" =~ re("JSON::object");  # matches

 "{\"a\":1}" =~ re("JSON::object");  # matches

 # Missing closing curly bracket
 "{\"a\":1" =~ re("JSON::object");  # doesn't match

 # Unquoted key
 "{a: 1}" =~ re("JSON::object");  # doesn't match

=item * string

Match a JSON string literal.

Examples:

 "\"\"" =~ re("JSON::string");  # matches

 # Single quotes are not string delimiters
 "''" =~ re("JSON::string");  # doesn't match

 "\"\\n\"" =~ re("JSON::string");  # matches

 "\"contains \\\" double quote\"" =~ re("JSON::string");  # matches

=item * value

Match a JSON value.

Examples:

 "true" =~ re("JSON::value");  # matches

 "[]" =~ re("JSON::value");  # matches

 "{}" =~ re("JSON::value");  # matches

 -1 =~ re("JSON::value");  # matches

 "\"\"" =~ re("JSON::value");  # matches

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-JSON>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-JSON>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-JSON>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<JSON::Decode::Regexp>

L<Regexp::Common::json>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
