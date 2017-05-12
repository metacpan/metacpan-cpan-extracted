
+PP:PerlPoint

+IB:\I<\B<__body__>>

+IC:\I<\C<__body__>>

+BC:\B<\C<__body__>>

? lc($PerlPoint->{targetLanguage}) eq 'html'

+RED:\F{color=red}<__body__>

+GREEN:\F{color=green}<__body__>

+BLUE:\F{color=blue}<__body__>

+MAGENTA:\F{color=magenta}<__body__>


? lc($PerlPoint->{targetLanguage}) ne 'html'

+RED:\B<__body__>

+GREEN:__body__

+BLUE:__body__

+MAGENTA:__body__

? 1


=Introduction

OK, there's this special cool multiplatform presenter software you want to use, but currently \PP cannot be translated into its format. This situation can be changed - just write a \PP converter. A \PP converter takes a \PP source and translates it into another format.

The target format can be almost everything. There's no restriction to formats used by \I<presentation software>. Documents can be presented in many ways: on a wall, on screen or printed, in the Web or intranet - and there are many formats out there meeting many special needs. Think of the \PP converters already there: they address \I<HTML> (for browser presentations, online documentations, training materials, ...), \I<Clinton Pierce's Perl Projector> (for traditional presentations), \I<LaTex> (for high quality prints) and \I<SDF> (as an intermediate format to generate PDF, PostScript, POD, text and more easily). \IB<Once you know the target format, you can write a \PP converter to it.>

Usually, there's one converter for every target format. This is no strict rule - you may want to implement features which are not provided by an already existing \C<pp2anything> converter, so feel free to implement your own version. Nevertheless, to avoid confusion, it may be worth a try to cooperate with the original author before you start. Maybe you can join his team.

In this document, it is assumed that you are familiar with the \PP language and its element, which is explained in ...


=The architecture of a converter

All \PP converters are basically built the same way.

\LOCALTOC{type=linked}


==The base design

To relieve converter authors, the CPAN distribution \C<\PP::Package> provides a framework to write converters. The simple idea is that because all converters have to process \PP sources (and should do this the same way), there's no need to implement this parsing again and again. So the framework provides a \I<parser> which reads the sources and generates data which contain the source contents. Please have a look at the following image.

\IMAGE{src="../images/pp-src-stream-e.png"}

The parser reads \PP sources and checks them for integrity. Valid sources are translated into intermediate data which is called a "stream", so all converters will be fed with correct input. The parser is provided by the framework class \B<\PP::Parser>. It implements the \PP base language definition to recognize paragraphs, macros, variables, tags, and so on.

Once we have the intermediate data, there's another job all converters need to perform the same way: these data need to be processed as well. It's seems to be a good idea to encapsulate this processing by another general interface. This relieves converter authors even more, freeing them from the need of dealing with the details of the stream implementation. (Which may occasionally change.) So there's another framework class called \B<\PP::Backend>. Its objects can walk through the stream, calling user defined functions to provide its elements. And these callbacks are the place where the target format is produced.

\IMAGE{src="../images/pp-stream-result-e.png"}

With this framework, a converter author can focus just on target format generation. That's the part naturally most interesting to him.

==The language implementation

Let's go back to the parser. It was said that it implements the "\PP base language definition to recognize paragraphs, macros, variables, tags, and so on". Does this mean that the complete language is implemented there? No, that's not the case. Instead of this, there is an important part left to the converter author to make the design as flexible as possible. This point is the definition of tags.

Tags are very converter specific. They usually reflect a feature of the target format or a special feature the converter author wants to provide.

  Hyperlinks, for example, are essential if converting
  to HTML. They can be used in PDF as well. But if you
  are writing a converter to \I<pure text>, they might
  be useless.

  Or: one author wants to provide footnotes, while another
  one does not.

To implement all wished tags in the parser would make the converter framework very inflexible and hard to maintain. Such an approach could end up with a huge, difficult to maintain or even unusable tag library. All tag implementation details of all converters would need to be well coordinated. So that's no real alternative.

Instead of this, \PP (or its \I<base> definition) only defines the \I<syntax> of a tag (and reserves a small set of tags implementing base features like tables or image integration). \I<The definition of real tags, however, is a task of the several converters.> So you are free to define all the tags you want, and you can modify this set without changes to the framework. A definition currently includes the tag name, option and body declarations, and controls how the parser handles tag occurences. It's even possible to hook into the parsers tag processing in various ways.

Tags are defined by \I<Perl modules>, for a simple reason: I looked for a way to make their usage as easy as possible. And what could be easier than to write something like

  use \PP::Tags::\RED<MyFormat>;

\? Hardly nothing.

But there are even more advantages. Defining tags by modules provides a simple way to \I<combine> definitions, to publish them in a central tag repository (CPAN) and to use them in various converters. \PP even offers a way to say the parser "We do not implement the tags of target language SuperDooper, but please treat them as tags anywhere (we will ignore them in the backend running subsequently)." - which makes it easy to process one and the same source by numerous converters defining completely different tag sets.

==The whole picture

So there are two main tasks to perform when writing a converter: define the tags you want to use and write backend callbacks which generate one or more documents in the target format. These pieces are then put together by an application that loads tag definitions, runs the parser and calls the backend (which invokes your callbacks).


The following chapters will describe this work in detail.


=Tag definition

It's up to you to define your tag meanings. Tags are usually used to mark up text. This may be a logical markup (index entry, code sequence, ...) or a formatting one (bold, italics, ...), for example.

  \RED<\\B<something\>> marks "something" to
  be formatted bold.

  The pp2html tag \RED<\\X> declares index entries
  like \RED<\\X<here>>.

Note that the common (and recommended) way of markup is to expect the marked text part in the tags body. However, it is also possible to declare begin and end tags which enclose the marked parts, like the builtin \C<\\TABLE> and \C<\\END_TABLE> do. This allows to enclose even empty lines (and therefore several paragraphs).

  \\TABLE

  Column   | Column
  contents | contents

  \\END_TABLE

Note that a tag does note necessarily need to have a body part. \C<\\END_TABLE>, for example, has not.

Depending on the tag meaning (or "semantics"), a tag may need options. These are parameters passed to the tag, specifying how it shall be evaluated. Tag options can be optional or mandatory.

  The \\IMAGE tag uses options to specify
  what file should be loaded, as in

  \\IMAGE{src="image.png"}

As a general rule, tag options control tag processing, while the tag body contains parts of the document. Keep in mind that your tags might be processed by \I<other> converters as well which do not handle them. In such a case, only the tag body will remain a visible part of the source.

The same is true vice versa:

  Theoretically, the image tag could use the
  tags \I<body> as well to declare the image file:

  \\IMAGE\RED<<image.png\>>

  But if a converter ignores \\IMAGE, this
  would result in the \I<text> "image.png" which
  will usually make no sense to a reader.

So, when you design your tags, make sure that nothing of them remains visible in the result in case they will be ignored.


==Finding tag names

New tag names can be freely chosen, with two exceptions: first, certain tag names are already used (and therefore reserved) by the base system:

