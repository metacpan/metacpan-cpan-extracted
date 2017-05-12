package Quota::OO;

use strict;
use warnings;

use version;our $VERSION = qv('0.0.1');

use Class::Std;
use Class::Std::Utils;

use Quota;

{
    my %dev :ATTR('set' => 'dev', 'get' => 'dev', 'init_arg' => 'dev');
    my %uid :ATTR('set' => 'uid', 'get' => 'uid', 'init_arg' => 'uid');
    my %gid :ATTR('set' => 'gid', 'get' => 'gid', 'init_arg' => 'gid');

    my %rpc_host :ATTR('set' => 'rpc_host', 'get' => 'rpc_host', 'init_arg' => 'rpc_host');
    my %rpc_path :ATTR('set' => 'rpc_path', 'get' => 'rpc_path', 'init_arg' => 'rpc_path');
    my %rpc_port :ATTR('set' => 'rpc_port', 'get' => 'rpc_port', 'init_arg' => 'rpc_port');
    my %rpc_uid  :ATTR('set' => 'rpc_uid',  'get' =>  'rpc_uid', 'init_arg' => 'rpc_uid');
    my %rpc_gid  :ATTR('set' => 'rpc_gid',  'get' =>  'rpc_gid', 'init_arg' => 'rpc_gid');
    my %rpc_use_tcp :ATTR('set' => 'rpc_use_tcp', 'get' => 'rpc_use_tcp', 'init_arg' => 'rpc_use_tcp');
    my %rpc_timeout :ATTR('set' => 'rpc_timeout', 'get' => 'rpc_timeout', 'init_arg' => 'rpc_timeout');

    sub BUILD {
        my ($self, $obj_id, $arg_ref) = @_;

        $dev{$obj_id} = $self->set_dev( $arg_ref->{'dev'} );
        $uid{$obj_id} = $self->set_uid( $arg_ref->{'uid'} );
        $gid{$obj_id} = $self->set_gid( $arg_ref->{'gid'} );
    }

    sub set_dev {
        my ($self, $dev)	= @_;
        $dev{ ident $self }   = $self->getqcarg($dev);
    }

    sub set_uid {
        my ($self, $uid) = @_;
        $uid{ ident $self } = $uid =~ m{^\d+$} ? $uid : $>;	
    }

    sub set_gid {
        my ($self, $gid) = @_;
        $gid{ ident $self } 
            = $gid =~ m{^\d+$} ? $gid : ( getpwuid($uid{ ident $self }) )[3];	
    }

#### do rcp* ##
#### Quota::rpcquery ##
	sub rpcquery {
    	my ($self, $host, $path, $uid) = @_;
        
        Quota::rpcquery(
	        defined $host ? $host : $rpc_host{ ident $self },
	        defined $path ? $path : $rpc_path{ ident $self }, 
	        defined $uid  ? $uid  : $rpc_uid{ ident $self },
	    );
	}

#### Quota::rpcpeer ##
	sub rpcpeer {
    	my ($self, $port, $use_tcp, $timeout) = @_;
    
        Quota::rpcpeer(
	        defined $port    ? $port    : $rpc_port{ ident $self }, 
	        defined $use_tcp ? $use_tcp : $rpc_use_tcp{ ident $self }, 
	        defined $timeout ? $timeout : $rpc_timeout{ ident $self },
	    );
	}

#### Quota::rpcauth ##
	sub rpcauth {
    	my ($self, $uid, $gid, $ host) = @_;

        Quota::rpcauth(
	        defined $uid  ? $uid  : $rpc_uid{ ident $self }, 
	        defined $gid  ? $gid  : $rpc_gid{ ident $self }, 
	        defined $host ? $host : $rpc_host{ ident $self },
	    );
	}

	sub get_rpc_query {
    	my ($self, $args_hr) = @_;

    	$self->rpcpeer( 
            $args_hr->{'rpc_port'}, 
            $args_hr->{'rpc_use_tcp'},
            $args_hr->{'rpc_timeout'},
        );

    	$self->rpcauth( 
            $args_hr->{'rpc_uid'},
            $args_hr->{'rpc_gid'},
            $args_hr->{'rpc_host'},
        );

        my @rpc_results = $self->rcpquery( 
            				  $args_hr->{'rpc_host'},
            		 		  $args_hr->{'rpc_path'},
            		          $args_hr->{'rpc_uid'},
                          );
    	return wantarray ? @rpc_results : \@rpc_results;
   	
    }

	sub get_rpc_query_hash {
    	my ($self, $args_hr) = @_;

    	my $query_ar = $self->get_rpc_query( $args_hr );

    	my $query_hr = {
        	'block_current'   => $query_ar->[0], 
        	'block_soft'      => $query_ar->[1], 
        	'block_hard'      => $query_ar->[2], 
        	'block_timelimit' => $query_ar->[3],
        	'inode_current'   => $query_ar->[4], 
        	'inode_soft'      => $query_ar->[5], 
        	'inode_hard'      => $query_ar->[6], 
        	'inode_timelimit' => $query_ar->[7],
    	};

    	return wantarray ? %{ $query_hr } : $query_hr;
	}

#### Quota::query ##
    sub query {
       my($self, $dev, $id, $id_is_group) = @_;

       my $original_dev = $dev{ ident $self };
       $dev{ ident $self } = $self->getqcarg( $dev );

       my @query = $id_is_group ? $self->get_gid_query($id)
                                : $self->get_uid_query($id);

       $dev{ ident $self } = $original_dev;
       return @query;
    }

    sub get_query {
        my($self, $id, $id_is_group) = @_;

        $id_is_group = 0 if !defined $id_is_group;

        if(!defined $id) {
        	$id = $id_is_group  ? $gid{ ident $self }
                                : $uid{ ident $self };
        }

        return wantarray ?  $self->query($dev{ ident $self }, $id, $id_is_group)
                         : [$self->query($dev{ ident $self }, $id, $id_is_group)];
    }

    sub get_uid_query {
        my($self, $uid) = @_;
        return $self->get_query($uid, 0);
    }

    sub get_gid_query {
        my($self, $gid) = @_;
        return $self->get_query($gid, 1);
    }

    sub get_query_hash {
        my($self, $id, $id_is_group) = @_;

        my $query_ar = $self->get_query($id, $id_is_group);

        my $query_hr = {
            'block_current'   => $query_ar->[0], 
            'block_soft'      => $query_ar->[1], 
            'block_hard'      => $query_ar->[2], 
            'block_timelimit' => $query_ar->[3],
            'inode_current'   => $query_ar->[4], 
            'inode_soft'      => $query_ar->[5], 
            'inode_hard'      => $query_ar->[6], 
            'inode_timelimit' => $query_ar->[7],
        };

        return wantarray ? %{ $query_hr } : $query_hr;
    }

    sub get_uid_query_hash {
        my($self, $uid) = @_;
        return $self->get_query_hash($uid, 0);
    }

    sub get_gid_query_hash {
        my($self, $uid) = @_;
        return $self->get_query_hash($uid, 1);
    }

#### Quota::setqlim ##
    sub setqlim {
	    shift;
        Quota::setqlim(@_);
    }

    sub set_quota_limit {
	    my($self, $args_hr) = @_;
	
        my $dev = !defined $args_hr->{'dev'} ? $dev{ ident $self }  
		                                     : $self->getqcarg( $args_hr->{'dev'} );
		$args_hr->{'id'}  = $uid{ ident $self } if !defined $args_hr->{'uid'};
		$args_hr->{'block_soft'} = int( $args_hr->{'block_soft'} );
		$args_hr->{'block_hard'} = int( $args_hr->{'block_hard'} );
	    $args_hr->{'inode_soft'} = int( $args_hr->{'inode_soft'} ); 
		$args_hr->{'inode_hard'} = int( $args_hr->{'inaode_hard'} );
		$args_hr->{'time_limit'} = 0 if !defined $args_hr->{'time_limit'};
		$args_hr->{'id_is_gid'}  = 0 if !defined $args_hr->{'id_is_gid'};
		
        $self->setqlim(
			$dev,
			$args_hr->{'id'},
			$args_hr->{'block_soft'},
			$args_hr->{'block_hard'},
			$args_hr->{'inode_soft'}, 
			$args_hr->{'inode_hard'},
			$args_hr->{'time_limit'},
			$args_hr->{'id_is_gid'},	        
	    );
    }
     
    sub set_uid_quota_limit {
        my($self, $args_hr) = @_;
        $args_hr->{'id_is_gid'} = 0;
        $self->set_quota_limit($args_hr);
    }

    sub set_gid_quota_limit {
        my($self, $args_hr) = @_;
        $args_hr->{'id_is_gid'} = 1;
        $self->set_quota_limit($args_hr);
    }

#### Quota::sync ##
    sub sync {
        my($self, $dev) = @_;
        Quots::sync( $self->getqcarg( $dev ) || $dev{ ident $self } );
    }

    sub sync_all {
        Quota::sync();
    }
    
#### Quota::getqcarg ##
    sub getqcarg {
	    shift;
        Quota::getqcarg(@_);
    }

#### Quota::getdev ##
    sub getdev {
        shift;
        Quota::getdev(@_);
    }

#### Quota::strerr ##
    sub strerr {
        Quota::strerr();
    }

    sub get_errstr {
        Quota::strerr();
    }

#### *mntent ##
#### Quota::setmntent ##
    sub setmntent {
	    Quota::setmntent();
    }

#### Quota::getmntent ##
    sub getmntent {
        Quota::getmntent();
    }

#### Quota::endmntent ##
    sub endmntent {
	    Quota::endmntent();
    }
  
    sub get_mntent_hash {
	     my($self) = @_;
	     my $hr = {};
	     $self->setmntent();
	     while( my @ent = $self->getmntent() ){
		     $hr->{ $ent[0] } = {
			     'path' => $ent[1],
			     'type' => $ent[2],
			     'opts' => $ent[3],			 
	   	     };		
	     }
	     $self->endmntent();
  
	     return wantarray ? %{ $hr } : $hr;
    }
}
  
