package Net::AppDynamics::REST;

use Modern::Perl;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use AnyEvent::HTTP::MultiGet;
use JSON qw();
use Data::Dumper;
use Carp qw(croak);
use MIME::Base64 qw();
use URI::Escape;
use HTTP::Request;
use HTTP::Headers;
use Ref::Util qw(is_plain_arrayref);
use namespace::clean;
BEGIN { 
  with 'HTTP::MultiGet::Role';
}
our $AUTOLOAD;
 

=head1 NAME

Net::AppDynamics::REST - AppDynamics AnyEvent Friendly REST Client

=head1 SYNOPSIS

  use Net::AppDynamics::REST;
  use AnyEvent;

  my $cv=AnyEvent->condvar;
  my $obj=Net::AppDynamics::REST->new(PASS=>'password',USER=>'Username',SERVER=>'SERVERNAME');

  # to get a list of applications in a non blocking context
  my $resut=$obj->list_applications;

  # get a list of applications in a non blocking context
  $cv->begin;
  $obj->que_list_applications(sub {
    my ($self,$id,$result,$request,$response)=@_;
    $cv->end;
  });
  $obj->agent->run_next;
  $cv->recv;

=head1 DESCRIPTION

Appdynamics AnyEvent friendly Rest client.

=head1 OO Declarations

Required

  USER: Sets the user appd
  PASS: Sets the password
  SERVER: Sets the server

Optional

  logger: sets the logging object
  CUSTOMER: default customer1
  PORT: default 8090
  PROTO: default http
  cache_max_age: how long to keep the cache for in seconds
    default value is 3600
  agent: Gets/Sets the AnyEvent::HTTP::MultiGet object we will use

For Internal use

  data_cache: Data structure used to cache object resolion
  cache_check: boolean value, if true a cache check is in progress

=head2 Moo::Roles

This module makes use of the following roles:  L<HTTP::MultiGet::Role>, L<Log::LogMethods> and L<Data::Result::Moo>

=cut

our $VERSION="1.004";

has USER=>(
  is=>'ro',
  isa=>Str,
  required=>1,
);

has cache_check=>(
  is=>'rw',
  isa=>Bool
  default=>0,
);

has CUSTOMER=>(
  required=>1,
  is=>'ro',
  isa=>Str,
  default=>'customer1',
);

has PASS=>(
  is=>'ro',
  isa=>Str,
  required=>1,
);

has SERVER=>(
  is=>'ro',
  isa=>Str,
  required=>1,
);

has PORT=>(
  is=>'ro',
  isa=>Int,
  default=>8090,
  required=>1,
);

has PROTO=>(
  is=>'rw',
  isa=>Str,
  default=>'http',
  required=>1,
);

has data_cache=>(
  is=>'rw',
  isa=>HashRef,
  required=>1,
  lazy=>1,
  default=>sub { {created_on=>0} },
);

has cache_max_age =>(
  is=>'ro',
  isa=>Num,
  lazy=>1,
  required=>1,
  default=>3600,
);

# This method runs after the new constructor
sub BUILD {
  my ($self)=@_;
  my $auth='Basic '.MIME::Base64::encode_base64($self->{USER} . '@' . $self->{CUSTOMER} . ':' . $self->{PASS});
  $auth=~ s/\s*$//s;
  $self->{header}=[ Authorization=>$auth ];
}

# this method runs before the new constructor, and can be used to change the arguments passed to the module
around BUILDARGS => sub {
  my ($org,$class,@args)=@_;
  
  return $class->$org(@args);
};


=head1 NonBlocking interfaces

All methods with a prefix of que_xxx are considered non blocking interfaces.

Default Callback arguments:

  my $code=sub {
    # 0: this Net::AppDynamics::REST Object
    # 1: id, for internal use
    # 2: Data::Result Final object ( if failed, it will say why it failed )
    # 3: HTTP::Request Last Object|undef
    # 4: HTTP::Response Last Object|undef
    my ($self,$id,$result,$request,$response)=@_;
  };

=head1 Blocking Interfaces

All interfaces that are prefixed with que_xxx have a corisponding blocking method that is simply the xxx portion of the method name.

Example Non Blocking version of que_list_applicatinos:

  my $result->list_applicatinos();

