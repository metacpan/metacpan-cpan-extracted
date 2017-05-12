# Net::IPA.pm -- Perl 5 interface of the (Free)IPA JSON-RPC API
#
#   for more information about this api see: https://vda.li/en/posts/2015/05/28/talking-to-freeipa-api-with-sessions/
#
#   written by Nicolas Cisco (https://github.com/nickcis)
#   https://github.com/nickcis/perl-Net-IPA
#
#     Copyright (c) 2016 Nicolas Cisco. All rights reserved.
#     Licensed under the GPLv2, see LICENSE file for more information.

package Net::IPA::Methods;
use strict;

use JSON;

our $USE_RAW = JSON::true;

#** Ping request
#*
sub ping
{
	return {
		method => 'ping',
		params => [
			[],
			{}
		]
	};
}

##** user-show request
# @param $username: uid of the queried user
# @param %args: optional named arguments
#*
sub user_show
{
	my ($username, %args) = @_;

	unless(%args){
		%args = (
			all => 0,
			no_members => 0,
			rights => 0,
		);
	}

	$args{raw} = $USE_RAW unless(exists $args{raw});

	return {
		method => 'user_show',
		params => [
			[ $username ],
			\%args,
		]
	};
}

##** Ejecuta group-show
# @param $group: nombre del grupo
# @param $args : argumentos opcionales
# @return Lo que devuelve IPA
#*
sub group_show
{
	my ($username, %args) = @_;

	$args{raw} = $USE_RAW unless(exists $args{raw});

	return {
		method => 'group_show',
		params => [
			[ $username ],
			\%args,
		]
	};
}

#** Ejecuta group-remove-member
# Saca miembros del un grupo
# @param $group: nombre del group
# @param Usuario 1
# @param Usuario ... n
# @return Anda a saber
#*
sub group_remove_member
{
	my ($group, @users) = @_;
	return {
		method => 'group_remove_member',
		params => [
			[ $group ],
			{
				all => 0,
				no_members => 0,
				user => \@users,
				raw => $USE_RAW,
			}
		]
	};
}

#** Ejecuta group-add-member
# Agrega un miembro a un grupo
# @param $group: nombre del grupo
# @param Usuario 1
# @param Usuario ... n
#*
sub group_add_member
{
	my ($group, @users) = @_;
	return {
		method => 'group_add_member',
		params => [
			[ $group ],
			{
				all => 0,
				no_members => 0,
				user => \@users,
				raw => $USE_RAW,
			}
		]
	};
}

sub user_find
{
	my ($user, %args) = @_;

	unless(%args){
		%args = (
			all => 0,
			no_members => JSON::false,
			pkey_only => JSON::false,
		);
	}

	$args{raw} = $USE_RAW unless(exists $args{raw});

	return {
		method => 'user_find',
		params => [
			[ $user || '' ],
			\%args,
		]
	};
}

sub group_find
{
	my ($group, $kargs) = @_;
	return {
		method => 'group_find',
		params => [
			[ $group || '' ],
			$kargs || {
				all => 0,
				sizelimit => 0,
				pkey_only => JSON::false,
				raw => $USE_RAW,
			}
		]
	};
}

sub group_add
{
	my ($group, %args) = @_;

	$args{raw} = $USE_RAW unless(exists $args{raw});

	return {
		method => 'group_add',
		params => [
			[ $group ],
			\%args
		]
	};
}

sub group_del
{
	my ($group, %args) = @_;

	return {
		method => 'group_del',
		params => [
			[ $group ],
			\%args
		]
	};
}

sub user_add
{
	my ($user, %args) = @_;

	$args{all} = JSON::false unless(exists $args{all});
	$args{no_members} = JSON::false unless(exists $args{no_members});
	$args{noprivate} = JSON::false unless(exists $args{noprivate});
	$args{random} = JSON::false unless(exists $args{random});
	$args{raw} = $USE_RAW unless(exists $args{raw});

	return {
		method => 'user_add',
		params => [
			[ $user ],
			\%args
		]
	}
}

sub user_del
{
	my ($user, %args) = @_;

	$args{preserve} = JSON::false unless(exists $args{preserve});

	return {
		method => 'user_del',
		params => [
			[ $user ],
			\%args
		]
	};
}

sub user_disable
{
	my ($user, %args) = @_;
	return {
		method => 'user_disable',
		params => [
			[ $user ],
			\%args
		]
	};
}

sub user_enable
{
	my ($user, %args) = @_;
	return {
		method => 'user_enable',
		params => [
			[ $user ],
			\%args
		]
	};
}

sub user_mod
{
	my ($user, %args) = @_;
	return {
		method => 'user_mod',
		params => [
			[ $user ],
			\%args
		]
	};
}

