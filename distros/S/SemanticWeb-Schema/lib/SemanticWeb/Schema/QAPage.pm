use utf8;

package SemanticWeb::Schema::QAPage;

# ABSTRACT: A QAPage is a WebPage focussed on a specific Question and its Answer(s)

use Moo;

extends qw/ SemanticWeb::Schema::WebPage /;


use MooX::JSON_LD 'QAPage';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::QAPage - A QAPage is a WebPage focussed on a specific Question and its Answer(s)

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A QAPage is a WebPage focussed on a specific Question and its Answer(s),
e.g. in a question answering site or documenting Frequently Asked Questions
(FAQs).

=head1 SEE ALSO

L<SemanticWeb::Schema::WebPage>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
