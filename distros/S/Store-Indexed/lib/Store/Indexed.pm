package Store::Indexed;
use strict;
use warnings;

our $VERSION = '0.1';
our $BACKEND;

sub import {
    my ($class, @tags) = @_;
    ($BACKEND) = map { uc($1) } grep { /^:(XS|PP)$/i } @tags;
}

sub new {
    my ($class, %args) = @_;
    my $type = $args{backend} || $BACKEND || $ENV{STORE_BACKEND} || 'AUTO';
    $type = eval { require Store::Indexed::XS; 1 } ? 'XS' : 'PP' if $type eq 'AUTO';
    my $target = ($type eq 'XS') ? 'Store::Indexed::XS' : 'Store::Indexed::PP';
    warn $target;
    eval { (my $f = "$target.pm") =~ s|::|/|g; require $f };
    die "Load failed: $@" if $@;
    return $target->new(%args);
}

1;

=pod

=head1 NAME

Store::Indexed - A fast, key-indexed data store with dual XS and Pure-Perl backends.

=head1 SYNOPSIS

    use Store::Indexed;

    # Auto-detects best backend (XS preferred)
    my $store = Store::Indexed->new(qw(key1 key2 key3));

    # Accessors are generated dynamically based on keys
    $store->set_key1(0, "value_for_id_0");
    my $val = $store->get_key1(0);

=head1 DESCRIPTION

B<Store::Indexed> provides an interface for storing and retrieving data points 
indexed by an integer ID and a column name. It uses a flat array structure under 
the hood to achieve high performance. It supports both a highly optimized 
C-based implementation (XS) and a portable Pure-Perl implementation (PP).

=head1 METHODS

=head2 new(@keys)

Creates a new C<Store::Indexed> instance. The list of C<@keys> defines the fixed 
columns of the data store. This will dynamically generate C<get_$key>, 
C<set_$key>, C<exists_$key>, and C<delete_$key> methods for each key provided.

=head2 Dynamic Accessors

For every key defined in C<new()>, the following methods are injected:

=over 4

=item * C<get_$key($id)>: Returns the value at row C<$id> and column C<$key>.

=item * C<set_$key($id, $value)>: Sets the value at row C<$id> and column C<$key>.

=item * C<exists_$key($id)>: Returns true if a value exists at that location.

=item * C<delete_$key($id)>: Removes the value at that location.

=back

=head1 ENVIRONMENT

=over 4

=item * C<STORE_BACKEND>: Set to C<XS> or C<PP> to globally define the preferred 
backend for the current process.

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut