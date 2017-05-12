1;
__END__
=pod

=head1 NAME

ScraperPOD - A Framework for scraping results from search engines.

=head1 SYNOPSIS

=over 1

=item use WWW::Scraper;

 # Name your Scraper module / search engine as the first parameter,
 use WWW::Scraper('eBay');
 # or in the new() method
 $scraper = new WWW::Scraper('eBay');

=item Classic WWW::Search mode

 # Use a Scraper engine just as you would a WWW::Search engine.    
 $scraper = new WWW::Scraper('carsforsale', 'Honda', { 'lbxModel' => 'Accord', 'lbxVehicleYearFrom' => 1998 });
 while ( $response = $scraper->next_result() ) {
     # harvest results via hash-table reference.
     print $scraper->{'sellerPhoneNumber'};
 }

=item Canonical Request/Response mode (not yet implemented)

 $scraper = new WWW::Scraper('carsforsale', 'Request' => 'Autos', 'Response' => 'Autos');
 # or, since 'carsforsale.pm' defaults to the Request and Response classes of 'Autos'
 $scraper = new WWW::Scraper('carsforsale');
 #
 # Set field values via field-named canonical access methods.
 $scraper->scraperRequest->make('Honda');
 $scraper->scraperRequest->model('Accord');
 $scraper->scraperRequest->minYear(1998);
 #
 # Note: this is *not* next_result().
 while ( $response = $scraper->next_response() ) {
     #
     # harvest results via field-named access methods.
     print $response->sellerPhoneNumber();
 }

=item Variant Requests to a single search engine

 $scraper = new WWW::Scraper('carsforsale');
 $scraper->scraperRequest->make('Honda');
 $scraper->scraperRequest->minYear(1998);
 #
 for ( $model = ('Accord' 'Civic') ) {
     $scraper->scraperRequest->model($model);
     $response = $scraper->next_response() ) {
     # all response fields are returned as a reference to the value.
     print ${$response->sellerPhoneNumber()};
 }

