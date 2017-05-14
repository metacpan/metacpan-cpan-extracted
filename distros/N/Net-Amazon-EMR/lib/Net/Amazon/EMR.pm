package Net::Amazon::EMR;

use Moose;
with 'MooseX::Log::Log4perl';
use MooseX::Params::Validate;

use Log::Log4perl qw(:easy);
use Exception::Class (
    'Net::Amazon::EMR::Exception' => { fields => [ qw/error code type/ ] },
    );

use XML::Simple;
use LWP::UserAgent;
use LWP::Protocol::https;
use Digest::SHA qw(hmac_sha256);
use URI;
use MIME::Base64 qw(encode_base64 decode_base64);
use POSIX qw(strftime);
use Data::Dumper qw(Dumper);
use URI::Escape qw(uri_escape_utf8);

use Net::Amazon::EMR::Coercions;

use Net::Amazon::EMR::AddInstanceGroupsResult;
use Net::Amazon::EMR::BootstrapActionConfig;
use Net::Amazon::EMR::BootstrapActionDetail;
use Net::Amazon::EMR::DescribeJobFlowsResult;
use Net::Amazon::EMR::HadoopJarStepConfig;
use Net::Amazon::EMR::InstanceGroupDetail;
use Net::Amazon::EMR::InstanceGroupConfig;
use Net::Amazon::EMR::InstanceGroupModifyConfig;
use Net::Amazon::EMR::JobFlowDetail;
use Net::Amazon::EMR::JobFlowExecutionStatusDetail;
use Net::Amazon::EMR::JobFlowInstancesConfig;
use Net::Amazon::EMR::JobFlowInstancesDetail;
use Net::Amazon::EMR::KeyValue;
use Net::Amazon::EMR::PlacementType;
use Net::Amazon::EMR::RunJobFlowResult;
use Net::Amazon::EMR::ScriptBootstrapActionConfig;
use Net::Amazon::EMR::StepConfig;
use Net::Amazon::EMR::StepDetail;
use Net::Amazon::EMR::StepExecutionStatusDetail;

our $VERSION = '0.17';

has 'AWSAccessKeyId'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'SecretAccessKey'   => ( is => 'ro', isa => 'Str', required => 1 );
has 'signature_version' => ( is => 'ro', isa => 'Int', default => 2 );
has 'version'           => ( is => 'ro', isa => 'Str', required => 1, default => '2009-03-31' );
has 'ssl'               => ( is => 'ro', isa => 'Bool', required => 1, default => 1 );
has 'base_url'                  => ( 
        is                      => 'ro', 
        isa                     => 'Str', 
        default         => sub {
                return 'http' . ($_[0]->ssl ? 's' : '') . '://elasticmapreduce.amazonaws.com';
        }
);
has 'max_failures'      => ( is => 'ro', isa => 'Int', default => 5 );

after 'BUILDARGS' => sub {
    unless (Log::Log4perl->initialized) {
        Log::Log4perl->easy_init($ERROR);
    }
};

sub timestamp {
    return strftime("%Y-%m-%dT%H:%M:%SZ",gmtime);
}
    
sub _hashit {
        my $self                                                                = shift;
        my ($secret_access_key, $query_string)  = @_;
        
        return encode_base64(hmac_sha256($query_string, $secret_access_key), '');
}