When called without the que context the methods provides the more traditional blocking style inteface.  When called in a blocking context only the Data::Result Object is returned.

=head1 Application Model API


=head2 Listing Applications 

=over 4

=item * Blocking context my $result=$self->list_applications

Returns a Data::Result object, when true it contains the Listing of Applications, when false it contains why it failed.

=cut

=item * Non Blocking context my $id=$self->que_list_applicatinos($cb)

Queues a requst to fetch the list of all applications.

Example Callback: 

  my $cb=sub {
    my ($self,$id,$result,$request,$result)=@_;
    # 0 Net::AppDynamics::REST Object
    # 1 Id of the request
    # 2 Data::Result Object
    # 3 HTTP::Request Object
    # 4 HTTP::Result Object
  };

=cut

sub que_list_applications {
  my ($self,$cb)=@_;
  my $path='/controller/rest/applications';
  my $req=$self->create_get($path);
  return $self->queue_request($req,$cb);
}

=back

=head3 Listing Tiers

Each Application can contain many Tiers

=over 4

=item * Blocking context my $result=$self->list_tiers($application);

Returns a Data::Result Object, when true it contains the Listing of Tiers

=item * Non Blocking context my $id=$self->que_list_tiers($cb,$application);

Queues a request to fetch the list of tiers within a given application.

Example Callback: 

  my $cb=sub {
    my ($self,$id,$result,$request,$result)=@_;
    # 0 Net::AppDynamics::REST Object
    # 1 Id of the request
    # 2 Data::Result Object
    # 3 HTTP::Request Object
    # 4 HTTP::Result Object
  };

=cut

sub que_list_tiers {
  my ($self,$cb,$app)=@_;
  my $path=sprintf '/controller/rest/applications/%s/tiers',uri_escape($app);
  
  my $req=$self->create_get($path);
  return $self->queue_request($req,$cb);
}

=back

=head4 Listing Tier Details

=over 4

=item * Blocking context my $result=$self->list_tier($application,$tier);

Returns a Data::Result object, when true it contains the list of tiers.

=item * Non BLocking Context my $id=$self->que_list_tier($cb,$application,$tier);

Ques a request for the details of the application tier.

Example Callback: 

  my $cb=sub {
    my ($self,$id,$result,$request,$result)=@_;
    # 0 Net::AppDynamics::REST Object
    # 1 Id of the request
    # 2 Data::Result Object
    # 3 HTTP::Request Object
    # 4 HTTP::Result Object
  };

=cut

sub que_list_tier {
  my ($self,$cb,$app,$tier)=@_;
  my $path=sprintf '/controller/rest/applications/%s/tiers/%s',uri_escape($app),uri_escape($tier);
  
  my $req=$self->create_get($path);
  return $self->queue_request($req,$cb);
}

=back

=head3 Listing Busuness Transactions

Each Application can contain many business transactions.

=over 4

=item * Blocking context my $result=$self->list_business_transactions($application)

=item * Non Blocking context my $id=$self->que_list_business_transactions($cb,$application)

Queues a request to fetch the list of business transactions for a given application

Example Callback: 

  my $cb=sub {
    my ($self,$id,$result,$request,$result)=@_;
    # 0 Net::AppDynamics::REST Object
    # 1 Id of the request
    # 2 Data::Result Object
    # 3 HTTP::Request Object
    # 4 HTTP::Result Object
  };

=cut

sub que_list_business_transactions {
  my ($self,$cb,$app)=@_;
  my $path=sprintf '/controller/rest/applications/%s/business-transactions',uri_escape($app);
  
  my $req=$self->create_get($path);
  return $self->queue_request($req,$cb);
}

=back

=head3 List Nodes

Each Application will contain many nodes

=over 4

=item * Blocking context my $result=$self->list_nodes($application)

Returns a Data::Result object, when true it contains the list of nodes.

=item * Non Blocking context my $id=$self->que_list_nodes($cb,$application)

Ques a request to all the nodes in a given application

Example Callback: 

  my $cb=sub {
    my ($self,$id,$result,$request,$result)=@_;
    # 0 Net::AppDynamics::REST Object
    # 1 Id of the request
    # 2 Data::Result Object
    # 3 HTTP::Request Object
    # 4 HTTP::Result Object
  };

