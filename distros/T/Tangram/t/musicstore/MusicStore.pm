
package MusicStore;

use CD;
use Tangram qw(:core :compat_quiet);
use Tangram::Schema;
use Tangram::IntrArray;
use Tangram::TimePiece;
use Tangram::IntrSet;
use Tangram::Set;
use Tangram::IDBIF;

our $schema =
   ({
    classes => [
       CD => {
         fields => {
            string => [ qw(title) ],
            timepiece => [ qw(publishdate) ],
            iarray  => { songs => { class => 'CD::Song',
                                    aggreg => 1,
                                    back => 'cd',
                                  },
                       },
         }
       },
       CD::Song => {
         fields => {
            string => [ qw(name) ],
         }
       },
       CD::Artist => {
         abstract => 1,
         fields => {
            string => [ qw(name popularity) ],
            iset => { cds => { class => 'CD',
                               aggreg => 1,
                               back => 'artist' },
                             },
		   },
       },
       CD::Person => {
         bases  => [ "CD::Artist" ],
         fields => {
            string => [ qw(gender haircolor) ],
            timepiece => [ qw(birthdate) ],
         }
       },
       CD::Band => {
         bases  => [ "CD::Artist" ],
         fields => {
            timepiece => [ qw(creationdate enddate) ],
            set => { members => { class => 'CD::Person',
				  table => "artistgroup",
				},
                   },
	    },
       },
    ],
});


our $pixie_like_schema =
    ({
      classes =>
      [
       HASH =>
       {
	table => "objects",
	sql => { sequence => "oid_sequence" },
	fields => { idbif => undef },
       },
      ],
     });

use Storable qw(dclone);

our $new_schema = dclone $schema;

push @{ $new_schema->{classes} },
    (
     "CD::Compilation" =>
     {   # CD sub-class with an author per track
      bases => [ qw(CD) ],
     },

     "CD::Compilation::Song" =>
      {
       bases => [ qw(CD::Song) ],
       fields => {
		  ref => { artist => { class => "CD::Artist" },
			 },
		 },
      },
    );

# munge all the table names
$new_schema->{normalize} = sub {
    my $class_name = shift;
    (my $table_name = $class_name) =~ s{::}{_}g;
    $table_name =~ s{^}{new_};
    return $table_name;
};

# normalisation isn't applied to manually configured names!
$new_schema->{classes}[9]{fields}{set}{members}{table}
    = "new_artistgroup";

$new_schema->{control} = "new_Tangram";

sub AUTOLOAD {
    my ($func) = ($AUTOLOAD =~ m/.*::(.*)$/);
    return Tangram::Schema->new(${$func})
}

1;
