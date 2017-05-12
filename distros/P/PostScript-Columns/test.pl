# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; }
END {print "not ok 1\n" unless $loaded;}
use PostScript::Columns;
$loaded = 1;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use Test;
BEGIN { plan tests => 1 }

my $doc;
ok($doc= pscolumns(
  -size => 5,
  -head => "Left\nLeft Also\tTest Document\tRight",
  -text => join('',<DATA>),
  -foot => scalar(localtime)."\tFoot\tPage \$p of \$pp",
));

if(open DOC, '>test.ps')
{ print DOC $doc; }

__END__
NAME
    MIME-tools - modules for parsing (and creating!) MIME entities

SYNOPSIS
    Here's some pretty basic code for parsing a MIME message, and
    outputting its decoded components to a given directory:

        use MIME::Parser;
         
        # Create parser, and set the output directory:
        my $parser = new MIME::Parser;
        $parser->output_dir("$ENV{HOME}/mimemail");
         
        # Parse input:
        $entity = $parser->read(\*STDIN) or die "couldn't parse MIME stream";
        
        # Take a look at the top-level entity (and any parts it has):
        $entity->dump_skeleton; 

    Here's some code which composes and sends a MIME message
    containing three parts: a text file, an attached GIF, and some
    more text:

        use MIME::Entity;

        # Create the top-level, and set up the mail headers:
        $top = build MIME::Entity Type    =>"multipart/mixed",
                                  From    => "me\@myhost.com",
                                  To      => "you\@yourhost.com",
                                  Subject => "Hello, nurse!";
        
        # Part #1: a simple text document: 
        attach $top  Path=>"./testin/short.txt";
        
        # Part #2: a GIF file:
        attach $top  Path        => "./docs/mime-sm.gif",
                     Type        => "image/gif",
                     Encoding    => "base64";
            
        # Part #3: some literal text:
        attach $top  Data=>$message;
        
        # Send it:
        open MAIL, "| /usr/lib/sendmail -t -i" or die "open: $!";
        $top->print(\*MAIL);
        close MAIL;

DESCRIPTION
    MIME-tools is a collection of Perl5 MIME:: modules for parsing,
    decoding, *and generating* single- or multipart (even nested
    multipart) MIME messages. (Yes, kids, that means you can send
    messages with attached GIF files).

