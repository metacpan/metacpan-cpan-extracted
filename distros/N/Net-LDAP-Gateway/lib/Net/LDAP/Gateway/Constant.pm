package Net::LDAP::Gateway::Constant;

use strict;
use warnings;

use Net::LDAP::Gateway ();

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS;

my %tag = map { $_ => uc "LDAP_${_}_"} qw(op deref_aliases scope filter);
my %tags;

for my $cst (grep /^LDAP_/, keys %{Net::LDAP::Gateway::Constant::}) {
    my $tag = 'error';
    # print "cst: $cst\n";
    for(keys %tag) {
	$tag = $_
	    if index($cst, $tag{$_}) == 0
    }
    push @{$EXPORT_TAGS{$_} ||= []}, $cst
	for ($tag, 'all');

    # no strict 'refs';
    # my $v = ${$cst};
    # print "cst: $cst\n";
    # *$cst = sub () { $v };
}

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;
