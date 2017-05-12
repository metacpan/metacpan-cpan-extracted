package Net::Amazon::Utils::Regions;

use strict;

=head1 NAME

Net::Amazon::Utils::Regions - Data for Net::Amazon::Utils::Regions.
Generated from L<https://raw.githubusercontent.com/aws/aws-sdk-android-v2/master/src/com/amazonaws/regions/regions.xml>

=head1 VERSION

Version 0.01

=cut

our $VERSION = '200140730';

=head2 get_regions_data

Returns the structure of regions.xml.

=cut

sub get_regions_data {
	my $regions={
  'Services' => {
    'Service' => {
      'dynamodb' => {
        'FullName' => 'Amazon DynamoDB',
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1',
          'us-gov-west-1'
        ]
      },
      'sqs' => {
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1',
          'us-gov-west-1'
        ],
        'FullName' => 'Amazon Simple Queue Service'
      },
      'sns' => {
        'FullName' => 'Amazon Simple Notification Service',
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1',
          'us-gov-west-1'
        ]
      },
      'cloudfront' => {
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1'
        ],
        'FullName' => 'Amazon CloudFront'
      },
      'opsworks' => {
        'FullName' => 'AWS OpsWorks',
        'RegionName' => 'us-east-1'
      },
      'elasticloadbalancing' => {
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1',
          'us-gov-west-1'
        ],
        'FullName' => 'Elastic Load Balancing'
      },
      'elasticmapreduce' => {
        'FullName' => 'Amazon Elastic MapReduce',
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1',
          'us-gov-west-1'
        ]
      },
      'email' => {
        'FullName' => 'Amazon Simple Email Service',
        'RegionName' => 'us-east-1'
      },
      'monitoring' => {
        'FullName' => 'Amazon CloudWatch',
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1',
          'us-gov-west-1'
        ]
      },
      'route53' => {
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1'
        ],
        'FullName' => 'Amazon Route 53'
      },
      'elasticache' => {
        'FullName' => 'Amazon ElastiCache',
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1'
        ]
      },
      'autoscaling' => {
        'FullName' => 'Auto Scaling',
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1',
          'us-gov-west-1'
        ]
      },
      'datapipeline' => {
        'RegionName' => 'us-east-1',
        'FullName' => 'AWS Data Pipeline'
      },
      'cloudsearch' => {
        'FullName' => 'Amazon CloudSearch',
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-southeast-1',
          'eu-west-1'
        ]
      },
      'rds' => {
        'FullName' => 'Amazon Relational Database Service',
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1',
          'us-gov-west-1'
        ]
      },
      'kinesis' => {
        'FullName' => 'Amazon Kinesis',
        'RegionName' => 'us-east-1'
      },
      'iam' => {
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1',
          'us-gov-west-1'
        ],
        'FullName' => 'AWS Identity & Access Management'
      },
      'redshift' => {
        'FullName' => 'Amazon Redshift',
        'RegionName' => [
          'us-east-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'eu-west-1'
        ]
      },
      'elasticbeanstalk' => {
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1'
        ],
        'FullName' => 'AWS Elastic Beanstalk'
      },
      'cloudformation' => {
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1'
        ],
        'FullName' => 'Amazon CloudFormation'
      },
      'support' => {
        'FullName' => 'AWS Support',
        'RegionName' => 'us-east-1'
      },
      'directconnect' => {
        'FullName' => 'AWS Direct Connect',
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1'
        ]
      },
      'swf' => {
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1',
          'us-gov-west-1'
        ],
        'FullName' => 'Amazon Simple Workflow Service'
      },
      'importexport' => {
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1'
        ],
        'FullName' => 'AWS Import/Export'
      },
      'storagegateway' => {
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1'
        ],
        'FullName' => 'AWS Storage Gateway'
      },
      'elastictranscoder' => {
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'eu-west-1'
        ],
        'FullName' => 'Amazon Elastic Transcoder'
      },
      'glacier' => {
        'FullName' => 'Amazon Glacier',
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-2',
          'eu-west-1'
        ]
      },
      'cloudtrail' => {
        'FullName' => 'AWS CloudTrail',
        'RegionName' => [
          'us-east-1',
          'us-west-2'
        ]
      },
      'ec2' => {
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1',
          'us-gov-west-1'
        ],
        'FullName' => 'Amazon Elastic Compute Cloud'
      },
      'sts' => {
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1',
          'us-gov-west-1'
        ],
        'FullName' => 'AWS Security Token Service'
      },
      'sdb' => {
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1'
        ],
        'FullName' => 'Amazon SimpleDB'
      },
      's3' => {
        'FullName' => 'Amazon Simple Storage Service',
        'RegionName' => [
          'us-east-1',
          'us-west-1',
          'us-west-2',
          'ap-northeast-1',
          'ap-southeast-1',
          'ap-southeast-2',
          'sa-east-1',
          'eu-west-1',
          'us-gov-west-1'
        ]
      }
    }
  },
  'Regions' => {
    'Region' => {
      'eu-west-1' => {
        'Endpoint' => {
          'monitoring' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'monitoring.eu-west-1.amazonaws.com'
          },
          'glacier' => {
            'Hostname' => 'glacier.eu-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'elastictranscoder' => {
            'Hostname' => 'elastictranscoder.eu-west-1.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'storagegateway' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'storagegateway.eu-west-1.amazonaws.com'
          },
          'elasticloadbalancing' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'elasticloadbalancing.eu-west-1.amazonaws.com'
          },
          'elasticmapreduce' => {
            'Hostname' => 'elasticmapreduce.eu-west-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'sns' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'sns.eu-west-1.amazonaws.com'
          },
          'importexport' => {
            'Hostname' => 'importexport.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'cloudfront' => {
            'Hostname' => 'cloudfront.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'directconnect' => {
            'Hostname' => 'directconnect.eu-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'swf' => {
            'Hostname' => 'swf.eu-west-1.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'dynamodb' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'dynamodb.eu-west-1.amazonaws.com'
          },
          'sqs' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'sqs.eu-west-1.amazonaws.com'
          },
          's3' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 's3-eu-west-1.amazonaws.com'
          },
          'redshift' => {
            'Hostname' => 'redshift.eu-west-1.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'cloudformation' => {
            'Hostname' => 'cloudformation.eu-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'elasticbeanstalk' => {
            'Hostname' => 'elasticbeanstalk.eu-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'iam' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'iam.amazonaws.com'
          },
          'sdb' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'sdb.eu-west-1.amazonaws.com'
          },
          'rds' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'rds.eu-west-1.amazonaws.com'
          },
          'sts' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'sts.amazonaws.com'
          },
          'cloudsearch' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'cloudsearch.eu-west-1.amazonaws.com'
          },
          'ec2' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'ec2.eu-west-1.amazonaws.com'
          },
          'autoscaling' => {
            'Hostname' => 'autoscaling.eu-west-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'route53' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'route53.amazonaws.com'
          },
          'elasticache' => {
            'Hostname' => 'elasticache.eu-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          }
        }
      },
      'ap-northeast-1' => {
        'Endpoint' => {
          's3' => {
            'Hostname' => 's3-ap-northeast-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'cloudformation' => {
            'Hostname' => 'cloudformation.ap-northeast-1.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'elasticbeanstalk' => {
            'Hostname' => 'elasticbeanstalk.ap-northeast-1.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'redshift' => {
            'Hostname' => 'redshift.ap-northeast-1.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'iam' => {
            'Hostname' => 'iam.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'sdb' => {
            'Hostname' => 'sdb.ap-northeast-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'sts' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'sts.amazonaws.com'
          },
          'rds' => {
            'Hostname' => 'rds.ap-northeast-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'ec2' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'ec2.ap-northeast-1.amazonaws.com'
          },
          'autoscaling' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'autoscaling.ap-northeast-1.amazonaws.com'
          },
          'elasticache' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'elasticache.ap-northeast-1.amazonaws.com'
          },
          'route53' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'route53.amazonaws.com'
          },
          'monitoring' => {
            'Hostname' => 'monitoring.ap-northeast-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'elastictranscoder' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'elastictranscoder.ap-northeast-1.amazonaws.com'
          },
          'glacier' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'glacier.ap-northeast-1.amazonaws.com'
          },
          'storagegateway' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'storagegateway.ap-northeast-1.amazonaws.com'
          },
          'elasticmapreduce' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'elasticmapreduce.ap-northeast-1.amazonaws.com'
          },
          'elasticloadbalancing' => {
            'Hostname' => 'elasticloadbalancing.ap-northeast-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'importexport' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'importexport.amazonaws.com'
          },
          'cloudfront' => {
            'Hostname' => 'cloudfront.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'sns' => {
            'Hostname' => 'sns.ap-northeast-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'swf' => {
            'Hostname' => 'swf.ap-northeast-1.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'directconnect' => {
            'Hostname' => 'directconnect.ap-northeast-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'sqs' => {
            'Hostname' => 'sqs.ap-northeast-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'dynamodb' => {
            'Hostname' => 'dynamodb.ap-northeast-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          }
        }
      },
      'ap-southeast-1' => {
        'Endpoint' => {
          's3' => {
            'Hostname' => 's3-ap-southeast-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'redshift' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'redshift.ap-southeast-1.amazonaws.com'
          },
          'cloudformation' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'cloudformation.ap-southeast-1.amazonaws.com'
          },
          'elasticbeanstalk' => {
            'Hostname' => 'elasticbeanstalk.ap-southeast-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'iam' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'iam.amazonaws.com'
          },
          'sdb' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'sdb.ap-southeast-1.amazonaws.com'
          },
          'rds' => {
            'Hostname' => 'rds.ap-southeast-1.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'sts' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'sts.amazonaws.com'
          },
          'cloudsearch' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'cloudsearch.ap-southeast-1.amazonaws.com'
          },
          'ec2' => {
            'Hostname' => 'ec2.ap-southeast-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'autoscaling' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'autoscaling.ap-southeast-1.amazonaws.com'
          },
          'route53' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'route53.amazonaws.com'
          },
          'elasticache' => {
            'Hostname' => 'elasticache.ap-southeast-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'monitoring' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'monitoring.ap-southeast-1.amazonaws.com'
          },
          'elastictranscoder' => {
            'Hostname' => 'elastictranscoder.ap-southeast-1.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'storagegateway' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'storagegateway.ap-southeast-1.amazonaws.com'
          },
          'elasticloadbalancing' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'elasticloadbalancing.ap-southeast-1.amazonaws.com'
          },
          'elasticmapreduce' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'elasticmapreduce.ap-southeast-1.amazonaws.com'
          },
          'sns' => {
            'Hostname' => 'sns.ap-southeast-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'cloudfront' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'cloudfront.amazonaws.com'
          },
          'importexport' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'importexport.amazonaws.com'
          },
          'directconnect' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'directconnect.ap-southeast-1.amazonaws.com'
          },
          'swf' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'swf.ap-southeast-1.amazonaws.com'
          },
          'dynamodb' => {
            'Hostname' => 'dynamodb.ap-southeast-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'sqs' => {
            'Hostname' => 'sqs.ap-southeast-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          }
        }
      },
      'us-west-1' => {
        'Endpoint' => {
          'swf' => {
            'Hostname' => 'swf.us-west-1.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'directconnect' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'directconnect.us-west-1.amazonaws.com'
          },
          'cloudfront' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'cloudfront.amazonaws.com'
          },
          'importexport' => {
            'Hostname' => 'importexport.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'sns' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'sns.us-west-1.amazonaws.com'
          },
          'sqs' => {
            'Hostname' => 'sqs.us-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'dynamodb' => {
            'Hostname' => 'dynamodb.us-west-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'elastictranscoder' => {
            'Hostname' => 'elastictranscoder.us-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'glacier' => {
            'Hostname' => 'glacier.us-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'monitoring' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'monitoring.us-west-1.amazonaws.com'
          },
          'elasticmapreduce' => {
            'Hostname' => 'elasticmapreduce.us-west-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'elasticloadbalancing' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'elasticloadbalancing.us-west-1.amazonaws.com'
          },
          'storagegateway' => {
            'Hostname' => 'storagegateway.us-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'ec2' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'ec2.us-west-1.amazonaws.com'
          },
          'cloudsearch' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'cloudsearch.us-west-1.amazonaws.com'
          },
          'rds' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'rds.us-west-1.amazonaws.com'
          },
          'sts' => {
            'Hostname' => 'sts.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'elasticache' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'elasticache.us-west-1.amazonaws.com'
          },
          'route53' => {
            'Hostname' => 'route53.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'autoscaling' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'autoscaling.us-west-1.amazonaws.com'
          },
          'elasticbeanstalk' => {
            'Hostname' => 'elasticbeanstalk.us-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'cloudformation' => {
            'Hostname' => 'cloudformation.us-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          's3' => {
            'Hostname' => 's3-us-west-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'sdb' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'sdb.us-west-1.amazonaws.com'
          },
          'iam' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'iam.amazonaws.com'
          }
        }
      },
      'sa-east-1' => {
        'Endpoint' => {
          'elasticbeanstalk' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'elasticbeanstalk.sa-east-1.amazonaws.com'
          },
          'cloudformation' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'cloudformation.sa-east-1.amazonaws.com'
          },
          's3' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 's3-sa-east-1.amazonaws.com'
          },
          'sdb' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'sdb.sa-east-1.amazonaws.com'
          },
          'iam' => {
            'Hostname' => 'iam.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'ec2' => {
            'Hostname' => 'ec2.sa-east-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'sts' => {
            'Hostname' => 'sts.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'rds' => {
            'Hostname' => 'rds.sa-east-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'route53' => {
            'Hostname' => 'route53.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'elasticache' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'elasticache.sa-east-1.amazonaws.com'
          },
          'autoscaling' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'autoscaling.sa-east-1.amazonaws.com'
          },
          'monitoring' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'monitoring.sa-east-1.amazonaws.com'
          },
          'elasticloadbalancing' => {
            'Hostname' => 'elasticloadbalancing.sa-east-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'elasticmapreduce' => {
            'Hostname' => 'elasticmapreduce.sa-east-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'storagegateway' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'storagegateway.sa-east-1.amazonaws.com'
          },
          'directconnect' => {
            'Hostname' => 'directconnect.sa-east-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'swf' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'swf.sa-east-1.amazonaws.com'
          },
          'sns' => {
            'Hostname' => 'sns.sa-east-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'importexport' => {
            'Hostname' => 'importexport.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'cloudfront' => {
            'Hostname' => 'cloudfront.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'dynamodb' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'dynamodb.sa-east-1.amazonaws.com'
          },
          'sqs' => {
            'Hostname' => 'sqs.sa-east-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          }
        }
      },
      'us-west-2' => {
        'Endpoint' => {
          'storagegateway' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'storagegateway.us-west-2.amazonaws.com'
          },
          'elasticmapreduce' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'elasticmapreduce.us-west-2.amazonaws.com'
          },
          'elasticloadbalancing' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'elasticloadbalancing.us-west-2.amazonaws.com'
          },
          'monitoring' => {
            'Hostname' => 'monitoring.us-west-2.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'glacier' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'glacier.us-west-2.amazonaws.com'
          },
          'elastictranscoder' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'elastictranscoder.us-west-2.amazonaws.com'
          },
          'sqs' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'sqs.us-west-2.amazonaws.com'
          },
          'dynamodb' => {
            'Hostname' => 'dynamodb.us-west-2.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'cloudfront' => {
            'Hostname' => 'cloudfront.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'importexport' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'importexport.amazonaws.com'
          },
          'sns' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'sns.us-west-2.amazonaws.com'
          },
          'swf' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'swf.us-west-2.amazonaws.com'
          },
          'directconnect' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'directconnect.us-west-2.amazonaws.com'
          },
          'iam' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'iam.amazonaws.com'
          },
          'sdb' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'sdb.us-west-2.amazonaws.com'
          },
          's3' => {
            'Hostname' => 's3-us-west-2.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'cloudformation' => {
            'Hostname' => 'cloudformation.us-west-2.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'elasticbeanstalk' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'elasticbeanstalk.us-west-2.amazonaws.com'
          },
          'redshift' => {
            'Hostname' => 'redshift.us-west-2.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'autoscaling' => {
            'Hostname' => 'autoscaling.us-west-2.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'elasticache' => {
            'Hostname' => 'elasticache.us-west-2.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'cloudtrail' => {
            'Hostname' => 'cloudtrail.us-west-2.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'route53' => {
            'Hostname' => 'route53.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'rds' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'rds.us-west-2.amazonaws.com'
          },
          'sts' => {
            'Hostname' => 'sts.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'ec2' => {
            'Hostname' => 'ec2.us-west-2.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'cloudsearch' => {
            'Hostname' => 'cloudsearch.us-west-2.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          }
        }
      },
      'us-east-1' => {
        'Endpoint' => {
          'sqs' => {
            'Hostname' => 'sqs.us-east-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'dynamodb' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'dynamodb.us-east-1.amazonaws.com'
          },
          'opsworks' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'opsworks.us-east-1.amazonaws.com'
          },
          'cloudfront' => {
            'Hostname' => 'cloudfront.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'sns' => {
            'Hostname' => 'sns.us-east-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'elasticmapreduce' => {
            'Hostname' => 'elasticmapreduce.us-east-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'elasticloadbalancing' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'elasticloadbalancing.us-east-1.amazonaws.com'
          },
          'email' => {
            'Hostname' => 'email.us-east-1.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'monitoring' => {
            'Hostname' => 'monitoring.us-east-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'elasticache' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'elasticache.us-east-1.amazonaws.com'
          },
          'route53' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'route53.amazonaws.com'
          },
          'datapipeline' => {
            'Hostname' => 'datapipeline.us-east-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'autoscaling' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'autoscaling.us-east-1.amazonaws.com'
          },
          'cloudsearch' => {
            'Hostname' => 'cloudsearch.us-east-1.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'rds' => {
            'Hostname' => 'rds.us-east-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'kinesis' => {
            'Hostname' => 'kinesis.us-east-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'iam' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'iam.amazonaws.com'
          },
          'elasticbeanstalk' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'elasticbeanstalk.us-east-1.amazonaws.com'
          },
          'cloudformation' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'cloudformation.us-east-1.amazonaws.com'
          },
          'support' => {
            'Hostname' => 'support.us-east-1.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'redshift' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'redshift.us-east-1.amazonaws.com'
          },
          'swf' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'swf.us-east-1.amazonaws.com'
          },
          'directconnect' => {
            'Hostname' => 'directconnect.us-east-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'importexport' => {
            'Hostname' => 'importexport.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'storagegateway' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'storagegateway.us-east-1.amazonaws.com'
          },
          'glacier' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'glacier.us-east-1.amazonaws.com'
          },
          'elastictranscoder' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'elastictranscoder.us-east-1.amazonaws.com'
          },
          'cloudtrail' => {
            'Hostname' => 'cloudtrail.us-east-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'ec2' => {
            'Hostname' => 'ec2.us-east-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'sts' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'sts.amazonaws.com'
          },
          'sdb' => {
            'Hostname' => 'sdb.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          's3' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 's3.amazonaws.com'
          }
        }
      },
      'us-gov-west-1' => {
        'Endpoint' => {
          'iam' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'iam.us-gov.amazonaws.com'
          },
          'elasticloadbalancing' => {
            'Hostname' => 'elasticloadbalancing.us-gov-west-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'elasticmapreduce' => {
            'Hostname' => 'elasticmapreduce.us-gov-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          's3' => {
            'Hostname' => 's3-us-gov-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'monitoring' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'monitoring.us-gov-west-1.amazonaws.com'
          },
          'autoscaling' => {
            'Hostname' => 'autoscaling.us-gov-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'dynamodb' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'dynamodb.us-gov-west-1.amazonaws.com'
          },
          'sqs' => {
            'Hostname' => 'sqs.us-gov-west-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'sns' => {
            'Hostname' => 'sns.us-gov-west-1.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'sts' => {
            'Hostname' => 'sts.us-gov-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'rds' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'rds.us-gov-west-1.amazonaws.com'
          },
          'ec2' => {
            'Hostname' => 'ec2.us-gov-west-1.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'swf' => {
            'Hostname' => 'swf.us-gov-west-1.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          }
        }
      },
      'ap-southeast-2' => {
        'Endpoint' => {
          'monitoring' => {
            'Hostname' => 'monitoring.ap-southeast-2.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'glacier' => {
            'Hostname' => 'glacier.ap-southeast-2.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'storagegateway' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'storagegateway.ap-southeast-2.amazonaws.com'
          },
          'elasticloadbalancing' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'elasticloadbalancing.ap-southeast-2.amazonaws.com'
          },
          'elasticmapreduce' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'elasticmapreduce.ap-southeast-2.amazonaws.com'
          },
          'sns' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'sns.ap-southeast-2.amazonaws.com'
          },
          'cloudfront' => {
            'Https' => 'true',
            'Http' => 'true',
            'Hostname' => 'cloudfront.amazonaws.com'
          },
          'importexport' => {
            'Hostname' => 'importexport.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'directconnect' => {
            'Hostname' => 'directconnect.ap-southeast-2.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'swf' => {
            'Https' => 'true',
            'Http' => 'false',
            'Hostname' => 'swf.ap-southeast-2.amazonaws.com'
          },
          'dynamodb' => {
            'Hostname' => 'dynamodb.ap-southeast-2.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'sqs' => {
            'Hostname' => 'sqs.ap-southeast-2.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          's3' => {
            'Hostname' => 's3-ap-southeast-2.amazonaws.com',
            'Http' => 'true',
            'Https' => 'true'
          },
          'redshift' => {
            'Hostname' => 'redshift.ap-southeast-2.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'elasticbeanstalk' => {
            'Hostname' => 'elasticbeanstalk.ap-southeast-2.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'cloudformation' => {
            'Http' => 'false',
            'Https' => 'true',
            'Hostname' => 'cloudformation.ap-southeast-2.amazonaws.com'
          },
          'iam' => {
            'Hostname' => 'iam.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'sdb' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'sdb.ap-southeast-2.amazonaws.com'
          },
          'sts' => {
            'Hostname' => 'sts.amazonaws.com',
            'Https' => 'true',
            'Http' => 'false'
          },
          'rds' => {
            'Hostname' => 'rds.ap-southeast-2.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'ec2' => {
            'Hostname' => 'ec2.ap-southeast-2.amazonaws.com',
            'Https' => 'true',
            'Http' => 'true'
          },
          'autoscaling' => {
            'Http' => 'true',
            'Https' => 'true',
            'Hostname' => 'autoscaling.ap-southeast-2.amazonaws.com'
          },
          'route53' => {
            'Hostname' => 'route53.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          },
          'elasticache' => {
            'Hostname' => 'elasticache.ap-southeast-2.amazonaws.com',
            'Http' => 'false',
            'Https' => 'true'
          }
        }
      }
    }
  }
}
;
	return $regions;
}
return 1;
