###########################################################
# SIOC::Thread
# Thread class for the SIOC ontology
###########################################################
#
# $Id: Thread.pm 10 2008-03-01 21:38:39Z geewiz $
#

package SIOC::Thread;

use strict;
use warnings;

use version; our $VERSION = qv(1.0.0);

use Moose;

extends 'SIOC::Container';

### required attributes

has 'page' => (
    isa => 'Num',
    is => 'ro',
    required => 1,
    );

### methods

after 'fill_template' => sub {
    my ($self) = @_;
    
    $self->set_template_var(page => $self->page);
};

1;
__DATA__
__rdfoutput__
<sioc:Thread rdf:about="[% url | url %]">
    <sioc:link rdf:resource="[% url | url %]"/>
[% IF views %]
    <sioc:num_views>[% views %]</sioc:num_views>
[% END %]
[% IF note %]
    <rdfs:comment>[% note %]</rdfs:comment>
[% END %]
[% FOREACH topic = topics %]
    <sioc:topic>[% topic %]</sioc:topic>
[% END %]
[% FOREACH post = items %]
    <sioc:container_of>
        <sioc:Post rdf:about="[% post.url | url %]">
            <rdfs:seeAlso rdf:resource="[% siocURL('post', post.id) %]"/>
[% IF post.prev_by_date %]
		    <sioc:previous_by_date rdf:resource="[% post.prev_by_date | url %]"/>
[% END %]
[% IF post.next_by_date %]
		    <sioc:next_by_date rdf:resource="[% post.next_by_date | url %]"/>
[% END %]
        </sioc:Post>
    </sioc:container_of>
[% END %]
[% IF next %]
    <rdfs:seeAlso rdf:resource="[% siocURL('thread', id, page+1) %]"/>
[% END %]
</sioc:Thread>
__END__
    
=head1 NAME

SIOC::Thread -- SIOC Thread class

=head1 VERSION

This documentation refers to SIOC::Thread version 1.0.0.

=head1 SYNOPSIS

   use SIOC::Thread;

=head1 DESCRIPTION

Mailing lists, forums and blogs on community sites usually employ some
threaded discussion methods, whereby discussions are initialised by a certain
user and replied to by others. The Thread container is used to group Posts
from a single discussion thread together via the sioc:container_of property,
especially where a sioc:has_reply / reply_of structure is absent.


=head1 SUBROUTINES/METHODS

TODO: document methods


=head1 DIAGNOSTICS

For diagnostics information, see the SIOC base class.


=head1 CONFIGURATION AND ENVIRONMENT

This module doesn't need configuration.


=head1 DEPENDENCIES

This module depends on the following modules:

=over

=item *

Moose -- OOP framework (CPAN)

=item *

SIOC -- SIOC abstract base class (part of this module's distribution)

=back

=head1 INCOMPATIBILITIES

There are no known incompatibilities.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems via the bug tracking system on the perl-SIOC project
website: L<http://developer.berlios.de/projects/perl-sioc/>.

Patches are welcome.

=head1 AUTHOR

Jochen Lillich <geewiz@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Jochen Lillich <geewiz@cpan.org>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * The names of its contributors may not be used to endorse or promote
      products derived from this software without specific prior written
      permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.