1;

__END__

=head1 NAME

Quota::OO - Perl extension for Object Oriented Quota Management and reporting

=head1 SYNOPSIS

    use Quota::OO;
    my $quo = Quota::OO->new();

    my $mount_entities_hr = $quo->get_mntent_hash();

=head1 DESCRIPTION

Object oriented interface to the L<Quota> module. It has a method for each function that L<Quota> has. All take the same arguments and return the same results, except for sync() (see below).

In addition it has new methods to make it easier to obtain certain info and do certain tasks. See the METHODS section below.

=head1 METHODS

=head2 new()

Takes either no arguments or a single argument that is a hashref with the following optional keys:

    'dev' => DEV,
    'uid' => UID,
    'gid' => GID,

Each takes the same value and has the same defaults as the corresponding set_ method.

=head2 $quo->get_* and $quo->set_* methods

$quo->get_dev(), $quo->get_uid(), and $quo->get_gid() each return their respective part of the current object.

=head3 $quo->set_dev( $dev )

Sets the current device to given argument. Sets it to the $quo->getqcarg() of your argument. 

=head3 $quo->set_uid( $uid )

Sets current UID to given argument. If not numeric defaults to effective UID  of the script.

=head3 $quo->set_gid( $gid )

Sets current GID to given argument. If not numeric defaults to the GID of the UID.

