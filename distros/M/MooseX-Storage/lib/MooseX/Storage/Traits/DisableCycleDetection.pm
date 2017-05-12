package MooseX::Storage::Traits::DisableCycleDetection;
# ABSTRACT: A custom trait to bypass cycle detection

our $VERSION = '0.52';

use Moose::Role;
use namespace::autoclean;

requires 'pack';
requires 'unpack';

around 'pack' => sub {
    my ($orig, $self, %args) = @_;
    $args{engine_traits} ||= [];
    push(@{$args{engine_traits}}, 'DisableCycleDetection');
    $self->$orig(%args);
};

around 'unpack' => sub {
    my ($orig, $self, $data, %args) = @_;
    $args{engine_traits} ||= [];
    push(@{$args{engine_traits}}, 'DisableCycleDetection');
    $self->$orig($data, %args);
};

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage::Traits::DisableCycleDetection - A custom trait to bypass cycle detection

=head1 VERSION

version 0.52

=head1 SYNOPSIS

    package Double;
    use Moose;
    use MooseX::Storage;
    with Storage( traits => ['DisableCycleDetection'] );

    has 'x' => ( is => 'rw', isa => 'HashRef' );
    has 'y' => ( is => 'rw', isa => 'HashRef' );

    my $ref = {};

    my $double = Double->new( 'x' => $ref, 'y' => $ref );

    $double->pack;

=head1 DESCRIPTION

C<MooseX::Storage> implements a primitive check for circular references.
This check also triggers on simple cases as shown in the Synopsis.
Providing the C<DisableCycleDetection> traits disables checks for any cyclical
references, so if you know what you are doing, you can bypass this check.

This trait is applied to all objects that inherit from it. To use this
on a per-case basis, see C<disable_cycle_check> in L<MooseX::Storage::Basic>.

=for stopwords culted

See the SYNOPSIS for a nice example that can be easily cargo-culted.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Storage>
(or L<bug-MooseX-Storage@rt.cpan.org|mailto:bug-MooseX-Storage@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris.prather@iinteractive.com>

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
