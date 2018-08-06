package SemanticWeb::Schema::PerformAction;

# ABSTRACT: The act of participating in performance arts.

use Moo;

extends qw/ SemanticWeb::Schema::PlayAction /;


use MooX::JSON_LD 'PerformAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has entertainment_business => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'entertainmentBusiness',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PerformAction - The act of participating in performance arts.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

The act of participating in performance arts.

=head1 ATTRIBUTES

=head2 C<entertainment_business>

C<entertainmentBusiness>

A sub property of location. The entertainment business where the action
occurred.

A entertainment_business should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::EntertainmentBusiness']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::PlayAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
