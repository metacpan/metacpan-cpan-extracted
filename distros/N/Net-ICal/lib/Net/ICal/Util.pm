#!/usr/bin/perl -w
# vi:sts=4:shiftwidth=4
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: Util.pm,v 1.4 2001/08/04 04:59:36 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::Util -- Utility functions for Net::ICal modules

=cut

package Net::ICal::Util;
use strict;

use base qw(Exporter);

use Net::Domain qw(hostfqdn);
use Date::ICal;

our %EXPORT_TAGS = (
    all => [qw(
	create_uuid
	add_validation_error
    )],
);

our @EXPORT = ();
our @EXPORT_OK = qw(
    create_uuid
    add_validation_error
);

=head1 DESCRIPTION

General utility functions for Net::ICal and friends

=head1 FUNCTIONS

=head2 create_uuid

Generate a globally unique ID.

=begin testing
use Net::ICal::Util;

my $uuid = create_uuid;

ok(defined($uuid), "create_uuid with no arguments returns a value");

=end

=cut

my $count = 0;
sub create_uuid {
    my ($time) = @_;

    unless (defined $time) {
	#what we really want, but Date::ICal can't handle that yet
	#$time = Date::ICal->new (epoch => time, timezone => 'UTC');
	$time = Date::ICal->new (epoch => time);
    }

    #quick internals hack into Date::ICal to force UTC time instead
    $time->{timezone} = "UTC"; 

    # using Net::Domain to get a fqdn
    my $host = &hostfqdn;	
    chomp $host;

    return $time->ical # time with second precision
	 . "-$$-"      # plus process id
	 . $count++    # plus counter
	 . "\@$host";  # plus fqdn should be sufficiently unique
}


=head2 add_validation_error ($object, $string)

Add a validation error containing $string to the errlog list of 
$object

=begin testing

TODO: {
    local $TODO = "write tests for add_validation_error";
};

=end testing

=cut

sub add_validation_error {
    my ($obj, $str) = @_;
    my $err;

    my $domain = caller;
    $domain =~ s/(.*)::\w+/$1/;
    $err = "[$domain] " . $obj->type;
    #if (UNIVERSAL::can ($obj, 'uid')) {
    #if ($obj->uid) {
#	$err .= " (" . $obj->uid . ")";
#    }
    $err .= ": $str";
    push (@{$obj->errlog}, $err);
}

1;

=head1 SEE ALSO

More documentation pointers can be found in L<Net::ICal>.

=cut
