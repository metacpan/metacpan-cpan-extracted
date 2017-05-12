#!/bin/bash
############################################################
#
#   $Id$
#   snmp.sh - Simple shell wrapper script for running rrd-client.pl
#
#   Copyright 2007, 2008 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################
# vim:ts=4:sw=4:tw=78

config_file="$1"

if test -z "$config_file"
then
	echo "Syntax: snmp.sh <config>"
	exit
fi

if ! test -e "$config_file"
then
	echo "Warning: configuration file '$config_file' does not exist!"
	exit
fi

if ! test -s "$config_file"
then
	echo "Warning: configuration file '$config_file' is empty!"
	exit
fi

egrep -v '^\s*[#;]' "$config_file" | while read host community version port
do
	if test -z "$community"
	then
		community="public"
	fi

	if test -z "$version"
	then
		version="2c"
	fi

	if test -z "$port"
	then
		port="161"
	fi

	if test -n "$host"
	then
		temp="/tmp/snmp-$host-$port-$$"
		echo "Probing '$host' [community=$community, version=$version, port=$port] ..."
		rrd-client.pl -q -s "$host" -c "$community" -V "$version" -P "$port" > "$temp"
		cat "$temp" | rrd-server.pl -u "$host"
		rm -f "$temp"
	fi
done

