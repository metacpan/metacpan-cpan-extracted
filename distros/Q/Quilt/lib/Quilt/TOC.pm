#
# Copyright (C) 1998 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: TOC.pm,v 1.1 1998/03/09 03:18:14 ken Exp $
#

package Quilt::TOC;

use strict;
use vars qw{$singleton};

my $singleton = undef;

sub new {
    my ($type) = @_;

    return ($singleton)
	if (defined $singleton);

    my ($self) = {};

    bless ($self, $type);

    $singleton = $self;

    return $self;
}

sub visit_scalar {
}

sub visit_SGML_SData {
}

sub visit_Quilt_DO_Struct_Section {
    my $self = shift; my $section = shift; my $formatter = shift; my $toc = shift;

    $formatter->visit_TOC ($self, $section, $toc, @_);
}

# ignore everything but sections
sub AUTOLOAD {
}

1;
