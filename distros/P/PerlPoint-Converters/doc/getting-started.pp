
+PP:PerlPoint

+BC:\B<\C<__body__>>


=Introduction

Welcome to the world of \PP. Efforts were made to make your stay as comfortable as possible. Depending on your travel experience, several things might look hard, unusual or rough at very first sight, but don't hesitate to come in and look around. You might discover new promising areas and tell your travel stories another way then.

First, make sure you have the software installed. For these first steps, you need \BC<perl> (5.00503 or above), \BC<\PP::Package> and \BC<\PP::Converters> from CPAN. Install them in the mentioned order, according to the attached instructions (please do not remove the installation directory of \C<\PP::Converters>). Additionally, you need a text editor and a Web browser.

\PP is both a presentation and a documentation toolset. More precise, its a toolset to \I<generate> presentations and documentations. You will write a \I<simple text> and start a \I<converter> to make the final documents from this source. \I<The final format is your choice>, depending on the used converter. So you can make a presentation, speaker notes, handouts, an internet documentation and a brochure all from the same text source, but looking very individual.

Because of this two step architecture \PP authors deal both with the text format and several converters. The text source describes \I<structure> and \I<contents> of your document, while a converter adds \I<layout>. Let's start.

=A First Slide

Open a new text document. Let's communicate the office way of drinking coffee. The first draft may look like this:

  * Come when you are thirsty.

  * Make new coffee if the pot is empty.

  * Fill your cup (regardless of size).

  * Insert 0,50 into the box.

This looks perfect - four points to state out. Start a point by a \C<*> character at the left margin, and complete it by an empty line. If it contains a lot of text, simply continue on the next line at any position like in 

  * Fill your cup
    (regardless of size).

The lines will be automatically combined correctly until the documents end or an empty line follows. The whole thing is called a "paragraph". Paragraphs are a base principle of \PP.

=Adding Headlines

OK, well - we are almost done with our first sheet. We are only missing a headline. "Enjoy office coffee" might be chosen. We add it to the points.

  =Enjoy office coffee

  * Come when you are thirsty.

  * Make new coffee if the pot is empty.

  * Fill your cup (regardless of size).

  * Insert 0,50 into the box.

Note that the headline looks very similar to the points - it's a paragraph as well. The \I<startup character> makes the difference - each paragraph type has its own. Headlines begin with a \C<=>.

=Creating Slides

It's time now to make our source a document. HTML can be displayed everywhere, so we choose the converter \BC<pp2html> which converts \PP sources into HTML pages. As mentioned before, the converter adds layout. HTML layouts can be configured very fine grained by the various options of \C<pp2html>, or one can use predeclared layouts called "styles". Luckily, \C<pp2html> comes with several example styles, so we take one of those.

Please remember where you installed \C<\PP::Converters> from (the directory where you called \C<make install>). Let's say it is stored in the environment variable \C<$PPCPATH>. Please ask your administrator for assistance if necessary.

Assumed the text source was stored in \C<coffee.pp>, you can call \C<pp2html> the following way now:

  pp2html -style_dir $PPCPATH/pp2html_styles -style orange_slides coffee.pp

Several files are made just where you are. To look at the result, open \C<frame_set.html> in a Web browser.

If you want to try another layout, try

  pp2html -style_dir $PPCPATH/pp2html_styles -style \B<big_blue> coffee.pp

and open \C<slide0001.htm>. Notice that with these layouts, a list of contents and navigation elements were automatically added for you, so that a presenter can easily switch between pages.

=More Slides

But right now, there's only one page. So back to the source, let's add statistics. Append the following to your source:

  =Statistics

  We counted our coffee material needs over half a year.
  Surprisingly, we consume almost as much milk as coffee!
  We need

  # 50% coffee

  # 40% milk

  # 10% sugar
  

The first paragraph is another headline, opening a new chapter. The next paragraph is of a new type - this is a \I<text> paragraph. For convenience, it needs no special startup character. So you can start writing text without thinking of rules. The paragraph ends with an empty line as usual.

The following list consists of paragraphs starting with a \C<#>. What's that? The \C<#> symbolizes a number, and these paragraphs are made points of an \I<ordered list>. They will be replaced by the correct numbers automatically. Store the source, rerun \C<pp2html> and look at the results!

  pp2html -style_dir $PPCPATH/pp2html_styles -style orange_slides coffee.pp

The new chapter is made a new slide, and the ordered list contains numbers.

=Read On

OK, well done! You are now familiar with the base process of \PP working. But there are several more things to discover, including tags, image inclusion, source nesting and on the fly source generation. And there are several more formats to convert sources into, currently including LaTeX, SDF, POD and Clinton Pierce's Perl Projector. Further processing (by additional utilities) provides formatted text, manual pages, PostScript, PDF and more. Read on in the tutorial which will explain these features in detail.
