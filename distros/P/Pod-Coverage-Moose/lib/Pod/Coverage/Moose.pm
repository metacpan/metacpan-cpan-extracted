package Pod::Coverage::Moose; # git description: v0.07-13-g19d14b4
# ABSTRACT: Pod::Coverage extension for Moose
# KEYWORDS: pod coverage verification validity tests documentation completeness moose methods inheritance
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.08';

use Moose;

use Pod::Coverage;
use Carp            qw( croak );
use Class::Load qw( load_class );

use namespace::autoclean;


#pod =head1 SYNOPSIS
#pod
#pod   use Pod::Coverage::Moose;
#pod
#pod   my $pcm = Pod::Coverage::Moose->new(package => 'MoosePackage');
#pod   print 'Coverage: ', $pcm->coverage, "\n";
#pod
#pod =head1 DESCRIPTION
#pod
#pod When using L<Pod::Coverage> in combination with L<Moose>, it will
#pod report any method imported from a L<role|Moose::Role>. This is especially bad when
#pod used in combination with L<Test::Pod::Coverage>, since it takes away
#pod its ease of use.
#pod
#pod To use this module in combination with L<Test::Pod::Coverage>, use
#pod something like this:
#pod
#pod   use Test::Pod::Coverage;
#pod   all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::Moose'});
#pod
#pod =head1 ATTRIBUTES
#pod
#pod =head2 package
#pod
#pod This is the package used for inspection.
#pod
#pod =cut

has package => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

#pod =head2 cover_requires
#pod
#pod Boolean flag to indicate that C<requires $method> declarations in a Role should be trusted.
#pod
#pod =cut

has cover_requires => (
    is          => 'ro',
    isa         => 'Bool',
    default => 0,
);

#
#   original pod_coverage object
#

has _pod_coverage => (
    is          => 'rw',
    isa         => 'Pod::Coverage',
    handles     => [qw( coverage why_unrated naked uncovered covered )],
);

#pod =head1 METHODS
#pod
#pod =head2 meta
#pod
#pod L<Moose> meta object.
#pod
#pod =head2 BUILD
#pod
#pod =for stopwords initialises
#pod
#pod Initialises the internal L<Pod::Coverage> object. It uses the meta object
#pod to find all methods and attribute methods imported via roles.
#pod
#pod =cut

my %is = map { $_ => 1 } qw( rw ro wo );
sub BUILD {
    my ($self, $args) = @_;

    my $meta    = $self->package->meta;
    my @trustme = @{ $args->{trustme} || [] };

    push @trustme, qr/^meta$/;
    push @trustme,                                          # MooseX-AttributeHelpers hack
        map  { qr/^$_$/ }
        map  { $_->name }
        grep { $_->isa('MooseX::AttributeHelpers::Meta::Method::Provided') }
        $meta->get_all_methods
            unless $meta->isa('Moose::Meta::Role');
    push @trustme,
        map { qr/^\Q$_\E$/ }                                # turn value into a regex
        map {                                               # iterate over all roles of the class
            my $role = $_;
            $role->get_method_list,
            ($self->cover_requires ? ($role->get_required_method_list) : ()),
            map {                                           # iterate over attributes
                my $attr = $role->get_attribute($_);
                ($attr->{is} && $is{$attr->{is}} ? $_ : ()),  # accessors
                grep defined, map { $attr->{ $_ } }                             # other attribute methods
                    qw( clearer predicate reader writer accessor );
            } $role->get_attribute_list,
        }
        $meta->calculate_all_roles;

    $args->{trustme} = \@trustme;

    $self->_pod_coverage(Pod::Coverage->new(%$args));
}

#pod =head1 DELEGATED METHODS
#pod
#pod Delegated to the traditional L<Pod::Coverage> object are:
#pod
#pod =head2 coverage
#pod
#pod =head2 covered
#pod
#pod =head2 naked
#pod
#pod =head2 uncovered
#pod
#pod =head2 why_unrated
#pod
#pod =head1 EXTENDED METHODS
#pod
#pod =head2 new
#pod
#pod The constructor will only return a C<Pod::Coverage::Moose> object if it
#pod is invoked on a class that C<can> a C<meta> method. Otherwise, a
#pod traditional L<Pod::Coverage> object will be returned. This is done so you
#pod don't get in trouble for mixing L<Moose> with non Moose classes in your
#pod project.
#pod
#pod =cut

around new => sub {
    my $next = shift;
    my ($self, @args) = @_;

    my %args  = (@args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args);
    my $class = $args{package}
        or croak 'You need to specify a package in the constructor arguments';

    load_class($class);
    return Pod::Coverage->new(%args) unless $class->can('meta');

    return $self->$next(@args);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::Moose - Pod::Coverage extension for Moose

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  use Pod::Coverage::Moose;

  my $pcm = Pod::Coverage::Moose->new(package => 'MoosePackage');
  print 'Coverage: ', $pcm->coverage, "\n";

=head1 DESCRIPTION

When using L<Pod::Coverage> in combination with L<Moose>, it will
report any method imported from a L<role|Moose::Role>. This is especially bad when
used in combination with L<Test::Pod::Coverage>, since it takes away
its ease of use.

To use this module in combination with L<Test::Pod::Coverage>, use
something like this:

  use Test::Pod::Coverage;
  all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::Moose'});

=head1 ATTRIBUTES

=head2 package

This is the package used for inspection.

=head2 cover_requires

Boolean flag to indicate that C<requires $method> declarations in a Role should be trusted.

=head1 METHODS

=head2 meta

L<Moose> meta object.

=head2 BUILD

=for stopwords initialises

Initialises the internal L<Pod::Coverage> object. It uses the meta object
to find all methods and attribute methods imported via roles.

=head1 DELEGATED METHODS

Delegated to the traditional L<Pod::Coverage> object are:

=head2 coverage

=head2 covered

=head2 naked

=head2 uncovered

=head2 why_unrated

=head1 EXTENDED METHODS

=head2 new

The constructor will only return a C<Pod::Coverage::Moose> object if it
is invoked on a class that C<can> a C<meta> method. Otherwise, a
traditional L<Pod::Coverage> object will be returned. This is done so you
don't get in trouble for mixing L<Moose> with non Moose classes in your
project.

=head1 SEE ALSO

=over 4

=item *

L<Moose>

=item *

L<Pod::Coverage>,

=item *

L<Test::Pod::Coverage>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Coverage-Moose>
(or L<bug-Pod-Coverage-Moose@rt.cpan.org|mailto:bug-Pod-Coverage-Moose@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Robert 'phaylon' Sedlacek <rs@474.at>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Vyacheslav Matyukhin Dave Rolsky

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Vyacheslav Matyukhin <me@berekuk.ru>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Robert 'phaylon' Sedlacek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
