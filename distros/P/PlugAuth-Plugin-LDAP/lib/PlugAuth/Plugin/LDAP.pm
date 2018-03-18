package PlugAuth::Plugin::LDAP;

# ABSTRACT: (Deprecated) LDAP back end for PlugAuth
our $VERSION = '0.09'; # VERSION


use strict;
use warnings;
use v5.10;
use Net::LDAP;
use Log::Log4perl qw/:easy/;
use Role::Tiny::With;

with 'PlugAuth::Role::Plugin';
with 'PlugAuth::Role::Auth';


sub check_credentials {
    my ($class, $user,$pw) = @_;
    $user = lc $user;

    my $ldap_config = $class->global_config->ldap(default => '');

    if (!$ldap_config or !$ldap_config->{authoritative}) {
        # Check files first.
        return 1 if $class->deligate_check_credentials($user, $pw);
    }
    return 0 unless $ldap_config;
    my $server = $ldap_config->{server} or LOGDIE "Missing ldap server";
    my $ldap = Net::LDAP->new($server, timeout => 5) or do {
        ERROR "Could not connect to ldap server $server: $@";
        return 0;
    };
    my $orig = $user;
    my $extra = $user =~ tr/a-zA-Z0-9@._-//dc;
    WARN "Invalid username '$orig', turned into $user" if $extra;
    my $dn = sprintf($ldap_config->{dn},$user);
    my $mesg = $ldap->bind($dn, password => $pw);
    $mesg->code or return 1;
    INFO "Ldap returned ".$mesg->code." : ".$mesg->error;
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Plugin::LDAP - (Deprecated) LDAP back end for PlugAuth

=head1 VERSION

version 0.09

=head1 SYNOPSIS

In your PlugAuth.conf file:

 ---
 ldap :
   server : ldap://198.118.255.141:389
   dn : uid=%s, ou=people, dc=users, dc=example, dc=com
   authoritative : 1

Note that %s in the dn will be replaced with the username
when binding to the LDAP server.

=head1 DESCRIPTION

B<NOTE>: This module has been deprecated, and may be removed on or after 31 December 2018.
Please see L<https://github.com/clustericious/Clustericious/issues/46>.

Handle authentication only from LDAP server.
Everything else is handled by L<PlugAuth::Plugin::FlatAuth>
(e.g. authorization, groups, etc).

=head1 METHODS

=head2 PlugAuth::Plugin::LDAP-E<gt>check_credentials( $user, $password )

Given a user and password, check to see if the password is correct.

=head1 SEE ALSO

L<PlugAuth>, L<PlugAuth::Routes>, L<PlugAuth::Plugin::FlatAuth>

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