#** Agrega una zona de dns.
# Especificar en args 'idnsallowdynupdate' para dynamic update!
# @param $name: nombre de la zona
# @param %args 
#*
sub dnszone_add
{
	my ($name, %args) = @_;
	return {
		method => 'dnszone_add',
		params => [
			[ $name ],
			\%args
		],
	};
}

sub dnszone_del
{
	my ($name, %args) = @_;
	return {
		method => 'dnszone_del',
		params => [
			[ $name ],
			\%args
		]
	};
}

sub dnszone_find
{
	my ($name, %args) = @_;

	unless(%args){
		%args = (
			pkey_only => JSON::false,
			sizelimit => 0,
			raw => $USE_RAW,
		);
	}

	return {
		method => 'dnszone_find',
		params => [
			[ $name || '' ],
			\%args
		]
	};
}

#** Modifica valores de la zona
# En params se puede especificar:
#    - Dynamic update: 'idnsallowdynupdate' => 'TRUE' / 'FALSE'
#    - Administrator e-mail address: 'idnssoarname'
#    - SOA expire: 'idnssoaexpire'
#    - SOA minimum: 'idnssoaminimum'
#    - SOA refresh: 'idnssoarefresh'
#    - SOA retry: 'idnssoaretry'
#    - SOA serial: 'idnssoaserial'
#*
sub dnszone_mod
{
	my ($name, $name, %args) = @_;

	$args{rights} = JSON::true unless(exists $args{rights});
	$args{all} = JSON::true unless(exists $args{all});

	return {
		method => 'dnszone_mod',
		params => [
			[ $name ],
			\%args
		]
	};
}

sub dnsrecord_add
{
	my ($zone, $name, %args) = @_;
	return {
		method => 'dnsrecord_add',
		params => [
			[ $zone, $name ],
			\%args
		]
	};
}

sub dnsrecord_del
{
	my ($zone, $name, %args) = @_;
	$args{del_all} = JSON::true unless(exists $args{del_all});
	return {
		method => 'dnsrecord_del',
		params => [
			[ $zone, $name ],
			\%args
		]
	};
}

#**
# 'a_extra_create_reverse' => 1 :: Para crear reverso
#*
sub dnsrecord_add_a
{
	my ($zone, $name, $ip, %args) = @_;
	$args{a_part_ip_address} = $ip;
	return dnsrecord_add($zone, $name, %args);
}

sub dnsrecord_add_ns
{
	my ($zone, $name, $hostname, %args) = @_;
	$args{ns_part_hostname} = $hostname;
	return dnsrecord_add($zone, $name, %args);
}

sub dnsrecord_add_mx
{
	my ($zone, $name, $preference, $exchanger, %args) = @_;
	$args{mx_part_preference} = $preference;
	$args{mx_part_exchanger} = $exchanger;
	return dnsrecord_add($zone, $name, %args);
}

sub dnsrecord_add_cname
{
	my ($zone, $name, $hostname, %args) = @_;
	$args{cname_part_hostname} = $hostname;
	return dnsrecord_add($zone, $name, %args);
}

sub dnsrecord_add_ptr
{
	my ($zone, $name, $hostname, %args) = @_;
	$args{ptr_part_hostname} = $hostname;
	return dnsrecord_add($zone, $name, %args);
}

sub dnsrecord_add_srv
{
	my ($zone, $name, $priority, $weight, $port, $target, %args) = @_;
	$args{ptr_part_priority} = $priority;
	$args{ptr_part_weight} = $weight;
	$args{ptr_part_port} = $port;
	$args{ptr_part_target} = $target;
	return dnsrecord_add($zone, $name, %args);
}

sub dnsrecord_add_txt
{
	my ($zone, $name, $data, %args) = @_;
	$args{txt_part_data} = $data;
	return dnsrecord_add($zone, $name, %args);
}
#
#** Adds a forward dns zone
# @param $name: nombre de la zona
# @param $zone_forwarders : ip (string) or ref array of ip (string)
# @param %args (
#   idnsforwardpolicy: 'first' / 'only' / 'disabled'
# )
#*
sub dnsforwardzone_add
{
	my ($name, $zone_forwarders, %args) = @_;
	$args{idnsforwarders} = $zone_forwarders;
	$args{idnsforwardpolicy} = 'first' unless(exists $args{idnsforwardingpolicy});
	return {
		method => 'dnsforwardzone_add',
		params => [
			[ $name ],
			\%args
		],
	};
}

sub dnsforwardzone_del
{
	my ($name, %args) = @_;
	return {
		method => 'dnsforwardzone_del',
		params => [
			[ $name ],
			\%args
		]
	};
}

sub dnsforwardzone_find
{
	my ($name, %args) = @_;
	unless(%args){
		%args = (
			pkey_only => JSON::false,
			sizelimit => 0,
			raw => $USE_RAW,
		);
	}

	return {
		method => 'dnsforwardzone_find',
		params => [
			[ $name || '' ],
			\%args
		]
	};
}

1;