sub _sign {
    my $self                                            = shift;
    my %args                                            = @_;
    my $action                                          = delete $args{Action};
    my %sign_hash                                       = %args;
    my $timestamp                                       = $self->timestamp;

    $sign_hash{AWSAccessKeyId}          = $self->AWSAccessKeyId;
    $sign_hash{Action}                          = $action;
    $sign_hash{Timestamp}                       = $timestamp;
    $sign_hash{Version}                         = $self->version;
    $sign_hash{SignatureVersion}        = $self->signature_version;
    $sign_hash{SignatureMethod}     = "HmacSHA256";

    my $sign_this = "POST\n";
    my $uri = URI->new($self->base_url);

    $sign_this .= lc($uri->host) . "\n";
    $sign_this .= "/\n";

    my @signing_elements;

    foreach my $key (sort keys %sign_hash) {
        push @signing_elements, uri_escape_utf8($key)."=".uri_escape_utf8($sign_hash{$key});
    }

    $sign_this .= join "&", @signing_elements;

    $self->log->debug("QUERY TO SIGN: $sign_this");
    my $encoded = $self->_hashit($self->SecretAccessKey, $sign_this);

    my %params = (
        Action                          => $action,
        SignatureVersion        => $self->signature_version,
        SignatureMethod     => "HmacSHA256",
        AWSAccessKeyId          => $self->AWSAccessKeyId,
        Timestamp                       => $timestamp,
        Version                         => $self->version,
        Signature                       => $encoded,
        %args
        );

    my $ur      = $uri->as_string();
    $self->log->debug("GENERATED QUERY URL: $ur");
    my $ua      = LWP::UserAgent->new();
    $ua->env_proxy;

    # We should force <item> elements to be in an array
    my $xs      = XML::Simple->new(
        ForceArray => qr/(?:item|Errors)/i, # Always want item elements unpacked to arrays
        KeyAttr => '', # Turn off folding for 'id', 'name', 'key' elements
        SuppressEmpty => undef, # Turn empty values into explicit undefs
        );

    my $xml;
    my @failures;
    while (1) {
        my $res     = $ua->post($ur, \%params);
        # Check the result for connectivity problems, if so throw an error
        if ($res->code >= 500) {
            $self->log->error("Client internal error for action $action: HTTP POST FAILURE " . $res->status_line);
            push(@failures, $res->status_line);
            if (@failures >= $self->max_failures) {
                Net::Amazon::EMR::Exception->throw( error => join("\n", @failures),
                                                    code => 'HTTP POST FAILURE',
                                                    type => 'Client Internal' );
            }
        }
        else {
            $xml = $res->content();
            last;
        }
    }

    my $ref = $xs->XMLin($xml);

    $self->log->debug(sub { "Action $action result: " . Dumper($ref) });

    if ($ref->{Error}) {
        $self->log->error("Error response for action $action: $ref->{Error}{Type}/$ref->{Error}{Code}; $ref->{Error}{Message}");
        Net::Amazon::EMR::Exception->throw( error => $ref->{Error}{Message},
                                            code => $ref->{Error}{Code},
                                            type => $ref->{Error}{Type} );
    }
    return $ref->{$action . 'Result'};

}


sub _to_flat_args {
    my ($arg, $result, $prefix) = @_;

    my $ref = ref($arg);
    if ($ref =~ m/Net::Amazon::EMR::/) {
        $arg = $arg->as_hash;
        $ref = ref($arg);
    }
    if ($ref eq 'HASH') {
        while (my ($k, $v) = each %$arg) {
            _to_flat_args($v, $result, $prefix ? "$prefix.$k" : $k);
        }
    }
    elsif ($ref eq 'ARRAY') {
        my $count = 1;
        for my $entry (@$arg) {
            _to_flat_args($entry, $result, "$prefix.member.$count");
            $count++;
        }
    }
    elsif ($ref eq 'DateTime') {
        $result->{$prefix} = "$arg";
    }
    elsif (! $ref) {
        $result->{$prefix} = $arg;
    }
    else {
        die "Unable to handle argument of type $ref";
    }
}

sub _convert_bool {
    my ($arg, $name) = @_;

    if (exists $arg->{$name}) {
        $arg->{$name} = $arg->{$name} ? 'true' : 'false';
    }
}


sub add_instance_groups {
    my ($self, %args) = validated_hash( \@_, 
        JobFlowId => { isa => 'Str' },
        InstanceGroups => { isa => 'Net::Amazon::EMR::Type::ArrayRefofInstanceGroupConfig', 
                            coerce => 1 },
                         );
    my %flat_args;
    _to_flat_args(\%args, \%flat_args);

    my $xml = $self->_sign(Action  => 'AddInstanceGroups', %flat_args);

    return Net::Amazon::EMR::AddInstanceGroupsResult->new($xml);
    
}