@|
tag                                                      | description
\BC<\\B>, \BC<\\C>, \BC<\\HIDE>, \BC<\\I>, \BC<\\IMAGE>, \BC<\\READY>, \BC<\\REF>, \BC<\\SEQ> | Base tags defined by \BC<\PP::Tags::Basic>. By convention, \I<all> converters support these tags. (The list might be incomplete, please look at the latest version of the module.)
\BC<\\TABLE>, \BC<\\END_TABLE>                           | construct tables
\BC<\\EMBED>, \BC<\\END_EMBED>                           | embed other languages into a \PP source, e.g. to directly include parts in the target format, or to call Perl code which produces \PP on the fly
\BC<\\INCLUDE>                                           | loads additional files which are made part of the source (in various ways)

Second, please have a look at existing converters and \I<their> tags. It might confuse users if one and the same tag name has completely different meanings in different converters. So if your prefered name is already used, please invent another one. On the other hand, it may be the intention to support "foreign" tags as well, in a way that fits into your target format. In this case, the "foreign" names (and their syntax) \I<have> to be used, of course.

All tag names are made of uppercased letters. Underscores and digits are allowed as well. The parser does not recognize a tag if its name does not match these rules.


==Tag option conventions

You are free to invent whatever option names you prefer. Well, almost. There are a few
simple conventions:

* Options \I<presented to a user> (the documented ones ;-)
  should not begin or end with an underscore.

* \I<Special option tags> evaluated by the parser begin
  and end with \I<one> underscore. They are made known
  to the user, and this convention distinguishs them
  from the tags own options. \C<\\REF>'s option
  \C<_cnd_> is an example.

* Informations intended to be used \I<internally only>
  (to pass informations between various tag hooks
  or to the backend) begin and end with \I<two>
  underscores.

That's all to take care of here.


==Writing a tag module

Now when your \GREEN<tags> are designed, you need to define them \I<by a module> in the \BC<PerlPoint::Tags> namespace and make it a subclass of \BC<PerlPoint::Tags>:

  \GREEN<# declare a tag declaration package>
  package PerlPoint::Tags::New;

  \GREEN<# declare base "class">
  use base qw(PerlPoint::Tags);

The base module \BC<\PP::Tags> contains a special \C<import()> method which arranges that the parser learns new tag definitions when a tag module is loaded by \C<use>. \BC<\PP::Tags> is provided as part of the converter framework \BC<\PP::Package>.

It is recommended to have a "top level" tag declaration module for each \PP converter, so there could be a \C<PerlPoint::Tags::\I<HTML>>, a \C<PerlPoint::Tags::\I<Latex>>, \C<PerlPoint::Tags::\I<SDF>>, a \C<PerlPoint::Tags::\I<XML>> and so on. (These modules of course may simply \XREF{name="Integrating foreign tags"}<invoke lower level declarations> if appropriate.)

To complete the intro, configure variable handling:

  \GREEN<# pragmata>
  use strict;
  use vars qw(%tags %sets);

\C<%tags> and \C<%sets> are important variables used by convention. They will be explained in the next sections.


===Tag definition

Now the tags can be declared really.

Tag declarations are expected in a global hash named \BC<%tags>. Each key is the name of a tag, while the tag descriptions are nested structures stored as related values.

  \GREEN<# tag declarations>
  %tags=(
         \RED<EMPHASIZE> => {...}

         \RED<COLORIZE>  => {...},

         \RED<FONTIFY>   => {...},

         ...
        );

Please note that there are no tag namespaces. Although Perl modules are used to define the tags, tags declared by various \C<PerlPoint::Tags::Xyz> share the same one "global scope", because a \PP document author simply uses all tag names the same way, regardless where they were defined. This means that different tags should be \I<named> different.

Each tag description consists of several parts: 

\LOCALTOC{type=linked}

Most of these parts are optional.


====Base definition

What the parser basically needs to know about a tag is if it takes options and a body, because this influences parsing directly. If a tag has no body but the parser looks for it, a parsing error might occur for no real reason, or bodylike source parts following the tag immediately would be misinterpreted. Providing the necessary informations is simple. Here's the example from the last section again, expanded by the related details.

  \GREEN<# tag declarations>
  %tags=(
         EMPHASIZE => {
                       \GREEN<# options>
                       \RED<options =\> TAGS_OPTIONAL>,

                       \GREEN<# don't miss the body!>
                       \RED<body    =\> TAGS_MANDATORY>,
                      },

         COLORIZE => {...},

         FONTIFY  => {},

         ...
        );

This is easy to understand. The \C<option> and \C<body> slots express if options and body are obsolete, optional or mandatory. This is done by using constants provided by
\BC<PerlPoint::Constants> (which comes with the framework). The following constants are defined:

@|
constant            | meaning
\BC<TAGS_OPTIONAL>  | Options/body can be used or not.
\BC<TAGS_MANDATORY> | The option/body part \I<must> be specified.
\BC<TAGS_DISABLED>  | No need to use options/body. \I<The parser will not expect such parts.> This means that with an obsolete body, an \C<<anything\>> sequence will not be treated as a tag body but as plain text. Likewise, if options are declared to be obsolete and a \C<{thing=something}> follows the tag name, this will be detected as plain text, not as the tag options. This can cause syntactical errors if the body is mandatory, because in this case the parser expects the body to follow the tag name.

Omitted \C<options> or \C<body> slots mean that options or body are \I<optional>. So a descripton at least consists of an empty anonymous hash (see \C<FONTIFY> in the example above).


====Parsing hooks

So based on your option and body declarations, the parser controls how it checks the tag syntax. If you need \I<further> checks you can \I<hook> into parsing by using the \C<hook> key, specifying a subroutine:

  %tags=(
         EMPHASIZE => {
                       \GREEN<# options>
                       options => TAGS_OPTIONAL,

                       \GREEN<# perform special checks>
                       \RED<hook> => sub {
                                    \GREEN<# get parameters>
                                    my (
                                        $tagline,
                                        $options,
                                        $body,
                                        $anchors
                                       )=@_;

                                    \GREEN<# checks>
                                    $rc=...

                                    \GREEN<# reply results>
                                    $rc;
                                   }
                      },

         COLORIZE => {...},

         FONTIFY  => {...},

         ...
        );

Whenever the parser detects an occurence of the defined tag, it will invoke the hook function and pass the source line number, a reference to a hash of option name / value pairs to check, a refernce to an array of body elements, and an anchor collection object. Using the \I<option hash> reference, the hook can read \I<and modify> the options. Different to this, the \I<body array> is \I<a copy> of the body part of the stream. Therefore the hook cannot modify the body part. (The parser depends on the body stream structure, and modifications could damage the streams integrity.)


\B<Example>

Here's an example hook from an implementation of \C<\\IMAGE>. It checks if all necessary options were set and if a specified image file really exists (to warn a user when an invalid image file is detected). Finally, it modifies the source option to provide the absolute path to the backend, which is known when the source is parsed, but unknown when the backend processes the stream.

  sub
   {
    \GREEN<# declare and init variable>
    my $ok=PARSING_OK;

    \GREEN<# take parameters>
    my ($tagLine, $options)=@_;

    \GREEN<# check them>
    $ok=PARSING_FAILED,
     warn qq(\\n\\n[Error] Missing "src" option in IMAGE tag, line $tagLine.\\n) 
      unless \RED<exists $options-\>{src}>;

    $ok=PARSING_ERROR,
     warn qq(\\n\\n[Error] Image file "$options->{src}" does not exist or is no file in IMAGE tag, line $tagLine.\\n)
      if $ok==PARSING_OK and \RED<not (-e $options-\>{src} and not -d _)>;

    \GREEN<# absolutify the image source path (should work on UNIX and DOS, but other systems?)>
    my ($base, $path, $type)=fileparse($options->{src});
    \RED<\B<$options-\>{src}=join('/', abs_path($path), basename($options-\>{src}))>>
       if $ok==PARSING_OK;

    \GREEN<# supply status>
    $ok;
   },


