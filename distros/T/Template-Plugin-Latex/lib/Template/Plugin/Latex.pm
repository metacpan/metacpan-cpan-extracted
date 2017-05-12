#============================================================= -*-perl-*-
#
# Template::Plugin::Latex
#
# $Id:$
#
# DESCRIPTION
#   Template Toolkit plugin for Latex
#
# AUTHOR
#   Chris Travers  <chris.travers@gmail.com> (Current Maintainer)
#   Andrew Ford    <a.ford@ford-mason.co.uk>
#   Andy Wardley   <abw@wardley.org>
#
# COPYRIGHT
#   Copyright (C) 2014-2016 Chris Travers. All Rights Reserved.
#   Copyright (C) 2006-2014 Andrew Ford.   All Rights Reserved.
#   Copyright (C) 1996-2006 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# HISTORY
#   * Originally written by Craig Barratt, Apr 28 2001.
#   * Win32 additions by Richard Tietjen.
#   * Extracted into a separate Template::Plugin::Latex module by
#     Andy Wardley, 27 May 2006
#   * Removed the program pathname options on the FILTER call
#     Andrew Ford, 05 June 2006
#   * Totally rewritten by Andrew Ford September 2007
#   * Version 3.00 released March 2009
#
#========================================================================

package Template::Plugin::Latex;

use strict;
use warnings;
use base 'Template::Plugin';

use File::Spec;
use LaTeX::Driver 0.07;
use LaTeX::Encode;
use LaTeX::Table;


our $VERSION = '3.11';           # Update "=head1 VERSION" below!!!!
our $DEBUG; $DEBUG = 0 unless defined $DEBUG;
our $ERROR   = '';
our $FILTER  = 'latex';
our $THROW   = 'latex';        # exception type

#------------------------------------------------------------------------
# constructor
#
#------------------------------------------------------------------------

sub new {
    my ($class, $context, $options) = @_;

    # make sure that $options is a hash ref
    $options ||= {};

    # create a closure to generate filters with additional options
    my $filter_factory = sub {
        my $factory_context = shift;
        my $filter_opts = ref $_[-1] eq 'HASH' ? pop : { };
        my $filter_args = [ @_ ];
        $filter_opts->{$_} //= $options->{$_} for keys %$options;
        return sub {
            # Template::Plugin::Latex::_filter->run($context, $filter_opts, $filter_args, @_);
            _tt_latex_filter($class, $factory_context, $filter_opts, $filter_args, @_);
        };
    };

    # create a closure to generate filters with additional options
    my $encode_filter_factory = sub {
        my $factory_context = shift;
        my $filter_opts = ref $_[-1] eq 'HASH' ? pop : { };
        my $filter_args = [ @_ ];
        $filter_opts->{$_} //= $options->{$_} for keys %$options;
        return sub {
            # Template::Plugin::Latex::_filter->run($context, $filter_opts, $filter_args, @_);
            _tt_latex_encode_filter($class, $factory_context, $filter_opts, $filter_args, @_);
        };
    };

    # and a closure to represent the plugin
    my $plugin = sub {
        my $plugopt = ref $_[-1] eq 'HASH' ? pop : { };
        $plugopt->{$_} //= $options->{$_} for keys %$options;
        # Template::Plugin::Latex::_filter->run($context, $plugopt, @_ );
        _tt_latex_filter($class, $context, $plugopt, {}, @_ );
    };


    # now define the filter and return the plugin
    $context->define_filter('latex_encode', [ $encode_filter_factory => 1 ]);
    $context->define_filter($options->{filter} || $FILTER, [ $filter_factory => 1 ]);

    return bless $plugin, $class;
}


#------------------------------------------------------------------------
# _tt_latex_encode_filter
#
#
#------------------------------------------------------------------------

sub _tt_latex_encode_filter {
    my ($class, $context, $options, $filter_args, @text) = @_;
    my $text = join('', @text);
    return latex_encode($text, %{$options});
}


#------------------------------------------------------------------------
# _tt_latex_filter
#
#
#------------------------------------------------------------------------

