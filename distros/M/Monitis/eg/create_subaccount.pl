#!/usr/bin/env perl
use strict;
use warnings;

use Monitis;

use Getopt::Long;
use Pod::Usage;

my $opts = {};

my $result = GetOptions(
    "api-key=s"    => \$opts->{api},
    "secret-key=s" => \$opts->{secret},
    "first-name=s" => \$opts->{first},
    "last-name=s"  => \$opts->{last},
    "email=s"       => \$opts->{email},
    "password=s"   => \$opts->{password},
    "group=s"      => \$opts->{group},
);

unless ($opts->{api} && $opts->{secret}) {
    warn "Please, provide API key and secret\n";
    pod2usage;
}

my @lack = grep { !exists $opts->{$_} } qw/first last email password group/;

if (@lack) {
    warn "Following mandatory parameters missing\n\n";
    warn "    $_\n" for @lack;
    warn "\n";
    pod2usage;
}

my $api = Monitis->new(
    secret_key => $opts->{secret},
    api_key    => $opts->{api}
);

my $response = $api->sub_accounts->add(
    firstName => $opts->{first},
    lastName  => $opts->{last},
    email     => $opts->{email},
    password  => $opts->{password},
    group     => $opts->{group},
);

if ($response->{status} eq 'ok') {
    print "Account '$opts->{email}' successfully created\n";
    print "Account ID: $response->{data}{userId}\n";
    exit;
}

my $error_message = $response->{status} || $response->{error};

die <<END;
Error occured while creating account '$opts->{email}':

    $error_message

END

__END__

=head1 NAME

create_subaccount.pl - create subbaccount using Monitis API

=head1 SYNOPSIS

create_subaccount.pl [options]

    Options (mandatory):
    --api-key           brief help message
    --secret-key        full documentation
    --first-name        user first name
    --last-name         user last name
    --email             user email
    --password          user password
    --group             group user belongs to

=head1 OPTIONS

=over 4

=item B<--api-key>

Your API key.
You can get it at L<http://monitis.com/> under Tools -> API -> API key

=item B<--api-secret>

Your API secret.
You can get it at L<http://monitis.com/> under Tools -> API -> API key

=back

=head1 DESCRIPTION

Creates new subaccount


=head1 AUTHOR

Yaroslav Korshak  C<< <ykorshak@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (C) 2006-2011, Monitis Inc.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
