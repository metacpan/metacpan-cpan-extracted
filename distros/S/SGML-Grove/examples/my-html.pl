#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: my-html.pl,v 1.3 1998/02/08 17:54:13 ken Exp $
#

# `my-html.pl' uses `accept_gi' methods to generate calls back using
# an element's GI instead of the generic `visit_SGML_Element'.
# Because we don't want to handle every single possible GI, Perl's
# AUTOLOAD feature is used to pass through any elements we don't
# handle.
#
# `SpecBuilder.pm' is another example of using `visit_gi_NAME'
# callbacks.
#
# NOTE: SP does not generate SData events when there are no character
# entities defined for an entity reference, for example when you parse
# an HTML or XML document without a DTD.  What this means is that you
# must use a valid HTML doctype declaration (<!DOCTYPE...) to use
# entities like `&uml;'.
# 
#

#
# This example needs a GroveBuilder module to read a grove, we'll use
# SGML::SPGroveBuilder
#

use SGML::SPGroveBuilder;
use SGML::Grove;

($prog = $0) =~ s|.*/||g;

die "usage: $prog HTML-DOC\n"
    if ($#ARGV != 0);

$grove = SGML::SPGroveBuilder->new ($ARGV[0]);

$grove->accept (MyHTML->new);

exit (0);

######################################################################
#
# A Visitor package.
#

package MyHTML;

use strict;
use vars qw{$AUTOLOAD};

sub new {
    my $type = shift;

    return (bless {}, $type);
}

sub visit_SGML_Grove {
    my $self = shift;
    my $grove = shift;

    $grove->children_accept_gi ($self, @_);
}

sub visit_SGML_Element {
    die "$::prog: visit_SGML_Element called while using accept_gi??\n";
}

sub visit_SGML_SData {
    my $self = shift;
    my $sdata = shift;

    warn "is SData?\n";
    print "&" . $sdata->name . ";";
}

sub visit_scalar {
    my $self = shift;
    my $scalar = shift;

    $scalar =~ tr/\r/\n/;
    print $scalar;
}

######################################################################
#
# My special HTML tags
#

sub visit_gi_DATE {
    my $time = localtime;

    # use only non-breaking spaces
    $time =~ s/ /\&nbsp;/g;

    print $time;
}

sub visit_gi_PERL {
    my $self = shift;
    my $element = shift;

    # doesn't grok entities/SData, be sure to use CDATA marked sections
    my $perl = $element->as_string;
    $perl =~ tr/\r//d;
    no strict;
    eval $perl;
    use strict;
    warn $@ if $@;
}

######################################################################
#
# Everything else
#
# See ``perltoot - Tom's object-oriented tutorial for perl''
# for a discussion of AUTOLOAD
#   <http://www.perl.com/CPAN/doc/FMTEYEWTK/perltoot.html>
#
sub AUTOLOAD {
    my $self = shift;

    my $type = ref($self)
	or die "$self is not an object, calling $AUTOLOAD";

    my $name = $AUTOLOAD;
    # strip fully-qualified portion, returning operator and gi
    my ($op, $gi) = ($name =~ /.*::(visit_gi_)?(.*)/);
    
    die "$::prog: called AUTOLOAD without \`visit_gi_'\n"
	if ($op ne 'visit_gi_');

    # XXX needs to output attributes
    my $element = shift;
    print "<$gi>";
    $element->children_accept_gi ($self, @_);
    print "</$gi>";
}

1;
