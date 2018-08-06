package SemanticWeb::Schema::ComputerLanguage;

# ABSTRACT: This type covers computer programming languages such as Scheme and Lisp

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'ComputerLanguage';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ComputerLanguage - This type covers computer programming languages such as Scheme and Lisp

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html This type covers computer programming languages such as Scheme and Lisp, as
well as other language-like computer representations. Natural languages are
best represented with the <a class="localLink"
href="http://schema.org/Language">Language</a> type.

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
