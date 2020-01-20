#!/bin/bash

cover -delete
PERL5OPT=-MDevel::Cover=-coverage,statement,branch,condition,path,subroutine,+ignore,t/.*,prove,.+perltidier,/MySQL/Util prove -lrsv t
cover

if [[ "$1" == "ff" ]]; then
    firefox file:///${PWD}/cover_db/coverage.html &
fi
