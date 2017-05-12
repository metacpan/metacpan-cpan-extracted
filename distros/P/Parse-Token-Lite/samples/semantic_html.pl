#!/usr/bin/env perl 
use lib './lib';
use Parse::Token::Lite;
use LWP::UserAgent;
use LWP::Simple;
#use strict;
my $urlpat = qr@https?://[a-zA-Z0-9_/\.\%&\?#=\-\+\(\)]+@;
my $proppat1 = qr@[\w_-]+\s*=\s*'@;
my $proppat2 = qr@[\w_-]+\s*=\s*"@;
my $proppat3 = qr@[\w_-]+\s*=\s*@;
my $numpat = qr@\d[\d,\.]*\d?@;
my $puncpat= qr@[\!\@#\$\%^&\*\(\)_\-=\+/{}\[\]>'"`]@;
sub on_error{
    my ($parser,$token) = @_;
#  die $_[1]->data;
}
my %rules = (
    MAIN=>[
      {name=>HTML_ENTITY_VAL, re=>qr/&\S+?;/},
      {name=>HTML_COMMENT, re=>qr/<!--.+?-->/ms},
      {name=>HTML_DOCTYPE, re=>qr/<!.+?>/ms},
      {name=>HTML_STYLE, re=>qr@<style.+?</style>@ms},
      {name=>HTML_JSBLOCK, re=>qr@<script.+?</script>@ms},
      {name=>TAG_START_IN, re=>qr/<\w+/, state=>[qw(+TAG_IN)] },
      {name=>TAG_END, re=>qr@</\w+>@ },
      {name=>NUM_VAL, re=>$numpat},
      {name=>URL_VAL, re => $urlpat },
      {name=>WHITE_SPACE, re=>qr/\s+/ },
      {name=>PUNC_VAL, re => qr/$puncpat/ },
      {name=>TEXT_VAL, re => qr/[^<]+/},
    ],
    TAG_IN=>[
      {name=>TAG_PROP_IN1_VAL, re=>$proppat1, state=>['+PROP_IN1']},
      {name=>TAG_PROP_IN2_VAL, re=>$proppat2, state=>['+PROP_IN2']},
      {name=>TAG_PROP_IN3_VAL, re=>$proppat3, state=>['+PROP_IN3']},
      {name=>TAG_PROP_SINGLE_VAL, re=>qr@\w+@},
      {name=>TAG_START_OUT, re=>qr@/?>@, state=>[qw(-TAG_IN)]},
      {name=>TAG_WHITE_SPACE, re=>qr/\s+/ },
      {name=>TAG_ERR, re => qr/.+/, func=>\&on_error },
    ],
    PROP_IN1=>[
      {name=>URL_VAL, re => $urlpat },
      {name=>PROP1_VAL, re=>qr@[^']+@},
      {name=>PROP1_OUT, re=>qr@'@, state=>['-PROP_IN1']},
      {name=>PROP1_ERR, re => qr/.+/, func=>\&on_error },
    ],
    PROP_IN2=>[
      {name=>URL_VAL, re => $urlpat },
      {name=>PROP2_VAL, re=>qr@[^"]+@},
      {name=>PROP2_OUT, re=>qr@"@, state=>['-PROP_IN2']},
      {name=>PROP2_ERR, re => qr/.+/, func=>\&on_error },
    ],
    PROP_IN3=>[
      {name=>URL_VAL, re => $urlpat },
      {name=>PROP3_VAL, re=>qr@[^>\s]+@},
      {name=>PROP3_OUT, re=>qr@[^>\S]+@, state=>['-PROP_IN3']},
      {name=>PROP3_TAG_OUT, re=>qr@>@, state=>['-PROP_IN3','-TAG_IN']},
      {name=>PROP3_ERR, re => qr/.+/, func=>\&on_error },
    ],

);

my $parser = Parse::Token::Lite->new(rulemap=>\%rules);


my $html = <<'HTML';
<html>
  <body>
  ABC
  <img src="http://metacpan.org">
  </body>
</html>

HTML



my $ua = LWP::UserAgent->new;
if( $ARGV[0] ){
  $html = $ua->get($ARGV[0])->decoded_content;
}
else{
  local($/);
  undef($/);
  $html = <STDIN>;
}
print "START\n";
$parser->from($html);

my @tokens;
while( ! $parser->eof ){
    my($token, @rest) = $parser->nextToken;
    my $state_tag = $token->rule->name;
    my $data = $token->data;
    my $d = 1;
#    $d = $state_tag =~ /VAL$/;
#    $d = $state_tag =~ /SIGIL/;
#    $d = $state_tag =~ /^URL/;
#    $d = $state_tag =~ /NUM_VAL/;

    if( $d ){
      push(@tokens, $data);
      #printf "%-20s\t%s\n",$state_tag,$data;
      #print "\n[ ".join(">",@{$parser->state_stack})." ]\n";
    }
}
use YAML;
print Dump( \@tokens, {pretty=>1});
__DATA__

