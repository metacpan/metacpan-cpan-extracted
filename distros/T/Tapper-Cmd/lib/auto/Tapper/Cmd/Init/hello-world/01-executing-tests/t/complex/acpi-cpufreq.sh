#! /bin/bash

. ./tapper-autoreport --import-utils

require_crit_level 4 # cpu off/on toggle

switch_governor() {
	_succ=0
	for _cpu in $SYSFS/cpu[0-9]*/cpufreq
	do
		echo "$1" > $_cpu/scaling_governor 2> /dev/null && continue
		_cpurnr=$(echo $_cpu | sed -e 's,^.*/cpu\([0-9].*\)/.*,\1,')
		ok 1 "could not set $1 governor for CPU $_cpunr"
	done
	return $_succ
}

SYSFS=/sys/devices/system/cpu

if vendor_amd ; then
	family=$(get_cpu_family)
	todo=" # TODO run on a GH or later processor"
	[ $family -ge 16 ] && todo=""
	require_ok $? "CPU is family $(printf "%02xh" $family)$todo$skip"
fi

todo=" # TODO not supported by virtualized guests (and Dom0) by now"
is_running_under_xen_hv || is_running_in_kvm_guest || todo=""
if vendor_amd ; then
	grep -q "^power management:.* hwpstate" /proc/cpuinfo
	require_ok $? "has hardware P-states feature$todo"
else
	has_cpufeature est
	require_ok $? "has Enhanced SpeedStep feature$todo"
fi


todo=" # TODO not expected on older kernels"
version_number_compare $(get_kernel_release) -ge 3.7.0 && todo=""

if [ ! -d $SYSFS/cpu0/cpufreq ] ; then
	if grep -q powernowk8_exit /proc/kallsyms ; then
		ok 0 "PowerNow-K8 loaded, but not active$todo"
	else
		modprobe powernow_k8 2> /dev/null
		negate_ok $? "PowerNow-K8 driver must not load on modern AMD CPUs$todo"
	fi
	if grep -q acpi_cpufreq_exit /proc/kallsyms ; then
		ok 1 "acpi-cpufreq loaded, but not active$todo"
	else
		modprobe acpi_cpufreq
		ok $? "acpi-cpufreq driver loaded$todo"
	fi
fi

[ -d $SYSFS/cpu0/cpufreq ] && [ $(cat $SYSFS/cpu0/cpufreq/scaling_driver) = "acpi-cpufreq" ]
require_ok $? "acpi-cpufreq driver loaded and active$todo"

[ -f $SYSFS/cpufreq/boost ]
ok $? "has global boost file"

allboost=1
allcpb=1
anycpb=0
for cpu in $SYSFS/cpu*/cpufreq
do
	[ -f $cpu/boost ] || allboost=0
	[ -f $cpu/cpb ] || allcpb=0
	[ -f $cpu/cpb ] && anycpb=1
done

[ $allboost = 1 ]
ok $? "all CPUs have local boost file # TODO to be implemented"

if vendor_intel ; then
	skip=" # SKIP legacy CPB kernel config option not enabled"
	has_kernel_config CONFIG_X86_ACPI_CPUFREQ_CPB && todo=""
	[ $anycpb = 0 ]
	ok $? "no CPU must have local cpb file on Intel$skip"
else
	todo=" # TODO enable legacy CPB kernel config option"
	has_kernel_config CONFIG_X86_ACPI_CPUFREQ_CPB && todo=""
	[ $allcpb = 1 ]
	ok $? "all CPUs have local cpb file$todo"
fi

nrdirs=0
nrlinks=0
nrcpus=0
for cpu in $SYSFS/cpu[0-9]*
do
	[ -d $cpu/cpufreq ] && let nrdirs+=1
	[ -h $cpu/cpufreq ] && let nrlinks+=1
	let nrcpus+=1
done

[ $nrcpus -eq $nrdirs ]
ok $? "each CPU has a cpufreq directory ($((nrcpus-nrdirs)) missing)"

[ $nrlinks -eq 0 ]
ok $? "each cpufreq directory is genuine ($nrlinks are symbolic links)"

