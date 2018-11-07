use utf8;

package SemanticWeb::Schema::AchieveAction;

# ABSTRACT: The act of accomplishing something via previous efforts

use Moo;

extends qw/ SemanticWeb::Schema::Action /;


use MooX::JSON_LD 'AchieveAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::AchieveAction - The act of accomplishing something via previous efforts

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

The act of accomplishing something via previous efforts. It is an
instantaneous action rather than an ongoing process.

=head1 SEE ALSO

L<SemanticWeb::Schema::Action>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
