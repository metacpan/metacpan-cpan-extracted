package Solstice::Service::YahooUI;

# $Id: YahooUI.pm 3364 2006-05-05 07:18:21Z pmichaud $

=head1 NAME

Solstice::Service::YahooUI - A service for managing Yahoo UI javascript files.

=head1 SYNOPSIS

  my $service = Solstice::Service::YahooUI->new();

=head1 DESCRIPTION

This will load Yahoo UI javascript files.  This should probably expand in scope further down the road, right now initializing will load drag and drop, animation, and logging.

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Service);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new()

Creates a new YahooUI service object, and includes a collection of javascript files.

=cut

sub new {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_);

    my $include_serivce = $self->getIncludeService();

    #bring in the essential yui files
    $self->getIncludeService()->addIncludedFile({
            file    => 'javascript/yui/build/animation/animation-min.js',
            type    => 'text/javascript'
        });
    $self->getIncludeService()->addIncludedFile({
            file    => 'javascript/yui/build/dragdrop/dragdrop-min.js',
            type    => 'text/javascript'
        });
    $self->getIncludeService()->addIncludedFile({
            file    => 'javascript/yui/build/logger/logger-min.js',
            type    => 'text/javascript'
        });
    $self->getIncludeService()->addIncludedFile({
            file    => 'javascript/yui/build/logger/assets/logger.css',
            type    => 'text/css'
        });

    return $self;
}

sub addFlyoutMenuFiles {
    my $self = shift;

    my $include_serivce = $self->getIncludeService();

    $self->getIncludeService()->addIncludedFile({
            file    => 'javascript/yui/build/container/container_core-min.js',
            type    => 'text/javascript'
        });

    $self->getIncludeService()->addIncludedFile({
            file    => 'javascript/yui/build/menu/menu-min.js',
            type    => 'text/javascript'
        });

}

sub addCalendarFiles {
    my $self = shift;
    my $include_serivce = $self->getIncludeService();

    $self->getIncludeService()->addIncludedFile({
            file    => 'javascript/yui/build/calendar/calendar.js',
            type    => 'text/javascript'
        });

     $self->getIncludeService()->addIncludedFile({
            file    => 'styles/yui_calendar.css',
            type    => 'text/css'
        });

}

1;

__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $

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
