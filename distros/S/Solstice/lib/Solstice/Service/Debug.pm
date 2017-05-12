package Solstice::Service::Debug;

# $Id: YahooUI.pm 3364 2006-05-05 07:18:21Z pmichaud $

=head1 NAME

Solstice::Service::Debug - A service for managing debug levels

=head1 SYNOPSIS

    #adding debug messages in your application, in any Solstice subclass:
    $self->debug('tag', 'Message');
    #for example
    $self->debug('grading', 'grade set to 0 because of missing answer.');
    


    #To see debug messages:
    #in an application config:
    <url ...
        debug_level="grading storage"
    />

    #this will cause all debug messages tagged as "grading" or "storage" to be shown at this particular url

    #in the Solstice config:
    <debug_level>scam lifecycle</debug_level>

    #this will cause all debug messages tagged as "scam" or "lifecycle" to be shown for all urls





=head1 DESCRIPTION

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Service);

use constant TRUE => 1;
use constant FALSE => 0;

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
    my $tags = shift;
    my $self = $obj->SUPER::new(@_);

    if($tags){
        for my $tag (split(/,|\s+/, $tags)){
            $tag =~ s/^\s*//;
            $tag =~ s/\s*$//;
            $self->set($tag, TRUE);
        }
    }

    return $self;
}


sub debug {
    my ($self, $tag, $mesg, $package, $line) = @_;
    if($self->get($tag) || $self->get('all')){
        $mesg =~ s/^\s*//;
        $mesg =~ s/\s*$//;
        $mesg .= " at $package line $line\n";
        warn $mesg;
    }
    return TRUE;
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
