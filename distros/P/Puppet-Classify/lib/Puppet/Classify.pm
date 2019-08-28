# Author: Matthew Mallard
# Website: www.q-technologies.com.au
# Date: 6th October 2016

# ABSTRACT: Connects to the Puppet Classifier API (PE Console groups)




package Puppet::Classify;

use JSON;
use LWP::UserAgent;
use HTTP::Request;
use Puppet::DB;
use Log::MixedColor;
use 5.10.0;
use Moose;
use Moose::Exporter;
use Module::Load::Conditional qw[ check_install ];
use Data::Dumper;
use YAML::XS qw(Dump Load LoadFile);

if( check_install( module => 'MooseX::Storage' )){
    require MooseX::Storage;
    MooseX::Storage->import();
    with Storage('format' => 'JSON', 'io' => 'File', traits => ['DisableCycleDetection']);
}
my $log = Log::MixedColor->new;





around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if ( @_ == 1 && !ref $_[0] ) {
      return $class->$orig( server_name => $_[0], puppet_db => Puppet::DB->new($_[0]) );
  }
  else {
      return $class->$orig(@_);
  }
};



has 'server_name' => (
    is => 'rw', 
    isa => 'Str',
    required => 1,
    default => 'localhost',
    predicate => 'has_server_name',
);




has 'server_port' => (
    is => 'rw', 
    isa => 'Int',
    required => 1,
    default => 4433,
    predicate => 'has_server_port',
);





has 'access_token' => (
    is => 'rw', 
    isa => 'Str',
    required => 0,
    builder => 'load_access_token',
    predicate => 'has_access_token',
);





has 'environment' => (
    is => 'rw', 
    isa => 'Str',
    required => 1,
    default => 'dev',
    predicate => 'has_environment',
);




# Use a certificate by this name
has 'cert_name' => (
    is => 'rw', 
    isa => 'Maybe[Str]',
    required => 0,
    predicate => 'has_cert_name',
);





has 'puppet_ssl_path' => (
    is => 'rw', 
    isa => 'Str',
    required => 1,
    default => '/etc/puppetlabs/puppet/ssl',
    predicate => 'has_puppet_ssl_path',
);





has 'timeout' => (
    is => 'rw', 
    isa => 'Int',
    required => 1,
    default => 360, # seconds
    predicate => 'has_timeout',
);






has 'puppet_db' => (
    is => 'rw', 
    isa => 'Puppet::DB',
    required => 1,
    predicate => 'has_puppet_db',
);







sub update_classes {
    my $self = shift;
    $self->push_data( "update-classes" );
}







sub get_classes {
    my $self = shift;
    return $self->get_data( "environments/".$self->environment."/classes" );
}





sub get_group_rule {
    my $self = shift;
    my $name = shift;
    my $groups = $self->get_groups();
    for my $group ( @$groups ){
        return $group->{rule} if $group->{name} eq $name;
    }
}





sub get_group_id {
    my $self = shift;
    my $name = shift;
    my $groups = $self->get_groups();
    for my $group ( @$groups ){
        return $group->{id} if $group->{name} eq $name;
    }
}






sub get_groups_match {
    my $self = shift;
    my $match = shift;
    my @mgroups;
    my $groups = $self->get_groups();
    for my $group ( @$groups ){
        push @mgroups, $group if $group->{name} =~ /$match/i;
    }
    return \@mgroups;
}






sub get_groups {
    my $self = shift;
    my $groups = shift;
    return $self->get_data( "groups" );
}






sub get_group_children {
    my $self = shift;
    my $gid = shift;
    my $group_with_children;
    eval { $group_with_children = $self->get_data( "group-children/$gid" ) };
    if( not $group_with_children ){
        $log->debug_msg( "There are no children groups" );
        return;
    }
    return $group_with_children->[0]{children};
}