\B<Return codes>

The hook in the last example replied \C<PARSING_OK>, \C<PARSING_ERROR> or \C<PARSING_FAILED>. In general, a hook should return one of the following codes (defined by \BC<\PP::Constants>):

@|
return code            | description
\BC<PARSING_COMPLETE>  | Parsing will be stopped \I<immediately>. The source is declared to be valid.
\BC<PARSING_ERASE>     | The tag and all its contents will be removed from the stream.
\BC<PARSING_ERROR>     | A semantic error occurred. This error will be counted, but parsing will be continued to possibly detect even more errors.
\BC<PARSING_FAILED>    | A syntactic error occured. Parsing will be stopped immediately.
\BC<PARSING_IGNORE>    | The parser will ignore the tag. The result is just the body (if any).
\BC<PARSING_OK>        | The checked object is declared to be OK, parsing will be continued.


\B<Anchor management>

But what about the anchor parameter? We did not speak about it yet. Well, the \I<anchor object> passed to a hook is used "globally" to collect anchors declared in the \I<whole document>. It is an instance of \BC<\PP::Anchors>, built and maintained by the parser (the class is part of the framework). Providing all tags access to this central object is an offer to tag designers to store \I<every> anchor therein. By doing so all tags \I<referencing> anchors can verify links quickly.

The next example shows an implementation of the basic tags \C<\\SEQ> hook implementation. \C<\\SEQ> can take an optional name, which declares the produced number to be referencable by that name. The hook checks the setting and adds a new anchor name to the anchor collection.

  sub
   {
    \GREEN<# declare and init variable>
    my $ok=PARSING_OK;

    \GREEN<# take parameters>
    my ($tagLine, $options, $body, \RED<$anchors>)=@_;

    \GREEN<# check them (a sequence type must be specified, a name is optional)>
    $ok=PARSING_FAILED,
    warn qq(\\n\\n[Error] Missing "type" option in SEQ tag, line $tagLine.\\n)
      unless exists $options->{type};

    \GREEN<# still all right?>
    if ($ok==PARSING_OK)
      {
       \GREEN<# get a new entry, store it by option>
       $options->{__nr__}=++$seq{$options->{type}};

       \GREEN<# if a name was set, store it together with the value>
       \RED<\B<$anchors-\>add(>$options-\>{name}, $seq{$options-\>{type}}\B<)>
         if $options-\>{name};>
      }

    \GREEN<# supply status>
    $ok;
   },

Please note that when an anchor is registered, \I<two> values are stored. Besides the \I<name> of the anchor itself, this is a \I<value> which is something closely related to the anchor.

  For \\SEQ, the generated sequence number is made
  the anchors value. Whenever the anchor is accessed
  it will be possible to read the related number.

For pure link addresses it is recommended to store the anchor name both as name \I<and> value, but this depends on the usage which can be made of the link.

If one prefers, more anchor related things could be done in a hook, like checking if a new anchor is really new or was already declared before. That's up to you.

To sum it up, the parser managed anchor collection is a way to coordinate anchor related tags and make them interact \I<before backend invokation>. The parser itself uses it to register every headline as a similarly named anchor. Anchor related basic tags like \C<\\SEQ> and \C<\\REF> use it as well. While there is no \I<convention> to join their team, it is strongly \I<recommended> to do so for a simple reason: \PP document authors might be confused if several link checks are performed at parsing time, while other happen quite lately (in the backend). Nevertheless, the decision is yours.


\B<Conclusion>

Hooks are an interesting way to extend document parsing, but please take into consideration that tag hooks might be called quite often. So, if checks have to be performed, users will be glad if they are performed quickly.


====Post-parsing hooks

You are right. The previous section mentioned anchor reference checks several times but did not show how to perform them. Well, for an obvious reason. If I want to \I<check> a link via an anchor collection object in a parsing hook, I might fail even if the link is valid, because the hook is invoked at parsing time and the link might not have been parsed before the tag but may follow it somewhere. To check a reference, one needs to know the complete source first. To solve problems like this, another type of tag hooks is available.

\I<Post-parsing hooks> are invoked when parsing is successfully \I<completed> and a possibly installed parsing hook was called successfully. (So if a \C<hook> function returned an error code, the related post-parsing hook will be ignored.)

These hooks are defined via the \C<finish> key. Here's an example from an implementation of \C<\\REF>.

  finish =>  sub
              {
               \GREEN<# declare and init variable>
               my $ok=PARSING_OK;

               \GREEN<# take parameters>
               my \MAGENTA<($options, $anchors)>=@_;

               \GREEN<# try to find an alternative, if possible>
               if (exists $options->{alt} and not \RED<$anchors-\>query($options-\>{name})>)
                 {
                  foreach my $alternative (split(/\s*,\s*/, $options->{alt}))
                    {
                     if (\RED<$anchors-\>query($alternative)>)
                       {
                        warn qq(\n\n[Info] Unknown link address "$options->{name}" is replaced by alternative "$alternative".\n);
                        \BLUE<$options-\>{name}=$alternative>;
                        last;
                       }
                    }
                 }

               \GREEN<# check link for being valid - finally>
               unless (\RED<$anchors-\>query($options-\>{name})>)
                 {
                  \GREEN<# allowed case?>
                  if (exists $options->{occasion} and $options->{occasion})
                    {
                     $ok=PARSING_IGNORE;
                     warn qq(\n\n[Info] Unknown link address "$options->{name}": REF tag ignored.\n);
                    }
                  else
                    {
                     $ok=PARSING_FAILED;
                     warn qq(\n\n[Error] Unknown link address "$options->{name}".\n);
                    }
                 }
               else
                 {
                  \GREEN<# link ok, get value>
                  \BLUE<$options-\>{__value__}=>\RED<$anchors-\>query($options-\>{name})>->{$options-\>{name}};
                 }

                \GREEN<# supply status>
               $ok;
              },

This hook \RED<uses the anchor collection> to verify several passed links. If everything is ok, it extracts the value of the finally chosen anchor and stores it in an internal "option" slot (remember the \REF{name="Tag option conventions" type=linked}<tag option conventions>). To do so, \BLUE<it modifies the tag options>.

The \MAGENTA<interface> is quite similar to parsing hooks, except for data that cannot be provided after parsing, like source line number or the body contents. So a post-parsing hook receives the options hash (which it can modify as is wishes) and the anchor collection object and should return one of the follwing values:

@|
return code            | description
\BC<PARSING_ERASE>     | The tag and all its contents will disappear (which means that these parts will not be presented to the backend).
\BC<PARSING_ERROR>     | A semantic error occurred.
\BC<PARSING_IGNORE>    | The tag will disappear. The result is just the body (if any).
\BC<PARSING_OK>        | All right.

Use of another \C<PARSING_> constant is not recommended because it makes no sense in its original meaning, but it will be automatically treated as something very close: \C<PARSING_COMPLETE> is evaluated like \C<PARSING_OK>, while \C<PARSING_FAILED> is translated into \C<PARSING_ERROR>.


