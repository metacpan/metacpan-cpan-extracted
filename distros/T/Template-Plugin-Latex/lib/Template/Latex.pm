#============================================================= -*-perl-*-
#
# Template::Latex
#
# DESCRIPTION
#   Provides an interface to Latex from the Template Toolkit.
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
#   * Latex plugin originally written by Craig Barratt, Apr 28 2001.
#   * Win32 additions by Richard Tietjen.
#   * Extracted into a separate Template::Latex module by Andy Wardley,
#     May 2006
#   * Removed the functionality to specify program pathnames on the FILTER call
#     Andrew Ford, 05 June 2006
#   * Now runs BibTeX and Makeindex if required
#     Andrew Ford, 05 June 2006
#   * Rewritten to set up TEXINPUTS so that inclusions can be found and to run
#     latex, bibtex and makeindex repeatedly as needed until references stabilize
#     (NOT YET FINISHED)
#     Andrew Ford, September 2007
#
#========================================================================

package Template::Latex;

use strict;
use warnings;
use base 'Template';
use Template::Exception;
use Template::Plugin::Latex;
use LaTeX::Driver;

our $VERSION  = '3.11';
our $DEBUG    = 0 unless defined $DEBUG;
our $ERROR    = '';
our $FILTER   = 'latex';        # default filter name
our $FORMAT   = '';             # output format (auto-detect if unset)
our @PROGRAMS = qw( latex pdflatex bibtex makeindex dvips ps2pdf );


sub new {
    my $class  = shift;
    my $config = @_ && ref $_[0] eq 'HASH' ? shift : { @_ };
    my $self   = $class->SUPER::new($config) || return;
    my %options;
    
    #     # set default format from config option
    $options{format} = $config->{LATEX_FORMAT}
        if $config->{LATEX_FORMAT};


    my @unsupported = ( 'LATEX', 'PDFLATEX', 'DVIPS', 'PS2PDF',
                        'BIBTEX', 'MAKEINDEX' );
    
    warn "Template::Latex no longer supports various *_PATH options to new()"
        if scalar(grep { defined $config->{"${_}_PATH"} } @unsupported) > 0;
    

    # install the latex filter
    Template::Plugin::Latex->new($self->context, \%options);

    return $self;
}


#------------------------------------------------------------------------
# latex_format()
# latex_path()
# pdflatex_path()
# dvips_path()
#
# Methods to get/set the $FORMAT, $LATEX, $PDFLATEX and $DVIPS package
# variables that specify the default output format and the paths to
# the latex, pdflatex and dvips programs.
#------------------------------------------------------------------------

sub latex_format {
    my $class = shift;
    return @_ ? ($FORMAT = shift) : $FORMAT;
}

sub latex_path {
    my $class = shift;
    return LaTeX::Driver->program_path('latex', @_);
}

sub pdflatex_path {
    my $class = shift;
    return LaTeX::Driver->program_path('pdflatex', @_);
}

sub dvips_path {
    my $class = shift;
    return LaTeX::Driver->program_path('dvips', @_);
}

sub ps2pdf_path {
    my $class = shift;
    return LaTeX::Driver->program_path('ps2pdf', @_);
}

sub bibtex_path {
    my $class = shift;
    return LaTeX::Driver->program_path('bibtex', @_);
}

sub makeindex_path {
    my $class = shift;
    return LaTeX::Driver->program_path('makeindex', @_);
}

sub xelatex_path {
    my $class = shift;
    return LaTeX::Driver->program_path('xelatex', @_);
}

#------------------------------------------------------------------------
# latex_paths()
#
# Method to get/set the above all in one go.
#------------------------------------------------------------------------

sub latex_paths {
    my $class = shift;
    if (@_) {
        my $args = ref $_[0] eq 'HASH' ? shift : { @_ };

        LaTeX::Driver->program_path($_, $args->{$_})
            for qw( latex pdflatex bibtex makeindex dvips ps2pdf );
    }
    else {
        return {
            map { ( $_ => LaTeX::Driver->program_path($_) ) } @PROGRAMS
        };
    }
}

1;

__END__


=head1 NAME

Template::Latex - Latex support for the Template Toolkit

=head1 SYNOPSIS

    use Template::Latex;
    
    my $tt = Template::Latex->new({
        INCLUDE_PATH  => '/path/to/templates',
        OUTPUT_PATH   => '/path/to/pdf/output',
        LATEX_FORMAT  => 'pdf',
    });
    my $vars = {
        title => 'Hello World',
    }
    $tt->process('example.tt2', $vars, 'example.pdf', binmode => 1)
        || die $tt->error();

=head1 DESCRIPTION

The Template::Latex module is a wrapper of convenience around the
Template module, providing additional support for generating PDF,
PostScript and DVI documents from LaTeX templates.

You use the Template::Latex module exactly as you would the Template
module.  

    my $tt = Template::Latex->new(\%config);
    $tt->process($input, \%vars, $output)
        || die $t->error();

It supports the C<LATEX_FORMAT> option to specify the default
output format.  This can be set to C<pdf>, C<ps> or C<dvi>.

    my $tt = Template::Latex->new({
        LATEX_FORMAT  => 'pdf',
    });

Previous versions of the module supported the C<LATEX_PATH>,
C<PDFLATEX_PATH>, C<DVIPS_PATH>, C<PS2PDF_PATH>, C<BIBTEX_PATH>
and C<MAKEINDEX_PATH> options. These are now deprecated
and their use will result in a deprecation warning, as their use
would result in modifying global state, disallowing different values
for different simultaneous instances.

