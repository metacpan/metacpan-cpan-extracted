#!/usr/bin/perl

use strict;
use Net::LDAP;
use vars qw($opt_n $opt_v $opt_b $opt_d $opt_D $opt_w $opt_h $opt_p $opt_3 $opt_x);
use Getopt::Std;
use Data::Dumper;

print "Usage: $0 [options]
options:\
    -v          run in verbose mode\
    -h host     ldap server\
    -x          dump schema content or whatever..

    unused/untested:
    -n          show what would be done but don\'t actually do\
    -b basedn   search here 
    -d level    set LDAP debugging level to \'level\'\
    -D binddn   bind dn\
    -w passwd   bind passwd (for simple authentication)\
    -p port     port on ldap server\
    -3          connect using LDAPv3, otherwise use LDAPv2\n" unless @ARGV;

getopts('nvxb:d:D:w:h:p:3');

$opt_h = 'gold' unless $opt_h;

my %newargs;

$newargs{port} = $opt_p if $opt_p;
$newargs{debug} = $opt_d if $opt_d;

dumpargs("new", $opt_h, \%newargs) if ($opt_n || $opt_v);
my $ldap;

unless ($opt_n) {
    $ldap = Net::LDAP->new($opt_h, %newargs) or die $@;
}

#
# Bind as the desired version, falling back if required to v2
#
my %bindargs;
$bindargs{dn} = $opt_D if $opt_D;
$bindargs{password} = $opt_w if $opt_w;
$bindargs{version} = $opt_3 ? 3 : 2;

#login
if ($bindargs{version} == 3) {
    dumpargs("bind", undef, \%bindargs) if ($opt_n || $opt_v);
    unless ($opt_n) {
	$ldap->bind(%bindargs) or $bindargs{version} = 2;
    }
}

if ($bindargs{version} == 2) {
    dumpargs("bind", undef, \%bindargs) if ($opt_n || $opt_v);
    unless ($opt_n) {
	$ldap->bind(%bindargs) or die $@;
    }
}

die ("not connected: $!") unless $ldap->{net_ldap_socket};

# do 
# my $mesg = $ldap->search(
#                 base   => $opt_b,
#                 scope  => 'sub',
#                 filter => 'objectclass=*'
#                 );
# print Dumper $mesg;

print "============ ROOT DSE DUMP ==============\n"  if ($opt_n || $opt_v);
my $root = $ldap->root_dse;
# get naming Context
if ($root) {
        print Dumper $root if ($opt_v);
        $root->get_value( 'namingContext', asref => 1 );
        my $nc = $root->{attrs}->{namingcontexts};
        foreach (@$nc) {
                print "============ DUMP: $_ ==============\n";
                if ($opt_x) {
                        system "ldapsearch -s sub -x -h $opt_h -b '$_' \n";
                } else {
                        print "ldapsearch -s sub -x -h $opt_h -b '$_' \n";
                }
        }
        # get supported LDAP versions
        #print $root->supported_version;
}

print "============ SCHEMA ATTS DUMP ==============\n" if ($opt_n || $opt_v);
unless ($opt_n) {
        my $schema = $ldap->schema or die "no schema: $!";
        print Dumper $schema if $opt_v;
        # get objectClasses
        my @ocs = $schema->all_objectclasses;
        print Dumper @ocs if $opt_v;
        print "====== objectclasses: $#ocs \n" if ($opt_v);
        # Get the attributes
        my @atts = $schema->all_attributes;
        print Dumper @atts if $opt_v;
        print "====== attributes: $#atts \n"  if ($opt_v);
        #foreach (@atts) { print "$_\n"; }
}


# logout
if ($opt_n || $opt_v) {
    print "unbind()\n";
}
unless ($opt_n) {
    $ldap->unbind() or die $@;
}

sub dumpargs {
    my ($cmd,$s,$rh) = @_;
    my @t;
    push @t, "'$s'" if $s;
    map {
	my $value = $$rh{$_};
	if (ref($value) eq 'ARRAY') {
	    push @t, "$_ => [" . join(", ", @$value) . "]";
	} else {
	    push @t, "$_ => '$value'";
	}
    } keys(%$rh);
    print "$cmd(", join(", ", @t), ")\n";
}
