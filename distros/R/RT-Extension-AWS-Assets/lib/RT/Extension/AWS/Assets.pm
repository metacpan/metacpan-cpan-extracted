use strict;
use warnings;
package RT::Extension::AWS::Assets;

use Paws;
use Paws::Credential::Explicit;

our $VERSION = '0.07';

=head1 NAME

RT-Extension-AWS-Assets - Manage AWS resources in RT assets

=head1 DESCRIPTION

Manage AWS resources in RT assets

=head1 RT VERSION

Works with RT 6.0

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::AWS::Assets');

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

=item Restart your webserver

=back

=head1 USAGE

This extension is designed to fetch data for EC2 and RDS instances in
AWS and create RT asset records for each. It also can fetch information
on reserved instances and create assets records for these, in a different
catalog.

Once you have fetched the above information, you can use linking in RT
to associate an AWS resource, like an AWS EC2 instance, with a reservation
you have purchased. The extension provides a page in the RT web UI at
C<https://myrt.com/AWS/LinkAsset.html?id=123> to match AWS resources
with reservations based on the service, instance type, and region.

=head1 CONFIGURATION

The following configuration options need to be set to use this
extension.

=head2 AWS API Credentials

In the AWS IAM console, create keys for external access and set:

    Set($AWS_ACCESS_KEY, 'foo');
    Set($AWS_SECRET_KEY, 'barbaz');

=head2 Asset Catalogs

Set the following with the names of the catalogs to use for AWS
resources (like EC2 and RDS instances) and reserved instances.

    Set($AWSAssetsInstanceCatalog, 'AWS Resources');
    Set($AWSAssetsReservedInstancesCatalog, 'AWS Reserved Instances');

=head2 Data Field Mapping

Information from AWS resources is stored mostly in custom fields on
assets in RT. Use this configuration to define which custom fields to
populate. The names mostly map to the name provided by AWS in the API.

The EC2 and RDS keys are for AWS resources. The EC2:RI and RDS:RI are
for reserved instances.

    Set($AWSAssetsUpdateFields, {
        'EC2' => ['Instance Type', 'Platform', 'Placement:Tenancy', 'Placement:Availability Zone', 'Tags:Name', 'Tags:customer'],
        'RDS' => ['Instance Type', 'Engine', 'Allocated Storage', 'Availability Zone', 'Name', 'MultiAZ', 'TagList:customer'],
        'EC2:RI' => ['Instance Type', 'Platform', 'Tenancy', 'Reservation Start', 'Reservation End', 'Duration', 'Offering Class', 'Offering Type', 'Name', 'Product Description', 'State'],
        'RDS:RI' => ['Instance Type', 'Platform', 'Reservation Start', 'Reservation End', 'Duration', 'Offering Type', 'Name', 'MultiAZ', 'Product Description', 'State', 'AWS Reserved Instance ID'],
    }
    );

=head2 Asset Linking Page

This format defines the columns shown on the reservation linking page.

Set($AWSAssetsLinkFormat,
    q{'<a href="__WebPath__/Asset/Display.html?id=__id__">__id__</a>/TITLE:#'}
    .q{,'<a href="__WebHomePath__/Asset/Display.html?id=__id__">__Name__</a>/TITLE:Name'}
    .q{,'__CustomFieldView.{AWS ID}__'}
    .q{,'__CustomFieldView.{customer}__'}
    .q{,'__CustomFieldView.{Instance Type}__'}
    .q{,'__CustomFieldView.{Engine}__'}
);

To link to this page, create a saved search to find any unlinked reserved
instance records. A search like this should find these records:

    Catalog = 'AWS Reserved Instances' AND DependedOnBy IS NULL AND ( CF.{State} = 'payment-pending' OR CF.{State} = 'active' )

After creating the search, go to the Advanced page and add this line to the Format:

'<a href="__WebPath__/AWS/LinkAsset.html?id=__id__" target="_blank">Link to Resource</a>/TITLE:Link to Resource'

