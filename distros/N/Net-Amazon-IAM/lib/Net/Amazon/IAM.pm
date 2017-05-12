package Net::Amazon::IAM;
use Moose;

use URI;
use Carp;
use JSON;
use URI::Encode;
use XML::Simple;
use POSIX qw(strftime);
use LWP::UserAgent;
use LWP::Protocol::https;
use Data::Dumper qw(Dumper);
use Params::Validate qw(validate SCALAR ARRAYREF HASHREF);
use HTTP::Request::Common;
use AWS::Signature4;

use Net::Amazon::IAM::Error;
use Net::Amazon::IAM::Errors;
use Net::Amazon::IAM::User;
use Net::Amazon::IAM::Users;
use Net::Amazon::IAM::Policy;
use Net::Amazon::IAM::Policies;
use Net::Amazon::IAM::UserPolicy;
use Net::Amazon::IAM::PolicyVersion;
use Net::Amazon::IAM::PolicyVersions;
use Net::Amazon::IAM::Group;
use Net::Amazon::IAM::Groups;
use Net::Amazon::IAM::GroupPolicy;;
use Net::Amazon::IAM::GetGroupResult;
use Net::Amazon::IAM::AccessKey;
use Net::Amazon::IAM::AccessKeyMetadata;
use Net::Amazon::IAM::AccessKeysList;
use Net::Amazon::IAM::Role;
use Net::Amazon::IAM::Roles;
use Net::Amazon::IAM::VirtualMFADevice;
use Net::Amazon::IAM::VirtualMFADevices;
use Net::Amazon::IAM::MFADevice;
use Net::Amazon::IAM::MFADevices;
use Net::Amazon::IAM::InstanceProfile;
use Net::Amazon::IAM::InstanceProfiles;
use Net::Amazon::IAM::LoginProfile;

our $VERSION = '0.05';

=head1 NAME

Net::Amazon::IAM - Perl interface to the Amazon Identity and Access Management.

=head1 VERSION

This is Net::Amazon::IAM version 0.05

IAM Query API version: '2010-05-08'

=head1 SYNOPSIS

 use Net::Amazon::IAM;

 my $iam = Net::Amazon::IAM->new(
   AWSAccessKeyId  => 'PUBLIC_KEY_HERE',
   SecretAccessKey => 'SECRET_KEY_HERE',
   return_errors   => 0, # which is default
 );

 # prepare user policy document
 my $policy_document = {
   Version => '2012-10-17',
   Statement => [
      {
         Effect   => 'Allow',
         Action   => [
            's3:Get*',
            's3:List*',
         ],
         Resource => [
            'arn:aws:s3:::sometestbucket',
            'arn:aws:s3:::sometestbucket/*',
         ],
      },
   ],
 };

 try {
   # create new user
   my $user = $iam->create_user(
      UserName => 'testuser',
      Path     => '/path/to/test/users/',
   );
   
   # Add an inline user policy document.
   my $policy = $iam->put_user_policy (
      PolicyName     => 'somtestpolicy',
      UserName       => 'sometestuser',
      PolicyDocument => $policy_document,
   );

   print $user->UserId . "\n";
   print $policy->PolicyId . "\n";
 } catch {
   my $error = shift();
   print $error->as_string() . "\n";
 }

If an error occurs while communicating with IAM, these methods will
throw a L<Net::Amazon::IAM::Error> exception.

=head1 DESCRIPTION

This module is a Perl interface to Amazon's Identity and Access Management (IAM). It uses the Query API to
communicate with Amazon's Web Services framework.

=head1 CLASS METHODS

=head2 new(%params)

This is the constructor, it will return you a Net::Amazon::IAM object to work with.  It takes
these parameters:

=over

=item AWSAccessKeyId (required)

Your AWS access key.

=item SecretAccessKey (required)

Your secret key, B<WARNING!> don't give this out or someone will be able to use your account
and incur charges on your behalf.

=item debug (optional)

A flag to turn on debugging. Among other useful things, it will make the failing api calls print
a stack trace. It is turned off by default.

=item return_errors (optional)

A flag to enable returning errors as objects instead of throwing them as exceptions.

=back

=cut

has 'AWSAccessKeyId' => (
   is       => 'ro',
   isa      => 'Str',
   lazy     => 1,
   default  => sub {
      if (defined($_[0]->temp_creds)) {
         return $_[0]->temp_creds->{'AccessKeyId'};
      } else {
         return undef;
      }
   }
);

has 'SecretAccessKey' => (
   is       => 'ro',
   isa      => 'Str',
   lazy     => 1,
   default  => sub {
      if (defined($_[0]->temp_creds)) {
         return $_[0]->temp_creds->{'SecretAccessKey'};
      } else {
         return undef;
      }
   }
);

has 'SecurityToken' => (
   is        => 'ro',
   isa       => 'Str',
   lazy      => 1,
   predicate => 'has_SecurityToken',
   default   => sub {
      if (defined($_[0]->temp_creds)) {
         return $_[0]->temp_creds->{'Token'};
      } else {
         return undef;
      }
   }
);

has 'base_url' => (
   is          => 'ro',
   isa         => 'Str',
   lazy        => 1,
   default     => sub {
      return 'http' . ($_[0]->ssl ? 's' : '') . '://iam.amazonaws.com';
   }
);

has 'temp_creds' => (
   is        => 'ro',
   lazy      => 1,
   predicate => 'has_temp_creds',
   default   => sub {
      my $ret;
      $ret = $_[0]->_fetch_iam_security_credentials();
   },
);

has 'debug'             => ( is => 'ro', isa => 'Str',  default => 0 );
has 'version'           => ( is => 'ro', isa => 'Str',  default => '2010-05-08' );
has 'ssl'               => ( is => 'ro', isa => 'Bool', default => 1 );
has 'return_errors'     => ( is => 'ro', isa => 'Bool', default => 0 );

sub _timestamp {
   return strftime("%Y-%m-%dT%H:%M:%SZ",gmtime);
}

sub _fetch_iam_security_credentials {
   my $self = shift;
   my $retval = {};

   my $ua = LWP::UserAgent->new();
   # Fail quickly if this is not running on an EC2 instance
   $ua->timeout(2);

   my $url = 'http://169.254.169.254/latest/meta-data/iam/security-credentials/';

   $self->_debug("Attempting to fetch instance credentials");

   my $res = $ua->get($url);
   if ($res->code == 200) {
      # Assumes the first profile is the only profile
      my $profile = (split /\n/, $res->content())[0];

      $res = $ua->get($url . $profile);

      if ($res->code == 200) {
         $retval->{'Profile'} = $profile;
         foreach (split /\n/, $res->content()) {
            return undef if /Code/ && !/Success/;
            if (m/.*"([^"]+)"\s+:\s+"([^"]+)",/) {
               $retval->{$1} = $2;
            }
         }

         return $retval if (keys %{$retval});
      }
   }

   return undef;
}

