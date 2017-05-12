#!/bin/sh

cd /etc
for CF in `find *[-_][rRvV][eE][lLrR]* \
		issue /etc.defaults/VERSION \
                VERSION release \
                2>/dev/null | sort` ; do

    case $CF in
	/etc.default*)
	    echo "mkdir etc.defaults"
	    echo "cat > $CF <<EOF"
	    cat $CF
	    echo "EOF"
	    ;;
	*)
	    D=`dirname $CF`
	    F=`basename $CF`

	    if [ -d $CF ]; then
		echo "mkdir $F"
	    else
		echo "cat > $CF <<EOF"
		cat $CF
		echo "EOF"
		fi
	    ;;
	esac
    done
