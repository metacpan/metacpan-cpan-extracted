package Mojo::Collection::Role::Transform;
use Mojo::Base -role;
use Carp ();

our $VERSION = '0.01';

requires 'reduce';

sub hashify { _reduce(shift, \&_multi_key_hash_assign, {}, @_) }

sub hashify_collect {
    my $self = shift;

    if (ref $_[0] eq 'HASH' and _parse_flatten_option(shift)) {
        return _reduce($self, \&_multi_key_hash_collect_and_flatten, {}, @_)
    }

    return _reduce($self, \&_multi_key_hash_collect, {}, @_);
}

sub collect_by {
    my $self = shift;

    if (ref $_[0] eq 'HASH' and _parse_flatten_option(shift)) {
        return _reduce($self, \&_collect_by_and_flatten, [Mojo::Collection->new, {}], @_)->[0];
    }

    return _reduce($self, \&_collect_by, [Mojo::Collection->new, {}], @_)->[0];
}

sub _multi_key_hash_assign {
    my ($hash, $keys, $value, @extra_values) = @_;
    Carp::confess 'multiple values returned from get_value sub when one is expected' if @extra_values;

    _create_leading_key_hashes($hash, $keys)->{$keys->[-1]} = $value;
}

sub _multi_key_hash_collect {
    my ($hash, $keys, @values) = @_;

    push @{ _create_leading_key_hashes($hash, $keys)->{$keys->[-1]} ||= Mojo::Collection->new }, @values;
}

sub _multi_key_hash_collect_and_flatten {
    my ($hash, $keys, @values) = @_;

    push
        @{ _create_leading_key_hashes($hash, $keys)->{$keys->[-1]} ||= Mojo::Collection->new },
        _flatten(@values);
}

sub _collect_by {
    my ($collection, $hash, $keys, @values) = (@{+shift}, @_);

    my $leading_hash = _create_leading_key_hashes($hash, $keys);
    unless (exists $leading_hash->{$keys->[-1]}) {
        push @$collection, $leading_hash->{$keys->[-1]} = Mojo::Collection->new;
    }

    push @{ $leading_hash->{$keys->[-1]} }, @values;
}

sub _collect_by_and_flatten {
    my ($collection, $hash, $keys, @values) = (@{+shift}, @_);

    my $leading_hash = _create_leading_key_hashes($hash, $keys);
    unless (exists $leading_hash->{$keys->[-1]}) {
        push @$collection, $leading_hash->{$keys->[-1]} = Mojo::Collection->new;
    }

    push @{ $leading_hash->{$keys->[-1]} }, _flatten(@values);
}

