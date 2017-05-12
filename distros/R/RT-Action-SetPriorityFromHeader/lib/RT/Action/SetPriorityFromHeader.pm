package RT::Action::SetPriorityFromHeader;

our $VERSION = '0.01';

use warnings;
use strict;

use base qw(RT::Action);

sub Prepare { 
    my $self = shift;

    my $attach = $self->TransactionObj->Attachments->First;
    unless ($attach) {
        RT->Logger->debug("No message found to set priority from");
        return 0;
    }

    my $map = RT->Config->Get('PriorityMap') || {};
    my $header = RT->Config->Get('PriorityHeader') || 'X-Priority';
    my $priority = $attach->GetHeader( $header );

    if (not defined $priority) {
        RT->Logger->debug("No '$header' found, not setting priority");
        return 0;
    }

    $priority =~ s/(?:^\s*|\s*$)//g;

    unless (exists $map->{$priority}) {
        RT->Logger->debug("No priority mapping found for '$priority'");
        return 0;
    }

    $self->{'set_priority'} = $map->{$priority};

    return 1;
}

sub Commit  {
    my $self = shift;
    my $priority = $self->{'set_priority'};

    my ($ok, $msg) = $self->TicketObj->SetPriority( $priority );
    unless ($ok) {
        RT->Logger->error("Unable to set ticket priority to '$priority': $msg");
        return 0;
    }

    RT->Logger->debug("Set ticket priority to '$priority'");
    return 1;

}

=head1 NAME

RT::Action::SetPriorityFromHeader - Set ticket priority from an email header of your choosing

=head1 INSTALLATION 

=over

=item perl Makefile.PL

=item make

=item make install

May need root permissions

=item make initdb

Only run the first time you install this action.

=item Edit your /opt/rt4/etc/RT_SiteConfig.pm

Add this line:

    Set(@Plugins, qw(RT::Action::SetPriorityFromHeader));

or add C<RT::Extension::SetPriorityFromHeader> to your existing C<@Plugins> line.

You also need to configure the email header to use and a mapping from the email
header values to RT priority values.

    Set($PriorityHeader, 'X-Priority');
    Set(%PriorityMap, highest => 1, high => 2, normal => 3, low => 4, lowest => 5);
    # With the above, a header like "X-Priority: high" would set the RT ticket priority to 2

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Thomas Sibley <trs@bestpractical.com>

=head1 LICENCE AND COPYRIGHT

This software is copyright (c) 2011 by Best Practical Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;