That will show a column linking to the reservation linking page.

=head2 AWS IDs Used for Assets

AWS uses different identifiers with different services. This extension uses
the below mapping of AWS value to RT custom fields on assets. When a
new asset is created, the named custom fields must exist and they
will be set. On update, this value is used to load new data from
the existing assets.

=over

=item EC2

AWS Value: "Instance ID"
RT Asset CF: "AWS ID"

=item RDS

AWS Value: "DBI Resource ID"
RT Asset CF: "AWS ID"

=item EC2 Reserved Instance

AWS Value: "Reserved Instances ID"
RT Asset CF: "AWS Reserved Instance ID"

=item RDS Reserved Instance

AWS Value: "Lease ID"
RT Asset CF: "AWS Reserved Instance ID"

=back

=head1 METHODS

=cut

sub ReloadFromAWS {
    my $asset = shift;
    my $asset_id_cf = shift;
    my $reserved = shift;

    my $res_obj = FetchSingleAssetFromAWS(
                      AssetObj => $asset,
                      AWSID => $asset->FirstCustomFieldValue("$asset_id_cf"),
                      ServiceType => $asset->FirstCustomFieldValue('Service Type'),
                      Region => $asset->FirstCustomFieldValue('Region'),
                      ReservedInstances => $reserved );

    return unless $res_obj;

    UpdateAWSAsset( AssetObj => $asset, PawsObj => $res_obj,
        Service => $asset->FirstCustomFieldValue('Service Type'),
        ReservedInstances => $reserved );

    return 1;
}

sub AWSCredentials {
    my $credentials = Paws::Credential::Explicit->new(
        access_key => RT->Config->Get('AWS_ACCESS_KEY'),
        secret_key => RT->Config->Get('AWS_SECRET_KEY'),
    );
    return $credentials;
}

sub FetchSingleAssetFromAWS {
    my %args = @_;

    unless ( $args{'AWSID'} ) {
        RT->Logger->error('RT-Extension-AWS-Assets: No AWS ID found.');
        return;
    }

    unless ( $args{'ServiceType'}) {
        RT->Logger->error('RT-Extension-AWS-Assets: No Service Type found.');
        return;
    }

    if ( $args{'ServiceType'} eq 'RDS' && !$args{'ReservedInstances'} && !$args{AssetObj} ) {
        RT->Logger->error('RT-Extension-AWS-Assets: AssetObj is required for RDS assets.');
        return;
    }

    my $instance_obj;
    my $credentials = AWSCredentials();

    my $method = 'DescribeInstances'; # Default for EC2
    $method = 'DescribeDBInstances' if $args{'ServiceType'} eq 'RDS';


    if ( $args{'ServiceType'} eq 'EC2' ) {
        if ( $args{'ReservedInstances'} ) {
            eval {
                my $service = Paws->service($args{'ServiceType'}, credentials => $credentials, region => $args{'Region'});

                # No paging for reserved instance API
                my $res = $service->DescribeReservedInstances(ReservedInstancesIds => [$args{'AWSID'}]);
                $instance_obj = $res->ReservedInstances->[0];
            };
        }
        else {
            eval {
                my $service = Paws->service($args{'ServiceType'}, credentials => $credentials, region => $args{'Region'});
                my $res = $service->$method(InstanceIds => [$args{'AWSID'}]);
                $instance_obj = $res->Reservations->[0]->Instances->[0];
            };
        }
    }
    elsif ( $args{'ServiceType'} eq 'RDS' ) {
        if ( $args{'ReservedInstances'} ) {
            eval {
                my $service = Paws->service($args{'ServiceType'}, credentials => $credentials, region => $args{'Region'});

                my $res = $service->DescribeReservedDBInstances(LeaseId => $args{'AWSID'});
                $instance_obj = $res->ReservedDBInstances->[0];
            };
        }
        else {
            eval {
                my $service = Paws->service($args{'ServiceType'}, credentials => $credentials, region => $args{'Region'});
                # Doesn't work now, not sure why, Values are passed as null
#                my $res = $service->DescribeDBInstances(Filters => [{ Name => 'dbi-resource-id', Values => ["foo", "bar"] }]);
                my $res = $service->DescribeDBInstances(DBInstanceIdentifier => $args{'AssetObj'}->Name);
                $instance_obj = $res->DBInstances->[0];
            };
        }
    }

    if ( $@ ) {
        RT->Logger->error("RT-Extension-AWS-Assets: Failed call to AWS: " . $@);
    }

    return $instance_obj;
}

