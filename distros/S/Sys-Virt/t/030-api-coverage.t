#!/usr/bin/perl

use strict;
use warnings;
use XML::XPath;

use Test::More;

unless ($ENV{TEST_MAINTAINER}) {
    plan skip_all => "Test only for module maintainer. Set TEST_MAINTAINER=1 to run";
}

my $apifile = `pkg-config --variable=libvirt_api libvirt`;
chomp $apifile;

open API, "<", $apifile or die "cannot read $apifile: $!";
my $xml;
{
    local $/ = undef;
    $xml = <API>;
};
close API;


my $count = 0;

my $xp = XML::XPath->new($xml);

my @enums;
my @functions;
my @macros;

my $set = $xp->find('/api/files/file/exports[@type="function"]/@symbol');
foreach my $n ($set->get_nodelist) {
    $count++;
    push @functions, $n->getData();
}

$set = $xp->find('/api/files/file/exports[@type="enum"]/@symbol');
foreach my $n ($set->get_nodelist) {
    $count++;
    push @enums, $n->getData();
}

$set = $xp->find('/api/files/file/exports[@type="macro"]/@symbol');
foreach my $n ($set->get_nodelist) {
    $count++;
    push @macros, $n->getData();
}

open XS, "<Virt.xs" or die "cannot read Virt.xs: $!";

my $xs;
{
    local $/ = undef;
    $xs = <XS>
}
close XS;

my @blacklist = qw(
virConnCopyLastError
virConnGetLastError
virConnResetLastError
virConnSetErrorFunc
virCopyLastError
virDefaultErrorFunc
virErrorFunc
virFreeError
virResetLastError
virSaveLastError
virGetLastErrorMessage

virConnectAuthCallbackPtr
virConnectOpen
virConnectOpenReadOnly

virConnectDomainEventBlockJobCallback
virConnectDomainEventCallback
virConnectDomainEventDiskChangeCallback
virConnectDomainEventGraphicsCallback
virConnectDomainEventIOErrorCallback
virConnectDomainEventIOErrorReasonCallback
virConnectDomainEventRTCChangeCallback
virConnectDomainEventWatchdogCallback
virConnectDomainEventPMSuspendCallback
virConnectDomainEventPMSuspendDiskCallback
virConnectDomainEventPMWakeupCallback
virConnectDomainEventTrayChangeCallback
virConnectDomainEventBalloonChangeCallback
virConnectDomainEventDeviceAddedCallback
virConnectDomainEventDeviceRemovedCallback
virConnectDomainEventTunableCallback
virConnectDomainEventAgentLifecycleCallback
virConnectDomainEventMigrationIterationCallback
virConnectDomainEventJobCompletedCallback
virConnectDomainEventDeviceRemovalFailedCallback
virConnectDomainEventMetadataChangeCallback
virConnectDomainEventBlockThresholdCallback

virConnectNetworkEventLifecycleCallback

virConnectStoragePoolEventLifecycleCallback

virConnectNodeDeviceEventLifecycleCallback

virConnectSecretEventLifecycleCallback

virEventAddHandleFunc
virEventAddTimeoutFunc
virEventRemoveHandleFunc
virEventRemoveTimeoutFunc
virEventUpdateHandleFunc
virEventUpdateTimeoutFunc

virStreamEventCallback
virStreamSinkFunc
virStreamSourceFunc

virConnectCloseFunc

virDomainMigrate
virDomainMigrate2
virDomainMigrateToURI
virDomainMigrateToURI2

virTypedParamsAddBoolean
virTypedParamsAddDouble
virTypedParamsAddFromString
virTypedParamsAddInt
virTypedParamsAddLLong
virTypedParamsAddString
virTypedParamsAddStringList
virTypedParamsAddUInt
virTypedParamsAddULLong
virTypedParamsClear
virTypedParamsFree
virTypedParamsGet
virTypedParamsGetBoolean
virTypedParamsGetDouble
virTypedParamsGetInt
virTypedParamsGetLLong
virTypedParamsGetString
virTypedParamsGetUInt
virTypedParamsGetULLong

virNetworkDHCPLeaseFree
);

foreach my $func (sort { $a cmp $b } @functions) {
    if ($func =~ /(GetConnect|Ref|GetDomain)$/ ||
	grep {/$func/ } @blacklist) {
	ok(1, $func);
	next;
    }

    ok($xs =~ /\b$func\b/, $func);
}


foreach my $enum (sort { $a cmp $b } @enums) {
    if ($enum =~ /_LAST$/ ||
	$enum =~ /VIR_(TYPED_PARAM|DOMAIN_MEMORY_PARAM|DOMAIN_SCHED_FIELD|DOMAIN_BLKIO_PARAM)_(STRING|STRING_OKAY|BOOLEAN|DOUBLE|INT|LLONG|UINT|ULLONG)/ ||
	$enum eq "VIR_CPU_COMPARE_ERROR" ||
	$enum eq "VIR_DOMAIN_NONE" ||
	$enum eq "VIR_DOMAIN_MEMORY_STAT_NR") {
	ok(1, $enum);
	next;
    }

    ok($xs =~ /REGISTER_CONSTANT(_STR)?\($enum,/, $enum);
}


@blacklist = qw(
LIBVIR_VERSION_NUMBER
VIR_COPY_CPUMAP
VIR_CPU_MAPLEN
VIR_CPU_USABLE
VIR_CPU_USED
VIR_DOMAIN_BLKIO_FIELD_LENGTH
VIR_DOMAIN_BLOCK_STATS_FIELD_LENGTH
VIR_DOMAIN_EVENT_CALLBACK
VIR_NETWORK_EVENT_CALLBACK
VIR_STORAGE_POOL_EVENT_CALLBACK
VIR_NODE_DEVICE_EVENT_CALLBACK
VIR_SECRET_EVENT_CALLBACK
VIR_DOMAIN_MEMORY_FIELD_LENGTH
VIR_DOMAIN_MEMORY_PARAM_UNLIMITED
VIR_DOMAIN_SCHED_FIELD_LENGTH
VIR_GET_CPUMAP
VIR_NODEINFO_MAXCPUS
VIR_NODE_CPU_STATS_FIELD_LENGTH
VIR_NODE_MEMORY_STATS_FIELD_LENGTH
VIR_SECURITY_DOI_BUFLEN
VIR_SECURITY_LABEL_BUFLEN
VIR_SECURITY_MODEL_BUFLEN
VIR_TYPED_PARAM_FIELD_LENGTH
VIR_UNUSE_CPU
VIR_USE_CPU
VIR_UUID_BUFLEN
VIR_UUID_STRING_BUFLEN
_virBlkioParameter
_virMemoryParameter
_virSchedParameter
LIBVIR_CHECK_VERSION
);

foreach my $macro (sort { $a cmp $b } @macros) {
    if (grep {/$macro/} @blacklist) {
	ok(1, $macro);
	next;
    }

    ok($xs =~ /REGISTER_CONSTANT(_STR)?\($macro,/, $macro);
}

done_testing($count);