sub add_job_flow_steps {
    my ($self, %args) = validated_hash( \@_, 
        JobFlowId => { isa => 'Str' },
        Steps => { isa =>  'Net::Amazon::EMR::Type::ArrayRefofStepConfig', 
                   coerce => 1},
                         );

    my %flat_args;
    _to_flat_args(\%args, \%flat_args);

    my $xml = $self->_sign(Action  => 'AddJobFlowSteps', %flat_args);

    return 1;
}

sub describe_job_flows {
    my ($self, %args) = validated_hash( \@_, 
        CreatedAfter    => { isa => 'Net::Amazon::EMR::Type::DateTime', 
                             optional => 1, 
                             coerce => 1 },
        CreatedBefore   => { isa => 'Net::Amazon::EMR::Type::DateTime', 
                             optional => 1, 
                             coerce => 1 },
        JobFlowIds      => { isa => 'ArrayRef', optional => 1 },
        JobFlowStates   => { isa => 'ArrayRef[Str]', optional => 1 },
                         );
    my %flat_args;
    _to_flat_args(\%args, \%flat_args);

    my $xml = $self->_sign(Action  => 'DescribeJobFlows', %flat_args);

    return Net::Amazon::EMR::DescribeJobFlowsResult->new($xml);
}

sub modify_instance_groups {
    my ($self, %args) = validated_hash( \@_, 
                                        InstanceGroups => { isa => 'Net::Amazon::EMR::Type::ArrayRefofInstanceGroupModifyConfig', 
                                                            optional => 1,
                                                            coerce => 1 },
                         );

    my %flat_args;
    _to_flat_args(\%args, \%flat_args);

    my $xml = $self->_sign(Action  => 'ModifyInstanceGroups', %flat_args);

    return 1;

}

sub run_job_flow {
    my ($self, %args) = validated_hash( \@_, 
        AdditionalInfo  => { isa => 'Str', optional => 1 },
        AmiVersion      => { isa => 'Str', optional => 1 },
        BootstrapActions => { isa => 'Net::Amazon::EMR::Type::ArrayRefofBootstrapActionConfig | Undef', 
                              optional => 1, 
                              coerce => 1 },
        Instances       => { isa => 'Net::Amazon::EMR::Type::JobFlowInstancesConfig', coerce => 1 },
        LogUri  => { isa => 'Str | Undef', optional => 1 },
        Name    => { isa => 'Str' },
        Steps   => { isa => 'Net::Amazon::EMR::Type::ArrayRefofStepConfig', optional => 1, coerce => 1 },
        SupportedProducts => { isa => 'ArrayRef[Str] | Undef', optional => 1 },
        VisibleToAllUsers => { isa => 'Net::Amazon::EMR::Type::Bool', optional => 1 },
                                        );

    _convert_bool(\%args, 'VisibleToAllUsers');

    my %flat_args;
    _to_flat_args(\%args, \%flat_args);

    my $xml = $self->_sign(Action  => 'RunJobFlow', %flat_args);

    return Net::Amazon::EMR::RunJobFlowResult->new($xml);
}


sub set_termination_protection {
    my ($self, %args) = validated_hash( \@_, 
                                        JobFlowIds      => { isa => 'ArrayRef' },
                                        TerminationProtected => { isa => 'Net::Amazon::EMR::Type::Bool', 
                                                                  coerce => 1 },
        );
    _convert_bool(\%args, 'TerminationProtected');

    my %flat_args;
    _to_flat_args(\%args, \%flat_args);

    my $xml = $self->_sign(Action  => 'SetTerminationProtection', %flat_args);
    return 1;
}

sub set_visible_to_all_users {
    my ($self, %args) = validated_hash( \@_, 
        JobFlowIds      => { isa => 'ArrayRef' },
        VisibleToAllUsers => { isa => 'Net::Amazon::EMR::Type::Bool', 
                               coerce => 1 },
        );
    _convert_bool(\%args, 'VisibleToAllUsers');

    my %flat_args;
    _to_flat_args(\%args, \%flat_args);

    my $xml = $self->_sign(Action  => 'SetVisibleToAllUsers', %flat_args);
    return 1;
}