sub _tt_latex_filter {
    my ($class, $context, $options, $filter_args, @text) = @_;
    my $text = join('', @text);

    # Get the output and format options

#    my $output = $options->{output};
    my $output = delete $options->{ output } || shift(@$filter_args) || '';
    my $format = $options->{format};

    # If the output is just a format specifier then set the format to
    # that and undef the output

    if ($output =~ /^ (?: dvi | ps | pdf(?:\(\w+\))? ) $/x) {
        ($format, $output) = ($output, undef);
    }

    # If the output is a filename then convert to a full pathname in
    # the OUTPUT_PATH directory, outherwise set the output to a
    # reference to a temporary variable.

    if ($output) {
        my $path = $context->config->{ OUTPUT_PATH }
            or $class->_throw('OUTPUT_PATH is not set');
        $output = File::Spec->catfile($path, $output);
    }
    else {
        my $temp;
        $output = \$temp;
    }

    # Run the formatter

    eval {
        my $drv = LaTeX::Driver->new( source    => \$text,
                                      output    => $output,
                                      format    => $format,
                                      maxruns   => $options->{maxruns},
                                      extraruns => $options->{extraruns},
                                      texinputs => _setup_texinput_paths($context),
                                    );
        $drv->run;
    };
    if (my $e = LaTeX::Driver::Exception->caught()) {
        $class->_throw("$e");
    }

    # Return the text if it was output to a scalar variable, otherwise
    # return nothing.

    return ref $output ? $$output : '';
}


#------------------------------------------------------------------------
# $self->setup_texinput_paths
#
# setup the TEXINPUT path environment variables
#------------------------------------------------------------------------

sub _setup_texinput_paths {
    my ($context) = @_;
    my $template_name = $context->stash->get('template.name');
    my $include_path = [];

    # Ask each Template::Provider object for a list of paths. This properly
    # handles coderefs and objects in INCLUDE_PATH.
    for my $provider (@{ $context->{LOAD_TEMPLATES} }) {
        push @$include_path, @{ $provider->paths || [] };
    }

    my @texinput_paths = ("");
    foreach my $path (@$include_path) {
        my $template_path = File::Spec->catfile($path, $template_name);
        if (-f $template_path) {
            my($volume, $dir) = File::Spec->splitpath($template_path);
            $dir = File::Spec->catfile($volume, $dir);
            unshift @texinput_paths, $dir;
            next if $dir eq $path;
        }
        push @texinput_paths, $path;
    }
    return  \@texinput_paths;
}


sub _throw {
    my $self = shift;
    die Template::Exception->new( $THROW => join('', @_) );
}


sub table {
    my $args  = ref($_[-1]) eq 'HASH' ? pop(@_) : { };
    my ($table, $text);
    eval {
        $table = LaTeX::Table->new($args);
        $text  = $table->generate_string;
    };
    if ($@) {
        die Template::Exception->new( $THROW => $@ );
    }
    return $text;
}


1;

__END__

=head1 NAME

Template::Plugin::Latex - Template Toolkit plugin for Latex

=head1 VERSION

This documentation refers to C<Template::Plugin::Latex> version 3.11

=head1 SYNOPSIS

Sample Template Toolkit code:

    [%- USE Latex;

        mystr = "a, b & c" | latex_encode;

        FILTER latex("pdf");  -%]

    \documentclass{article}
    \begin{document}
      This is a PDF document generated by
      LaTeX and the Template Toolkit, with some
      interpolated data: [% mystr %]
    \end{document}

    [%  END; -%]


=head1 DESCRIPTION

The C<Latex> Template Toolkit plugin provides a C<latex> filter that
allows the use of LaTeX to generate PDF, PostScript and DVI output files
from the Template Toolkit.  The plugin uses L<LaTeX::Driver> to run the
various LaTeX programs.

Processing of the LaTeX document takes place in a temporary directory
that is deleted once processing is complete.  The standard LaTeX
programs (C<latex> or C<pdflatex>, C<bibtex> and C<makeindex>) are run
and re-run as necessary until all references, indexes, bibliographies,
table of contents, and lists of figures and tables are stable or it is
apparent that they will not stabilize.  The format converters C<dvips>,
C<dvipdf>, C<ps2pdf> and C<pdf2ps> are run as necessary to convert the
output document to the requested format.  The C<TEXINPUTS> environment
variable is set up to include the template directory and the C<INCLUDES>
directories, so that LaTeX file inclusion commands should find the
intended files.

