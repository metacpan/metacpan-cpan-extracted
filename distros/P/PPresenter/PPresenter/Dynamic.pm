# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Dynamic;

use strict;
use PPresenter::StyleElem;
use base 'PPresenter::StyleElem';

use PPresenter::Program;

#
# Used while initializing.
#

use constant ObjDefaults =>
{ type            => 'dynamic'
, -name           => undef
, -aliases        => undef
, -startPhase     => 0
, -exportPhases   => 0
};

sub makeProgram($$$)
{   my ($dynamic, $show, $view, $displace_x) = @_;

    my $program = PPresenter::Program->new
    ( startPhase   => $dynamic->{-startPhase}
    , show         => $show
    , view         => $view
    , viewport     => $view->viewport
    , canvas       => $view->canvas
    , dx           => $displace_x
    );

    $program;
}

sub exportedPhases($)
{   my ($dynamic, $program) = @_;
    my $export  = $dynamic->{-exportPhases} || return $program->lastPhase;

    ref $export ? @$export : (0..$program->lastPhase);
}

1;
