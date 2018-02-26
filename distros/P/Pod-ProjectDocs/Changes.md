## 0.51 2018-02-20
- Allow regexp objects to be passed as value for 'except', thanks to Erik Huelsmann.

## 0.50 2018-01-09
- Added `-nosourcecode` option to suppress inclusion of the original sources.

## 0.49 2017-09-20
- Switch to metacpan for external perldoc links.
- Ported to Moose.

## 0.48 2017-04-25
- Rewrite of the Parser to use Pod::Simple::XHTML internally instead of legacy Pod::Parser. This fixes some issues with linking and adds proper encoding support based on the Pod command `=encoding`.
- Therefore the `-charset` parameter was removed. Pod sources are correctly processed as described by the specification, all output files are generated as UTF-8.
- Support for function source code embedding was removed in order to focus on proper Pod rendering instead.
- Fixed support for Perl 5.8 and 5.10 that was missing in 0.45.

## 0.45 2016-11-17
- Fixed: 0.44 removes empty lines in verbatim sections (#1).

## 0.44 2016-11-12
- Removed support for JavaScript Pod. www.openjsan.org is dead since 2011 and JavaScript has its own specialized documentation format, JSDOC.
- Use '::' as path separator for Perl Modules and '/' otherwise, instead of '-' (github issue#1).

## 0.43 2016-11-08
- Properly handle UTF-8 input files by applying the -charset param also when parsing source files.
- Fixed handling of character escape sequences (RT#25123).
- Removed support for broken distribution Syntax::Highlight::Universal.
- Improved POD wording for this distribution. ;)

## 0.42 2016-11-07
- Fixed race condition on parallel test execution (RT#105374).
- Fixed method source code being shown in wrong modules (RT#69545).
- Improved verbatim block output to not add tralining lines (RT#15052).
- Fixed: don't use replace markers that might conflict with other software such as Perl::Critic (RT#35478).

## 0.41 2016-11-07
- Fixed JSON output to generate stable structures that can be added to version control
  systems without changing all the time.
- Generate Perl package documentation with proper :: separators in package name.
- Ignore files which don't contain POD.
- Correctly skip content in data sections (between =begin and =end).

## 0.40 Tue Oct 26 02:54:00 2010
- removed auto_install from Makefile.PM. Thanks to tokuhirom.
  https://github.com/lyokato/p5-pod-projectdocs/pull/2

## 0.39 Tue Oct 26 02:54:00 2010
- updated for windows compatibility. Thanks to wchristian
  http://github.com/lyokato/p5-pod-projectdocs/pull/1

## 0.38 Thr Mar 11 01:20:00 2010
- fixed pod2projdocs typo
  Thanks to Tokuhiro Matsuno and Naoki Tomita

## 0.36 Wed May 14 10:20:00 2008
- $json->objToJson => $json->encode
  objToJson prints deprecated warnings.
  Thanks to tokuhirom.

## 0.35 Fri Jan 18 18:10:00 2008
- removed $json->autoconv(0) because JSON doesn't have autoconv method from version 2.
		  RT#32408, 32409

## 0.34 Sat Oct 27 21:56:00 2007
- Fixed pod2projdocs bug.
  Added METHOD_REGEXP, now you can control pattern that the parser consider as method.
  Thanks to Ktat.

## 0.33 Mon Oct 15 01:55:00 2007
- Fixed document of pod2projdocs - added description for forcegen option.
  Now it shows it's usage when excused without any option.
  Applyed a patch that makes JSON's autoconvert functionality off.
  Thanks to Ktat.

## 0.31 Mon Jan 29 12:00:00 2007
- Changed to use Module::Install for instllation,
  and made dependency on Syntax::Highlight::Universal optional.

## 0.30 Tue Jan 09 12:00:00 2007
- applyed a great patch from Ankur Gupta.
  Now you can see syntax highlighten source code below the document for each methods.
  When the parser finds format like "=head2 method_name", it appends source code block
  on HTML. Click the anchor "[Source]", and it toggles the source code block.

## 0.26 Tue Jul 11 02:00:00 2006
- added 'except' parameter,
  Thanks to Nadim.

## 0.22 Tue Dec 11 02:00:00 2005
- now generated files are strict xhtml.

## 0.21 Tue Sep 27 13:00:00 2005
- added function highlighting matched word

## 0.20 Tue Sep 27 12:00:00 2005
- fixed test script

## 0.19 Tue Sep 27 02:00:00 2005
- fixed some bug
- added search box to index page
  reported by Nadim

## 0.18 Tue Sep 13 22:33:00 2005
- fixed _htmlEscape in parser to prevent to put out not intended results
  with double html-escaping
  reported by Tatsuhiko Miyagawa

## 0.17 Sun Sep 4 00:07:00 2005
^    - fixed MANIFEST

## 0.16 Sun Sep 4 00:07:00 2005
- fixed Makefile.PL

## 0.15 Sat Sep 3 22:04:00 2005
- added option 'forcegen'
- fixed parser, now it creates link for L<foo> properly.
  patched by Tatsuhiko Miyagawa.

## 0.14 Sat Sep 3 11:56:00 2005
- fixed mismapping in Pod::ProjectDocs::Parser
  found by Tatsuhiko Miyagawa.

## 0.13  Sat Aug 27 14:00:00 2005
- fixed Makefile.PL, to remove bug appears in old version of Pod::Parser.
  Reported by Tatsuhiko Miyagawa.

## 0.12  Fri Aug 26 23:00:00 2005
- add footer

## 0.11  Fri Aug 26 22:00:00 2005
- fixed bug in DocManager

## 0.1   Fri Aug 26 02:00:00 2005
- fixed bug that doesn't create 'src' directory.
- fixed parser html-building-process little bit.
- fixed bug by typo in DocManager
- add manager for trigger-scripts ('.cgi', '.pl' files)

## 0.09  Sat Aug 20 02:00:00 2005
- fixed problem about namespace confliction between '.pm' and '.js'.

## 0.08  Fri Aug 19 12:00:00 2005
- fixed not to use Pod::Xhtml.
- add manager for javascript libraries.

## 0.07  Thu Aug 18 23:00:00 2005
- add link to source file.
- fixed to check last modified time.

## 0.06  Thu Aug 18 18:00:00 2005
- fixed to handle multiple 'libroot' by patch from Tatsuhiko Miyagawa.

## 0.05  Fri Jun 24 18:00:00 2005
- fixed bug.
    now you can set relative path for -lib and -out options.

## 0.02  Sat Jun 18 18:00:00 2005
- CPAN release version;

## 0.01  Thu Jun 16 16:52:20 2005
- original version; created by h2xs 1.23 with options
    -X -A Pod::ProjectDocs