# Token can be NextToken for EC2 or Marker for RDS

sub FetchMultipleAssetsFromAWS {
    my %args = (
        MaxResults => 100,
        Token => undef,
        @_,
    );

    unless ( $args{'Region'} ) {
        RT->Logger->error('RT-Extension-AWS-Assets: No Region found.');
        return;
    }

    unless ( $args{'ServiceType'}) {
        RT->Logger->error('RT-Extension-AWS-Assets: No Service Type found.');
        return;
    }

    my $aws_resources;
    my $credentials = AWSCredentials();
    my $res;
    my $token;

    if ( $args{'ServiceType'} eq 'EC2' ) {
        if ( $args{'ReservedInstances'} ) {
            eval {
                my $service = Paws->service($args{'ServiceType'}, credentials => $credentials, region => $args{'Region'});

                # No paging for reserved instance API
                $res = $service->DescribeReservedInstances();
                $aws_resources = $res->ReservedInstances;
            };
        }
        else {
            eval {
                my $service = Paws->service($args{'ServiceType'}, credentials => $credentials, region => $args{'Region'});

                if ( $args{'Token'} ) {
                    $res = $service->DescribeInstances(MaxResults => $args{'MaxResults'}, NextToken => $args{'Token'});
                }
                else {
                    $res = $service->DescribeInstances(MaxResults => $args{'MaxResults'});
                }

                $aws_resources = $res->Reservations;
                $token = $res->NextToken;
            };
        }
    }
    elsif ( $args{'ServiceType'} eq 'RDS' ) {
        if ( $args{'ReservedInstances'} ) {
            eval {
                my $service = Paws->service($args{'ServiceType'}, credentials => $credentials, region => $args{'Region'});

                # The RDS version does have paging, but leaving it out for consistency with EC2
                # Set Max to the Max allowed. Will need to update when we go over 100 in a region
                $res = $service->DescribeReservedDBInstances(MaxRecords => 100);
                $aws_resources = $res->ReservedDBInstances;
            };
        }
        else {
            eval {
                my $service = Paws->service($args{'ServiceType'}, credentials => $credentials, region => $args{'Region'});

                if ( $args{'Token'} ) {
                    $res = $service->DescribeDBInstances(MaxRecords => $args{'MaxResults'}, Marker => $args{'Token'});
                }
                else {
                    $res = $service->DescribeDBInstances(MaxRecords => $args{'MaxResults'});
                }

                $aws_resources = $res->DBInstances;
                $token = $res->Marker;
            };
        }
    }

    if ( $@ ) {
        RT->Logger->error("RT-Extension-AWS-Assets: Failed call to AWS: " . $@);
    }

    return ($aws_resources, $token);
}

=pod

Accept a loaded RT::Asset object and a Paws Instance object.

=cut

