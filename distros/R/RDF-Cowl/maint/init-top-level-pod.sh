#!/bin/bash

set -eu

CURDIR=`dirname "$0"`
#CURDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # works in sourced files, only works for bash

perl -0777 \
	-MTemplate::Toolkit::Simple \
	-Mcurry \
	'-M5;$z=tt->include_path(q|maint/tt|)->curry::render(q|toplevel-class.pod.tt|)' \
	-pi -e 's{require RDF::Cowl::Lib::Gen::Class::(?<name>\w+).*}{$&.$z->({%+})}se'  \
	$( \
		comm -13 \
			<( git grep -l '=cowl_gendoc' lib/ | sort ) \
			<( git grep -l 'require RDF::Cowl::Lib::Gen::Class::' lib/ | sort ) \
	)