sub _create_leading_key_hashes {
    my ($hash, $keys) = @_;

    my $cur_hash = $hash;
    for my $key (@$keys[0..$#$keys - 1]) {
        $cur_hash = $hash->{$key} ||= {};
    }

    return $cur_hash;
}

sub _reduce {
    my ($self, $apply_key_and_value, $initial) = (shift, shift, shift);

    unless (@_) {
        Carp::croak 'must provide get_keys sub';
    }

    my $get_keys = shift;
    my $get_keys_ref = ref $get_keys || 'scalar value';
    Carp::croak qq{get_keys sub must be a subroutine, but was '$get_keys_ref'} unless $get_keys_ref eq 'CODE';

    my $get_value;
    if (@_) {
        $get_value = shift;
        my $get_value_ref = ref $get_value || 'scalar value';
        Carp::croak qq{get_value must be a subroutine if provided, but was '$get_value_ref'} if $get_value_ref ne 'CODE';
    } else {
        $get_value = sub { $_ };
    }

    return $self->reduce(sub {
        local $_ = $b;
        $apply_key_and_value->($a, [$get_keys->($b)], $get_value->($b));

        $a;
    }, $initial);
}

sub _flatten { map { ref($_) ? _flatten(@$_) : $_ } @_ }

sub _parse_flatten_option {
    my ($options) = @_;
    return unless %$options;

    Carp::confess 'only one option can be provided' if keys %$options > 1;

    my $flatten = delete $options->{flatten};

    Carp::confess 'unknown options provided: ' . Mojo::Util::dumper $options if %$options;

    return $flatten;
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::Collection::Role::Transform - Transformations for Mojo::Collection

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojo-Collection-Role-Transform"><img src="https://travis-ci.org/srchulo/Mojo-Collection-Role-Transform.svg?branch=master"></a> <a href='https://coveralls.io/github/srchulo/Mojo-Collection-Role-Transform?branch=master'><img src='https://coveralls.io/repos/github/srchulo/Mojo-Collection-Role-Transform/badge.svg?branch=master' alt='Coverage Status' /></a>

=head1 SYNOPSIS

  my $c = Mojo::Collection->new(
    {
      name           => 'Bob',
      age            => 23,
      favorite_color => 'blue',
    },
    {
      name           => 'Alice',
      age            => 24,
      favorite_color => 'blue',
    },
    {
      name           => 'Eve',
      age            => 27,
      favorite_color => 'green',
    },
  )->with_roles('+Transform');

  # hash key is name, value is the original hash
  my $name_to_person = $c->hashify(sub { $_->{name} });

  # 23
  say $name_to_person->{Bob}{age};

  # 27
  say $name_to_person->{Eve}{age};

  # set your own value
  my $name_to_favorite_color = $c->hashify(sub { $_->{name} }, sub { $_->{favorite_color} });

  # blue
  say $name_to_favorite_color->{Bob};

  # green
  say $name_to_favorite_color->{Eve};


  # collect values with the same key in a Mojo::Collection
  my $favorite_color_to_collection = $c->hashify_collect(sub { $_->{favorite_color} });

  # $favorite_color_to_collection->{blue} contains Mojo::Collection of Bob and Alice hashes
  # $favorite_color_to_collection->{green} contains Mojo::Collection of Eve hash

  # says Bob, then Alice
  for my $person ($favorite_color_to_collection->{blue}->each) {
    say $person->{name};
  }


  # Create a Mojo::Collection of Mojo::Collections, where all values in each inner
  # Mojo::Collection share the same key
  my $collections_by_favorite_color = $c->collect_by(sub { $_->{favorite_color} });
  for my $favorite_color_collection ($collections_by_favorite_color->each) {
    say $favorite_color_collection->[0]->{favorite_color};

    for my $person ($favorite_color_collection->each) {
      say "\t$person->{name}";
    }
  }

  # output is
  # blue
  #     Bob
  #     Alice
  # green
  #     Eve

=head1 DESCRIPTION

L<Mojo::Collection::Role::Transform> provides methods that allow you to transform your L<Mojo::Collection> in meaningful and flexible ways.

=head1 METHODS

=head2 hashify

=over 4

=item hashify($get_keys_sub, [$get_value_sub])

=back

  my $c = Mojo::Collection->new(
    {
      name           => 'Bob',
      age            => 23,
      favorite_color => 'blue',
    },
    {
      name           => 'Alice',
      age            => 24,
      favorite_color => 'blue',
    },
    {
      name           => 'Eve',
      age            => 27,
      favorite_color => 'green',
    },
  )->with_roles('+Transform');

  # hash key is name, value is the original hash
  my $name_to_person = $c->hashify(sub { $_->{name} });

  # 23
  say $name_to_person->{Bob}{age};

  # 27
  say $name_to_person->{Eve}{age};


  # set your own value
  my $name_to_favorite_color = $c->hashify(sub { $_->{name} }, sub { $_->{favorite_color} });

  # blue
  say $name_to_favorite_color->{Bob};

  # green
  say $name_to_favorite_color->{Eve};


  # return multiple keys as a list to create a multiple nested hashes based on the returned keys and their order
  my $name_to_age_favorite_color = $c->hashify(sub { @$_{qw(name age)} }, sub { $_->{favorite_color} });

  # blue
  say $name_to_favorite_color->{Bob}{23};

  # green
  say $name_to_favorite_color->{Eve}{27};

L</hashify> allows you to transform a L<Mojo::Collection> into a single key or multi-key hash based on its elements. A unique
key or list of keys may only have one value, so for any duplicate keys, the final element seen with that key will be the one that sets the
value.

=head3 get_keys

L</get_keys> is required and must return a single key or a list of keys. The return value of L</get_keys> will be the keys used to
ultimately access the value that is returned by L</get_value> for the same element.

  # return single key
  my $hash = $c->hashify(sub { $_->{name} });
  my $value = $hash->{$name};

  # return multiple keys
  my $hash = $c->hashify(sub { $_->{name}, $_->{age} });
  my $value = $hash->{$name}{$age};

The current element is available via C<$_>, or as the first argument to L</get_keys>.

=head3 get_value

L</get_value> must return a B<single> value for the current element in the L<Mojo::Collection>.

  my $name_to_age = $c->hashify(sub { $_->{name} }, sub { $_->{age} });
  my $age = $name_to_age->{Bob};

The default is to return the current element:

  # default get_value
  sub { $_ }

  # not passing in get_value uses the above subroutine to return the current collection element, in this case a hash
  my $name_to_person = $c->hashify(sub { $_->{name} });
  my $age = $name_to_person->{Bob}{age};

The current element is available via C<$_>, or as the first argument to L</get_value>.

=head2 hashify_collect

=over 4

=item hashify_collect($get_keys_sub, [$get_values_sub])

=back

  my $c = Mojo::Collection->new(
    {
      name           => 'Bob',
      age            => 23,
      favorite_color => 'blue',
    },
    {
      name           => 'Alice',
      age            => 24,
      favorite_color => 'blue',
    },
    {
      name           => 'Eve',
      age            => 27,
      favorite_color => 'green',
    },
  )->with_roles('+Transform');

  # collect values with the same key in a Mojo::Collection
  my $favorite_color_to_collection = $c->hashify_collect(sub { $_->{favorite_color} });

  # $favorite_color_to_collection->{blue} contains Mojo::Collection of Bob and Alice hashes
  # $favorite_color_to_collection->{green} contains Mojo::Collection of Eve hash

  # says Bob, then Alice
  for my $person ($favorite_color_to_collection->{blue}->each) {
    say $person->{name};
  }

  # provide your own get_values sub
  my $favorite_color_to_names = $c->hashify_collect(sub { $_->{favorite_color} }, sub { $_->{name} });

  # $favorite_color_to_names->{blue} contains Mojo::Collection of 'Bob' and 'Alice'
  # $favorite_color_to_names->{green} contains Mojo::Collection of 'Eve'

  # return multiple values
  my $favorite_color_to_names_and_ages = $c->hashify_collect(sub { $_->{favorite_color} }, sub { $_->{name}, $_->{age} });

  # $favorite_color_to_names_and_ages->{blue} contains Mojo::Collection of 'Bob', 23, 'Alice', 24
  # $favorite_color_to_names_and_ages->{green} contains Mojo::Collection of 'Eve', 27

L</hashify_collect> allows you to transform a L<Mojo::Collection> into a single key or multi-key hash where the final value is a L<Mojo::Collection> with
all elements that match that key. L</get_values> allows you to control which values are collected in the L<Mojo::Collection>.

=head3 get_keys

L<"get_keys"|/get_keys1> is required and must return a single key or a list of keys. The return value of L<"get_keys"|/get_keys1> will be the keys used to
ultimately access the L<Mojo::Collection> of values that are returned by L</get_values> for each element.

  # return single key
  my $hash = $c->hashify(sub { $_->{name} });
  my $collection = $hash->{$name};

  # return multiple keys
  my $hash = $c->hashify(sub { $_->{name}, $_->{age} });
  my $collection = $hash->{$name}{$age};

The current element is available via C<$_>, or as the first argument to L<"get_keys"|/get_keys1>.

=head3 get_values

L</get_values> may return one or more values as a list for the current element in the L<Mojo::Collection>.

  # return single value
  my $name_to_ages = $c->hashify(sub { $_->{name} }, sub { $_->{age} });
  my $ages_collection = $name_to_ages->{Bob};

  # return multiple values
  my $name_to_ages_and_favorite_colors = $c->hashify(sub { $_->{name} }, sub { $_->{age}, $_->{favorite_color} });
  my $ages_and_favorite_colors_collection = $name_to_ages_and_favorite_colors->{Bob};

The default is to return the current element:

  # default get_value
  sub { $_ }

  # not passing in get_value uses the above subroutine to return the current collection element, in this case a hash
  my $name_to_persons = $c->hashify(sub { $_->{name} });
  my $person_collection = $name_to_persons->{Bob};

The current element is available via C<$_>, or as the first argument to L</get_values>.

=head3 OPTIONS

=head4 flatten

  # trivial example where returned values are wrapped in arrayrefs to demonstrate flatten
  my $name_to_ages = $c->hashify({flatten => 1}, sub { $_->{name} }, sub { [$_->{age}] });

The L</flatten> option flattens each resulting L<Mojo::Collection>, meaning that
it flattens nested collections/arrays recursively and creates a new collection with all elements. See L<Mojo::Collection/flatten>
for more details.

Internally, L</flatten> is implemented differently for performance, but the end result is the same.

=head2 collect_by

=over 4

=item collect_by($get_keys_sub, [$get_values_sub])

=back

  my $c = Mojo::Collection->new(
    {
      name           => 'Bob',
      age            => 23,
      favorite_color => 'blue',
    },
    {
      name           => 'Alice',
      age            => 24,
      favorite_color => 'blue',
    },
    {
      name           => 'Eve',
      age            => 27,
      favorite_color => 'green',
    },
  )->with_roles('+Transform');

  # Create a Mojo::Collection of Mojo::Collections, where all values in each inner
  # Mojo::Collection share the same key
  my $collections_by_favorite_color = $c->collect_by(sub { $_->{favorite_color} });
  for my $favorite_color_collection ($collections_by_favorite_color->each) {
    say $favorite_color_collection->[0]->{favorite_color};

    for my $person ($favorite_color_collection->each) {
      say "\t$person->{name}";
    }
  }

  # output is
  # blue
  #     Bob
  #     Alice
  # green
  #     Eve

  # collect by multiple keys
  # uses favorite_color and age as the keys
  my $collections_by_favorite_color_and_age = $c->collect_by(sub { $_->{favorite_color}, $_->{age} });

L</collect_by> allows you to transform a L<Mojo::Collection> into a L<Mojo::Collection> of L<Mojo::Collection>s,
where all elements of the inner collections share the same single key or list of keys.
L<"get_values"|/get_values1> allows you to control which values are collected in the L<Mojo::Collection>.

=head3 get_keys

L<"get_keys"|/get_keys2> is required and must return a single key or a list of keys. The return value of L<"get_keys"|/get_keys2> will be the keys used group
values that are returned by L<"get_values"|/get_values1> into each inner L<Mojo::Collection>.

  # return single key
  my $collections = $c->hashify(sub { $_->{name} });

  # return multiple keys
  my $collections = $c->hashify(sub { $_->{name}, $_->{age} });

The current element is available via C<$_>, or as the first argument to L<"get_keys"|/get_keys2>.

=head3 get_values

L<"get_values"|/get_values1> may return one or more values as a list for the current element in the L<Mojo::Collection>.

  # return single value
  my $collections_of_age = $c->hashify(sub { $_->{name} }, sub { $_->{age} });

  # i.e.
  # [ [23], [24], [27] ]

  # return multiple values
  my $collections_of_age_and_favorite_color = $c->hashify(sub { $_->{name} }, sub { $_->{age}, $_->{favorite_color} });

  # i.e.
  # [ [23, 'blue'], [24, 'blue'], [27, 'green'] ]

The default is to return the current element:

  # default get_value
  sub { $_ }

  # not passing in get_value uses the above subroutine to return the current collection element, in this case a hash
  my $collections = $c->hashify(sub { $_->{name} });

  # i.e.
  # [ [{ name => 'Bob', ...}], [{ name => 'Alice', ...}], [{name => 'Eve', ...}] ]

The current element is available via C<$_>, or as the first argument to L<"get_values"|/get_values1>.

=head3 OPTIONS

=head4 flatten

  # trivial example where returned values are wrapped in arrayrefs to demonstrate flatten
  my $collections = $c->hashify({flatten => 1}, sub { 'key' }, sub { [$_->{age}] });

  # i.e.
  # [ [23, 24, 27] ]

The L<"flatten"|/flatten1> option flattens each inner L<Mojo::Collection>, meaning that
it flattens nested collections/arrays recursively and creates a new collection with all elements. See L<Mojo::Collection/flatten>
for more details.

Internally, L<"flatten"|/flatten1> is implemented differently for performance, but the end result is the same.

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019- Adam Hopkins

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item

* L<Mojo::Collection>

=item

* L<Mojo::Base/with_roles>

=item

* L<Role::Tiny>

=back

=cut
