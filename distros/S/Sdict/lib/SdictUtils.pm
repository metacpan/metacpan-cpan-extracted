# $RCSfile: SdictUtils.pm,v $
# $Author: swaj $
# $Revision: 1.5 $
#
# Copyright (c) Alexey Semenoff 2001-2007. All rights reserved.
# Distributed under GNU Public License.
#


use 5.008;
use strict;
use warnings;

package SdictUtils;

use Encode qw / encode decode from_to /;
use Data::Dumper;

require Exporter;

use vars qw (
	     @ISA
	     @EXPORT
	     @EXPORT_OK
	     %EXPORT_TAGS
	     $VERSION
	     $PACKAGE
	     $debug
	     );

$VERSION = '1.0';

@ISA = qw ( Exporter );

@EXPORT = qw (
	     &utf8_lowercase
	     );


sub utf8_lowercase ($);


sub utf8_lowercase ($) {

    my ($string) = @_; 

    unless ( utf8::is_utf8 ( $string ) ) {
	warn "Not valid utf8 string: '$string' \n"; 
	    return q{} ;
    }

    return lc ( $string );

}


1;



__END__