A QUICK TOUR
  Overview of the classes

    Here are the classes you'll generally be dealing with directly:

               .------------.       .------------.           
               | MIME::     |------>| MIME::     |
               | Parser     |  isa  | ParserBase |   
               `------------'       `------------'
                  | parse()
                  | returns a...
                  |
                  |
                  |
                  |    head()       .--------.
                  |    returns...   | MIME:: | get()
                  V       .-------->| Head   | etc... 
               .--------./          `--------'      
         .---> | MIME:: | 
         `-----| Entity |           .--------. 
       parts() `--------'\          | MIME:: | 
       returns            `-------->| Body   |
       sub-entities    bodyhandle() `--------'
       (if any)        returns...       | open() 
                                        | returns...
                                        | 
                                        V  
                                    .--------. read()    
                                    | IO::   | getline()  
                                    | Handle | print()          
                                    `--------' etc...    

    To illustrate, parsing works this way:

    *   The "parser" parses the MIME stream. Every "parser" inherits
        from the "parser base" class, which does the real work. When
        a message is parsed, the result is an "entity".

    *   An "entity" has a "head" and a "body". Entities are MIME message
        parts.

    *   A "body" knows where the data is. You can ask to "open" this
        data source for *reading* or *writing*, and you will get
        back an "I/O handle".

    *   An "I/O handle" knows how to read/write the data. It is an
        object that is basically like an IO::Handle or a
        FileHandle... it can be any class, so long as it supports a
        small, standard set of methods for reading from or writing
        to the underlying data source.

    A typical multipart message containing two parts -- a textual
    greeting and an "attached" GIF file -- would be a tree of
    MIME::Entity objects, each of which would have its own
    MIME::Head. Like this:

        .--------.
        | MIME:: | Content-type: multipart/mixed 
        | Entity | Subject: Happy Samhaine!
        `--------'
             |
             `----.
            parts |
                  |   .--------.   
                  |---| MIME:: | Content-type: text/plain; charset=us-ascii
                  |   | Entity | Content-transfer-encoding: 7bit
                  |   `--------' 
                  |   .--------.   
                  |---| MIME:: | Content-type: image/gif
                      | Entity | Content-transfer-encoding: base64
                      `--------' Content-disposition: inline; filename="hs.gif"

  Parsing, in a nutshell

    You usually start by creating an instance of the MIME::Parser
    manpage (a subclass of the abstract the MIME::ParserBase
    manpage), and setting up certain parsing parameters: what
    directory to save extracted files to, how to name the files,
    etc.

    You then give that instance a readable filehandle on which waits
    a MIME message. If all goes well, you will get back a the
    MIME::Entity manpage object (a subclass of Mail::Internet),
    which consists of...

    *   A MIME::Head (a subclass of Mail::Header) which holds the MIME
        header data.

    *   A MIME::Body, which is a object that knows where the body data
        is. You ask this object to "open" itself for reading, and it
        will hand you back an "I/O handle" for reading the data:
        this is a FileHandle-like object, and could be of any class,
        so long as it conforms to a subset of the IO::Handle
        interface.

    If the original message was a multipart document, the
    MIME::Entity object will have a non-empty list of "parts", each
    of which is in turn a MIME::Entity (which might also be a
    multipart entity, etc, etc...).

    Internally, the parser (in MIME::ParserBase) asks for instances
    of MIME::Decoder whenever it needs to decode an encoded file.
    MIME::Decoder has a mapping from supported encodings (e.g.,
    'base64') to classes whose instances can decode them. You can
    add to this mapping to try out new/experiment encodings. You can
    also use MIME::Decoder by itself.

  Composing, in a nutshell

    All message composition is done via the the MIME::Entity manpage
    class. For single-part messages, you can use the the "build"
    entry in the MIME::Entity manpage constructor to create MIME
    entities very easily.

    For multipart messages, you can start by creating a top-level
    `multipart' entity with the "build" entry in the MIME::Entity
    manpage, and then use the similar the "attach" entry in the
    MIME::Entity manpage method to attach parts to that message.
    *Please note:* what most people think of as "a text message with
    an attached GIF file" is *really* a multipart message with 2
    parts: the first being the text message, and the second being
    the GIF file.

    When building MIME a entity, you'll have to provide two very
    important pieces of information: the *content type* and the
    *content transfer encoding*. The type is usually easy, as it is
    directly determined by the file format; e.g., an HTML file is
    `text/html'. The encoding, however, is trickier... for example,
    some HTML files are `7bit'-compliant, but others might have very
    long lines and would need to be sent `quoted-printable' for
    reliability.

    See the section on encoding/decoding for more details, as well
    as the section on "A MIME PRIMER".

  Encoding/decoding, in a nutshell

    The the MIME::Decoder manpage class can be used to *encode* as
    well; this is done when printing MIME entities. All the standard
    encodings are supported (see the section on "A MIME PRIMER" for
    details):

        Encoding...       Normally used when message contents are...
        -------------------------------------------------------------------
        7bit              7-bit data with under 1000 chars/line, or multipart.
        8bit              8-bit data with under 1000 chars/line.
        binary            8-bit data with possibly long lines (or no line breaks).
        quoted-printable  Text files with some 8-bit chars (e.g., Latin-1 text).
        base64            Binary files.

    Which encoding you choose for a given document depends largely
    on (1) what you know about the document's contents (text vs
    binary), and (2) whether you need the resulting message to have
    a reliable encoding for 7-bit Internet email transport.

    In general, only `quoted-printable' and `base64' guarantee
    reliable transport of all data; the other three "no-encoding"
    encodings simply pass the data through, and are only reliable if
    that data is 7bit ASCII with under 1000 characters per line, and
    has no conflicts with the multipart boundaries.

    I've considered making it so that the content-type and encoding
    can be automatically inferred from the file's path, but that
    seems to be asking for trouble... or at least, for Mail::Cap...

  Other stuff you can do

    If you want to tweak the way this toolkit works (for example, to
    turn on debugging), use the routines in the the MIME::ToolUtils
    manpage module.

  Good advice

    *   Run with `-w' on. If you see a warning about a deprecated
        method, change your code ASAP. This will ease upgrades
        tremendously.

    *   Don't try to MIME-encode using the non-standard MIME encodings.
        It's just not a good practice if you want people to be able
        to read your messages.

    *   Be aware of possible thrown exceptions. For example, if your
        mail-handling code absolutely must not die, then perform
        mail parsing like this:

            $entity = eval { $parser->parse(\*INPUT) };
            
        Parsing is a complex process, and some components may throw exceptions
        if seriously-bad things happen.  Since "seriously-bad" is in the
        eye of the beholder, you're better off I<catching> possible exceptions 
        instead of asking me to propagate C<undef> up the stack.  Use of exceptions in
        reusable modules is one of those religious issues we're never all 
        going to agree upon; thankfully, that's what C<eval{}> is good for.

NOTES
  Terminology

    Here are some excerpts from RFC-1521 explaining the terminology
    we use; each is accompanied by the equivalent in MIME:: module
    terms...

    Message
        From RFC-1521:

            The term "message", when not further qualified, means either the
            (complete or "top-level") message being transferred on a network, or
            a message encapsulated in a body of type "message".

        There currently is no explicit package for messages; under
        MIME::, messages are streams of data which may be read in
        from files or filehandles.

    Body part
        From RFC-1521:

            The term "body part", in this document, means one of the parts of the
            body of a multipart entity. A body part has a header and a body, so
            it makes sense to speak about the body of a body part.

        Since a body part is just a kind of entity (see below), a
        body part is represented by an instance of the MIME::Entity
        manpage.

    Entity
        From RFC-1521:

            The term "entity", in this document, means either a message or a body
            part.  All kinds of entities share the property that they have a
            header and a body.

        An entity is represented by an instance of the MIME::Entity
        manpage. There are instance methods for recovering the
        header (a the MIME::Head manpage) and the body (a the
        MIME::Body manpage).

    Header
        This is the top portion of the MIME message, which contains
        the Content-type, Content-transfer-encoding, etc. Every MIME
        entity has a header, represented by an instance of the
        MIME::Head manpage. You get the header of an entity by
        sending it a head() message.

    Body
        From RFC-1521:

            The term "body", when not further qualified, means the body of an
            entity, that is the body of either a message or of a body part.

        A body is represented by an instance of the MIME::Body
        manpage. You get the body of an entity by sending it a
        bodyhandle() message.

  Compatibility

    As of 4.x, MIME-tools can no longer emulate the old MIME-parser
    distribution. If you're installing this as a replacement for the
    MIME-parser 1.x release, you'll have to do a little tinkering
    with your code.

  Design issues

    Why assume that MIME objects are email objects?
        I quote from Achim Bohnet, who gave feedback on v.1.9 (I
        think he's using the word *header* where I would use
        *field*; e.g., to refer to "Subject:", "Content-type:",
        etc.):

            There is also IMHO no requirement [for] MIME::Heads to look 
            like [email] headers; so to speak, the MIME::Head [simply stores] 
            the attributes of a complex object, e.g.:

                new MIME::Head type => "text/plain",
                               charset => ...,
                               disposition => ..., ... ;

        I agree in principle, but (alas and dammit) RFC-1521 says
        otherwise. RFC-1521 [MIME] headers are a syntactic subset of
        RFC-822 [email] headers. Perhaps a better name for these
        modules would be RFC1521:: instead of MIME::, but we're a
        little beyond that stage now. (*Note: RFC-1521 has recently
        been obsoleted by RFCs 2045-2049, so it's just as well we
        didn't go that route...*)

        However, in my mind's eye, I see a mythical abstract class
        which does what Achim suggests... so you could say:

             my $attrs = new MIME::Attrs type => "text/plain",
                                         charset => ...,
                                         disposition => ..., ... ;

        We could even make it a superclass or companion class of
        MIME::Head, such that MIME::Head would allow itself to be
        initiallized from a MIME::Attrs object.

        In the meanwhile, look at the build() and attach() methods
        of MIME::Entity: they follow the spirit of this mythical
        class.

    To subclass or not to subclass?
        When I originally wrote these modules for the CPAN, I
        agonized for a long time about whether or not they really
        should subclass from Mail::Internet (then at version 1.17).
        Thanks to Graham Barr, who graciously evolved MailTools 1.06
        to be more MIME-friendly, unification was achieved at MIME-
        tools release 2.0. The benefits in reuse alone have been
        substantial.

  Questionable practices

    Fuzzing of CRLF and newline on input
        RFC-1521 dictates that MIME streams have lines terminated by
        CRLF (`"\r\n"'). However, it is extremely likely that folks
        will want to parse MIME streams where each line ends in the
        local newline character `"\n"' instead.

        An attempt has been made to allow the parser to handle both
        CRLF and newline-terminated input.

        *See MIME::ParserBase for further details.*

    Fuzzing of CRLF and newline when decoding
        The `"7bit"' and `"8bit"' decoders will decode both a `"\n"'
        and a `"\r\n"' end-of-line sequence into a `"\n"'.

        The `"binary"' decoder (default if no encoding specified)
        still outputs stuff verbatim... so a MIME message with CRLFs
        and no explicit encoding will be output as a text file that,
        on many systems, will have an annoying ^M at the end of each
        line... *but this is as it should be*.

        *See MIME::ParserBase for further details.*

    Fuzzing of CRLF and newline when encoding/composing
        All encoders currently output the end-of-line sequence as a
        `"\n"', with the assumption that the local mail agent will
        perform the conversion from newline to CRLF when sending the
        mail.

        However, there probably should be an option to output CRLF
        as per RFC-1521. I'm currently working on a good mechanism
        for this.

        *See MIME::ParserBase for further details.*

    Inability to handle multipart boundaries with embedded newlines
        First, let's get something straight: this is an evil, EVIL
        practice. If your mailer creates multipart boundary strings
        that contain newlines, give it two weeks notice and find
        another one. If your mail robot receives MIME mail like
        this, regard it as syntactically incorrect, which it is.

        *See MIME::ParserBase for further details.*

