package Search::Mousse;
use strict;
our $VERSION = '0.32';
use base qw(Class::Accessor::Chained::Fast);
__PACKAGE__->mk_accessors(
  qw(directory name stemmer key_to_id id_to_key id_to_value word_to_id
    id_to_related and
  )
);
use CDB_File;
use CDB_File_Thawed;
use List::Uniq qw(uniq);
use Path::Class;
use Search::QueryParser;
use Set::Scalar;

sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;

	my %args = @_;
	$self->directory($args{directory});
  $self->name($args{name});
  $self->stemmer(
    $args{stemmer} ||
    sub {
      my $words = lc shift;
      return uniq(split / /, $words);
    }
  );
  $self->and($args{and} || 0);

	$self->_init;
  return $self;
}

sub _init {
  my ($self) = @_;
  my $name   = $self->name;
  my $dir    = $self->directory;

  my $filename = file($dir, "${name}_key_to_id.cdb");
  tie my %cdb1, 'CDB_File', $filename or die "tie failed: $!\n";
  $self->key_to_id(\%cdb1);

  $filename = file($dir, "${name}_id_to_key.cdb");
  tie my %cdb2, 'CDB_File', $filename or die "tie failed: $!\n";
  $self->id_to_key(\%cdb2);

  $filename = file($dir, "${name}_id_to_value.cdb");
  tie my %cdb3, 'CDB_File_Thawed', $filename or die "tie failed: $!\n";
  $self->id_to_value(\%cdb3);

  $filename = file($dir, "${name}_word_to_id.cdb");
  tie my %cdb4, 'CDB_File_Thawed', $filename or die "tie failed: $!\n";
  $self->word_to_id(\%cdb4);

  $filename = file($dir, "${name}_id_to_related.cdb");
  if (-f $filename) {
    tie my %cdb7, 'CDB_File_Thawed', $filename or die "tie failed: $!\n";
    $self->id_to_related(\%cdb7);
  }
}

sub fetch {
  my ($self, $key) = @_;

  my $id = $self->key_to_id->{$key};
  return unless $id;
  return $self->id_to_value->{$id};
}

sub fetch_related {
  my ($self, $key) = @_;
  my $id_to_value = $self->id_to_value;
  
  my $id = $self->key_to_id->{$key};
  return unless $id;
  my $ids = $self->id_to_related->{$id} || [];
  return map { $id_to_value->{$_} } @$ids;
}

sub fetch_related_keys {
  my ($self, $key) = @_;
  my $id_to_key = $self->id_to_key;
  
  my $id = $self->key_to_id->{$key};
  return unless $id;
  my $ids = $self->id_to_related->{$id} || [];
  return map { $id_to_key->{$_} } @$ids;
}

sub search {
  my ($self, $words) = @_;

  my @ids = $self->_search_ids($words);

  my @values = map { $self->id_to_value->{$_} } @ids;
  return @values;
}

sub search_keys {
  my ($self, $words) = @_;
  my @ids = $self->_search_ids($words);

  my @keys = map { $self->id_to_key->{$_} } @ids;
  return @keys;
}

