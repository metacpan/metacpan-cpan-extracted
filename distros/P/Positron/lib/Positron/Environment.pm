package Positron::Environment;
our $VERSION = 'v0.1.3'; # VERSION

=head1 NAME

Positron::Environment - container class for template parameters

=head1 VERSION

version v0.1.3

=head1 SYNOPSIS

    use Positron::Environment;
    my $env   = Positron::Environment->new({ key1 => 'value 1', key2 => 'value 2'});
    my $child = Positron::Environment->new({ key1 => 'value 3'}, { parent => $env });

    say $env->get('key1');   # value 1
    say $env->get('key2');   # value 2
    say $child->get('key1'); # value 3
    say $child->get('key2'); # value 2

    $child->set( key2 => 'value 4' );
    say $child->get('key2'); # value 4
    say $env->get('key2');   # value 2

=head1 DESCRIPTION

C<Positron::Environment> is basically a thin wrapper around hashes (key-value mappings)
with hierarchy extensions. It is used internally by the C<Positron> template systems
to store template variables.

C<Positron::Environment> provides getters and setters for values. It can also optionally
refer to a parent environment. If the environment does not contain anything for an
asked-for key, it will ask its parent in turn.
Note that if a key refers to C<undef> as its value, this counts as "containing something",
and the parent will not be asked.

Getting or setting the special key C<_> (a single underscore) accesses the entire data,
i.e. the hash that was used in the constructor.
These requests are never passed to any parents.

=head2 Non-hash data

Although C<Positron::Environment> is built for hashes, it can also be used with plain
scalar data (strings, numbers, C<undef>) or array references.
Calling C<get> when the data is a string results in C<undef> being returned.
Calling C<set> when the data is a string results in a warning, and returns C<undef>,
but currently does not raise an exception. Just don't expect to get that value back
again.

Calling C<get> or C<set> when the data is an array (reference) works by first converting
the key to an integer via the builtin C<int> function.
This means that alphabetic keys will be coerced to the number C<0> (with the regular
Perl warning) and floating point values get rounded towards 0.
On the other hand, this means that negative keys will start counting from the back of
the array.

=cut

use v5.10;
use strict;
use warnings;
use Carp qw(croak carp);

=head1 CONSTRUCTOR

=head2 new

    my $env = Positron::Environment->new( \%data, \%options );

Creates a new environment which serves the data passed in a hash reference. The following options are supported:

=over 4

=item immutable

If set to a true value, the constructed environment will be immutable; calling the
C<set> method will raise an exception.

=item parent

A reference to another environment. If the newly constructed environment does not
contain a key when asked with C<get>, it will ask this parent environment (which
can have a parent in turn).

=back

=cut

sub new {
    my($class, $data, $options) = @_;
    $options //= {};
    my $self = {
        data => $data // {},
        immutable => $options->{'immutable'} // 0,
        # We don't need to weaken, since we are always pointing upwards only!
        parent => $options->{'parent'} // undef,
    };
    return bless($self, $class);
}

=head1 METHODS

=head2 get

    my $value = $env->get('key');

Returns the value stored under the key C<key> in the data of this environment.
This is very much like a standard hash ref. If this environment does not know
about this key (i.e. it does not exist in the data hash), it returns C<undef>,
unless a parent environment is set. In this case, it will recursively query
its parent for the key.

The special key C<_> returns the entire data of this environment, never
querying the parent.

=cut

sub get {
    my ($self, $key) = @_;
    if ($key eq '_') {
        return $self->{'data'};
    }
    if (ref($self->{'data'}) eq 'HASH' and exists $self->{'data'}->{$key}) {
        return $self->{'data'}->{$key};
    } elsif (ref($self->{'data'}) eq 'ARRAY') {
        # What about parents with array refs?
        no warnings 'numeric'; # all else is 0, that's ok.
        return $self->{'data'}->[int($key)];
    # N.B.: other scalars (non-refs, objects) never perform subqueries, always 'undef'
    } elsif ($self->{'parent'}) {
        return $self->{'parent'}->get($key);
    }
    return undef; # always scalar
}

=head2 set

    my $value = $env->set('key', 'value');

Sets the key to the given value in this environment's data hash.
This call will croak if the environment has been marked as immutable.
Setting the value to C<undef> will effectively mask any parent; a C<get>
call will return C<undef> even if the parent has a defined value.

The special key C<_> sets the entire data of this environment.

Returns the value again I<(this may change in future versions)>.

=cut

# Why do we need this, again?
# TODO: Should this delete if no value is passed?
sub set {
    my ($self, $key, $value) = @_;
    croak "Immutable environment being changed" if $self->{'immutable'};
    if ($key eq '_') {
        $self->{'data'} = $value;
    } elsif (ref($self->{'data'}) eq 'ARRAY') {
        no warnings 'numeric';
        $self->{'data'}->[int($key)] = $value;
    } elsif (ref($self->{'data'}) eq 'HASH') {
        $self->{'data'}->{$key} = $value;
    } else {
        carp "Setting an environment which is neither hash nor array";
    }
    return $value;
}

1; # End of Positron::Environment

__END__

=head1 AUTHOR

Ben Deutsch, C<< <ben at bendeutsch.de> >>

=head1 BUGS

None known so far, though keep in mind that this is alpha software.

Please report any bugs or feature requests to C<bug-positron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Positron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

This module is part of the Positron distribution.

You can find documentation for this distribution with the perldoc command.

    perldoc Positron

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Positron>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Positron>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Positron>

=item * Search CPAN

L<http://search.cpan.org/dist/Positron/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Ben Deutsch. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
See L<http://dev.perl.org/licenses/> for more information.

=cut
