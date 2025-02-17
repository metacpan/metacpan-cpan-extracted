package Sisimai::Order;
use v5.26;
use strict;
use warnings;
use Sisimai::Lhost;

sub make {
    # Returns an MTA Order decided by the first word of the "Subject": header
    # @param         [String] argv0 Subject header string
    # @return        [Array]        Order of MTA modules
    # @since         v4.25.4
    my $class = shift;
    my $argv0 = shift || return []; y/_[] / /s, s/\A[ ]+// for $argv0;
    my @words = split(/[ ]/, lc($argv0), 3);
    my $first = '';

    # The following order is decided by the first 2 words of Subject: header
    state $subject = {
        'abuse-report'     => ['Sisimai::ARF'],
        'auto'             => ['Sisimai::RFC3834'],
        'auto-reply'       => ['Sisimai::RFC3834'],
        'automatic-reply'  => ['Sisimai::RFC3834'],
        'aws-notification' => ['Sisimai::Lhost::AmazonSES'],
        'complaint-about'  => ['Sisimai::ARF'],
        'delivery-failure' => ['Sisimai::Lhost::Domino', 'Sisimai::Lhost::X2'],
        'delivery-notification' => ['Sisimai::Lhost::MessagingServer'],
        'delivery-report'  => ['Sisimai::Lhost::PowerMTA'],
        'delivery-status'  => [
            'Sisimai::Lhost::GSuite',
            'Sisimai::Lhost::Outlook',
            'Sisimai::Lhost::GoogleGroups',
            'Sisimai::Lhost::McAfee',
            'Sisimai::Lhost::OpenSMTPD',
            'Sisimai::Lhost::AmazonSES',
            'Sisimai::Lhost::AmazonWorkMail',
            'Sisimai::Lhost::ReceivingSES',
            'Sisimai::Lhost::Gmail',
            'Sisimai::Lhost::X3',
        ],
        'dmarc-ietf-dmarc' => ['Sisimai::ARF'],
        'email-feedback'   => ['Sisimai::ARF'],
        'failed-delivery'  => ['Sisimai::Lhost::X2'],
        'failure-delivery' => ['Sisimai::Lhost::X2'],
        'failure-notice'   => [
            'Sisimai::Lhost::Yahoo',
            'Sisimai::Lhost::qmail',
            'Sisimai::Lhost::mFILTER',
            'Sisimai::Lhost::Activehunter',
            'Sisimai::Lhost::X4',
        ],
        'loop-alert'    => ['Sisimai::Lhost::FML'],
        'mail-could'    => ['Sisimai::Lhost::InterScanMSS'],
        'mail-delivery' => [
            'Sisimai::Lhost::Exim',
            'Sisimai::Lhost::DragonFly',
            'Sisimai::Lhost::MailRu',
            'Sisimai::Lhost::GMX',
            'Sisimai::Lhost::EinsUndEins',
            'Sisimai::Lhost::Zoho',
            'Sisimai::Lhost::MessageLabs',
            'Sisimai::Lhost::MXLogic',
        ],
        'mail-failure' => ['Sisimai::Lhost::Exim'],
        'mail-not'     => ['Sisimai::Lhost::X4'],
        'mail-system'  => ['Sisimai::Lhost::EZweb'],
        'message-delivery' => ['Sisimai::Lhost::MailFoundry'],
        'message-frozen'   => ['Sisimai::Lhost::Exim'],
        'message-you'      => ['Sisimai::Lhost::Barracuda'],
        'não-entregue'     => ['Sisimai::Lhost::Office365'],
        'non-recapitabile' => ['Sisimai::Lhost::Exchange2007'],
        'non-remis' => ['Sisimai::Lhost::Exchange2007'],
        'notice'    => ['Sisimai::Lhost::Courier'],
        'onbestelbaar'       => ['Sisimai::Lhost::Office365'],
        'permanent-delivery' => ['Sisimai::Lhost::X4'],
        'postmaster-notify'  => ['Sisimai::Lhost::Sendmail'],
        'returned-mail' => [
            'Sisimai::Lhost::Sendmail',
            'Sisimai::Lhost::Aol',
            'Sisimai::Lhost::V5sendmail',
            'Sisimai::Lhost::Bigfoot',
            'Sisimai::Lhost::Biglobe',
            'Sisimai::Lhost::X1',
        ],
        'sorry-your' => ['Sisimai::Lhost::Facebook'],
        'there-was'  => ['Sisimai::Lhost::X6'],
        'undeliverable' => [
            'Sisimai::Lhost::Office365',
            'Sisimai::Lhost::Exchange2007',
            'Sisimai::Lhost::Aol',
            'Sisimai::Lhost::Exchange2003',
        ],
        'undeliverable-mail' => [
            'Sisimai::Lhost::Amavis',
            'Sisimai::Lhost::MailMarshalSMTP',
            'Sisimai::Lhost::IMailServer',
        ],
        'undeliverable-message' => ['Sisimai::Lhost::Notes', 'Sisimai::Lhost::Verizon'],
        'undelivered-mail' => [
            'Sisimai::Lhost::Postfix',
            'Sisimai::Lhost::Aol',
            'Sisimai::Lhost::SendGrid',
            'Sisimai::Lhost::Zoho',
        ],
        'warning' => ['Sisimai::Lhost::Sendmail', 'Sisimai::Lhost::Exim'],
    };

    if( rindex($words[0], ':') > 0 ) {
        # Undeliverable: ..., notify: ...
        $first = lc substr($argv0, 0, index($argv0, ':'));

    } else {
        # Postmaster notify, returned mail, ...
        $first = join('-', splice(@words, 0, 2));
    }
    $first =~ y/:",*//d;
    return $subject->{ $first } || [];
}