=cut

sub que_list_nodes {
  my ($self,$cb,$app)=@_;
  my $path=sprintf '/controller/rest/applications/%s/nodes',uri_escape($app);
  
  my $req=$self->create_get($path);
  return $self->queue_request($req,$cb);
}

=back

=head4 Listing Node Details

=over 4

=item * Blocking context my $id=$self->list_node($application,$node)

Returns a Data::Result object

=item * Non BLocking context my $id=$self->que_list_node($cb,$application,$node)

Queues a request to list the details of a node in a given tier

Example Callback: 

  my $cb=sub {
    my ($self,$id,$result,$request,$result)=@_;
    # 0 Net::AppDynamics::REST Object
    # 1 Id of the request
    # 2 Data::Result Object
    # 3 HTTP::Request Object
    # 4 HTTP::Result Object
  };

=cut

sub que_list_node {
  my ($self,$cb,$app,$node)=@_;
  my $path=sprintf '/controller/rest/applications/%s/nodes/%s',uri_escape($app),uri_escape($node);
  
  my $req=$self->create_get($path);
  return $self->queue_request($req,$cb);
}

=back

=head3 Listing BackEnds

Each application can contain many backends

=over 4

=item * Non Blocking context my $id=$self->que_list_backends($cb,$application)

Returns a Data::Result Object when true, it contains the list of backends.

=item * Non Blocking context my $id=$self->que_list_backends($cb,$application)

Queues a request to list the backends for a given application

Example Callback: 

  my $cb=sub {
    my ($self,$id,$result,$request,$result)=@_;
    # 0 Net::AppDynamics::REST Object
    # 1 Id of the request
    # 2 Data::Result Object
    # 3 HTTP::Request Object
    # 4 HTTP::Result Object
  };

=cut

sub que_list_backends {
  my ($self,$cb,$app)=@_;
  my $path=sprintf '/controller/rest/applications/%s/backends',uri_escape($app);
  
  my $req=$self->create_get($path);
  return $self->queue_request($req,$cb);
}

=back

=head1 Walking The entire api

THis method walks all aspects of the appdynamics api and returns a data structure.

The structure of $result->get_data when true contains the following anonymous hash.

Objects are listed by ids

  ids: Anonymous hash of ids to object refrerences

  # keys used to map names to object ids
  applications, business_transactions, tiers, nodes
    Each element contains an anonymous hash of of an array refres
      Each element in the array ref refres back to an ids object.

=over 4

=item * Blocking context my $result=$self->walk_all()

Reutruns a Data::Result Object

=item * Non Blocking context my $id=$self->que_walk_all($cb)

Queues a request to walk everything.. $cb arguments are different in this caes, $cb is called with the following arguments.  Keep in mind this walks every single object in mass and up to 20 requests are run at a time ( by default ), so this can put a strain on your controler if run too often.

  my $cb=sub {
    my ($self,$id,$result,$request,$response,$method,$application)=@_;
    # 0: this Net::AppDynamics::REST Object
    # 1: id, for internal use
    # 2: Data::Result Final object ( if failed, it will say why it failed )
    # 3: HTTP::Request Last Object|undef
    # 4: HTTP::Response Last Object|undef
    # 5: method ( wich method this result set is for ) 
    # 6: application ( undef the method is list_applications )
  };

=cut