sub UpdateAWSAsset {
    my %args = @_;
    my $asset = $args{'AssetObj'};
    my $paws_obj = $args{'PawsObj'};
    my $service = $args{'Service'};
    my $reserved = $args{'ReservedInstances'};

    # For looking up the field mapping, use RI (Reserved Instances) for the service
    # rather than the AWS service the RI is for.
    my $config_key = $service;
    $config_key .= ':RI' if $reserved;

    foreach my $aws_value ( @{ RT->Config->Get('AWSAssetsUpdateFields')->{$config_key} } ) {

        my $submethod;
        my $cf_name = $aws_value;
        ($submethod, $cf_name) = split(':', $aws_value) if $aws_value =~ /:/;

        my $method = $cf_name;
        $method =~ s/\s+//g;

        # Fixup some special cases
        if ( $service eq 'RDS' ) {
            $method = 'DBInstanceIdentifier' if ( $cf_name eq 'Name' );
            $method = 'DBInstanceClass' if ( $cf_name eq 'Instance Type' );
        }

        if ( $reserved ) {
            $method = 'ProductDescription' if ( $cf_name eq 'Platform' );
            $method = 'InstanceTenancy' if ( $cf_name eq 'Tenancy' );
            $method = 'Start' if ( $service eq 'EC2' && $cf_name eq 'Reservation Start' );
            $method = 'StartTime' if ( $service eq 'RDS' && $cf_name eq 'Reservation Start' );
            $method = 'End' if ( $cf_name eq 'Reservation End' );
            $method = 'InstanceType' if ( $service eq 'EC2' && $cf_name eq 'Name' );
            $method = 'ReservedDBInstanceId' if ( $service eq 'RDS' && $cf_name eq 'Name' );
            $method = 'LeaseId' if ( $service eq 'RDS' && $cf_name eq 'AWS Reserved Instance ID' );
        }

        # Fixups (mostly) done, start setting values
        my ($ret, $msg);

        # RDS RIs don't provide EndTime as a value via the API, even though EC2 does
        # Calculate it here using Start and Duration.
        if ( $reserved && $service eq 'RDS' && $cf_name eq 'Reservation End' ) {
            my $end = RT::Date->new(RT->SystemUser);
            $end->Set( Format => 'unknown', Value => $paws_obj->StartTime );
            $end->AddSeconds($paws_obj->Duration);

            ($ret, $msg) = $asset->AddCustomFieldValue( Field => $cf_name, Value => $end->ISO );
            next;
        }

        if ( $submethod && ( $submethod eq 'Tags' || $submethod eq 'TagList' ) ) {
            foreach my $tag ( @{ $paws_obj->$submethod } ) {
                if ( $tag->Key eq $cf_name ) {
                    if ( $cf_name eq 'Name' ) {
                        # Name isn't a CF but a core asset field
                        ($ret, $msg) = $asset->SetName($tag->Value);
                        last;
                    }
                    else {
                        ($ret, $msg) = $asset->AddCustomFieldValue( Field => $cf_name, Value => $tag->Value );
                        last;
                    }
                }
            }
        }
        elsif ( $cf_name eq 'Name' ) {
            # Name isn't a CF but a core asset field
            ($ret, $msg) = $asset->SetName($paws_obj->$method);
        }
        elsif ( $submethod ) {
            ($ret, $msg) = $asset->AddCustomFieldValue( Field => $cf_name, Value => $paws_obj->$submethod->$method );
        }
        elsif ( $cf_name eq 'Platform' ) {
            # Paws currently defaults Platform to Windows. All of our systems are
            # currently "Linux/UNIX" so set that.
            ($ret, $msg) = $asset->AddCustomFieldValue( Field => $cf_name, Value => "Linux/UNIX" );
        }
        else {
            ($ret, $msg) = $asset->AddCustomFieldValue( Field => $cf_name, Value => $paws_obj->$method );
        }

        if ( $msg && $msg =~ /That is already the current value/ ) {
            # Don't log an error for the "current value" message
            $ret = 1;
        }

        unless ( $ret ) {
            RT->Logger->error("RT-Extension-AWS-Assets: On asset " . $asset->Id . " unable to update CF $cf_name: $msg");
        }
    }

    return;
}

