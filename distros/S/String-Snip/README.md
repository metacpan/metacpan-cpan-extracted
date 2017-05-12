# NAME

String::Snip - Shorten large substrings in your strings

# SYNOPSIS

    use String::Snip;

    my $large_string = 'blabla , somethingelse=AStringThatIsMuchTooLongToBeDisplayedInALogEntryORAnywhereSensible';

    print String::Snip::snip($large_string);
    # Prints 'blabla, somethingelse=AStringThat ..[SNIP 2345chars].. whereSensible'

## snip

Pure function. Returns the given string with its long substrings shortened.

Usage:

    print String::Snip::snip($large_string);

    print String::Snip::snip($large_string, { max_length => 1000 });

Options:

- max\_length

    Maximum length of a substring. After this length, it gets truncated to a string of `short_length` characters. Default to 2000.
    There is a hard bottom limit at 100.

- short\_length

    Length of shortened substrings. Defaults to 100.
    There is a hard bottom limit at 50.

- substr\_regex

    The regex that captures the substring of this string. Defaults to `\S+`, which will capture any consecutive non-space
    strings. If you want this to capture multiline large strings, you can use `[\\S\\n]+`.

# IDEAS

## Keep the option of outputting your full string

Use that in your log outputs, reserving the full output when your log is in debug mode:

    if( $something_is_debug ){
       $log->debug("Full string:".$large_string);
    }
    $log->info(String::Snip::snip($large_string));

## Use that when you trace large data blobs

For instance if you deal with base64 encoded binary files, it's likely you will have your log filled with meaningless
base64 giant strings. Use this to shorten them!

# CAVEATS

If you use that on structured data (like a JSON structure), this might render your
data invalid. For instance if you have a large base64 string in your JSON, it will be broken
by this. To avoid this being an issue, make sure you have a way to output the whole untouched
thing should you need it.

# SEE ALSO

[String::Truncate](https://metacpan.org/pod/String::Truncate)
