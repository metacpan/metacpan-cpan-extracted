# NAME

SPRAGL::Cgi\_reply - Simple HTTP replies.

# VERSION

1.30

# SYNOPSIS

    use SPRAGL::Cgi_reply;

    my %df = map {(/^(\S+).+\s(\d+)\%/)} grep {/\d\%/} qx[ df ];
    reply_json \%df;

# DESCRIPTION

Simple module for sending simple HTTP replies. Geared towards CGI scripts.

CGI is simple and quick to code for, even though it is not so performant or fashionable. It nevertheless is handy when making quick and dirty web services that are not going to see a lot of load. HTTP Routing is handled by the file system. Adding or removing functionality is easy and orthogonal, like playing with Lego bricks.

The reply methods in SPRAGL::Cgi\_reply will exit when they have been called. The exit is based on "die", so it is catchable.

# FUNCTIONS AND VARIABLES

Loaded by default:
[fail](#fail-c),
[redirect](#redirect-u),
[reply](#reply-s),
[reply\_file](#reply_file-fn),
[reply\_html](#reply_html-d),
[reply\_json](#reply_json-hr),
[set\_header](#set_header-h),
[cexec](#cexec)

Loaded on demand:
[%status\_code](#status_code)

- fail( $c )

    Replies with the given return code plus the standard return message attached to that, and then exits. It can be given a second parameter, a string, to replace the standard return message with. As in:

        fail 404 , 'Lost in Space.'; # Instead of just "fail 404;".

- redirect( $u )

    Replies with a 302 redirect to the given URI, and then exits.

- reply( $s )

    Replies with the given string as plain/text, and then exits.

- reply\_file( $fn )

    Replies with the file content pointed to by the given filename, and then exits.

- reply\_html( $d )

    Replies with the given string as HTML, and then exits.

- reply\_json( $hr )

    Replies with the given hashref transformed into JSON, and then exits.

- set\_header( %h )

    Add and or overwrite the headers that are going to be used in a reply.

- cexec ...

    CGI exec. Executes a system command, and sends a reply of your choice, in one go. Works like exec ought to in a CGI context. Calling it looks like this:

        cexec('mysqldump orders > orders_backup.sql')->reply('Database backup started.');

    Or like this:

        cexec('sudo postfix stop && postfix start')->redirect('status.html');

    You must naturally be very careful about what system commands it is possible to run from your webserver.

- %status\_code

    A hash that maps return codes to standard return messages.

    Only loaded on demand.

## OPTIONAL NAMED PARAMETERS

Optional named parameters can be given in the reply calls. If the name is "redirect" the reply will be like calling the redirect method. If the name is anything else, a header with that name and value will be inserted in the reply. The header will be normalized, by capitalizing words and changing underscores to dashes. The header value will be inserted raw. Be sure to adhere to RFC 8187.

Examples:

    reply $x.' seconds to go!' , refresh => 5; # Inserts a "Refresh: 5" header.

    fail 503 , 'We are down at the moment, please try again later' , 'Retry-After' => $t;

    fail 308 , redirect => 'https://perlmaven.com/'; # Redirecting with another code than 302.

## DEPRECATED

- csystem( $c )

    A CGI system command. Does pretty much what system already does, so use that instead. It is loaded by default.

# DEPENDENCIES

File::Basename

File::Spec

JSON

# KNOWN ISSUES

No known issues.

# TODO

# SEE ALSO

[SPRAGL::Cgi\_read](https://metacpan.org/pod/SPRAGL::Cgi_read)

[CGI](https://metacpan.org/pod/CGI)

# LICENSE & COPYRIGHT

(c) 2022-2023 Bjørn Hee

Licensed under the Apache License, version 2.0

https://www.apache.org/licenses/LICENSE-2.0.txt