sub terminate_job_flows {
    my ($self, %args) = validated_hash( \@_, 
        JobFlowIds      => { isa => 'ArrayRef' },
                         );
    my %flat_args;
    _to_flat_args(\%args, \%flat_args);

    my $xml = $self->_sign(Action  => 'TerminateJobFlows', %flat_args);
    return 1;
}


1;

__END__

=head1 NAME

Net::Amazon::EMR - API for Amazon's Elastic Map-Reduce service

=head1 SYNOPSIS

  use Net::Amazon::EMR;

  my $emr = Net::Amazon::EMR->new(
    AWSAccessKeyId  => $AWS_ACCESS_KEY_ID,
    SecretAccessKey => $SECRET_ACCESS_KEY,
    ssl             => 1,
    );

  # start a job flow
  my $id = $emr->run_job_flow(Name => "Example Job",
                              Instances => {
                                  Ec2KeyName => 'myKeyId',
                                  InstanceCount => 10,
                                  KeepJobFlowAliveWhenNoSteps => 1,
                                  MasterInstanceType => 'm1.small',
                                  Placement => { AvailabilityZone => 'us-east-1a' },
                                  SlaveInstanceType => 'm1.small',
                              },
                              BootstrapActions => [{
                                Name => 'Bootstrap-configure',
                                ScriptBootstrapAction => {
                                  Path => 's3://elasticmapreduce/bootstrap-actions/configure-hadoop',
                                  Args => [ '-m', 'mapred.compress.map.output=true' ],
                                },
                              }],
                              Steps => [{
                                ActionOnFailure => 'TERMINATE_JOB_FLOWS',
                                Name => "Set up debugging",
                                HadoopJarStep => { 
                                           Jar => 's3://us-east-1.elasticmapreduce/libs/script-runner/script-runner.jar',
                                           Args => [ 's3://us-east-1.elasticmapreduce/libs/state-pusher/0.1/fetch' ],
                                           },
                              }],
                            );

  print "Job flow id = " . $id->JobFlowId . "\n";

  # Get details of just-launched job
  $result = $emr->describe_job_flows(JobFlowIds => [ $id->JobFlowId ]);

  # or get details of all jobs created after a given time
  $result = $emr->describe_job_flows(CreatedAfter => '2012-12-17T07:19:57Z');

  # or use DateTime
  $result = $emr->describe_job_flows(CreatedAfter => DateTime->new(year => 2012, month => 12, day => 17));

  # See the details of the typed result
  use Data::Dumper; print Dumper($result);

  # or dispense with types and see the details as a perl hash
  use Data::Dumper; print Dumper($result->as_hash);

  # Flexible Booleans - 1, 0, undef, 'true', 'false'
  $emr->set_visible_to_all_users(JobFlowIds => $id, VisibleToAllUsers => 1);
  $emr->set_termination_protection(JobFlowIds => [ $id->JobFlowId ], TerminationProtected => 'false');

  # Add map-reduce steps and execute
  $emr->add_job_flow_steps(JobFlowId => $job_id,
                           Steps => [{
            ActionOnFailure => 'CANCEL_AND_WAIT',
            Name => "Example",
            HadoopJarStep => { 
              Jar => '/home/hadoop/contrib/streaming/hadoop-streaming.jar',
              Args => [ '-input', 's3://my-bucket/my-input',
                        '-output', 's3://my-bucket/my-output',
                        '-mapper', '/path/to/mapper-script',
                        '-reducer', '/path/to/reducer-script',
                      ],
              Properties => [ { Key => 'reduce_tasks_speculative_execution', Value => 'false' } ],
              },
        }, ... ]);

=head1 DESCRIPTION

This is an implementation of the Amazon Elastic Map-Reduce API.

=head1 CONSTRUCTOR

=head2 new(%options)

This is the constructor.  Options are as follows:

=over 4

