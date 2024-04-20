package Net::EPP::ResponseCodes;
use base qw(Exporter);
use vars qw(@EXPORT);
use strict;

=head1 NAME

Net::EPP::ResponseCodes - a module to export some constants that correspond to
EPP response codes.

=head1 SYNOPSIS

    use Net::EPP::ResponseCodes;
    use Net::EPP::Simple;
    use strict;

    my $epp = Net::EPP::Simple->new(
        host    => 'epp.nic.tld',
        user    => 'my-id',
        pass    => 'my-password',
    );

    my $result = $epp->domain_transfer_request('example.tld', 'foobar', 1);

    if ($result) {
        print "Transfer initiated OK\n";

    } else {
        if ($Net::EPP::Simple::Code == OBJECT_PENDING_TRANSFER) {
            print "Error: domain is already pending transfer\n";

        } elsif ($Net::EPP::Simple::Code == INVALID_AUTH_INFO) {
            print "Error: invalid authcode provided\n";

        } elsif ($Net::EPP::Simple::Code == OBJECT_DOES_NOT_EXIST) {
            print "Error: domain not found\n";

        } elsif ($Net::EPP::Simple::Code == STATUS_PROHIBITS_OP) {
            print "Error: domain cannot be transferred\n";

        } else {
            print "Error code $Net::EPP::Simple::Code\n";

        }
    }

=head1 DESCRIPTION

Every response sent to the client by an EPP server contains at least one
C<E<lt>resultE<gt>> element that has a C<code> attribute. This is a four-digit
numeric code that describes the result of the request. This module exports a set
of constants that provide handy mnemonics for each of the defined codes.

=head1 EXPORTS

C<Net::EPP::ResponseCodes> exports the following constants. The number in
brackets is the integer value associated with the constant.

=head2 Successful command completion responses (1nnn)

=over

=item  OK (1000)

=item  OK_PENDING (1001)

=item  OK_NO_MESSAGES (1300)

=item  OK_MESSAGES (1301)

=item  OK_BYE (1500)

=back

=head2 Command error responses (2nnn)

=head3 Protocol Syntax

=over

=item  UNKNOWN_COMMAND (2000)

=item  SYNTAX_ERROR (2001)

=item  USE_ERROR (2002)

=item  MISSING_PARAM (2003)

=item  PARAM_RANGE_ERROR (2004)

=item  PARAM_SYNTAX_ERROR (2005)

=back

=head3 Implementation-specific Rules

=over

=item  UNIMPLEMENTED_VERSION (2100)

=item  UNIMPLEMENTED_COMMAND (2101)

=item  UNIMPLEMENTED_OPTION (2102)

=item  UNIMPLEMENTED_EXTENSION (2103)

=item  BILLING_FAILURE (2104)

=item  NOT_RENEWABLE (2105)

=item  NOT_TRANSFERRABLE (2106)

=back

=head3 Security (22nn)

=over

=item  AUTHENTICATION_ERROR (2200)

=item  AUTHORISATION_ERROR (2201)

=item  AUTHORIZATION_ERROR (2201)

=item  INVALID_AUTH_INFO (2202)

=back

=head3 Data Management (23nn)

=over

=item  OBJECT_PENDING_TRANSFER (2300)

=item  OBJECT_NOT_PENDING_TRANSFER (2301)

=item  OBJECT_EXISTS (2302)

=item  OBJECT_DOES_NOT_EXIST (2303)

=item  STATUS_PROHIBITS_OP (2304)

=item  ASSOC_PROHIBITS_OP (2305)

=item  PARAM_POLICY_ERROR (2306)

=item  UNIMPLEMENTED_OBJECT_SERVICE (2307)

=item  DATA_MGMT_POLICY_VIOLATION (2308)

=back

=head3 Server System (24nn)

=over

=item  COMMAND_FAILED (2400)

=back

=head3 Connection Management (25nn)

=over

=item  COMMAND_FAILED_BYE (2500)

=item  AUTH_FAILED_BYE (2501)

=item  SESSION_LIMIT_EXCEEDED_BYE (2502)

=back

=head1 COPYRIGHT

This module is (c) 2008 - 2023 CentralNic Ltd and 2024 Gavin Brown. This module
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

#
# Successful command completion responses:
#
use constant OK             => 1000;
use constant OK_PENDING     => 1001;
use constant OK_NO_MESSAGES => 1300;
use constant OK_MESSAGES    => 1301;
use constant OK_BYE         => 1500;

#
# Command error responses:
#

# Protocol Syntax:
use constant UNKNOWN_COMMAND    => 2000;
use constant SYNTAX_ERROR       => 2001;
use constant USE_ERROR          => 2002;
use constant MISSING_PARAM      => 2003;
use constant PARAM_RANGE_ERROR  => 2004;
use constant PARAM_SYNTAX_ERROR => 2005;

# Implementation-specific Rules:
use constant UNIMPLEMENTED_VERSION   => 2100;
use constant UNIMPLEMENTED_COMMAND   => 2101;
use constant UNIMPLEMENTED_OPTION    => 2102;
use constant UNIMPLEMENTED_EXTENSION => 2103;
use constant BILLING_FAILURE         => 2104;
use constant NOT_RENEWABLE           => 2105;
use constant NOT_TRANSFERRABLE       => 2106;

# Security:
use constant AUTHENTICATION_ERROR => 2200;
use constant AUTHORISATION_ERROR  => 2201;
use constant AUTHORIZATION_ERROR  => 2201;
use constant INVALID_AUTH_INFO    => 2202;

# Data Management:
use constant OBJECT_PENDING_TRANSFER      => 2300;
use constant OBJECT_NOT_PENDING_TRANSFER  => 2301;
use constant OBJECT_EXISTS                => 2302;
use constant OBJECT_DOES_NOT_EXIST        => 2303;
use constant STATUS_PROHIBITS_OP          => 2304;
use constant ASSOC_PROHIBITS_OP           => 2305;
use constant PARAM_POLICY_ERROR           => 2306;
use constant UNIMPLEMENTED_OBJECT_SERVICE => 2307;
use constant DATA_MGMT_POLICY_VIOLATION   => 2308;

# Server System:
use constant COMMAND_FAILED => 2400;

# Connection Management:
use constant COMMAND_FAILED_BYE         => 2500;
use constant AUTH_FAILED_BYE            => 2501;
use constant SESSION_LIMIT_EXCEEDED_BYE => 2502;

our @EXPORT;
my $package = __PACKAGE__;
foreach my $constant (keys(%constant::declared)) {
    if ($constant =~ /^$package/) {
        $constant =~ s/^$package\:\://;
        push(@EXPORT, $constant);
    }
}

1;