sub InsertAWSAssets {
    my %args = (
        @_
    );

    my $catalog = RT->Config->Get('AWSAssetsInstanceCatalog');
    $catalog = RT->Config->Get('AWSAssetsReservedInstancesCatalog') if $args{'ReservedInstances'};

    my $asset_id_cf = 'AWS ID';
    $asset_id_cf = 'AWS Reserved Instance ID' if $args{'ReservedInstances'};

    my @assets;
    for my $resource ( @{ $args{'AWSResources'} } ) {
        my $resource_id;
        my $instance;
        my $count = 1; # Regular EC2 and RDS are always 1

        if ( $args{'ServiceType'} eq 'EC2' ) {
            if ( $args{'ReservedInstances'} ) {
                $instance = $resource;
                $resource_id = $resource->ReservedInstancesId;
                $count = $instance->InstanceCount;
            }
            else {
                $instance = $resource->Instances->[0];
                $resource_id = $resource->Instances->[0]->InstanceId;
            }
        }
        elsif ( $args{'ServiceType'} eq 'RDS' ) {
            if ( $args{'ReservedInstances'} ) {
                $instance = $resource;
                $resource_id = $resource->LeaseId;
                $count = $instance->DBInstanceCount;
            }
            else {
                $instance = $resource;
                $resource_id = $resource->DbiResourceId;
            }
        }

        # Load as system user to find all possible assets to avoid
        # trying to create a duplicate CurrentUser might not be able to see
        my $assets = RT::Assets->new( RT->SystemUser );
        my ($ok, $msg) = $assets->FromSQL("Catalog = '" . $catalog .
            "' AND 'CF.{$asset_id_cf}' = '" . $resource_id . "'");

        my $asset_exists = 0;
        $asset_exists = 1 if $assets->Count >= $count;

        # Asset already exists, next
        if ( $asset_exists ) {
            RT->Logger->debug("Asset for " . $resource_id . " exists, skipping");
            push @assets, $assets->First;
            next;
        }

        # Create an empty asset to more easily load the CF ids
        my $void_asset = RT::Asset->new($args{'CurrentUser'});

        my $aws_id_cf;
        if ( $args{'ReservedInstances'} ) {
            $aws_id_cf = LoadCustomFieldByIdentifier($void_asset, 'AWS Reserved Instance ID', $catalog, $args{'CurrentUser'});
        }
        else {
            $aws_id_cf = LoadCustomFieldByIdentifier($void_asset, 'AWS ID', $catalog, $args{'CurrentUser'});
        }

        unless ( $aws_id_cf && $aws_id_cf->Id ) {
            RT->Logger->error('Unable to load AWS ID CF for asset');
            next;
        }

        my $region_cf = LoadCustomFieldByIdentifier($void_asset, 'Region', $catalog, $args{'CurrentUser'});
        unless ( $region_cf && $region_cf->Id ) {
            RT->Logger->error('Unable to load Region CF for asset');
            next;
        }

        my $service_type_cf = LoadCustomFieldByIdentifier($void_asset, 'Service Type', $catalog, $args{'CurrentUser'});
        unless ( $service_type_cf && $service_type_cf->Id ) {
            RT->Logger->error('Unable to load Service Type CF for asset');
            next;
        }

        my $created = 0;
        while ( $created < $count ) {
            # Try to create a new asset with AWS ID, Region, Service Type

            my $new_asset = RT::Asset->new($args{'CurrentUser'});
            ($ok, $msg) = $new_asset->Create(
                Catalog => $catalog,
                'CustomField-' . $aws_id_cf->Id => $resource_id,
                'CustomField-' . $region_cf->Id => $args{'Region'},
                'CustomField-' . $service_type_cf->Id => $args{'ServiceType'},
            );
            $created++;

            if ( not $ok ) {
                RT->Logger->error('Unable to create new asset for instance ' . $resource_id . ' ' . $msg);
                next;
            }
            else {
                RT->Logger->debug('Created asset ' . $new_asset->Id . ' for instance ' . $resource_id);
            }

            # Call UpdateAWSAsset to load remaining CFs
            UpdateAWSAsset( AssetObj => $new_asset, PawsObj => $instance,
                Service => $args{'ServiceType'}, ReservedInstances => $args{'ReservedInstances'});
            push @assets, $new_asset;
        }
    }
    return @assets;
}

