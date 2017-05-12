#!/usr/bin/python 

#################################################################################
#                                                                              	#
#  Copyright (C) 2003 Wim Vanderbauwhede. All rights reserved.                  #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################

import sys, getopt

#------------------------------------------------------------------------------
def quadratic(a,b,c,x):
    y=float(a)*float(x)*float(x)+float(b)*float(x)+float(c)
    return y

#==============================================================================

if len(sys.argv) < 2:
    print 'usage: %s -i <inputfile> -o <outputfile>' % sys.argv[0]
    sys.exit(1)

#Handle command line options
optlist, args = getopt.getopt(sys.argv[1:], 'i:o:')

for arg, filename in optlist:
    if arg == '-i':
        infile = filename
    if arg == '-o':
        outfile = filename
        
IN=file(infile,'r');
variables=IN.readline()
#optional IN.close()
(a,b,c,x)=variables.split()

OUT=file(outfile,'w')
OUT.write('%s\n' % quadratic(a,b,c,x))
#print quadratic(a,b,c,x)
#optional OUT.close()
