

=Base concepts and idea

This model has the following characteristics.

\LOCALTOC{type=linked}

==Formatter based

There is a (small) number of structural \PP entities like headlines, tables and tags.
A formatter of a certain entity determines how this entity is transformed into the target
language. It receives the complete contents, plus entity configuration settings if available.

 A tag formatter gets the tag name, tag
 options and tag body. It supplies a
 formatted tag.

 A headline formatter gets the headline
 text (possibly including smaller entities
 like tagged text parts which were formatted
 before), plus meta informations like headline
 level etc. It supplies a formatted headline.

 A page formatter gets all the preformatted
 contents of the page, plus page meta informations.
 It supplies (or emits) a formatted page.


==Modular

The concept is based on a module hierarchy called \BCX<\PP::Generator>.

\CX<\PP::Generator> is part of the framework and does all processing that is necessary
for \I<all> converters (or generators). 

\C<\PP::Generator::\B<<language\>>> modules do the work specific for a certain target
language. They are derived from \C<\PP::Generator>. By choosing another language module,
another target format is produced. The choice is made using the \CX<-target>
\REF{type=linked name="Option driven"}<option>.

  The \PP::Package distribution comes with
  \PP::Generator::\I<XML> for XML
  handling, and \PP::Generator::\I<SDF>
  for SDF handling.

  To produce XML, \I<-target XML> is used.
  Likewise, \I<-target SDF> produces SDF.

Additionally, \C<\PP::Generator::<language\>::\B<<formatter\>>> classes define special,
language specific formatting. They are derived from \C<\PP::Generator::<language\>>. By
choosing another formatter module a user determines the way the target format shall be
produced. \I<This> choice is made via the \CX<-formatter>
\REF{type=linked name="Option driven"}<option>.

By convention at least a \CX<\PP::Generator::<language\>::Default>> module needs to be
available. It is used as a fallback in case the user does not choose a formatter explicitly.

  The distribution comes with several
  default formatters:
  \PP::Generator::XML::Default and
  \PP::Generator::SDF::Default.

  \I<-target XML -format Default> produces
  default formatted XML.
  
Every user can derive further levels. See \REF{type=linked name="Style featured"}<below>.


==Option driven

All configurations are done by options, which (using option files) makes generator calls
very comfortable.

Options are defined by the several (module) levels: the startup script (\CX<perlpoint>) declares
a few bootstrap options only. Then \CX<\PP::Generator> declares options common to all
generators. Then \C<\PP::Generator::<language\>> declares options available for all
converters to \C<<language\>>, and \C<\PP::Generator::<language\>::<formatter\>> the
options that are specific to that formatter.

Option files are the base of \I<\REF{type=linked name="Style featured"}<styles>> as well.


==Style featured

Styles were introduced into \PP with \CX<pp2html>, Lorenz Domkes \PP converter to HTML.
With the new formatter (or generator) model, \I<all> converters can use styles, and styles
of an extended definition.

A style (according to this new definition) is a \I<directory structure> (or possibly \CX<PAR>
file in the future) that defines several things:

* \B<An option collection.> A configuration file combines all the options that set
  up a certain layout.

* \B<Formatters.> A style can define and use \I<its own formatter modules>. If it
  contains a \CX<lib> subdirectory with a module
  \C<\PP::Generator::<special_language\>::<special_formatter\>>, and the options
  set up in the style contain \C<-target special_language -formatter special_formatter>,
  the \C<lib> directory is added to the module search path dynamically and the
  modules of the style are loaded. This happens transparently. For users, this results
  in simple style choices, without need of special one shot installations.

* \B<Template engines.> Similar to formatters, a style can extend the installed PerlPoint
  libraries by own \<template engines>. This works the same way: if the style contains a
  \C<lib> directory with an own engine module \C<\PP::Template::<special_engine\>> and
  the style options contain \C<-templatetype special_engine>, than \C<perlpoint> will
  use that engine to process your template files.

* \B<Templates.> A formatter can be template driven. The style contains all necessary
  template files. The template system is not fix - \PP allows to use \I<any> system
  by providing a generalized API. To add a new template system, only a small layer module
  needs to be written. For available template interfaces, see \PP::Template modules on CPAN.

* \B<Description and documentation.> Style directories can be set up to hold short
  descriptions, screenshots and manuals for a certain style. These can be used by
  external tools, like librarians or Web pages, to present a style.


==One converter

Because the \C<Generator> module does most of the work, the startup needs are really small
and independent on the target format. So the few startup code lines are collected in a single
script called \BCX<perlpoint> ("tdo"="template driven output", based on an initial goal of the
new design (to write a common platform for the integration of arbitrary templating systems)).


=Getting started

To write a formatter, you first should know what the base modules of the generator already do,
which methods of \CX<Generator> objects can be overwritten and which interface they provide.