====Using foreign definitions

Sometimes definitions made by another module become important to a converter author, for example if a generalized version of existing tags becomes available.

  \B<pp2html> introduced various reference tags. After a
  while, it was decided to make a \I<generalized> reference
  tag \I<\\REF> available with \C<\PP::Package>.

To avoid multiple similar implementations, and to allow it to keep well known tag interfaces alive while using new features, or simply to use a tag from another definition module as base of an own tag definition, it is possible to call a foreign hook function from a tag hook, passing the tag name, the hook type (\C<hook> or \C<finish>) and the usual parameters.

   $rc=\RED<PerlPoint::Tags::call('TAG', 'hook', @_)>;

If the tag is not registered, or has no hook of the specified type, an undefined value is supplied, otherwise you receive the return code of the invoked function.

By using this feature, one could translate own options to the options of the used "base" tag, invoke its hook, translate the values back and continue processing. The invoked hook might perform all one needs, or one might add own operations. One could even try to combine several other tags ...

Of course, for reasons of performance, it is not recommended to use this interface between tags declared in the same module. Please stay with usual function calls then to avoid an additional function call layer.



===Tag sets

Tag definitions can be grouped by setting up a global hash named \C<%sets>.

  %sets=(
         pointto => [qw(EMPHASIZE COLORIZE)],
        );

When using the definition module, this allows to activate the tags \C<\\EMPHASIZE> and \C<\\COLORIZE> together:

  \GREEN<# declare all the tags to recognize>
  use PerlPoint::Tags::New \RED<qw(:pointto)>;

The syntax is obviously borrowed from Perls usual import mechanism.

Tag sets can overlap:

  %sets=(
         pointto => [qw(EMPHASIZE \RED<COLORIZE>)],
         set2    => [qw(\RED<COLORIZE> FONTIFY)],
        );

And of course they can be nested:

  %sets=(
         \RED<pointto> => [qw(EMPHASIZE COLORIZE)],
         all     => [(\RED<':pointto'>, qw(FONTIFY))],
        );


===Completing the module

As usual, the module should flag successful loading by a final statement like

  1;


===Integrating foreign tags

You may want your converter to provide tags already defined somewhere. It is not necessary to redefine them, which would make it hard to keep all definitions synchronized later. Instead of this, simply load the appropriate modules. As an example, here's the (almost) complete code of \C<\PP::Tags::SDF>. The related converter \C<pp2sdf> does not define a single tag itself - its tag definitions are just a combination of "foreign" tags.

  01: \GREEN<# declare package>
  02: package PerlPoint::Tags::SDF;
  03: 
  04: \GREEN<# declare package version>
  05: $VERSION=...;
  06: 
  07: \GREEN<# declare base "class">
  08: use base qw(PerlPoint::Tags);
  09: 
  10: \GREEN<# set pragmata>
  11: use strict;
  12: 
  13: \GREEN<# declare tags (reuse definitions made elsewhere)>
  14: \RED<use PerlPoint::Tags::Basic;>
  15: \RED<use PerlPoint::Tags::HTML qw(A L PAGEREF SECTIONREF U XREF);>
  16: 
  17: 1;

This example demonstrates two methods of reusing other definitions. Line 14 loads all definitions made by \C<PerlPoint::Tags::Basic>. Line 15, on the other hand, picks certain definitions made by \C<PerlPoint::Tags::HTML>, the definition file of \C<pp2html>, ignoring all definitions not explicitly listed in the \C<use> statement.

If tags are defined in more than one of the included modules, messages will be displayed warning about duplicated definitions. New definitions overwrite earlier ones, so the last appearing definition of a tag wins.


===Documentation

The tag definition module is a good place to describe your tags by POD. This way, CPAN will provide these descriptions automatically to both other converter authors and \PP users.

Additionally, it is recommended to provide \PP documentations, one file per tag. Examples can be found in \C<\PP::Package>, describing the base tags \C<\\B>, \C<\\C>, \C<\\I>, \C<\\IMAGE> and \C<\\READY>. Those documentations, collected from all available converters, will make it easy to build (and maintain) a reference document of all \PP tags automatically which is planned to be provided on a future \PP homepage.


===Examples and more

\C<\PP::Package> comes with various tag modules which may illustrate this chapter. Please have a look at \C<\PP::Tags::Basic> and \C<\PP::Tags::SDF>.

Further documentation about tag definition can be found in the manpage of \C<\PP::Tags>.


=Writing the converter

Because all converters are built on base of the same frameset, there's a general scheme they can be constructed according to, which is described in the following chapters. Additionally to the frameset there are several \I<conventions> what features all converters should share. These conventions are only suggestions, no rules, but make it easier for \PP users to deal with various converters.

==The converter package

Different to usual Perl scripts, each \PP converter should declare its own namespace, which is by convention \C<\PP::Converter::<converter name\>>.

  \GREEN<# declare script package>
  package \RED<PerlPoint::Converter::pp2sdf>;

The background of this convention is the way \I<Active Contents> is implemented. \I<Active Contents> means \PP source parts made from embedded Perl. To make document source sharing as secure as possible, and configurable to \PP users, this embedded Perl can be evaluated in a compartment provided by the \BC<Safe> module.

\C<Safe> executes passed code in a special namespace, to suppress access to "unsafed" code parts. It is arranged that the \I<executed code itself> sees this namespace as \C<main>. So the embedded code uses \C<main>, which is in fact the special compartment namespace \I<different> to \C<main>.  

OK. That's no problem. But unfortunately not all code can be executed by \C<Safe>. It is different to use \C<sort> and to load modules, for example. That's why current versions of the frameset allow to execute Active Contents by \C<eval()> alternatively.

Now, if a document author writes Active Contents, he's not necessarily aware of how this embedded code will be executed. He doesn't know about \C<Safe> and \C<eval()>, so \PP has to arrange that the code can be executed \I<both> ways. Because it cannot modify \C<Safe>, it has to deal with \C<eval()>, so it makes it working in \C<main>. This means that embedded user code will access \C<main>, and that's why \C<main> should not be used by a converter itself.


==Modules to load

Several modules need to be loaded by all converters.

  use Safe;

\BC<Safe> is necessary to arrange the \XREF{name="The converter package"}<mentioned> execution of embedded Perl code.

  use Getopt::Long;
  use Getopt::ArgvFile;

\BC<Getopt::Long> and \BC<Getopt::ArgvFile> are used to evaluate converter options. This handling can of course be managed by alternative option modules or handcrafted code, if you prefer.

  use PerlPoint::Parser;
  use PerlPoint::Backend;
  use PerlPoint::Constants;

These modules are used to build parser and backend.

  use PerlPoint::Tags;

\BC<\PP::Tags> enables to accept tags defined by \I<other> converters.

  use PerlPoint::Tags::Format;

Finally, declare the tags which shall be be valid. These can be tags you \XREF{name="Tag definition"}<defined> for this converter especially, tags developed for another converter or basic tags provided with the converter framework. If the tags you want to support are spread around, you can load as many definition modules as necessary. Note that warnings will be displayed if tags are defined multiply, and that the last appearing definition of a tag will overwrite earlier ones.


==Several variables

