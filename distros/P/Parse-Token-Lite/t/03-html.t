use strict;
use warnings;
use lib qw(./lib);
use Test::More tests => 2;                      # last test to print
use Data::Printer;

BEGIN{
	use_ok("Parse::Token::Lite");
}


my $rules = {
    MAIN=>[
        {name=>'URL',re=>qr@http://[a-zA-Z-_\%0-9/#=&\?\.]+@},
        {name=>'WS',re=>qr/\s+/},
        {name=>'DELI',re=>qr@["'<>/=]+@},
        {name=>'WORD',re=>qr@[^"'<>/=\s]+@},
    ]
};

my $html = <<END;
<html>
<body>
<a href='http://mabook.com'>mabook</a>
</body>
</html>
END

my $lexer = Parse::Token::Lite->new(rulemap=>$rules);
$lexer->from($html);
my @token;

my $url;
while(!$lexer->eof){
    @token = $lexer->nextToken;
    if( $token[0]->rule->name eq 'URL'){
        $url = $token[0]->data;
    }
    print $token[0]->rule->name."\t: '".$token[0]->data."'\n";
}
is( $url, 'http://mabook.com', 'detect URL');
done_testing;
