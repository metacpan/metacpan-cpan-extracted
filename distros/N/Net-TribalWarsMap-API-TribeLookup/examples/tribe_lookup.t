use v5.16;
use warnings;

use Net::TribalWarsMap::API::TribeLookup;
use Data::Dump qw(pp);

my @tags = qw( Sexy -WAR- ~WAR~ SF );

my @tribes;

for my $tag (@tags) {

  my $la = Net::TribalWarsMap::API::TribeLookup->get_tag( 'en69', $tag );
  if ( not $la ) {
    warn "no such tribe $tag";
  }
  else {
    push @tribes, $la;
  }
}

sub render_table {
  my ( $name, $trs, $fields, $sort_field ) = @_;

  my @rows;

  push @rows, sprintf '[**]%s[||]%s[/**]', $name, ( join q{[||]}, @{$fields} );
  for my $tribe ( sort { $a->$sort_field <=> $b->$sort_field } @{$trs} ) {
    my $prelude = sprintf '[ally]%s[/ally]', $tribe->{tag};
    my @fvs = ($prelude);
    for my $field ( @{$fields} ) {
      if ( $field eq $sort_field ) {
        push @fvs, sprintf '[color=red]%s[/color]', $tribe->$field;
      }
      else {
        push @fvs, $tribe->$field;
      }
    }
    push @rows, sprintf '[**]%s[/**]', ( join q{[|]}, @fvs );
  }
  return join qq[\n], q{[table]}, @rows, q{[/table]}, '';
}

say render_table( points => \@tribes, [qw( members points rank avg_points )],                           'avg_points' );
say render_table( od     => \@tribes, [qw( members oda oda_rank avg_oda odd odd_rank avg_odd avg_od )], 'avg_od' );
say render_table( ratios => \@tribes, [qw( members od_ratio od_point_ratio )],                          'od_point_ratio' );

__END__
my @fields = qw( members oda oda_rank odd odd_rank points rank od_ratio od_point_ratio avg_od avg_points );

say '[table]';
say '[**][||]'. ( join q{[||]}, @fields ) . '[/**]';


sub get_field {
    my ( $tribe, $field ) = @_;
    if ( not ref $tribe ) {
        die "Tribe not a ref";
    }
    if ( not $tribe->can($field) ) {
        die "Tribe can't $field";
    }
    return $tribe->$field();
}
sub get_fields {
    my ( $tribe ) = @_ ;
    return map { get_field( $tribe, $_ ) } @fields;
}

for my $tribe ( sort { $a->od_ratio <=> $b->od_ratio } @tribes ) {
    say '[**][ally]' . $tribe->tag . '[/ally][|]' . ( join q{[|]}, get_fields( $tribe )  ) . '[/**]';
}
say '[/table]';


1;

