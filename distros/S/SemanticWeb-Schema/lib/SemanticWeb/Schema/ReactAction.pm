package SemanticWeb::Schema::ReactAction;

# ABSTRACT: The act of responding instinctively and emotionally to an object

use Moo;

extends qw/ SemanticWeb::Schema::AssessAction /;


use MooX::JSON_LD 'ReactAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ReactAction - The act of responding instinctively and emotionally to an object

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

The act of responding instinctively and emotionally to an object,
expressing a sentiment.

=head1 SEE ALSO

L<SemanticWeb::Schema::AssessAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
