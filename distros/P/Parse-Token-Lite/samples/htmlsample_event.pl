#!/usr/bin/env perl 
use lib './lib','../lib';
use Parse::Token::Lite;

my %rules = (
    MAIN=>[
	    { name=>'OPENTAG', state=>['+TAG'], re=> qr/<\w+/ },
	    { name=>'CLOSETAG',	re=> qr@</[^>]+?>@ },
        { name=>'SPC' ,re=> qr/[\n\s]+/ },
        { name=>'STR' ,re=> qr/\w+/ },
        { name=>'STR2' ,re=> qr/\W+/ },
    ],
    TAG=>[
        { name=>'SPC', re=>qr/\s+/ },
        { name=>'NEW', re=>qr/\n+/ },
        { name=>'LEFT',state=>['+RIGHT'], re=>qr/\w+\s*=/ },
	    
        { name=>'TAGOUT',state=>['-TAG'], re=>qr/>/ },
    ],
	RIGHT=>[
    	{ name=>'RIGHT', state=>['+Q2'] , re=> qr/"/ },
	    { name=>'RIGHT', state=>['+Q1'] , re=> qr/'/ },
    ],
    Q2=>[
        { name=>'VAL', re => qr/[^"]+/, func=>\&show},
        { state=>['-Q2','-RIGHT'], re => qr/"/},
    ],
    Q1=>[
        { name=>'VAL', re => qr/[^']+/, func=>\&show},
        { state=>['-Q1','-RIGHT'], re => qr/'/},
    ],

	
);


my $html = <<END;
<html>
	<body>
		<a href="http://www.daum.net">daum</a>
		<a href='http://www.daum.net'>daum</a>
		<a href='http://www.daum.net/"abc"'>daum</a>
		<a href="http://www.daum.net/'abc'">daum</a>
		<a href="http://www.daum.net/abc">daum</a>
	</body>
</html>
END

sub show{
    my ($parser,$token) = @_;
	print $token->rule->name." : ".$token->data."\n";
}

my $parser = Parse::Token::Lite->new(rulemap=>\%rules);
$parser->from($html);

$parser->parse;