=item * AWSAccessKeyId (required)

Your AWS access key.

=item * SecretAccessKey (required)

Your secret key.

=item * base_url (optional)

The base URL for your chosen Amazon region; see L<http://docs.aws.amazon.com/general/latest/gr/rande.html#emr_region>.  If not specified, the default URL is used (which implies region us-east-1).

  my $emr = Net::Amazon::EMR->new(
      AWSAccessKeyId  => $AWS_ACCESS_KEY_ID,
      SecretAccessKey => $SECRET_ACCESS_KEY,
      base_url => 'https://elasticmapreduce.us-west-2.amazonaws.com',
  );


=item * ssl (optional)

If set to a true value, the default base_url will use https:// instead of http://. Defaults to true.  

The ssl flag is not used if base_url is set explicitly.

=item * max_failures (optional)

Number of times to retry if a communications failure occurs, before raising an exception.  Defaults to 5.

=back

=head1 METHODS

Detailed information on each of the methods can be found in the Amazon EMR API documentation.  Each method takes a hash of parameters using the names given in the documentation.  Parameter passing uses the following rules:

=over 4

=item * Array inputs such as InstanceGroups.member.N use their primary name and a Perl ArrayRef, i.e. InstanceGroups => [ ... ] in this example.

=item * Either hashes or object instances may be passed in; e.g both of the following forms are acceptable:

    $emr->run_job_flow(Name => "API Test Job",
                                Instances => {
                                    Ec2KeyName => 'xxx',
                                    InstanceCount => 1,
                                },
        );

    $emr->run_job_flow(Name => "API Test Job",
                                Instances => Net::Amazon::EMR::JobFlowInstancesConfig->new(
                                    Ec2KeyName => 'xxx',
                                    InstanceCount => 1,
                                ),
        );

=item * Otherwise, the names of parameters are exactly as found in the Amazon documentation for API version 2009-03-31.

=back


=head2 add_instance_groups(%params)

AddInstanceGroups adds an instance group to a running cluster. Returns a L<Net::Amazon::EMR::AddInstanceGroupsResult> object.

=head2 add_job_flow_steps(%params)

AddJobFlowSteps adds new steps to a running job flow. Returns 1 on success.


=head2 describe_job_flows(%params)

Returns a L<Net::Amazon::EMR::RunJobFlowResult> that describes the job flows that match all of the supplied parameters.

=head2 modify_instance_groups(%params)

Modifies the number of nodes and configuration settings of an instance group. Returns 1 on success.

=head2 run_job_flow(%params)

Creates and starts running a new job flow. Returns a L<Net::Amazon::EMR::RunJobFlowResult> object that contains the job flow ID.

=head2 set_termination_protection(%params)

Locks a job flow so the Amazon EC2 instances in the cluster cannot be terminated by user intervention, an API call, or in the event of a job-flow error. Returns 1 on success.

=head2 set_visible_to_all_users(%params)

Sets whether all AWS Identity and Access Management (IAM) users under your account can access the specifed job flows. Returns 1 on success.

=head2 terminate_job_flows(%params)

Terminates a list of job flows.  Returns 1 on success.

=head1 ERROR HANDLING 

If an error occurs in any of the methods, the error will be logged and an L<Exception::Class> exception of type Net::Amazon::EMR::Exception will be thrown.

=head1 ERROR LOGGING

=head2 Quick Start
Logging uses Log::Log4perl.  You should initialise Log::Log4perl at the beginning of your program to suit your needs.  The simplest way to enable debugging output to STDERR is to call

  use Log::Log4perl qw/:easy/;
  Log::Log4perl->easy_init($DEBUG);

=head2 Advanced Logging Configuration

L<Log::Log4perl> provides great flexibility and there are many ways to set it up.  A favourite of my own is to use L<Config::General> format to specify all configuration parameters including logging, and to initialise in the following manner:

  use Config::General qw/ParseConfig/;
  
  my %opts = ParseConfig(-ConfigFile => 'my.conf',
                         -SplitPolicy => 'equalsign',
                         -UTF8 => 1);
  ... 
   
  unless (Log::Log4perl->initialized) {
      if ($opts{log4perl}) {
            Log::Log4perl::init($opts{log4perl});
      }
      else {
         Log::Log4perl->easy_init();
      }
  }
   
