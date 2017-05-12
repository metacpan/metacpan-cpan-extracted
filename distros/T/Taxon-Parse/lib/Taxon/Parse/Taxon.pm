package Taxon::Parse::Taxon;

use strict;
use warnings;
use utf8;

use parent qw( Taxon::Parse );

our $VERSION = '0.013';

sub init {
  my $self = shift;

  my $p = $self->{pattern_parts};

  # l_ - patterns for latin names
  $p->{apostrophe} = qr/[\'´`]/xms;
  $p->{compound_connector} = qr/[-]/xms;
  $p->{NAME_LETTERS} = qr/[A-ZÏËÖÜÄÉÈČÁÀÆŒ]/xms;
  $p->{name_letters} = qr/[a-zïëöüäåéèčáàæœſú]/xms;
 
  
  $p->{word}     = qr/
    \b
    [\p{Latin}]+
    \b
  /xms;
  $p->{compound} = qr/
    $p->{word}
    [-]
    $p->{word}
  /xms;
  $p->{group}    = qr/
    \b
    $p->{NAME_LETTERS}
    $p->{name_letters}+
    \b
    \??
  /xms;
  $p->{epithet}  = qr/
    ×?
    $p->{name_letters}+
    (?:
      [-]?
      $p->{name_letters}+
    )?
  /xms;
  $p->{abbrev}   = qr/
    [\p{Latin}]{1,3}
    [\.]
  /xms;
  $p->{bracketed}    = qr/
    [(\[]
    \s*
    (?:
      $p->{group}
      | $p->{abbrev}
    )
    \s*
    [)\]]
  /xms;
  $p->{infragenus}  = qr/
    (?:
      $p->{bracketed}
      | (?:
      
           (?: ser|subg|sect|trib ) 
           \. \s* $p->{group}
         )
    )
  /xms;
  
  $p->{genus}    = qr/
    $p->{group}
    (?:
      \s*
      $p->{infragenus}
    )?
  /xms;
  $p->{species}  = qr/
    $p->{genus}
    \s+
    $p->{epithet}
  /xms;
  $p->{species_marker} = qr/
    (?:(?:
      subsp
      |ssp
      |var
      |v
      |subvar
      |subv
      |sv
      |forma
      |form
      |fo
      |f
      |subform
      |subf
      |sf
      |cv
      |cf
      |hort
      |m
      |morph
      |nat
      |ab
      |aberration
      |agg
      |aff
      |[xX×]
      |\?
    )\.?)            
  /xms;
  $p->{sensu} = qr/
    (?:
      (?:
        (?:s\.|sensu\b)\s*
        (?:l\.|str\.|latu\b|strictu?\b)
      )
      |
      (?:
        (?: 
          sec\.?
          |sensu
          |[aA]uct\.?(?: \s* \b non)? 
          |non
        )
      )
    )            
  /xms;
  $p->{list}     = qr/
    $p->{group}
    \s*
    (?:
      [,]\s*
      $p->{group}
    )+
  /xms;
  $p->{name}     = qr/
    (?: ["] \s* )?
    $p->{genus}
      (?:
        (?:
          \s+
          $p->{species_marker}
        )?
        \s+
        $p->{epithet}
      )*
      (?: ["] \s* )?
      (?:
        \s+
        $p->{sensu}
      )?
  /xms;
  $p->{namecaptured}     = qr/
    (?: ["] \s* )?
    (?<genus> $p->{genus} )
      (?:
        (?:
          \s+
          (?<species_marker> $p->{species_marker} )
        )?
        \s+
        (?<epithet> $p->{epithet} )
      )*
      (?: ["] \s* )?
      (?:
        \s+
        (?<sensu> $p->{sensu} )
      )?
  /xms;

  
  my $patterns = $self->{patterns};
  my @patterns = qw< name group genus species list epithet namecaptured>;
  map { $patterns->{$_} = $p->{$_} } @patterns;
  $self->{scores} = $self->scores();
  $self->{order}->{namecaptured} = [qw< genus species_marker epithet sensu >];  
}

sub scores {
  my $self = shift;
  
  return {
    group => 0.5,
    species => 1,
    list => 0.75,
    epithet => 0.5,
  };
}

1;
