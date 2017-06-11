package Net::Domain::Registration::Check;

use 5.006;
use strict;
use warnings;
use utf8;
use Carp;
use Net::DNS;
use Net::Domain::TLD qw(tld_exists);
use base qw(Exporter);

our @EXPORT = qw(domain_on_parent);



=head1 NAME

Net::Domain::Registration::Check - Fast check on availability of domain registration

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

This module takes a quick check on domain registration, to find out if the domain is available or not.

It doesn't query to whois server, but checks if domain exists on its parent nameservers.

So it gets a quick check response.

For domain which is redemptionPeriod status, it does not get listed on parent nameservers, but you can't register it from the registrar this time. See: https://icann.org/epp#redemptionPeriod

It makes no sense on second-level ccTLDs, such as com.cn, co.uk etc. For IANA official root zone DB please see: https://www.iana.org/domains/root/db

I have made a webpage for bulk searching domains based on this module: http://fenghe.org/names/

该模块用来快速检查域名是否可以被注册。

它并不查询whois服务器，而是检查该域名是否存在于父一级的名字服务器上。

所以它的查询非常迅速，远快于whois.

某些待删除的域名处于redemptionPeriod状态，它确实不存在于父一级名字服务器上，但是这个时候你还不能注册。请见：https://icann.org/epp#redemptionPeriod

该模块并不能查询到ccTLD里，各国自己设置的二级域名，比如com.cn，co.uk。IANA官方定义的顶级域名gTLD和国家级域名ccTLD请见：https://www.iana.org/domains/root/db

Usage:

    use Net::Domain::Registration::Check;
	
    print domain_on_parent($domain) ? "domain has been taken" : "domain may not be taken";

Run via command line:

    $ perl -MNet::Domain::Registration::Check -le 'print domain_on_parent(+shift)' yahoo.io
    1

    $ perl -MNet::Domain::Registration::Check -le 'print domain_on_parent(+shift)' yahoo234.com
    0

    $ perl -MNet::Domain::Registration::Check -le 'print domain_on_parent(+shift)' yahoo.nonexist
    domain TLD not exists at -e line 1


=head1 EXPORT

This module exports only one method, domain_on_parent(), to check if domain exists on its parent nameservers.

该模块输出唯一的方法，domain_on_parent()，用来检查域名是否存在于父一级名字服务器上。

如果域名已存在于父一级名字服务器上，则肯定已经被注册了。反过来则可能未被注册。

Important updates:

If the method returns true, most time domain has got taken. But there are few ccTLDs which have wildcards setup, though this is really bad behavior, they break the rule here. For example, .fm domain has wildcard setup, queries to any non-exists .fm domain will get response of NOERROR, rather than NXDOMAIN.

If the method returns false, it may or may not indicate domain has not been taken. For example, when input yahoo.uk, it returns false, but you can't register yahoo.uk at all, because uk's registry keeps it but doesn't delegate DNS to it.

So using this tool for reference only, maybe as a fast filter before whois.

重要更新：

假如该方法返回true，大部分时候表明域名已被注册了。但有少数ccTLD设置了泛域名，尽管这是非常不当的行为，但它破坏了该方法运行的规则。例如，.fm域名设置了泛记录，导致任何不存在的.fm域名查询都返回NOERROR，而不是正确的NXDOMAIN。

假如该方法返回false，它并不直接表明域名未被注册。例如，输入yahoo.uk，返回false，但你并不能注册yahoo.uk，因为uk的注册局保留了它，不过没有做DNS授权。

所以该工具的使用仅做参考，可以作为whois查询之前的快速过滤器。


=cut

sub domain_on_parent {

    my $domain = shift || croak "no domain provided";
    my $tld;

    if ($domain =~ /^(.*?)\.(.*)$/) {
        $tld = $2;
    }
    
    croak "domain TLD not exists" unless tld_exists($tld);

    my $res = Net::DNS::Resolver->new;
    my $answer = $res->query($tld, 'NS');
    my @nameservers;

    if (defined $answer) {
        my @rr= $answer->answer;
        for (@rr) {
            my $ns = $_->rdatastr;
            push @nameservers, $ns;
        }
    }

    $res  = Net::DNS::Resolver->new(nameservers => [@nameservers]);
    $answer = $res->send($domain);

    if ( $answer->header->rcode eq 'NXDOMAIN' ) {
        return 0;
    } elsif ( $answer->header->rcode eq 'NOERROR') {
        return 1;
    } else {
       croak "unsure on domain status: $answer->header->rcode";
    }
}


=head1 AUTHOR

Peng Yonghua <pyh@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to <pyh@cpan.org>, I will respond it quickly.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Domain::Registration::Check


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Domain-Registration-Check>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Domain-Registration-Check>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Domain-Registration-Check>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Domain-Registration-Check/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Peng Yonghua.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Net::Domain::Registration::Check
