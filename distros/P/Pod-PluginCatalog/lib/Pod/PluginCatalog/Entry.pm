#---------------------------------------------------------------------
package Pod::PluginCatalog::Entry;
#
# Copyright 2012 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 20 Jul 2012
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: An entry in a PluginCatalog
#---------------------------------------------------------------------

use 5.010;
use Moose;

our $VERSION = '0.02'; #VERSION
# This file is part of Pod-PluginCatalog 0.02 (January 3, 2015)

#=====================================================================


has name => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has module => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has description => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has author => (
  is       => 'ro',
  isa      => 'Str',
);

has source_file => (
  is       => 'ro',
  isa      => 'Str',
);

has _tags => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
  traits  => ['Hash'],
  handles => {
    has_tag => 'exists',
    tags    => 'keys',
  },
);


sub other_tags
{
  my ($self, $tag) = @_;

  grep { $_ ne $tag } sort $self->tags;
} # end other_tags

#---------------------------------------------------------------------
sub BUILD
{
  my ($self, $args) = @_;

  my $tags = $self->_tags;

  confess 'tags is required' unless ref $args->{tags} and @{ $args->{tags} };

  $tags->{$_} = undef for @{ $args->{tags} };
} # end BUILD

#=====================================================================
# Package Return Value:

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Pod::PluginCatalog::Entry - An entry in a PluginCatalog

=head1 VERSION

This document describes version 0.02 of
Pod::PluginCatalog::Entry, released January 3, 2015
as part of Pod-PluginCatalog version 0.02.

=head1 DESCRIPTION

This class represents a plugin in a L<Pod::PluginCatalog>.

=for Pod::Coverage
BUILD

=head1 ATTRIBUTES

=head2 author

The plugin author's CPAN ID (optional)


=head2 description

The plugin's description (required, but could be the empty string)


=head2 module

The plugin's module (a.k.a. package) name (required)


=head2 name

The plugin name (required)


=head2 tags

The list of tags for this plugin (required).
Note: when setting this, you pass an arrayref, but when reading it,
you get a list.

=head1 METHODS

=head2 other_tags

  @tags = $entry->other_tags($current_tag);

This is just a shortcut for

  @tags = grep { $_ ne $current_tag } $entry->tags;

=head1 CONFIGURATION AND ENVIRONMENT

Pod::PluginCatalog::Entry requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Pod-PluginCatalog AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Pod-PluginCatalog >>.

You can follow or contribute to Pod-PluginCatalog's development at
L<< https://github.com/madsen/pod-plugincatalog >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
