use strict;
use blib;
use Test::More;

BEGIN { 
	my @modules = qw(
		Net::Amazon::EC2::AvailabilityZone
		Net::Amazon::EC2::BlockDeviceMapping
		Net::Amazon::EC2::ConfirmProductInstanceResponse
		Net::Amazon::EC2::ConsoleOutput
		Net::Amazon::EC2::DescribeAddress
		Net::Amazon::EC2::DescribeImageAttribute
		Net::Amazon::EC2::DescribeImagesResponse
		Net::Amazon::EC2::DescribeKeyPairsResponse
		Net::Amazon::EC2::Error
		Net::Amazon::EC2::Errors
		Net::Amazon::EC2::GroupSet
		Net::Amazon::EC2::InstanceState
		Net::Amazon::EC2::IpPermission
		Net::Amazon::EC2::IpRange
		Net::Amazon::EC2::KeyPair
		Net::Amazon::EC2::LaunchPermission
		Net::Amazon::EC2::LaunchPermissionOperation
		Net::Amazon::EC2::PlacementResponse
		Net::Amazon::EC2::ProductCode
		Net::Amazon::EC2::ProductInstanceResponse
		Net::Amazon::EC2::ReservationInfo
		Net::Amazon::EC2::RunningInstances
		Net::Amazon::EC2::SecurityGroup
		Net::Amazon::EC2::UserData
		Net::Amazon::EC2::UserIdGroupPair		
		Net::Amazon::EC2::Volume
		Net::Amazon::EC2::Attachment
		Net::Amazon::EC2::Snapshot
		Net::Amazon::EC2::BundleInstanceResponse
		Net::Amazon::EC2::Region
		Net::Amazon::EC2::ReservedInstance
		Net::Amazon::EC2::ReservedInstanceOffering
		Net::Amazon::EC2::MonitoredInstance
		Net::Amazon::EC2::InstancePassword
		Net::Amazon::EC2::SnapshotAttribute
		Net::Amazon::EC2::CreateVolumePermission
		Net::Amazon::EC2::AvailabilityZoneMessage
		Net::Amazon::EC2::StateReason
		Net::Amazon::EC2::InstanceBlockDeviceMapping
		Net::Amazon::EC2::InstanceStateChange
		Net::Amazon::EC2::DescribeInstanceAttributeResponse
		Net::Amazon::EC2::EbsInstanceBlockDeviceMapping
		Net::Amazon::EC2::EbsBlockDevice
		Net::Amazon::EC2::DescribeTags
		Net::Amazon::EC2::TagSet
        Net::Amazon::EC2::Details
        Net::Amazon::EC2::Events
        Net::Amazon::EC2::InstanceStatus
        Net::Amazon::EC2::InstanceStatuses
        Net::Amazon::EC2::SystemStatus
	);

	plan tests => scalar @modules;
	use_ok($_) for @modules;
}
