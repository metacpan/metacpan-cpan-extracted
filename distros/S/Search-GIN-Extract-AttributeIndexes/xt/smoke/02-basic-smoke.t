
use strict;
use warnings;

use Test::More tests => ( 100 * 100 );

{

  package Model;
  use Moose;
  use MooseX::AttributeIndexes;
  use MooseX::Types::Moose qw( :all );

  has id => (
    isa           => Int,
    is            => 'rw',
    lazy_build    => 1,
    primary_index => 1,
  );

  has name => (
    isa      => Str,
    is       => 'rw',
    required => 1,
    indexed  => 1,
  );

  has password => (
    isa      => Str,
    is       => 'rw',
    required => 1,
  );

  my $idn = 0;

  sub _build_id {
    ++$idn;
  }

  __PACKAGE__->meta->make_immutable;

}

sub chars {
  join '', map { chr( rand(255) ) } 0 .. 30;
}

use Search::GIN::Extract::AttributeIndexes;
use Data::Dump qw( dump );

for ( 1 .. 100 ) {

  my $extractor = Search::GIN::Extract::AttributeIndexes->new();

item: for ( 1 .. 100 ) {
    my ( $name, $pass );
    $name = chars();
    $pass = chars();

    my $model = Model->new( name => $name, password => $pass );
    my @results;
    @results = $extractor->extract_values($model);
    my $found = {};
    my $fail  = 0;

  result: for (@results) {
      if ( $_ =~ /^id:(\d+)$/ ) {
        $fail++ if exists $found->{'id'};
        $found->{id} = $1;
        next result;
      }
      if ( $_ =~ /^name:(.*$)/s ) {
        $fail++ if exists $found->{'name'};
        $found->{name} = $1;
        next result;
      }
      $fail++;
    }

    if ($fail) {
      ok( 0, "Data Structure returned too many items or badly identified items" );
      diag( \@results );
      next;
    }
    if ( $found->{'id'} eq $model->id && $found->{'name'} eq $model->name ) {
      ok( 1, "Datastructure collects properly" );
      next;
    }
    ok( 0, "Datastructure and model diverge" );
    diag( 'harvested', dump $found );
    diag( 'model',     dump $model );
    diag( 'result',    dump \@results );
  }
}
