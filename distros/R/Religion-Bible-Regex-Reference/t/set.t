use t::TestConfig;
use Data::Dumper;
use utf8;
plan tests => 1 * blocks();

run {
    my $block = shift;
    my $c = new Religion::Bible::Regex::Config($block->yaml); 
    my $r = new Religion::Bible::Regex::Builder($c);
    my $ref = new Religion::Bible::Regex::Reference($c, $r);
    $ref->set($block->init);
    my $hash = $ref->{'reference'};
#    print Dumper $hash;
    my $result = $block->result;
#    print Dumper $ref->{reference};
    is_deeply($hash, $result, $block->name);
};

__END__

=== Parse LCVLCV - Ge 1:1-Ex 2:5
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: Genèse
      Abbreviation: Ge
  2: 
    Match:
      Book: ['Exode']
      Abbreviation: ['Ex']
    Normalized: 
      Book: Exode
      Abbreviation: Ex
regex:
  livres_avec_un_chapitre: (?:Ab|Abdias|2Jn|2Jean|Phm|Philemon|Philémon|Jud|Jude|3Jn|3Jean)

--- init eval
{b=>'Ge',s2=>' ',c=>'1',cvs=>':',v=>'1', dash=>'-',b2=>'Ex',s7=>' ',c2=>'2',v2=>'5'}
--- result eval
{
    'data' => {
	'key' => '1',
	'c' => '1',
	'v' => '1',
	'key2' => '2',
	'c2' => '2',
	'v2' => '5',
    },
    'original' => {
	'b'  => 'Ge',
	'c'  => '1',
	'v'  => '1',
	'b2' => 'Ex',	    
	'c2' => '2',
	'v2' => '5',
    },
    'spaces' => {
	's2' => ' ',
	's7' => ' ',
    },
    'info' => {
	'cvs' =>':',
	'dash' => '-',
    }
}
=== Parse LCVLCV - Ge 1:1-Ex 2:5
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: Genèse
      Abbreviation: Ge
  2: 
    Match:
      Book: ['Exode']
      Abbreviation: ['Ex']
    Normalized: 
      Book: Exode
      Abbreviation: Ex
regex:
  livres_avec_un_chapitre: (?:Ab|Abdias|2Jn|2Jean|Phm|Philemon|Philémon|Jud|Jude|3Jn|3Jean)

--- init eval
{b=>'Ge',s2=>' ',c=>'1',cvs=>':',v=>'1', dash=>'-',b2=>'Ex',s7=>' ',c2=>'2',v2=>'5'}
--- result eval
{
    'data' => {
	'key' => '1',
	'c' => '1',
	'v' => '1',
	'key2' => '2',
	'c2' => '2',
	'v2' => '5',
    },
    'original' => {
	'b'  => 'Ge',
	'c'  => '1',
	'v'  => '1',
	'b2' => 'Ex',	    
	'c2' => '2',
	'v2' => '5',
    },
    'spaces' => {
	's2' => ' ',
	's7' => ' ',
    },
    'info' => {
	'cvs' =>':',
	'dash' => '-',
    }
}
=== Parse LCLCV - Ge 1-Ex 2:5b
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: Genèse
      Abbreviation: Ge
  2: 
    Match:
      Book: ['Exode']
      Abbreviation: ['Ex']
    Normalized: 
      Book: Exode
      Abbreviation: Ex

--- init eval
{b=>'Ge',s2=>' ',c=>'1', dash=>'-',b2=>'Ex',s7=>' ',c2=>'2',cvs=>':',v2=>'5b'}
--- result eval 
{
    'data' => {
	'key' => '1',
	'c' => '1',
	'key2' => '2',
	'c2' => '2',
	'v2' => '5',
	'v2letter' => 'b',
    },
    'original' => {
	'b' => 'Ge',
	'c' => '1',
	'b2' => 'Ex',
	'v2' => '5b',
	'c2' => '2'
    },
    'spaces' => {
	's2' => ' ',
	's7' => ' ',
    },
    'info' => {
	'cvs' =>':',
	'dash' => '-',
    }
}

=== Parse LCLC - Ge 1-Ex 2
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: Genèse
      Abbreviation: Ge
  2: 
    Match:
      Book: ['Exode']
      Abbreviation: ['Ex']
    Normalized: 
      Book: Exode
      Abbreviation: Ex

--- init eval
{b=>'Ge',s2=>' ',c=>'1', dash=>'-',b2=>'Ex',s7=>' ',c2=>'2'}
--- result eval
{
    'data' => {
	'key' => '1',
	'c' => '1',
	'key2' => '2',
	'c2' => '2'
    },
    'original' => {
	'b' => 'Ge',
	'c' => '1',
	'b2' => 'Ex',
	'c2' => '2'
    },
    'spaces' => {
	's2' => ' ',
	's7' => ' ',
    },
    'info' => {
	'dash' => '-',
    }
}