A MIME PRIMER
    So you need to parse (or create) MIME, but you're not quite up
    on the specifics? No problem...

  Content types

    This indicates what kind of data is in the MIME message, usually
    as *majortype/minortype*. The standard major types are shown
    below. A more-comprehensive listing may be found in RFC-2046.

    application
        Data which does not fit in any of the other categories,
        particularly data to be processed by some type of
        application program. `application/octet-stream',
        `application/gzip', `application/postscript'...

    audio
        Audio data. `audio/basic'...

    image
        Graphics data. `image/gif', `image/jpeg'...

    message
        A message, usually another mail or MIME message.
        `message/rfc822'...

    multipart
        A message containing other messages. `multipart/mixed',
        `multipart/alternative'...

    text
        Textual data, meant for humans to read. `text/plain',
        `text/html'...

    video
        Video or video+audio data. `video/mpeg'...

  Content transfer encodings

    This is how the message body is packaged up for safe transit.
    There are the 5 major MIME encodings. A more-comprehensive
    listing may be found in RFC-2045.

    7bit
        No encoding is done at all. This label simply asserts that
        no 8-bit characters are present, and that lines do not
        exceed 1000 characters in length (including the CRLF).

    8bit
        No encoding is done at all. This label simply asserts that
        the message might contain 8-bit characters, and that lines
        do not exceed 1000 characters in length (including the
        CRLF).

    binary
        No encoding is done at all. This label simply asserts that
        the message might contain 8-bit characters, and that lines
        may exceed 1000 characters in length. Such messages are the
        *least* likely to get through mail gateways.

    base64
        A standard encoding, which maps arbitrary binary data to the
        7bit domain. Like "uuencode", but very well-defined. This is
        how you should send essentially binary information (tar
        files, GIFs, JPEGs, etc.).

    quoted-printable
        A standard encoding, which maps arbitrary line-oriented data
        to the 7bit domain. Useful for encoding messages which are
        textual in nature, yet which contain non-ASCII characters
        (e.g., Latin-1, Latin-2, or any other 8-bit alphabet).

