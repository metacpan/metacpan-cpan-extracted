#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

SV* typeis ( SV* what ) ;

SV* typeis ( SV* what )
{
	if ( SvIOK( what ) )
		return newSVpvs( "integer" ) ;
	else if ( SvNOK( what ) )
		return newSVpvs( "double" ) ;
	else if ( SvPOK( what ) )
		return newSVpvs( "string" ) ;

	return newSVpvs( "unknown" ) ;
}


MODULE = NoSQL::PL2SQL		PACKAGE = NoSQL::PL2SQL::Node

PROTOTYPES: ENABLE

SV* 
typeis( what )
	SV* what
