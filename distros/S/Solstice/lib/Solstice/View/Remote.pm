package Solstice::View::Remote;

=head1 NAME

Solstice::View::Remote - View of the XML response to AJAX calls.

=over 4

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::View);

use constant TRUE  => 1;
use constant FALSE => 0;

sub new {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_);
    
    $self->_setTemplate('boilerplate/remote.xml');
    $self->_setTemplatePath('templates');

    return $self;
}

sub setActions {
    my $self = shift;
    $self->{'_actions'} = shift;
}

sub getActions {
    my $self = shift;
    return $self->{'_actions'};
}

=item generateParams()

=cut

sub generateParams {
    my $self = shift;

    for my $action ( @{$self->getActions()} ){
        $self->addParam('actions', {
            type     => $action->{'type'},
            content  => $action->{'content'},
            block_id => $action->{'block_id'} ? $action->{'block_id'} : undef,
        });
    
        next if $action->{'type'} eq 'action';

        # Inline javascript must be pulled out for execution
        $self->addScriptParams($action->{'content'});
    }

    # Accumulated onload events must be executed
    for my $event ( @{$self->getOnloadService()->getEvents()} ){
        $self->addParam('actions', {
            type    => 'action',
            content => $event.';',
        });
    }

    return TRUE;
}

=item addScriptParams($str)

=cut

sub addScriptParams {
    my $self = shift;
    my $string = shift;
    return unless $string;

    my $parser = HTML::Parser->new(
        report_tags   => [qw(script)],
        unbroken_text => TRUE,
        start_h       => [sub {
            my $s = shift;
            $s->handler(text => [], '@{dtext}');
        }, 'self'],
        end_h         => [sub {
            my $s = shift;
            $self->addParam('actions', {
                type    => 'action',
                content => $s->handler('text')->[0],
            });
            #warn join("", @{$s->handler('text')});
            $s->handler(text => undef);
        }, 'self'],
    );
    $parser->parse($string);
    $parser->eof();
    return;
}


1;


=back 

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
