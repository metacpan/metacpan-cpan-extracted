package Taxon::Parse::Author;

use strict;
use warnings;

use parent qw( Taxon::Parse );

our $VERSION = '0.013';

sub init {
  my $self = shift;

  my $p = $self->{pattern_parts};

  # a_ - patterns for author names
  $p->{apostrophe} = qr/[\'´`\x{2019}]/xms;
  $p->{compound_connector} = qr/[-]/xms;
  $p->{prefix} = qr/
    (?:
      [vV](?:an)(?:[ -](?:den|der))?
      |An \s+ der
      |[vV]on (?:[ -](?:den|der|dem))?
      |v\.?
      |[vV]\.?\s*d\.?\s*
      |(?:delle|del|[Dd]es|De|de|di|Di|da|du|N)[`' _]?
      |le 
      |[Dd] $p->{apostrophe}
      |[Dd]e (?:[ ][lL]a)? 
      |d\.
      |Mac
      |Mc
      |Le
      |St\.?
      |Ou
      |O'
      |'t
      |\?
    )
  /xms;
  $p->{suffix} = qr/
    (?:
      (?:
        f|fil|j|jr|jun|junior|sr|sen|senior|ms|\?
      )
      \.?
    )
  /xms;
  $p->{team_connector} = qr/
    (?:
      \s*
      (?: &|,|; )
      \s*
    )
    |
    (?:
      \s+
      (?: et|and|und|y )
      \s+
    )
  /xms;
  $p->{reference_relation} = qr/
    (?:
      ex\.?
      |in
      |sensu
      |emend\.?
      |sec\.?
    )
  /xms;  
  $p->{word}     = qr/
    [\p{IsUpper}\'][\p{IsLower}\'´`\x{2019}]+
  /xms;
  $p->{compound} = qr/
    $p->{word}
    $p->{compound_connector}
    $p->{word}
  /xms;
  $p->{initial} = qr/
    \b[\p{IsUpper}\'´`][\p{IsLower}]{0,2}[\.]    
  /xms;
  $p->{abbreviation}   = qr/
    (?:
      (?:
        $p->{prefix}\s*
      )? 
      (?:
        (?:
          [\p{IsUpper}\'´`][\p{IsLower}]{0,9}[\.]?
        )(?:
          [-]
          [\p{IsUpper}\'´`][\p{IsLower}]{0,9}[\.]?
        )?
      )
      | \b DC[\.]
      | hort\. \s* (?: [\p{IsUpper}\p{IsLower}][\p{IsLower}]{0,9}[\.]? )?
    )
  /xms;
  $p->{abbreviated_name} = qr/
    (?: 
      $p->{abbreviation}
    )(?:
      \s*(?:
        $p->{abbreviation}
        |$p->{compound}
        |$p->{word}
      )
    )*
    (?:
        \s*
        $p->{suffix}
    )?  
  /xms;
  $p->{name}     = qr/
    (?:
      (?:
        $p->{prefix}\s*
      )? 
      (?:
        $p->{compound}
        |$p->{word}
      )
      (?:
        \s*$p->{suffix}
      )? 
    )(?:
      \s*
      (?:
        $p->{prefix}\s*
      )? 
      (?:
        $p->{compound}
        |$p->{word}
      )
      (?:
        \s*$p->{suffix}
      )?
    )*
  /xms;
  $p->{'list'}   = qr/
    (?:
      $p->{name}
      |$p->{abbreviated_name}
    )
    (?:
      \s*[,]\s*
      (?:
      $p->{name}
      |$p->{abbreviated_name}
      )
    )*
    (?:
      (?:
        $p->{'team_connector'}
      )
      (?:
        al\.?
        |$p->{name}
        |$p->{abbreviated_name}
      )
    )*
  /xms;
  $p->{year}   = qr/
    (?:
      1[5-9]\d\d  # 1500 .. 1999
      |
      20\d\d      # 2000 .. 2099
    )
    (?:[a-zA-Z])?
    (?:
      (?: 
        [\/-]       # to
        | \s* & \s*
      )
      \d{2,4}
    )?
  /xms;
  $p->{date} = qr/
    (?:
      [\(\[]\s*
      $p->{year}
      \s*[\)\]]
    )
    |$p->{year}
  /xms;
  $p->{phrase} = qr/
    (?:
      $p->{list}
      |$p->{name}
      |$p->{abbreviated_name}
    )(?:
      [\s,]*
      $p->{date}
    )?
  /xms;
  $p->{non} = qr/
    (?:
    (?:
      \s*\,?\s*
      [\[(]? \s*
      (?:
        p \.? \s* p \.?
        | non .*
        | not .*
        | nec .*
        | nom\. \s* illeg\.?
        | nom\. \s* inval\.?
        | nom\. \s* nud\.?
        | nomen \s+ nudum
        | nom\. \s* nov\.
        | nomen \s+ novum
        | comb\. \s* illeg\.
        | nom\. \s* rej\.
        | nom\. \s* illegit\.
        | nom\. \s* cons\.
        | anon\. \s* ined\.
        | anon\.
        | auct\. \s* mult\.
        | auct\. \s* americ\.
        | pro \s+ sp\.?
        | pro \s+ hybr\.?
      )
      \s* [\])]?
    )?
    [.,;\s]*
    )?
  /xms;

  $p->{plain}  = qr/
    $p->{phrase}
    (?:
      \s*\b
      $p->{reference_relation}\s+
      $p->{phrase}
    ){0,3}
  /xms;  
  $p->{bracketed}  = qr/
    [\(\[]\s*
    $p->{plain}
    \s*[\)\]]
  /xms;
  $p->{full}   = qr/
    (?:
      $p->{bracketed}\s*
    )?
    (?:
      $p->{reference_relation}
    )?
    (?:
      \s*
      $p->{plain}
    )?
    (?:
      \s*
      $p->{date}
    )?
    (?:
      $p->{non}
    )?
  /xms;

  $p->{authorcaptured}   = qr/
    (?<basionymauthor>
      $p->{bracketed}\s*
    )?
    (?<reference_relation>
      $p->{reference_relation}
    )?
    (?<author>
      \s*
      $p->{plain}
    )?
    (?<date>
      \s*
      $p->{date}
    )?
    (?<non>
      $p->{non}
    )?
  /xms;

  
  my $patterns = $self->{patterns};
  my @patterns = qw< full abbreviated_name authorcaptured>;
  map { $patterns->{$_} = $p->{$_} } @patterns;
  $self->{order}->{authorcaptured} = [qw< basionymauthor reference_relation author date non>];  
}


1;