For this, the following sections describe what's done on the several generator levels.

\LOCALTOC{type=linked depth=1}


==The startup script

\LOCALTOC{type=linked}


===Options declared on this level

The startup script declares very basic options, which will be available in general.

@|
option          | arguments                | example              | description
\BCX<target>    | the target format        | \C<-target XML>      | mandatory
\BCX<formatter> | the formatter to be used | \C<-formatter Easy>  | defaults to "Default"
\BCX<styledir>  | a directory to be searched for styles | \C<-styledir ~/perlpoint/styles> | Can be used multiply. Defaults to the startup directory. For reasons of compatibility with older converters, \CX<style_dir> is allowed as well.
\BCX<style>     | a style name             | \C<-style modern>    | The name of a \REF{type=linked name="Style featured"}<style>.


===Function

Basically this script takes options, builds a \X<\PP::Generator> object and starts it
(by calling its \C<run()> method). This is just a bootstrap.



==The generator level

This is where most of the work is done. Behind the scenes ;-)

This is \CX<\PP::Generator>.

\LOCALTOC{type=linked}


===Options declared on this level

The \CX<Generator> module is the base of all generators, so these options are generally
available.

@|
option               | arguments             | example              | description
\BCX<activeContents> |                       | \C<-activeContents>  | enables active contents
\BCX<cache>          |                       | \C<-cache>           | activates the cache
\BCX<cacheCleanup>   |                       | \C<-cacheCleanup>    | performs a cache cleanup
\BCX<docstreaming>   | method code           | \C<-docstreaming 1>  | configures the document stream handling
\BCX<help>           |                       | \C<-help>            | displays online help ("usage")
\BCX<includelib>     | directory             | \C<-includelib inc>  | Adds a directory to the path searched for files to be included via \CX<\\INCLUDE>. Can be used multiply.
\BCX<nocopyright>    |                       | \C<-nocopyright>     | suppress copyright message
\BCX<noinfo>         |                       | \C<-noinfo>          | suppress runtime informations
\BCX<nowarn>         |                       | \C<-nowarn>          | suppress runtime warnings
\BCX<quiet>          |                       | \C<-quiet>           | suppress all runtime messages except of errors
\BCX<safeOpcode>     | an opcode or "ALL"    | \C<-safeOpcode ALL>  | specifies permitted opcodes in active contents (see the Opcode manpage for details), can be used multiply
\BCX<set>            | a user setting        | \C<-set test>        | allows user settings which can be evaluated in documents
\BCX<skipstream>     | the stream name       | \C<-skipstream left> | skip a certain document stream
\BCX<tagset>         | the set               | \C<-tagset HTML>     | adds a tag set to the scripts own tag declarations (making those tags available)
\BCX<title>          | presentation title    | \C<-title Examples>  | sets up the presentation title
\BCX<trace>          | numerical trace level | \C<-trace 2>         | activates trace messages


===Object data defined on this level

The following public object attributes are defined by this class:

@|
attribute       | description
\BCX<anchorfab> | generates anchor names, use: \C<$me-\>{anchorfab}-\>generic>
\BCX<backend>   | the backend object (see \CX<\PP::Backend>)
\BCX<options>   | a hash of options passed to the generator script
\BCX<parser>    | the parser object (see \CX<\PP::Parser>)

Please note that due to the concepts of this module hierarchy and the mechanisms of Perls
\CX<base> pragma, there are more attributes visible in subclasses, but those are not intended
for public use.


===Function

The base module of the generator hierarchy controls the translation process. It performs
initializations, parses the \PP source and prepares the results for formatters, which it
invokes at the right time.

Knowledge of the internals of this class is no precondition to write subclasses, so the
details are not furtherly explained here. To sum them up, a generator module performs
initializations, parses the \PP sources, runs a backend object to deal with the results
and invokes formatters as soon as their target entities are completely available.


===Inheritable methods

These methods are intended to be inherited and overwritten.

\LOCALTOC{type=linked}


====bootstrap()

\B<Invocation:> called after the constructor (of a subclass).

\B<Function in the \C<Generator> class>: collects options and source filters.

\B<Intention for subclasses:> perform own bootstrap operations.

\B<Parameters:> the object.

\B<Return values:> none expected.

\B<Hints:> it is strongly recommended to invoke the parent method,
as by \C<$me-\>SUPER::bootstrap>.


====options()

\B<Invocation:> called after the constructor of a subclass, by the \C<bootstrap()> method.

\B<Function in the \C<Generator> class>: defines \C<Generator> options.

\B<Intention for subclasses:> add own options.

\B<Parameters:> the object.

\B<Return values:> an option list.

\B<Hints:> it is strongly recommended to invoke the parent method, as by

  # provide the base options plus your own
  (
   $me->SUPER::options, # base options

   "newopt1=s",         # new options
   "newopt2=s",
  );