The output of the filter is binary data (although PDF and PostScript are
not stictly binary).  You should be careful not to prepend or append any
extraneous characters (even space characters) or text outside the FILTER
block as this text will be included in the file output.  Notice in the
example below how we use the post-chomp flags ('-') at the end of the
C<USE> and C<END> directives to remove the trailing newline characters:

    [% USE Latex(format='pdf') -%]
    [% FILTER latex %]
    ...LaTeX document...
    [% END -%]

If you're redirecting the output to a file via the third argument of
the Template module's C<process()> method then you should also pass
the C<binmode> parameter, set to a true value to indicate that it is a
binary file.

    use Template;

    my $tt = Template->new({
        INCLUDE_PATH => '/path/to/templates',
        OUTPUT_PATH  => '/path/to/pdf/output',
    });
    my $vars = {
        title => 'Hello World',
    }
    $tt->process('example.tt2', $vars, 'example.pdf', binmode => 1)
        || die $tt->error();

If you want to capture the output to a template variable, you can do
so like this:

    [% output = FILTER latex %]
    ...LaTeX document...
    [% END %]

You can pass additional arguments when you invoke the filter, for
example to specify the output format.

    [% FILTER latex(format='pdf') -%]
       ...LaTeX document...
    [% END %]

If you want to write the output to a file then you can specify an
C<output> parameter.

    [% FILTER latex(output='example.pdf') %]
    ...LaTeX document...
    [% END %]

If you don't explicitly specify an output format then the filename
extension (e.g. 'pdf' in the above example) will be used to determine
the correct format.

You can specify a different filter name using the C<filter> parameter.

    [% USE Latex(filter='pdf') -%]
    [% FILTER pdf %]
    ...LaTeX document...
    [% END %]

You can also specify the default output format.  This value can be
C<latex>, C<pdf> or C<dvi>.

    [% USE Latex(format='pdf') %]


Note: the C<LaTeX::Driver> distribution includes three filter programs
(C<latex2dvi>, C<latex2pdf> and C<latex2ps>) that use the
C<LaTeX::Driver> package to process LaTeX source data into DVI, PDF or
PostScript file respectively.  These programs have a C<-tt2> option to
run their input through the Template Toolkit before processing as LaTeX
source.  The programs do not use the C<Latex> plugin unless the template
requests it, but they may provide an alternative way of processing
Template Toolkit templates to generate typeset output.


=head1 SUBROUTINES/METHODS

=head2 C<USE Latex(options)>

This statement loads the plugin (note that prior to version 2.15 the
filter was built in to Template Toolkit so this statement was
unnecessary; it is now required).


=head2 The C<latex> Filter

The C<latex> filter accepts a number of options, which may be
specified on the USE statement or on the filter invocation.

=over 4

=item C<format>

specifies the format of the output; one of C<dvi> (TeX device
independent format), C<ps> (PostScript) or C<pdf> (Adobe Portable
Document Format).  The follow special values are also accepted:
C<pdf(ps)> (generates PDF via PostScript, using C<dvips> and
C<ps2pdf>), C<pdf(dvi)> (generates PDF via dvi, using C<dvipdfm>)

=item C<output>

the name of the output file, or just the output format

=item C<indexstyle>

the name of the C<makeindex> style file to use (this is passed with
the C<-s> option to C<makeindex>)

=item C<indexoptions>

options to be passed to C<makeindex>.  Useful options are C<-l> for
letter ordering of index terms (rather than the default word
ordering), C<-r> to disable implicit page range formation, and C<-c>
to compress intermediate blanks in index keys. Refer to L<makeindex(1)>
for full details.

=item C<maxruns>

The maximum number of runs of the formatter program (defaults to 10).

=item C<extraruns>

The number of additional runs of the formatter program after it seems
that the formatting of the document has stabilized (default 0).  Note
that the setting of C<maxruns> takes precedence, so if C<maxruns> is
set to 10 and C<extraruns> is set to 3, and formatting stabilizes
after 8 runs then only 2 extra runs will be performed.