sub add_group_safe {
    my $self = shift;
    my $name = shift;
    my $group_def = shift;
    my $force = shift;
    
    my $gid = $self->get_group_id( $name );
    if( ( $gid and $force and $self->try_remove_group( $name )) or not $gid ){
        $log->info_msg( "Creating the group: ".$log->quote($name) );
        $self->create_group( $group_def );
    } elsif( $gid ){
        $log->fatal_err( "The group ".$log->quote($name)." already exists - it will only be redefined if you specify (force)" );
    }

}






sub create_group {
    my $self = shift;
    my $group = shift;
    return $self->push_data( "groups", $group );
}






sub update_group_rule {
    my $self = shift;
    my $gid = shift;
    my $rule = shift;
    $self->update_group( $gid, { rule => $rule } );
}






sub update_group_environment {
    my $self = shift;
    my $gid = shift;
    my $environment = shift;
    $self->update_group( $gid, { environment => $environment } );
}







sub update_group {
    my $self = shift;
    my $gid = shift;
    my $config = shift;
    $self->push_data( "groups/$gid", $config );
}







sub remove_group_safe {
    my $self = shift;
    my $name = shift;
    my $force = shift;
    
    my $rule = $self->get_group_rule( $name );
    my $pinned = $self->get_hosts_from_pinned_rule( $rule );
    if( $pinned and @$pinned and not $force ){
        $log->fatal_err( "The group ".$log->quote($name)." has pinned nodes - it can only be removed if you specify (force)" );
    } else {
        $self->try_remove_group( $name, $force );
    }
}







sub try_remove_group {
    my $self = shift;
    my $name = shift;
    my $force = shift;
    my $gid = $self->get_group_id( $name );
    if( not $gid ) { 
        $log->info_msg( $log->quote($name)." doesn't exist - nothing to delete" );
        return;
    }
    my $children = $self->get_group_children( $gid );
    if( @$children ){
        $log->fatal_err( "The group ".$log->quote($name)." has children - it cannot be removed even if you specify (force)" );
    } else {
        $log->info_msg( "Deleting ".$log->quote($name)." as 'force' was specified" ) if $force;
        $log->info_msg( "Deleting ".$log->quote($name)." as 'remove_group' was invocated directly" ) if not $force;
        $self->delete_group( $gid );
        return 1;
    }
}







sub delete_group {
    my $self = shift;
    my $id = shift;
    
    my %headers;
    my $uri = "https://".$self->server_name.":".$self->server_port."/classifier-api/v1/groups/$id";

    my $ssl_opts = { verify_hostname => 1, SSL_ca_file => $self->puppet_ssl_path."/certs/ca.pem" };
    if( $self->cert_name ){
        $ssl_opts->{SSL_cert_file} = $self->puppet_ssl_path."/certs/".$self->cert_name.".pem";
        $ssl_opts->{SSL_key_file} = $self->puppet_ssl_path."/private_keys/".$self->cert_name.".pem";
    } else {
        %headers = ( 'X-Authentication' => $self->access_token );
    }

    my $ua = LWP::UserAgent->new( timeout => $self->timeout, ssl_opts => $ssl_opts );
    my $response = $ua->delete( $uri, %headers );
    die $response->status_line."\n".$response->decoded_content if not $response->is_success( 204 );
}







sub convert_rule_for_puppetdb {
    my $self = shift;
    my $rule = shift;
    return $self->push_data( "rules/translate", $rule );
}







sub get_nodes_matching_group {
    my $self = shift;
    my $group_name = shift;
    my $rule = $self->get_group_rule( $group_name );

    $rule = $self->convert_rule_for_puppetdb( $rule );
    $self->puppet_db->refresh( "nodes", $rule );
    my $data = $self->puppet_db->results;

    my $nodes = [];
    for my $node ( @$data ){
        push @$nodes, $node->{certname};
    }

    return $nodes;
    
}