sub _sign {
   my $self      = shift;
   my %args      = @_;
   my $action    = delete $args{'Action'};
   my %sign_hash = %args;
   my $timestamp = $self->_timestamp;

   $sign_hash{'Action'}           = $action;
   $sign_hash{'Version'}          = $self->version;

   if ($self->has_temp_creds || $self->has_SecurityToken) {
      $sign_hash{'SecurityToken'} = $self->SecurityToken;
   }

   my $signer = AWS::Signature4->new(
      -access_key => $self->{'AWSAccessKeyId'},
      -secret_key => $self->{'SecretAccessKey'},
   );

   my $ua = LWP::UserAgent->new();

   my $request = POST(
      $self->base_url,
      [
         %sign_hash,
      ],
   );

   $signer->sign($request);

   my $res = $ua->request($request);

   # We should force <item> elements to be in an array
   my $xs   = XML::Simple->new(
      ForceArray => qr/(?:item|Errors)/i, # Always want item elements unpacked to arrays
      KeyAttr => '',                      # Turn off folding for 'id', 'name', 'key' elements
      SuppressEmpty => undef,             # Turn empty values into explicit undefs
   );
   my $xml;

   # Check the result for connectivity problems, if so throw an error
   if ($res->code >= 500) {
      my $message = $res->status_line;
      $xml = <<EOXML;
<xml>
   <RequestID>N/A</RequestID>
   <Errors>
      <Error>
         <Code>HTTP POST FAILURE</Code>
         <Message>$message</Message>
      </Error>
   </Errors>
</xml>
EOXML

   } else {
      $xml = $res->content();
   }

   my $ref = $xs->XMLin($xml);
   warn Dumper($ref) . "\n\n" if $self->debug == 1;

   return $ref;
}

sub _parse_errors {
   my $self       = shift;
   my $errors_xml = shift;

   my $es;
   my $request_id = $errors_xml->{'RequestId'};

   my $error = Net::Amazon::IAM::Error->new(
      code       => $errors_xml->{'Error'}{'Code'},
      message    => $errors_xml->{'Error'}{'Message'},
      request_id => $request_id,
   );

   if ($self->return_errors) {
      return $error;
   }

   # Print a stack trace if debugging is enabled
   if ($self->debug) {
      confess 'Last error was: ' . $error->message;
   }else{
      croak $error;
   }
}

sub _debug {
   my $self    = shift;
   my $message = shift;

   if ((grep { defined && length} $self->debug) && $self->debug == 1) {
      print "$message\n\n\n\n";
   }
}

sub _build_filters {
   my ($self, $args) = @_;

   my $filters = delete $args->{Filter};

   return unless $filters && ref($filters) eq 'ARRAY';

   $filters = [ $filters ] unless ref($filters->[0]) eq 'ARRAY';
   my $count   = 1;
   foreach my $filter (@{$filters}) {
      my ($name, @args) = @$filter;
      $args->{"Filter." . $count.".Name"}      = $name;
      $args->{"Filter." . $count.".Value.".$_} = $args[$_-1] for 1..scalar @args;
      $count++;
   }
}

sub _parse_attributes {
   my $self          = shift;
   my $single_object = shift;
   my $list_objects  = shift;
   my %result        = @_;

   my $attributes;
   if ( grep { defined && length } $result{$list_objects}{'member'} ) {
      if(ref($result{$list_objects}{'member'}) eq 'ARRAY') {
         for my $attr(@{$result{$list_objects}{'member'}}) {
            my $a = "Net::Amazon::IAM::$single_object"->new(
               $attr,
            );
            push @$attributes, $a;
         }
      }else{
         my $a = "Net::Amazon::IAM::$single_object"->new(
            $result{$list_objects}{'member'},
         );
         push @$attributes, $a;
      }
   }else{
      $attributes = [];
   }

   return $attributes;
}

=head2 create_user(%params)

Create new IAM user

=over

=item UserName (required)

New user username

=item Path (optional)

Where to create new user

=back

