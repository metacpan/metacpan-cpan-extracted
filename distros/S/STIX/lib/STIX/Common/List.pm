package STIX::Common::List;

use 5.016000;
use strict;
use warnings;
use utf8;

use overload '@{}' => \&to_array, fallback => 1;

sub new {
    my $collection = CORE::shift;
    bless({collections => [@_]}, $collection);
}

sub each {

    my ($self, $callback) = @_;

    return @{$self} unless $callback;

    my $idx = 0;
    $_->$callback($idx++) for @{$self};

    return $self;

}

sub grep {
    my ($self, $callback) = @_;
    return $self->new(CORE::grep { $_->$callback(@_) } @{$self});
}

sub map {
    my ($self, $callback) = @_;
    return $self->new(CORE::map { $_->$callback(@_) } @{$self});
}

sub size { CORE::scalar @{$_[0]->{collections}} }

sub get { $_[0]->{collections}->[$_[1]] }

sub set { $_[0]->{collections}->[$_[1]] = $_[2] }

sub clear { @{$_[0]->{collections}} = () }

sub pop { CORE::pop @{$_[0]->{collections}} }

sub push { CORE::push @{$_[0]->{collections}}, @_[1 .. $#_] }

sub shift { CORE::shift @{$_[0]->{collections}} }

sub unshift { CORE::unshift @{$_[0]->{collections}}, @_[1 .. $#_] }

sub join { CORE::join($_[1] // '', @{$_[0]}) }

sub first { $_[0]->{collections}[0] }

sub last { $_[0]->{collections}[-1] }

sub to_array { [@{$_[0]->{collections}}] }

sub TO_JSON { [@{$_[0]->{collections}}] }

1;

__END__

=encoding utf-8

=head1 NAME

STIX::Common::List - Collection utility

=head1 SYNOPSIS

    use STIX::Common::List;
    my $collection = STIX::Common::List->new( qw[foo bar baz] );


=head1 DESCRIPTION

L<STIX::Common::List> is a collection utility.


=head2 METHODS

=over

=item STIX::Common::List->new( ARRAY )

Create a new collection.

    my $c = STIX::Common::List->new( [foo bar baz] );

=item $c->add

Alias for L</"push">.

=item $c->each

Evaluate callback for each element in collection.

    foreach my $item ($c->each) {
        [...]
    }

    my $collection = $c->each(sub {...});

    $c->each(sub {
        my ($value, $idx) = @_;
        [...]
    });

=item $c->clear

Reset the collection.

=item $c->first

Get the first element of collection.

=item $c->get

Get item from N index position.

    my $item = $c->get(5);

=item $c->grep

Filter items.

    my $filtered = $c->grep(sub { $_ eq 'foo' });

=item $c->push

Add a new item in collection.

    $c->push('foo');
    $c->push(sub {...});

=item $c->join

Join elements in collection.

    $c->join(', ');

=item $c->last

Get the last element of collection.

=item $c->map

Evaluate the callback and create a new collection.

    STIX::Common::List->new(1,2,3)->map(sub { $_ * 2 });

=item $c->pop

Remove and return the last element of collection.

    my $item = $c->pop;

=item $c->push

Add one or more elements in collection.

    $c->push('foo', 'bar', 'baz');

=item $c->set

Set item value in N index position.

    $c->set(5, 'foo');

=item $c->shift

Take the first element from the collection-

    my $item = $c->shift;

=item $c->size

Number of item elements.

=item $c->unshift

Add one or more elements at the beginning of the collection.

    $c->unshift('baz');

=item $c->to_array

Return the collection ARRAY.

=item $c->TO_JSON

Convert the collenction in JSON.

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-STIX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-STIX>

    git clone https://github.com/giterlizzi/perl-STIX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