sub get_hosts_from_pinned_rule {
    my $self = shift;
    my $rule = shift;
    return if not $rule;
    my @rule = @$rule;
    my @nodes;
    if( shift( @rule ) eq 'or' ){
        for my $rule ( @rule ) {
            push @nodes, $rule->[2] if( $rule->[0] eq '=' and $rule->[1] eq 'name' );
        }
    } else {
        $log->debug_msg( "The specified rule does not seem to have pinned nodes" );
    }
    return \@nodes;
}







sub list_nodes_pinned_in_group {
    my $self = shift;
    my $group = shift;
    my $rule = $self->get_group_rule( $group );
    my $pinned = $self->get_hosts_from_pinned_rule( $rule );
    for( @$pinned ){
        say $_;
    }
}







sub purge_old_nodes {
    my $self = shift;
    my $parent_id = shift;

    my $children = $self->get_group_children( $parent_id );
    for my $child ( @$children ){
        my $rule = $child->{rule};
        next if not $rule;
        my $pinned = $self->get_hosts_from_pinned_rule( $rule );
        my @not_found;
        for my $pn ( @$pinned ){
            push @not_found, $pn if not $self->puppet_db->is_node_in_puppetdb( $pn);
        }
        $self->remove_pinned_node_from_group( $child, \@not_found );
    }
}







sub list_membership_of_nodes {
    my $self = shift;
    my $parent = shift;
    my $nodes = shift;
    my $parent_id = $self->get_group_id( $parent );

    $nodes = $self->get_nodes_matching_group( $parent ) unless @$nodes;

    my $ans = {};
    for my $node ( @$nodes ){
        $ans->{$node} = 'Not pinned to any group';
    }

    my $children = $self->get_group_children( $parent_id );
    for my $child ( @$children ){
        my $rule = $child->{rule};
        next if not $rule;
        my $pinned = $self->get_hosts_from_pinned_rule( $rule );
        my @not_found;
        for my $pn ( @$pinned ){
            for my $node ( @$nodes ){
                $ans->{$node} = $child->{name} if $pn eq $node;
            }
        }
    }
    return $ans;
}







sub remove_nodes_from_all_groups {
    my $self = shift;
    my $parent_id = shift;
    my $nodes = shift;

    my $children = $self->get_group_children( $parent_id );
    for my $child ( @$children ){
        $self->remove_pinned_node_from_group( $child, $nodes );
    }
}







sub empty_group_of_pinned_nodes {
    my $self = shift;
    # Remove pinned nodes only - leave other rules in place
    my $group = shift;
    my $rule = $self->get_group_rule( $group );
    my $pinned = $self->get_hosts_from_pinned_rule( $rule );
    $self->remove_pinned_node_from_group( $group, $pinned );
}







sub remove_pinned_node_from_group {
    my $self = shift;
    my $group = shift;
    my $nodes = shift;
    my $gid;
    # Detect whether we were passed the group name or the assoc array of the group
    if( ref($group) eq "HASH" ){
        $gid = $group->{id};
        $group = $group->{name};
    } else {
        $log->debug_msg( "Checking whether ".$log->quote($group)." exists" );
        $gid = $self->get_group_id( $group );
        $log->fatal_err( "Could not find the specified group (".$log->quote($group).") are you sure it's a valid group?" ) if not $gid;
    }

    my @deleted;
    $log->debug_msg( "Fetching the existing rule for ".$log->quote($group) );
    my $rule = $self->get_group_rule( $group );
    if( $rule ){
        if( $rule->[0] eq 'or' ){
            my $max = @$rule;
            for( my $i = 1; $i < $max; $i++){
                next if $rule->[$i][0] ne '=' and $rule->[$i][1] ne 'name';
                for my $node ( @$nodes ){
                    if( $node eq $rule->[$i][2] ){
                        splice @$rule, $i, 1;
                        $i--; $max--;
                        $log->debug_msg( $log->quote($node)." was deleted from the rule" );
                        push @deleted, $node;
                        last unless $i;
                        next;
                    }
                }
            }
            $rule = undef if @$rule == 1;
        } else {
            $log->debug_msg( "The specified rule does not seem to have pinned nodes" );
        }
    } else {
        $log->info_msg( "The specified rule for ".$log->quote($group)." does not exist - nothing to do" );
        return;
    }

    if( @deleted > 0 ){
        $log->info_msg( "Updating the group: ".$log->quote($group) );
        $self->update_group_rule( $gid, $rule );
    } else {
        $log->info_msg( "None of the specified nodes were found in ".$log->quote($group) );
    }
}







