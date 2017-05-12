
+PP:PerlPoint

+IB:\I<\B<__body__>>

+IC:\I<\C<__body__>>

+BC:\B<\C<__body__>>

+IX:\I<\X<__body__>>

+BX:\B<\X<__body__>>

+CX:\C<\X<__body__>>

+BCX:\B<\C<\X<__body__>>>

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

The \X<target format> can be almost everything. There's no \X<restriction> to \X<formats> used by \I<presentation software>. Documents can be presented in many ways: on a wall, on screen, or printed, in the Web or intranet - and there are many formats out there meeting many special needs. Think of the \PP converters already there: they address \IX<HTML> (for browser presentations, online documentations, training materials, ...), \IX<PPresenter> (for traditional presentations), \IX<LaTex> (for high quality prints) as well as \IX<XML> and \IX<SDF> (as intermediate formats to generate \X<PDF>, \X<PostScript>, \X<POD>, \X<text> and more easily). \IB<Once you know the target format, you can write a \PP converter to it.>

There are two ways to write a converter using the \PP framework. First, the \IX<traditional> way, which is \X<stream oriented> and deals with \X<stream events>. In this model, there's a converter program for \I<each> target format.

The second model is more abstract. Based on the experience with traditional converters, it hides much more of the internals, provides more base features and allows to deal with \IX<structural> entities like paragraphs, tables etc. There is \I<one> converter for all formats, configured by \I<modules> which are loaded automatically, depending on the format. The modules are organized in an inheritance chain, allowing to write new converters on base of existing ones. This is the \IX<formatter> model.

If you are new to \PP converters, I strongly recommend to use the formatter approach. The traditional approach is still working (in fact the formatter model is based on it), but it is harder to deal with.

\LOCALTOC{type=linked}


=The traditional approach

\INCLUDE{type=pp file="writing-converters-traditional.pp" headlinebase=CURRENT_LEVEL}

=The formatter approach

\INCLUDE{type=pp file="writing-converters-formatters.pp" headlinebase=CURRENT_LEVEL}

=Appendix

\INCLUDE{type=pp file="writing-converters-appendix.pp" headlinebase=CURRENT_LEVEL}

=Index

\INDEX

