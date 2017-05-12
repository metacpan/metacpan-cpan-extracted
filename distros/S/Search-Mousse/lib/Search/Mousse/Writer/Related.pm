package Search::Mousse::Writer::Related;
use strict;
use base qw(Class::Accessor::Chained::Fast);
__PACKAGE__->mk_accessors(
  qw(mousse id_to_related size)
);
use CDB_File;
use CDB_File_Thawed;
use File::Temp qw/ :POSIX /;
use List::Uniq qw(uniq);
use Path::Class;
use Search::ContextGraph;

sub new {
  my $class = shift;
  my %args  = @_;

  my $self = {};
  bless $self, $class;

  my $mousse = $args{mousse} || die "No mousse passed";
  $self->mousse($mousse);

  my $name      = $mousse->name;
  my $directory = $mousse->directory;

  my $filename = file($directory, "${name}_id_to_related.cdb");
  my $tempfile = tmpnam();
  $self->id_to_related(CDB_File_Thawed->new($filename, $tempfile)) or die $!;

  $self->size($args{size} || 20);

  return $self;
}

sub write {
  my $self          = shift;
  my $mousse        = $self->mousse;
  my $id_to_related = $self->id_to_related;
  my $size          = $self->size;

  my $cg = Search::ContextGraph->new(auto_reweight => 0);
  my %docs;
  while (my ($word, $ids) = each %{ $mousse->word_to_id }) {
    foreach my $id (@$ids) {
      push @{ $docs{$id} }, $word;
    }
  }
  $cg->bulk_add(%docs);
  $cg->reweight_graph();

  while (my ($id, $key) = each %{ $mousse->id_to_key }) {
    my @ids;
    eval {
      local $SIG{ALRM} = sub { die "alarm\n" };
      alarm 1;
      my ($docs, $words) = $cg->find_similar($id);
      @ids = (sort { $docs->{$b} <=> $docs->{$a} } keys %$docs);
      @ids = grep { $_ ne $id } @ids;
      @ids = splice(@ids, 0, $size);

      my @keys = map { $mousse->id_to_key->{$_} } @ids;

      #      print "$key -> @keys\n";
      alarm 0;
    };
    $id_to_related->insert($id, \@ids);
  }
  $id_to_related->finish;
}

1;

__END__

=head1 NAME

Search::Mousse::Writer::Related - Writer for related items in Search::Mousse

=head1 SYNOPSIS

  my $related = Search::Mousse::Writer::Related->new(
    mousse => $mousse,
    size   => 10,
  );
  $related->write;

=head1 DESCRIPTION

L<Search::Mousse::Writer::Related> takes a L<Search::Mousse> database
and analyses it to find related items. Once you have analysed it, the
L<Search::Mousse> methods fetch_similar and fetch_similar_keys will then
be available.

=head1 CONSTRUCTOR

=head2 new

The constructor takes a few arguments: a new L<Search::Mousse> object
and the maximum number of related items you wish to retrieve:

  my $related = Search::Mousse::Writer::Related->new(
    mousse => $mousse,
    size   => 10,
  );

=head1 METHODS

=head2 write

To analyse the database and write out the results, you must call the
write() method:

  $related->write;

=head1 SEE ALSO

L<Search::Mousse>, L<Search::Mousse::Writer>

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>

=head1 COPYRIGHT

Copyright (C) 2005, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
