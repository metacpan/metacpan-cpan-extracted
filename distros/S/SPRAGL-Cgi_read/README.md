# NAME

SPRAGL::Cgi\_read - Barebones CGI.

# VERSION

0.71

# SYNOPSIS

    use SPRAGL::Cgi_read;

    # Reading a header.
    my $greet = "Buon Giorno" if header("Accept-Language") =~ m/\b it \b/x;

    # Reading a parameter value.
    my $id = param->{ID}; # Parameter names are case sensitive.

    # Multi value parameters.
    for my ($i,$val) ( each param_all("files")->@* ) {
        write_to_log "processing ".meta_all("files")->[$i]->{filename};
        do_something( ${val} );
        };

# IDIOMS

    param->{p}          # first value of parameter p
    param_all('p')->@*  # all values assigned to parameter p
    param_all('p')->[2] # the third value assigned to parameter p
    meta->{p}           # metadata for first value of parameter p
    meta_all('p')->@*   # metadata for every value assigned to parameter p
    meta_all('p')->[2]  # the metadata for the third value assigned to parameter p
    keys param->%*      # list of all parameter names sent in the request

# DESCRIPTION

Barebones module for handling CGI requests. It is applicative and lightweight, and has only a few dependencies.

CGI is simple and quick to code for, even though it is not so performant or fashionable. It nevertheless is handy when making quick and dirty web services that are not going to see a lot of load. HTTP Routing is handled by the file system. Adding or removing functionality is easy and orthogonal, like playing with Lego bricks.

For decades CGI.pm has been the gold standard for doing CGI with Perl. It is a big featureful module, and in many cases that is what is needed. But in other cases you just need a simple basic module.

SPRAGL::Cgi\_read.pm exists so you dont have to use CGI.pm.

The SPRAGL::Cgi\_read module follows Postels Law (be conservative in what you do, be liberal in what you accept). So in case a request is a bit off, the module will not right out fail, but will try to get fairly intelligible data out of it.

## OPTIMIZATIONS

The SPRAGL::Cgi\_read module optimizes ressources based on the imports of the CGI script. This works without further ado for normal scripts. But if the script references a method or variable using the SPRAGL::Cgi\_read namespace, then it should specify so in its import statement. This is done by prefixing "::" to the import. For example

    use SPRAGL::Cgi_read qw(param $uri ::meta ::$method);
    use SPRAGL::Cgi_reply;

    my $custname = param->{name};
    my $custmeta = SPRAGL::Cgi_read::meta(name);
    reply "URI was ".$uri." and method was ".$SPRAGL::Cgi_read::method;

If these imports are not specified, calls and lookups might give the wrong values.

## COMMAND LINE

With SPRAGL::Cgi\_read you can run your CGI scripts from the commandline. This is convenient when debugging or testing. The script will be run as if a GET request with no data started it. But by using options, you can change that.

**-c**

Emulate that the request was a POST request. Send the content to it on STDIN.

**-H &amp;lt;string&amp;gt;**

Emulate that the request had the given header field.

**-q &amp;lt;string&amp;gt;**

Emulate that the request had the given querystring.

Example:

    perl index.pl -H "Referer: https://news.ycombinator.com/" -q "?tag=mars"

# FUNCTIONS AND VARIABLES

Loaded by default:
[param](#param),
[meta](#meta),
[param\_all](#param_all-p),
[meta\_all](#meta_all-p),
[header](#header-h)

Loaded on demand:
[$method](#method),
[$uri](#uri),
[%header](#header),
[$content](#content),
[$cgi\_mode](#cgi_mode)

- param()

    Gives a hashref with values for all parameters in the request.

    In case a parameter name is assigned a value multiple times, the hashref will only contain "the first" of them.

    If the request contained data without any parameter information, that data will be assigned the name "" (empty string). In that case, it will be the only parameter recognized in the request.

    Parameter names can consist of any characters, but special characters need to be encoded in the request. The module only prevents the name "" (empty string), as it is reserved for the value that has no parameter name.

- meta()

    Gives a hashref with metadata for the parameters in the request.

    The keys are the parameter names. The values are hashrefs themselves. Their keys can be:
    \- name (string) - The name of the parameter. Same as the key used to look up the hashref.
    \- type (string) - The content-type of the value.
    \- filename (string) - The filename used locally on the client.
    \- header (hashref) - Headers specific for the value.

- param\_all( $p )

    Gives a listref of values for the given parameter name.

    If the parameter name was not in the request, the list is empty.

- meta\_all( $p )

    Gives a listref of metadata entries for the given parameter name.

    The list mirrors the list given by the param\_all function. Each entry is a hashref built the same way the metadata, given by the meta function, is.

- header( $h )

    Gives the value of the given header name.

    Gives undef if the given header name was not in the request.

    Note that two strings can be different, but be the same header name. To this module header names are US-ASCII case-insensitive, and dashes and underscores are equivalent.

    Only headers provided by the web servers CGI interface can be looked up.

- $method

    The method of the request. It can be one of the strings "GET", "HEAD", "POST", "PUT", "DELETE", "OPTIONS", "CONNECT", "PATCH" and "TRACE". Only in case of the "POST", "PUT", "PATCH" methods are parameters read from the request content. In case of the "TRACE" method any parameters sent are ignored.

    Only loaded on demand.

- $uri

    The relative URI of the request. It will contain a querystring, if that was part of the URI the client used.

    Only loaded on demand.

- %header

    The request headers are available as the %header hash. Only the headers that are passed on by the web servers CGI interface can be found in the hash. The header names are reformatted, attempting to follow common practice. For example the CGI name "HTTP\_ACCEPT\_LANGUAGE" will be rewritten to "Accept-Language".

    Only loaded on demand.

- $content

    The content of the request, available as the string `$content`.

    Only loaded on demand.

- $cgi\_mode

    Is true if the script, that uses SPRAGL::Cgi\_read, has been started from CGI.

    Only loaded on demand.

# DEPENDENCIES

Encode

List::Util

Scalar::Util

# KNOWN ISSUES

Limited testing. Should work with all major web servers.

# TODO

# SEE ALSO

[SPRAGL::Cgi\_reply](https://metacpan.org/pod/SPRAGL::Cgi_reply)

[CGI](https://metacpan.org/pod/CGI)

# LICENSE & COPYRIGHT

(c) 2022-2023 Bjørn Hee

Licensed under the Apache License, version 2.0

https://www.apache.org/licenses/LICENSE-2.0.txt
