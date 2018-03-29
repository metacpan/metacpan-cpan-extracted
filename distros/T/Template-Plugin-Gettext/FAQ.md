# Frequently Asked Questions

Well, not all of them are frequently asked but rather just interesting.

## Why Do Template Syntax Errors Go Through Unnoticed

The message extractor `xgettext-tt2` is not a syntax checker for template
files.  It just understands enough of Template Toolkit's syntax to extract
translatable strings from templates according to the options you have
invoked it with.

See https://github.com/gflohr/Template-Plugin-Gettext/issues/2 for
more aspects.

## Can I Use `xgettext-tt2` For [Log::Report::Template](http://search.cpan.org/~markov/Log-Report-Template/)?

Yes, like this:

```shell
xgettext-tt2 --plug-in --keyword --keyword=loc --flag=loc:1:perl-brace-format --add-comments=TRANSLATORS: --from-code=utf-8 TEMPLATEFILE...
```

Using the option `--plug-in` without an argument has the
effect that `xgettext-tt2` will recognize template functions
in the root namespace.

Extracting strings for `Log::Report::Template` with `xgettext-tt2` has a number of advantages:

* easier integration into build processes
* correct flags for extracted messages
* translator comments
* all boiler-plate options from [Locale::XGettext](http://search.cpan.org/~guido/Locale-XGettext/) like `--msgid-bugs-address`, `--from-code`, etc.

You need at least version `xgettext-tt2` version 0.5 (contained in Locale-XGettext-TT2 version 0.5) for extracting strings from functions in the root namespace.