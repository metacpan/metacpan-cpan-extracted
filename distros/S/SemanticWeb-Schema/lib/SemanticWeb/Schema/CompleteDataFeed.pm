use utf8;

package SemanticWeb::Schema::CompleteDataFeed;

# ABSTRACT: A CompleteDataFeed is a DataFeed whose standard representation includes content for every item currently in the feed

use Moo;

extends qw/ SemanticWeb::Schema::DataFeed /;


use MooX::JSON_LD 'CompleteDataFeed';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v4.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CompleteDataFeed - A CompleteDataFeed is a DataFeed whose standard representation includes content for every item currently in the feed

=head1 VERSION

version v4.0.1

=head1 DESCRIPTION

=for html <p>A <a class="localLink"
href="http://schema.org/CompleteDataFeed">CompleteDataFeed</a> is a <a
class="localLink" href="http://schema.org/DataFeed">DataFeed</a> whose
standard representation includes content for every item currently in the
feed.<br/><br/> This is the equivalent of Atom's element as defined in Feed
Paging and Archiving <a href="https://tools.ietf.org/html/rfc5005">RFC
5005</a>, For example (and as defined for Atom), when using data from a
feed that represents a collection of items that varies over time (e.g. "Top
Twenty Records") there is no need to have newer entries mixed in alongside
older, obsolete entries. By marking this feed as a CompleteDataFeed, old
entries can be safely discarded when the feed is refreshed, since we can
assume the feed has provided descriptions for all current items.<p>

=head1 SEE ALSO

L<SemanticWeb::Schema::DataFeed>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
