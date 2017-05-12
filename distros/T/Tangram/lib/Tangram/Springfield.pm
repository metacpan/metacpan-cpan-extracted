

use strict;

package SpringfieldObject;

sub new
  {
    my $class = shift;
    bless { @_ }, $class;
  }

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s{.*::}{};
    if ( @_ ) {
	$self->{$AUTOLOAD} = shift;
    } else {
	$self->{$AUTOLOAD};
    }
}

package Person;
use vars qw(@ISA);
 @ISA = qw( SpringfieldObject );

package NaturalPerson;
use vars qw(@ISA);
 @ISA = qw( Person );

package LegalPerson;
use vars qw(@ISA);
 @ISA = qw( Person );

package Address;
use vars qw(@ISA);
 @ISA = qw( SpringfieldObject );

package Tangram::Springfield;
use Exporter;
use vars qw(@ISA);
 @ISA = qw( Exporter );
use vars qw( @EXPORT $schema $raw_schema );

@EXPORT = qw( $schema );

$schema = {
	   classes =>
	   {
	    Person =>
	    {
	     id => 1,
	     abstract => 1,
	     fields =>
	     {
	      iarray =>
	      {
	       addresses => { class => 'Address',
			      aggreg => 1 }
	      }
	     }
	    },

	    Address =>
	    {
	     id => 2,
	     fields =>
	     {
	      string => [ qw( type city ) ],
	     }
	    },

	    NaturalPerson =>
	    {
	     id => 3,
	     bases => [ qw( Person ) ],
	     fields =>
	     {
	      string   => [ qw( firstName name ) ],
	      int      => [ qw( age ) ],
	      ref      => [ qw( partner ) ],
	      array    => { children => 'NaturalPerson' },
	     },
	    },

	  LegalPerson =>
	  {
	   id => 4,
	   bases => [ qw( Person ) ],

	   fields =>
	   {
	    string   => [ qw( name ) ],
	    ref      => [ qw( manager ) ],
	   },
	  },
	 }
	} );

sub schema {
    shift if @_ and UNIVERSAL::isa($_[0], __PACKAGE__);

    if ( my @classes = @_ ) {
	my %classes = map { $_ => 1 } @classes;
	my @gonners;
	while ( my $class = each %{$schema->{classes}}) {
	    push @gonners, $class unless exists $classes{$class};
	}
	delete @{$schema->{classes}}{@gonners} if @gonners;
    }

    Tangram::Schema->new($schema);
}

1;