====checkUsage()

\B<Invocation:> called after the constructor of a subclass and \C<options()>,
by the \C<bootstrap()> method.

\B<Function in the \C<Generator> class>: none that far.

\B<Intention for subclasses:> check usage, e.g. options.

\B<Parameters:> the object. Note that the option list is available in attribute \C<options>.

\B<Return values:> none expected. The method should terminate the program if necessary.

\B<Hints:> it is strongly recommended to invoke the parent method, as by

  # don't forget the base class
  $me->SUPER::checkUsage;



====sourceFilters()

\B<Invocation:> called after the constructor of a subclass and \C<checkUsage()>,
by the \C<bootstrap()> method.

\B<Function in the \C<Generator> class>: enables \C<perl> sources (should be valid
for most generators).

\B<Intention for subclasses:> add own source filters.

\B<Parameters:> the object.

\B<Return values:> a filter list.

\B<Hints:> in most cases it will be useful to invoke the parent method, except when
\C<perl> filters are not required, as by

  (
   $me->SUPER::sourceFilters,  # parent class list
   "xml",                      # embedded XML;
  );


====initParser()

\B<Invocation:> called between parser construction and parser startup.

\B<Function in the \C<Generator> class>: none that far.

\B<Intention for subclasses:> perform whatever seems appropriate in this state.

\B<Parameters:> the object. Remember that the parser object is available in attribute
\CX<parser>.

\B<Return values:> none expected.

\B<Hints:> it is strongly recommended to invoke the parent method, as by

  # don't forget the base class
  $me->SUPER::initParser;


====initBackend()

\B<Invocation:> called between backend construction and backend startup (so the sources
were already parsed).

\B<Function in the \C<Generator> class>: binds intermediate data to the \CX<backend> attribute,
to allow derived methods to let the backend work on it.

\B<Intention for subclasses:> perform whatever seems appropriate in this state.

\B<Parameters:> the object. Remember that the backend object is available in attribute
\CX<backend>.

\B<Return values:> none expected.

\B<Hints:> it is \I<strongly> recommended to invoke the parent method, otherwise derived
methods accessing the backend object will probably not work.

  # don't forget the base class
  $me->SUPER::initBackend;


====finish()

\B<Invocation:> called when everything is done.

\B<Function in the \C<Generator> class>: none that far.

\B<Intention for subclasses:> perform whatever seems appropriate to complete your work.

\B<Parameters:> the object.

\B<Return values:> none expected.

\B<Hints:> it is \I<strongly> recommended to invoke the parent method, as by

  # don't forget the base class
  $me->SUPER::finish;


==The language level

If you plan to subclass an existing language module, please see its documentation.
General informations, especially those about
\REF{type=linked name="Formatters to be defined"}<formatters>, are of interest for authors
of both language modules and their subclasses.

\LOCALTOC{type=linked depth=1}

===Options declared on this level

Target format specific options.

===Object data defined on this level

It is up to the language class designer to add desired attributes. Please make sure the names
are not already used in base classes.

===Function

This class level is intended to do everything specific for the target language. This might
include base formatting, but does not need to.


===Optional methods


\LOCALTOC{type=linked}


====preFormatter()

This is an optional method called before formatting. It is \I<no> formatter by itself,
but useful to recognize global state switches and the like (e.g. if in an embedded part
and of what language). When defined, it is called for \I<all> entities,
using \I<the traditional directive interface>. See the traditional model for details.
Here is a list of parameters to expect:

\INCLUDE{type=pp file="writing-converters-entityinterfaces.pp"}



===Formatters to be defined

The generator model expects that formatters are defined for \PP entities. This should be
done on this level or below.

\LOCALTOC{type=linked}


====Interface

All formatters receive \I<the object>, \I<page data> and \I<an item structure>.

The \I<object> and its attributes were described above.

The \I<page data> ...

The \I<item structure> is a hash with the following slots:

@|
key           | value
\BCX<context> | A reference to an array of embedding entities, entities are represented by their \C<DIRECTIVE_...> codes (see \CX<\PP::Constants>). This allows a converter to determine the entities location in a hierarchy of entities, e.g. that a list is a nested list on 45th level.
\BCX<parts>   | A reference to an array of elements, usually the embedded parts (or the "body" part), e.g. the headline text for a headline entity, or the tag body for a tag entity.
\BCX<cfg>     | A reference to a configuration hash, see below.

The entries of the configuration hash:

@|
key           | value
\BCX<type>    | the original directive type of the entity - usually unused by a formatter
\BCX<mode>    | the original state of an entity - should not be used by a formatter
\BCX<data>    | this is the interesting part, as it holds various attributes which are formatter specific


