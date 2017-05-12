package Net::Duowan::DNS::Records;

use 5.006;
use warnings;
use strict;
use Carp qw/croak/;
use JSON;
use base 'Net::Duowan::DNS::Common';

use vars qw/$VERSION/;
$VERSION = '1.2.0';

sub new {
    my $class = shift;
    my $psp = shift;
    my $token = shift;
    bless { psp => $psp, token => $token },$class;
}

sub fetchSize {
    my $self = shift;
    my $zone = shift || croak "no zone provided";

    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'rec_load_size';
    my %reqs = (a=>$act,psp=>$psp, tkn=>$token, z=>$zone);

    return $self->reqTemplate(%reqs);
}

sub fetchMulti {
    my $self = shift;
    my $zone = shift || croak "no zone provided";

    my %args = @_;
    my $offset = $args{offset} || 0;
    my $number = $args{number} || 100;
    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'rec_load_all';
    my %reqs = (a=>$act, psp=>$psp, tkn=>$token, z=>$zone, offset=>$offset, number=>$number);

    return $self->reqTemplate(%reqs);
}

sub fetchOne {
    my $self = shift;
    my $zone = shift || croak "no zone provided";

    my %args = @_;
    my $rid = $args{rid} || croak "no rid provided";
    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'rec_load';
    my %reqs = (a=>$act, z=>$zone, rid=>$rid, psp=>$psp, tkn=>$token);

    return $self->reqTemplate(%reqs);
}

sub create {
    my $self = shift;
    my $zone = shift || croak "no zone provided";

    my %args = @_;
    my $name = $args{name} || "";
    my $type = $args{type} || croak "no record type provided";
    my $content = $args{content} || croak "no record content provided";
    my $isp = $args{isp} || croak "no ISP provided";
    my $ttl = $args{ttl} || 300;
    my $prio = $args{prio} || 0;
    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'rec_new';
    my %reqs = (a=>$act, z=>$zone, name=>$name, type=>$type, content=>$content, 
                isp=>$isp, ttl=>$ttl, prio=>$prio, psp=>$psp, tkn=>$token);

    return $self->reqTemplate(%reqs);
}

sub modify {
    my $self = shift;
    my $zone = shift || croak "no zone provided";

    my %args = @_;
    my $rid = $args{rid} || croak "no rid provided";
    my $name = $args{name} || "";
    my $type = $args{type} || croak "no record type provided";
    my $content = $args{content} || croak "no record content provided";
    my $isp = $args{isp} || croak "no ISP provided";
    my $ttl = $args{ttl} || 300;
    my $prio = $args{prio} || 0;
    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'rec_edit';
    my %reqs = (a=>$act, z=>$zone, rid=>$rid, name=>$name, type=>$type, content=>$content, 
                isp=>$isp, ttl=>$ttl, prio=>$prio, psp=>$psp, tkn=>$token);

    return $self->reqTemplate(%reqs);
}

sub remove {
    my $self = shift;
    my $zone = shift || croak "no zone provided";

    my %args = @_;
    my $rid = $args{rid} || croak "no rid provided";
    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'rec_delete';
    my %reqs = (a=>$act, z=>$zone, rid=>$rid, psp=>$psp, tkn=>$token);

    return $self->reqTemplate(%reqs);
}

sub bulkCreate {
    my $self = shift;
    my $zone = shift || croak "no zone provided";

    my %args = @_;
    my $records = $args{records} || croak "no records provided";

    unless (ref $records) {
        croak "records must be an array reference";
    }
    $records = to_json($records);

    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'bulk_rec_new';
    my %reqs = (a=>$act, z=>$zone, records=>$records, psp=>$psp, tkn=>$token);

    return $self->reqTemplate(%reqs);
}

sub bulkRemove {
    my $self = shift;
    my $zone = shift || croak "no zone provided";

    my %args = @_;
    my $rids = $args{rids} || croak "no rids provided";
    unless (ref $rids) {
        croak "rids must be an array reference";
    }
    $rids = join ',',@$rids;
    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'bulk_rec_delete';
    my %reqs = (a=>$act, z=>$zone, rids=>$rids, psp=>$psp, tkn=>$token);

    return $self->reqTemplate(%reqs);
}

sub removebyHost {
    my $self = shift;
    my $zone = shift || croak "no zone provided";

    my %args = @_;
    my $name = $args{name} || "";
    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'rec_delete_by_name';
    my %reqs = (a=>$act, z=>$zone, name=>$name, psp=>$psp, tkn=>$token);

    return $self->reqTemplate(%reqs);
}

sub search {
    my $self = shift;
    my $zone = shift || croak "no zone provided";

    my %args = @_;
    my $key = $args{keyword} || croak "no keyword provided";
    my $psp = $self->{psp};
    my $token = $self->{token};
    my $offset = $args{offset} || 0;
    my $number = $args{number} || -1;
    my $act = 'rec_search';
    my %reqs = (a=>$act, z=>$zone, k=>$key, psp=>$psp, tkn=>$token, offset=>$offset, number=>$number);

    return $self->reqTemplate(%reqs);
}

sub fetchbyHost {
    my $self = shift;
    my $zone = shift || croak "no zone provided";

    my %args = @_;
    my $name = $args{name} || "";
    my $psp = $self->{psp};
    my $token = $self->{token};
    my $offset = $args{offset} || 0;
    my $number = $args{number} || -1;
    my $act = 'rec_load_by_name';
    my %reqs = (a=>$act, z=>$zone, name=>$name, psp=>$psp, tkn=>$token, offset=>$offset, number=>$number);

    return $self->reqTemplate(%reqs);
}

sub fetchbyPrefix {
    my $self = shift;
    my $zone = shift || croak "no zone provided";

    my %args = @_;
    my $prefix = $args{prefix} || croak "no record prefix provided";
    my $psp = $self->{psp};
    my $token = $self->{token};
    my $offset = $args{offset} || 0;
    my $number = $args{number} || -1;
    my $act = 'rec_load_by_prefix';
    my %reqs = (a=>$act, z=>$zone, name=>$prefix, psp=>$psp, tkn=>$token, offset=>$offset, number=>$number);

    return $self->reqTemplate(%reqs);
}

1;
