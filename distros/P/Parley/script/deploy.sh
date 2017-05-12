#!/usr/bin/env sh

############################################################################
#
# Usage: deploy.sh <version>
#   e.g. deploy 0.58_12
#
# This is the script I use on my home server to (easily)
# deploy new versions of Parley
#
# I run under FastCGI using config/parley and Ubuntu's "site_available"
# with apache2
#
# I drop all my tarballs in /home/parley and run the script from there
#
# I don't know how the script will behave if there isn't an existing
# deployment - I had one before writing the script.
#
############################################################################

############################################################################
#            THERE IS NOTHING CONFIGURABLE IN THIS SCRIPT!!                #
############################################################################

VERSION=$1;
MAJOR_VERSION=${VERSION%_*}
MINOR_VERSION=${VERSION#*_}

TARBALL="Parley-${VERSION}.tar.gz"
DIR="Parley-${VERSION}"

if [ -z "$VERSION" ]; then
	echo "usage: $0 <version>";
	exit;
fi


if [ ! -f $TARBALL ]; then
	echo "tarball missing: $TARBALL";
	exit;
fi

tar zxf $TARBALL

PATCH_MATCH_COUNT=`ls ${DIR}/db/*${MAJOR_VERSION}*sql | grep -c -`

if [ $PATCH_MATCH_COUNT -gt 0 ]; then
	echo "There are ${PATCH_MATCH_COUNT} patch(es) that match the requested version to deploy:"
	ls ${DIR}/db/*${MAJOR_VERSION}*sql
	echo ""
	read -p "Use ctrl-z to return to the shell and apply any patches. fg then ENTER to continue." FOOBAR
fi

if [ ! -d $DIR ]; then
	echo "directory missing: $DIR";
	exit;
fi

cp -a ./parley/root/static/user_file ./$DIR/root/static/ 2>/dev/null
ls ./$DIR/root/static/user_file/

(cd $DIR && perl Makefile.PL)

./parley/script/parley_email_engine.pl stop

rm parley
ln -s $DIR parley

./parley/script/parley_email_engine.pl start

sudo /etc/init.d/apache2 reload
