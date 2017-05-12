#!/bin/sh
#
# $RCSfile: makedct.sh,v $
# $Author: swaj $
# $Revision: 1.2.2.1 $
#
# This script will look for .sdct source files in the current directory
# then compile them to .dct files - binary format 
#


#
# Change according to your layout   
#

SDICT_TOOLS="sdict-tools.plx"


#
# Use compilation switch
#

COMPILE="${SDICT_TOOLS} --compile " 



# If you need to sort some exotic langs out, 
# look at lib/latin-cyrillic.pl and extend it according to glyphs you need.
# !!! Dont mix up caps and lowers -
# Sdict works with such dictionaries only with '--ignoresindex', but it's really SLOW!!!

OPTIONS="--sort=latin-cyrillic --compress=gzip"



#
# TARGET_DIR is also used for all temporary files
#

TARGET_DIR="."



echo "Compiling *.sdct with options '$OPTIONS'"

for i in *.sdct

do
    o=`echo $i | perl -ne 'chomp; s|sdct|dct|i; print "$_"'`
    echo "running $COMPILE --input-file=$i --output-file=${TARGET_DIR}/$o $OPTIONS"
    $COMPILE --input-file=$i --output-file=${TARGET_DIR}/$o $OPTIONS
done


echo "FINISHED"


    
#__END__