=item Single Request to variant search engines

 # Set the request parameters in a Request object (sub-class 'Autos').
 $request = new WWW::Scraper::Request('Autos');
 $request->make('Honda');
 $request->model('Accord');
 $request->minYear(1998);
 #
 for ( $searchEngine = ('carsforsale' '1001cars') ) {
     $scraper = new WWW::Scraper($searchEngine, 'Request' => $request);
     for ( $response = $scraper->next_response() ) {
         # all response fields are returned as a reference to the value.
         print ${$response->sellerPhoneNumber()};
 }

=back

=head1 DESCRIPTION

=over 1

=item SCRAPER FRAMEWORK

 [============================================================================]
 [                                                                            ]
 [        Your Request Values                   The Response Values           ]
 [                 |                                     ^                    ]
 [                 v                                     |                    ]
 [     +-------------------------+         +-------------------------+        ]
 [     |                         |         |                         |        ]
 [     |    Request Object       |         |    Response Object      |        ]
 [     |                         |         |                         |        ]
 [     |   [e.g. Auction.pm]     |         |    [e.g. Auction.pm]    |        ]
 [     |   (custom, or auto-     |         |   (custom, or auto-     |        ]
 [     |   gened by Scraper.pm)  |         |   gened by Scraper.pm)  |        ]
 [     |                         |         |                         |        ]
 [     +-------------------------+         +-------------------------+        ]
 [                      |                          ^                          ]
 [                      |                          |                          ]
 [                      |                          |                          ]
 [                      V                          |                          ]
 [              +---------------------------------------------+               ]
 [              |                                             |               ]
 [              |               Scraper Engine                |               ]
 [              |                                             |               ]
 [              |       [e.g. Brainpower.pm, eBay.pm]         |               ]
 [              |  (these are customized by Scraper authors)  |               ]
 [              |                                             |               ]
 [              +---------------------------------------------+               ]
 [                           |             ^                                  ]
 [                           |             |                                  ]
 [                           |             |                                  ]
 [                           v             |                                  ]
 [              +---------------------------------------------+               ]
 [              |                                             |               ]
 [              |            WWW Search Engine                |               ]
 [              |                                             |               ]
 [              |  [e.g. www.Brainpower.com, www.eBay.com]    |               ] 
 [              |  (these are the live, commercial, sites)    |               ]
 [              |                                             |               ]
 [              +---------------------------------------------+               ]
 [                                                                            ]
 +============================================================================+

"Scraper" is a framework for issuing queries to a search engine, and scraping the
data from the resultant multi-page responses, and the associated detail pages.

As a framework, it allows you to get these results using only slight knowledge
of HTML and Perl.

A full-featured example, "Scraper.pl", uses Scraper.pm to investigate the "advanced search page"
of a search engine, issue a user specified query, and parse the results. Scraper.pm can
be used by itself to support more elaborate searching Perl scripts. Scraper.pl and Scraper.pm
have a limited amount of intelligent to figure out how to interpret the search page and
its results. That's where your human intelligence comes in. You need to supply hints to 
Scraper to help it find the right interpretation. And that is why you need some limited
knowledge of HTML and Perl.

=back

=head1 MAJOR FEATURES

=over 1

=item Framing

A simple opcode based language makes describing the results and details pages of new engines easy,
and adapting to occasional changes in an existing engine's format simple.

=item Canonical Requests

A common Request container makes multiple search engine searches easy to implement, and 
automatically adapts to changes.

=item Canonical Response

A common Response container makes interpretation of results common among all search engines possible.
Also adapts easily to changes.

=item Post-filtering

Post-filtering provides a powerful client-based extension of the search capabilities to all search engines.

=back

=head1 SCRAPER ENGINE

Sometimes referred to as the "Scraper module", this module is customized by Scraper authors.
It defines the search engines URL, the fields in that engine's request form, and the parsing
rules to scrape the resultant fields from the result page (and sometimes from detail pages).

An individual Scraper engine may also specify field translations for each type of Request or Response sub-classes.
It also may massage the data a bit before passing it on (removing HTML tags, for instance).

=head1 REQUEST OBJECT

The Request object is a sub-class of the Request class (see C<WWW::Scraper::Request>).
It translates your request parameters from their "canonical" form to the native values and field names.
For instance, Jobs.pm (a Request sub-class) translates "location" values for Dice.com from

        location='CA-San Jose' => acode=408

For Monster.com, the same "canonical" location would be translated to

        location='CA-San Jose' => lid=356

A Request object will be created in one of two modes, depending on how you instantiate it.

=over 4

=item Native: Each parameter is "native" to the search engine

Each parameter you supply will be handed to the search engine exactly as you specify,
with the same name and value. Seems obvious, but the disadvantage of this is that you
must supply custom parameters to each search engine. You need to know what the parameter
names are, and exactly what values are allowed.


=item Canonical: Each parameter will be translated to native values by the Request class

The canonical mode allows you to use a common set of parameter names and values.
The Request class will translate those common parameters to native parameters to be passed on to each search engine.


=item How do you get it to be Native or Canonical?

If you create your Request object directly from the base class (Scraper::Request), as in

    $request = new WWW::Scraper::Request( . . . );

then it will be a "native" request. You must supply parameter names and values that correspond
exactly with what the target search engine expects.

If you create your Request object as one of the subclasses of Request, as in

    $request = new WWW::Scraper::Request::Job( . . . );

then it is a "canonical" request. You supply common parameter names and values (as in 'skills' => 'Perl')
and the Request::Jobs class translates each parameter to the name and value expected by the target search engine.

If you do not create a Request object (you just let Scraper create one), as in

    $request = new WWW::Scraper('Google', { . . . });

then the associated implicit Request object will be the style that the associated Scraper module specifies.
For Google, it would be native; for Brainpower, it is Request::Job, which is canonical.

Regardless of how it is instantiated, the type of the Request object can be found with the method C<_isCanonical()>,
which will be the name of the canonical sub-class (e.g., 'Job').

Optimally, there would be a seperate Request sub-class for each search engine and Request type (e.g., Jobs, or Auctions).
This would lead to an immense number of modules in the Scraper Perl package. A feature of the Request base class can
be used to mitigate this possibility; see L<WWW::Scraper::FieldTranslations>.

=item What if I *want* native mode?

C<"new Scraper()"> will create a canonical Request by default (if the Scraper engine supplys it),
but what if you want complete control over the native parameters?
You can get that by prepending the string "NativeRequest::" to the name of your Scraper engine, as in

    $scraper = new WWW::Scraper('NativeRequest::HotJobs', . . .);

This will create a native Request object by default instead of the canonical Request.
Note that there is no actual C<Scraper::NativeRequest::HotJobs> module.
This is just a syntactic gimmick to tell C<"new Scraper()"> to use a non-canonical, native mode for the Request.

=back

The Request class is also responsible for "post-selection".
This feature allows you to filter out responses from the search engine based on more sophisticated criteria
than the search engine itself may provide (by bid-count on eBay, for instance, or by reading and filtering by data from the detail page).

The Request sub-class is normally automatically generated by C<Scraper.pm>.
It will generate this from specifications it finds in the Scraper module,
but you can specify your own override of that auto-generated Request sub-class
(either as a user, or as a Scraper module author).

=head1 RESPONSE OBJECT

The Response object is a sub-class of Response class (see C<WWW::Scraper::Response>).
It translates the native field values from the Scraper module to their "canonical" form.

The Response sub-class is normally automatically generated by C<Scraper.pm>.
It will generate this from specifications it finds in the Scraper module,
but you can specify your own override of that auto-generated Request sub-class
(either as a user, or as a Scraper module author).

(This class is not yet as fully developed as the Request class. Stay tuned!)

=head1 USING SCRAPER

=over 1

=item new

In addition to its special modes, Scraper can be used in the same style as WWW::Search engines.

    $scraper = new WWW::Scraper($engineName, {'fieldName' => $fieldValue});

This sets up a request on the named $engineName, with native field names and values from the hash-table.
Note that the basic native query is not treated specially by Scraper, as it is for WWW::Search.
You would specify the native query as just another one of the options in the hash-table.

Additionally, Scraper allows you to set up the canonical Request and Response classes.

    $scraper = new WWW::Scraper($engineName, $requestClassName, $responseClassName, {'fieldName' => $fieldValue});

You can specify these in any order, and all but $engineName are optional.
Scraper.pm is smart enough to figure out the type of each parameter, and will default these to classes appropriate to the $engineName.

Finally, you can specify specific Request and Response objects if you prefer.

    $requestObject = new WWW::Scraper::Request($requestClassName);
    $responseObject = new WWW::Scraper::Response($responseClassName);
    $scraper = new WWW::Scraper($engineName, $requestObject, $responseObject, {'fieldName' => $fieldValue});

In this mode, you can reuse the same Request with multiple Scraper engines.
The responses in the Response object will be cleared out before handing of to the new Scraper engine.

=back

=head1 BUILDING NEW SCRAPERS

=head2 FRONT-END

The front-end of each Scraper module is the part that figures out the search page and issues a query.
There are three ways to implement this end.

=head3 Three Ways to Issue Requests

=over 4

=item Use Sherlock

Apple Computer and Mozdev have established a standard format for accessing search engines named "Sherlock".
Via a "plugin" that describes the search engine's submission form and results pages, both Mac's and Mozilla
can access many search engines via a common interface. The Perl package C<WWW::Scraper::Sherlock> can read Sherlock
plugins and access those sites the same way.

This is simplest way to get up and running on a search engine. You just name the plugin, provide your query,
and watch it fly! You do not even need a sub-module associated with the search engine for this approach.
See C<WWW::Scraper::Sherlock> for examples of how this is done.

There are about a hundred plugins available at F<http://sherlock.mozdev.org/source/browse/sherlock/www/>,
contributed by many in the Open Source community.

There are a few drawbacks to this approach.

=over 4

=item Not all search engines have plugins.

Obviously, you are limited in this approach to those search engines that have plugins already built.
(You can build a plugin yourself, which is remarkably easy.  See F<http://www.apple.com/sherlock/plugindev.html>.)

=item The Sherlock standard is somewhat limited.

You can supply the value for only one of the
fields in the submission form. This still makes Sherlock pretty valuable, since it's rare that a search engine
will have more than one interesting field to fill in (and WWW::Scraper::Sherlock will allow you to set other field
values, even though that's not in the Sherlock standard.)

=item The Sherlock standard does not parse all the interesting data from the response.

Sherlock parses only a half-dozen interesting fields from the data. Your client is left with the burden of parsing the
rest from the 'result' data field.

=item Sherlock parses only the first page of the response.

You should set the results-per-page to a high value. Sherlock will not go to the "Next" page.

=item Not all Sherlock plugins are created equal.

You'll find that many of the plugins simply do not work. This is in spite of the fact that Sherlock includes
an automatic updating feature. But if you're updating to a version that doesn't work either, then you're kind of stuck!

=back

If you run into these limitations, then you may want to use one of the following approaches.

=item Load-and-parse the submission <FORM>

Scraper has the capability to automatically load the submission form, parse it, and create the query request.
All you do is supply the URL for the submission form, and the query parameter(s). Scraper loads and parses the form,
fills in the fields, and pushes the submit button for you. All you need to do is parse the results in the back-end.

=item Parse the <FORM> manually.

Go get the form yourself, and view the source. Editing the "scraperFrame" structure of your search module,
find the URL of the ACTION= in the <FORM>, and plug that into your search module's C<'url'> attribute.
Also provide the METHOD= value from the <FORM> into the C<'type'> attribute.
You'll find the input fields in the <FORM> as <INPUT> elements.
List these in the C<'nativeDefaults'> hash-table. Set a default for each, or C<undef>.
Scraper will use this table to discover the input field names for the default Request object.

=back

See the EXAMPLES below for these two latter approaches.

=head3 prepare ( Canonical )

Anyway you go about executing a request, it is desirable to use a canonical interface to the user.
This allows the user to create one request, based on a "canon" of how requests should be formed,
that can be presented to any Scraper module and that module will understand what to do with it.
To make this work, each Scraper module must include a method for translating the canonical request
into a native request to their search engine. This is done with the prepare() method. If you are
going to write your own Scraper module, then you should write a prepare() method as well.

See the canonical request module F<WWW::Scraper::Request> for a description of the canonical form,
and how the Scraper module uses it to generate a native form.
F<WWW::Scraper> contains a prepare() method itself, which links up with the FieldTranslation class,
which will translate from a canonical field to one or more native fields.
It is based on a table lookup in so-called "tied-translation tables".
It also performs a "postSelect()" operation (via FieldTranslation) based on a table lookup in the same "tied-translation table".
See F<eg/setupLocations.pl> for an example of how this is used (in this case, for the canonical "locations" field).
See guidelines presented in F<WWW::Scraper::Request> to get the best, most adaptable results.

=head2 BACK-END

The back-end of Scraper.pm receives the response from the search engine, handling the multiple pages
which it may be composed of, parses the results, and returns to the caller an appropriate Perl
representation of these results ("appropriate" means an array of hash tables of type WWW::Search::SearchResult).
Scraper.pl (or some other Perl client) further processes this data, or presents in some human readable form.

There are a few common ways in which search engines return their results in the HTML response.
These could be detected by Scraper.pm if it were intelligent enough, but unfortunately most
search engines add so much administrative clutter, banner ads, "join" options, and so forth
to the result that Scraper.pm usually needs some help in locating the real data.

The Scraper scripting language consists of both HTML parsing and string searching commands.
While a strict HTML parse should produce the most reliable results, as a practical matter it
is sometimes extremely difficult to grok just what the HTML structure of a response is (remember, these
reponses are composed by increasingly complex application server programs.) Therefore, it is necessary to provide
some hints as to where to start an interpretation by giving Scraper some kind of string searching
command.

The string searching commands (BODY, COUNT, NEXT) will point Scraper to approximately
the right place in the response page, while HTML parsing commands (TABLE, TR, TD, etc) will precisely
extract the exact data. There are also ways to to callbacks into your sub-module to do exactly the
type of parsing your engine requires.

Scraper performs its function by viewing the entire response page at once. Whenever a particular section
of the page is recognized, it will process that section according to your instructions, then discard the
recognized text from the page. It will repeat until no further sections are recognized.

We'll illustrate the exact syntax of this language in later examples, but 
the commands in this language include:

=over 4

=item BODY

This command directs Scraper to a specific section of the result page. Two parameters on the
BODY command give it a "start-string" and an "end-string". Scraper will search the result page
for these two strings, throw away everything before the "start-string" (including the start-string),
throw away everything after the "end-string" (including the end-string), then continue processing
with the remainder.

This is a quick way to get rid of a lot of administrative clutter. Either of the parameters is optional,
but one should be supplied or else it's a no-op.

Both start-string and end-string are treated as "regular expressions". If you don't know anything
about regular expressions, that's ok. Just treat them as strings that you would search for
in the result page; see the examples.

=item COUNT

This command provides a string by which Scraper will locate the "approximate count". It is a regular
expression (see comments above). See the examples for some self-explanatory illustrations.

=item NEXT

This command provides a string by which Scraper will be able to locate the "NEXT" button. You supply a string
that you expect to appear as text in the NEXT button anchor element (this is easier to find than you might expect.
A simple search for "NEXT" often does the trick.)

It is a regular expression (see comments above). See the examples for some self-explanatory illustrations.

=item TABLE, TR, DL or FORM

These commands are the HTML parsing commands. They use strict HTML parsing to zero in on areas containing actual data.

=item TD, DT and DD

These commands declare the locations of the actual data elements. Some search engines use <TD> elements to
present data, some use <DT> and <DD> elements.
(Some use neither, which is why you'll need to use C<DATA> or C<REGEX> on these.)
The first parameter on the TD, DT or DD command names the field in which the garnered data will be placed.
A second parameter provides a reference to optional subroutine for further processing of the data.

=item DATA

DATA is like BODY in that it specifies a specific area of the document according to start and end strings.
It's different in that it will take that text and store it as result data rather than further processing it.

=item A, AN and AQ

Often, data and a hyperlink (to a detail page, for instance) are presented simultaneously in an "anchor", <A></A>, element.
Two parameters on the A command name the fields into which the garnered link and data will be placed.

There are two forms of the C<A> command since some loosely coded HTML will supply the hyperlink without the quote marks.
This creates some disturbing results sometimes, so if your data is in an anchor where the HREF is
provided without quotes, then the C<AN> operation will parse it more reliably.

The AQ option is an 'A' option, plus the stipulation that the content of the anchor should match the given regex.
For example:

    [ 'AQ', 'more', 'url', 'title' ]
    
will assign 'url' and 'title' fields if it can find an <A> element that contains the word "more" in its text.
(The match is case-insensitive.)

=item SNIP

This command will remove all regions that match the given regex from the content.
This is useful for those cases, for instance, where a search engine will put HTML tags inside of comments,
thus confusing the HTML scanning process. Since Scraper matches both HTML and any text simultaneously,
it is impossible to assume that HTML in a comment is not relevant to the scrape. SNIP is the way you
can tell it so by either removing all comments, or only those comments that match the regex. SNIP, of course,
can be used to snip out any kind of text, not just comments.

For instance, to remove all comments, code

    [ 'SNIP', '<!--.*?-->', [next scraper frame] ]
    
To remove only comments that contain an embedded '<td>' string (as appears in NorthernLight.com), code

    [ 'SNIP', '<!--[^>]*?<td>.*?-->', [next scraper frame] ]

=item XPath

Find significant data by specifying the XPath to that data's region. 
This requires the TidyXML method to convert HTML to well-formed XML.

    [ 'XPath', 'font/a/@href', 'url', \&trimXPathHref ]

This finds the HREF attribute of the anchor in the <font> element, processes it with the trimXPathHref function,
then assigns it to the 'url' response field.

See F<http://www.w3.org/TR/xpath> to learn how to code "location paths" in the XPath language.

See FlipDog.pm and Dogpile.pm for examples of 'XPath' in Scraper engines.

=item TidyXML

Instead of 'HTML', use 'TidyXML' to convert the HTML to well-formed XML before processing.
This changes the structure slightly, but especially it makes it accessible to the XPath method for locating data.

    [ 'TidyXML', \&cleanupHeadBody, \&removeScriptsInHTML, [ [ frame ] ] ]

The functions (cleanupHeadBody() and removeScriptsInHTML) are executed on the HTML before handing it to TidyXML.
These two functions are handy, in that TidyXML doesn't like stuff in </HEAD>. . .<BODY> (which some engines produce),
and scripts in some engines results often contain unrecognized entities, but are otherwise useless content to us.    

See FlipDog.pm and Brainpower (detail page) for examples.

=item HIT*

This command declares that the hits are about to be coming!
There are several formats for this command; they declare the hit is here, the type of the hit, and how to parse it.
An optional second parameter names the type of WWW::Scraper::Response class will encapsulate the response.
This parameter may be a string, naming the class ('Job', or 'Apartment', for instance), or it may be a reference
of a subroutine that instantiates the response (as if C<new WWW::Scraper::Response::Job>, for instance).
(You may override this with a 'scraperResultType' option on Scraper->new().)
The last parameter (being second or third parameter, depending if you declare a hit type) specifies a Scraper script,
as described here, for parsing all the data for one complete record.
HIT* will process that script, instantiate a Response object, stash the results into it, discarding the parsed text,
and continuing until there is no more parsable data to be found.

=item FOR

For iteration - specify a interator name, and a "for" condition in "i..j" format.
The contained frame is executed for each value in the range "i" to "j".
The current iteration can be substituted into XPath strings using the function "for(iteratorName)".

    [ 'FOR', 'myInterator', '3..7', [ [ frame ] ] ]

See FlipDog.pm for an example


=item REGEX

Well, this would be self-explanatory if you knew anything about regular expressions, you dope! Oh, sorry . . .

The first parameter on the REGEX command is a regular expression. The rest of the parameters are a list naming which
fields the matched variables of this regex ($1, $2, $3, etc) will be placed.

=item CALLBACK

CALLBACK is like DATA, in that it selects a section of the text based on start and end strings
(which are treated as regular expressions). Then, rather than storing the data away, it will
call a subroutine that you have provided in your sub-module. Your subroutine may decide to store
some data into the hit; it can decide whether to discard the text after processing, or to keep
it for further processing; it can decide whether the data justifies being a hit or not (unless some
parsing step finds this justification, then the parsing will stop. TD, DATA, REGEX, et.al. will do that,
but if you are using CALLBACK, you might not need the other data harvesting operations at all, so your
callback subroutine must "declare" this justification when appropriate).

See the code for C<WWW::Scraper::Sherlock> for an illustration of how this works. Sherlock uses this
method for almost all its parsing. A sample Sherlock scraper frame is also listed below in the EXAMPLES.

=item TRYAGAIN

Sometimes, a scraper frame process may come upon a text that matches its pattern, but is not actually a "hit".
We can tell Scraper to skip this one and try again on the following text using the TRYAGAIN command.
It will repeat the same parsing, a limited number of times, until a given field is discovered.
The syntax for the TRYAGAIN command is

    [ 'TRYUNTIL', <limit>, <fieldName>, [ [ <sub-frame> ] ]

The <sub-frame> is repeated until the field named by <fieldName> returns a non-empty value.
The repetition is limited to <limit> times.

For instance, eBay.com occasionally inserts a <TABLE> element that actually has no data in it, but because it's a <TABLE>,
Scraper will parse it, decide since there's no data there, then this is the end. We fix that misconception with the following:

    [ 'TRYUNTIL', 2, 'url', [ [ 'TABLE', [  [. . . ] ] ]

If the first <TABLE> has 'url' result in it, that that is the "hit", If not, then we look at the next <TABLE>.
If it, too, has no 'url' result, then that is the end of the page.

=item RESIDUE

After each of the parsing commands is executed, the text within the scope of that command is discarded.
In the end, there may be some residue left over. It may be convenient to put this residue in some field so
you can see if you have missed any important data in your parsing.

=item BOGUS

Even after carefully designing a scraper frame, the HIT* section's parsing sometimes results
in extra hits at the beginning or end of the page. A positive value for BOGUS clips that 
many responses from the beginning of the hit list; a negative value for BOGUS pops that 
many resonses off the end of the list.

=item TRACE

TRACE will print the entire text that is currently in context of the Scraper parser, to STDERR.

=item HTML

HTML is simply a command that you will place first in your script. Don't ask why, just do it.

=item WSDL

An interface to WSDL was introduced in Scraper version 2.22. 
At first this may seem a regressive use of WSDL, 
since WSDL (Web Service Definition Language) is designed to do the type of thing with web-services that Scraper is supposed to do with HTML services
(so why use Scraper for web-services?) But hang with me on this. There is are benefits to this in the future.

WSDL helps you execute methods on the remote service. 
This is very handy by inself, but Scraper will reduce this to a simple request/response model (so why use Scraper to reduce your accessiblity?).
The value here is in how Scraper can "normalize" the interface. 
That is, via Scraper's Request/Response model, the same Request can be made to multiple servers,
and the Responses can be tranformed into a "canonical" form, regardless of how the individual service's interface works.
A single Scraper Request is translated to the target WSDL interface,
and Responses are translated to a canonical form; you send the same request to multiple servers (even to WSDL servers),
and you get the same type of response from multiple servers (even from WSDL servers).

Version 2.22 of this interface is very primitive; more of a proof of concept than anything else.
You can use this interface via the following form:

    use WWW::Scraper::WSDL(qw(1.00));
    $serviceName = 'http://www.xmethods.net/sd/StockQuoteService.wsdl';
    $scraper = new WWW::Scraper::WSDL( $serviceName );
    print $scraper->{'_service'}->getQuote('MSFT');

The 'getQuote()' is a method defined by $serviceName (they do all the work!).
This is an incredibly simple way to access web services.
It's even simpler to do if you use SOAP::Lite to do it, of course, but one of the benefits of using Scraper is that
you can discover the names of methods and their results easily
(via Scraper's Request/Response model). That is more difficult to do using SOAP::Lite. 
If you're automating the gathering of data among various web services, this can be valuable.

Again, the v2.22 implementation of this is very primitive, and recommended for enthuiasts only.
See eg/WSDL.pl for an example.

=back 4

=head2 SYNTAX

Scraper accepts its command script as a reference to a Perl array. You don't need to know how to build
a Perl array; just follow these simple steps.

As noted above, every script begins with an HTML command

[ 'HTML' ]

You put the command is square brackets, and the name of the command in single quotes.
HTML will have a single parameter, which is a reference to a Scraper script (in other words, another array).

[ 'HTML', [ ...Scraper script... ] ]

(You can see this is going to get messy with all these square brackets.)

Suppose we want to parse for just the NEXT button.

    [ 'HTML', 
              [
                     [ 'NEXT', '<B>Next' ]
              ]
    ]

The basic syntax is, a set of square brackets, and a command name in single quotes, to designate a command.
Following that command name may be one or two parameters, and following those parameters may be another list
of commands. The list is within a set of square brackets, so often you will see two opening brackets together.
At the end you will see a lot of closing brackets together (get used to counting brackets!).

=head2 EXAMPLES

=over 4

=item CraigsList

CraigsList.com produces a relatively simple result page. Unfortunately, it does not use any of the
standard methods for presenting data in a table, so we are required to use the REGEX method for
locating data. 

Most search engines will not require you to use REGEX. We've used CraigsList here not to illustrate REGEX,
but to illustrate the structure of the Scraper scripting syntax more clearly.
Just ignore the REGEX command in this script; realize that it parses a data string and puts the
results in the fields named there.

    [ 'HTML', 
       [
          [ 'BODY', '</FORM>', '' ,
             [
                [ 'COUNT', 'found (\d+) entries'] ,
                  [ 'HIT*' ,
                    [
                       [ 'REGEX', '(.*?)-.*?<a href=([^>]+)>(.*?)</a>(.*?)<.*?>(.*?)<', 
                                   'date',  'url', 'title', 'location', 'description' ]
                    ]
                ]
             ]
          ]
       ]
    ]

This tells Scraper to skip ahead, just past the first "</FORM>" string (it's only a coincidence that this
string is also an HTML end-tag.) In the remainder of the result page,
Scraper will find the appoximate COUNT in the string "found (\d+) entries" (the '\d+' means to find at least one digit),
then the HITs will be found by applying the regular expression repeatedly to the rest.

=item JustTechJobs

JustTechJobs.com presents one of the prettiest results pages around. It is nice and very deeply structured
(by Lotus-Domino, I think), which makes it very difficult to figure out manually. However, a few simple short-cuts
produce a relatively simple Scraper script.


    [ 'HTML', 
       [   
          [ 'COUNT', '\d+ - \d+ of (\d+) matches' ] ,
          [ 'NEXT', '<b>Next ' ] ,
          [ 'HIT*' ,
             [
                [ 'BODY', '<input type="checkbox" name="check_', '',
                   [  [ 'A', 'url', 'title' ] ,
                      [ 'TD' ],
                      [ 'TABLE', '#0',
                         [
                            [ 'TD' ] ,
                            [ 'TD', 'payrate' ],
                            [ 'TD' ] ,
                            [ 'TD', 'company' ],
                            [ 'TD' ] ,
                            [ 'TD', 'locations' ],
                            [ 'TD' ] ,
                            [ 'TD', 'description' ]
                         ]
                      ]
                   ]
                ]
             ]
          ]
       ]
    ]

Note that the initial BODY command, that was used in CraigsLIst, is optional.
We don't use it here since most of JustTechJobs' result page is data, with very little administrative clutter.

We pick up the COUNT right away, with a simple regular expression. Then the NEXT button is located and stashed.
The rest of the result page is rich with content, so the actual data starts right away.

Because of the extreme complexity of this page (due to its automated generation) the simplest way to locate a data
record is by scanning for a particular string. In this case, the string '<input type . . .check_' identifies a checkbox
that starts each data record on the JustTechJobs page. We put this BODY command inside of a HIT* so that it is 
executed as many times as required to pick up all the data records on the page.

Within the area specified by the BODY command, you will find a table that contains the data.
The first parameter of the TABLE command, '#0', means to skip zero tables and to just read the first one.
The second parameter of the TABLE is a script telling Scraper how to interpret the data in the table.
The primitive data in this table is contained in TD elements, as are labels for each of the data elements.
We throw away those labels by specifying no destination field for the data.

The page, as composed by Lotus-Domino, literally consists of a form, containing several tables, 
one of which contains another table, which in turn contains data elements which are themselves
two tables in which each of the job listings are presented in various forms (I think). 
Given such a complex page, this Scraper script is remarkably simple for interpreting it.

=item DICE

Ok, I know you all wanted to know what DICE.com looks like. Well, here it is:
                            
    [ 'HTML', 
       [  
          [ 'BODY', ' matching your query', '' ,
             [  
                [ 'NEXT', '<img src="/images/rightarrow.gif" border=0>' ]
               ,[ 'COUNT', 'Jobs [-0-9]+ of (\d+) matching your query' ]
               ,[ 'HIT*' ,
                   [  
                      [ 'DL',
                         [
                            [ 'DT', 'title', \&addURL ] 
                           ,[ 'DD', 'location', \&touchupLocation ]
                           ,[ 'RESIDUE', 'residue' ]
                         ]
                      ]
                   ]
                ]
             ] 
          ]  
       ]
    ]

We'll leave this as an exercise for the reader (note that this is the "brief" form of the response page.)

=item Sherlock

Now that you're fairly well-versed in Scraper frame operations syntax, we'll use a fairly complex frame,
automatically generated by C<WWW::Scraper::Sherlock>, to illustrate how Sherlock uses the Scraper framework.

If you point Sherlock to the Yahoo plugin, it will generate the following Scraper frame to parse the result page.

        [
          'HTML',
          [
            [
              'CALLBACK', \&resultList,
              'Inside Yahoo! Matches',
              'Yahoo! Category Matches',
              [
                [
                  'HIT*',
                  [
                    [
                      'CALLBACK', \&resultItem,
                      '<b>',
                      '<br>',
                      [
                        [
                          'CALLBACK',
                          \&resultData,
                          '<b>',
                          ':</b>',
                          'result_name'
                        ]
                      ],
                      undef
                    ]
                  ],
                  'result'
                ]
              ]
            ],
            [
              'CALLBACK',
              \&resultList,
              'Yahoo! Category Matches',
              'Yahoo! News Headline Matches',
              [
                [
                  'HIT*',
                  [
                    [
                      'CALLBACK', \&resultItem,
                      '<dt><font face=arial size=-1>',
                      '</a></li><p></dd>',
                      [
                        [
                          'CALLBACK', \&resultData,
                          '<li>',
                          '</a></li><p></dd>',
                          'result_name'
                        ]
                      ],
                      undef
                    ]
                  ],
                  'category'
                ]
              ]
            ]
          ]
        ]

You'll notice that there are three callback functions in here (six invocations). 
These are named after the parts-of-speech specified in the Sherlock technotes.
These callback functions will process the data a little differently than the standard Scraper
functions would. 

In Sherlock, for instance, the start and end strings are considered part
of the data, so throwing them away causes unfortunate results. Our callbacks handle the data
more in the way that Sherlock's creators intended. 

'resultList' corresponds to Scraper's BODY, 'resultItem' corresponds to Scraper's TABLE, and 'resultData'
corresponds to Scraper's DATA. The next two parameters of each CALLBACK operation indicate the start and
end strings for that callback function. (A fourth parameter allows you to pass more specific information
from the Scraper frame to the callback function, as desired.) 
Of course, these callback functions then handle the data in the "Sherlock way", rather than the "Scraper way".

Note that the start string for the second resultList is the same as the end string of the first resultList.
This is but one illustration of how Sherlock handles things differently than Scraper. But by using the
CALLBACK operation, just about any type of special treatment can be created for Scraper.

We refer you to the code for C<WWW::Scraper::Sherlock> for further education on how to compose your own CALLBACK functions.

=back

=head1 EXTENDING SCRAPER WITH NEW OPERATIONS

You can extend Scraper by building new search engine interfaces,
but there is a deeper meaning of extensibility that you can also apply.
You can invent and use your own scraping operations in the Scraper frames themselves.

By building a subclass of C<WWW::Scraper::Opcodecode>, you can use your invented operation by inserting your opcode into the scraper frame.
Your code will be called to scrape the (local) HTML code, and put whatever results it garners into the Response object.
You can even parameterize your opcode so you can modulate its behavior depending on where in the frame it appears.

=head2 Example

The first operation we implemented using Extensible Scraper Operations was 'GRUB'.
GRUB is also one of the simpler operations, so it makes a good example.
(Recall, from the description above, that GRUB scrapes all detail pages linked to the root detail page by 'next' links.)

You will find this example code in F<WWW::Scraper::Opcodecode::GRUB.pm>. 
See F<WWW::Scraper::Grub.pm> for how this is used, and F<eg/GrabGrub.pl> for a fully functional program using GRUB.

The new() method instantiates the object and returns an array naming the fields that this operation captures.
In the case of GRUB, it captures no newly named fields (it just appends new results to existing fields).

Then the scrape() method is handed the (local) HTML code that it should examine.
F<GRUB.pm> simply looks to a field that has already been captured in an earlier step,
converts that to an absolute URL, then scrapes that page using ScrapeDetailPage().
Recursion into ScrapeDetailPage() simply appends new field values to the existing ones
(this is the normal behavior of ScrapeDetailPage().)
F<GRUB.pm> also contains some code to control recursion, and to use multiple fields as the 'next' links.

=head2 Methods

=over 6

=item Opcode::new ($scaffold, $params)

The new() method should instantiate the object, and place a reference to an array of field names that this operation
will capture into $self->{'fieldsDiscovered'}.
If no fields are captured, then the hash-element should remain undefined.

It should return itself.

Example: (from Opcode::FORM.pm)

    sub new {
        my ($cls, $scaffold, $params) = @_;
        return bless { 'fieldsDiscovered' => ['name','action','method'] };
    }


The base class (default) of new() will assume that all non-references in the scaffold are names of captured fields
(see F<WWW::Scraper::Opcodecode>).

=over 6

=item $scaffold

Points to the array is the scaffold element that invokes this extended operation.
(The term "scaffold" refers to a particular location in the Scraper frame.)

=item $params

A reference to an array of strings that are the parameters of the operation,
as specified within parenthesis immediately following the opcode in the scaffold.
(A simple C<split> on commas is used to seperate these parameters into separate array elements.)

This should not be confused with the subsequent scaffold parameters that appear after the opcode and its parameters.

=back

=item Opcode::scrape ($scraper, $scaffold, $TidyXML, $hit)

The scrape() method is where the actual scraping takes place.

This method should return undef if all it does is capture field values.
It should return an array if it has deliniated a region to be processed by the sub-scaffold.
That array should contain ($nextScaffold, $newString). 
$newString should be undef if there was no change from the old string (harmless but wasteful if you return the old string).
$newString should be an empty string if there is nothing left in the content to process.

=over 6

=item $scraper

The Scraper interface object for this operation.

=item $scaffold

The scaffold is passed in here, again.

=item $TidyXML

A TidyXML object representing the current state of the scrape.
(All scraping modes, not just TidyXML, are represented by a TidyXML object).
$TidyXML->asString() will return the current (local) HTML code.
You can replace that (after, for instance, capturing some data from the code that you don't want to see in the next iteration)
by using $TidyXML->asString($newString) as a set method.

=item $hit

The current Response object. This is created when Scraper encounters the 'HIT' or 'HIT*' opcodes.
Append newly scraped field values using the method $hit->fieldName($newFieldValue) .

Example: (from Opcode::FORM.pm)

    sub scrape {
        my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
        
        my ($sub_string, $attributes) = $TidyXML->getMarkedTextAndAttributes('FORM');
        return undef unless $attributes;
    
        return ($$scaffold[1], $sub_string, $attributes);
    }


=back

=back

=head1 Dependencies

In addition to F<WWW::Search>, Scraper depends on these non-core modules in order to support the
translation of requests from canonical forms to native forms.

=over 8

=item F<Tie::Persistent>

=item F<Storable>

=back

The Scraper modules that do table driven field translations (from canonical requests to native requests) will have
files included in their package representing the translation table in Storable format. The names of these files are
<ScraperModuleName>.<requestType>.<canonicalFieldName>. E.G., Brainpower.pm owns a translation table for the 'location'
field of the canonical Request::Job module; it is named C<Brainpower.Job.location> . 

See F<WWW::Scraper::Request.pm> for more information on Translations.

=head1 Tools for Building a New Scraper Engine

=item artifactFolder($folderName)

Set a pathname (absolute or relative) via artifactFolder()
and artifacts of the Scraper process will be written into that folder.
You will see each HTML page Scraper downloads, and the XML version of each page if you are using TidyXML.

=item Tracing

Scraper has a built in tracing function, "setScraperTrace()", to help in the development and use of new Scraper engines.
It is activated by the following Scraper method:

    $scraper->setScraperTrace('code');

=over 8

=item setScraperTrace('U')

Lists every URL that Scraper uses to access search engines.

=item setScraperTrace('d')

Lists, in minute detail, every parsing operation Scraper uses to interpret the responses from search engings.

=back

=head1 ACKNOWLEDGEMENTS

=over 8

=item To J.C.Wren <jcwren@jcwren.com>, for his help in improving eBay.pm

and a firm boot in the pants. His was also the inspiration to facilitate array-type field results in Scraper's Response.

=item To Klemens Schmid (klemens.schmid@gmx.de), for FormSniffer.

This tool is an excellent compliment to Scraper to almost instantly discover form and CGI parameters for configuring new Scraper modules.
It instantly revealed what I was doing wrong in the new ZIPplus4 format one day (after hours of my own clumsy attempts).
See FormSniffer at http://www.klemid.de/formsniffer2.aspx (Win32 only).

=item To Dave Raggett <dsr@w3.org> and the many people

involved in the SourceForge projects to maintain Tidy on a wide range of
platforms and languages. Without this tool, I'd have wasted
untold millenia trying to keep up with many search engines.
This tool along with XPath and XmlSpy, makes configuring
scraper modules to new results pages extremely easy.
See http://tidy.sourceforge.net/ for links to the projects.
The original Tidy page is at: http://www.w3.org/People/Raggett/tidy

=item To Martin Thurn

for the foundation and inspiration of WWW::Search, and his timely patches!

=item and, of course, Larry Wall

for his conception and husbanding of the Perl language to an Industry standard.
Perl is a powerful tool for large number of applications (many of which are not widely recognized),
and has afforded your humble CPAN author a comfortable, if not sumptuous, lifestyle over the past several years.

=back

=head1 AUTHOR

Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (C) 2001-2002 Glenn Wood. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

