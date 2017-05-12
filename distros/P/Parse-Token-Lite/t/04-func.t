use strict;
use warnings;
use lib qw(./lib ../lib);
use Test::More tests => 6;                      # last test to print
use Data::Printer;

BEGIN{
	use_ok("Parse::Token::Lite");
}


my %rules = (
    MAIN=>[
	{name=>'SET', re=>qr/\$\w+\s*=\s*.+?;?/,
     func=>
		sub{
			my($lexer,$rule) = @_;
            my $matched = $rule->data;
			if( $matched =~ /(.+?)\s*=\s*(.+?);?/ ){
				return {var=>$1, val=>$2};
			}
		}
	},
	{name=>'DELIMETER', re=>qr/\W/},
    ]
);

my $lexer = Parse::Token::Lite->new(rulemap=>\%rules);
eval{ 
	$lexer->from(q{$a=2;$b=3;});
};

fail('Check Implemented') if $@;

my @r;

@r = $lexer->nextToken;
is $r[1]->{var},'$a';
is $r[1]->{val},'2';

@r = $lexer->nextToken;
is $r[1]->{var},'$b';
is $r[1]->{val},'3';

is $lexer->eof,1,'check EOF';

done_testing;
