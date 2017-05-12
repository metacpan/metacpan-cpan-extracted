###########################################################
# SIOC::Site
# Site class for the SIOC ontology
###########################################################
#
# $Id: Site.pm 10 2008-03-01 21:38:39Z geewiz $
#

package SIOC::Site;

use strict;
use warnings;
use Carp;
use Readonly;

use version; our $VERSION = qv(1.0.0);

use Moose;
use MooseX::AttributeHelpers;

extends 'SIOC::Space';

### optional attributes

has 'administrators' => (
    metaclass => 'Collection::Array',
    is => 'rw', 
    isa => 'ArrayRef[SIOC::User]',
    default => sub { [] },
    provides => {
        'push' => 'add_administrator',
    },
);

has 'forums' => (
    metaclass => 'Collection::Array',
    is => 'rw', 
    isa => 'ArrayRef[SIOC::Forum]',
    default => sub { [] },
    provides => {
        'push' => 'add_forum',
    },
);

has 'admin_usergroup' => (
    isa => 'Str',
    is => 'rw', 
    default => sub { 'admin' },
);

### methods

after 'fill_template' => sub {
    my ($self) = @_;
    
    $self->set_template_var(forums => $self->forums);
    $self->set_template_var(admin_ug => $self->admin_usergroup);
    $self->set_template_var(administrators => $self->administrators);
};

### EOC

1;
__DATA__
__rdfoutput__
<sioc:Site rdf:about="[% url | url %]">
    <dc:title>[% name %]</dc:title>
    <dc:description>[% description %]</dc:description>
    <sioc:link rdf:resource="[% url | url %]"/>
[% FOREACH forum = forums %]
    <sioc:host_of rdf:resource="[% forum.export_url %]"/>
[% END %]
    <sioc:has_Usergroup rdf:nodeID="[% admin_ug %]"/>
</sioc:Site>

[% FOREACH forum = forums %]
<sioc:Forum rdf:about="[% forum.url | url %]">
    <sioc:link rdf:resource="[% forum.url | url %]"/>
    <rdfs:seeAlso rdf:resource="[% forum.export_url %]"/>
</sioc:Forum>
[% END %]

[% IF administrators %]
<sioc:Usergroup rdf:nodeID="[% admin_ug %]">
    <sioc:name>Administrators for "[% name %]"</sioc:name>
[% FOREACH user = administrators %]
    <sioc:has_member>
        <sioc:User rdf:about="[% user.url | url %]">
            <rdfs:seeAlso rdf:resource="[% user.export_url %]"/>
        </sioc:User>
    </sioc:has_member>
[% END %]
</sioc:Usergroup>
[% END %]
__END__
    
=head1 NAME

SIOC::Site - SIOC Site class

=head1 VERSION

This documentation refers to SIOC::Site version 1.0.0.

=head1 SYNOPSIS

   use SIOC::Site;

=head1 DESCRIPTION

A Site is the location of an online community or set of communities, with
Users in Usergroups creating content therein. While an individual Forum or
group of Forums are usually hosted on a centralised Site, in the future the
concept of a "site" may be extended (for example, a topic Thread could be
formed by Posts in a distributed Forum on a peer-to-peer environment Space).

=head1 CLASS ATTRIBUTES

=over

=item administrators 

Users who are administrators of this Site.

=item forums 

Forums that are hosted on this Site.

=back


=head1 SUBROUTINES/METHODS

=head2 add_administrator($user)

Adds a new value to the corresponding array attribute.

=head2 add_forum($forum)

Adds a new value to the corresponding array attribute.


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