To change the paths of the various programs being called by the
LaTeX::Driver module which this module wraps, the user is referred
to the API of that module.  This module provides a number of (wrapper)
class methods around the LaTeX::Driver routine (latex_path() and
friends).

The C<latex> filter is automatically defined when you use the
Template::Latex module.  There's no need to load the Latex plugin in
this case, although you can if you want (e.g. to set some
configuration defaults).  If you're using the regular Template module
then you should first load the Latex plugin to define the C<latex>
filter.

    [% USE Latex %]
    [% FILTER latex('example.pdf') %]
    ...LaTeX doc...
    [% END %]

=head1 PUBLIC METHODS

The Template::Latex module is a subclass of the Template module and
inherits all its methods.  Please consult the documentation for the
L<Template> module for further information on using it for template
processing.  Wherever you see C<Template> substitute it for
C<Template::Latex>.

In addition to those inherted from the Template module, the following
methods are also defined.

=head2 latex_paths()

Method to get or set the paths to the F<latex>, F<pdflatex> and
F<dvips> programs.  These values are stored in the Template::Latex
C<$LATEX>, C<$PDFLATEX> and C<$DVIPS> package variables, respectively.
It can be called as either a class or object method.

    Template::Latex->latex_paths({
        latex    => '/usr/bin/latex',
        pdflatex => '/usr/bin/pdflatex',
        dvips    => '/usr/bin/dvips',
    });

    my $paths = Template::Latex->latex_paths();
    print $paths->{ latex };    # /usr/bin/latex

=head2 latex_path()

Method to get or set the C<$Template::Latex::LATEX> package
variable which defines the location of the F<latex> program on your
system.  It can be called as a class or object method.

    Template::Latex->latex_path('/usr/bin/latex');
    print Template::Latex->latex_path();   # '/usr/bin/latex'

=head2 pdflatex_path()

Method to get or set the C<$Template::Latex::PDFLATEX> package
variable which defines the location of the F<pdflatex> program on your
system.  It can be called as a class or object method.

    Template::Latex->pdflatex_path('/usr/bin/pdflatex');
    print Template::Latex->pdflatex_path();   # '/usr/bin/pdflatex'

=head2 dvips_path()

Method to get or set the C<$Template::Latex::DVIPS> package
variable which defines the location of the F<dvips> program on your
system.  It can be called as a class or object method.

    Template::Latex->dvips_path('/usr/bin/dvips');
    print Template::Latex->dvips_path();   # '/usr/bin/dvips'

=head2 bibtex_path()

Method to get or set the C<$Template::Latex::BIBTEX> package
variable which defines the location of the F<bibtex> program on your
system.  It can be called as a class or object method.

    Template::Latex->bibtex_path('/usr/bin/bibtex');
    print Template::Latex->bibtex_path();   # '/usr/bin/bibtex'

=head2 makeindex_path()

Method to get or set the C<$Template::Latex::MAKEINDEX> package
variable which defines the location of the F<makeindex> program on your
system.  It can be called as a class or object method.

    Template::Latex->makeindex_path('/usr/bin/makeindex');
    print Template::Latex->makeindex_path();   # '/usr/bin/makeindex'

=head1 INTERNALS

This section is aimed at a technical audience.  It documents the
internal methods and subroutines as a reference for the module's
developers, maintainers and anyone interesting in understanding how it
works.  You don't need to know anything about them to use the module
and can safely skip this section.

=head2 define_filter($context,\%config)

This class method installs the C<latex> filter in the context passed
as the first argument.  The second argument is a hash reference
containing any default filter parameters (e.g. those specified when
the Template::Plugin::Latex plugin is loaded via a C<USE> directive).

    Template::Latex->define_filter($context, { format => 'pdf' });

The filter is installed as a I<dynamic filter factory>.  This is just
a fancy way of saying that the filter generates a new filter
subroutine each time it is used to account for different invocation
parameters.  The filter subroutine it creates is effectively a wrapper
(a "closure" in technical terms) around the C<filter()> subroutine
(see below) which does the real work.  The closure keeps track of any
configuration parameters specified when the filter is first defined
and/or when the filter is invoked.  It passes the merged configuration
as the second argument to the C<filter()> subroutine (see below).

See the L<Template::Filters> module for further information on how
filters work.

=head2 filter($text,\%config)

This is the main LaTeX filter subroutine which is called by the
Template Toolkit to generate a LaTeX document from the text passed as
the first argument.  The second argument is a reference to a hash
array of configuration parameters.  These are usually provided by the
filter subroutine that is generated by the filter factory.

    Template::Latex::filter($latex, { 
        latex    => '/usr/bin/latex',
        pdflatex => '/usr/bin/pdflatex',
        dvips    => '/usr/bin/dvips',
        output   => 'example.pdf',
    });

=head2 throw($message)

Subroutine which throws a L<Template::Exception> error using C<die>.
The exception type is set to C<latex>.

    Template::Latex::throw("I'm sorry Dave, I can't do that");

=head2 debug($message)

Debugging subroutine which print all argument to STDERR.  Set the 
C<$DEBUG> package variable to enable debugging messages.

    $Template::Latex::DEBUG = 1;

=head1 AUTHOR

Andrew Ford E<lt>a.ford@ford-mason.co.ukE<gt> (current maintainer)

Andy Wardley E<lt>abw@wardley.orgE<gt> L<http://wardley.org/>

The original Latex plugin on which this is based was written by Craig
Barratt with additions for Win32 by Richard Tietjen.

=head1 COPYRIGHT

  Copyright (C) 1996-2006 Andy Wardley.  All Rights Reserved.
  Copyright (C) 2006-2014 Andrew Ford.  All Rights Reserved.
  Copyright (C) 2014-2016 Chris Travers. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::Latex>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