# some hotplug testing: the driver has a hotplug notifier, lets stress it
nrcores=$(grep -ci bogomips /proc/cpuinfo)
for i in $(seq 1 100)
do
	cpunr=$(((RANDOM%(nrcores-1))+1))
	current=$(cat $SYSFS/cpu$cpunr/online)
	new=$((1-current))
	echo $new > $SYSFS/cpu$cpunr/online
	sleep 0.1
done
# now online all CPUs again
for cpunr in $SYSFS/cpu[0-9]*/online
do
	if [ $(cat $cpunr) = "0" ] ; then echo 1 > $cpunr; fi
done

ok 0 "survived 100 CPU off/online transitions"

online_cpus=$(($(grep 1 $SYSFS/cpu[0-9]*/online | wc -l)+1))
ondemands=$(grep ondemand $SYSFS/cpu[0-9]*/cpufreq/scaling_available_governors | wc -l)

[ $online_cpus -eq $ondemands ]
ok $? "all online CPUs support the ondemand governor"

if [ $? -eq 0 ] ; then
	switch_governor ondemand
	ok $? "setting ondemand governor for all CPUs"

	min_freq=$(cat $SYSFS/cpu[0-9]*/cpufreq/scaling_min_freq | sort -n | head -1)
	sleep 3
	cur_freq=$(cat $SYSFS/cpu[0-9]*/cpufreq/scaling_cur_freq | sort -n | uniq -c)

	ok 0 "mininum frequency is $((min_freq/1000)) MHz"

	[ $(echo "$cur_freq" | wc -w) -eq 2 ]
	ok $? "idle: all CPUs at the same frequency"

	echo "$cur_freq" | grep -q " $min_freq$"
	ok $? "idle: all CPUs at the mininum frequency"

	md5sum /dev/zero &
	sleep 2
	cur_freq=$(cat $SYSFS/cpu[0-9]*/cpufreq/scaling_cur_freq | sort -n | uniq -c)

	diff_freq=$(echo "$cur_freq" | wc -w)
	[ $diff_freq -ge 4 ]
	ok $? "single load: CPUs at $((diff_freq/2)) different frequencies"

	echo "$cur_freq" | grep -q "$((online_cpus-1)) $min_freq"
	if [ $? -eq 0 ] ; then
		ok 0 "single load: all but one CPU at minimum frequency"
	else
		echo "$cur_freq" | grep -q "$((online_cpus-2)) $min_freq"
		ok $? "single load: all but two CPUs at minimum frequency"
	fi

	kill %1
else
	ok 0 "idle/load with ondemand governor # SKIP ondemand governor not available"
fi

userspaces=$(grep userspace $SYSFS/cpu[0-9]*/cpufreq/scaling_available_governors | wc -l)

[ $online_cpus -eq $userspaces ]
ok $? "all online CPUs support the userspace governor"

if [ $? -eq 0 ] ; then
	switch_governor userspace
	ok $? "setting userspace governor for all CPUs"

	nrfreqs=$(cat $SYSFS/cpu0/cpufreq/scaling_available_frequencies | wc -w)

	succ=0
	for i in $(seq 1 100)
	do
		cpunr=$((RANDOM%online_cpus))
		freqidx=$(((RANDOM%nrfreqs)+1))
		freq=$(cut -d\  -f "$freqidx" $SYSFS/cpu0/cpufreq/scaling_available_frequencies)
		echo "$freq" > $SYSFS/cpu$cpunr/cpufreq/scaling_setspeed || ok 1 "could not set $((freq/1000)) MHz on CPU $cpunr" || succ=1
		sleep 0.5
		cur_freq=$(cat $SYSFS/cpu$cpunr/cpufreq/scaling_cur_freq)
		[ $cur_freq -eq $freq ] || ok 1 "frequency on CPU $cpunr is $((cur_freq/1000)), but should be $((freq/1000)) MHz" || success=1
		sleep 0.1
	done

	ok $success "100 successful transitions to different frequencies"

	switch_governor ondemand
	ok $success "resetting to ondemand governor on all CPUs"
