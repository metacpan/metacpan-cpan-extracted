#!/usr/bin/perl
# $Id: Parser.pm 399 2010-07-19 01:33:17Z jabra $
package t::Test::Parser;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;
  
    my $session1 = $self->{parser1}->get_session();

    is ( $session1->generated, '20100731T190953350', 'generated');
    
    my @hosts = $self->{parser1}->get_all_hosts();
    is (scalar(@hosts), 1,'size');
    my $host1 = $hosts[0];
    is ( $host1->address, '127.0.0.1', 'address');
    
    my $host1_fp =  $host1->get_fingerprint();
    is ( $host1_fp->certainty, '1.00', 'certainty');
    is ( $host1_fp->description, 'Ubuntu Linux 8.10', 'description');
    is ( $host1_fp->vendor, 'Ubuntu', 'name');
    is ( $host1_fp->family, 'Linux', 'family');
    is ( $host1_fp->product, 'Linux', 'family');
    is ( $host1_fp->version, '8.10', 'family');
    is ( $host1_fp->device_class, '', 'family');
    is ( $host1_fp->arch, 'x86_64', 'family');
 
    my @host1_services = $host1->get_all_services();
    is ( scalar(@host1_services), 4, 'number of services');
    my $host1_service1 = $host1_services[0];
    is ( $host1_service1->port, '22', 'port');
    is ( $host1_service1->name, 'SSH', 'name');
    is ( $host1_service1->protocol, 'tcp', 'protocol');

    my $host1_service2 = $host1_services[1];
    is ( $host1_service2->port, '5432', 'port');
    is ( $host1_service2->name, 'Postgres', 'name');
    is ( $host1_service2->protocol, 'tcp', 'protocol');

    my $host1_service3 = $host1_services[2];
    is ( $host1_service3->port, '631', 'port');
    is ( $host1_service3->name, 'HTTP', 'name');
    is ( $host1_service3->protocol, 'tcp', 'protocol');

    my $host1_service4 = $host1_services[3];
    is ( $host1_service4->port, '80', 'port');
    is ( $host1_service4->name, 'HTTP', 'name');
    is ( $host1_service4->protocol, 'tcp', 'protocol');

    my $host1_service1_fp = $host1_service1->get_fingerprint();

    is ( $host1_service1_fp->certainty, '0.90', 'certainty');
    is ( $host1_service1_fp->description, 'OpenSSH 5.1p1', 'description');
    is ( $host1_service1_fp->vendor, '', 'name');
    is ( $host1_service1_fp->family, 'OpenSSH', 'family');

    my $host1_service2_fp = $host1_service2->get_fingerprint();

    is ( $host1_service2_fp->certainty, undef, 'certainty');
    is ( $host1_service2_fp->description, undef, 'description');
    is ( $host1_service2_fp->vendor, undef, 'name');
    is ( $host1_service2_fp->family, undef, 'family');

    my @host1_vulns = $host1->get_all_vulnerabilities();
    my $host1_vuln1 = $host1_vulns[0];
    is ( $host1_vuln1->id, 'unix-unowned-files-or-dirs','id');
    is ( $host1_vuln1->result_code, 'VE', 'result code');

    my $host1_vuln2 = $host1_vulns[1];
    is ( $host1_vuln2->id, 'generic-ip-source-routing-enabled','id');
    is ( $host1_vuln2->result_code, 'VE', 'result code');

    my @host1_service1_vulns = $host1_service1->get_all_vulnerabilities();
    
    my $host1_service1_vuln1 = $host1_service1_vulns[0];
    is ( $host1_service1_vuln1->id, 'ssh-openssh-cbc-mode-info-disclosure','id');
    is ( $host1_service1_vuln1->result_code, 'VV', 'result code');

    @host1_service1_vuln1_refs = $host1_service1_vuln1->get_all_references();
    is ( scalar( @host1_service1_vuln1_refs), 5, 'size refs');
    
    my $host1_service1_vuln1_ref1 =  $host1_service1_vuln1_refs[0];
    is ( $host1_service1_vuln1_ref1->type, 'cve','id');
    is ( $host1_service1_vuln1_ref1->id, 'CVE-2008-5161', 'id');

    my $host1_service1_vuln1_ref2 =  $host1_service1_vuln1_refs[1];
    is ( $host1_service1_vuln1_ref2->id, '32319','id');
    is ( $host1_service1_vuln1_ref2->type, 'bid', 'type');

    my $host1_service1_vuln1_ref3 =  $host1_service1_vuln1_refs[2];
    is ( $host1_service1_vuln1_ref3->id, '32760','id');
    is ( $host1_service1_vuln1_ref3->type, 'secunia', 'type');

    my @host1_service4_vulns = $host1_service4->get_all_vulnerabilities();
    my $host1_service4_vuln1 = $host1_service4_vulns[0];
    is ( $host1_service4_vuln1->id, 'http-apache-apr_palloc-heap-overflow','id');
    is ( $host1_service4_vuln1->result_code, 'VV', 'result code');

    @host1_service4_vuln1_refs = $host1_service4_vuln1->get_all_references();
    is ( scalar( @host1_service4_vuln1_refs), 4, 'size refs');
    
    my $host1_service4_vuln1_ref1 =  $host1_service4_vuln1_refs[0];
    is ( $host1_service4_vuln1_ref1->type, 'cve','id');
    is ( $host1_service4_vuln1_ref1->id, 'CVE-2009-2412', 'id');

    my $host1_service4_vuln1_ref2 =  $host1_service4_vuln1_refs[1];
    is ( $host1_service4_vuln1_ref2->id, '35949','id');
    is ( $host1_service4_vuln1_ref2->type, 'bid', 'type');
}
1;
