# Template-Plugin-Gettext

Localization for the Template Toolkit 2

## Description

This Perl library offers a complete translation solution for the Template Toolkit 2.
It consists of a plugin that offers translation functions inside templates
and a string extractor `xgettext-tt2` that extracts translatable strings
from templates and writes them to PO files (or rather a `.pot` file in PO
format).

## Usage

The solution offered by this library is suitable for templates that have 
a lot of markup (normally HTML) compared to text.  If the files contain
a lot of content other solutions are probably more suitable.  One of them
is [xml2po](https://github.com/mate-desktop/mate-doc-utils/tree/master/xml2po),
especially if the input format is HTML.

If the input format is Markdown, for example for a static side generator,
a feasible approach may be to simply split the input into paragraphs, and
turn each paragraph into an entry of a PO file.

In the following, we will assume that you have decided to localize
templates with this library.

### Templates

The first step is to mark all translatable strings.  This serves
a double purpose.  Strings are marked, so that the extractor 
`xgettext-tt2` can find them and write them into a translation file 
in PO format.

The second purpose is that these markers are also valid functions
resp. filters for the template toolkit and will interpolate the
translations for these messages into the output, when rendering the
template.  As a result, your templates remain pretty readable after
localizing them.

In every source file that you want to use translations, you have
to `USE` the template:

    [% USE gtx = Gettext('com.mydomain.www', 'fr') %]

Do *not* forget to `USE` the plug-in in all templates!  The template
toolkit will not warn you, when you forget it but the translation 
mechanism will not work!

The first argument is the so-called *textdomain*.  This is the
identifier for your message catalogs and also the basename of several
files.  In the example above, the translated message catalog would
be searched as *`LOCALEDIR`*`/fr/LC_MESSAGES/com.mydomain.www.mo`. The second parameter is the language.  This will normally come from
a variable instead of a hard-coded string.

A possible third argument (omitted in the example) is the character
set to use, all following arguments are additional directories to
search first for translations.

The default list of directories is:

* `./locale`
* `/usr/share/locale`
* `/usr/local/share/locale`

The directory `./locale` is relative to the current working directory
from where you invoke the template processor.

#### Simple Translations With `gettext()`

The simplest and most common way of doing things is:

```html
    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    <title>[% gtx.gettext("World Of Themes") %]</title>
    
    <h1>[% "Introduction" | gettext %]

    <p>
    [% FILTER gettext %]
    The "World Of Themes" is the ultimate source of templates
    for the Template Toolkit.
    [% END %]
    </p>
```

This shows three different ways of localizing strings.  You can
use the function `gtx.gettext()`, the filter `gettext` with pipe
syntax, or the same filter with block syntax.  The result is always
the same.  The string will be recognized as translatable by 
`xgettext-tt2` and it will be translated into the selected language,
when rendering the template.

#### Interpolating Strings Into Translations

One important thing to understand is that the argument to the
gettext functions or filters is the lookup key into the translation
database, when the template gets rendered.  That implies that this
key has to be invariable and must not use any interpolated variables.

```html
    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    [% gtx.gettext("Hello, $firstname $lastname!") %]
```

This template code is syntactically correct and will also render
correctly.  But `xgettext-tt2` will bail out on it with an error
message like

    templates.html:3: Illegal variable interpolation at "$"

The function `gettext()` will receive the interpolated string
as its argument, and that is not the same as the string that
the extractor program `xgettext-tt2` sees.  And that means that
the translation cannot be found.

The correct way to interpolate strings uses `xgettext()`:

```html
    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    [% gtx.xgettext("Hello, {first} {last}!",
                    first => firstname, last => lastname) %]
    [% "Hello, {first} {last}!" | xgettext(first => firstname, 
                                           last => lastname) %]
    [% FILTER xgettext(first => firstname, last => lastname) %]
    Hello, {first} {last}!
    [% END %]
```

One additional benefit of this is that the extractor program
`xgettext-tt2` will also mark these strings with the flag
"perl-brace-format".  When the translation from the `.po`
file gets compiled into an `.mo` file, the compiler `msgfmt`
checks that the translated strings contains exactly the same
placeholders as the original.

One thing that you should also avoid is to assemble strings
in the template source code.  Do *not*:

```html
    [% gtx.gettext("Please contact") %] [% name %]
    [% gtx.gettext("for help about the") %] [% package %]
    [% gtx.gettext("software.") %]
```

This will result in three translatable text snippets
"Please contact", "for help about the", and "software." that
are hard to translate without context.  Besides it makes
illegal assumptions about the word order in translated sentences.
Instead, use `xgettext()` and write in complete sentences with
placeholders.

By the way, the `x` in the function `xgettext()` stands for *eXpand*
while the `x` in the program `xgettext-tt2` or GNU Gettext's
`xgettext` program stands for *eXtract*.

#### Plural Forms

Do *not* write this:

```html
    [% IF num != 1 %]
    [% gtx.xgettext("{number} documents deleted!", number => num) %]
    [% ELSE %]
    [% gtx.gettext("One document deleted!") %]
    [% END %]
```

This assumes that every language has one singular and one plural
(and no other forms) and that the condition that selects the correct
form is always `COUNT != 1`.  But this is wrong for many languages
for example Russian (two plural forms), Chinese (no plural), French
(different condition), and many more.

Write instead:

```html
    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    [% gtx.nxgettext("One document deleted.", 
                     "{count} documents deleted."
                     num,
                     count => num) %]
```

The function `nxgettext()` receives the singular and plural
form as the first and second argument, followed by the number
of items, followed by an arbitrary number of key/value pairs
for interpolating variables in the strings.

There is also a function `ngettext()` that does not expand
its first two arguments.  You will find out that you almost
never need that function.

You can also use `nxgettext()` and `ngettext()` as filters.
But the necessary code is awkward, and their use is therefore
not recommended.

#### Ambiguous Strings (message contexts)

Sometimes an English string has different meanings in other
languages:

```html
    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    [% gtx.gettext("State:") %]
    [% IF state == '1' %]
    [% gtx.pgettext("state", "Open") %]
    [% ELSE %]
    [% gtx.gettext("Closed") %]
    [% END %]
    <a href="/action/open">[% gtx.pgettext("action", "Open") %]</a>
```

The function `pgettext()` works like gettext but has one 
extra argument preceding the string, the so-called
message context.  The string extractor `xgettext-tt2` will now
create two distinct messages "Open", one with the context "state",
the other one with the context "action".  The sole purpose of this
context is to disambiguate the string "Open" for languages where the
verb ("to open") and the adjective ("the door is *open*") has
two distinct translations.

You will normally use this function, when a translator asks you
to do so, but not on your own behalf.

There is also a function `pxgettext()` that supports placeholder
interpolation, and `npxgettext()` that has the following semantics:

```perl
    npxgettext(CONTEXT, SINGULAR, PLURAL, COUNT,
               KEY1 => VALUE1, KEY2 => VALUE2, ...)
```

#### More Esoteric Functions

The [API documentation](lib/Template/Plugin/Gettext.pod#user-content-FUNCTIONS) contains
some more functions and filters that are available for completeness.
You will never need them in normal projects.

#### Translator Hints

You can add comments to the source code that are copied into the
`.po` file as hints for the translators.  This will look like
this:

```html
    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    <!-- TRANSLATORS: This is the day of the week! -->
    [% gtx.gettext("Sun") %]
```

In order to make that work, you have to invoke the extractor
program `xgettext-tt2` like this:

    xgettext-tt2 --add-comments=TRANSLATORS: t1.html t2.html ...

#### Modifying Flags

In rare situations, you may need the following:

```html
    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    <!-- xgettext:no-perl-brace-format -->
    [% gtx.xgettext("Value: {value}", value => whatever) %]
```

Normally, the argument of `xgettext()` will be flagged in
the `.po` file with "perl-brace-format", and a translation
will fail to compile if the translation does not contain exactly
the same placeholders as the original does.

You can override that default behavior for individual messages
by placing a comment containing the string "xgettext:" directly
in front of the string.

### Translation Workflow

The translation workflow is the standard workflow known from GNU 
Gettext.  All files relevant for translations are conventionally
kept in a subdirectory `po`.

You can save time if you use the seed project
[Template-Plugin-Gettext-Seed](https://github.com/gflohr/Template-Plugin-Gettext-Seed)
as a base.  It contains a directory `po` ready for use,
with --- at your choice --- a Makefile or a script `po-make.pl`
that automates the entire translation workflow.  It is also
prepared for extracting strings from other sources than
template files.  In that example, these are Perl source files,
but it will work in a similar fashion for other programming
languages.

But rolling your own version is also simple.  Just read on.

#### Extracting Strings With `xgettext-tt2`

Extracting translatable strings from templates for the Template
Toolkit 2 is as easy as:

```shell
   $ xgettext-tt2 TEMPLATE....
```

This will scan all files given as arguments for translatable strings
and create a file `messages.po` with the strings found.

The normal invocation of `xgettext-tt2` is normally a little bit more
sophisticated:

```shell
$ xgettext-tt2 --files-from=POTFILES \
    --output=com.mydomain.www.pot \
    --add-comments=TRANSLATORS: --from-code=utf-8 \
    --force-po
```

You can, of course, write everyting in one line and omit the backslashes.

Specifying all input files as arguments on the command-line can
quickly become unwieldy.  It is more common to put the list of input
files into a text file, each input file on one line, and instruct
`xgettext-tt2` to read it with the option `--files-from`.  The name
of the file is by convention `POTFILES`.

The output file is normally a file `TEXTDOMAIN.pot`, where 
`TEXTDOMAION` is the identifier selected in the templates.  The
reverse hostname of the server serving the rendered templates
is a good choice.

If you want to be able to give hints to translators in the source
files, you have to specify the trigger string --- normally
"TRANSLATORS:" --- with the option `--add-comments`.  Specifying
an empty string (`--add-comments=''`) instructs `xgettext-tt2` 
to copy all comments into the `.pot` file.

If your templates contain characters outside of US-ASCII, you should
specify the character set of the template files with the option
`--from-code=CODESET`.

The option `--force-po` instructs `xgettext-tt2` to write an output
file even if no translatable strings had been found.  But this
is a matter of taste.  Omit the option, if you prefer it.

`xgettext-tt2` has a lot more options.  They are mostly compatible
with the ones of `xgettext` from GNU gettext for C, Perl, and
a lot more languages.  See the [documentation for GNU Gettext's
xgettext](https://www.gnu.org/software/gettext/manual/html_node/xgettext-Invocation.html)
and the documentation for [Locale::XGettext](https://github.com/gflohr/Locale-XGettext/blob/master/lib/Locale/XGettext.pod)
for more information.

By the way, why is the ouput file a `.pot` file and not a `.po`
file?  It is the *template* for the `.po` files for the individual
languages.  You never edit that file, but re-generate it, whenever
the source files have changed.  Hence, it only contains strings
in the original, in the base language.

#### Creating Translation Files

For each supported language (except for the base language) you
should create a file `LL.po`, where `LL` is the two-letter
language code for that language, for example `fr.po`, `de.po`,
or `it.po`.  You can also specify the combination of language
and country like in `de_DE.po` or `pt_BR.po`.

One option for that is to simply copy the `.pot` file and
edit the header accordingly.  It is normally easier to do that
with the program `msginit`:

```
$ msginit --input=com.mydomain.www.pot --locale=fr
```

Replace `TEXTDOMAIN.pot` with the name of the `.pot` file, and
`fr` with the language in question.  This will prefill a lot
of fields in the `.po` file.

#### Compiling Translation Files

The translated `.po` files are compiled with the program `msgfmt`:

```shell
$ msgfmt --check --statistics --verbose -o fr.mo fr.po
fr.po: 212 translated messages, 1 fuzzy translation, 3 untranslated messages.
```

This will compile the translation file `fr.po` into a binary
file `fr.mo`.  It also checks the translations for formal errors
and print statistics about the number of translated and
untranslated strings.

#### Installing Translation Files

The plugin does not use `.po` files for looking up translations
but the binary `.mo` files.  But it has to find them.

You have to decide for one of the directories that 
`Template::Plugin::Gettext` searches for translations.  The
default order is:

* `@INC/LocaleData`
* `/usr/share/locale`
* `/usr/local/share/locale`

The first line means that every directory `LocaleDir` inside
Perl's include directories is searched for translation files.
Keep in mind, that for security reasons the current directory
(`.`) is nowadays often *not* in Perl's `@INC`.

Let's assume that `/var/www/lib` is in Perl's @INC.  You would
then install the French translation file `fr.mo` as `/var/www/lib/LocaleData/fr/LC_MESSAGES/com.mydomain.www.mo`.
`TEXTDOMAIN` is a placeholder for the textdomain you have
selected (and `LC_MESSAGES` is *not* a placeholder but a real 
directory name).

That is good except for the fact that `/var/www/lib` is usually
not in Perl's `@INC`.  But you can change that where you invoke
the template processor:

```perl
BEGIN {
    unshift @INC, '/var/www/lib';
}

use Template;

Template->new->process('template.html', $data);
```

You can completely override the default search order in the
templates:

```html
[% USE gtx = Gettext('com.mydomain.www', lang, 'utf-8', 
                     '/var/www/locale', '/srv/www/locale')]
```

Now, the French translation would be searched in 
`/var/www/locale/fr/LC_MESSAGES/com.mydomain.www.mo` and 
`/var/www/locale/fr/LC_MESSAGES/com.mydomain.www.mo`.

#### Updating Translation Files

Translations may become obsolete, when the source templates
change.  In this case, you have to merge the new set of 
translatable strings into the existing translation files.
Fortunately, GNU Gettext makes this easy:

```shell
$ xgettext-tt2 --files-from=POTFILES \
    --output=com.mydomain.www.pot \
    --add-comments=TRANSLATORS: --from-code=utf-8 \
    --force-po
$ cp fr.po fr.old.po
$ msgmerge fr.old.po com.mydomain.www.pot -o fr.po
....... done
```

You first update the `.pot` file with `xgettext-tt2` so that it
contains the current set of translatable strings.  You then
make a backup of each `.po` file and then invoke the program
`msgmerge` for merging the current translations from `fr.old.po`
with the new set of strings from `com.mydomain.www.pot` into
the updated translation file `fr.po`.

The file `fr.po` will now contain the new strings as untranslated
entries.  Strings that have only slightly change will retain their
translations but they will be marked as "fuzzy", so that they
can be reviewed by a translator.  Entries for strings that are
no longer present in the sources are obsoleted.

#### Integrating With Other Programming Languages

The GNU Gettext framework is available for a lot of programming
languages and it is not uncommon that two or more of these 
languages are mixed in a project.  It is beneficial in these
cases to use a common translation base for all used 
technologies.

`xgettext-tt2` is based on [`Locale-XGettext`](https://github.com/gflohr/Locale-XGettext)
and therefore not only understands Template Toolkit templates
but also `.po` and `.pot` files as input.  GNU Gettext's xgettext
has the same feature.

Accumulating all translatable strings from the different
technologies is therefore very easy.  If you have a project
that uses Template Toolkit for rendering web pages and Perl
for the business logic you first extract strings from your 
Perl files --- as usual --- with `xgettext` from GNU gettext
into a temporary file, for example `plfiles.pot`.  Then you
extract the strings from the templates with `xgettext-tt2` 
from this library, but you specify `plfiles.pot` as an 
additional input file. And now the output file of `xgettext-tt2`
contains all the strings from the template files *plus* those
from the Perl files in `plfiles.pot`.

Of course, you can also do it the other way round, extract
with `xgettext-tt2` into `ttfiles.pot`, and then feed that as
an additional input file to GNU Gettext's `xgettext`.

You can use the seed project [Template-Plugin-Gettext-Seed](https://github.com/gflohr/Template-Plugin-Gettext-Seed)
as a fully functional starting point for such setups.

## Bugs

Please report bugs at [https://github.com/gflohr/Template-Plugin-Gettext/issues](https://github.com/gflohr/Template-Plugin-Gettext/issues)

## Author

Template-Plugin-Gettext was written by [Guido Flohr](http://www.guido-flohr.net/).
