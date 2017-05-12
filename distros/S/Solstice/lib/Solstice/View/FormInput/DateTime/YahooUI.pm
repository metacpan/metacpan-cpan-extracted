package Solstice::View::FormInput::DateTime::YahooUI;

# $Id: Editor.pm 3155 2006-02-21 20:08:18Z mcrawfor $

=head1 NAME

JSCalendar::View::DateTime::Editor - A view of a Solstice DateTime obj,
showing a selection widget.

=head1 SYNOPSIS

  use JSCalendar::View::DateTime::Editor;

=head1 DESCRIPTION

This is a view of Solstice::DateTime.

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::View::FormInput::DateTime);

use Solstice::DateTime;
use Solstice::Service::YahooUI;

use constant TRUE  => 1;
use constant FALSE => 0;

our $template = 'form_input/datetime.html';

our ($VERSION) = ('$Revision: 3155 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::View::FormInput::DateTime|Solstice::View::FormInput::DateTime>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item generateParams()
         
=cut
             
sub generateParams {
    my $self = shift;
   
    my $name       = $self->getName();    
    my $format     = $self->getFormat()    || "%m/%d/%Y";
    my $start_date = $self->getStartDate();
    my $end_date;
    my $start_year = $self->getStartYear();
    my $year_count = $self->getYearCount() || 1;

    my $client_action;
    for my $action (@{$self->getClientActions()}) {
        $client_action .= $action.';';
    }
    
    if ($start_year) {
        $start_date = Solstice::DateTime->new({
                                                year    => $start_year,
                                                day     => 1,
                                                month   => 1,
                                                hour    => 0,
                                                min     => 0,
                                                sec     => 0,
                                            });
    }
    
    if (defined $start_date && $start_date->isValid()) { 
        $end_date = Solstice::DateTime->new($start_date->toSQL());
        $end_date->addYears($year_count);
    }
    
    $self->addClientAction("Solstice.YahooUI.Calendar.update('$name')");
    $self->SUPER::generateParams();
    
    my $button_id = $name . '_button';

    my $yahooui_service = Solstice::Service::YahooUI->new();
    $yahooui_service->addCalendarFiles();
   
    $self->getOnloadService()->addEvent('Solstice.YahooUI.Calendar.init("'.
        $name.'", "'.
        $button_id.'", "'.
        $format.'", '.
        (defined $start_date ? '"'.$start_date->toCommon().'"' : 'false').', '.
        (defined $end_date ? '"'.$end_date->toCommon().'"' : 'false').
        (defined $client_action ? ", function(){$client_action}" : '').
        ');'
    );
    
    # This is kinda cheesy, but it really eliminates duplicated code in
    # the template, see solstice/templates/form_input/datetime.html
    $self->setParam('calendar', '<a href="javascript: void(0);" onclick="Solstice.YahooUI.Calendar.show(\''.$button_id.'\');">
        <img src="./images/calendar.gif"></a>'."<div id='$button_id'></div>");
   
    return TRUE; 
}


1;

__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3155 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
