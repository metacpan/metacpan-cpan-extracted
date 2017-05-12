#!/bin/bash
cp ip_loc.csv ip_loc_old.csv
perl ip_loc_taobao.pl
perl ip_loc_tidy.pl ip_loc_taobao.csv ip_loc_taobao.tidy.csv
perl ip_loc_update.pl ip_loc.csv ip_loc_taobao.tidy.csv ip_loc_update.csv
perl ip_loc_from_as.pl ip_loc_update.csv ip_loc_from_as.csv
perl ip_loc_update.pl ip_loc_update.csv ip_loc_from_as.csv ip_loc.csv

make_inet_from_cidr.pl ip_loc.csv inet_loc_raw.csv 'ip,country,isp'
refine_inet.pl inet_loc_raw.csv inet_loc_src.csv

mv inet_loc.csv inet_loc_old.csv
merge_file.pl -f country.csv -k 1 -v 0 -F inet_loc_src.csv -K 2 -o inet_loc.csv.c
merge_file.pl -f country_area.csv -k 0,3 -v 1 -F inet_loc.csv.c -K 5,3 -o inet_loc.csv.p
merge_file.pl -f country_isp.csv -k 0,3 -v 1 -F inet_loc.csv.p -K 5,4 -o inet_loc.csv
rm inet_loc.csv.c
rm inet_loc.csv.p
