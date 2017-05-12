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
);

# Check for parameters
unless ($opts->{api} && $opts->{secret}) {
    warn "Please, provide API key and secret\n";
    pod2usage;
}

# Create API instance
my $api = Monitis->new(
    secret_key => $opts->{secret},
    api_key    => $opts->{api}
);

my $param = shift(@ARGV) || '';

# Have numeric ID
if ($param =~ /^\d+$/) {
    delete_account_by_id($api, $param);
    exit;
}

# Make sure we have at least empty string
$param ||= '';

# Get all subaccounts and find one matching our email
my $accounts = $api->sub_accounts->get;
my $found;

foreach my $account (@$accounts) {
    if ($account->{account} eq $param) {
        $found = $account->{id};
        last;
    }
}

if ($found) {
    warn "Found account '$param': id $found\n";
    warn "Try to delete it...\n\n";
    delete_account_by_id($api, $found);
    exit;
}

if ($param) {
    warn "Account '$param' not found\n";
}

# List existing accounts
warn "Existing accounts:\n";
warn "[$_->{id}]\t$_->{account}\n" for @$accounts;
warn "\n";

sub delete_account_by_id {
    my ($api, $id) = @_;
    my $response = $api->sub_accounts->delete(userId => $id);

    my $error = $response->{error};
    $error ||= $response->{status} if $response->{status} ne 'ok';

    die <<END if $error;
Error occured while deleting account '$id':

    $error

END

    print "Account $id successfully deleted\n";

}
__END__

=head1 NAME

delete_subaccount.pl - delete subbaccount using Monitis API

=head1 SYNOPSIS

delete_subaccount.pl <id | account email>

    Options (mandatory):
    --api-key           brief help message
    --secret-key        full documentation

If no email or id provided, prints list of existing accounts.

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

Deletes subaccount by id or email.
If no email or id provided - prints list of existing accounts


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
