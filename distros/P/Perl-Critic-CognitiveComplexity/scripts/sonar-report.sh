#!/bin/bash

set -e # Exit with nonzero exit code if anything fails

prove -l -a testReport.tgz
cover -test -report clover
sed -i 's#blib/lib#lib#' cover_db/clover.xml
perlcritic --profile $TRAVIS_BUILD_DIR/.perlcriticrc --quiet --verbose "%f~|~%s~|~%l~|~%c~|~%m~|~%e~|~%p~||~%n" lib t > perlcritic_report.txt || true
sonar-scanner -Dsonar.host.url=http://sonarqube.racodond.com/ -Dsonar.login=$SONAR_TOKEN
