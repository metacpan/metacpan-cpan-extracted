use utf8;

package SemanticWeb::Schema::EndorsementRating;

# ABSTRACT: An EndorsementRating is a rating that expresses some level of endorsement

use Moo;

extends qw/ SemanticWeb::Schema::Rating /;


use MooX::JSON_LD 'EndorsementRating';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EndorsementRating - An EndorsementRating is a rating that expresses some level of endorsement

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html An EndorsementRating is a rating that expresses some level of endorsement,
for example inclusion in a "critic's pick" blog, a "Like" or "+1" on a
social network. It can be considered the <a class="localLink"
href="http://schema.org/result">result</a> of an <a class="localLink"
href="http://schema.org/EndorseAction">EndorseAction</a> in which the <a
class="localLink" href="http://schema.org/object">object</a> of the action
is rated positively by some <a class="localLink"
href="http://schema.org/agent">agent</a>. As is common elsewhere in
schema.org, it is sometimes more useful to describe the results of such an
action without explicitly describing the <a class="localLink"
href="http://schema.org/Action">Action</a>.<br/><br/> An <a
class="localLink"
href="http://schema.org/EndorsementRating">EndorsementRating</a> may be
part of a numeric scale or organized system, but this is not required:
having an explicit type for indicating a positive, endorsement rating is
particularly useful in the absence of numeric scales as it helps consumers
understand that the rating is broadly positive.

=head1 SEE ALSO

L<SemanticWeb::Schema::Rating>

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