=== Parse LC - Ge 1
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: Genèse
      Abbreviation: Ge

--- init eval
{b=>'Ge', s2=>' ', c=>'1'}
--- result eval
{
    'data' => {
	'key' => '1',
	'c' => '1',
    },
    'original' => {
	'b' => 'Ge',
	'c' => '1',
    },
    'spaces' => {
	's2' => ' ',
    },
}
=== Parse LCVCV - Ge 1:1-2:5
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: Genèse
      Abbreviation: Ge
    
--- init eval
{b=>'Ge',s2=>' ',c=>'1',cvs=>':',v=>'1', dash=>'-',c2=>'2',v2=>'5'}
--- result eval
{
    'data' => {
	'key' => '1',
	'c' => '1',
	'v' => '1',
	'c2' => '2',
	'v2' => '5',
    },
    'original' => {
	'b' => 'Ge',
	'c' => '1',
	'v' => '1',
	'v2' => '5',
	'c2' => '2'
    },
    'spaces' => {
	's2' => ' ',
    },
    'info' => {
	'cvs' =>':',
	'dash' => '-',
    }
}
=== Parse LCVCV - Ge 1:1-2:5
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: Genèse
      Abbreviation: Ge
    
--- init eval
{b=>'Ge',s2=>' ',c=>'1',cvs=>':',v=>'1', dash=>'-',c2=>'2',v2=>'5'}
--- result eval
{
    'data' => {
	'key' => '1',
	'c' => '1',
	'v' => '1',
	'c2' => '2',
	'v2' => '5',
    },
    'original' => {
	'b' => 'Ge',
	'c' => '1',
	'v' => '1',
	'v2' => '5',
	'c2' => '2'
    },
    'spaces' => {
	's2' => ' ',
    },
    'info' => {
	'cvs' =>':',
	'dash' => '-',
    }
}
=== Parse LCCV - Ge 1-2:5a
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: Genèse
      Abbreviation: Ge
--- init eval
{b=>'Ge',s2=>' ',c=>'1', dash=>'-',c2=>'2',cvs=>':',v2=>'5a'}
--- result eval 
{
    'data' => {
	'key' => '1',
	'c' => '1',
	'c2' => '2',
	'v2' => '5',
	'v2letter' => 'a',
    },
    'original' => {
	'b' => 'Ge',
	'c' => '1',
	'v2' => '5a',
	'c2' => '2'
    },
    'spaces' => {
	's2' => ' ',
    },
    'info' => {
	'cvs' =>':',
	'dash' => '-',
    }
}

=== Parse LCC - Ge 1-2
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: Genèse
      Abbreviation: Ge

--- init eval
{b=>'Ge',s2=>' ',c=>'1', dash=>'-',c2=>'2'}
--- result eval
{
    'data' => {
	'key' => '1',
	'c' => '1',
	'c2' => '2'
    },
    'original' => {
	'b' => 'Ge',
	'c' => '1',
	'c2' => '2'
    },
    'spaces' => {
	's2' => ' ',
    },
    'info' => {
	'dash' => '-',
    }
}

=== Parse LC - Ge 1
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: Genèse
      Abbreviation: Ge

--- init eval
{b=>'Ge', s2=>' ', c=>'1'}
--- result eval
{
    'data' => {
	'key' => '1',
	'c' => '1',
    },
    'original' => {
	'b' => 'Ge',
	'c' => '1',
    },
    'spaces' => {
	's2' => ' ',
    },
}

=== Parse CVCV - 1:1-2:5
--- yaml
---
--- init eval
{c=>'1',cvs=>':',v=>'1', dash=>'-',c2=>'2',v2=>'5'}
--- result eval
{
    'data' => {
	'c' => '1',
	'v' => '1',
	'c2' => '2',
	'v2' => '5',
    },
    'original' => {
	'c' => '1',
	'v' => '1',
	'c2' => '2',
	'v2' => '5',
    },
    'info' => {
	'cvs' =>':',
	'dash' => '-',
    }
}

=== Parse CVCV - 1:1-2:5
--- yaml
---
--- init eval
{c=>'1',cvs=>':',v=>'1', dash=>'-',c2=>'2',v2=>'5'}
--- result eval
{
    'data' => {
	'c' => '1',
	'v' => '1',
	'c2' => '2',
	'v2' => '5',
    },
    'original' => {
	'c' => '1',
	'v' => '1',
	'c2' => '2',
	'v2' => '5',
    },
    'info' => {
	'cvs' =>':',
	'dash' => '-',
    }
}
=== Parse CCV - 1-2:5a
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: Genèse
      Abbreviation: Ge