Of course the variables to declare strongly depend on how you are going to construct your converter. For the following sections, we need an array to store stream data in, and a hash to mirror user options.

  \GREEN<# declare variables>
  my (
      @streamData,                # PerlPoint stream;
      %options,                   # option hash;
     );

==Option handling

Option handling is a highly individual part of software design. CPAN provides numerous modules which solve this task in several ways. This reflects the very different preferences of various people, and we do not want to restrict anyone in this field. On the other hand, \PP will be obviously easier to use if its several converters provide similar working interfaces. For this reason, the following conventions are established:

* Provide a way to use \XREF{name="Option files"}<option files>.

* Provide \XREF{name="Common options"}<common \PP options>.


===Option files

Option files allow to specify Perl script options \I<by files>, so they simply contain what would normally be specified in the commandline. This relieves a user from typing in typical options again and again. It also allows to \I<reuse> options, which is helpful if a script provides a great option number. \C<pp2html>, for example, currently offers about 80 options. It is almost impossible to remember the combinations which produce a certain result, but it is easy to store them in a file like this:

  \GREEN<# configure style>
  -style_dir /opt/perlpoint/pp2html/styles
  -style surprise

, to store this file as \C<style.cfg> and to invoke \C<pp2html> as in

  > pp2html \RED<@style.cfg> ...

Option files can be nested and cascaded, and you can use as many of them as you want. It is also possible to use \I<default> option files which do not need to be specified when calling the script but are resolved automatically. They make it very handy to use a multi option script.

To provide option file usage, all you have to do is to integrate the following statement.

  \GREEN<# resolve option files>
  argvFile(default=>1, home=>1);

\C<argvFile()> is a function of \C<Getopt::ArgvFile> which was already \XREF{name="Modules to load"}<loaded> and performs three tasks in this call:

# It searches the users home directory for a file named \C<.<converter name\>>, e.g.
  \C<\B<.>pp2sdf>. All options found therein are "unshifted" into \C<@ARGV>. A default
  option file in ones home directory stores individual preferences of calling the converter.

# It searches the directory where the converter script is located for (probably another)
  \C<.<converter name\>> and integrates its options likewise, "unshifting" them to \C<@ARGV>
  as well. Such a global option file can be used to set up options to be used by all
  script users.

# It processes \C<@ARGV> to resolve any explicit and nested option files.

The result is an \C<@ARGV> array which contains all options, both specified directly and by file, ready to be processed by usual option handling modules like \BC<Getopt::Long>.


===Common options

I personally prefer \BC<Getopt::Long> for option handling. Your preferences may vary, but please provide at least the options specified in this example statement:

  \GREEN<# get options>
  GetOptions(\%options,

             "activeContents",    \GREEN<# evaluation of active contents;>
             "cache",             \GREEN<# control the cache;>
             "cacheCleanup",      \GREEN<# cache cleanup;>
             "help",              \GREEN<# online help, usage;>
             "nocopyright",       \GREEN<# suppress copyright message;>
             "noinfo",            \GREEN<# suppress runtime informations;>
             "nowarn",            \GREEN<# suppress runtime warnings;>
             "quiet",             \GREEN<# suppress all runtime messages except of error ones;>
             "safeOpcode=s@",     \GREEN<# permitted opcodes in active contents;>
             "set=s@",            \GREEN<# user settings;>
             "tagset=s@",         \GREEN<# add a tag set to the scripts own tag declarations;>
             "trace:i",           \GREEN<# activate trace messages;>
            );

:\BC<activeContents>: flags if active contents shall be evaluated or not.

:\BC<cache>: allows user to activate and deactivate the cache.

:\BC<cacheCleanup>: enforces a cleanup of existing cache files.

:\BC<help>: displays a usage message, which is usually the complete converter manpage.
            The converter is stopped after performing the display task.

:\BC<nocopyright>, \BC<noinfo> and \BC<nowarn>: suppress informations a user can occasionally
                                                live without: copyright messages, informations
                                                and warnings.

:\BC<quiet>: combines \C<nocopyright>, \C<noinfo> and \C<nowarn>.

:\BC<safeOpcode>: Embedded code ("Active Contents") is usually executed in a \BC<Safe>
                  compartment. This way a user can control which operations shall be allowed
                  and which shall be denied. According to the interface of \C<Safe>, allowed 
                  operations are specified by Perl opcodes as defined by the \BC<Opcode>
                  module. With this option, a user can specify such an opcode to allow its
                  execution. It can be used multiply to accept several opcodes. Alternatively,
                  the user might pass the special string \C<ALL> which flags that Active
                  Contents shall be executed without any restriction - which will be done by
                  using \C<eval()> instead of \C<Safe>.

:\BC<set>: provides a way to inject user defined settings into Active Contents. This is helpful
           to process documents in various ways, without a need to modify document sources.

:\BC<tagset>: can be used multiply to declare that foreign tags shall be accepted. Foreign tags
              are tags not supported by the converter, but defined for other converters. By 
              accepting them, a user can make a source pass to the converter even if it uses
              tags of another converter.

:\BC<trace>: activates several traces, at least of the frameset modules.

Luckily, the implementation of most of these options is as common as the options themselves and shown in the following sections. So in most cases it's no extra effort to provide these features.

For example, \C<quiet> can be implemented by

  @options{qw(nocopyright noinfo nowarn)}=() x 3 if exists $options{quiet};

It should be possible to control traces by an environment variable \BC<SCRIPTDEBUG> as well as by option \C<trace>:

  $options{trace}=$ENV{SCRIPTDEBUG} if not exists $options{trace} and exists $ENV{SCRIPTDEBUG};


==Usual startup operations

Now could be a good time to display a copyright message if you like.

  \GREEN<# display copyright unless suppressed>

Help requests can be fulfilled very quickly, because they do not need further operations.

  \GREEN<# check for a help request>
  (exec("pod2text $0 | less") or die "[Fatal] exec() cannot be called: $!\n") if $options{help};

After presenting the manpage, the converter stops. It also terminates in case of a wrong usage, especially missing document sources.

  \GREEN<# check usage>
  die "[Fatal] Usage: $0 [<options>] <PerlPoint source(s)>\n" unless @ARGV>=1;

  \GREEN<# check passed sources>
  -r or die "[Fatal] Source file $_ does not exist or is unreadable.\n" foreach @ARGV;


==Foreign tag integration

Every converter \XREF{name="Modules to load"}<supports> a set of tags, but users can process the same sources by \I<several> converters which support different tags, so a source to be read by your converter may contain tags you did not think of. Fortunately this can be easily handled by implementing \XREF{name="Common options"}<option> \C<-tagset> and the following statement.

  \GREEN<# import tags>
  PerlPoint::Tags::addTagSets(@{$options{tagset}}) if exists $options{tagset};

\C<PerlPoint::Tags::addTagSets()> extends the converters tag definitions by loading foreign \XREF{name="Writing a tag module"}<definition files>. To make this intuitive, users have to pass \I<target formats> to \C<-tagset>, e.g. \C<HTML>.

  If a document was initially written to be processed
  by pp2\RED<html> and is now passed to your converter,
  a user can use "-tagset \RED<HTML>".

Tag definition packages are named \C<\PP::Tags::<target format\>>, so this rule makes it easy to find the appropriate definitions, and \C<PerlPoint::Tags::addTagSets()> can load them.

  If "-tagset \RED<HTML>" is specified, the definition
  module \PP::Tags::\RED<HTML> is loaded.

