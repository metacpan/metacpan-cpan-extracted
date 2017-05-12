# COPYRIGHT:
#
# Copyright 2009 REN-ISAC[1] and The Trustees of Indiana University[2]
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
#
# Author wes@barely3am.com (with the help of BestPractical.com)
#
# [1] http://www.ren-isac.net
# [2] http://www.indiana.edu

package RT::IODEF;

our $VERSION = '0.08';

use warnings;
use strict;

=head1 NAME

RT::IODEF - A perl module for translating RT tickets to IODEF messages and also maps IODEF to RT's Custom Fields based on their description tag

=head1 SYNOPSIS

  # to map the IODEF XML to a custom field, set the custom field's "description" to it's IODEF (XML::IODEF) representation of the xml path prepended with _IODEF_
  # these will be mapped when the IODEF_ProcessMessage script runs during a TicketCreate transaction
  # see lib/RT/Action/IODEF_ProcessMessage.pm

  Description       _IODEF_IncidentDescription
  Restriction:      _IODEF_Incidentrestriction
  Address:          _IODEF_IncidentEventDataFlowSystemNodeAddress
  Severity:         _IODEF_IncidentAssessmentImpactseverity
  Impact:           _IODEF_IncidentAssessmentImpact
  Service Protocol: _IODEF_IncidentEventDataFlowSystemServiceip_protocol
  Service Portlist: _IODEF_IncidentEventDataFlowSystemServicePortlist
  # and so on...

  # example taken from html/IODEF/IODEF.html
  <%INIT>
    use RT::Ticket;

    my $Ticket = RT::Ticket->new($session{'CurrentUser'});
    $Ticket->Load($ARGS{'id'});
    my $xml = $Ticket->IODEF();

    $r->content_type('application/xml');
    $xml = $xml->out();
  
    $m->out($xml);
    $m->abort();
  </%INIT>
  <%ARGS>
  $id => undef
  </%ARGS>
 
package RT::Ticket;
require XML::IODEF::Simple;

=head1 METHODS

=head2 IODEF

=cut

## TODO -- speed this up if we can
sub IODEF {
	my $self = shift;
    my $tkt = $self;
    my $inc_history = shift || 0;

	my $cfs = RT::CustomFields->new($self->CurrentUser());
	$cfs->LimitToQueue($tkt->Queue());
	$cfs->Limit(FIELD => 'Description', VALUE => '_IODEF_Incident', OPERATOR => 'LIKE');
	return(undef) unless($cfs->Count());

    my $source = $tkt->OwnerObj->EmailAddress() || $tkt->RequestorAddresses || RT->Config->Get('Organization');
    if($source =~ /,/){
        my @a = split(/,/,$source);
        $source = $a[0];
    }

    my $altid = RT->Config->Get('WebURL').'Ticket/Display.html?id='.$tkt->Id();
    my $altid_restriction = 'private';
    my $detecttime = $self->CreatedObj->AsString();

    my $group = $tkt->FirstCustomFieldValue('Constituency') || $tkt->FirstCustomFieldValue('_RTIR_Constituency');
    my @sharewith;
    my $values = $tkt->CustomFieldValues('Share With');
    my $sw = join("\n", grep { defined $_ } map { $_->Content } @{$values->ItemsArrayRef});

    if($sw){
        @sharewith = split(/\n/,$sw);
    }
    my @history;
    if($inc_history){
        my $trans = $tkt->Transactions();
        while(my $t = $trans->Next()){
            next unless($t->Type() eq 'Comment' || $t->Type() eq 'Create');
            my $user = RT::User->new($self->CurrentUser());
            $user->Load($t->Creator());
            my $role = 'cc';
            my $type = 'person';
            if($tkt->OwnerObj->EmailAddress && $user->EmailAddress()){
                $role = 'creator' if($tkt->OwnerObj->EmailAddress() eq $user->EmailAddress());
            }
            if($user->Name() && $user->Name() eq 'RT_System'){
                $role = 'irt';
                $type = 'organization';
            }
            my $content = $t->Content();
            #if($content =~ /^<\?xml version.*/){
            #    $content =~ s/\n//g;
            #}
            push(@history,{
                restriction => 'private',
                action      => 'status-new-info',
                DateTime    => $t->CreatedAsString(),
                IncidentID  => {
                    content     => RT->Config->Get('WebURL').'Ticket/Display.html?id='.$tkt->Id().'#txn-'.$t->Id(),
                    name        => RT->Config->Get('Organization'),
                    instance    => RT->Config->Get('rtname'),
                },
                Contact     => {
                    name        => $user->Name(),
                    email       => $user->EmailAddress(),
                    role        => $role,
                    type        => $type,
                },
                Description => $content,
            });
        }
        @history = reverse(@history);
    }
    my $restriction = $tkt->FirstCustomFieldValue('Restriction') || 'private';
    $restriction = 'private' unless($restriction =~ /^(default|private|need-to-know|public)$/);

    my $report = XML::IODEF::Simple->new({
        guid        => $group,
        IncidentID  => {
            restriction => 'private',
            name        => RT->Config->Get('Organization'),
            instance    => RT->Config->Get('rtname'),
            content     => RT->Config->Get('WebURL').'Ticket/Display.html?id='.$tkt->Id(),
        },
        alternativeid   => RT->Config->Get('WebURL').'Ticket/Display.html?id='.$tkt->Id(),
        alternativeid_restriction   => 'private',
        source      => $source,
        restriction => $tkt->FirstCustomFieldValue('Restriction') || 'private',
        sharewith   => \@sharewith,
        description => $tkt->FirstCustomFieldValue('ReportDescription') || $tkt->Subject(),
        impact      => $tkt->FirstCustomFieldValue('Assessment Impact'),
        address     => $tkt->FirstCustomFieldValue('Address'),
        protocol    => $tkt->FirstCustomFieldValue('Service Protocol'),
        portlist    => $tkt->FirstCustomFieldValue('Service Portlist'),
        contact     => [
            {
                name        => $tkt->OwnerObj->Name(),
                email       => $tkt->OwnerObj->EmailAddress(),
                AdditionalData  => {
                    sector  => 'education',
                },
            },
            #{
            #    ## TODO -- RESTRICTION ?
            #    name        => 'leo.ren-isac.net',
            #    email       => '',
            #    type        => 'organization',
            #    role        => 'cc',
            #    AdditionalData  => {
            #        sector  => 'leo',
            #    },
            #},
        ],
        purpose                     => $tkt->FirstCustomFieldValue('Purpose'),
        confidence                  => $tkt->FirstCustomFieldValue('Confidence'),
        #alternativeid               => $altid,
        #alternativeid_restriction   => $altid_restriction,
        history                     => \@history,
    });

	return($report);
}	
	

eval "require RT::IODEF_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/IODEF_Vendor.pm});
eval "require RT::IODEF_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/IODEF_Local.pm});

1;
