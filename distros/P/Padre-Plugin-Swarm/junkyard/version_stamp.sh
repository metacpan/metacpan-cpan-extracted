#!/bin/bash
find lib -path '*/.svn' -prune -o -type f -exec  sed -i -e "s|VERSION = .*|VERSION = '$NEWVERSION';|g"  '{}' \;
