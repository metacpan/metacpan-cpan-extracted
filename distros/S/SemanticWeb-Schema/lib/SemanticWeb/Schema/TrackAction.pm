use utf8;

package SemanticWeb::Schema::TrackAction;

# ABSTRACT: An agent tracks an object for updates

use Moo;

extends qw/ SemanticWeb::Schema::FindAction /;


use MooX::JSON_LD 'TrackAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has delivery_method => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'deliveryMethod',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TrackAction - An agent tracks an object for updates

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

=for html An agent tracks an object for updates.<br/><br/> Related actions:<br/><br/>
<ul> <li><a class="localLink"
href="http://schema.org/FollowAction">FollowAction</a>: Unlike
FollowAction, TrackAction refers to the interest on the location of
innanimates objects.</li> <li><a class="localLink"
href="http://schema.org/SubscribeAction">SubscribeAction</a>: Unlike
SubscribeAction, TrackAction refers to the interest on the location of
innanimate objects.</li> </ul> 

=head1 ATTRIBUTES

=head2 C<delivery_method>

C<deliveryMethod>

A sub property of instrument. The method of delivery.

A delivery_method should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DeliveryMethod']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::FindAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