Returns a L<Net::Amazon::IAM::User> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub create_user {
   my $self = shift;

   my %args = validate(@_, {
      UserName => { type => SCALAR },
      Path     => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action  => 'CreateUser', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return Net::Amazon::IAM::User->new(
         $xml->{'CreateUserResult'}{'User'},
      );
   }
}

=head2 delete_user(%params)

Delete IAM User

=over

=item UserName (required)

What user should be deleted

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub delete_user {
   my $self = shift;

   my %args = validate(@_, {
      UserName => { type => SCALAR },
   });

   my $xml = $self->_sign(Action  => 'DeleteUser', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 get_user(%params)

Get IAM user details

=over

=item UserName (required)

New user username

=back

Returns a L<Net::Amazon::IAM::User> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub get_user {
   my $self = shift;

   my %args = validate(@_, {
      UserName => { type => SCALAR },
   });

   my $xml = $self->_sign(Action  => 'GetUser', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return Net::Amazon::IAM::User->new(
         $xml->{'GetUserResult'}{'User'},
      );
   }
}

=head2 update_user(%params)

Updates the name and/or the path of the specified user.

=over

=item UserName (required)

Name of the user to update. If you're changing the name of the user, this is the original user name.

=item NewPath (optional)

New path for the user. Include this parameter only if you're changing the user's path.

=item NewUserName (optional)

New name for the user. Include this parameter only if you're changing the user's name.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub update_user {
   my $self = shift;

   my %args = validate(@_, {
      UserName    => { type => SCALAR },
      NewPath     => { type => SCALAR, optional => 1 },
      NewUserName => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action  => 'UpdateUser', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 list_users(%params)

Lists the IAM users that have the specified path prefix. 
If no path prefix is specified, the action returns all users in the AWS account. 

=over

=item Marker (required)

Use this parameter only when paginating results, and only in a subsequent request 
after you've received a response where the results are truncated. Set it to the 
value of the Marker element in the response you just received.

=item MaxItems (optional)

Use this parameter only when paginating results to indicate the maximum number of 
user names you want in the response. If there are additional user names beyond the 
maximum you specify, the IsTruncated response element is true. This parameter is 
optional. If you do not include it, it defaults to 100.

=item PathPrefix (optional)

The path prefix for filtering the results. For example: 
/division_abc/subdivision_xyz/, which would get all user 
names whose path starts with /division_abc/subdivision_xyz/.

=back

Returns L<Net::Amazon::IAM::Users> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub list_users {
   my $self = shift;

   my %args = validate(@_, {
      Marker     => { type => SCALAR, optional => 1 },
      MaxItems   => { type => SCALAR, optional => 1 },
      PathPrefix => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action  => 'ListUsers', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my %result = %{$xml->{'ListUsersResult'}};
      my $users  = $self->_parse_attributes('User', 'Users', %result);

      return Net::Amazon::IAM::Users->new(
         Users       => $users,
         IsTruncated => $result{'IsTruncated'},
         Marker      => $result{'Marker'},
      );
   }
}

=head2 add_user_to_group(%params)

Adds the specified user to the specified group.

=over

=item GroupName (required)

The name of the group to update.

=item UserName (required)

The name of the user to add.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub add_user_to_group {
   my $self = shift;

   my %args = validate(@_, {
      GroupName => { type => SCALAR },
      UserName  => { type => SCALAR },
   });

   my $xml = $self->_sign(Action  => 'AddUserToGroup', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 remove_user_from_group(%params)

Removes the specified user from the specified group.

=over

=item GroupName (required)

The name of the group to update.

=item UserName (required)

The name of the user to remove.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub remove_user_from_group {
   my $self = shift;

   my %args = validate(@_, {
      GroupName => { type => SCALAR },
      UserName  => { type => SCALAR },
   });

   my $xml = $self->_sign(Action  => 'RemoveUserFromGroup', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 create_group(%params)

Creates a new group.

=over

=item GroupName (required)

The name of the group to create.

=item Path (optional)

The path to the group.

=back

Returns L<Net::Amazon::IAM::Group> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub create_group {
   my $self = shift;

   my %args = validate(@_, {
      GroupName => { type => SCALAR },
      Path      => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action  => 'CreateGroup', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return Net::Amazon::IAM::Group->new(
         $xml->{'CreateGroupResult'}{'User'},
      );
   }
}

=head2 get_group(%params)

Returns group details and list of users that are in the specified group.

=over

=item GroupName (required)

The name of the group.

=item MaxItems (optional)

Use this only when paginating results to indicate the maximum number of 
groups you want in the response. If there are additional groups beyond the 
maximum you specify, the IsTruncated response element is true. This parameter is optional. 
If you do not include it, it defaults to 100.

=item Marker (optional)

Use this only when paginating results, and only in a subsequent request 
after you've received a response where the results are truncated. 
Set it to the value of the Marker element in the response you just received.

=back

Returns L<Net::Amazon::IAM::GetGroupResult> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub get_group {
   my $self = shift;

   my %args = validate(@_, {
      GroupName => { type => SCALAR },
      Marker    => { type => SCALAR, optional => 1 },
      MaxItems  => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action  => 'GetGroup', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my %result = %{$xml->{'GetGroupResult'}};
      my $users  = $self->_parse_attributes('User', 'Users', %result);

      my $group = Net::Amazon::IAM::Group->new(
         %{$result{'Group'}},
      );

      return Net::Amazon::IAM::GetGroupResult->new(
         IsTruncated => $result{'IsTruncated'},
         Marker      => $result{'Marker'},
         Users       => $users,
         Group       => $group,
      );
   }
}

=head2 delete_group(%params)

Deletes the specified group. The group must not contain any users or have any attached policies.

=over

=item GroupName (required)

The name of the group to delete.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub delete_group {
   my $self = shift;

   my %args = validate(@_, {
      GroupName => { type => SCALAR },
   });

   my $xml = $self->_sign(Action  => 'DeleteGroup', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 list_groups(%params)

Lists the groups that have the specified path prefix.

=over

=item Marker (optional)

Use this only when paginating results, and only in a subsequent request after 
you've received a response where the results are truncated. Set it to the value 
of the Marker element in the response you just received.

=item MaxItems (optional)

Use this only when paginating results to indicate the maximum number of groups 
you want in the response. If there are additional groups beyond the maximum you specify, 
the IsTruncated response element is true. This parameter is optional. If you do not include 
it, it defaults to 100.

=item PathPrefix (optional)

The path prefix for filtering the results. For example, the prefix /division_abc/subdivision_xyz/ 
gets all groups whose path starts with /division_abc/subdivision_xyz/.

=back

Returns L<Net::Amazon::IAM::Groups> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub list_groups {
   my $self = shift;

   my %args = validate(@_, {
      Marker     => { type => SCALAR, optional => 1 },
      MaxItems   => { type => SCALAR, optional => 1 },
      PathPrefix => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action  => 'ListGroups', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my %result = %{$xml->{'ListGroupsResult'}};
      my $groups = $self->_parse_attributes('Group', 'Groups', %result);

      return Net::Amazon::IAM::Groups->new(
         Groups      => $groups,
         IsTruncated => $result{'IsTruncated'},
         Marker      => $result{'Marker'},
      );
   }
}

=head2 create_policy(%params)

Creates a new managed policy for your AWS account.

=over

=item PolicyName (required)

The name of the policy document.

=item PolicyDocument (required)

The policy document.

=item Description (optional)

A friendly description of the policy.

=item Path (optional)

The path for the policy.

=back

Returns L<Net::Amazon::IAM::Policy> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub create_policy {
   my $self = shift;

   my %args = validate(@_, {
      PolicyName     => { type => SCALAR },
      PolicyDocument => { type => HASHREF },
      Description    => { type => SCALAR, optional => 1 },
      Path           => { type => SCALAR, optional => 1 },
   });

   $args{'PolicyDocument'} = encode_json delete $args{'PolicyDocument'};

   my $xml = $self->_sign(Action  => 'CreatePolicy', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return Net::Amazon::IAM::Policy->new(
         $xml->{'CreatePolicyResult'}{'Policy'},
      );
   }
}

=head2 get_policy(%params)

Retrieves information about the specified managed policy.

=over

=item PolicyArn (required)

The Amazon Resource Name (ARN). ARNs are unique identifiers for AWS resources.

=back

Returns L<Net::Amazon::IAM::Policy> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub get_policy {
   my $self = shift;

   my %args = validate(@_, {
      PolicyArn => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'GetPolicy', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return Net::Amazon::IAM::Policy->new(
         $xml->{'GetPolicyResult'}{'Policy'},
      );
   }
}

=head2 delete_policy(%params)

Deletes the specified managed policy.

=over

=item PolicyArn (required)

The Amazon Resource Name (ARN). ARNs are unique identifiers for AWS resources.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub delete_policy {
   my $self = shift;

   my %args = validate(@_, {
      PolicyArn => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'DeletePolicy', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 list_policies(%params)

Lists all the managed policies that are available to your account, 
including your own customer managed policies and all AWS managed policies.

You can filter the list of policies that is returned using the optional 
OnlyAttached, Scope, and PathPrefix parameters. For example, to list only the 
customer managed policies in your AWS account, set Scope to Local. 
To list only AWS managed policies, set Scope to AWS.

=over

=item OnlyAttached (optional)

A flag to filter the results to only the attached policies.
When OnlyAttached is true, the returned list contains only the 
policies that are attached to a user, group, or role. 
When OnlyAttached is false, or when the parameter is not 
included, all policies are returned.

=item PathPrefix (optional)

The path prefix for filtering the results. 
If it is not included, it defaults to a slash (/), listing all policies.

=item Scope (optional)

The scope to use for filtering the results.

To list only AWS managed policies, set Scope to AWS. 
To list only the customer managed policies in your AWS account, set Scope to Local.
If it is not included, or if it is set to All, all policies are returned.

=item MaxItems (optional)

Maximum number of policies to retrieve.

=item Marker (optional)

If IsTruncated is true, this element is present and contains the value to use for the 
Marker parameter in a subsequent pagination request.

Example: 
 my $policies = $iam->list_policies(
    MaxItems => 1
 );

 while($policies->IsTruncated eq 'true') {
    for my $policy(@{$policies->{'Policies'}}) {
       print $policy->PolicyId . "\n";
    }

    $policies = $iam->list_policies(
       MaxItems => 50,
       Marker   => $policies->Marker,
    );
 }

=back

Returns L<Net::Amazon::IAM::Policies> on success or L<Net::Amazon::IAM::Error> on fail.
When no policies found, the Policies attribute will be just empty array.

=cut

sub list_policies {
   my $self = shift;

   my %args = validate(@_, {
      Marker       => { type => SCALAR, optional => 1 },
      MaxItems     => { type => SCALAR, optional => 1 },
      PathPrefix   => { type => SCALAR, optional => 1, default => '/' },
      OnlyAttached => { regex => qr/true|false/, optional => 1, default => 'false' },
      Scope        => { regex => qr/AWS|Local|All/, optional => 1, default => 'All' },
   });

   my $xml = $self->_sign(Action => 'ListPolicies', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my %result = %{$xml->{'ListPoliciesResult'}};
      my $policies = $self->_parse_attributes('Policy', 'Policies', %result);

      return Net::Amazon::IAM::Policies->new(
         Policies    => $policies,
         IsTruncated => $result{'IsTruncated'},
         Marker      => $result{'Marker'},
      );
   }
}

=head2 get_policy_version(%params)

Retrieves information about the specified version of the specified 
managed policy, including the policy document.

=over

=item PolicyArn (required)

The Amazon Resource Name (ARN). ARNs are unique identifiers for AWS resources.

=item VersionId (required)

Identifies the policy version to retrieve.

=back

Returns L<Net::Amazon::IAM::PolicyVersion> on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub get_policy_version {
   my $self = shift;

   my %args = validate(@_, {
      PolicyArn => { type => SCALAR },
      VersionId => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'GetPolicyVersion', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my %result = %{$xml->{'GetPolicyVersionResult'}{'PolicyVersion'}};
      $result{'Document'} = decode_json(URI::Encode->new()->decode($result{'Document'}));
      return Net::Amazon::IAM::PolicyVersion->new(
         %result,
      );
   }
}

=head2 set_default_policy_version(%params)

Sets the specified version of the specified policy as the policy's default (operative) version.

=over

=item PolicyArn (required)

The Amazon Resource Name (ARN). ARNs are unique identifiers for AWS resources.

=item VersionId (required)

The version of the policy to set as the default (operative) version.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub set_default_policy_version {
   my $self = shift;

   my %args = validate(@_, {
      PolicyArn => { type => SCALAR },
      VersionId => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'SetDefaultPolicyVersion', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 list_policy_versions(%params)

Lists information about the versions of the specified managed policy, including the 
version that is set as the policy's default version.

=over

=item PolicyArn (required)

The Amazon Resource Name (ARN). ARNs are unique identifiers for AWS resources.

=item MaxItems (optional)

Use this parameter only when paginating results to indicate the maximum number 
of policy versions you want in the response.

=item Marker (optional)

Use this parameter only when paginating results, and only in a subsequent request 
after you've received a response where the results are truncated. Set it to the value 
of the Marker element in the response you just received.

=back

Returns L<Net::Amazon::IAM::PolicyVersions> on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub list_policy_versions {
   my $self = shift;

   my %args = validate(@_, {
      PolicyArn => { type => SCALAR },
      MaxItems  => { type => SCALAR, optional => 1 },
      Marker    => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action => 'ListPolicyVersions', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my %result   = %{$xml->{'ListPolicyVersionsResult'}};
      my $versions = $self->_parse_attributes('PolicyVersion', 'Versions', %result);

      return Net::Amazon::IAM::PolicyVersions->new(
         Policies => $versions,
      );
   }
}

=head2 create_policy_version(%params)

Creates a new version of the specified managed policy. To update a managed policy, 
you create a new policy version. A managed policy can have up to five versions. 
If the policy has five versions, you must delete an existing version using DeletePolicyVersion 
before you create a new version.

Optionally, you can set the new version as the policy's default version. The default version 
is the operative version; that is, the version that is in effect for the IAM users, groups, 
and roles that the policy is attached to.

=over

=item PolicyArn (required)

The Amazon Resource Name (ARN). ARNs are unique identifiers for AWS resources.

=item PolicyDocument (required)

The policy document.

=item SetAsDefault (optional)

Specifies whether to set this version as the policy's default version.

When this parameter is true, the new policy version becomes the operative 
version; that is, the version that is in effect for the IAM users, groups, 
and roles that the policy is attached to.

=back

Returns L<Net::Amazon::IAM::PolicyVersion> on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub create_policy_version {
   my $self = shift;

   my %args = validate(@_, {
      PolicyArn      => { type => SCALAR },
      PolicyDocument => { type => HASHREF },
      SetAsDefault   => { regex => qr/true|false/s, optional => 1 },
   });

   $args{'PolicyDocument'} = encode_json delete $args{'PolicyDocument'};

   my $xml = $self->_sign(Action => 'CreatePolicyVersion', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return Net::Amazon::IAM::PolicyVersion->new(
         $xml->{'CreatePolicyVersionResult'}{'PolicyVersion'},
      );
   }
}

=head2 delete_policy_version(%params)

=over

=item PolicyArn (required)

The Amazon Resource Name (ARN). ARNs are unique identifiers for AWS resources.

=item VersionId (required)

The policy version to delete.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub delete_policy_version {
   my $self = shift;

   my %args = validate(@_, {
      PolicyArn => { type => SCALAR },
      VersionId => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'DeletePolicyVersion', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 put_user_policy(%params)

Adds (or updates) an inline policy document that is embedded in the specified user.

=over

=item PolicyDocument (required)

The policy document. Must be HashRef.

=item PolicyName (required)

The name of the policy document.

=item UserName (required)

The name of the user to associate the policy with.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub put_user_policy {
   my $self = shift;

   my %args = validate(@_, {
      PolicyDocument => { type => HASHREF },
      PolicyName     => { type => SCALAR },
      UserName       => { type => SCALAR },
   });

   $args{'PolicyDocument'} = encode_json delete $args{'PolicyDocument'};

   my $xml = $self->_sign(Action => 'PutUserPolicy', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 get_user_policy(%params)

Retrieves the specified inline policy document that is embedded in the specified user.

=over

=item PolicyName (required)

The name of the policy document to get.

=item UserName (required)

The name of the user who the policy is associated with.

=back

Returns L<Net::Amazon::IAM::UserPolicy> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub get_user_policy {
   my $self = shift;

   my %args = validate(@_, {
      PolicyName     => { type => SCALAR },
      UserName       => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'GetUserPolicy', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my $user_policy = Net::Amazon::IAM::UserPolicy->new(
         $xml->{'GetUserPolicyResult'}
      );
      $user_policy->{'PolicyDocument'} = decode_json(URI::Encode->new()->decode($user_policy->PolicyDocument));
      return $user_policy;
   }
}

=head2 delete_user_policy(%params)

Deletes the specified inline policy that is embedded in the specified user.

=over

=item PolicyName (required)

The name identifying the policy document to delete.

=item UserName (required)

The name (friendly name, not ARN) identifying the user that the policy is embedded in.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub delete_user_policy {
   my $self = shift;

   my %args = validate(@_, {
      PolicyName     => { type => SCALAR },
      UserName       => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'DeleteUserPolicy', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 list_user_policies(%params)

Lists the names of the inline policies embedded in the specified user.

=over

=item UserName (required)

The name of the user to list policies for.

=back

When found one or more policies, this method will return ArrayRef with policy names.
Once no policies found, will return undef.
L<Net::Amazon::IAM::Error> will be returned on error.

=cut

sub list_user_policies {
   my $self = shift;

   my %args = validate(@_, {
      UserName => { type => SCALAR },
      Marker   => { type => SCALAR, optional => 1 },
      MaxItems => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action => 'ListUserPolicies', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my $policies;

      my %result = %{$xml->{'ListUserPoliciesResult'}};

      if ( grep { defined && length } $result{'PolicyNames'} ) {
         if(ref($result{'PolicyNames'}{'member'}) eq 'ARRAY') {
            $policies = $result{'PolicyNames'}{'member'};
         }else{
            push @$policies, $result{'PolicyNames'}{'member'};
         }
      } else {
         $policies = undef;
      }

      return $policies;
   }
}

=head2 create_access_key(%params)

Creates a new AWS secret access key and corresponding AWS access key ID for the specified user.
The default status for new keys is Active.
If you do not specify a user name, IAM determines the user name implicitly based on the AWS access
key ID signing the request. Because this action works for access keys under the AWS account, you can use
this action to manage root credentials even if the AWS account has no associated users.

B<Important>:

To ensure the security of your AWS account, the secret access key is accessible only during
key and user creation. You must save the key (for example, in a text file) if you want to be
able to access it again. If a secret key is lost, you can delete the access keys for the associated
user and then create new keys.

=over

=item UserName (optional)

The user name that the new key will belong to.

=back

Returns L<Net::Amazon::IAM::AccessKey> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub create_access_key {
   my $self = shift;

   my %args = validate(@_, {
      UserName => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action => 'CreateAccessKey', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return Net::Amazon::IAM::AccessKey->new(
         $xml->{'CreateAccessKeyResult'}{'AccessKey'},
      );
   }
}

=head2 delete_access_key(%params)

Deletes the access key associated with the specified user.

If you do not specify a user name, IAM determines the user name implicitly based
on the AWS access key ID signing the request. Because this action works for access
keys under the AWS account, you can use this action to manage root credentials even
if the AWS account has no associated users.

=over

=item AccessKeyId (required)

The access key ID for the access key ID and secret access key you want to delete.

=item UserName (optional)

The name of the user whose key you want to delete.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub delete_access_key {
   my $self = shift;

   my %args = validate(@_, {
      AccessKeyId => { type => SCALAR },
      UserName    => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action => 'DeleteAccessKey', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 update_access_key(%params)

Changes the status of the specified access key from Active to Inactive, or vice versa. 
This action can be used to disable a user's key as part of a key rotation work flow.

If the UserName field is not specified, the UserName is determined implicitly based 
on the AWS access key ID used to sign the request. Because this action works for access
keys under the AWS account, you can use this action to manage root credentials even if 
the AWS account has no associated users.

=over

=item AccessKeyId (required)

The access key ID of the secret access key you want to update.

=item Status (required)

The status you want to assign to the secret access key. 
Active means the key can be used for API calls to AWS, while Inactive 
means the key cannot be used.

=item UserName (optional)

The name of the user whose key you want to update.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub update_access_key {
   my $self = shift;

   my %args = validate(@_, {
      AccessKeyId => { type => SCALAR },
      Status      => { regex => qr/Active|Inactive/ },
      UserName    => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action => 'UpdateAccessKey', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   } 
}

=head2 list_access_keys(%params)

Returns information about the access key IDs associated with the specified user.
If the UserName field is not specified, the UserName is determined implicitly based on the AWS access
key ID used to sign the request. Because this action works for access keys under the AWS account,
you can use this action to manage root credentials even if the AWS account has no associated users.

=over

=item UserName (optional)

The name of the user.

=back

Returns Net::Amazon::IAM::AccessKeysList on success.
If specified user has no keys, "Keys" attribute of L<Net::Amazon::IAM::AccessKeysList> object
will be just empty array.
Returns L<Net::Amazon::IAM::Error> on fail.

=cut

sub list_access_keys {
   my $self = shift;

   my %args = validate(@_, {
      UserName => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action => 'ListAccessKeys', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my %result = %{$xml->{'ListAccessKeysResult'}};
      my $keys   = $self->_parse_attributes('AccessKeyMetadata', 'AccessKeyMetadata', %result);

      return Net::Amazon::IAM::AccessKeysList->new(
         Keys => $keys,
      );
   }
}

=head2 create_role(%params)

Creates a new role for your AWS account.

The example policy grants permission to an EC2 instance to assume the role.
   {
      "Version": "2012-10-17",
      "Statement": [{
         "Effect": "Allow",
         "Principal": {
            "Service": ["ec2.amazonaws.com"]
         },
            "Action": ["sts:AssumeRole"]
      }]
   }

=over

=item AssumeRolePolicyDocument (required)

The policy that grants an entity permission to assume the role.

=item RoleName (required)

The name of the role to create.

=item Path (optional)

The path to the role. 

=back

Returns L<Net::Amazon::IAM::Role> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub create_role {
   my $self = shift;

   my %args = validate(@_, {
      AssumeRolePolicyDocument => { type => HASHREF },
      RoleName                 => { type => SCALAR },
      Path                     => { type => SCALAR, optional => 1 },
   });

   $args{'AssumeRolePolicyDocument'} = encode_json delete $args{'AssumeRolePolicyDocument'};

   my $xml = $self->_sign(Action => 'CreateRole', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return Net::Amazon::IAM::Role->new(
         $xml->{'CreateRoleResult'}{'Role'},
      );
   }
}

=head2 get_role(%params)

Retrieves information about the specified role.

=over

=item RoleName (required)

The name of the role to get information about.

=back

Returns L<Net::Amazon::IAM::Role> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub get_role {
   my $self = shift;

   my %args = validate(@_, {
      RoleName => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'GetRole', %args);

   if( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   }else{
      my $role = Net::Amazon::IAM::Role->new(
         $xml->{'GetRoleResult'}{'Role'},
      );

      $role->{'AssumeRolePolicyDocument'} = decode_json(
         URI::Encode->new()->decode($role->AssumeRolePolicyDocument)
      );

      return $role;
   }
}

=head2 list_roles(%params)

Retrieves information about the specified role.

=over

=item Marker (optional)

Use this parameter only when paginating results, and only in a subsequent 
request after you've received a response where the results are truncated. 
Set it to the value of the Marker element in the response you just received.

=item MaxItems (optional)

Use this parameter only when paginating results to indicate the maximum number 
of roles you want in the response. If there are additional roles beyond the maximum 
you specify, the IsTruncated response element is true. This parameter is optional. 
If you do not include it, it defaults to 100.

=item PathPrefix (optional)

The path prefix for filtering the results. For example, the prefix /application_abc/component_xyz/ 
gets all roles whose path starts with /application_abc/component_xyz/.

This parameter is optional. If it is not included, it defaults to a slash (/), listing all roles.

=back

Returns L<Net::Amazon::IAM::Roles> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub list_roles {
   my $self = shift;

   my %args = validate(@_, {
      Marker     => { type => SCALAR, optional => 1 },
      MaxItems   => { type => SCALAR, optional => 1 },
      PathPrefix => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action => 'ListRoles', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my %result = %{$xml->{'ListRolesResult'}};
      my $roles  = $self->_parse_attributes('Role', 'Roles', %result);

      return Net::Amazon::IAM::Roles->new(
         Roles       => $roles,
         Marker      => $result{'Marker'},
         IsTruncated => $result{'IsTruncated'},
      );
   }
}

=head2 delete_role(%params)

Deletes the specified role. The role must not have any policies attached.

B<Important>:

Make sure you do not have any Amazon EC2 instances running with the role you are about to delete. 
Deleting a role or instance profile that is associated with a running instance will break any 
applications running on the instance.

=over

=item RoleName (required)

The name of the role to delete.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub delete_role {
   my $self = shift;

   my %args = validate(@_, {
      RoleName => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'DeleteRole', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 put_role_policy(%params)

Adds (or updates) an inline policy document that is embedded in the specified role.

=over

=item PolicyDocument (required)

The policy document.

=item PolicyName (required)

The name of the policy document.

=item RoleName (required)

The name of the role to associate the policy with.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub put_role_policy {
   my $self = shift;

   my %args = validate(@_, {
      PolicyDocument => { type => HASHREF },
      PolicyName     => { type => SCALAR },
      RoleName       => { type => SCALAR },
   });

   $args{'PolicyDocument'} = encode_json delete $args{'PolicyDocument'};

   my $xml = $self->_sign(Action => 'PutRolePolicy', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 create_virtual_MFA_device(%params)

Creates a new virtual MFA device for the AWS account. 
After creating the virtual MFA, use EnableMFADevice to 
attach the MFA device to an IAM user. 

B<Important>:

The seed information contained in the QR code and the Base32 string 
should be treated like any other secret access information, such as 
your AWS access keys or your passwords. After you provision your virtual 
device, you should ensure that the information is destroyed following 
secure procedures.

=over

=item VirtualMFADeviceName (required)

The name of the virtual MFA device. Use with path to uniquely identify a virtual MFA device.

=item Path (required)

The path for the virtual MFA device.

=back

Returns L<Net::Amazon::IAM::VirtualMFADevice> object on success or L<Net::Amazon::IAM::Error> on fail.

B<This method wasn't tested>

=cut

sub create_virtual_MFA_device {
   my $self = shift;

   my %args = validate(@_, {
      VirtualMFADeviceName => { type => SCALAR },
      Path                 => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action => 'CreateVirtualMFADevice', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return Net::Amazon::IAM::VirtualMFADevice->new(
         $xml->{'CreateVirtualMFADeviceResult'}{'VirtualMFADevice'},
      );
   }
}

=head2 delete_virtual_MFA_device(%params)

Deletes a virtual MFA device.

B<Note>:

You must deactivate a user's virtual MFA device before you can delete it.

=over

=item SerialNumber (required)

The serial number that uniquely identifies the MFA device. 
For virtual MFA devices, the serial number is the same as the ARN.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

B<This method wasn't tested>

=cut

sub delete_virtual_MFA_device {
   my $self = shift;

   my %args = validate(@_, {
      SerialNumber => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'DeleteVirtualMFADevice', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 list_virtual_MFA_devices(%params)

Lists the virtual MFA devices under the AWS account by assignment status. 

=over

=item Marker (optional)

Use this parameter only when paginating results, and only in a subsequent 
request after you've received a response where the results are truncated. 
Set it to the value of the Marker element in the response you just received.

=item MaxItems (optional)

Use this parameter only when paginating results to indicate the maximum number 
of VirtualMFADevices you want in the response. If there are additional devices beyond the maximum 
you specify, the IsTruncated response element is true. This parameter is optional. 
If you do not include it, it defaults to 100.

=item AssignmentStatus (optional)

The status (unassigned or assigned) of the devices to list. 
If you do not specify an AssignmentStatus, the action defaults to Any 
which lists both assigned and unassigned virtual MFA devices.

Valid Values: Assigned | Unassigned | Any

=back

Returns L<Net::Amazon::IAM::MFADevices> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub list_virtual_MFA_devices {
   my $self = shift;

   my %args = validate(@_, {
      AssignmentStatus => { regex => qr/Assigned|Unassigned|Any/, optional => 1 },
      Marker           => { type => SCALAR, optional => 1 },
      MaxItems         => { type => SCALAR, optional => 1 },
   }); 

   my $xml = $self->_sign(Action => 'ListVirtualMFADevices', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my $devices;

      my %result = %{$xml->{'ListVirtualMFADevicesResult'}};

      if ( grep { defined && length } $result{'MFADevices'} ) {
         if(ref($result{'VirtualMFADevices'}{'member'}) eq 'ARRAY') {
            for my $device(@{$result{'VirtualMFADevices'}{'member'}}) {
               my $d = Net::Amazon::IAM::VirtualMFADevice->new(
                  $device,
               );
               push @$devices, $d;
            }
         }else{
            my $d = Net::Amazon::IAM::VirtualMFADevice->new(
               $result{'VirtualMFADevices'}{'member'},
            );
            push @$devices, $d;
         }
      }else{
         $devices = [];
      }

      return Net::Amazon::IAM::VirtualMFADevices->new(
         VirtualMFADevices  => $devices,
         Marker             => $result{'Marker'},
         IsTruncated        => $result{'IsTruncated'},
      );
   }
}

=head2 enable_MFA_device(%params)

Enables the specified MFA device and associates it with the specified user name. 
When enabled, the MFA device is required for every subsequent login by the user 
name associated with the device.

=over

=item AuthenticationCode1 (required)

An authentication code emitted by the device.

=item AuthenticationCode2 (required)

A subsequent authentication code emitted by the device.

=item SerialNumber (required)

The serial number that uniquely identifies the MFA device. 
For virtual MFA devices, the serial number is the device ARN.

=item UserName (required)

The name of the user for whom you want to enable the MFA device.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

B<This method wasn't tested>

=cut

sub enable_MFA_device {
   my $self = shift;

   my %args = validate(@_, {
      AuthenticationCode1 => { type => SCALAR },
      AuthenticationCode2 => { type => SCALAR },
      SerialNumber        => { type => SCALAR },
      UserName            => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'EnableMFADevice', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 deactivate_MFA_device(%params)

Enables the specified MFA device and associates it with the specified user name. 
When enabled, the MFA device is required for every subsequent login by the user 
name associated with the device.

=over

=item SerialNumber (required)

The serial number that uniquely identifies the MFA device. 
For virtual MFA devices, the serial number is the device ARN.

=item UserName (required)

The name of the user whose MFA device you want to deactivate.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

B<This method wasn't tested>

=cut

sub deactivate_MFA_device {
   my $self = shift;

   my %args = validate(@_, {
      SerialNumber        => { type => SCALAR },
      UserName            => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'DeactivateMFADevice', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 list_MFA_devices(%params)

Retrieves information about the specified role.

=over

=item Marker (optional)

Use this parameter only when paginating results, and only in a subsequent 
request after you've received a response where the results are truncated. 
Set it to the value of the Marker element in the response you just received.

=item MaxItems (optional)

Use this parameter only when paginating results to indicate the maximum number 
of MFADevices you want in the response. If there are additional devices beyond the maximum 
you specify, the IsTruncated response element is true. This parameter is optional. 
If you do not include it, it defaults to 100.

=item UserName (optional)

The name of the user whose MFA devices you want to list.

=back

Returns L<Net::Amazon::IAM::MFADevices> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub list_MFA_devices {
   my $self = shift;

   my %args = validate(@_, {
      Marker   => { type => SCALAR, optional => 1 },
      MaxItems => { type => SCALAR, optional => 1 },
      UserName => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action => 'ListMFADevices', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my $devices;

      my %result = %{$xml->{'ListMFADevicesResult'}};

      if ( grep { defined && length } $result{'MFADevices'} ) {
         if(ref($result{'MFADevices'}{'member'}) eq 'ARRAY') {
            for my $device(@{$result{'MFADevices'}{'member'}}) {
               my $d = Net::Amazon::IAM::MFADevice->new(
                  $device,
               );
               push @$devices, $d;
            }
         }else{
            my $d = Net::Amazon::IAM::MFADevice->new(
               $result{'MFADevices'}{'member'},
            );
            push @$devices, $d;
         }
      }else{
         $devices = [];
      }

      return Net::Amazon::IAM::MFADevices->new(
         MFADevices  => $devices,
         Marker      => $result{'Marker'},
         IsTruncated => $result{'IsTruncated'},
      );
   }
}

=head2 create_instance_profile(%params)

Creates a new instance profile.

=over

=item InstanceProfileName (required)

The name of the instance profile to create.

=item Path (optional)

The path to the instance profile.

=back

Returns L<Net::Amazon::IAM::InstanceProfile> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut


sub create_instance_profile {
   my $self = shift;

   my %args = validate(@_, {
      InstanceProfileName => { type => SCALAR },
      Path                => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action => 'CreateInstanceProfile', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return Net::Amazon::IAM::InstanceProfile->new(
         $xml->{'CreateInstanceProfileResult'}{'InstanceProfile'},
      );
   }
}

=head2 get_instance_profile(%params)

Retrieves information about the specified instance profile, 
including the instance profile's path, GUID, ARN, and role.

=over

=item InstanceProfileName (required)

The name of the instance profile to get information about.

=back

Returns L<Net::Amazon::IAM::InstanceProfile> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub get_instance_profile {
   my $self = shift;

   my %args = validate(@_, {
      InstanceProfileName => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'GetInstanceProfile', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my %result    = %{$xml->{'GetInstanceProfileResult'}{'InstanceProfile'}};
      my $roles     = $self->_parse_attributes('Role', 'Roles', %result);

      my $roles_obj = Net::Amazon::IAM::Roles->new(
         Roles => $roles,
      );

      return Net::Amazon::IAM::InstanceProfile->new(
         Arn                 => $result{'Arn'},
         CreateDate          => $result{'CreateDate'},
         InstanceProfileId   => $result{'InstanceProfileId'},
         InstanceProfileName => $result{'InstanceProfileName'},
         Path                => $result{'Path'},
         Roles               => $roles_obj,
      );
   }
}

=head2 list_instance_profiles(%params)

Lists the instance profiles that have the specified path prefix.

=over

=item Marker (optional)

Use this parameter only when paginating results, and only in a subsequent 
request after you've received a response where the results are truncated. 
Set it to the value of the Marker element in the response you just received.

=item MaxItems (optional)

Use this parameter only when paginating results to indicate the maximum number
of instance profiles you want in the response. If there are additional instance 
profiles beyond the maximum you specify, the IsTruncated response element is true. 
This parameter is optional. If you do not include it, it defaults to 100.

=item PathPrefix (optional)

The path prefix for filtering the results. For example, the prefix 
/application_abc/component_xyz/ gets all instance profiles whose path 
starts with /application_abc/component_xyz/.

=back

Returns L<Net::Amazon::IAM::InstanceProfiles> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub list_instance_profiles {
   my $self = shift;

   my %args = validate(@_, {
      Marker     => { type => SCALAR, optional => 1 },
      MaxItems   => { type => SCALAR, optional => 1 },
      PathPrefix => { type => SCALAR, optional => 1 },
   });

   my $xml = $self->_sign(Action => 'ListInstanceProfiles', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my %result = %{$xml->{'ListInstanceProfilesResult'}};
      my $instance_profiles = $self->_parse_attributes('InstanceProfile', 'InstanceProfiles', %result);

      for my $profile (@{$instance_profiles}) {
         my %roles;
         $roles{'Roles'} = $profile->{'Roles'};
         my $roles = $self->_parse_attributes('Role', 'Roles', %roles);

         my $roles_obj = Net::Amazon::IAM::Roles->new(
            Roles => $roles,
         );

         $profile->{'Roles'} = $roles_obj;
      }

      return Net::Amazon::IAM::InstanceProfiles->new(
         InstanceProfiles  => $instance_profiles,
         Marker            => $result{'Marker'},
         IsTruncated       => $result{'IsTruncated'},
      );
   }
}

=head2 delete_instance_profile(%params)

Deletes the specified instance profile. The instance profile must not have an associated role.

=over

=item InstanceProfileName (required)

The name of the instance profile to delete.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub delete_instance_profile {
   my $self = shift;

   my %args = validate(@_, {
      InstanceProfileName => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'DeleteInstanceProfile', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 add_role_to_instance_profile(%params)

Adds the specified role to the specified instance profile.

=over

=item InstanceProfileName (required)

The name of the instance profile to update.

=item RoleName (required)

The name of the role to add.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub add_role_to_instance_profile {
   my $self = shift;

   my %args = validate(@_, {
      InstanceProfileName => { type => SCALAR },
      RoleName            => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'AddRoleToInstanceProfile', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 remove_role_from_instance_profile(%params)

Removes the specified role from the specified instance profile.

B<Important>:

Make sure you do not have any Amazon EC2 instances running with the role 
you are about to remove from the instance profile. Removing a role from an 
instance profile that is associated with a running instance will break any 
applications running on the instance.

=over

=item InstanceProfileName (required)

The name of the instance profile to update.

=item RoleName (required)

The name of the role to remove.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub remove_role_from_instance_profile {
   my $self = shift;

   my %args = validate(@_, {
      InstanceProfileName => { type => SCALAR },
      RoleName            => { type => SCALAR },
   });

   my $xml = $self->_sign(Action => 'RemoveRoleFromInstanceProfile', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 list_instance_profiles_for_role(%params)

Lists the instance profiles that have the specified associated role.

=over

=item RoleName (required)

The name of the role to list instance profiles for.

=item MaxItems (optional)

Use this parameter only when paginating results to indicate the maximum number of 
instance profiles you want in the response. If there are additional instance profiles 
beyond the maximum you specify, the IsTruncated response element is true. This parameter 
is optional. If you do not include it, it defaults to 100.

=item Marker (optional)

Use this parameter only when paginating results, and only in a subsequent request 
after you've received a response where the results are truncated. Set it to the 
value of the Marker element in the response you just received.

=back

Returns L<Net::Amazon::IAM::InstanceProfiles> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub list_instance_profiles_for_role {
   my $self = shift;

   my %args = validate(@_, {
      RoleName => { type => SCALAR },
      Marker   => { type => SCALAR, optional => 1 },
      MaxItems => { type => SCALAR, optional => 1 },
   }); 

   my $xml = $self->_sign(Action => 'ListInstanceProfilesForRole', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my %result = %{$xml->{'ListInstanceProfilesForRoleResult'}};
      my $instance_profiles = $self->_parse_attributes('InstanceProfile', 'InstanceProfiles', %result);

      for my $profile (@{$instance_profiles}) {
         my %roles;
         $roles{'Roles'} = $profile->{'Roles'};
         my $roles = $self->_parse_attributes('Role', 'Roles', %roles);

         my $roles_obj = Net::Amazon::IAM::Roles->new(
            Roles => $roles,
         );

         $profile->{'Roles'} = $roles_obj;
      }

      return Net::Amazon::IAM::InstanceProfiles->new(
         InstanceProfiles  => $instance_profiles,
         Marker            => $result{'Marker'},
         IsTruncated       => $result{'IsTruncated'},
      );
   }
}

=head2 create_login_profile(%params)

Lists the instance profiles that have the specified associated role.

=over

=item UserName (required)

The name of the user to create a password for.

=item Password (required)

The new password for the user.

=item PasswordResetRequired (optional)

Specifies whether the user is required to set a new password on next sign-in.

=back

Returns L<Net::Amazon::IAM::LoginProfile> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub create_login_profile {
   my $self = shift;

   my %args = validate(@_, {
      Password              => { type => SCALAR },
      UserName              => { type => SCALAR },
      PasswordResetRequired => { type => SCALAR, optional => 1 },
   }); 

   my $xml = $self->_sign(Action => 'CreateLoginProfile', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return Net::Amazon::IAM::LoginProfile->new(
         $xml->{'CreateLoginProfileResult'}{'LoginProfile'},
      );
   }
}

=head2 delete_login_profile(%params)

Deletes the password for the specified user, which terminates the user's ability 
to access AWS services through the AWS Management Console.

B<Important>:
Deleting a user's password does not prevent a user from accessing IAM through 
the command line interface or the API. To prevent all user access you must also either 
make the access key inactive or delete it. For more information about making keys inactive 
or deleting them, see update_access_key and delete_access_key.

=over

=item UserName (required)

The name of the user whose password you want to delete.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub delete_login_profile {
   my $self = shift;

   my %args = validate(@_, {
      UserName => { type => SCALAR },
   }); 

   my $xml = $self->_sign(Action => 'DeleteLoginProfile', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 get_login_profile(%params)

Retrieves the user name and password-creation date for the specified user. 
If the user has not been assigned a password, the action returns a 404 (NoSuchEntity) error.

=over

=item UserName (required)

The name of the user whose login profile you want to retrieve.

=back

Returns L<Net::Amazon::IAM::LoginProfile> object on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub get_login_profile {
   my $self = shift;

   my %args = validate(@_, {
      UserName => { type => SCALAR },
   }); 

   my $xml = $self->_sign(Action => 'GetLoginProfile', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return Net::Amazon::IAM::LoginProfile->new(
         $xml->{'GetLoginProfileResult'}{'LoginProfile'},
      );
   }
}

=head2 update_login_profile(%params)

Changes the password for the specified user.

=over

=item UserName (required)

The name of the user whose password you want to update.

=item Password (required)

The new password for the specified user.

=item PasswordResetRequired (optional)

Require the specified user to set a new password on next sign-in.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub update_login_profile {
   my $self = shift;

   my %args = validate(@_, {
      UserName              => { type => SCALAR },
      Password              => { type => SCALAR, optional => 1 },
      PasswordResetRequired => { type => SCALAR, optional => 1 },
   }); 

   my $xml = $self->_sign(Action => 'UpdateLoginProfile', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 update_assume_role_policy(%params)

Updates the policy that grants an entity permission to assume a role.

=over

=item RoleName (required)

The name of the role to update.

=item PolicyDocument (required)

The policy that grants an entity permission to assume the role.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub update_assume_role_policy {
   my $self = shift;

   my %args = validate(@_, {
      RoleName       => { type => SCALAR },
      PolicyDocument => { type => HASHREF },
   }); 

   $args{'PolicyDocument'} = encode_json delete $args{'PolicyDocument'};
   
   my $xml = $self->_sign(Action => 'UpdateAssumeRolePolicy', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 add_client_ID_to_open_ID_connect_provider(%params)

Adds a new client ID (also known as audience) to the list of client IDs already registered for 
the specified IAM OpenID Connect provider.

This action is idempotent; it does not fail or return an error if you add an existing client 
ID to the provider.

=over

=item ClientID (required)

The client ID (also known as audience) to add to the IAM OpenID Connect provider.

=item OpenIDConnectProviderArn (required)

The Amazon Resource Name (ARN) of the IAM OpenID Connect (OIDC) provider to add the client ID to.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

B<This method wasn't tested>

=cut

sub add_client_ID_to_open_ID_connect_provider {
   my $self = shift;

   my %args = validate(@_, {
      ClientID                 => { type => SCALAR },
      OpenIDConnectProviderArn => { type => SCALAR },
   }); 

   my $xml = $self->_sign(Action => 'AddClientIDToOpenIDConnectProvider', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 create_open_ID_connect_provider(%params)

Creates an IAM entity to describe an identity provider (IdP) that supports OpenID Connect (OIDC).

=over

=item ClientIDList (required)

A list of client IDs (also known as audiences). When a mobile or web app registers with 
an OpenID Connect provider, they establish a value that identifies the application. 
(This is the value that's sent as the client_id parameter on OAuth requests.)

You can register multiple client IDs with the same provider. For example, you might have 
multiple applications that use the same OIDC provider. You cannot register more than 100 
client IDs with a single IAM OIDC provider.

=item ThumbprintList (required)

A list of server certificate thumbprints for the OpenID Connect (OIDC) identity provider's 
server certificate(s). Typically this list includes only one entry. However, IAM lets you 
have up to five thumbprints for an OIDC provider. This lets you maintain multiple thumbprints 
if the identity provider is rotating certificates.

The server certificate thumbprint is the hex-encoded SHA-1 hash value of the X.509 certificate 
used by the domain where the OpenID Connect provider makes its keys available. It is always a 
40-character string.

You must provide at least one thumbprint when creating an IAM OIDC provider. For example, if the 
OIDC provider is server.example.com and the provider stores its keys at 
"https://keys.server.example.com/openid-connect", the thumbprint string would be the hex-encoded 
SHA-1 hash value of the certificate used by https://keys.server.example.com.

=item Url (required)

The URL of the identity provider. The URL must begin with "https://" and should correspond to 
the iss claim in the provider's OpenID Connect ID tokens. Per the OIDC standard, path components 
are allowed but query parameters are not. Typically the URL consists of only a host name, like 
"https://server.example.org" or "https://example.com".

You cannot register the same provider multiple times in a single AWS account. If you try to 
submit a URL that has already been used for an OpenID Connect provider in the AWS account, 
you will get an error.

=back

Returns OpenIDConnectProviderArn on success or L<Net::Amazon::IAM::Error> on fail.

B<This method wasn't tested>

=cut

sub create_open_ID_connect_provider {
   my $self = shift;

   my %args = validate(@_, {
      ClientIDList   => { type => ARRAYREF, optional => 1 },
      ThumbprintList => { type => ARRAYREF },
      Url            => { type => SCALAR },
   }); 

   my $client_ids_list  = delete $args{'ClientIDList'};
   my $thumb_print_list = delete $args{'ThumbprintList'};

   my $c_count = 1;
   for my $id(@{$client_ids_list}) {
      $args{'ClientIDList.list.' . $c_count} = $id;
      $c_count++;
   }

   my $t_count = 1;
   for my $thumb(@{$thumb_print_list}) {
      $args{'ThumbprintList.list.' . $t_count} = $thumb;
      $t_count++;
   }

   my $xml = $self->_sign(Action => 'CreateOpenIDConnectProvider', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return $xml->{'CreateOpenIDConnectProviderResult'}{'OpenIDConnectProviderArn'}
   }
}

=head2 delete_open_ID_connect_provider(%params)

Deletes an IAM OpenID Connect identity provider.

Deleting an OIDC provider does not update any roles that reference the provider as a 
principal in their trust policies. Any attempt to assume a role that references a 
provider that has been deleted will fail.

This action is idempotent; it does not fail or return an error if you call the action 
for a provider that was already deleted.

=over

=item OpenIDConnectProviderArn (required)

The Amazon Resource Name (ARN) of the IAM OpenID Connect provider to delete.

=back

Returns true on success or L<Net::Amazon::IAM::Error> on fail.

B<This method wasn't tested>

=cut

sub delete_open_ID_connect_provider {
   my $self = shift;

   my %args = validate(@_, {
      OpenIDConnectProviderArn   => { type => SCALAR },
   }); 

   my $xml = $self->_sign(Action => 'DeleteOpenIDConnectProvider', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      return 1;
   }
}

=head2 get_group_policy(%params)

=over

=item GroupName (required)

The name of the group the policy is associated with.

=item PolicyName (required)

The name of the policy document to get.

=back

Returns L<Net::Amazon::IAM::GroupPolicy> on success or L<Net::Amazon::IAM::Error> on fail.

=cut

sub get_group_policy {
   my $self = shift;

   my %args = validate(@_, {
      GroupName  => { type => SCALAR },
      PolicyName => { type => SCALAR },
   }); 

   my $xml = $self->_sign(Action => 'GetGroupPolicy', %args);

   if ( grep { defined && length } $xml->{'Error'} ) {
      return $self->_parse_errors($xml);
   } else {
      my %result = ${$xml->{'GetGroupPolicyResult'}};
      $result{'PolicyDocument'} = decode_json(URI::Encode->new()->decode($result{'PolicyDocument'}));

      return Net::Amazon::IAM::GroupPolicy->new(
         %result,
      );
   }
}

no Moose;
1;

=head1 KNOWN ISSUES

* missing some ( a lot of ) methods

* missing tests

* list_user_policies returns just an ArrayRef.

=head1 SEE ALSO

=over

=item Amazon IAM API reference

http://docs.aws.amazon.com/IAM/latest/APIReference/Welcome.html

=back

=head1 AUTHOR

Igor Tsigankov <tsiganenok@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2015 Igor Tsigankov.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__END__
