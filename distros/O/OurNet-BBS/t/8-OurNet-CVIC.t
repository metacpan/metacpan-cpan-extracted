#!/usr/bin/perl -w
# $File: //depot/libOurNet/BBS/t/8-OurNet-CVIC.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 1 $ $DateTime: 2002/06/11 15:35:12 $

use strict;
use File::Path;
use File::Temp qw/tempdir/;

our $prefix = tempdir( CLEANUP => 0 );

mkpath(["$prefix/boards", "$prefix/group", "$prefix/man/boards"])
    or die "Cannot make $prefix";
open(my $BOARDS, '>', "$prefix/.BOARDS") 
    or die "Cannot make $prefix/.BOARDS: $!";
close $BOARDS;

###################################################################

use OurNet::BBS;

our $BBS = { backend => 'CVIC', bbsroot => $prefix };
(($_ = $0) =~ s/[\w-]+\.t$/stdtests/) and do $_ if $BBS;

__END__