sub que_walk_all {
  my ($self,$cb)=@_;

  my $state=1;
  my $data={};
  my $total=0;
  my @ids;

  my $app_cb=sub {
    my ($self,$id,$result,$request,$response)=@_;

    if($result) {
      foreach my $obj (@{$result->get_data}) {
        $data->{ids}->{$obj->{id}}=$obj;
        $obj->{applicationId}=$obj->{id};
        $obj->{applicationName}=$obj->{name};
	my $app_id=$obj->{id};
	$obj->{our_type}='applications';
	my $name=lc($obj->{name});
	$data->{applications}->{lc($obj->{name})}=[] unless exists $data->{applications}->{$obj->{name}};
        push @{$data->{applications}->{$name}},$obj->{id};
        foreach my $method (qw(que_list_nodes que_list_tiers que_list_business_transactions )) {
	  ++$total;
	  my $code=sub {
            my ($self,undef,$result,$request,$response)=@_;
            return unless $state;
            return ($cb->($self,$id,$result,$request,$response,$method,$obj),$state=0) unless $result;
	    --$total;
	    foreach my $sub_obj (@{$result->get_data}) {
	      my $target=$method;
	      $target=~ s/^que_list_//;

	      foreach my $field (qw(name machineName)) {
	        next unless exists $sub_obj->{$field};
		my $name=lc($sub_obj->{$field});
	        $data->{$target}->{$name}=[] unless exists $data->{$target}->{$name};
	        push @{$data->{$target}->{$name}},$sub_obj->{id};
	      }
              $sub_obj->{applicationId}=$obj->{id};
              $sub_obj->{applicationName}=$obj->{name};
	      $sub_obj->{our_type}=$target;
	      $data->{ids}->{$sub_obj->{id}}=$sub_obj;
	      if(exists $sub_obj->{machineId}) {
	        $data->{ids}->{$sub_obj->{machineId}}=$sub_obj;
	        $data->{id_map}->{$app_id}->{$sub_obj->{machineId}}++;
	      }
	      $data->{id_map}->{$app_id}->{$sub_obj->{id}}++;
	      if(exists $sub_obj->{tierId}) {
	        $data->{id_map}->{$sub_obj->{tierId}}->{$sub_obj->{id}}++;
	        $data->{id_map}->{$sub_obj->{tierId}}->{$sub_obj->{machineId}}++ if exists $sub_obj->{machineId};
	      }
	    }

	    if($total==0) {
              return ($cb->($self,$id,$self->new_true($data),$request,$response,'que_walk_all',$obj),$state=0) 
	    }
	  };
	  push @ids,$self->$method($code,$obj->{id});
	}
      }
    } else {
      return $cb->($self,$id,$result,$request,$response,'que_list_applications',undef);
    }
    $self->add_ids_for_blocking(@ids);
    $self->agent->run_next;
  };

  return $self->que_list_applications($app_cb);
}

=back

=head1 Alert and Response API

Queues a health rule violation lookup

For more details, please see: L<https://docs.appdynamics.com/display/PRO43/Alert+and+Respond+API#AlertandRespondAPI-RetrieveAllHealthRuleViolationsinaBusinessApplication>

=over 4

=item * Blocking context my $result=$self->health_rule_violations($app,%args);

Example ( defaults if no arguments are passed ):

  my $result=$self->health_rule_violations($cb,"PRODUCTION",'time-range-type'=>'BEFORE_NOW','duration-in-mins'=>15);

=item * Non Blocking context my $id=$self->que_health_rule_violations($cb,$app,%args);

Example ( defaults if no arguments are passed ):

  my $id=$self->que_health_rule_violations($cb,"PRODUCTION",'time-range-type'=>'BEFORE_NOW','duration-in-mins'=>15);

Example Callback: 

  my $cb=sub {
    my ($self,$id,$result,$request,$result)=@_;
    # 0 Net::AppDynamics::REST Object
    # 1 Id of the request
    # 2 Data::Result Object
    # 3 HTTP::Request Object
    # 4 HTTP::Result Object
  };

=cut

sub que_health_rule_violations {
  my ($self,$cb,$app,%args)=@_;
  $app="PRODUCTION" unless defined($app);
  my $path=sprintf '/controller/rest/applications/%s/problems/healthrule-violations',uri_escape($app);
  if(keys %args==0) {
    %args=('time-range-type'=>'BEFORE_NOW','duration-in-mins'=>15);
  }
  
  my $req=$self->create_get($path,%args);
  return $self->queue_request($req,$cb);
}

=back

=head1 Configuration Import and Export API

This section documents the Configuration Import and Export API.

=over 4

=item * Blocking context my $result=$self->export_policies($app) 

=item * Non Blocking context my $id=$self->que_export_policies($cb,$app) 

Queues the exporting of a policy

Example Callback: 

  my $cb=sub {
    my ($self,$id,$result,$request,$result)=@_;
    # 0 Net::AppDynamics::REST Object
    # 1 Id of the request
    # 2 Data::Result Object
    # 3 HTTP::Request Object
    # 4 HTTP::Result Object
  };