sub _search_ids {
  my ($self, $words) = @_;

  my $qp = Search::QueryParser->new;
  my $query = $qp->parse($words);
  return unless $query;

  my @union;
  foreach my $term (@{$query->{""}}) {
    my $value = $term->{value};
    my @values = $self->stemmer->($value);
    push @union, $values[0];
  }
  
  my @plus;
  foreach my $term (@{$query->{"+"}}) {
    my $value = $term->{value};
    my @values = $self->stemmer->($value);
    push @plus, $values[0];
  }
  
  my @minus;
  foreach my $term (@{$query->{"-"}}) {
    my $value = $term->{value};
    my @values = $self->stemmer->($value);
    push @minus, $values[0];
  }
  
  if ($self->and) {
    push @plus, @union;
    @union = ();
  }
  
  my $s = Set::Scalar->new;

	if (@union) {
    foreach my $word (@union) {
      next unless exists $self->word_to_id->{$word};
      my @ids = @{ $self->word_to_id->{$word} };
      $s->insert(@ids);
    }
  
    foreach my $word (@plus) {
      return unless exists $self->word_to_id->{$word};
      my @ids = @{ $self->word_to_id->{$word} };
      my $s2 = Set::Scalar->new(@ids);
      $s = $s->intersection($s2);
    }
  } else {
    my $word = pop @plus;
    my @ids = @{ $self->word_to_id->{$word} };
    $s->insert(@ids);

    foreach my $word (@plus) {
      return unless exists $self->word_to_id->{$word};
      my @ids = @{ $self->word_to_id->{$word} };
      my $s2 = Set::Scalar->new(@ids);
      $s = $s->intersection($s2);
    }   
  }

  foreach my $word (@minus) {
    next unless exists $self->word_to_id->{$word};
    my @ids = @{ $self->word_to_id->{$word} };
    $s = $s->delete(@ids);
  }
  
  return $s->members;
}

1;

__END__

=head1 NAME

Search::Mousse - A simple and fast inverted index

=head1 SYNOPSIS

  my $mousse = Search::Mousse->new(
    directory => $directory,
    name      => 'recipes',
  );
  my $recipe = $mousse->fetch("Hearty Russian Beet Soup");
  my @recipes = $mousse->search("crumb");
  my @recipe_keys = $mousse->search_keys("italian soup");
  
=head1 DESCRIPTION

L<Search::Mousse> provides a simple and fast inverted index.

It is intended for constant databases (this is why it can be fast).
Documents have a key, keywords (which the document can later be search
for with) and a value (which can be a Perl data structure or object).

Use L<Search::Mousse::Writer> to construct a database.

The default stemmer is:

  sub {
    my $words = lc shift;
    return uniq(split / /, $words);
  }

Why is it called Search::Mousse? Well, in culinary terms, mousses are
simple to make, can include quite complicated ingredients, and are
inverted before presentation.

=head1 CONSTRUCTOR

=head2 new

The constructor takes a few arguments: the directory to store files in,
and a name for the database. If you have a custom stemmer, also pass it in:

  my $mousse = Search::Mousse->new(
    directory => $directory,
    name      => 'recipes',
  );
  
  my $mousse2 = Search::Mousse->new(
    directory => $directory,
    name      => 'photos',
    stemmer   => \&stemmer,
  );

=head1 METHODS

=head2 and

If this is set to true, query terms are ANDed by default. Thus "white
bread" would be parsed the same as "+white +bread":

  $mousse->and(1);

=head2 fetch

Returns a value from the database, given a key:

  my $recipe = $mousse->fetch("Hearty Russian Beet Soup");

=head2 fetch_related

If you have used L<Search::Mousse::Writer::Related> to analyse the
database, the fetch_related() method returns a list of values that are
similar to the given key:

  my @recipes = $mousse->fetch_related("Hearty Russian Beet Soup");

=head2 fetch_related_keys

If you have used L<Search::Mousse::Writer::Related> to analyse the
database, the fetch_related_keys() method returns a list of keys that
are similar to the given key:

  my @keys = $mousse->fetch_related_keys("Hearty Russian Beet Soup");
  
=head2 search

Returns a list of values that match the search terms (but see and()):

  my @white_or_bread = $mousse->search("white bread");
  my @white_bread    = $mousse->search("+white +bread");
  my @nonwhite_bread = $mousse->search("-white +bread");

=head2 search_keys

Returns a list of keys that have all the keywords passed:

  my @recipe_keys = $mousse->search_keys("italian soup");

=head1 SEE ALSO

L<Search::Mousse::Writer>, L<Search::Mousse::Writer::Related>

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>

=head1 COPYRIGHT

Copyright (C) 2005, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