TERMS AND CONDITIONS
    Eryq (eryq@zeegee.com), ZeeGee Software Inc
    (http://www.zeegee.com).

    Copyright (c) 1998, 1999 by ZeeGee Software Inc
    (www.zeegee.com).

    All rights reserved. This program is free software; you can
    redistribute it and/or modify it under the same terms as Perl
    itself. See the COPYING file in the distribution for details.

SUPPORT
    Please email me directly with questions/problems (see AUTHOR
    below).

    If you want to be placed on an email distribution list (not a
    mailing list!) for MIME-tools, and receive bug reports, patches,
    and updates as to when new MIME-tools releases are planned, just
    email me and say so. If your project is using MIME-tools, it
    might not be a bad idea to find out about those bugs *before*
    they become problems...

CHANGE LOG
  Future plans

    *   Dress up mimedump and mimeexplode utilities to take cmd line
        options for directory, environment vars (MIMEDUMP_OUTPUT,
        etc.).

    *   Support for S/MIME and message/partial?

  Current events

    Version 4.123
        Cleaned up some of the tests for non-Unix OS'es. Will
        require a few iterations, no doubt.

    Version 4.122
        Resolved CORE::open warnings for 5.005. *Thanks to several
        folks for this bug report.*

    Version 4.121
        Fixed MIME::Words infinite recursion. *Thanks to several
        folks for this bug report.*

    Version 4.117
        Nicer MIME::Entity::build. No longer outputs warnings with
        undefined Filename, and now accepts Charset as well. *Thanks
        to Jason Tibbits III for the inspirational patch.*

        Documentation fixes. Hopefully we've seen the last of the
        pod2man warnings...

        Better test logging. Now uses ExtUtils::TBone.

    Version 4.116
        Bug fix: MIME::Head and MIME::Entity were not downcasing the
        content-type as they claimed. This has now been fixed.
        *Thanks to Rodrigo de Almeida Siqueira for finding this.*

    Version 4.114
        Gzip64-encoding has been improved, and turned off as a
        default, since it depends on having gzip installed. See
        MIME::Decoder::Gzip64 if you want to activate it in your
        app. You can now set up the gzip/gunzip commands to use, as
        well. *Thanks to Paul J. Schinder for finding this bug.*

    Version 4.113
        Bug fix: MIME::ParserBase was accidentally folding newlines
        in header fields. *Thanks to Jason L. Tibbitts III for
        spotting this.*

    Version 4.112
        MIME::Entity::print_body now recurses when printing
        multipart entities, and prints "everything following the
        header." This is more likely what people expect to happen.
        PLEASE read the "two body problem" section of MIME::Entity's
        docs.

    Version 4.111
        Clean build/test on Win95 using 5.004. Whew.

    Version 4.110
        Added make_multipart() and make_singlepart() in
        MIME::Entity.

        Improved handling/saving of preamble/epilogue.

    Version 4.109
    Overall Major version shift to 4.x accompanies numerous structural
            changes, and the deletion of some long-deprecated code.
            Many apologies to those who are inconvenienced by the
            upgrade.

            MIME::IO deprecated. You'll see IO::Scalar,
            IO::ScalarArray, and IO::Wrap to make this toolkit work.

            MIME::Entity deep code. You can now deep-copy MIME
            entities (except for on-disk data files).

    Encoding/decoding
            MIME::Latin1 deprecated, and 8-to-7 mapping removed.
            Really, MIME::Latin1 was one of my more dumber ideas.
            It's still there, but if you want to map 8-bit
            characters to Latin1 ASCII approximations when 7bit
            encoding, you'll have to request it explicitly. *But use
            quoted-printable for your 8-bit documents; that's what
            it's there for!*

            7bit and 8bit "encoders" no longer encode. As per RFC-
            2045, these just do a pass-through of the data, but
            they'll warn you if you send bad data through.

            MIME::Entity suggests encoding. Now you can ask
            MIME::Entity's build() method to "suggest" a legal
            encoding based on the body and the content-type. No more
            guesswork! See the "mimesend" example.

            New module structure for MIME::Decoder classes. It
            should be easier for you to see what's happening.

            New MIME decoders! Support added for decoding `x-
            uuencode', and for decoding/encoding `x-gzip64'. You'll
            need "gzip" to make the latter work.

            Quoted-printable back on track... and then some. The
            'quoted-printable' decoder now uses the newest
            MIME::QuotedPrint, and amends its output with guideline
            #8 from RFC2049 (From/.). *Thanks to Denis N. Antonioli
            for suggesting this.*

    Parsing Preamble and epilogue are now saved. These are saved in the
            parsed entities as simple string-arrays, and are output
            by print() if there. *Thanks to Jason L. Tibbitts for
            suggesting this.*

            The "multipart/digest" semantics are now preserved.
            Parts of digest messages have their mime_type()
            defaulted to "message/rfc822" instead of "text/plain",
            as per the RFC. *Thanks to Carsten Heyl for suggesting
            this.*

    Output  Well-defined, more-complete print() output. When printing an
            entity, the output is now well-defined if the entity
            came from a MIME::Parser, even if using
            parse_nested_messages. See MIME::Entity for details.

            You can prevent recommended filenames from being output.
            This possible security hole has been plugged; when
            building MIME entities, you can specify a body path but
            suppress the filename in the header. *Thanks to Jason L.
            Tibbitts for suggesting this.*

    Bug fixes
            Win32 installations should work. The binmode() calls
            should work fine on Win32 now. *Thanks to numerous folks
            for their patches.*

            MIME::Head::add() now no longer downcases its argument.
            *Thanks to Brandon Browning & Jason L. Tibbitts for
            finding this bug.*

  Old news

    Version 3.204
        Bug in MIME::Head::original_text fixed. Well, it took a
        while, but another bug surfaced from my transition from 1.x
        to 2.x. This method was, quite idiotically, sorting the
        header fields. *Thanks, as usual, to Andreas Koenig for
        spotting this one.*

        MIME::ParserBase no longer defaults to RFC-1522-decoding
        headers. The documentation correctly stated that the default
        setting was to *not* RFC-1522-decode the headers. The code,
        on the other hand, was init'ing this parser option in the
        "on" position. This has been fixed.

        MIME::ParserBase::parse_nested_messages reexamined. If you
        use this feature, please re-read the documentation. It
        explains a little more precisely what the ramifications are.

        MIME::Entity tries harder to ensure MIME compliance. It is
        now a fatal error to use certain bad combinations of content
        type and encoding when "building", or to attempt to "attach"
        to anything that is not a multipart document. My apologies
        if this inconveniences anyone, but it was just too darn easy
        before for folks to create bad MIME, and gosh darn it, good
        libraries should at least *try* to protect you from
        mistakes.

        The "make" now halts if you don't have the right stuff,
        provided your MakeMaker supports PREREQ_PM. See the the
        section on "REQUIREMENTS" section for what you need to
        install this package. I still provide old courtesy copies of
        the MIME:: decoding modules. *Thanks to Hugo van der Sanden
        for suggesting this.*

        The "make test" is far less chatty. Okay, okay, STDERR is
        evil. Now a `"make test"' will just give you the important
        stuff: do a `"make test TEST_VERBOSE=1"' if you want the
        gory details (advisable if sending me a bug report). *Thanks
        to Andreas Koenig for suggesting this.*

    Version 3.203
        No, there haven't been any major changes between 2.x and
        3.x. The major-version increase was from a few more tweaks
        to get $VERSION to be calculated better and more efficiently
        (I had been using RCS version numbers in a way which created
        problems for users of CPAN::). After a couple of false
        starts, all modules have been upgraded to RCS 3.201 or
        higher.

        You can now parse a MIME message from a scalar, an array-of-
        scalars, or any MIME::IO-compliant object (including IO::
        objects.) Take a look at parse_data() in MIME::ParserBase.
        The parser code has been modified to support the MIME::IO
        interface. *Thanks to fellow Chicagoan Tim Pierce (and
        countless others) for asking.*

        More sensible toolkit configuration. A new config() method
        in MIME::ToolUtils makes a lot of toolkit-wide configuration
        cleaner. Your old calls will still work, but with
        deprecation warnings.

        You can now sign messages just like in Mail::Internet. See
        MIME::Entity for the interface.

        You can now remove signatures from messages just like in
        Mail::Internet. See MIME::Entity for the interface.

        You can now compute/strip content lengths and other non-
        standard MIME fields. See sync_headers() in MIME::Entity.
        *Thanks to Tim Pierce for bringing the basic problem to my
        attention.*

        Many warnings are now silent unless $^W is true. That means
        unless you run your Perl with `-w', you won't see
        deprecation warnings, non-fatal-error messages, etc. But of
        course you run with `-w', so this doesn't affect you. `:-)'

        Completed the 7-bit encodings in MIME::Latin1. We hadn't had
        complete coverage in the conversion from 8- to 7-bit; now we
        do. *Thanks to Rolf Nelson for bringing this to my
        attention.*

        Fixed broken parse_two() in MIME::ParserBase. BTW, if your
        code worked with the "broken" code, it should *still* work.
        *Thanks again to Tim Pierce for bringing this to my
        attention.*

    Version 2.14
        Just a few bug fixes to improve compatibility with Mail-
        Tools 1.08, and with the upcoming Perl 5.004 release.
        *Thanks to Jason L. Tibbitts III for reporting the problems
        so quickly.*

    Version 2.13
    New features
            Added RFC-1522-style decoding of encoded header fields.
            Header decoding can now be done automatically during
            parsing via the new `decode()' method in MIME::Head...
            just tell your parser object that you want to
            `decode_headers()'. *Thanks to Kent Boortz for providing
            the idea, and the baseline RFC-1522-decoding code!*

            Building MIME messages is even easier. Now, when you use
            MIME::Entity's `build()' or `attach()', you can also
            supply individual mail headers to set (e.g., `-Subject',
            `-From', `-To').

            Added `Disposition' to MIME::Entity's `build()' method.
            *Thanks to Kurt Freytag for suggesting this feature.*

            An `X-Mailer' header is now output by default in all
            MIME-Entity-prepared messages, so any bad MIME we
            generate can be traced back to this toolkit.

            Added `purge()' method to MIME::Entity for deleteing
            leftover files. *Thanks to Jason L. Tibbitts III for
            suggesting this feature.*

            Added `seek()' and `tell()' methods to built-in MIME::IO
            classes. Only guaranteed to work when reading! *Thanks
            to Jason L. Tibbitts III for suggesting this feature.*

            When parsing a multipart message with apparently no
            boundaries, the error message you get has been improved.
            *Thanks to Andreas Koenig for suggesting this.*

    Bug fixes
            Patched over a Perl 5.002 (and maybe earlier and later)
            bug involving FileHandle::new_tmpfile. It seems that the
            underlying filehandles were not being closed when the
            FileHandle objects went out of scope! There is now an
            internal routine that creates true FileHandle objects
            for anonymous temp files. *Thanks to Dragomir R. Radev
            and Zyx for reporting the weird behavior that led to the
            discovery of this bug.*

            MIME::Entity's `build()' method now warns you if you
            give it an illegal boundary string, and substitutes one
            of its own.

            MIME::Entity's `build()' method now generates safer,
            fully-RFC-1521-compliant boundary strings.

            Bug in MIME::Decoder's `install()' method was fixed.
            *Thanks to Rolf Nelson and Nickolay Saukh for finding
            this.*

            Changed FileHandle::new_tmpfile to FileHandle-
            >new_tmpfile, so some Perl installations will be
            happier. *Thanks to Larry W. Virden for finding this
            bug.*

            Gave `=over' an arg of 4 in all PODs. *Thanks to Larry
            W. Virden for pointing out the problems of bare =over's*

    Version 2.04
        A bug in MIME::Entity's output method was corrected.
        MIME::Entity::print now outputs everything to the desired
        filehandle explicitly. *Thanks to Jake Morrison for pointing
        out the incompatibility with Mail::Header.*

    Version 2.03
        Fixed bug in autogenerated filenames resulting from
        transposed "if" statement in MIME::Parser, removing spurious
        printing of header as well. (Annoyingly, this bug is
        invisible if debugging is turned on!) *Thanks to Andreas
        Koenig for bringing this to my attention.*

        Fixed bug in MIME::Entity::body() where it was using the
        bodyhandle completely incorrectly. *Thanks to Joel Noble for
        bringing this to my attention.*

        Fixed MIME::Head::VERSION so CPAN:: is happier. *Thanks to
        Larry Virden for bringing this to my attention.*

        Fixed undefined-variable warnings when dumping skeleton
        (happened when there was no Subject: line) *Thanks to Joel
        Noble for bringing this to my attention.*

    Version 2.02
        Stupid, stupid bugs in both BASE64 encoding and decoding
        were fixed. *Thanks to Phil Abercrombie for locating them.*

    Version 2.01
        Modules now inherit from the new Mail:: modules! This means
        big changes in behavior.

        MIME::Parser can now store message data in-core. There were
        a *lot* of requests for this feature.

        MIME::Entity can now compose messages. There were a *lot* of
        requests for this feature.

        Added option to parse `"message/rfc822"' as a pseduo-
        multipart document. *Thanks to Andreas Koenig for suggesting
        this.*

  Ancient history

    Version 1.13
        MIME::Head now no longer requires space after ":", although
        either a space or a tab after the ":" will be swallowed if
        there. *Thanks to Igor Starovoitov for pointing out this
        shortcoming.*

    Version 1.12
        Fixed bugs in parser where CRLF-terminated lines were
        blowing out the handling of preambles/epilogues. *Thanks to
        Russell Sutherland for reporting this bug.*

        Fixed idiotic is_multipart() bug. *Thanks to Andreas Koenig
        for noticing it.*

        Added untested binmode() calls to parser for DOS, etc.
        systems. No idea if this will work...

        Reorganized the output_path() methods to allow easy use of
        inheritance, as per Achim Bohnet's suggestion.

        Changed MIME::Head to report mime_type more accurately.

        POSIX module no longer loaded by Parser if perl >= 5.002.
        Hey, 5.001'ers: let me know if this breaks stuff, okay?

        Added unsupported ./examples directory.

    Version 1.11
        Converted over to using Makefile.PL. *Thanks to Andreas
        Koenig for the much-needed kick in the pants...*

        Added t/*.t files for testing. Eeeeeeeeeeeh...it's a start.

        Fixed bug in default parsing routine for generating output
        paths; it was warning about evil filenames if there simply
        *were* no recommended filenames. D'oh!

        Fixed redefined parts() method in Entity.

        Fixed bugs in Head where field name wasn't being case
        folded.

    Version 1.10
        A typo was causing the epilogue of an inner multipart
        message to be swallowed to the end of the OUTER multipart
        message; this has now been fixed. *Thanks to Igor
        Starovoitov for reporting this bug.*

        A bad regexp for parameter names was causing some parameters
        to be parsed incorrectly; this has also been fixed. *Thanks
        again to Igor Starovoitov for reporting this bug.* It is now
        possible to get full control of the filenaming algorithm
        before output files are generated, and the default algorithm
        is safer. *Thanks to Laurent Amon for pointing out the
        problems, and suggesting some solutions.*

        Fixed illegal "simple" multipart test file. D'OH!

    Version 1.9
        No changes: 1.8 failed CPAN registration

    Version 1.8.
        Fixed incompatibility with 5.001 and FileHandle::new_tmpfile
        Added COPYING file, and improved README.

AUTHOR
    MIME-tools was created by:

        ___  _ _ _   _  ___ _     
       / _ \| '_| | | |/ _ ' /    Eryq, (eryq@zeegee.com)
      |  __/| | | |_| | |_| |     President, ZeeGee Software Inc.
       \___||_|  \__, |\__, |__   http://www.zeegee.com/
                 |___/    |___/   

    Released as MIME-parser (1.0): 28 April 1996. Released as MIME-
    tools (2.0): Halloween 1996. Released as MIME-tools (4.0):
    Christmas 1997.

VERSION
    $Revision: 4.124 $

ACKNOWLEDGMENTS
    This kit would not have been possible but for the direct
    contributions of the following:

        Gisle Aas             The MIME encoding/decoding modules.
        Laurent Amon          Bug reports and suggestions.
        Graham Barr           The new MailTools.
        Achim Bohnet          Numerous good suggestions, including the I/O model.
        Kent Boortz           Initial code for RFC-1522-decoding of MIME headers.
        Andreas Koenig        Numerous good ideas, tons of beta testing,
                                and help with CPAN-friendly packaging.
        Igor Starovoitov      Bug reports and suggestions.
        Jason L Tibbitts III  Bug reports, suggestions, patches.
     
    Not to mention the Accidental Beta Test Team, whose bug reports (and
    comments) have been invaluable in improving the whole:

        Phil Abercrombie
        Mike Blazer
        Brandon Browning
        Kurt Freytag
        Steve Kilbane
        Jake Morrison
        Rolf Nelson
        Joel Noble    
        Michael W. Normandin 
        Tim Pierce
        Andrew Pimlott
        Dragomir R. Radev
        Nickolay Saukh
        Russell Sutherland
        Larry Virden
        Zyx

    Please forgive me if I've accidentally left you out. Better yet,
    email me, and I'll put you in.

SEE ALSO
    Users of this toolkit may wish to read the documentation of
    Mail::Header and Mail::Internet.

    The MIME format is documented in RFCs 1521-1522, and more
    recently in RFCs 2045-2049.

    The MIME header format is an outgrowth of the mail header format
    documented in RFC 822.

