package Solstice::SearchField;

# $Id:$

=head1 NAME

Solstice::SearchField - Represents one field a model defines in the search index.

=head1 SYNOPSIS

#within a model's store method, for example:

my $content_field = $self->createSearchField('content', $self->getContent());

$content_field->setStored(0);
$content_field->setCompressed(1);

=head1 DESCRIPTION

This allows for the creation of a searched bit of content.  The bit of content can then
have various options set about it's behavior in the index.

=over 4

=cut


use strict;
use warnings;
use 5.006_000;

use base qw(Solstice);

=item new

=cut

sub new {
    my $pkg = shift;
    my $name = shift;
    my $content = shift;
    my $self = $pkg->SUPER::new();

    return unless $name;
    $content = '' unless $content;

    $self->{'options'} = {};
    $self->{'options'}{'name'} = $name;
    $self->{'content'} = $content;

    return $self;
}

=item getName

=cut

sub getName {
    my $self = shift;
    return $self->{'options'}{'name'};
}

=item getContent

=cut

sub getContent {
    my $self = shift;
    return $self->{'content'};
}

=item getOptions

Retuns a hash of the options you have set - this is for backend use mostly.

=cut

sub getOptions {
    my $self = shift;
    return %{$self->{'options'}};
}

=item setWeight

Set the relevance multiplier for matches in this field

=cut

sub setWeight {
    my $self = shift;
    my $weight = shift;

    die "Non positive multiplier passed to Solstice::SearchField::setWeight from ".join(' ', caller) unless $self->isValidPositiveNumber($weight);

    $self->{'boost'} = $weight;
}

=item setIndexed

Do we search it or just store it with the record?

=cut

sub setIndexed {
    my $self = shift;
    $self->{'options'}{'indexed'} = shift;
}

=item setAnalyzed

Is the field stemmed/stopworded/etc

=cut

sub setAnalyzed {
    my $self = shift;
    $self->{'options'}{'analyzed'} = shift;
}

=item setStored

Is the field stored or just indexed

=cut

sub setStored {
    my $self = shift;
    $self->{'options'}{'stored'} = shift;
}

=item setCompressed

Should the stored content be gzipped

=cut

sub setCompressed {
    my $self = shift;
    $self->{'options'}{'compressed'} = shift;
}

=item setVectorized

Should vector data be generated and stored, so matches can be highlighted in excerpts while searching

=cut

sub setVectorized {
    my $self = shift;
    $self->{'options'}{'vectorized'} = shift;
}


1;

=back

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