--- init eval
{c=>'1', dash=>'-',c2=>'2',cvs=>':',v2=>'5a'}
--- result eval
{
    'data' => {
	'c' => '1',
	'c2' => '2',
	'v2' => '5',
	'v2letter' => 'a',
    },
    'original' => {
	'c' => '1',
	'c2' => '2',
	'v2' => '5a',
    },
    'info' => {
	'cvs' =>':',
	'dash' => '-',
    }
}
=== Parse CC - 1-2
--- yaml
---
--- init eval
{c=>'1', dash=>'-',c2=>'2'}
--- result eval
{
    'data' => {
	'c' => '1',
	'c2' => '2'
    },
    'original' => {
	'c' => '1',
	'c2' => '2'
    },
    'info' => {
	'dash' => '-',
    }
}
=== Parse C - 2
--- yaml
---
--- init eval
{c=>'1'}
--- result eval
{
    'data' => {
	'c' => '1',
    },
    'original' => {
	'c' => '1',
    }
}
=== Parse VV - 1-2
--- yaml
---
--- init eval
{v=>'1', dash=>'-',v2=>'2'}
--- result eval
{
    'data' => {
	'v' => '1',
	'v2' => '2',
    },
    'original' => {
	'v' => '1',
	'v2' => '2',
    },
    'info' => {
	'dash' => '-',
    }
}
=== Parse VV - 1-2
--- yaml
---
--- init eval
{v=>'1a', dash=>'-',v2=>'2b'}
--- result eval
{
    'data' => {
	'v' => '1',
	'vletter' => 'a',
	'v2' => '2',
	'v2letter' => 'b',
    },
    'original' => {
	'v' => '1a',
	'v2' => '2b',
    },
    'info' => {
	'dash' => '-',
    }
}
=== Parse V - 2
--- yaml
---
--- init eval
{v=>'1'}
--- result eval
{
    'data' => {
	'v' => '1',
    },
    'original' => {
	'v' => '1',
    }
}
=== Parse V - 1b
--- yaml
---
--- init eval
{v=>'1a'}
--- result eval
{
    'data' => {
	'v' => '1',
	'vletter' => 'a',
    },
    'original' => {
	'v' => '1a',
    }
}
=== Parse a book that has only one chapter - Jude 4
--- yaml
---
books:
  65: 
    Match:
      Book: ['Jude']
      Abbreviation: ['Ju']
    Normalized: 
      Book: Jude
      Abbreviation: Ju
regex:
  livres_avec_un_chapitre: (?:Ab|Abdias|2Jn|2Jean|Phm|Philemon|Philémon|Jud|Jude|3Jn|3Jean)

--- init eval
{b=>'Jude',s2=>' ',v=>'4'}
--- result eval
{
    'data' => {
	'key' => '65',
	'c' => '1',
	'v' => '4',
    },
    'original' => {
	'b'  => 'Jude',
	'c' => '1',
	'v'  => '4',
    },
    'spaces' => {
	's2' => ' ',
    },
    'info' => {
        'cvs' =>':',
    }

}
=== Parse a book that has only one chapter - Jude 4
--- yaml
---
books:
  65: 
    Match:
      Book: ['Jude']
      Abbreviation: ['Ju']
    Normalized: 
      Book: Jude
      Abbreviation: Ju
regex:
  livres_avec_un_chapitre: (?:Ab|Abdias|2Jn|2Jean|Phm|Philemon|Philémon|Jud|Jude|3Jn|3Jean)

--- init eval
{b=>'Jude',s2=>' ',v=>'4c'}
--- result eval
{
    'data' => {
	'key' => '65',
	'c' => '1',
	'v' => '4',
	'vletter' => 'c',
    },
    'original' => {
	'b'  => 'Jude',
	'c' => '1',
	'v'  => '4c',
    },
    'spaces' => {
	's2' => ' ',
    },
    'info' => {
        'cvs' =>':',
    }

}
=== Parse LCVLCV - Ge 1:1-Ex 2:5 - using keys instead of books and abbreviations
--- yaml
---
books:
  1: 
    Match:
      Book: ['Genèse', 'Genese']
      Abbreviation: ['Ge']
    Normalized: 
      Book: Genèse
      Abbreviation: Ge
  2: 
    Match:
      Book: ['Exode']
      Abbreviation: ['Ex']
    Normalized: 
      Book: Exode
      Abbreviation: Ex
regex:
  livres_avec_un_chapitre: (?:Ab|Abdias|2Jn|2Jean|Phm|Philemon|Philémon|Jud|Jude|3Jn|3Jean)

--- init eval
{key=>'1',s2=>' ',c=>'1',cvs=>':',v=>'1', dash=>'-',key2=>'2',s7=>' ',c2=>'2',v2=>'5'}
--- result eval
{
    'data' => {
	'key' => '1',
	'c' => '1',
	'v' => '1',
	'key2' => '2',
	'c2' => '2',
	'v2' => '5',
    },
    'original' => {
	'c'  => '1',
	'v'  => '1',
	'c2' => '2',
	'v2' => '5',
    },
    'spaces' => {
	's2' => ' ',
	's7' => ' ',
    },
    'info' => {
	'cvs' =>':',
	'dash' => '-',
    }
}