sub pin_nodes_to_group {
    my $self = shift;
    my $group = shift;
    my $nodes = shift;

    $log->debug_msg( "Checking whether ".$log->quote($group)." exists" );
    my $gid = $self->get_group_id( $group );
    $log->fatal_err( "Could not find the specified group (".$log->quote($group).") are you sure it's a valid group?" ) if not $gid;

    $log->debug_msg( "Fetching the existing rule for ".$log->quote($group) );
    my $old_rule = $self->get_group_rule( $group );

    my @host_matches;
    for my $node( @$nodes ){
        if( $self->puppet_db->is_node_in_puppetdb( $node ) ){
            $log->debug_msg( $log->quote($node)." will be added to the rule unless it is already present" );
            push @host_matches, [ '=', "name", $node ];
        } else {
            # Check whether we have been provided a short hostname
            if( $node !~ /\./ ){
                # Find the certname/clientcert for the shortname
                my $clientcert = $self->puppet_db->is_hostname_in_puppetdb( $node );
                if( $clientcert ){
                    push @host_matches, [ '=', "name", $clientcert ];
                } else {
                    $log->err_msg( $log->quote($node)." will not be added to the group as it is not found in the PuppetDB" );
                }
            } else {
                $log->err_msg( $log->quote($node)." will not be added to the group as it is not found in the PuppetDB" );
            }
        }
    }
    # no point continuing if there are no valid hosts to add
    return if @host_matches == 0;

    my $rule;
    if( $old_rule ){
        if( $old_rule->[0] eq 'or' ){
            for my $nhost ( @host_matches ){
                my $found = 0;
                for my $ohost ( @$old_rule ){
                    next if ref($ohost) ne 'ARRAY';
                    if( $nhost->[2] eq $ohost->[2] ){
                        $found = 1;
                    }
                }
                $log->debug_msg( $log->quote($nhost->[2])." was already present, ignoring" ) if $found;
                push @$old_rule, $nhost if not $found;
            }
            $rule = $old_rule;
        } else {
            $rule = [ 'or', $old_rule, @host_matches ];
        }
    } else {
        $rule = [ 'or', @host_matches ];
    }

    $log->info_msg( "Updating the group: ".$log->quote($group) );
    $self->update_group_rule( $gid, $rule );
}

# The following are really only used internally

sub load_access_token {
    my $token_file = $ENV{"HOME"} . "/.puppetlabs/token";
    my $token = '';
    if ( -r $token_file ) {
        open INFILE, "<$token_file" or die $!;
        while( <INFILE> ){
            $token .= $_;
        }
        close INFILE;
    }
    return $token;
}

sub do_web_request {
    my $self = shift;
    my $type = shift;
    my $action = shift;
    my $data = shift;
    my $uri = "https://".$self->server_name.":".$self->server_port."/classifier-api/v1/$action";
    my $req = HTTP::Request->new( $type, $uri );
    my $ssl_opts = { verify_hostname => 1, SSL_ca_file => $self->puppet_ssl_path."/certs/ca.pem" };
    if( $self->cert_name ){
        $ssl_opts->{SSL_cert_file} = $self->puppet_ssl_path."/certs/".$self->cert_name.".pem";
        $ssl_opts->{SSL_key_file} = $self->puppet_ssl_path."/private_keys/".$self->cert_name.".pem";
    } else {
        $req->header( 'X-Authentication' => $self->access_token );
    }
    my $ua = LWP::UserAgent->new( timeout => $self->timeout, ssl_opts => $ssl_opts );
    if( $type eq 'POST' ){
        $data = encode_json( $data ) if ref $data;
        $req->header( 'Content-Type' => 'application/json' );
        $req->content( $data );
    }
    my $response = $ua->request( $req );
    my $output;
    #if ($response->is_success) {
    if ($response->is_redirect( 303 ) or $response->is_success( 201 )) {
        $output =  $response->decoded_content;
    } else {
        die $response->status_line."\n".$response->decoded_content;
    }
    if( $output ){
        return decode_json( $output );
    } else {
        return;
    }
}

