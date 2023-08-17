#!perl

# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: Artistic-1.0-Perl

use 5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 123;
use experimental qw(smartmatch);

use Net::SharePoint::Basic;

my $sp = Net::SharePoint::Basic->new({config_file => 't/sharepoint.conf'});

is($sp->create_sharepoint_url(), undef, 'undef without a pattern');
is($sp->create_sharepoint_url({type => 'xx'}), undef, 'undef without a pattern');
is($sp->create_sharepoint_url({type => 'list'}), undef, 'undef without a pattern');


sub test_url ($$;@) {

	my $sp   = shift;
	my $opts = shift;
	my @args = @_;

	my $url = $sp->create_sharepoint_url($opts, @args);
	like($url, qr|^https://$sp->{config}{sharepoint_host}|, 'host in');
	like($url, qr|^https://$sp->{config}{sharepoint_host}/$sp->{config}{sharepoint_site}|, 'site in');
	like($url, qr|Shared Documents/$opts->{folder}|, 'folder in') if $opts->{folder} && $opts->{type} ne 'delete' && $opts->{type} ne 'list';
	like($url, qr|\b$opts->{object}\b|, 'object in') if $opts->{object} && $opts->{type} ne 'makedir';# && $opts->{type} ne 'delete';
	like($url, qr|guid.*$args[0]|, 'guid in') if @args;
	like($url, qr|fileOffset='$args[1]'|, 'offset in') if $opts->{type} eq 'chunk' && $opts->{subtype} ne 'start';
}

sub make_url ($$;$) {

	my $sp   = shift;
	my $type = shift;
	my $st   = shift || undef;

	my $opts = { $st ? (subtype => $st) : () };
	$opts->{type} = $type;
	my @args = $st && $type eq 'chunk' ? ('abcdef', 102020) : ();
	test_url($sp, $opts, @args);
	$opts->{folder} = 'xx';
	test_url($sp, $opts, @args);
	delete $opts->{folder};
	$opts->{object} = 'yy';
	test_url($sp, $opts, @args);
	$opts->{folder} = 'aa';
	$opts->{object} = 'bb';
	test_url($sp, $opts, @args);
}

for (qw(upload download makedir delete list chunk)) {
	if ($_ eq 'list') {
		for my $st (qw(files folders)) {
			make_url($sp, 'list', $st);
		}
	}
	elsif ($_ eq 'chunk') {
		for my $st (qw(start continue finish)) {
			make_url($sp, 'chunk', $st);
		}
	}
	else {
		make_url($sp, $_);
	}
}
