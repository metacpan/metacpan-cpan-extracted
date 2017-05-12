#  Copyright (c) 2009-2014 David Caldwell,  All Rights Reserved.

package Net::DNS::Create::Bind;
use Net::DNS::Create qw(internal full_host local_host email interval);
use feature ':5.10';
use strict;
use warnings;

use POSIX qw(strftime);
use File::Slurp qw(write_file);

our %config = (conf_prefix=>'', default_ttl=>'1h', dest_dir=>'.');
sub import {
    my $package = shift;
    my %c = @_;
    $config{$_} = $c{$_} for keys %c;
}

sub quote_txt(@) {
    local $_ = $_[0];
    s/\\/\\\\/g;
    # [[:cntrl:]] Appears redundant, but in perl 5.10 [[:print:]] includes \n (!)
    s/[^[:print:]]|[[:cntrl:]]/sprintf("\\%03o",ord($&))/ge;
    s/["]/\\"/g;
    "\"$_\""
}

sub txt(@) {
    return quote_txt(@_) if scalar @_ == 1;
    '('.join("\n" . " " x 41, map { quote_txt($_) } @_).')';
}

our @zone;
sub domain {
    my ($package, $domain, $entries) = @_;

    my $conf = '$TTL  '.interval($config{default_ttl})."\n".
               join '', map { ;
                              my $rr = lc $_->type;
                              my $ttl = $_->ttl != interval($config{default_ttl}) ? $_->ttl : "";
                              my $prefix = sprintf "%-30s %7s in %-5s", local_host($_->name, $domain), $ttl, $rr;

                              $rr eq 'mx'  ? "$prefix ".$_->preference." ".local_host($_->exchange, $domain)."\n" :
                              $rr eq 'ns'  ? "$prefix ".local_host($_->nsdname, $domain)."\n" :
                              $rr eq 'txt' ? "$prefix ".txt($_->char_str_list)."\n" :
                              $rr eq 'srv' ? "$prefix ".join(' ', $_->priority, $_->weight, $_->port, local_host($_->target, $domain))."\n" :
                              $rr eq 'rp'  ? "$prefix ".local_host(email($_->mbox), $domain)." ".local_host($_->txtdname, $domain)."\n" :
                              $rr eq 'soa' ? "$prefix ".join(' ', local_host($_->mname, $domain),
                                                                  local_host(email($_->rname), $domain),
                                                             '(',
                                                                  $_->serial || strftime('%g%m%d%H%M', localtime),
                                                                  $_->refresh,
                                                                  $_->retry,
                                                                  $_->expire,
                                                                  $_->minimum,
                                                             ')')."\n" :
                              $rr eq 'a'     ? "$prefix ".$_->address."\n" :
                              $rr eq 'cname' ? "$prefix ".local_host($_->cname, $domain)."\n" :
                                  die __PACKAGE__." doesn't handle $rr record types";
                          } @$entries;

    my $conf_name = "$config{dest_dir}/$config{conf_prefix}$domain.zone";
    $conf_name =~ s/\.\././g;
    push @zone, { conf => $conf_name, domain => $domain };
    write_file($conf_name, $conf);
}

sub master {
    my ($package, $filename, $prefix, @extra) = @_;
    $prefix //= '';
    my $master_file_name = "$config{dest_dir}/$config{conf_prefix}$filename";
    write_file($master_file_name,
               @extra,
               map { <<EOZ
zone "$_->{domain}" {
    type master;
    file "$prefix$_->{conf}";
};

EOZ
               } @zone);
    system("named-checkconf", "-z", $master_file_name);
}

sub domain_list($@) {
    print "$config{conf_prefix}$_[0].zone\n";
}

sub master_list($$) {
    print "$config{conf_prefix}$_[0]\n"
}

1;
__END__

=head1 NAME

Net::DNS::Create::Bind - Bind backend for Net::DNS::Create

=head1 SYNOPSIS

 use Net::DNS::Create qw(Bind), default_ttl => "1h", conf_prefix => "local_", dest_dir => "./bind";

 domain "example.com", { %records };

 master "master.conf", "/etc/bind/";

=head1 DESCRIPTION

You should never use B<Net::DNS::Create::Bind> directly. Instead pass "Bind" to
B<< L<Net::DNS::Create> >> in the "use" line.

=head1 OPTIONS

The following options are specific to B<Net::DNS::Create::Bind>:

=over 4

=item C<conf_prefix>

This controls how the file names for each zone file are created. If you have 2
domains, "example.com" and "example.net", and the conf_prefix is "local_" then
the zone files will be named "I<local_example.com.zone>" and
"I<local_example.net.zone>".

The default conf_prefix is C<''>.

=item C<dest_dir>

This controls where the master and zone files are put. It defaults to C<''>.

=back

=head1 MASTER PARAMETERS

 master "filename", "prefix", @extra_lines;

=over 4

=item C<filename>

The file name for the master file. The file will be placed in the directory
specified by the C<dest_dir> option, described above.

=item C<prefix>

Bind requires absolute path names. This parameter controls the include path for
the zone files inside the master file. You will probably want 'I</etc/bind>' or
'I</etc/named>'.

=item C<@extra_lines>

This lets you add extra configuration lines to the master.conf file, if you need
to for some reason.

=back

=head1 SEE ALSO

L<The Bind Home Page|https://www.isc.org/downloads/bind/>

L<Net::DNS::Create>

L<The Net::DNS::Create Home Page|https://github.com/caldwell/net-dns-create>

=head1 AUTHOR

David Caldwell E<lt>david@porkrind.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2014 by David Caldwell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