Please note that because \C<-tagset> is intended to reflect definitions made for a certain converter, there is no way to load only a subset of another converters tags descriptions.

Different to usual \XREF{name="Modules to load"}<definition loading>, no warning is displayed here if a loaded foreign tag is named like an own one, and the \I<original> converter definition will remain established to give the converter first priority.


==Set up Active Contents handling

If the special opcode \C<ALL> was passed, all embedded Perl operations are permitted and there's no need to perform them in a compartment provided by the \BC<Safe> module. This is flagged by a true \I<scalar> value. Otherwise, we need to construct a \C<Safe> object and to configure it according to the opcode settings.

  \GREEN<# Set up active contents handling. By default, we use a Safe object.>
  my $safe=new Safe;
  if (exists $options{safeOpcode})
   {
    unless (grep($_ eq 'ALL', @{$options{safeOpcode}}))
      {
       \GREEN<# configure compartment>
       $safe->permit(@{$options{safeOpcode}});
      }
    else
      {
       \GREEN<# simply flag that we want to execute active contents>
       $safe=1;
      }
   }

The variable \C<$safe> which is prepared by this code is intended to be passed to the parser soon.


==The parser call

And now, the parser can be called. Because it is implemented by a class, we first need to build an object, which is simple.

  \GREEN<# build parser>
  my $parser=new PerlPoint::Parser;

The objects method \C<run()> invokes the parser to process all document sources. Various parameters control how this task is performed and need to be set according to the converter options. It should be sufficient to simply copy this call and to slightly adapt it.

  \GREEN<# call parser>
  $parser->run(
               stream          => \\@streamData,
               files           => \\@ARGV,

               filter          => 'perl|sdf|html',

               safe            => exists $options{activeContents} ? $safe : undef,

               activeBaseData  => {
                                   targetLanguage => 'SDF',
                                   userSettings   => {map {$_=>1} exists $options{set} ? @{$options{set}} : ()},
                                  },

               predeclaredVars => {
                                   CONVERTER_NAME    => basename($0),
                                   CONVERTER_VERSION => do {no strict 'refs'; ${join('::', __PACKAGE__, 'VERSION')}},
                                  },

               vispro          => 1,

               cache           =>   (exists $options{cache} ? CACHE_ON : CACHE_OFF)
                                  + (exists $options{cacheCleanup} ? CACHE_CLEANUP : 0),

               display         =>   DISPLAY_ALL
                                  + (exists $options{noinfo} ? DISPLAY_NOINFO : 0)
                                  + (exists $options{nowarn} ? DISPLAY_NOWARN : 0),

               trace           =>   TRACE_NOTHING
                                  + ((exists $options{trace} and $options{trace} &  1) ? TRACE_PARAGRAPHS : 0)
                                  + ((exists $options{trace} and $options{trace} &  2) ? TRACE_LEXER      : 0)
                                  + ((exists $options{trace} and $options{trace} &  4) ? TRACE_PARSER     : 0)
                                  + ((exists $options{trace} and $options{trace} &  8) ? TRACE_SEMANTIC   : 0)
                                  + ((exists $options{trace} and $options{trace} & 16) ? TRACE_ACTIVE     : 0),
              ) or exit(1);


So what happens here?

:\BC<stream>: passes a reference to an array which will be used to store the stream element
              in. It is suggested to pass an empty array (but currently new fields will be
              \I<added>, so existing entries will not be damaged).

:\BC<files>: passes an array of document source files to parse.

:\BC<filter>: declares which formats are allowed to be embedded or included. You can accept all
              formats which can be processed by the software which has to deal with the converter
              product, and "perl" to provide the full power of Active Contents. All formats not
              matching the filter will be \I<ignored>.

:\BC<safe>: pass the \XREF{name="Set up Active Contents handling"}<prepared> variable \C<$safe>.

:\BC<activeBaseData>: sets up a hash reference which is made accessible to Active Contents as
                      \C<$main::\PP>. The keys \C<targetLanguage> and \C<userSettings> are
                      provided by convention, but you may add whatever keys you need.

:\BC<vispro>: if set to a true value, the parser will display runtime informations.

:\BC<cache>: used to pass the cache settings. Please copy this code.

:\BC<display>: used to pass the display settings. Please copy this code.

:\BC<trace>: used to pass the trace settings. Please copy this code.


\C<run()> returns a true value if parsing was successful. It is recommended to evaluate this code and to stop processing in case of an error.

  \GREEN<# call parser>
  $parser->run(...) \RED<or exit(1)>;


==Backend construction

When the sources are parsed their data are represented in the stream where they can be processed to produce the final document(s). It is strongly recommended to do this by using the backend class shipped with the converter framework. In a first step, we have to make an object of this class. It is immediately configured, right by the constructor call.

  \GREEN<# build a backend>
  my $backend=new PerlPoint::Backend(
                                     name    => 'pp2sdf',
                                     display =>   DISPLAY_ALL
                                                + (exists $options{noinfo} ? DISPLAY_NOINFO : 0)
                                                + (exists $options{nowarn} ? DISPLAY_NOWARN : 0),
                                     trace   =>   TRACE_NOTHING
                                                + ((exists $options{trace} and $options{trace} & 32) ? TRACE_BACKEND : 0),
                                     vispro  => 1,
                                    );

Names and behaviour of these constructor options are mostly known from \XREF{name="The parser call"}<call> of the parsers \C<run()> method.

:\BC<name>: a description used to identify the backend.

:\BC<display>: used to pass the display settings. Please copy this code.

:\BC<trace>: used to pass the trace settings. Please copy this code.

:\BC<vispro>: if set to a true value, the backend will display runtime informations.

Note: because backend processing does not consume stream data, it is possible to use more than one backend at a time, but there are still side effects. This may be improved by future framework versions.


==Backend callbacks

A backend is used to translate stream elements into appropriate expressions of the target format. Because of this, backends need to work very format (or converter) specific. The only common task is to read the stream and to ignore all parts which the converter doesn't wish to support. These requirements are solved by a callback architecture.

When a backend is \XREF{name="Backend invokation: produce new code"}<started>, it (usually) runs through the stream. Every stream element is checked for its type, and then it is checked if a callback was specified to handle it. If so, the callback will be invoked to handle the element found, if not, the element is ignored. Simple but powerful!

To make this work, callbacks need to be registered before the backend starts its stream run. This is done by the backend method \BC<register()>.

  \GREEN<# register backend handlers>
  $backend->register(DIRECTIVE_BLOCK, \\&handleBlock);
  ...

\C<register()> takes an element type and a code reference. All possible stream element types are declared by constants, which are defined and documented in \BC<\PP::Constants>. The code reference, on the other hand, points to a function which shall be invoked when an element of the described type is detected, which means that it begins or ends.

Consider, for example, the statement in the last recent example: \C<DIRECTIVE_BLOCK> describes a code block element. The stream does not store blocks by large objects, but by a begin and end flag which show the "edges" of the block construction. Therefore the specified callback \C<handleBlock()> will be invoked twice: it will be called both when the block begins and when it is completed.

The callback \I<interface> is simple. It has a \I<common> part which is equal for all elements, and a \I<special> part which depends on the element type. The common part includes the element type (\C<DIRECTIVE_BLOCK>, \C<DIRECTIVE_TEXT>, ...) and the mode which is either \C<DIRECTIVE_START> or \C<DIRECTIVE_COMPLETE>, flagging if the element is starting or completed.