=cut

sub que_export_policies {
  my ($self,$cb,$app)=@_;
  my $path=sprintf '/controller/policies/%s',uri_escape($app);
  
  my $req=$self->create_get($path);
  return $self->queue_request($req,$cb);
}

=back

=head1 Finding Health rule violations

See: que_health_rule_violations and que_resolve for more information.

=over 4

=item * Blocking Context my $result=$self->find_health_rule_violations($type,$name)

Returns a Data::Result Object, when true the result will cointain health rules on anything that resolved.

=item * Non Blocking Context my $id=$self->que_find_health_rule_violations($cb,$type,$name)

=cut

sub que_find_health_rule_violations {
  my ($self,$cb,$type,$name)=@_;

  my $id;
  my $code=sub {
    my ($self,undef,$result,$request,$response)=@_;
    return $cb->(@_) unless $result;
    my @resolved=@{$result->get_data};

    my @ids;
    my $resolved={};
    my $state=1;
    my $alerts=[];
    my $total=0;
    my $apps={};

    # safe to use here, since we know it is current
    my $cache=$self->data_cache;

    my $sub_cb=sub {
      my ($self,undef,$result,$request,$response)=@_;
      return unless $state;
      unless($result) {
        $cb->(@_);
	$state=0;
	return;
      }
      LOOK_UP: foreach my $event (@{$result->get_data}) {
        my $entity_id=$event->{affectedEntityDefinition}->{entityId};

        next unless exists $resolved->{$entity_id};
	my $target=$cache->{ids}->{$entity_id};
	foreach my $obj (@resolved) {
	  my $type=$obj->{our_type};
	  if($type eq 'tiers') {
	    my $tier_id=$obj->{id};
	    next unless exists $target->{tierId};
	    next unless $target->{tierId}==$tier_id;
	    push @{$alerts},$event;
	  } elsif($type eq 'applications') {
	    my $app_id=$obj->{id};
	    next unless $target->{applicationId}==$app_id;
	    push @{$alerts},$event;
	  } elsif($type eq 'business_transactions') {
	    my $id=$obj->{id};
	    next unless $target->{id}==$id;
	    push @{$alerts},$event;
	  } elsif($type eq 'nodes') {
	    foreach my $key (qw(id machineId)) {
	      next unless exists $obj->{$key};
	      next unless exists $target->{$key};
	      next unless $obj->{$key}==$target->{$key};
	      push @{$alerts},$event;
	      next LOOK_UP;
	    }
	  }
	}
      }
      
      return unless --$total==0;
      $cb->($self,$id,$self->new_true($alerts),undef,undef);
    };
    foreach my $obj (@{$result->get_data}) {
      $apps->{$obj->{applicationId}}++;

      foreach my $key (qw(id applicationId tierId machineId)) {
        next unless exists $obj->{$key};
        $resolved->{$obj->{$key}}++;
	my $id=$obj->{$key};
	if(exists $cache->{id_map}->{$id}) {
	  my @keys=keys %{$cache->{id_map}->{$id}};
	  @{$resolved}{@keys}=@{$cache->{id_map}->{$id}}{@keys};
	}
      }
      ++$total;

      my $app_id=$obj->{applicationId};
      push @ids,$self->que_health_rule_violations($sub_cb,$app_id);
    }
    $self->add_ids_for_blocking(@ids);
    $self->agent->run_next;
  };

  $id=$self->que_resolve($code,$type,$name);
  return $id;
}

=back

=head1 Resolving Objects

Used to resolve tiers, nodes, business_transactions, and applications to thier application's id.

 cb:  standard callback
 type: String representing the typpe of object to resolve (tiers|nodes|business_transactions|applications);
 name: name to be resolved

Uses the internal cache to resolve the object, if the internal cache is out of date or empty the cache will be refreshed.

=over 4

=item * Blocking context my $result=$self->resolve($type,$name);

Returns a Data::Result object, when true it contains the resolved object.

=item * Non Blocking context my $id=$self->que_resolve($cb,$type,$name);

