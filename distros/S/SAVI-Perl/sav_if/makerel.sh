#!/bin/sh
#
# Unix shell script to make release of SAV_IF.
#
# You may need to run this under SUSE, since it requires zip.
#
# Creates both DOS and Unix flavours (putting them in upper and lower case
# filenames), and then puts them into a ZIP and tar file respectively.
#
# Assumes the files are in DOS format to begin with, so converts the Unix
# files to be in Unix format.
#
# DOS bit.
#
# Translate filenames to uppercase.
#
/bin/rm -rf /tmp/SAV_IF
/bin/rm -rf /tmp/SAV_IF.ZIP
/bin/rm -rf /tmp/sav_if
/bin/rm -rf /tmp/sav_if.tar

# Check s_types.h and s_comput.h are there - if not, assume they are in the
# directory above (risky!)...

if [ ! -r s_types.h ]; then
  if [ ! -r ../s_types.h ]; then
    echo "Error: stypes.h does not exist in this directory or the one above..."
    exit -1
  fi
  cp ../s_types.h .
  echo "Copying s_types.h from .."
fi
if [ ! -r s_comput.h ]; then
  if [ ! -r ../s_comput.h ]; then
    echo "Error: s_comput.h does not exist in this directory or the one above..."
    exit -1
  fi
  cp ../s_comput.h .
  echo "Copying s_comput.h from .."
fi

echo "Creating DOS SAV_IF.ZIP file..."

mkdir /tmp/SAV_IF
for file in *.[ch]; do
  upperfile=`echo $file | tr '[:lower:]' '[:upper:]'`
  #echo $upperfile
  cp $file /tmp/SAV_IF/$upperfile
done
here=`pwd`
cd /tmp
zip SAV_IF.ZIP SAV_IF/*

# Unix bit.
#
# Strip out extraneous carriage returns
#
echo "Creating Unix sav_if.tar file..."
cd $here
mkdir /tmp/sav_if
for file in *.[ch]; do
  tr -d '\r' < $file > /tmp/sav_if/$file
done
cd /tmp
tar cvf sav_if.tar sav_if/*


