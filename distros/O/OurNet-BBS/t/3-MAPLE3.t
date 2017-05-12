#!/usr/bin/perl -w
# $File: //depot/libOurNet/BBS/t/3-MAPLE3.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 1 $ $DateTime: 2002/06/11 15:35:12 $

use strict;
use File::Path;
use File::Temp qw/tempdir/;

our $prefix = tempdir( CLEANUP => 1 );

mkpath(["$prefix/brd", "$prefix/gem", "$prefix/gem/@", "$prefix/gem/brd"])
    or die "Cannot make $prefix";
open(my $BOARDS, '>', "$prefix/.BRD")
    or die "Cannot make $prefix/.BRD: $!";
close $BOARDS;

###################################################################

use OurNet::BBS;
our $BBS = OurNet::BBS->new({backend => 'MAPLE3', bbsroot => $prefix});
(($_ = $0) =~ s/[\w-]+\.t$/stdtests/) and do $_ if $BBS;

__END__
