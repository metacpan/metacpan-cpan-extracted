#!/usr/bin/env sh

VERSION=$1;
MAJOR_VERSION=${VERSION%.*}
MINOR_VERSION=${VERSION##*.}

echo $VERSION
echo $MAJOR_VERSION
echo $MINOR_VERSION

#TARBALL="Parley-v${VERSION}.tar.gz"
TARBALL="Parley-${VERSION}.tar.gz"
#DIR="Parley-v${VERSION}"
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

PATCH_MATCH_COUNT=`ls ${DIR}/db/*_${MAJOR_VERSION}*sql 2>&1 |grep -c -`

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
sudo chown -R parley:www-data ./$DIR/root/static/user_file/
ls ./$DIR/root/static/user_file/

(cd $DIR && perl Makefile.PL)

./parley/script/parley_email_engine.pl stop

rm parley
ln -s $DIR parley

./parley/script/parley_email_engine.pl start

sudo /etc/init.d/apache2 reload
