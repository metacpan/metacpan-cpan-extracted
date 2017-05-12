package RT::CIFMinimal;

our $VERSION = '0.01';

use 5.008008;
use warnings;
use strict;

use Net::Abuse::Utils qw(:all);
use Regexp::Common qw/net URI/;
use Net::CIDR;

sub cif_data {
    my $args = shift;
    
    my $fields  = $args->{'fields'} || 'restriction,guid,severity,confidence,address,rdata,portlist,protocol,impact,description,detecttime,alternativeid_restriction,alternativeid';
    my $user    = $args->{'user'};
    my $q       = $args->{'q'};
    my $nolog   = $args->{'nolog'} || 0;
    my $results = $args->{'results'};
    return unless($q);

    require CIF::Client;
    my $tls_verify = RT->Config->Get('CIFMinimal_TLS_Verify') || 0;

    my ($client,$err) = CIF::Client->new({
        host            => RT->Config->Get('CIFMinimal_APIHostname') || RT->Config->Get('WebBaseURL').'/api',
        simple_hashes   => 1,
        fields          => $fields,
        group_map       => 1,
        verify_tls      => $tls_verify,
    });
    warn $err if($err);
    last if($err);
    require CIF::WebAPI::APIKey;
    my @recs = CIF::WebAPI::APIKey->search(uuid_alias => $user->EmailAddress());
    unless($recs[0] && $recs[0]->uuid()){
        # generate apikey
        require RT::CIFMinimal;
        my $id = RT::CIFMinimal::generate_apikey({ user => $user, description => 'generated automatically for WebUI search' });
        unless($id){
            push(@$results, 'unable to automatically generate an apikey, please contact your administrator');
            $RT::Logger->error('unable to generate an apikey for: '.$user->EmailAddress());
            return;
        } else {
            push(@recs,$id);
            push(@$results,'default WebUI apikey '.$id->uuid().' automatically generated');
        }
    }
    $client->{'apikey'} = $recs[0]->uuid();

    my @res;
    my @qarray = split(/,/,$q);
    foreach(@qarray){
        my $feed = $client->GET(
            query   => $_,
            limit   => 25,
            nolog   => $nolog,
        );
        if($feed){
            @recs = @{$feed->{'feed'}->{'entry'}};
            if($#recs > -1){
                @recs = sort { $b->{'confidence'} cmp $a->{'confidence'} } @recs;
                $feed->{'feed'}->{'entry'} = \@recs;
            }
            require CIF::Client::Plugin::Html;
            $client->{'class'}          = 'collection';
            $client->{'evenrowclass'}    = 'evenline';
            $client->{'oddrowclass'}     = 'oddline';
            my $t = CIF::Client::Plugin::Html->write_out($client,$feed,undef);
            push(@res,$t);
        } else {
            if($client->responseCode != 200){
                push(@$results,$client->responseContent());
            }
        }
    }
    my $text = (@res && $#res > -1) ? join("\n",@res) : '<h3>No Results</h3>';
    return($text);
}

sub generate_apikey {
    my $args        = shift;
    my $user        = $args->{'user'};
    my $key_desc    = $args->{'description'};
    my $default_guid    = $args->{'default_guid'};
    my $add_groups      = $args->{'groups'};

    my @a_groups = (ref($add_groups) eq 'ARRAY') ? @$add_groups : $add_groups;

    return unless($user);

    require CIF::WebAPI::APIKey;
    if(ref($user) eq 'RT::User'){
        my $g = $user->OwnGroups();
        my %group_map;

        while(my $grp = $g->Next()){
            next unless($grp->Name() =~ /^DutyTeam (\S+)/);
            my $guid = lc($1);
            my $priority = $grp->FirstCustomFieldValue('CIFGroupPriority');
            $group_map{$guid} = $priority;
        }
        $group_map{'everyone'} = 1000;
        my @sorted = sort { $group_map{$a} <=> $group_map{$b} } keys(%group_map);
        if($default_guid){
            $default_guid = $sorted[0] unless(exists($group_map{$default_guid}));
        } else {
            $default_guid = $sorted[0];
        }
        ## TODO -- fix this
        unless($a_groups[0]){
            @a_groups = @sorted;
        } else {
            foreach (@a_groups){
                return unless(exists($group_map{$_}));
            }
        }
        my $id = CIF::WebAPI::APIKey->genkey(
            uuid_alias      => $user->EmailAddress() || $user->Name(),
            description     => $key_desc,
            default_guid    => $default_guid,
            groups          => join(',',@a_groups),
        );
        return($id); 
    }
}

sub network_info {
    my $addr = shift;

    return if(IsPrivateAddress($addr));
    my ($as,$network,$ccode,$rir,$date) = get_asn_info($addr);
    my $as_desc = '';
    if($as){
        $as_desc = get_as_description($as);
    }
    return({
        asn => $as,
        cidr    => $network,
        cc  => $ccode,
        rir => $rir,
        modified => $date,
        description => $as_desc,
    }) if($as);
    return(0);
}

my @list = (
    "0.0.0.0/8",
    "10.0.0.0/8",
    "127.0.0.0/8",
    "192.168.0.0/16",
    "169.254.0.0/16",
    "192.0.2.0/24",
    "224.0.0.0/4",
    "240.0.0.0/5",
    "248.0.0.0/5"
);

sub IsPrivateAddress {
    my $addr = shift;
    my $found =  Net::CIDR::cidrlookup($addr,@list);
    return($found);
}

sub ReportsByType {
    my $user = shift;

    my @called = caller();
    my $type = $called[1];
    my @t = split(/\//,$type);
    $type = $t[$#t];
    my $category = $t[$#t-1];

    my $reports = RT::Tickets->new($user);
    my $query = "Queue = 'Incident Reports' AND (Status = 'new' OR Status = 'open')";
    $reports->FromSQL($query);
    $reports->OrderByCols({FILED => 'id', ORDER => 'DESC'});
    my @array;

    while(my $r = $reports->Next()){
        push(@array,$r->IODEF->to_tree());
    }
    return ('') unless($#array > -1);
    require JSON;
    return(JSON::to_json(\@array));
}

{
    my %cache;
    sub GetCustomField {
        my $field = shift or return;
        return $cache{ $field } if exists $cache{ $field };

        my $cf = RT::CustomField->new( $RT::SystemUser );
        $cf->Load( $field );
        return $cache{ $field } = $cf;
    }
}

use Hook::LexWrap;
use Regexp::Common;
use Regexp::Common::net::CIDR;

# on OCFV create format storage
require RT::ObjectCustomFieldValue;
wrap 'RT::ObjectCustomFieldValue::Create',
    pre => sub {
        my %args = @_[1..@_-2];
        my $cf = GetCustomField( 'Address' );
        unless ( $cf && $cf->id ) {
            $RT::Logger->crit("Couldn't load IP CF");
            return;
        }

        return unless $cf->id == $args{'CustomField'};

        for ( my $i = 1; $i < @_; $i += 2 ) {
            next unless $_[$i] && $_[$i] eq 'Content';

            my $arg = $_[++$i];
            next if ($arg =~ /^\s*$RE{net}{CIDR}{IPv4}{-keep}\s*$/go );
            my ($sIP, $eIP) = RT::IR::ParseIPRange( $arg );
            unless ( $sIP && $eIP ) {
                #$_[-1] = 0;
                return;
            }
            $_[$i] = $sIP;

            my $flag = 0;
            for ( my $j = 1; $j < @_; $j += 2 ) {
                next unless $_[$j] && $_[$j] eq 'LargeContent';
                $flag = $_[++$j] = $eIP;
                last;
            }
            splice @_, -1, 0, LargeContent => $eIP unless $flag;
            return;
        }
    };

eval "require RT::CIFMinimal_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/CIFMinimal_Vendor.pm});
eval "require RT::CIFMinimal_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/CIFMinimal_Local.pm});

package RT::User;
use Hook::LexWrap;
{
my $obj;
wrap 'RT::User::Create',
    pre => sub {
        my $user = $obj = $_[0];
        my %args = (@_[1..(@_-2)]);
        return if($args{'EmailAddress'});
        unless($args{'EmailAddress'}){ $args{'EmailAddress'} = $args{'Name'}; }
        my @res = $user->Create(%args);
        $_[-1] = \@res;
    },
    post => sub {
        return unless $_[-1];
        my $val = ref $_[-1]? \$_[-1][0]: \$_[-1];
        return unless($val =~ /\d+/);

        if(my %map = RT->Config->Get('CIFMinimal_UserGroupMapping')){
            my $x = $ENV{$map{'EnvVar'}};
            my @tags = split($map{'Pattern'},$x);
            my $group_map = $map{'Mapping'};
            foreach(keys %$group_map){
                foreach my $g (@tags){
                    if($g eq $_){
                        require RT::Group;
                        my $y = RT::Group->new($RT::SystemUser);
                        my ($ret,$err) = $y->LoadUserDefinedGroup($group_map->{$_});
                        $RT::Logger->debug("adding user to group: $g");  
                        ($ret,$err) = $y->AddMember($$val);
                        unless($ret){
                            $RT::Logger->error("Couldn't add user to group: ".$y->Name());
                            $RT::Logger->error($err);
                            $RT::Handle->Rollback();
                            return(0);
                        }
                    }
                }
            }
        } elsif (my $default = RT->Config->Get('CIFMinimal_DefaultUserGroup')){
            require RT::Group;
            my $default = RT->Config->Get('CIFMinimal_DefaultUserGroup');
            return unless($default);
            my $group = RT::Group->new($obj->CurrentUser());
            my ($ret,$err) = $group->LoadUserDefinedGroup($default);
            unless($ret){
                $RT::Logger->error("Couldn't add user to group: ".$default.': '.$err);
                return(0);
            }
            ($ret,$err) = $group->_AddMember(InsideTransaction => 1, PrincipalId => $$val);
            unless($ret){
                $RT::Logger->error("Couldn't add user to group: ".$group->Name());
                $RT::logger->error($err);
                $RT::Handle->Rollback();
                return(0);
            }
        }
    }
}
1;

__END__
=head1 NAME

RT::CIFMinimal - Perl extension for RT+IR integration with CIF

=head1 DESCRIPTION

This module wraps a work-flow friendly UI around CIF using the basic components found in RT.

=head1 SEE ALSO

  http://code.google.com/p/collective-intelligence-framework
  XML::IODEF
  XML::IODEF::Simple

=head1 AUTHOR

Wes Young, E<lt>wes@barely3am.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 REN-ISAC and The Trustees of Indiana University
Copyright (C) 2011 by Wes Young

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