sub push_data {
    my $self = shift;
    my $action = shift;
    my $data = shift;
    return $self->do_web_request( 'POST', $action, $data );
}
sub get_data {
    my $self = shift;
    my $action = shift;
    return $self->do_web_request( 'GET', $action );
}
sub get_data_old {
    my $self = shift;
    my $action = shift;
    my $uri = "https://".$self->server_name.":".$self->server_port."/classifier-api/v1/$action";
    my $req = HTTP::Request->new( 'GET', $uri );
    my $ssl_opts = { verify_hostname => 1, SSL_ca_file => $self->puppet_ssl_path."/certs/ca.pem" };
    if( $self->has_cert_name ){
        $ssl_opts->{SSL_cert_file} = $self->puppet_ssl_path."/certs/".$self->cert_name.".pem";
        $ssl_opts->{SSL_key_file} = $self->puppet_ssl_path."/private_keys/".$self->cert_name.".pem";
    } else {
        $req->header( 'X-Authentication' => $self->access_token );
    }
    my $ua = LWP::UserAgent->new( timeout => $self->timeout, ssl_opts => $ssl_opts );
    my $response = $ua->request( $req );
    my $output;
    if ($response->is_success) {
        $output =  $response->decoded_content;
    } else {
        die $response->status_line."\n".$response->decoded_content;
    }

    my $data  = decode_json( $output );
    return $data;
}

