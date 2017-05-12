use t::TestConfig;
use Data::Dumper;

plan tests => 1 * blocks();

my $yaml = <<"YAML";
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
  65: 
    Match:
      Book: ['Jude']
      Abbreviation: ['Ju']
    Normalized: 
      Book: Jude
      Abbreviation: Ju

regex:
  chapitre_mots: (?:voir aussi|voir|\\(|voir chapitre|\\bde\\b)
  verset_mots: (?:vv?\.|voir aussi v\.)
  livres_avec_un_chapitre: (?:Ab|Abdias|2Jn|2Jean|Phm|Philemon|Philémon|Jud|Jude|3Jn|3Jean)

YAML

my $c = new Religion::Bible::Regex::Config($yaml); 
my $b = new Religion::Bible::Regex::Builder($c);

run {
    my $block = shift;

    # Initialize a new reference
    my $ref = new Religion::Bible::Regex::Reference($c, $b);

    # Parse the reference
    $ref->parse($block->reference, $block->state);

    # Get the raw reference data
    my $result = $ref->{'reference'};

    my $expected = $block->result;
    is_deeply($result, $expected, $block->name);
};

__END__
=== Parse CV - voir 8:15
--- reference chomp
voir 8:15
--- state chomp
CHAPTER
--- result eval
{
    'data' => {
        'c' => '8',
        'v' => '15',
        'context_words' => 'voir',      
    },
    'original' => {
        'c' => '8',
        'v' => '15',
    },
    'spaces' => {
        's2' => ' ',
    },
    'info' => {
        'cvs' =>':',
    }

}

=== Parse LCVLCV - Ge 1:1-Ex 2:5
--- reference chomp
Ge 1:1-Ex 2:5
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
--- reference chomp
Ge 1:1-Ex 2:5
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
=== Parse LCVLC - Ge 1:5-Ex 2
--- reference chomp
Ge 1:5-Ex 2
--- result eval 
{
    'data' => {
	'key' => '1',
	'c' => '1',
	'v' => '5',
	'key2' => '2',
	'c2' => '2',
    },
    'original' => {
	'b' => 'Ge',
	'c' => '1',
	'v' => '5',
	'b2' => 'Ex',
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
--- reference chomp
Ge 1-Ex 2
--- result eval
{
    'data' => {
	'key' => '1',
	'c' => '1',
	'key2' => '2',
	'c2' => '2',
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
--- reference chomp
Ge 1
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
--- reference chomp
Ge 1:1-2:5
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
=== Parse LCCV - Ge 1-2:5
--- reference chomp
Ge 1-2:5
--- result eval 
{
    'data' => {
	'key' => '1',
	'c' => '1',
	'c2' => '2',
	'v2' => '5',
    },
    'original' => {
	'b' => 'Ge',
	'c' => '1',
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

=== Parse LCC - Ge 1-2
--- reference chomp
Ge 1-2
--- result eval
{
    'data' => {
	'key' => '1',
	'c' => '1',
	'c2' => '2',
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
--- reference chomp
Ge 1
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
--- reference chomp
1:1-2:5
--- state chomp
CHAPTER
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
=== Parse CCV - 1-2:5
--- reference chomp
1-2:5
--- state chomp
CHAPTER
--- result eval
{
    'data' => {
	'c' => '1',
	'c2' => '2',
	'v2' => '5',
    },
    'original' => {
	'c' => '1',
	'c2' => '2',
	'v2' => '5',
    },
    'info' => {
	'cvs' =>':',
	'dash' => '-',
    }
}
=== Parse CC - 1-2
--- reference chomp
1-2
--- state chomp
CHAPTER
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
--- reference chomp
1
--- state chomp
CHAPTER
--- result eval
{
    'data' => {
	'c' => '1',
    },
    'original' => {
	'c' => '1',
    },
}
=== Parse VV - 1-2
--- reference chomp
1-2
--- state chomp
VERSE
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
=== Parse V - 2
--- reference chomp
1
--- state chomp
VERSE
--- result eval
{
    'data' => {
	'v' => '1',
    },
    'original' => {
	'v' => '1',
    }
}
=== Parse a book that has only one chapter - Jude 4
--- reference chomp
Jude 4
--- state chomp
VERSE
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
	'cvs' => ':'
    }
}
=== Parse a book that has only one chapter - Jude 1:4
--- reference chomp
Jude 1:4
--- state chomp
VERSE
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
        'cvs' => ':'
    }
}

=== Parse CVCV - voir 1:1-2:5
--- reference chomp
voir 1:1-2:5
--- result eval
{
    'data' => {
	'c' => '1',
	'v' => '1',
	'c2' => '2',
	'v2' => '5',
	'context_words' => 'voir',
    },
    'original' => {
	'c'  => '1',
	'v'  => '1',
	'c2' => '2',
	'v2' => '5',
    },
    'spaces' => {
	's2' => ' ',
    },
    'info' => {
	'cvs' =>':',
	'dash' => '-',
    }
}
=== Parse CCV - voir aussi 1-2:5
--- reference chomp
voir aussi 1-2:5
--- result eval
{
    'data' => {
	'c' => '1',
	'c2' => '2',
	'v2' => '5',
	'context_words' => 'voir aussi',
    },
    'original' => {
	'c' => '1',
	'c2' => '2',
	'v2' => '5',
    },
    'spaces' => {
	's2' => ' ',
    },
    'info' => {
	'cvs' =>':',
	'dash' => '-',
    }
}

=== Parse CCV - voir aussi 1-2:5
--- reference chomp
voir aussi 1-2:5
--- result eval
{
    'data' => {
        'c' => '1',
        'c2' => '2',
        'v2' => '5',
        'context_words' => 'voir aussi',
    },
    'original' => {
        'c' => '1',
        'c2' => '2',
        'v2' => '5',
    },
    'spaces' => {
        's2' => ' ',
    },
    'info' => {
        'cvs' =>':',
        'dash' => '-',
    }
}

=== Parse CV - voir 8:15
--- reference chomp
voir 8:15
--- state chomp
CHAPTER
--- result eval
{
    'data' => {
	'c' => '8',
	'v' => '15',
	'context_words' => 'voir',	
    },
    'original' => {
	'c' => '8',
	'v' => '15',
    },
    'spaces' => {
        's2' => ' ',
    },
    'info' => {
        'cvs' =>':',
    }

}

=== Parse VV - vv. 1-2
--- reference chomp
vv. 1-2
--- state chomp
VERSE
--- result eval
{
    'data' => {
	'v' => '1',
	'v2' => '2',
	'context_words' => 'vv.',	
    },
    'original' => {
	'v' => '1',
	'v2' => '2',
    },
    'spaces' => {
	's2' => ' ',
    },
    'info' => {
	'dash' => '-',
    }
}

=== Parse V - voir aussi v. 1
--- reference chomp
voir aussi v. 1
--- state chomp
VERSE
--- result eval
{
    'data' => {
	'v' => '1',
	'context_words' => 'voir aussi v.',
    },
    'original' => {
	'v' => '1',
    },
    'spaces' => {
	's2' => ' ',
    },
}
