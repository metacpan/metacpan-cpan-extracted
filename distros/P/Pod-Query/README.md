# NAME

Pod::Query - Query pod documents

# SYNOPSIS

Query POD information from a file

    % perl -MPod::Query -E 'say for Pod::Query->new("ojo")->find("head1[0]")'

    NAME
    ojo - Fun one-liners with Mojo

    % perl -MPod::Query -E 'say Pod::Query->new("ojo")->find("head1[0]/Para[0]")'

    ojo - Fun one-liners with Mojo

    % perl -MPod::Query -E 'say Pod::Query->new(shift)->find("head1[0]/Para[0]")' my.pod

Find Methods:

        find_title;
        find_method;
        find_method_summary;
        find_events;
        find($query_sting);
        find(@query_structs);

# DESCRIPTION

This module takes a class name, extracts the POD
and provides methods to query specific information.

# SUBROUTINES/METHODS

## \_has

Generates class accessor methods (like Mojo::Base::attr)

## path

Path to the pod class file

## lol

List of lists (LOL) structure of the pod file.
Result of Pod::LOL.

## tree

An hierarchy is added to the lol to create a
tree like structure of the pod file.

## class\_is\_path

Flag to indicate if the class is really a path to the file.

## new

Create a new object.
Return value is cached (based on the class of the pod file).

        use Pod::Query;
        my $pod = Pod::Query->new('Pod::LOL', PATH_ONLY=0);

PATH\_ONLY can be used to determine the path to the pod
document without having to do much unnecessary work.

## \_class\_to\_path

Given a class name, returns the path to the pod file.
Return value is cached (based on the class of the pod file).

If the class is not found in INC, it will be checked whether
the input is an existing file path.

Returns an empty string if there are any errors.

## \_mock\_root

For debugging and/or testing.
Builds a sample object (overwrite this in a test file).

## \_flatten\_for\_tags

Removes for tags from the lol and flattens
out the inner tags to be on the same level as the for
tag was.

## \_lol\_to\_tree

Generates a tree from a Pod::LOL object.
The structure of the tree is based on the N (level) in "=headN".

This example pod:

    =head1 FUNCTIONS

    =Para  Description of Functions

    =head2 Function1

    =Para  Description of Function1

    =head1 AUTHOR

    =cut

This will be grouped as:

    =head1 FUNCTIONS
       =Para Description of Functions
       =head2 Function1
          =Para Description of Function1
    =head1 AUTHOR

In summary:

- Non "head" tags are always grouped "below".
- HeadN tags with a higher N with also be grouped below.
- HeadN tags with the same or lower N will be grouped higher.

## \_define\_heads\_regex\_table

Generates the regexes for head elements inside
and outside the current head.

## \_make\_leaf

Creates a new node (aka leaf).

## \_structure\_over

Restructures the text for an "over-text" element to be under it.
Also, "item-text" will be the first element of each group.

## find\_title

Extracts the title information.

## find\_method

Extracts the complete method information.

## find\_method\_summary

Extracts the method summary.

## \_clean\_method\_name

Returns a method name without any possible parenthesis.

## find\_events

Extracts a list of events with a description.

Returns a list of key value pairs.

## find

Generic extraction command.

Note: This function is Scalar/List context sensitive!

    $query->find($condition)

Where condtion is a string as described in ["\_query\_string\_to\_struct"](#_query_string_to_struct)

    $query->find(@conditions)

Where each condition can contain:

    {
       tag       => "TAG_NAME",    # Find all matching tags.
       text      => "TEXT_NAME",   # Find all matching texts.
       keep      => 1,             # Capture the text.
       keep_all  => 1,             # Capture entire section.
       nth       => 0,             # Use only the nth match.
       nth_in_group => 0,             # Use only the nth matching group.
    }

Return contents of entire head section:

    find (
       {tag => "head", text => "a", keep_all => 1},
    )

Results:

    [
       "  my \$app = a('/hel...",
       {text => "Create a route with ...", wrap => 1},
       "  \$ perl -Mojo -E ...",
    ]

## \_query\_string\_to\_struct

Convert a pod query string into a structure based on these rules:

    1. Split string by '/'.
       Each piece is a separate list of conditions.

    2. Remove an optional '*' or '**' from the last condition.
       Keep is set if we have '*'.
       Keep all is set if we have '**'.

    3. Remove an optional [N] from the last condition.
       (Where N is a decimal).
       Set nth base on 'N'.
       Set nth_in_group if previous word is surrounded by ():
          (WORD)[N]

    4. Double and single quotes are removed from the ends (if matching).

    5. Split each list of conditions by "=".
       First word is the tag.
       Second word is the text (if any).
       If either starts with a tilde, then the word:
          - is treated like a pattern.
          - is case Insensitive.

    Precedence:
       If quoted and ~, left wins:
       ~"head1" => qr/"head"/,
       "~head1" => qr/head/,

## \_check\_conditions

Check if queries are valid.

## \_set\_condition\_defaults

Assigns default query options.

## \_find

Lower level find command.

## \_invert

Previous elements are inside of the child
(due to the way the tree is created).

This method walks through each child and puts
the parent in its place.

## \_render

Transforms a tree of found nodes in a simple list
or a string depending on context.

Pod::Text formatter is used for `Para` tags when `keep_all` is set.

## get\_term\_width

Determines, caches and returns the terminal width.

### Error: Unable to get Terminal Size

If terminal width cannot be detected, 80 will be assumed.

# SEE ALSO

[App::Pod](https://metacpan.org/pod/App%3A%3APod)

[Pod::LOL](https://metacpan.org/pod/Pod%3A%3ALOL)

[Pod::Text](https://metacpan.org/pod/Pod%3A%3AText)

# AUTHOR

Tim Potapov, `<tim.potapov[AT]gmail.com>`

# BUGS

Please report any bugs or feature requests to [https://github.com/poti1/pod-query/issues](https://github.com/poti1/pod-query/issues).

# CAVEAT

Nothing to report.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::Query

You can also look for information at:

[https://metacpan.org/pod/Pod::Query](https://metacpan.org/pod/Pod::Query)
[https://github.com/poti1/pod-query](https://github.com/poti1/pod-query)

# ACKNOWLEDGEMENTS

TBD

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Tim Potapov.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
