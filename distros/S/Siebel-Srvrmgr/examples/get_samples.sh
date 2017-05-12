#!/bin/bash

function create_folder {

	if ! [ -d $1 ]
		then
		mkdir -v $1
	fi

}

function collect {

  echo "Running $5 for $6"

	create_folder $6
	srvrmgr /g $1 /e $2 /u $3 /p $4 /b /i $5 /o "$6.tmp"

	new_name=$(grep Version "$6.tmp" | awk '{ print $8"_"$9 }' | sed -e 's/\[//' -e 's/\]//')

	if [ $? -gt 0 ]
	then
		echo "error getting version from "$6.tmp" output file. Aborting..."
		exit 1
	fi

	mv -v "$6.tmp" "$6/$new_name.txt"

}

gateway=siebel1
enterprise=SBA_80
user=SADMIN
password=SADMIN

collect $gateway $enterprise $user $password 'list_cmd_del.txt' 'delimited' 
collect $gateway $enterprise $user $password 'list_cmd_fixed.txt' 'fixed' 

tar czvf all.tgz delimited fixed
rm -rfv delimited fixed

echo "Finished"
