# NAME

Pod::Extract - remove pod from file

# SYNOPSIS

    podextract -i path/to/module -o path/to/module-without-pod -p path/to/pod

or use the module...

    use Pod::Extract;

    open my $fh, '<', 'myfile.pm';

    my ($pod, $code, $sections) = extract_pod($fh);

# DESCRIPTION

Parses a Perl script or module looking for pod. Returns the pod and
code in separate objects or prints the code and pod to two different
locations. By default pod is written to STDERR, code to STDOUT.

Instead of returning pod, use the `--markdown` option to return
markdown.

This module does not attempt to check the validity of the pod
syntax. It's just a simple parser that looks for what might pass as
pod within your code. If you've done something odd, don't expect this
module to figure it out.

This module was a result of refactoring lots of Perl modules that had
pod scattered about the module on the basis of Perl Best Practices
recommendations to place pod at the end of a module. In addition to
the obvious standardization this provides for an application, it was
an eye-opening experience finding all the pod errors. ;-)

_This module has very few dependencies (and very few features). If
you want real pod parsing, use [Pod::Simple](https://metacpan.org/pod/Pod%3A%3ASimple)_.

## Options

    --infile, -i      input file
    --outfile, -o     file to write code to 
    --markdown, -m    return markdown
    --podfile, -p     file to write pod to
    --url-prefix, -u  URL prefix (see Pod::Markdown)

## Commands

    extract (default)
    check

## Notes

    If --infile is not specified, script reads from stdin
    If --outfile is not specified, code is written to stdout
    If --podfile is not specified, pod is written to stderr

# METHODS AND SUBROUTINES

## extract\_pod

    extract_pod( file-handle ) 

In list context returns a three element list consisting of the pod,
the code and a hash with section names. In scalar context returns a
hash consisting of the keys `pod`, `code` and `sections`
representing the same objects in list context.

- pod

    The pod text contained in the script or module in the order it was
    encountered.

- code

    The code text with the pod removed.

- sections

    A hash reference containing the section and section titles.

# AUTHOR

Rob Lauer - rlauer@treasurersbriefcase.com

# SEE OTHER

[Pod::Markdown](https://metacpan.org/pod/Pod%3A%3AMarkdown), [Pod::Simple](https://metacpan.org/pod/Pod%3A%3ASimple)

# LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
