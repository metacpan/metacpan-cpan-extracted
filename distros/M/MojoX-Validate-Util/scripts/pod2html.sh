#!/bin/bash

INFIX=MojoX/Validate
DEST=$DR/Perl-modules/html/$INFIX

pod2html.pl -i lib/$INFIX/Util.pm -o $DEST/Util.html
