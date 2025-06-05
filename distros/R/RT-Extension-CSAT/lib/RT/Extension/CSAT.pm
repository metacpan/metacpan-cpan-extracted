package RT::Extension::CSAT;

use strict;
use warnings;
use 5.10.1;

our $VERSION = '0.03';

=encoding utf8

=head1 NAME

RT::Extension::CSAT - Customer Satisfaction Feedback extension for Request Tracker

=head1 VERSION

version 0.03

=head1 AUTHOR

Jan Okrouhly <jan.okrouhly@xconsulting.cz>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DESCRIPTION

This is a simple RT (Request Tracker) extension to collect Customer Satisfaction (CSAT) feedback
via tokenized links in resolution emails. It uses RT's NoAuth interface to collect score and optional comment.

=head1 INSTALLATION

=over 4

=item 1. Extract the extension archive:

    tar xzf RT-Extension-CSAT.tar.gz
    cd RT-Extension-CSAT

=item 2. Install the extension:

    perl Makefile.PL
    make
    make install

=item 3. Configure RT to use the extension by editing your RT_SiteConfig.pm:

    Plugin('RT::Extension::CSAT');
    Set($CustomerSatisfactionSecret, 'mysupersecretvalue'); # Secret used to generate auth hash

=item 4. Create two Ticket custom fields in RT:

    - CSAT Score (Select one value 1 - 5)
    - CSAT Comment (Free text)

    Apply both of them globaly to all ticket queues and adjust any group or user rights to view their future content

=item 5. Update your RT resolution template to include links like:

    <a href="https://your.rt.url/NoAuth/CSAT?ticket=123&score=5&auth=...">Give Feedback</a>

   Generate the auth hash using:
       Digest::SHA::hmac_sha256_hex($ticket_id . $created_datetime . $score, $CustomerSatisfactionSecret)

=item 6. Restart your RT server.


=back

=head1 EXAMPLE

Example of Resolution template (change @icons with your preferred Emoji):

    Subject: Resolved: {$Ticket->Subject}
    Content-Type: text/html

    <p>Hello,<br><p>

    <p>your ticket has been resolved. If you still have some questions or complaints, simply reply on this email message.<p>

    <p>Please rate the ticket resolution, it will help us improve.<br>
    {
      use utf8;
      my $ticket_id = $Ticket->Id;
      my $created   = $Ticket->CreatedObj->ISO;
      my $secret    = $RT::CustomerSatisfactionSecret || 'mysupersecretvalue';
      use Digest::SHA qw(hmac_sha256_hex);

      my $base_url = RT->Config->Get("WebURL") . 'NoAuth/CSAT';

      my @icons = (
        [1, '🌑🌑🌑🌑⭐', 'Very Dissatisfied'],
        [2, '🌑🌑🌑⭐⭐' , 'Dissatisfied'],
        [3, '🌑🌑⭐⭐⭐' , 'Neutral'],
        [4, '🌑⭐⭐⭐⭐' , 'Satisfied'],
        [5, '⭐⭐⭐⭐⭐' , 'Very Satisfied'],
      );

      my $links = join(" ", map {
        my ($score, $icon, $rate) = @$_;
        my $auth = hmac_sha256_hex($ticket_id . $created . $score, $secret);
        my $url  = "$base_url?ticket=$ticket_id&score=$score&auth=$auth";
        qq{<a href="$url" title="$rate">$icon</a>&nbsp;<a href="$url" title="$rate">$rate</a><br>}
      } reverse @icons);

      return $links;

     }
</p><p>
Thank You,<br>
Support Team

</p>


=cut

1;