=back


=head2 The C<latex_encode> filter

The C<latex_encode> filter encodes LaTeX special characters in its
input into their LaTeX encoded representations.  It also encodes other characters that have

The special characters are: C<\> (command character), C<{> (open
group), C<}> (end group), C<&> (table column separator), C<#>
(parameter specifier), C<%> (comment character), C<_> (subscript),
C<^> (superscript), C<~> (non-breakable space), C<$> (mathematics mode).


=over 4

=item C<except>

Lists the characters that should be excluded from encoding.  By
default no special characters are excluded, but it may be useful to
specify C<except = "\\{}"> to allow the input string to contain LaTeX
commands such as C<"this is \textbf{bold} text">.

=item C<use_textcomp>

By default the C<latex_encode> filter will encode characters with the
encodings provided by the C<textcomp> LaTeX package (for example the
Pounds Sterling symbol is encoded as C<\textsterling{}>).  Setting
C<use_textcomp = 0> turns off these encodings.

=back

=head2 C<table()>

The C<table()> function provides an interface to the C<LaTeX::Table> module.

The following example shows how a simple table can be set up.

    [%- USE Latex;

        data = [ [ 'London', 'United Kingdom' ],
                 [ 'Berlin', 'Germany'        ],
                 [ 'Paris',  'France'         ],
                 [ 'Washington', 'USA'        ] ] );

        text = Latex.table( caption  = 'Capitol Cities',
                            label    = 'table:capitols',
                            headings = [ [ 'City', 'Country' ] ],
                            data     = data );
     -%]

The variable C<text> will hold the LaTeX commands to typeset the table
and can be further interpolated into a LaTeX document template.

=head1 DIAGNOSTICS

Most failures result from invalid LaTeX input and are propagated up from
L<LaTeX::Driver>, L<LaTeX::Encode> or L<LaTeX::Table>.

Failures detected in this module include:

=over 4

=item C<OUTPUT_PATH is not set>

an output filename was specified but the C<OUTPUT_PATH> configuration
option has not been set.

=back


=head1 DEPENDENCIES

=over 4

=item L<Template>

The Template Toolkit.

=item L<LaTeX::Driver>

Provides the logic for driving the LaTeX programs.

=item L<LaTeX::Encode>

Underpins the C<latex_encode> filter.

=item L<LaTeX::Table>

Underpins the C<table> function.

=back


=head1 INCOMPATIBILITIES

The C<latex> filter was distributed as part of the core
Template Toolkit distribution until version 2.15 (released in May 2006),
when it was moved into the separate Template-Latex distribution.  The
C<Latex> plugin must now be explicitly to enable the C<latex> filter.


=head1 BUGS AND LIMITATIONS

The paths to the F<latex>, F<pdflatex> and F<dvips> should be
pre-defined as part of the installation process of L<LaTeX::Driver>
(i.e. when you run C<perl Makefile.PL> for that package).  Alternative
values can be specified from Perl code using the C<program_path> class
method from that package, but there are deliberately no options to
specify these paths from TT code.


=head1 AUTHOR

Andrew Ford E<lt>a.ford@ford-mason.co.ukE<gt> (current maintainer)

Andy Wardley E<lt>abw@wardley.orgE<gt> L<http://wardley.org/>

The original Latex plugin on which this is based was written by Craig
Barratt with additions for Win32 by Richard Tietjen.  The code has
subsequently been radically refactored by Andrew Ford.

=head1 LICENSE AND COPYRIGHT

  Copyright (C) 1996-2006 Andy Wardley.  All Rights Reserved.
  Copyright (C) 2006-2014 Andrew Ford.  All Rights Reserved.
  Copyright (C) 2014-2016 Chris Travers. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This software is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

L<Template>, L<LaTeX::Driver>, L<LaTeX::Table>, L<LaTeX::Encode>


L<latex2dvi(1)>, L<latex2pdf(1)> and L<latex2ps(1)> (part of the
C<LaTeX::Driver> distribution)

=cut


# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