Example Callback: 

  my $cb=sub {
    my ($self,$id,$result,$request,$result)=@_;
    # 0 Net::AppDynamics::REST Object
    # 1 Id of the request
    # 2 Data::Result Object
    # 3 HTTP::Request Object
    # 4 HTTP::Result Object
  };

=cut

sub que_resolve {
  my ($self,$cb,$type,$name)=@_;

  my $code=sub {
    my ($self,$id,$result,$request,$response)=@_;
    return $cb->(@_) unless $result;


    foreach my $key ($type,$name) {
      $key=lc($key);
      $key=~ s/(?:^\s+|\s+$)//sg;
    }

    my $cache=$result->get_data;
    if(exists $cache->{$type}) {
      if(exists($cache->{$type}->{$name})) {
	my $data=[];
	foreach my $target (@{$cache->{$type}->{$name}}) {
	  push @{$data},$cache->{ids}->{$target};
	}
	return $cb->($self,$id,$self->new_false("Type: [$type] Name: [$name] Not Found"),undef,undef) if $#{$data}==-1;
        $cb->($self,$id,$self->new_true($data),$request,$response);
      } else {
        $cb->($self,$id,$self->new_false("Type: [$type] Name: [$name] Not Found"),undef,undef);
      }
    } else {
      $cb->($self,$id,$self->new_false("Type: [$type] Name: [$name] Not Found"),undef,undef);
    }
  };
  my $id=$self->que_check_cache($code);
  return $id;
}

=back

=head1 Internal Caching

The Net::AppDynamics::REST object uses an internal cache for resolving objects.  The $forceCacheRefresh is a boolean value, when set to true it forces the cache to refresh reguardless of the age of the cache.

=over 4

=item * Non BLocking context my $result=$self->que_check_cache($cb,$forceCacheRefresh);

Returns a Data::Result object, when true it contains the cache.

=item * BLocking context my $id=$self->que_check_cache($cb,$forceCacheRefresh);

Queues a cache check.  The resolve cache is refreshed if it is too old. 

Example Callback: 

  my $cb=sub {
    my ($self,$id,$result,$request,$result)=@_;
    # 0 Net::AppDynamics::REST Object
    # 1 Id of the request
    # 2 Data::Result Object
    # 3 HTTP::Request Object
    # 4 HTTP::Result Object
  };

=cut

sub que_check_cache {
  my ($self,$cb,$force)=@_;

  my $max=time - $self->cache_max_age;
  if(!$force and  $self->data_cache->{created_on} > $max) {
    return $self->queue_result($cb,$self->new_true($self->data_cache));
  } else {
    $self->cache_check(1);
    return $self->que_walk_all(sub {
      my ($self,$id,$result,@list)=@_;
      $self->cache_check(0);
      return $cb->(@_) unless $result;
      $self->data_cache($result->get_data);
      $self->data_cache->{created_on}=time;
      return $cb->($self,$id,$result,@list);
    });
  }
}

=back

=head1 OO Inernal OO Methods

=over 4

=item * my $url=$self->base_url

Creates the base url for a request.

=cut

sub base_url {
  my ($self)=@_;
  my $url=$self->PROTO.'://'.$self->SERVER.':'.$self->PORT;
  return $url;
}

=item * my $request=$self->create_get($path,%args);

Create a request object for $path with the required arguments

=cut

sub create_get {
  my ($self,$path,%args)=@_;

  my $str =$self->base_url.$path.'?';
  $args{output}='JSON';

  my $count=0;
  while(my ($key,$value)=each %args) {
    if($count++ ==0) {
      $str .="$key=".uri_escape($value);
    } else {
      $str .="\&$key=".uri_escape($value);
    }
  }

  my $headers=HTTP::Headers->new(@{$self->{header}});
  my $request=HTTP::Request->new(GET=>$str,$headers);

  return $request;
}

=back

=head1 Bugs and Patches

Please report bugs and submit patches via L<https://rt.cpan.org>

=head2 Todo

Implement more of the api.. it is pretty extensive, patches welcome!

=head1 See Also

L<https://docs.appdynamics.com/display/PRO43/AppDynamics+APIs>

L<AnyEvent::HTTP::MultiGet>

=head1 AUTHOR

Michael Shipper L<mailto:AKALINUX@CPAN.ORG>

=cut

1;