else
	ok 0 "frequency transitions with userspace governor # SKIP userspace governor not available"
fi

if [ 0$(stat -c %a $SYSFS/cpufreq/boost) -gt 0444 ] ; then
	ok 0 "boost file is writeable"
	has_cpufeature cpb || has_cpufeature ida
	ok $? "processor supports boosting"
	if [ -e $SYSFS/cpu0/cpufreq/cpb ] ; then
		ok 0 "system has legacy cpb files"
		all_writeable=1
		all_same=1
		all_writes_succeed=1
		cpbstate=$(cat $SYSFS/cpu0/cpufreq/cpb)
		for i in $SYSFS/cpu[0-9]*/cpufreq/cpb ; do
			[ 0$(stat -c %a $i) -gt 0444 ] || all_writeable=0
			[ $(cat $i) -eq $cpbstate ] || all_same=0
			echo $cpbstate > $i 2> /dev/null || all_writes_succeed=0
		done
		[ "$all_writeable" -eq 1 ]
		ok $? "all cpb files are writeable"
		[ "$all_same" -eq 1 ]
		ok $? "all cpb files read the same"
		[ "$all_writes_succeed" -eq 1 ]
		ok $? "all cpb files can be written to"
	fi
else
	ok 0 "boost file is write protected"
	! has_cpufeature cpb && ! has_cpufeature ida
	ok $? "processor does not support boosting"
	if [ -e $SYSFS/cpu0/cpufreq/cpb ] ; then
		ok 0 "system has legacy cpb files"
		all_writeable=1
		all_zero=1
		all_write_failing=1
		for i in $SYSFS/cpu[0-9]*/cpufreq/cpb ; do
			[ 0$(stat -c %a $i) -gt 0444 ] || all_writeable=0
			[ $(cat $i) -eq 0 ] || all_zero=0
			echo 0 > $i 2> /dev/null && all_write_failing=0
		done
		[ "$all_writeable" -eq 1 ]
		ok $? "all cpb files are writeable"
		[ "$all_zero" -eq 1 ]
		ok $? "all cpb files read as zero"
		[ "$all_write_failing" -eq 1 ]
		ok $? "no cpb file can be written to"
	fi

	ok 0 "testing boost switch # SKIP processor cannot boost"
	done_testing
	exit 0
fi

echo 1 > $SYSFS/cpufreq/boost 2> /dev/null
ok $? "enable boosting (global boost file)"
[ $(cat $SYSFS/cpufreq/boost) -eq 1 ]
ok $? "boosting enabled"

sumboost=0
TIMEFORMAT=%U
for i in $(seq 1 10)
do
	/usr/bin/time -o /dev/shm/_time.txt --format=%U sh -c 'dd if=/dev/zero bs=1M count=4096 status=noxfer 2> /dev/null | md5sum - > /dev/null'
	sumboost=$((sumboost+$(cat /dev/shm/_time.txt | tr -d .)))
done

[ $sumboost -gt 0 ]
ok $? "10 iterations of boosted md5sum <4GB of zeroes>: $sumboost ms"

echo 0 > $SYSFS/cpufreq/boost 2> /dev/null
ok $? "disable boosting (global boost file)"
[ $(cat $SYSFS/cpufreq/boost) -eq 0 ]
ok $? "boosting disabled"

sumnoboost=0
for i in $(seq 1 10)
do
	/usr/bin/time -o /dev/shm/_time.txt --format=%U sh -c 'dd if=/dev/zero bs=1M count=4096 status=noxfer 2> /dev/null | md5sum - > /dev/null'
	sumnoboost=$((sumnoboost+$(cat /dev/shm/_time.txt | tr -d .)))
done

[ $sumnoboost -gt 0 ]
ok $? "10 iterations of non-boosted md5sum <4GB of zeroes>: $sumnoboost ms"

ratio=$((sumnoboost*100/sumboost))
[ "$ratio" -gt 102 ]
ok $? "Boosting is faster than non-boosting, ratio is $ratio %"

rm -f /dev/shm/_time.txt

done_testing

# vim: set ts=4 sw=4 tw=0 ft=sh:
