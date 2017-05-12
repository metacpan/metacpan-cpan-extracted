use FindBin;
die unless ($FindBin::Script =~ m/^(.*?)\.PL$/);
open(STDOUT, ">$1") || die;
print <DATA>
__END__
#! /usr/local/bin/perl

# ShowModels - a script to demonstrate Spectrum::CLI by emulating "show models"
# Copyright (C) 2000  Dave Plonka

# $Id: ShowModels.PL,v 1.1 2000/01/21 21:22:49 dplonka Exp $
# Dave Plonka <plonka@doit.wisc.edu>

=head1 NAME

ShowModels - a script to demonstrate Spectrum::CLI by emulating "show models"

=head1 SYNOPSIS

 ShowModels [vnmhost]

=head1 DESCRIPTION

=head1 AUTHOR

Dave Plonka <plonka@doit.wisc.edu>

=cut

use English;
use Spectrum::CLI;

$FORMAT_LINES_PER_PAGE = 23;
map { write } Spectrum::CLI->new({verbose => 1}, @ARGV)->show_models;

format STDOUT_TOP =
MHandle     MName                               MTypeHnd    MTypeName
.

format STDOUT =
@<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<
$_->{MHandle} $_->{MName}                       $_->{MTypeHnd} $_->{MTypeName}
.