The \I<special part> contains things like the name of a source file (\C<DIRECTIVE_DOCUMENT>), tag options (\C<DIRECTIVE_TAG>) or a headline level (\C<DIRECTIVE_HEADLINE>). See \XREF{name="Appendix A: Stream directives"}<Appendix A> for a complete list of all callback interfaces.

There is no common way how callbacks should work. It strongly depends on the target format, the converter features and the tags. You may build another data structure which is finally made a file, or print immediately, or mix both approaches, and there are several more choices like this. But the frameset helps to begin coding this individual part quickly.


==Backend invokation: produce new code

Everything is well prepared now, so we can finally run the backend and generate the results a user is waiting for. There are several ways to do this, but there are useful defaults which make it pretty easy to perform the task. Let's have a look at this default processing first:

  \GREEN<# run the backend>
  $backend->run(\\@streamData);

That's all the necessary code. It enforces the backend to process all tokens in the passed stream data token by token, to detect their type, and to invoke appropriate \XREF{name="Backend callbacks"}<handlers> if registered.

In most cases, this is a very sufficient way to build a translator to a target language. If it is not, you can vary the \XREF{name="Vary token selection"}<choice of tokens> to handle and \XREF{name="Vary processing control"}<the way of stream procesing>. More, you can freely \XREF{name="Stream navigation"}<navigate> through the chapters of a document. See the following subsections for details.


===Vary token selection

By default, a backend object inspects the token stream token by token. This way everything
is handled in the original order, according to the input once parsed. But sometimes you want
to know something about the documents \I<structure> which simply means about \B<headlines>
\I<only>.

  For example, consider the case that you want to build
  a table of contents or a table of valid chapter references
  before the "real" slides are made. In the mentioned token
  mode this takes more time than it should, because a lot
  of additional tokens are processed besides the headlines.

In such cases, the backend can be enforced to work in "headline mode". This means that \I<only>
headlines are processed which accelerates things significantly. The backend only deals with
opening and closing headline directives and the tokens between them - usually very few.

Modes are switched by method \BC<mode()>. The following code limits the usual stream processing
to headlines.

  \GREEN<# switch to headline mode>
  \RED<$backend-\>mode(STREAM_HEADLINES);>

From now on, subsequent calls to \C<run()> (or \XREF{name="Vary processing control"}<next()>)
will take \I<only headlines> into account, ignoring anything else.

To switch back to the usual behaviour, \C<mode()> has to be called with another constant.
(All \C<STREAM_...> constants are declared in \C<PerlPoint::Constants> and can be imported by the
import tag \C<:stream>.)

  \GREEN<# switch to headline mode>
  \RED<$backend-\>mode(STREAM_TOKENS);>

Please note that a stream can be processed more than once, so one can process it in headline mode
first, use the headline information, and then switch back to the usual token mode and process the
entire document data.

You can even switch modes \I<while> processing the stream, which means from within a backend
callback. The new mode will come into action when the next element will be searched. So, if you
are running your backend in token mode and switch to headline mode, the next handled element
will be the following headline - remaining elements in the \I<current> chapter will be ignored.
On the other hand, if switched from headline mode to token processing from within a callback, the
backend will begin to provide the contents of the chapter which headline was handled when the
switch was performed.


===Stream navigation

Usually a stream is processed from the beginning to its end, but it is possible to set up an
arbitrary sequence of chapters as well. (This is mostly intended for use in projectors - imagine
how a speaker switches slides back and forth.) Two methods are provided to do this: \BC<reset()>
moves back to the beginning of the entire stream, while \BC<move2chapter()> chooses a certain
chapter to continue the processing with.

  \GREEN<# back to start>
  $backend->\RED<reset>;

  \GREEN<# proceed with 2nd chapter>
  $backend->move2chapter(2);

All navigation methods take affect in the \I<next> subsequent stream entry handling. That's why
navigation can be performed both from backend callbacks (invoked by \C<run()> \I<or> \C<next()>)
or before a \C<next()> call.

The chapter number passed to \C<move2chapter()> is an \I<absolute> number - the first
headline is headline \B<1>, the second is headline \B<2> etc. - regardless of headline
hierachies. The current headline number is always provided by \BC<currentChapterNr()>.

  \GREEN<# Which chapter are we reading?>
  $backend->\RED<currentChapterNr>;

This information could then be used to skip a chapter, for example.

  \GREEN<# skip a chapter>
  $backend->move2chapter($backend->currentChapterNr+2);

But - \I<are> there two more chapters, really? The \I<highest valid> headline number is provided
by the method \BC<headlineNr()>, which replies the number of headlines in the stream associated
with the backend object. (If no stream is associated, an undefined value is supplied.)

  \GREEN<# How many chapters to read through?>
  $backend->\RED<headlineNr>;

So, using this information we can avoid that \C<mode2chapter()> dies because of an invalid chapter
number, which would cause a fatal error otherwise.

  \GREEN<# move two chapters, if possible>
  $backend->move2chapter($backend->currentChapterNr+2)
    unless $backend->currentChapterNr+2>$backend->headlineNr;



===Vary processing control

The base model of stream processing implemented by \C<\PP::Backend> is based on "events", which
means that the token stream is processed by a loop which invokes user specified callback functions
to handle certain token types. In this default model, the \I<loop> is in control. You can
configure it, you can start it whenever you want, but once it is started it processes the entire
stream before control is passed back to your code.

This works fine in stream translation, e.g. to produce slides/documents straight into a target
format, and is done by invoking the method
\I<\XREF{name="Backend invokation: produce new code"}<run()>>.
Nevertheless, there are cases when converters need to be in \I<full> control, which means in fine
grained control of token processing. In this model \I<the calling program> (the converter)
initiates the processing of \I<every single token>. This is especially useful if a converter is
not really a converter but a projector which uses the stream to \I<present> the slides on the fly.

This second model of fine grained control is supported as well. The appropriate method (used
as an alternative of \C<run()>) is \BC<next()>. \C<next()> processes exactly \I<one> stream entry
and returns.

  \GREEN<# process next stream entry>
  $backend->\RED<next>;

After the \C<next()> call, you may \XREF{name="Stream navigation"}<move to another chapter>,
\XREF{name="Vary token selection"}<switch modes>, perform intermediate
tasks, allow a user to interact with your tool or something like that. Then, when it seems
to be the right time to proceed, you may invoke \C<next()> for another entry. But if you prefer,
you may as well decide to \I<stop> stream processing, without having handled all entries. It's
entirely up to you this way.

\I<Processing> an entry works \I<equally> to \C<run()>, by type detection and handler invokation,
there's absolutely no difference.

To make a backend object know of the stream to handle and enable it to store position hints
between several \C<next()> calls, a stream must be \I<bound> to a backend object before
\C<next()> can be used. This is done by I<bind()>.

  \GREEN<# bind the stream>
  $backend->\RED<bind($streamData)>;

  \GREEN<# process next stream entry>
  $backend->next;

After processing all data, I<unbind()> may be used to detach the stream.

  \GREEN<# detach the stream>
  $backend->\RED<unbind>;

Here's a complete example, emulating \C<run()> by \C<next()>:

  $backend->bind($streamData);
  {redo while $backend->next;}
  $backend->unbind;

