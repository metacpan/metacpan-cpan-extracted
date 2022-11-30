version=`perl -ne 'if (/^our .VERSION = ..(.*).;$/) { print $1 }' lib/Net/Z3950/FOLIO.pm`;
cat ${@+"$@"} | perl -npe 's/\$\{version}/'"$version"'/g; s/\$\{artifactId}/mod-z3950/g;'
