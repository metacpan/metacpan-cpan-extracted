# perl
use strict;
use warnings;
use 5.10.1;
use Carp;
use Parse::Taxonomy::MaterializedPath;

# Goal is to populate the letters table in the hierarchy database with rows
# that will permit evaluation of alternative definitions of views displaying
# materialized_paths and child counts.
#
# I want a CSV file which can be read as input for \copy FROM.  The purpose of
# this program is to compose that CSV file from dummy data which contains a valid
# taxonomy. I should be able to accomplish that by creating the Perl data
# structures needed to use Parse::Taxonomy::MaterializedPath's 'components'
# interface, then calling adjacentify() and write_adjacentified_to_file() on
# the object.

my @input_columns = ( qw| path letter_vendor_id is_actionable | );
my (@toplevels, @seconds, @thirds);
@toplevels = ( qw|
    alpha beta gamma delta epsilon zeta eta theta
    iota kappa lamda mu nu xi omicron pi
    rho sigma tau upsilon phi chi psi omega
| );
@seconds = ( qw|
    able
    baker
    charlie
    dogtag
    entry
    fargo
    golfer
    hiphop
    icicle
    joyride
| );
@thirds = (
  "AOL",
  "Aachen",
  "Aaliyah",
  "Aaron",
  "Abbas",
  "Abbasid",
  "Abbott",
  "Abby",
  "Abdul",
  "Abe",
  "Abel",
  "Abelard",
  "Abelson",
  "Aberdeen",
  "Abernathy",
  "Abidjan",
  "Abigail",
  "Abilene",
  "Abner",
  "Abraham",
  "Abram",
  "Absalom",
  "Abuja",
  "Abyssinia",
  "Abyssinian",
  "Acadia",
  "Acapulco",
  "Accenture",
  "Accra",
  "Acevedo",
  "Achaean",
  "Achebe",
  "Achernar",
  "Acheson",
  "Achilles",
  "Aconcagua",
  "Acosta",
  "Acropolis",
  "Acrux",
  "Actaeon",
  "Acton",
  "Acts",
  "Acuff",
  "Ada",
  "Adam",
  "Adan",
  "Adana",
  "Adar",
  "Addams",
  "Adderley",
  "Addie",
  "Addison",
  "Adela",
  "Adelaide",
  "Adele",
  "Adeline",
  "Aden",
  "Adenauer",
  "Adhara",
  "Adidas",
  "Adirondack",
  "Adkins",
  "Adler",
  "Adolf",
  "Adolfo",
  "Adolph",
  "Adonis",
  "Adonises",
  "Adrian",
  "Adriana",
  "Adriatic",
  "Adrienne",
  "Advent",
  "Adventist",
  "Advil",
  "Aegean",
  "Aelfric",
  "Aeneas",
  "Aeneid",
  "Aeolus",
  "Aeroflot",
  "Aeschylus",
  "Aesculapius",
  "Aesop",
  "Afghan",
  "Afghanistan",
  "Africa",
  "African",
  "Afrikaans",
  "Afrikaner",
  "Afro",
  "Afrocentrism",
  "Agamemnon",
  "Agassi",
  "Agassiz",
  "Agatha",
  "Aggie",
  "Aglaia",
  "Agnes",
  "Agnew",
);

my %toplevels_to_lvis = (
    ( map { $_ => 1 } @toplevels[0..7]),
    ( map { $_ => 2 } @toplevels[8..15]),
    ( map { $_ => 3 } @toplevels[16..23]),
);

my @data_records;
for my $r (@toplevels) {
    push @data_records, [ join('|' => ('', $r)), $toplevels_to_lvis{$r}, 0 ];
    for my $s (@seconds) {
        push @data_records, [ join('|' => ('', $r, $s)), $toplevels_to_lvis{$r}, 0 ];
        for my $t (@thirds) {
            push @data_records, [ join('|' => ('', $r, $s, $t)), $toplevels_to_lvis{$r}, 1 ];
        }
    }
}

my $self;
eval {
  $self = Parse::Taxonomy::MaterializedPath->new( {
      components  => {
          fields          => [ @input_columns ],
          data_records    => [ @data_records  ],
      },
      path_col_sep => '|',
  } );
};
croak "$@" if $@;

my $adjacentified = $self->adjacentify();

my $csv_file = $self->write_adjacentified_to_csv( {
    adjacentified => $adjacentified,
    csvfile => './letters.csv',
} );

say "\nFinished: created $csv_file";
