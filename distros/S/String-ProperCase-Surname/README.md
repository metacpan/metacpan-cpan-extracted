# NAME

String::ProperCase::Surname - Converts Surnames to Proper Case

# SYNOPSIS

    use String::ProperCase::Surname;
    print ProperCase($surname);

# DESCRIPTION

The package String::ProperCase::Surname is an [Exporter](https://metacpan.org/pod/Exporter) that exports exactly one function called ProperCase.  The ProperCase function is for use on Surnames which handles cases like O'Neal, O'Brien, McLean, etc.

After researching the proper case issues there are three different use cases with a wide variety of loose rules.  This algorithm is customized for surnames.  Other uses such as "TitleCase" and "MenuCase" have different algorithms.  The main difference is that in surnames the letter following an apostrophe is always uppercase (e.g. "O'Brien") in title case and menu case the letter is always lowercase (e.g. "They're").

# USAGE

    use String::ProperCase::Surname;
    print ProperCase($surname);

OR

    require String::ProperCase::Surname;
    print String::ProperCase::Surname::ProperCase($surname);

OR

    use String::ProperCase::Surname qw{};
    *pc=\&String::ProperCase::Surname::ProperCase;
    print pc($surname);

# VARIABLES

## %surname

You can add or delete custom mixed case surnames to/from this hash. 

Delete

    delete($String::ProperCase::Surname::surname{lc($_)}) foreach qw{MacDonald MacLeod};

Add

    $String::ProperCase::Surname::surname{lc($_)}=$_ foreach qw{DaVis};

Note: All keys are lower case and values are mixed case.

# FUNCTIONS

## ProperCase

Function returns the correct case given a surname.

    print ProperCase($surname);

Note: All "Mc" last names are assumed to be mixed case.

# LIMITATIONS

Surname default mixed case hash will never be perfect for every implementation.

# AUTHOR

    Michael R. Davis

# COPYRIGHT

This program is free software licensed under the...

    The BSD License

The full text of the license can be found in the LICENSE file included with this module.

# SEE ALSO

[Lingua::EN::Titlecase](https://metacpan.org/pod/Lingua::EN::Titlecase), [Spreadsheet::Engine::Function::PROPER](https://metacpan.org/pod/Spreadsheet::Engine::Function::PROPER)