A formatter \I<can> supply a result. This is appropriate in most cases, as the results are
made part of an embedding entity and provided to thats formatter when the entity is complete.
Higher level formatters receive results of lower level formatters in the \C<parts> slot of
their \I<item> parameter, see above.

  Imagine two nested tags. The body of the
  innermost tag is simple text, formatted
  by the simple text formatter. The formatter
  of the innermost tag receives the result
  of the simple text formatter in $item->{parts}.
  The formatter of the outer tag receives the
  result of the inner tag formatter in \I<its>
  $item->{parts} parameter slot.

A result can be of any type, except for pure (unblessed) hash references which are reserved
for internal purposes. As the results are only passed through to outer formatters, the
formatter class can organize its own data flow.

  The SDF formatter classes in the distribution
  in most cases use \I<simple strings> to transfer
  formatted results.

  They use \I<array references> to deal with document
  streams.

  The XML formatter classes in the distribution
  use XML::Generator \I<objects> as the intermediate
  data format between formatters.

In case you subclass an existing formatter class, take care which formats are used there.


====formatHeadline()

\B<Invoked for:> headlines

\B<Data (\C<%{$item-\>{cfg}{data}}>):>

@|
key         | value
\BCX<level> | chapter level
\BCX<full>  | the headline text, without embedded tags
\BCX<abbr>  | a shortcut version of the headline text


====formatUlist()

\B<Invoked for:> unordered lists

\B<Data (\C<%{$item-\>{cfg}{data}}>):>

@|
key           | value
\BCX<level>   | the list nesting level


====formatUpoint()

\B<Invoked for:> points of unordered lists

\B<Data (\C<%{$item-\>{cfg}{data}}>):>

@|
key             | value
\BCX<hierarchy> | the hierarchy of listlevels by array reference


====formatOlist()

\B<Invoked for:> ordered lists

\B<Data (\C<%{$item-\>{cfg}{data}}>):>

@|
key           | value
\BCX<level>   | the list nesting level


====formatOpoint()

\B<Invoked for:> points of ordered lists

\B<Data (\C<%{$item-\>{cfg}{data}}>):>

@|
key             | value
\BCX<hierarchy> | the hierarchy of listlevels by array reference, this allows to build an individual number for this point if necessary


====formatDlist()

\B<Invoked for:> definition lists

\B<Data (\C<%{$item-\>{cfg}{data}}>):>

@|
key         | value
\BCX<level> | the list nesting level


====formatDpoint()

\B<Invoked for:> definition list points

\B<Data (\C<%{$item-\>{cfg}{data}}>):>

@|
key             | value
\BCX<hierarchy> | the hierarchy of listlevels by array reference


====formatDpointItem()

\B<Invoked for:> definition list point items

\B<Data (\C<%{$item-\>{cfg}{data}}>):> none


====formatDpointText()

\B<Invoked for:> definition list point texts

\B<Data (\C<%{$item-\>{cfg}{data}}>):> none


====formatText()

\B<Invoked for:> text paragraphs

\B<Data (\C<%{$item-\>{cfg}{data}}>):> none


====formatBlock()

\B<Invoked for:> example blocks

\B<Data (\C<%{$item-\>{cfg}{data}}>):> none


====formatVerbatim()

\B<Invoked for:> verbatim blocks

\B<Data (\C<%{$item-\>{cfg}{data}}>):> none


====formatDStreamEntrypoint()

\B<Invoked for:> document stream parts (\I<not> only their entry)

\B<Data (\C<%{$item-\>{cfg}{data}}>):>

@|
key        | value
\BCX<name> | the name of the docstream


====formatDStreamFrame()

\B<Invoked for:> document stream frames (containing a sequence of docstreams different from "main")

\B<Data (\C<%{$item-\>{cfg}{data}}>):> none


====formatTag()

\B<Invoked for:> tags

\B<Data (\C<%{$item-\>{cfg}{data}}>):>

@|
key             | value
\BCX<name>      | tag name
\BCX<options>   | a hash of tag options and their values
\BCX<bodyparts> | the number of parts in the body (0 means: no tag body) - you should only check for 0 or not 0


====formatSimple()

\B<Invoked for:> simple strings.

\B<Data (\C<%{$item-\>{cfg}{data}}>):> none



====formatComment()

\B<Invoked for:> comments

\B<Data (\C<%{$item-\>{cfg}{data}}>):> none


====formatPage()

\B<Invoked for:> a complete page / slide

\B<Data (\C<%{$item-\>{cfg}{data}}>):> none


==The formatter level

\LOCALTOC{type=linked}

===Options declared on this level

Formatter specific options.

===Object data defined on this level

It is up to the formatter class designer to add desired attributes. Please make sure the
names are not already used in base classes.

===Function

On this class level, everything is about formatting. This includes result file handling,
implementation of template systems and so on.

Most probably the page formatter will be implemented on this level, but almost any formatter
can. Inherited formatters can be overwritten or extended. This is all up to you.