=head2 $quo->get_query($id, $id_is_grp)

Returns an array (in list context) or array ref (in scalar context).

Defaults to $id being the UID and not GID, returns same array as Quota::query()

=head2 $quo->get_uid_query($uid)

Same as get_query() but force user context

=head2 $quo->get_gid_query($gid)

Same as get_query() but force group context

=head2 $quo->get_query_hash($id, $id_is_grp)

Same as get_query but returns a hash (in list context) or a hashref (in scalar context) with the following keys:

    'block_current' 
    'block_soft' 
    'block_hard'
    'block_timelimit'
    'inode_current' 
    'inode_soft'
    'inode_hard'
    'inode_timelimit'

=head2 $quo->get_uid_query_hash($uid)

Same as get_query_hash() but force user context

=head2 $quo->get_gid_query_hash($gid)

Same as get_query_hash() but force group context

=head2 $quo->set_quota_limit()

Takes a single argument, a hashref with the following keys:

    'dev'          # defaults to object's device
    'id'           # defaults to object's UID
    'block_soft'   
    'block_hard'
    'inode_soft' 
    'inode_hard'
    'time_limit'   # defaults to 0
    'id_is_gid'    # defaults to 0

=head2 $quo->set_uid_quota_limit()

Same as $quo->set_quota_limit() except force user context.

=head2 $quo->set_gid_quota_limit()

Same as $quo->set_quota_limit() except force group context.

=head2 $quo->sync()

sync device given as argument or the object's device if no arguments

=head2 $quo->sync_all()

Same as Quota::sync with no arguments.

=head2 $quo->get_mntent_hash()

Returns a hash (in list context) or a hashref (in scalar context) where each key is a device and its value is a hashref with the keys 'path', 'type', 'opts'.

The device key and hash keys correspond to Quota::getmntent()'s return values.

=head2 $quo->get_errstr()

Alias to $quo->errstr()

=head2 rpc*

These all have get_ and set_ methods and can be passed as keys of the hashref argument to new() and the methods below.

The corresponding location in the original calls are noted in the comments after each one, the method name and its location in the argument list
 
    'rpc_host'    # rpcquery(0), rpcauth(2)
    'rpc_path'    # rpcquery(1)
    'rpc_port'    # rpcpeer(0)
    'rpc_uid'     # rpcquery(2), rpcauth(0)
    'rpc_gid'     # rpcauth(1)
    'rpc_use_tcp' # rpcpeer(1)
    'rpc_timeout' # rpcpeer(2)

=head3 $quo->get_rpc_query()

Can take a single hashref with any or all of the keys described above.

Returns the same array as $quo->get_query();

=head3 $quo->get_rpc_query_hash()

Can take a single hashref with any or all of the keys described above.

Returns the same hash[ref] as $quo->get_query_hash();

=head1 SEE ALSO

All heavy lifting is done by:

L<Quota>

=head1 TODO

test test test :) Feedback always welcome, we want useful stuff afterall right?

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