sub push_data_old {
    my $self = shift;
    my $action = shift;
    my $data = shift;
    $data = encode_json( $data ) if ref $data;
    my $uri = "https://".$self->server_name.":".$self->server_port."/classifier-api/v1/$action";
    my $req = HTTP::Request->new( 'POST', $uri );
    my $ssl_opts = { verify_hostname => 1, SSL_ca_file => $self->puppet_ssl_path."/certs/ca.pem" };
    if( $self->has_cert_name ){
        $ssl_opts->{SSL_cert_file} = $self->puppet_ssl_path."/certs/".$self->cert_name.".pem";
        $ssl_opts->{SSL_key_file} = $self->puppet_ssl_path."/private_keys/".$self->cert_name.".pem";
    } else {
        $req->header( 'X-Authentication' => $self->access_token );
    }
    my $ua = LWP::UserAgent->new( timeout => $self->timeout, ssl_opts => $ssl_opts );
    $req->header( 'Content-Type' => 'application/json' );
    $req->content( $data );
    my $response = $ua->request( $req ); 
    my $output;
    if ($response->is_redirect( 303 ) or $response->is_success( 201 )) {
        $output =  $response->decoded_content;
    } else {
        die $response->status_line ."\n".$response->decoded_content;
    }
    if( $output ){
        return decode_json( $output );
    } else {
        return;
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Puppet::Classify - Connects to the Puppet Classifier API (PE Console groups)

=head1 VERSION

version 0.003

=head1 SYNOPSIS

This module interacts with the Puppet Classifier API (i.e. Puppet Enterprise Console Classification groups)

    use Puppet::Classify;

    # Create a Puppet classification object
    my $classify = Puppet::Classify->new( 
                                          cert_name       => $config->{puppet_classify_cert},
                                          server_name     => $config->{puppet_classify_host},
                                          server_port     => $config->{puppet_classify_port},
                                          puppet_ssl_path => $config->{puppet_ssl_path},
                                          puppet_db       => $puppet_db,
                                        );
    # Get a group's rule
    my $rule = $classify->get_group_rule( $group_name );

    # Convert the rule for use with the PuppetDB
    $rule = $classify->convert_rule_for_puppetdb( $rule );

It requires the I<Puppet::DB> module.

=head1 METHODS

=head2 new

Create the I<Puppet::Classify> object.  The following can be set at creation time (defaults shown):

    my $puppet_db = Puppet::DB->new;
    my $classify = Puppet::Classify->new( 
                                          server_name     => 'localhost',
                                          server_port     => 4433,
                                          puppet_ssl_path => '/etc/puppetlabs/puppet/ssl',
                                          puppet_db       => $puppet_db,
                                        );

otherwise to create the object:

    my $puppet_db = Puppet::DB->new;
    my $classify = Puppet::Classify->new;
    my $classify = Puppet::Classify->new( 'puppet.example.com' );
    my $classify = Puppet::Classify->new( puppet_db => $puppet_db);

=head2 server_name

The puppet master that is running the classifier API. Connects to L<localhost> by default.

    $classify->server_name('puppet.example.com');

=head2 server_port

Connect to the Puppet Classifier server on port 4433 by default - this can be overidden when consumed.

    $classify->server_port(8754);

=head2 access_token

Use an access_token instead of a certificate to connect to the API.
This loads the authentication token saved in your home, but it can be set manually if it is not stored there.

    say $classify->access_token;

=head2 environment

The environment to use for the classification - this can be overidden when consumed. Defaults to 'dev'.

    $classify->environment('test');

=head2 cert_name

the basename of the certificate to be used for authentication.  This is a certificate that has been generated on the
Puppet Master and added to the whitelist.  This can be used instead of using an auth token.

    $classify->cert_name('api_access');

=head2 puppet_ssl_path

Set the path to the Puppet SSL certs, it uses the Puppet enterprise path by default.

    $classify->server_name('puppet.example.com');

=head2 timeout

The connection timeout.  Defaults to 360 seconds.

    $classify->timeout(30);

=head2 puppet_db

The puppet DB object used to interact with the Puppet DB.

    $classify->puppet_db(Puppet::DB->new);

=head2 update_classes

Updates the class cache.

    $classify->update_classes;

=head2 get_classes

Gets a list of all the class information.

    my $classes = $classify->get_classes( $group );

=head2 get_group_rule

Returns the rule as a Perl data structure given the group name.

    my $group_name = "Production";
    my $group_rule = $classify->get_group_rule( $group_name );

=head2 get_group_id

Returns the group ID given the group name.

    my $group_name = "Production environment";
    my $group_id = $classify->get_group_id( $group_name );

=head2 get_groups_match

Returns an array ref of a list of group data structures where their names match the given string

    my $groups = $classify->get_groups_match( "Roles" );
    say Dumper( $groups );

=head2 get_groups

Returns an array ref of all the group data structures

    my $groups = $classify->get_groups;
    say Dumper( $groups );

=head2 get_group_children

Returns an array ref of all the group data structures according to the specified parent group ID

    my $parent = "Production environment";
    my $parent_gid = $classify->get_group_id( $parent );
    my $children = $classify->get_group_children( $parent_gid );
    say Dumper( $children );

=head2 add_group_safe

Creates a new group, but checks if one already exists by the same name.  If it does, the force option can be specified to remove it first - thus redefining it.

The example data structure is the minimum.  See
L<https://puppet.com/docs/pe/latest/groups_endpoint.html#post-v1-groups>
for more info on the fields.

    my $parent = "Production environment";
    my $parent_gid = $classify->get_group_id( $parent );
    my $name = 'A group';
    my $force = 1;
    my $group = { 
                  name   => $name,
                  parent => $parent_id,
                };
    $classify->add_group_safe( $name, $group, $force );

=head2 create_group

Use with caution. It is preferable to use L<add_group_safe>

Creates a new group (or overwrites another).  The example data structure is the minimum.  See
L<https://puppet.com/docs/pe/latest/groups_endpoint.html#post-v1-groups>
for more info on the fields.

    my $parent = "Production environment";
    my $parent_gid = $classify->get_group_id( $parent );
    my $group = { 
                  name   => 'A group',
                  parent => $parent_id,
                };
    $classify->create_group( $group );

=head2 update_group_rule

Replaces a groups rule with a new one.  The group is specified by its group ID.

    $classify->update_group_rule( $gid, $rule );

=head2 update_group_environment

Sets the environment for a group.  The group is specified by its group ID.

    $classify->update_group_environment( $gid, $environment );

=head2 update_group

Updates a groups info according to the specified hash.  Only the elements
specified in the hash are updated (replaced).

    my $config = { 
                  environment => $environment,
                  parent => $parent_id,
                };
    $classify->update_group( $gid, $config );

=head2 remove_group_safe

Removes a group unless it has pinned nodes.  It can still be deleted if it has pinned nodes if a force option is turned on.

    my $force = 1;
    $classify->create_group( $group_name, $force );

=head2 try_remove_group

This will remove a group, but first check if it has children (it which case it will just log an error rather than doing anything)

    $classify->create_group( $group_name );

It is preferable to call L<remove_group_safe>.

=head2 delete_group

Deletes a group.  This will work ever if nodes are pinned to the group, but it cannot delete groups
that have children groups (the children must be removed first).

    $classify->delete_group( $id );

It is preferable to call L<remove_group_safe>.

=head2 convert_rule_for_puppetdb

Converts a classifier node matching rule into a form that is compatible with the PuppetDB

    my $rule2 = $classify->convert_rule_for_puppetdb( $rule1 );

=head2 get_nodes_matching_group

Returns an array ref list of nodes matching a group.

    my $nodes = $classify->get_nodes_matching_group( $group_name );

This can take some time to run as it needs to connect to the PuppetDB to find out the nodes.

=head2 get_hosts_from_pinned_rule

Returns an array ref list of nodes pinned to a group (you need to pass the rule of the group).

    my $group_rule = $classify->get_group_rule( $group_name );
    my $nodes = $classify->get_hosts_from_pinned_rule( $group_rule );

=head2 list_nodes_pinned_in_group

This lists the nodes in a group to STDOUT.

    $classify->list_nodes_pinned_in_group( $group_name );

=head2 purge_old_nodes

This will purge all the pinned nodes from the children of the specified group if those nodes
cannot be found in the Puppet DB anymore.

    $classify->purge_old_nodes( $parent_id );

=head2 list_membership_of_nodes

For a list of nodes and a parent group, maps which child group each node is pinned to.  If
no nodes are specified, it will be assumed to be all the nodes matching the parent.

    my $nodes = [ qw( node1 node2 ) ];
    $classify->list_membership_of_nodes( $parent_name, $nodes );

or

    $classify->list_membership_of_nodes( $parent_name );

=head2 remove_nodes_from_all_groups

Removes all the specified nodes from all the child groups of the specified parent group.

    my $parent = "Production environment";
    my $parent_gid = $classify->get_group_id( $parent );
    my $nodes = [ qw( node1 node2 ) ];
    $classify->remove_nodes_from_all_groups( $parent_gid, $nodes );

=head2 empty_group_of_pinned_nodes

Remove all pinned nodes from a group leaving other rules in place

    $classify->empty_group_of_pinned_nodes( $group_name );

=head2 remove_pinned_node_from_group

Remove specified pinned nodes from a group leaving other rules in place

    my $nodes = [ qw( node1 node2 ) ];
    $classify->remove_pinned_node_from_group( $group_name, $nodes );

=head2 pin_nodes_to_group

Pin nodes to the specified group

    my $nodes = [ qw( node1 node2 ) ];
    $classify->pin_nodes_to_group( $group_name $nodes );

=head1 AUTHOR

Matthew Mallard <mqtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Matthew Mallard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