So emulation is easy, but \I<mixing> both approaches is impossible to avoid confusion. 
This especially means that \C<next()> cannot be called from a callback invoked by \C<run()>.


===Mix it your way

\XREF{name="Vary token selection"}<Token selection modes>,
\XREF{name="Stream navigation"}<stream navigation>
and \XREF{name="Vary processing control"}<processing control>
can be set up independently. Mix them the way it meets your needs.


==Your individual parts

To complete the common "torso" shown in the sections above, you mostly need to add your own
\XREF{name="Backend callbacks"}<backend callbacks>. Go for it! We are curious about a new
interesting converter.

Please note that this document does not describe the complete backend API. Please have a
look at the manpage of \C<PerlPoint::Backend> as well. For example, there's a method \C<toc()>
that provides a list of subchapters, either of the complete document or of a certain "parent"
chapter. This can simplify TOC related tasks significantly.


=Documentation

As a \PP converter, it would be great to be delivered with a \PP documentation. If you want to do so, it might be helpful to have a look at the converter packages \C<doc> directory. Its parts are intended to be a help to converter documentation authors, describing parts of the base implementation. Feel free to copy these parts and to modify it according to your implementation. (To keep the results maintainable, \\INCLUDE may be used to integrate the framework components.)


=Appendix A: Stream directives

The following table describes the backends callback interfaces. The very first parameters
passed are a directive constant describing the detected items type, and a state constant
expressing the item either begins (\C<DIRECTIVE_START>) or is completed (\C<DIRECTIVE_COMPLETE>).

Although in the first design it was intended to make everything being enclosed by a start
\I<and> a completion directive, it turned out to be more pragmatic to let several very simple
tokens (and therefore stream elements) being represented by a \C<DIRECTIVE_START> flag only.
The table mentions all used flags.

If start \I<and> completion are flagged, tokens of various other types may be embedded. A
headline, for example, starts by a startup directive, embeds plain string tokens and possibly
flags, and is finally closed by  completion directive. On the other hand, tokens that only
provide a startup flag are \I<completely> represented by the token element containing the flag.
That means that plain string directives, for example, contain the string as well - nothing more
will follow. (That's easier to understand than to describe, hm.)

All parameters beginning with the third one are absolutely type specific.

If there are beginning and completing elements, all parameters will be provided at both places except where noted.

@|
1: type directive          | 2: used flags (modes)                        | 3...: more parameters
\BC<DIRECTIVE_BLOCK>       | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
\BC<DIRECTIVE_COMMENT>     | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
\BC<DIRECTIVE_DLIST>       | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | a reserved parameter, two parameters describing type and level of a preceeding list shift if any (0 otherwise, only provided in \I<start> directives), two parameters describing type and level of a following list shift if any (0 otherwise, only provided in \I<completion> directives)
\BC<DIRECTIVE_DOCUMENT>    | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | (base)name of source file
\BC<DIRECTIVE_DPOINT>      | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | a reserved parameter, two parameters describing type and level of a preceeding list shift if any (0 otherwise, only provided in \I<start> directives), two parameters describing type and level of a following list shift if any (0 otherwise, only provided in \I<completion> directives)
\BC<DIRECTIVE_DPOINT_ITEM> | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
\BC<DIRECTIVE_HEADLINE>    | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | Headline level. The full headline title (tags stripped off) is provided additionally in the startup directive \I<only>.
\BC<DIRECTIVE_LIST_LSHIFT> | \C<DIRECTIVE_START>                          | number of levels to shift
\BC<DIRECTIVE_LIST_RSHIFT> | \C<DIRECTIVE_START>                          | number of levels to shift
\BC<DIRECTIVE_NEW_LINE>    | \C<DIRECTIVE_START>                          | a hash reference: key "file" provides the current source file name, key "line" the new line number
\BC<DIRECTIVE_OLIST>       | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | A prefered startup number (defaults to 1). Two parameters describing type and level of a preceeding list shift if any (0 otherwise, only provided in \I<start> directives), two parameters describing type and level of a following list shift if any (0 otherwise, only provided in \I<completion> directives)
\BC<DIRECTIVE_OPOINT>      | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
\BC<DIRECTIVE_SIMPLE>      | \C<DIRECTIVE_START>                          | a list of strings
\BC<DIRECTIVE_TAG>         | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | First, the tag name, then a reference to a hash of tag options taken from the source. \I<Tag options in the open directive might have been modified by a tag finish hook and therefore differ from the options provided in the closing directive, which reflects the original options (before finish hook invokation).>
\BC<DIRECTIVE_TEXT>        | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
\BC<DIRECTIVE_ULIST>       | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
\BC<DIRECTIVE_UPOINT>      | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
\BC<DIRECTIVE_VARRESET>    | \C<DIRECTIVE_START>                          | -
\BC<DIRECTIVE_VARSET>      | \C<DIRECTIVE_START>                          | a hash reference: key "var" provides the variables name, key "value" the new value
\BC<DIRECTIVE_VERBATIM>    | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -


And here is how these directives correspond to the \PP source elements. To make reading
(and writing ;-) simpler, the string \C<DIRECTIVE_> and the type specific parameters passed
to appropriate callbacks are omitted. See the table above fo those details. A directive is
illustrated by enclosing brackets.

\B<Block:>

  [BLOCK, START]

    block contents

  [BLOCK, COMPLETED]


\B<Comment:>

  [COMMENT, START]

    comment text

  [COMMENT, COMPLETED]


\B<Description list:> The "description point item" is the described thing, marked in \PP
by enclosing colons.

  [DLIST, START]
    
    [DPOINT, START]
    
       [DPOINT_ITEM, START]

         item elements (text, tags, ...)

       [DPOINT_ITEM, COMPLETED]

       description elements (text, tags, ...)
    
    [DPOINT, COMPLETED]
    
    \I<there may be more points>

  [DLIST, COMPLETED]


\B<Document:>

  [DOCUMENT, START]

    main stream

  [DOCUMENT, COMPLETED]


\B<Headline:>

  [HEADLINE, START]

    headline text, tags etc.

  [HEADLINE, COMPLETED]


\B<List shifts:> Because these directives are extremely simple, there
                 are no completion directives.

  [LIST_LSHIFT, START]

-

  [LIST_RSHIFT, START]



\B<Ordered list:>

  [OLIST, START]
    
    [OPOINT, START]
    
      point contents
    
    [OPOINT, COMPLETED]
    
    \I<there may be more points>

  [OLIST, COMPLETED]



\B<Plain text:> the parser tries to provide as much text together as possible. Nevertheless,
there's no guarantee that a certain string sequence will be provided by a certain stream
sequence of simple token directives. Whatever way a simple token sequence \I<is> provided,
joining their contents by empty strings will result in the original string sequence.

  [SIMPLE, START]



\B<Tag:>

  [TAG, START]

    tagged things

  [TAG, COMPLETED]


\B<Text:>

  [TEXT, START]

    text

  [TEXT, COMPLETED]


\B<Unordered list:>

  [ULIST, START]
    
    [UPOINT, START]
    
      point contents
    
    [UPOINT, COMPLETED]
    
    \I<there may be more points>

  [ULIST, COMPLETED]



\B<Verbatim block:>

  [VERBATIM, START]

    block contents

  [VERBATIM, COMPLETED]


