#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "src/segmentize.h"

MODULE = Software::GenoScan::Segmentor			PACKAGE = Software::GenoScan::Segmentor

int
segmentize(filterFlags, fileName, outputDir, VERBOSE)
	int* filterFlags
	char* fileName
	char* outputDir
	int VERBOSE
	
	OUTPUT:
		RETVAL
	
	CLEANUP:
		free(filterFlags);

