use utf8;

package SemanticWeb::Schema::ReceiveAction;

# ABSTRACT: The act of physically/electronically taking delivery of an object thathas been transferred from an origin to a destination

use Moo;

extends qw/ SemanticWeb::Schema::TransferAction /;


use MooX::JSON_LD 'ReceiveAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has delivery_method => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'deliveryMethod',
);



has sender => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'sender',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ReceiveAction - The act of physically/electronically taking delivery of an object thathas been transferred from an origin to a destination

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html The act of physically/electronically taking delivery of an object thathas
been transferred from an origin to a destination. Reciprocal of
SendAction.<br/><br/> Related actions:<br/><br/> <ul> <li><a
class="localLink" href="http://schema.org/SendAction">SendAction</a>: The
reciprocal of ReceiveAction.</li> <li><a class="localLink"
href="http://schema.org/TakeAction">TakeAction</a>: Unlike TakeAction,
ReceiveAction does not imply that the ownership has been transfered (e.g. I
can receive a package, but it does not mean the package is now mine).</li>
</ul> 

=head1 ATTRIBUTES

=head2 C<delivery_method>

C<deliveryMethod>

A sub property of instrument. The method of delivery.

A delivery_method should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DeliveryMethod']>

=back

=head2 C<sender>

A sub property of participant. The participant who is at the sending end of
the action.

A sender should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Audience']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::TransferAction>

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
