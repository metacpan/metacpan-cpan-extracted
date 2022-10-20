#!/bin/sh

set -e

[ -e Makefile ] && make distclean || true

perl Makefile.PL

find lib -name '*.pm' | xargs scandeps.pl -R | \
  perl -MJSON -le '
    undef $/;
    %d=eval(<STDIN>);
    %i=do("./ignoredeps");
    $j=JSON::from_json(`cat MYMETA.json`);
    foreach (sort keys(%d)) {
	    $missing .= "'\''$_'\'' => '\''0'\'',\t# $d{$_}\n" if !defined($j->{prereqs}{runtime}{requires}{$_}) && !defined($i{$_})
    }

    if ($missing) {
	    print "\nMissing deps:\n(\n$missing)\n" ;

	    exit 1
    }
    '

make && make test && make distcheck && make dist