And a typical configuration in L<Config::General> format might look like this:

  <log4perl>
    log4perl.rootLogger = DEBUG, Screen, Logfile
    log4perl.appender.Logfile = Log::Log4perl::Appender::File
    log4perl.appender.Logfile.filename = debug.log
    log4perl.appender.Logfile.layout = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Logfile.layout.ConversionPattern = "%d %-5p %c - %m%n"
    log4perl.appender.Screen = Log::Log4perl::Appender::ScreenColoredLevels
    log4perl.appender.Screen.stderr = 1
    log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = "[%d] [%p] %c %m%n"
  </log4perl>

=head2 Logging Verbosity
 
At DEBUG level, the output can be very lengthy.  To see only important messages for Net::Amazon::EMR whilst debugging other parts of your code, you could raise the threshold just for Net::Amazon::EMR by adding the following to your Log4perl configuration: 

  log4perl.logger.Net.Amazon.EMR = WARN

=head1 Map-Reduce Notes

This is somewhat beyond the scope of the documentation for using Net::Amazon::EMR.  Nevertheless, here are a few notes about using EMR with Perl.

=head2 Installing Perl Libraries

Undoubtedly, to run any serious processing, you will need to install additional libraries on the map-reduce servers.  A practical way to do this is to pre-configure all of the libraries using local::lib and use a bootstrap task to install them when the servers boot, using steps similar to the following:

=over 4

=item * Start an interactive EMR job on a single instance using the same machine architecture (e.g. m1.large) that you plan to use for running your jobs.

=item * ssh to instance

=item * setup CPAN, get L<local::lib> and install

=item * setup .bashrc to contain the environment variables required to use L<local::lib>

=item * install all the other modules you need via cpan

=item * clean up files from .cpan that you don't need, such as build and source directories

=item * Create a tar file, e.g. tar cfz local-perl5.tar.gz perl5 .cpan .bashrc

=item * Copy the tar file to your bucket on S3.

=item * Set up a bootstrap script to copy back the tar file from S3 and untar it into the hadoop home directory, e.g.

    #!/bin/bash
    set -e
    bucket=mybucketname
    tarfile=local-perl5.tar.gz
    arch=large
    cd $HOME
    hadoop fs -get s3://$bucket/$arch/$tarfile .
    tar xfz $tarfile

=item * Put the bootstrap script on S3 and use it when creating a new job flow.

=back

=head2 Mappers and Reducers

Assuming the reader is familiar with the basic principles of map-reduce, in terms of implementation in Perl with hadoop-streaming.jar, a mapper/reducer is simply a script that reads from STDIN and writes to STDOUT, typically line by line using a tab-separated key and value pair on each line.  So the main loop of any mapper/reducer script is usually of the form:

    while (my $line = <>) {
      chomp $line;
      my ($key, $value) = split(/\t/, @line);
      ... do something with key and value
      print "$newkey\t$newvalue\n";
    }

Scripts can be uploaded to S3 using the web interface, or placed in the bootstrap bundle described above, or uploaded to the master instance using scp and distributed using the hadoop-streaming.jar -file option, or no doubt by many other mechanisms.  If due care is taken with quoting, a script can even be specified using the -mapper and -reducer options directly; for example:

  Args => [ '-mapper', '"perl -e MyClass->new->mapper"', ... ]

=head1 AUTHOR

Jon Schutz

L<http://notes.jschutz.net>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-amazon-emr at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Amazon-EMR>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Amazon::EMR


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Amazon-EMR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Amazon-EMR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Amazon-EMR>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Amazon-EMR/>

=back


=head1 ACKNOWLEDGEMENTS

The core interface code was adapted from L<Net::Amazon::EC2>.


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jon Schutz.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

Amazon EMR API: L<http://http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/Welcome.html>

=cut

