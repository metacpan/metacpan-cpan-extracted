package Search::Mousse::Writer;
use strict;
use base qw(Class::Accessor::Chained::Fast);
__PACKAGE__->mk_accessors(
  qw(directory name stemmer key_to_id id_to_key id_to_value word_to_id seen_key)
);
use CDB_File;
use CDB_File_Thawed;
use File::Temp qw/ :POSIX /;
use List::Uniq qw(uniq);
use Path::Class;

my $ID = 1;

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

	$self->_init;
  return $self;
}

sub _init {
  my ($self) = @_;
  my $name = $self->name;

  my $filename = file($self->directory, "${name}_key_to_id.cdb");
  my $tempfile = tmpnam();
  $self->key_to_id(CDB_File->new($filename, $tempfile)) or die $!;

  $filename = file($self->directory, "${name}_id_to_key.cdb");
  $tempfile = tmpnam();
  $self->id_to_key(CDB_File->new($filename, $tempfile)) or die $!;

  $filename = file($self->directory, "${name}_id_to_value.cdb");
  $tempfile = tmpnam();
  $self->id_to_value(CDB_File_Thawed->new($filename, $tempfile)) or die $!;

  $self->word_to_id({});
  $self->seen_key({});
}

sub add {
  my ($self, $key, $value, $words) = @_;

  # key must be unique
  return if $self->seen_key->{$key}++;

  my $id = $ID++;

  $self->key_to_id->insert($key,  $id);
  $self->id_to_key->insert($id,   $key);
  $self->id_to_value->insert($id, $value);

  my @words = $self->stemmer->($words);
  foreach my $word (@words) {
    push @{ $self->word_to_id->{$word} }, $id;
  }
}

sub write {
  my ($self) = @_;
  my $name = $self->name;

  $self->key_to_id->finish;
  $self->id_to_key->finish;
  $self->id_to_value->finish;

  my $filename = file($self->directory, "${name}_word_to_id.cdb");
  my $tempfile = tmpnam();
  my $cdb      = CDB_File_Thawed->new($filename, $tempfile) or die $!;

  while (my ($key, $value) = each %{ $self->word_to_id }) {
    $value = [ uniq @{$value} ];
    $cdb->insert($key, $value);
  }
  $cdb->finish;
}

1;

__END__

=head1 NAME

Search::Mousse::Writer - Writer for Search::Mousse databases

=head1 SYNOPSIS

  my $mousse = Search::Mousse::Writer->new(
    directory => $directory,
    name      => 'recipes',
  );
  $mousse->add("Borscht", $recipe, "borscht beet soup russian");
  $mousse->write;
  
=head1 DESCRIPTION

L<Search::Mousse::Writer> creates a L<Search::Mousse> database.

Use L<Search::Mousse> to query a database.

The default stemmer is:

  sub {
    my $words = lc shift;
    return uniq(split / /, $words);
  }

=head1 CONSTRUCTOR

=head2 new

The constructor takes a few arguments: the directory to store files in,
and a name for the database. If you have a custom stemmer, also pass it in:

  my $mousse = Search::Mousse::Writer->new(
    directory => $directory,
    name      => 'recipes',
  );
  
  my $mousse2 = Search::Mousse::Writer->new(
    directory => $directory,
    name      => 'photos',
    stemmer   => \&stemmer,
  );

=head1 METHODS

=head2 add

Adds a document to the database. A document has a key, a value (which
can be a Perl data structure or an object) and some keywords:

  $mousse->add("Borscht", $recipe, "borscht beet soup russian");

=head2 write

After adding all the documents, you must call the write() method:

  $mousse->write;

=head1 SEE ALSO

L<Search::Mousse::Writer>

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>

=head1 COPYRIGHT

Copyright (C) 2005, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.