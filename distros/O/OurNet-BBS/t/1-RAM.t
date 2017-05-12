#!/usr/bin/perl -w
# $File: //depot/libOurNet/BBS/t/1-RAM.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 1 $ $DateTime: 2002/06/11 15:35:12 $

use strict;
use OurNet::BBS;
our $BBS = OurNet::BBS->new({ backend => 'RAM'});
(($_ = $0) =~ s/[\w-]+\.t$/stdtests/) and do $_ if $BBS;

__END__
