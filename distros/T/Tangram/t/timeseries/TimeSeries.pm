
package TimeSeries;

use Tangram::Schema;
use Class::Tangram::Generator;
use Tangram::Type::Date::TimeHiRes;
use Tangram::Type::Interval::HiRes;

our $schema =
    { classes =>
      [ Event => { time_hires => { when => undef },
		   string => { who => undef, },
		   real => { clams => undef, },
		   iarray => { subsequent => { class => "Item" } },
		 },
	Item => { interval_hires => { delta => undef,
				    },
		  string => { what => undef, },
		},
      ],
    };

sub deploy {
    eval { &retreat };
    $DBConfig::dialect->deploy($tangram_schema, DBConfig::cparm,
			       );
}

sub retreat {
    $DBConfig::dialect->retreat($tangram_schema, DBConfig::cparm,
				($^S ? ({ RaiseError => 1,
					  PrintError => 0 }) : () )
			       );
}

Class::Tangram::Generator->new($schema);

our $tangram_schema = Tangram::Schema->new($schema);

