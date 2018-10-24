use utf8;

package SemanticWeb::Schema::EndorseAction;

# ABSTRACT: An agent approves/certifies/likes/supports/sanction an object.

use Moo;

extends qw/ SemanticWeb::Schema::ReactAction /;


use MooX::JSON_LD 'EndorseAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has endorsee => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'endorsee',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EndorseAction - An agent approves/certifies/likes/supports/sanction an object.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

An agent approves/certifies/likes/supports/sanction an object.

=head1 ATTRIBUTES

=head2 C<endorsee>

A sub property of participant. The person/organization being supported.

A endorsee should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::ReactAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