sub UpdateAWSAssets {
    my %args = (
        @_
    );

    my $catalog = RT->Config->Get('AWSAssetsInstanceCatalog');
    $catalog = RT->Config->Get('AWSAssetsReservedInstancesCatalog') if $args{'ReservedInstances'};

    my $asset_id_cf = 'AWS ID';
    $asset_id_cf = 'AWS Reserved Instance ID' if $args{'ReservedInstances'};

    for my $resource ( @{ $args{'AWSResources'} } ) {
        my $resource_id;
        my $instance;
        my $count = 1; # Regular EC2 and RDS are always 1

        if ( $args{'ServiceType'} eq 'EC2' ) {
            if ( $args{'ReservedInstances'} ) {
                $instance = $resource;
                $resource_id = $resource->ReservedInstancesId;
                $count = $instance->InstanceCount;
            }
            else {
                $instance = $resource->Instances->[0];
                $resource_id = $resource->Instances->[0]->InstanceId;
            }
        }
        elsif ( $args{'ServiceType'} eq 'RDS' ) {
            if ( $args{'ReservedInstances'} ) {
                $instance = $resource;
                $resource_id = $resource->LeaseId;
                $count = $instance->DBInstanceCount;
            }
            else {
                $instance = $resource;
                $resource_id = $resource->DbiResourceId;
            }
        }

        # Load as system user to find all possible assets to avoid
        # trying to create a duplicate CurrentUser might not be able to see
        my $assets = RT::Assets->new( RT->SystemUser );
        my ($ok, $msg) = $assets->FromSQL("Catalog = '" . $catalog .
            "' AND 'CF.{$asset_id_cf}' = '" . $resource_id . "'");

        my $asset_found = 0;
        $asset_found = 1 if $assets->Count;

        # New purchased reserved db instance's Lease ID could be empty
        if ( !$asset_found && $args{'ServiceType'} eq 'RDS' && $args{'ReservedInstances'} ) {
            my $name = $resource->ReservedDBInstanceId;
            $assets->FromSQL(qq<Catalog = '$catalog' AND 'CF.{$asset_id_cf}' IS NULL AND Name = '$name'>);
            $asset_found = 1 if $assets->Count;
        }

        unless ( $asset_found ) {
            RT->Logger->debug("No asset found for " . $resource_id . ", skipping");
            next;
        }

        $assets->RedoSearch;
        while ( my $asset = $assets->Next ) {
            UpdateAWSAsset( AssetObj => $asset, PawsObj => $instance,
                Service => $args{'ServiceType'}, ReservedInstances => $args{'ReservedInstances'});
            RT->Logger->debug('Updated asset ' . $asset->Id . ' ' . $asset->Name);
            $args{updated}{$asset->Id} = 1 if $args{updated};
        }
    }
    return;
}

# We don't have a catalog in the empty asset object when we want to
# load the CFs, so create a custom version of the loader that accepts
# catalog as a parameter.

sub LoadCustomFieldByIdentifier {
    my $asset = shift;
    my $field = shift;
    my $catalog = shift;
    my $current_user = shift;

    my $cf = RT::CustomField->new( $current_user );
    $cf->SetContextObject( $asset );
    my ($ok, $msg) = $cf->LoadByNameAndCatalog( Name => $field, Catalog => $catalog );
    return $cf;
}

=head1 AUTHOR

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-AWS-Assets@rt.cpan.org">bug-RT-Extension-AWS-Assets@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-AWS-Assets">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-AWS-Assets@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-AWS-Assets

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