sub default {
    # Make default order of MTA modules to be loaded
    # @return   [Array] Default order list of MTA modules
    # @since v4.13.1
    return [map { 'Sisimai::Lhost::'.$_ } Sisimai::Lhost->index()->@*];
}

sub another {
    # Make MTA modules list as a spare
    # @return   [Array] Ordered module list
    # @since v4.13.1

    # There are another patterns in the value of "Subject:" header of a bounce mail generated by the
    # following MTA modules
    state $orderE0 = [
        'Sisimai::Lhost::MailRu',
        'Sisimai::Lhost::Yandex',
        'Sisimai::Lhost::Exim',
        'Sisimai::Lhost::Sendmail',
        'Sisimai::Lhost::Aol',
        'Sisimai::Lhost::Office365',
        'Sisimai::Lhost::Exchange2007',
        'Sisimai::Lhost::Exchange2003',
        'Sisimai::Lhost::AmazonWorkMail',
        'Sisimai::Lhost::AmazonSES',
        'Sisimai::Lhost::Barracuda',
        'Sisimai::Lhost::InterScanMSS',
        'Sisimai::Lhost::KDDI',
        'Sisimai::Lhost::SurfControl',
        'Sisimai::Lhost::Verizon',
        'Sisimai::Lhost::ApacheJames',
        'Sisimai::Lhost::X2',
        'Sisimai::Lhost::X5',
        'Sisimai::Lhost::FML',
    ];

    # Fallback list: The following MTA/ESP modules is not listed orderE0
    state $orderE1 = [
        'Sisimai::Lhost::Postfix',
        'Sisimai::Lhost::GSuite',
        'Sisimai::Lhost::Yahoo',
        'Sisimai::Lhost::Outlook',
        'Sisimai::Lhost::GMX',
        'Sisimai::Lhost::MessagingServer',
        'Sisimai::Lhost::EinsUndEins',
        'Sisimai::Lhost::Domino',
        'Sisimai::Lhost::Notes',
        'Sisimai::Lhost::qmail',
        'Sisimai::Lhost::Courier',
        'Sisimai::Lhost::OpenSMTPD',
        'Sisimai::Lhost::Zoho',
        'Sisimai::Lhost::MessageLabs',
        'Sisimai::Lhost::MXLogic',
        'Sisimai::Lhost::MailFoundry',
        'Sisimai::Lhost::McAfee',
        'Sisimai::Lhost::V5sendmail',
        'Sisimai::Lhost::mFILTER',
        'Sisimai::Lhost::SendGrid',
        'Sisimai::Lhost::ReceivingSES',
        'Sisimai::Lhost::Amavis',
        'Sisimai::Lhost::PowerMTA',
        'Sisimai::Lhost::GoogleGroups',
        'Sisimai::Lhost::Gmail',
        'Sisimai::Lhost::EZweb',
        'Sisimai::Lhost::IMailServer',
        'Sisimai::Lhost::MailMarshalSMTP',
        'Sisimai::Lhost::Activehunter',
        'Sisimai::Lhost::Bigfoot',
        'Sisimai::Lhost::Biglobe',
        'Sisimai::Lhost::Facebook',
        'Sisimai::Lhost::X4',
        'Sisimai::Lhost::X1',
        'Sisimai::Lhost::X3',
        'Sisimai::Lhost::X6',
    ];

    return [@$orderE0, @$orderE1];
};

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Order - A Class for making an optimized order list for calling MTA modules in C<Sisimai::Lhost::*>

=head1 SYNOPSIS

    use Sisimai::Order

=head1 DESCRIPTION

C<Sisimai::Order> class makes optimized order list which include MTA modules to be loaded on first
from MTA specific headers in the bounce mail headers such as C<X-Failed-Recipients:>, which MTA modules
for JSON structure.

=head1 CLASS METHODS

=head2 C<B<default()>>

C<default()> method returns a default order of MTA modules as an array reference. The default order
is defined at C<Sisimai::Lhost->index()> method.

    print for Sisimai::Order->default->@*;

=head2 C<B<another()>>

C<another()> method returns another list of MTA modules as an array reference. Another list is defined
at this class.

    print for Sisimai::Order->another->@*;

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2015-2017,2019-2024 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

