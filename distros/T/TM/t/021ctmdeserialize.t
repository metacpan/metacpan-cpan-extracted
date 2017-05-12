use strict;
use warnings;

use constant DONE => 1;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;

sub _chomp {
    my $s = shift;
    chomp $s;
    return $s;
}

use TM;
use TM::PSI;

sub _parse {
  my $text = shift;
  my $ms = new TM (baseuri => 'tm:');
  use TM::CTM::Parser;
  my $p  = new TM::CTM::Parser (store => $ms);
  my $i  = $p->parse ($text);
  return $ms;
}

sub die_ok {
    my $ctm = shift;
    my $err = shift;
    eval {
	_parse ($ctm);
	fail ("exc: expected $@");
    };
    chomp ($@);
    my $verr = $@;
    $verr =~ s/\n/\n /g; # create blanks/comments on multiline complaints
    like ($@, qr/$err/, "exc: found '$verr'");
}

sub _q_players {
    my $ms = shift;
    my @res = $ms->match (TM->FORALL, @_);
#    warn "res no filter ".Dumper \@res;
    @res = grep ($_ !~ m|^tm:|, map { ref($_) ? ${$_} : $_ } map { @{$_->[TM->PLAYERS]} } $ms->match (TM->FORALL, @_));
#    warn "res ".Dumper \@res;
    return \@res;
}

my $warn = shift @ARGV;
unless ($warn) {
    close STDERR;
    open (STDERR, ">/dev/null");
    select (STDERR); $| = 1;
}

#== TESTS ===========================================================================

my $npa = scalar keys %{$TM::infrastructure->{assertions}};
my $npt = scalar keys %{$TM::infrastructure->{mid2iid}};

if (DONE) { # 3.2.1. Topic with an Item Identifier
    my $ms = _parse (q|
    john.
|);
#warn Dumper $ms;
    ok ($ms->tids ('john'), '3.2.1. Topic with an Item Identifier');
    is ($ms->toplets,        $npt+1, '  one additional');
}

if (DONE) { # 3.2.2. Typed Topic - Using Item Identifiers
    my $ms = _parse (q|
    john isa person.
|);
#warn Dumper $ms;
    ok ($ms->tids ('john'),            '3.2.2. Typed Topic - Using Item Identifiers');
    ok ($ms->tids ('person'),          '3.2.2. Typed Topic - Using Item Identifiers');
    is ($ms->toplets,        $npt+2,   '  additional');
    ok (eq_set ([ $ms->instances ('tm:person') ],	[ 'tm:john' ]), '  instances');
}

if (DONE) { # 3.2.3. Typed Topic - Using Subject Identifiers
    my $ms = _parse (q|
    john isa http://psi.example.org/music/guitarist.  

    paul isa http://psi.example.org/music/guitarist  .  

    george isa http://psi.example.org/music/guitarist  .

|);
#warn Dumper $ms;
    ok ($ms->tids ('john'),            '3.2.3. Typed Topic - Using Subject Identifiers');
    ok ($ms->tids ('paul'),            '3.2.3. Typed Topic - Using Subject Identifiers');
    ok ($ms->tids ('george'),          '3.2.3. Typed Topic - Using Subject Identifiers');
    is ($ms->toplets,        $npt+4,   '  additional');
    ok (eq_set ([ $ms->types ('tm:john') ],	[ 'tm:uuid-0000000000' ]), '  types');
    ok (eq_set ($ms->toplet ('tm:uuid-0000000000')->[TM->INDICATORS],	
		[
		 'http://psi.example.org/music/guitarist'
		 ]), '  indicators');
    ok (eq_set ([ $ms->instances ('tm:uuid-0000000000') ],
		[ 'tm:john', 'tm:paul', 'tm:george' ]
		), '  instances');
}

if (DONE) { # 3.2.3. Typed Topic - Using Subject Identifiers, using the "prefix" directive
    my $ms = _parse (q|
    %prefix music http://psi.example.org/music/

    john isa music:guitarist.

    paul isa music:guitarist  .  

    george isa music:guitarist  .

|);
#warn Dumper $ms;
    ok ($ms->tids ('john'),            '3.2.3. Typed Topic - Using Subject Identifiers, prefixed');
    ok ($ms->tids ('paul'),            '3.2.3. Typed Topic - Using Subject Identifiers, prefixed');
    ok ($ms->tids ('george'),          '3.2.3. Typed Topic - Using Subject Identifiers, prefixed');
    is ($ms->toplets,        $npt+4,   '  additional');

    my $guitarman = $ms->mids (\ 'http://psi.example.org/music/guitarist');
    ok (eq_set ($ms->toplet ($guitarman)->[TM->INDICATORS],	
		[
		 'http://psi.example.org/music/guitarist'
		 ]), '  indicators');

    ok (eq_set ([ $ms->instances ($guitarman) ], [ 'tm:john', 'tm:paul', 'tm:george' ]), '  instances');
}

if (DONE) { # 3.2.4. Multityped Topic - Using Item Identifiers
    my $ms = _parse (q|
    john isa singer; 
         isa guitarist.
|);
#warn Dumper $ms;
    ok ($ms->tids ('john'),            '3.2.4. Multityped Topic - Using Item Identifiers');
    ok ($ms->tids ('singer'),          '3.2.4. Multityped Topic - Using Item Identifiers');
    ok ($ms->tids ('guitarist'),       '3.2.4. Multityped Topic - Using Item Identifiers');
    is ($ms->toplets,        $npt+3,   '  additional');

    ok (eq_set ([ $ms->instances ('tm:singer') ],    [ 'tm:john' ]), '  instances');
    ok (eq_set ([ $ms->instances ('tm:guitarist') ], [ 'tm:john' ]), '  instances');
}

if (DONE) { # 3.2.5. Multityped Topic - Using Subject Identifiers
    my $ms = _parse (q|
    http://psi.example.org/beatles/john isa singer; isa guitarist.
|);
#warn Dumper $ms;
    my $john = $ms->tids (\ 'http://psi.example.org/beatles/john');
    ok ($john,                         '3.2.5. Multityped Topic - Using Subject Identifiers');
    ok ($ms->tids ('singer'),          '3.2.5. Multityped Topic - Using Subject Identifiers');
    ok ($ms->tids ('guitarist'),       '3.2.5. Multityped Topic - Using Subject Identifiers');
    is ($ms->toplets,        $npt+3,   '  additional');

    ok (eq_set ([ $ms->instances ('tm:singer') ],    [ $john ]), '  instances');
    ok (eq_set ([ $ms->instances ('tm:guitarist') ], [ $john ]), '  instances');
}

if (DONE) { # 3.3.1. Topic with an Item Identifier and Topic Name
    my $ms = _parse (q|
    john - "John Lennon".
|);
#warn Dumper $ms;
    ok ($ms->tids ('john'),          '3.3.1. Topic with an Item Identifier and Topic Name');
    is ($ms->toplets,          $npt+1,   '  additional');
    is ($ms->asserts,          $npa+1,   '  additional');
    ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match_forall (char => 1, topic => $ms->tids ('john')) ] ,
                [ 'John Lennon' ]),      '  names of john');
}

if (DONE) { # 3.3.2. Topic with a Subject Identifier and Topic Name
    my $ms = _parse (q|
    %prefix beatles http://psi.beatles.example.org/
    
    beatles:john - "John Lennon" .

|);
#warn Dumper $ms;
    my $john = $ms->tids (\ 'http://psi.beatles.example.org/john' );
    ok ($john,          '3.3.2. Topic with a Subject Identifier and Topic Name');
    is ($ms->toplets,          $npt+1,   '  additional');
    is ($ms->asserts,          $npa+1,   '  additional');
    ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match_forall (char => 1, topic => $john) ] ,
                [ 'John Lennon' ]),      '  names of john');
}

if (DONE) { # 3.3.3. Topic with a Subject Locator and a Topic Name
    my $ms = _parse (q|

= http://beatles.com/ - "Official website of The Beatles".

|);
#warn Dumper $ms;
    my $beatles = $ms->tids ( 'http://beatles.com/' );
    ok ($beatles,          '3.3.3. Topic with a Subject Locator and a Topic Name');
    is ($ms->toplets,          $npt+1,   '  additional');
    is ($ms->asserts,          $npa+1,   '  additional');
    ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match_forall (char => 1, topic => $beatles) ] ,
                [ 'Official website of The Beatles' ]),      '  name of beatles');
}

if (DONE) { # 3.3.4. Typed Topic Name - Using Item Identifiers
    my $ms = _parse (q|

john - fullname: "John Ono Lennon".

|);
#warn Dumper $ms;
    my $john = $ms->tids ( 'john' );
    ok ($john,          '3.3.4. Typed Topic Name - Using Item Identifiers');
    is ($ms->toplets,          $npt+2,   '  additional');
    is ($ms->asserts,          $npa+2,   '  additional');
    ok (eq_set ([ map { $_->[0] } 
                  map { $_->[TM->PLAYERS]->[1] }
		  grep { $_->[TM->TYPE] eq 'tm:fullname'}
		  $ms->match_forall (char => 1, topic => $john) ] ,
                [ 'John Ono Lennon' ]),      '  fullname of john');
    ok (eq_set ([ map { $_->[TM->TYPE] } $ms->retrieve ( $ms->instances ('name') ) ] ,
                [ 'tm:fullname' ]),      '  fullname of john (name subtype)');
}

if (DONE) { # 3.3.5. Typed Topic Names - Using Subject Identifiers
    my $ms = _parse (q|

john - http://psi.example.org/fullname: "John Ono Lennon".

|);
#warn Dumper $ms;
    my $john = $ms->tids ( 'john' );
    ok ($john,          '3.3.5. Typed Topic Names - Using Subject Identifiers');
    is ($ms->toplets,          $npt+2,   '  additional');
    is ($ms->asserts,          $npa+2,   '  additional');
    my $fn = $ms->tids (\ 'http://psi.example.org/fullname');
    ok (eq_set ([ map { $_->[0] } 
                  map { $_->[TM->PLAYERS]->[1] }
		  grep { $_->[TM->TYPE] eq $fn }
		  $ms->match_forall (char => 1, topic => $john) ] ,
                [ 'John Ono Lennon' ]),      '  fullname of john');
    ok (eq_set ([ map { $_->[TM->TYPE] } $ms->retrieve ( $ms->instances ('name') ) ] ,
                [ $fn ]),                    '  fullname of john (name subtype)');
}

if (DONE) { # 3.3.6. Scoped Topic Name - Using Item Identifiers
    my $ms = _parse (q|

john - "John Ono Lennon" @fullname.

|);
#warn Dumper $ms;
    my $john = $ms->tids ( 'john' );
    ok ($john,          '3.3.6. Scoped Topic Name - Using Item Identifiers');
    is ($ms->toplets,          $npt+2,   '  additional');
    is ($ms->asserts,          $npa+2,   '  additional');
    ok (eq_set ([ map { $_->[0] } 
                  map { $_->[TM->PLAYERS]->[1] }
		  grep { $_->[TM->SCOPE] eq 'tm:fullname' }
		  grep { $_->[TM->TYPE]  eq 'name' }
		  $ms->match_forall (char => 1, topic => $john) ] ,
                [ 'John Ono Lennon' ]),      '  name of john (scoped)');
    ok (eq_set ([ $ms->instances ('scope') ] ,
                [ 'tm:fullname', 'us' ]),           '  fullname of john isa scope');
}

if (DONE) { # 3.3.7. Scoped Topic Name - Using Subject Itentifiers
    my $ms = _parse (q|
    %prefix ex http://blabla.org/
    john - "John Ono Lennon" @ex:fullname.

|);
#warn Dumper $ms;
    my $john = $ms->tids ( 'john' );
    ok ($john,          '3.3.7. Scoped Topic Name - Using Subject Itentifiers');
    my $fn = $ms->tids (\ 'http://blabla.org/fullname');
    is ($ms->toplets,          $npt+2,   '  additional');
    is ($ms->asserts,          $npa+2,   '  additional');
    ok (eq_set ([ map { $_->[0] } 
                  map { $_->[TM->PLAYERS]->[1] }
		  grep { $_->[TM->SCOPE] eq $fn }
		  grep { $_->[TM->TYPE]  eq 'name' }
		  $ms->match_forall (char => 1, topic => $john) ] ,
                [ 'John Ono Lennon' ]),      '  name of john (scoped)');
    ok (eq_set ([ $ms->instances ('scope') ] ,
                [ $fn, 'us' ]),              '  fullname of john isa scope');
}

if (DONE) { # 3.3.8. Multi Scoped Topic Name
    eval {
    my $ms = _parse (q|
    %prefix ex http://blabla.org/
    beatles 
    - "The Beatles";
    - "Fab Four" @nickname short .
|);
    }; like ($@, qr/unparseable/, 'multipled scopes NOT supported here');
}

if (DONE) { # 3.3.9. Typed and Scoped Names
    my $ms = _parse (q|
  john - fullname: "John Ono Lennon" @yoko.

|);
#warn Dumper $ms;
    my $john = $ms->tids ( 'john' );
    ok ($john,          ' 3.3.9. Typed and Scoped Names');
    is ($ms->toplets,          $npt+3,   '  additional');
    is ($ms->asserts,          $npa+3,   '  additional');
    ok (eq_set ([ map { $_->[0] } 
                  map { $_->[TM->PLAYERS]->[1] }
		  grep { $_->[TM->SCOPE] eq 'tm:yoko' }
		  grep { $_->[TM->TYPE]  eq 'tm:fullname' }
		  $ms->match_forall (char => 1, topic => $john) ] ,
                [ 'John Ono Lennon' ]),      '  name of john (scoped)');
    ok (eq_set ([ $ms->subclasses ('name') ] ,
                [ 'tm:fullname' ]),     '  fullname of john ako name');
    ok (eq_set ([ $ms->instances ('scope') ] ,
                [ 'tm:yoko', 'us' ]),   '  fullname of john isa scope');
}

if (DONE) { # 3.3.10. Topic Name with Variant of datatype String
    eval {
    my $ms = _parse (q|
    john - "John Lennon" ("lennon, john" @tm:sort).

|);
    }; like ($@, qr/unparseable/, 'variants NOT supported here');
}

if (DONE) { # 3.3.11. Topic Name with Variant of datatype XML
    eval {
    my $ms = _parse (q|
  john - "John Lennon"
    ( "<b>John Lennon</b>"^^xsd:anyType @markup).

|);
    }; like ($@, qr/unparseable/, 'variants NOT supported here');
}

if (DONE) { # 3.3.12. Topic Name with Variant of datatype URI
    eval {
    my $ms = _parse (q|
  john - "John Lennon" (http://link/to/an/image.jpg @image).
|);
    }; like ($@, qr/unparseable/, 'variants NOT supported here');
}

if (DONE) { # 3.3.13. Topic Name with Variant with non-TMDM datatype
    eval {
    my $ms = _parse (q|
  revolution-nine - "Revolution No. 9" (9 @number).
|);
    }; like ($@, qr/unparseable/, 'variants NOT supported here');
}

if (DONE) { # template-simple
    my $ms = _parse (q|
def template ()
    topic.

    topic2  .

    created (person : mccartney, song : yesterday)

end

template()

|);
    ok ($ms->mids ('topic'),                           'template-simple');
    ok ($ms->mids ('topic2'),                          '  2. topic');
    ok (eq_array ([  map  { @{ $_->[TM->PLAYERS] } }
		     grep { $_->[TM->TYPE]  eq 'tm:created' }
		     $ms->match_forall (iplayer => 'tm:yesterday') ],
		  [ 'tm:mccartney', 'tm:yesterday' ]), '  template-simple: players');
}

if (DONE) { # templates with parameters
    my $ms = _parse (q|
    def has-shoesize($person, $size)
        $person 
        shoesize: $size.
    end
    
has-shoesize (aaa, 42)

has-shoesize (bbb, 43)

|);

    ok (1,                               'template params');

    ok ($ms->mids ('aaa'),                           '  aaa');
    ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match_forall (char => 1, topic => $ms->tids ('aaa')) ] ,
                [ '42' ]),      '  shoesize aaa');
    ok ($ms->mids ('bbb'),                           '  bbb');
    ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match_forall (char => 1, topic => $ms->tids ('bbb')) ] ,
                [ '43' ]),      '  shoesize bbb');

    is ($ms->toplets,          $npt+3,   '  additional');
    is ($ms->asserts,          $npa+3,   '  additional');
}

if (DONE)
{
eval {
   my $ms = _parse (q|

def template()
   topic .
end

def template ()
   topic2.
end

|);
}; like ($@, qr/template.*defined/, 'templates: double defed');
}

if (DONE)
{

eval {
   my $ms = _parse (q|

def template ()
   topic.
end

templtae()

|);
}; like ($@, qr/unparseable/, 'templates: undefed');
}

if (DONE)
{
eval {
   my $ms = _parse (q|

def template ($a, $b)
   topic.
end

template(23)

|);
}; like ($@, qr/too few/, 'templates: too few arguments');
}

if (DONE)
{
eval {
   my $ms = _parse (q|

def template ($a, $b)
   topic.
end

template(23, aaa, bbb)

|);
}; like ($@, qr/too many/, 'templates: too many arguments');
}

if (DONE) 
{ #-- topic template invocation
    my $ms = _parse (q|
    def has-shoesize($person, $size)
        $person 
        shoesize: $size.
    end
    
    def is-member-of($member, $group)
        is-member-of(member: $member, group: $group)
    end
    
    http://psi.example.org/beatles/paul isa person;
    has-shoesize(45);
    is-member-of(the-beatles);
    homepage: http://www.paulmccartney.com/ .

|);

    ok (1,                                          'topic template invocation');
    my $t = $ms->mids (\ 'http://psi.example.org/beatles/paul');
    ok ($t,                                         '  paul');
    ok (eq_set ([ map { $_->[0] } 
		  map { $_->[TM->PLAYERS]->[1] }
		  grep { $_->[TM->TYPE] eq 'tm:shoesize' }
		  $ms->match_forall (char => 1, topic => $ms->tids ($t)) ] ,
                [ '45' ]),                          '  shoesize paul');
    ok (eq_set ([ map { $_->[0] } 
		  map { $_->[TM->PLAYERS]->[1] }
		  grep { $_->[TM->TYPE] eq 'tm:homepage' }
		  $ms->match_forall (char => 1, topic => $ms->tids ($t)) ] ,
                [ 'http://www.paulmccartney.com/' ]),      '  homepage paul');
    ok (eq_array ([  map  { @{ $_->[TM->PLAYERS] } }
		     grep { $_->[TM->TYPE]  eq 'tm:is-member-of' }
		     $ms->match_forall (iplayer => $t) ],
		  [ 'tm:the-beatles', $t ]),       '  players');
    is ($ms->toplets,          $npt+8,             '  additional');
    is ($ms->asserts,          $npa+6,             '  additional');
}

if (DONE) {
    my $ms = _parse (q|
topic
occtype: "Occurrence" ~ [ - "reifier"].
|);
#warn Dumper $ms;
    ok ($ms->mids ('topic'),          'embedding topic');

    my @oc = $ms->match_forall (char => 1, topic => $ms->tids ('topic'));
    is (scalar @oc, 1,                    '  only one occ');
    is ($oc[0]->[TM->TYPE], 'tm:occtype', '  occtype');
    my ($re) = $ms->is_reified ($oc[0]);

    like ($re, qr/uuid-\d{10}/,        '  generated topic');

    ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match_forall (char => 1, topic => $re) ] ,
                [ 'reifier' ]),        '  name of reifier');
}

if (DONE) { # 3.4.2. Typed Occurrence of datatype String - Using Item Identifiers
    my $ms = _parse (q|
    a-day-in-the-life
    lyrics: "I read ...".
|);
#warn Dumper $ms;
    ok ('tm:a-day-in-the-life',          ' 3.4.2. Typed Occurrence of datatype String - Using Item Identifiers');
    is ($ms->toplets,          $npt+2,   '  additional');
    is ($ms->asserts,          $npa+2,   '  additional');
    ok (eq_set ([ map { $_->[0] } 
                  map { $_->[TM->PLAYERS]->[1] }
		  grep { $_->[TM->TYPE]  eq 'tm:lyrics' }
		  $ms->match_forall (char => 1, topic => 'tm:a-day-in-the-life') ] ,
                [ 'I read ...' ]),      '  occ types');
    ok (eq_set ([ $ms->subclasses ('occurrence') ] ,
                [ 'tm:lyrics' ]),       '  lyrics ako occurrence');
}

if (DONE)
{ # 3.4.3. Typed Occurrence of datatype String - Using Subject Identifiers
    my $ms = _parse (q|
    %prefix ex http://www.blabla.org/

    a-day-in-the-life
    ex:lyrics: "I read ...".

|);
#warn Dumper $ms;
    ok ('tm:a-day-in-the-life',          ' 3.4.2. Typed Occurrence of datatype String - Using Item Identifiers');
    is ($ms->toplets,          $npt+2,   '  additional');
    is ($ms->asserts,          $npa+2,   '  additional');
    ok (eq_set ([ map { $_->[0] } 
                  map { $_->[TM->PLAYERS]->[1] }
		  grep { $_->[TM->TYPE]  eq $ms->tids (\ 'http://www.blabla.org/lyrics') }
		  $ms->match_forall (char => 1, topic => 'tm:a-day-in-the-life') ] ,
                [ 'I read ...' ]),      '  occ types');
    ok (eq_set ([ $ms->subclasses ('occurrence') ] ,
                [ $ms->tids (\ 'http://www.blabla.org/lyrics') ]),
                                        '  lyrics ako occurrence');
}

if (DONE) { # 3.4.4. Scoped Occurrence of datatype String - Using Item Identifiers
    my $ms = _parse (q|
    a-day-in-the-life 
    lyrics: "I read ..." @en.
|);
#warn Dumper $ms;
    ok ('tm:a-day-in-the-life',          '3.4.4. Scoped Occurrence of datatype String - Using Item Identifiers');
    is ($ms->toplets,          $npt+3,   '  additional');
    is ($ms->asserts,          $npa+3,   '  additional');
    ok (eq_set ([ map { $_->[0] } 
                  map { $_->[TM->PLAYERS]->[1] }
		  grep { $_->[TM->SCOPE] eq 'tm:en' }
		  grep { $_->[TM->TYPE]  eq 'tm:lyrics' }
		  $ms->match_forall (char => 1, topic => 'tm:a-day-in-the-life') ] ,
                [ 'I read ...' ]),      '  occ types');
    ok (eq_set ([ $ms->subclasses ('occurrence') ] ,
                [ 'tm:lyrics' ]),
                                        '  lyrics ako occurrence');
    ok (eq_set ([ $ms->instances ('scope') ] ,
                [ 'tm:en', 'us' ]),     '  en isa scope');
}

if (DONE) { # 3.4.5. Scoped Occurrence of datatype String - Using Subject Identifiers
    my $ms = _parse (q|
    %prefix ex http://bla.org/
    %prefix lang http://language.org

    a-day-in-the-life 
    ex:lyrics: "I read ..." @lang:en.

|);
#warn Dumper $ms;
    ok ('tm:a-day-in-the-life',          '3.4.4. Scoped Occurrence of datatype String - Using Item Identifiers');
    is ($ms->toplets,          $npt+3,   '  additional');
    is ($ms->asserts,          $npa+3,   '  additional');
    ok (eq_set ([ map { $_->[0] } 
                  map { $_->[TM->PLAYERS]->[1] }
		  grep { $_->[TM->SCOPE] eq $ms->tids (\ 'http://language.orgen') }
		  grep { $_->[TM->TYPE]  eq $ms->tids (\ 'http://bla.org/lyrics') }
		  $ms->match_forall (char => 1, topic => 'tm:a-day-in-the-life') ] ,
                [ 'I read ...' ]),      '  occ types');
    ok (eq_set ([ $ms->subclasses ('occurrence') ] ,
                [ $ms->tids (\ 'http://bla.org/lyrics') ]),
                                        '  lyrics ako occurrence');
    ok (eq_set ([ $ms->instances ('scope') ] ,
                [ $ms->tids (\ 'http://language.orgen'), 'us' ]),     '  en isa scope');
}

if (DONE) { # 3.4.6. Occurrence of datatype XML
    my $ms = _parse (q|
   a-day-in-the-life
   lyrics: """<html>
                <head>[...]</head>
                <body id="lyrics">[...]</body>
              </html>"""^^xsd:anyType.

|);
#warn Dumper $ms;
    ok ('tm:a-day-in-the-life',          '3.4.6. Occurrence of datatype XML');
    is ($ms->toplets,          $npt+2,   '  additional');
    is ($ms->asserts,          $npa+2,   '  additional');

#    ok (eq_set ([ map { $_->[0] } 

    my ($v) = map  { $_->[TM->PLAYERS]->[1] }
              grep { $_->[TM->TYPE]  eq 'tm:lyrics' }
              $ms->match_forall (char => 1, topic => 'tm:a-day-in-the-life');
    like ($v->[0], qr/<html>.*html>/s, '  XML value');

    ok (eq_set ([ $ms->subclasses ('occurrence') ] ,
                [ 'tm:lyrics' ]),
                                        '  lyrics ako occurrence');
}

if (DONE) { # 3.4.7. Occurrence of datatype IRI
    my $ms = _parse (q|
    beatles website: http://www.beatles.com/ .

|);
#warn Dumper $ms;
    ok ('tm:beatles',          '3.4.7. Occurrence of datatype IRI');
    is ($ms->toplets,          $npt+2,   '  additional');
    is ($ms->asserts,          $npa+2,   '  additional');

    my ($v) = map  { $_->[TM->PLAYERS]->[1] }
              grep { $_->[TM->TYPE]  eq 'tm:website' }
              $ms->match_forall (char => 1, topic => 'tm:beatles');
    is ($v->[0], 'http://www.beatles.com/', '  value');
    is ($v->[1], TM::Literal->URI,          '  datatype');
    ok (eq_set ([ $ms->subclasses ('occurrence') ] ,
                [ 'tm:website' ]),
                                        '  website ako occurrence');
}

if (DONE) { # 3.4.7. Occurrence of datatype IRI, explict
    my $ms = _parse (q|
    beatles website: "http://www.beatles.com/"^^xsd:anyURI.

|);
#warn Dumper $ms;
    ok ('tm:beatles',          '3.4.7. Occurrence of datatype IRI, explicit');
    is ($ms->toplets,          $npt+2,   '  additional');
    is ($ms->asserts,          $npa+2,   '  additional');

    my ($v) = map  { $_->[TM->PLAYERS]->[1] }
              grep { $_->[TM->TYPE]  eq 'tm:website' }
              $ms->match_forall (char => 1, topic => 'tm:beatles');
    is ($v->[0], 'http://www.beatles.com/', '  value');
    is ($v->[1], TM::Literal->URI,          '  datatype');
    ok (eq_set ([ $ms->subclasses ('occurrence') ] ,
                [ 'tm:website' ]),
                                        '  website ako occurrence');
}

if (DONE) { # 3.4.8. Occurrence of non-TMDM datatype
    my $ms = _parse (q|
    pennylane track-number: 2.

|);
#warn Dumper $ms;
    ok ('tm:pennylane',          '3.4.8. Occurrence of non-TMDM datatype');
    is ($ms->toplets,          $npt+2,   '  additional');
    is ($ms->asserts,          $npa+2,   '  additional');

    my ($v) = map  { $_->[TM->PLAYERS]->[1] }
              grep { $_->[TM->TYPE]  eq 'tm:track-number' }
              $ms->match_forall (char => 1, topic => 'tm:pennylane');
    is ($v->[0], '2', '  value');
    is ($v->[1], TM::Literal->INTEGER,          '  datatype');
    ok (eq_set ([ $ms->subclasses ('occurrence') ] ,
                [ 'tm:track-number' ]),
                                        '  website ako occurrence');
}

if (DONE) { # 3.4.8. Occurrence of non-TMDM datatype, explicit
    my $ms = _parse (q|
    pennylane track-number: "2"^^xsd:integer.

|);
#warn Dumper $ms;
    ok ('tm:pennylane',          '3.4.8. Occurrence of non-TMDM datatype, explicit');
    is ($ms->toplets,          $npt+2,   '  additional');
    is ($ms->asserts,          $npa+2,   '  additional');

    my ($v) = map  { $_->[TM->PLAYERS]->[1] }
              grep { $_->[TM->TYPE]  eq 'tm:track-number' }
              $ms->match_forall (char => 1, topic => 'tm:pennylane');
    is ($v->[0], '2', '  value');
    is ($v->[1], TM::Literal->INTEGER,          '  datatype');
    ok (eq_set ([ $ms->subclasses ('occurrence') ] ,
                [ 'tm:track-number' ]),
                                        '  website ako occurrence');
}

if (DONE) {
for (q|
    created(person : mccartney, song : yesterday)

|,
     q|
     def created($creator, $song)
         created(person : $creator, song : $song)
     end
    
     mccartney created(yesterday).
|,
     q|
     def created($creator, $song)
         created(person : $creator, song : $song)
     end

     created(mccartney, yesterday)
|
) { # 3.5.1. Creating Associations
    my $ms = _parse ($_);
#warn Dumper $ms;
    ok ('tm:created',          '3.5.1. Creating Associations');
    ok ('tm:mcartney',         '3.5.1. Creating Associations');
    is ($ms->toplets,          $npt+5,   '  additional');
    is ($ms->asserts,          $npa+1,   '  additional');
    
    ok (eq_array ([  map  { @{ $_->[TM->PLAYERS] } }
		     grep { $_->[TM->TYPE]  eq 'tm:created' }
		     $ms->match_forall (iplayer => 'tm:yesterday') ],
		  [ 'tm:mccartney', 'tm:yesterday' ]), '  players');
}
}

if (DONE) { # 3.5.2. Scoped Association
    my $ms = _parse (q|
    created(person : mccartney, song : yesterday) @music

|);
#warn Dumper $ms;
    ok ('tm:created',          '3.5.2. Scoped Association');
    ok ('tm:mcartney',         '3.5.2. Scoped Association');
    is ($ms->toplets,          $npt+6,   '  additional');
    is ($ms->asserts,          $npa+2,   '  additional');
    
    ok (eq_array ([  map  { @{ $_->[TM->PLAYERS] } }
		     grep { $_->[TM->SCOPE] eq 'tm:music' }
		     grep { $_->[TM->TYPE]  eq 'tm:created' }
		     $ms->match_forall (iplayer => 'tm:yesterday') ],
		  [ 'tm:mccartney', 'tm:yesterday' ]), '  players');
    ok (eq_set ([ $ms->instances ('scope') ] ,
                [ 'tm:music', 'us' ]),           '  music isa scope');
}

if (DONE) { # 3.5.5. Supertype-Subtype relationship - Using Item Identifiers
    my $ms = _parse (q|
    song ako musical-work.

|);
#warn Dumper $ms;
    ok ('tm:song',           '3.5.5. Supertype-Subtype relationship - Using Item Identifiers');
    ok ('tm:musical-work',   '3.5.5. Supertype-Subtype relationship - Using Item Identifiers');
    is ($ms->toplets,          $npt+2,   '  additional');
    is ($ms->asserts,          $npa+1,   '  additional');
    
    ok (eq_set ([ $ms->subclasses ('tm:musical-work') ] ,
                [ 'tm:song' ]),          '  ako');
}

if (DONE) { # 3.5.6. Supertype-Subtype relationship - Using Subject Identifiers
    my $ms = _parse (q|
    %prefix ex http://something/

    ex:song ako ex:musical-work.

|);
#warn Dumper $ms;
    my $song = $ms->tids (\ 'http://something/song');
    my $work = $ms->tids (\ 'http://something/musical-work');
    ok ($song,           '3.5.6. Supertype-Subtype relationship - Using Subject Identifiers');
    ok ($work,           '3.5.6. Supertype-Subtype relationship - Using Subject Identifiers');
    is ($ms->toplets,          $npt+2,   '  additional');
    is ($ms->asserts,          $npa+1,   '  additional');
    
    ok (eq_set ([ $ms->subclasses ($work) ] ,
                [ $song ]),          '  ako');
}

if (DONE) { # 3.6.1 Reification of a Topic Map
  TODO: {
      local $TODO = "reification of map";
      eval {
    my $ms = _parse (q|
    ~ [- "Beatlestopicmap"]
|);
};
      ok (0);
  }
}

if (DONE) { # 3.6.2. Reification of a Topic Name
    my $ms = _parse (q|
    john - "John Ono Lennon" ~ name-of-john-lennon.

|);
#warn Dumper $ms;
    ok ($ms->tids ('john'),                 '3.6.2. Reification of a Topic Name');
    ok ($ms->tids ('name-of-john-lennon'),  '3.6.2. Reification of a Topic Name');
    is ($ms->toplets,          $npt+2,   '  additional');
    is ($ms->asserts,          $npa+1,   '  additional');

    my $a = $ms->reifies ('tm:name-of-john-lennon');
    is ($a->[TM->KIND], TM->NAME, '  reified name');
    is (($ms->is_reified ($a))[0], 'tm:name-of-john-lennon', '  reifying topic');
}

if (DONE) { # 3.6.3. Reification of a Variant
  TODO: {
      local $TODO = "reification of variant";
      eval {
    my $ms = _parse (q|
    john - "John Ono Lennon"
            ("lennon, john" @sort ~ sortname-of-john-lennon).
|);
};
      ok (0);
  }
}

if (DONE) { # 3.6.4. Reification of a Occurrence
    my $ms = _parse (q|
    john website: http://www.lennon.com/ ~ lennons-website.

|);
#warn Dumper $ms;
    ok ($ms->tids ('john'),              '3.6.4. Reification of a Occurrence');
    ok ($ms->tids ('lennons-website'),   '3.6.4. Reification of a Occurrence');
    is ($ms->toplets,          $npt+3,   '  additional');
    is ($ms->asserts,          $npa+2,   '  additional');

    my $a = $ms->reifies ('tm:lennons-website');
    is ($a->[TM->KIND], TM->OCC,                         '  reified occ');
    is (($ms->is_reified ($a))[0], 'tm:lennons-website', '  reifying topic');
}

for (q|
    partnership(person: lennon, person: mc-cartney) ~ lennon-mccartney

    lennon-mccartney - "Lennon / McCartney".
|,
#q|
#    partnership(person: lennon, person: mc-cartney) ~ [- "Lennon / McCartney"]
#|
) {
if (DONE) { # 3.6.5. Reification of an Association
    my $ms = _parse ($_);
#warn Dumper $ms;
    ok ($ms->tids ('lennon-mccartney'),              '3.6.5. Reification of an Association');
    is ($ms->toplets,          $npt+5,   '  additional');
    is ($ms->asserts,          $npa+2,   '  additional');

    my $a = $ms->reifies ('tm:lennon-mccartney');
    is ($a->[TM->KIND], TM->ASSOC,                        '  reified assoc');
    is (($ms->is_reified ($a))[0], 'tm:lennon-mccartney', '  reifying topic');
}
}

if (DONE) 
{ # (anonymous) wildcard
    my $ms = _parse (q|

    ?xxx
    - "James Bond" .

    ?xxx = http://topic.one/
    website: http://www.lennon.com/ .

    ?yyy = http://topic.two/
    - "John Lennon" .

    ? = http://topic.three/
    website: http://www.lennon3.com/ .

    ? = http://topic.four/
    website: http://www.lennon4.com/ .

    ?yyy
    website: http://www.lennon2.com/ .

    ?xxx
    website: http://www.lennon1.com/ .

|);
#warn Dumper $ms;
    my $one = $ms->tids('http://topic.one/');
    like ($one, qr/uuid-\d{10}/,        'named wildcard');

    ok (eq_set([
		map  { $_->[0] }
		map  { $_->[TM->PLAYERS]->[1] }
		$ms->match_forall (char => 1, topic => $one)
		],
	       [
		'James Bond',
		'http://www.lennon.com/',
		'http://www.lennon1.com/'
		]), '  one chars');


    my $two = $ms->tids('http://topic.two/');
    like ($two, qr/uuid-\d{10}/,        'named wildcard');
    ok (eq_set([
		map  { $_->[0] }
		map  { $_->[TM->PLAYERS]->[1] }
		$ms->match_forall (char => 1, topic => $two)
		],
	       [
		'John Lennon',
		'http://www.lennon2.com/'
		]), '  two chars');

    my $thr = $ms->tids('http://topic.three/');
    like ($thr, qr/uuid-\d{10}/,        'named wildcard');
    ok (eq_set([
		map  { $_->[0] }
		map  { $_->[TM->PLAYERS]->[1] }
		$ms->match_forall (char => 1, topic => $thr)
		],
	       [
		'http://www.lennon3.com/'
		]), '  thr chars');

    my $fou = $ms->tids('http://topic.four/');
    like ($fou, qr/uuid-\d{10}/,        'named wildcard');
    ok (eq_set([
		map  { $_->[0] }
		map  { $_->[TM->PLAYERS]->[1] }
		$ms->match_forall (char => 1, topic => $fou)
		],
	       [
		'http://www.lennon4.com/'
		]), '  fou chars');

    is ($ms->toplets,          $npt+5,   '  additional');
    is ($ms->asserts,          $npa+8,   '  additional');
}

if (DONE) 
{ # (anonymous) wildcard
    my $ms = _parse (q|

    ?xxx = http://topic.one/
    - "James Bond" .

    def TEMP ($l)
       ?yyy = http://topic.two/
       website: $l .

       ?yyy
       website: http://www.lennon3.com/ .
    end

    ?xxx
    website: http://www.lennon1.com/ .

    TEMP ("http://www.lennon2.com/") 

    ?yyy http://topic.three/
    website: http://www.lennon4.com/ .

    def TEMP2 ($l)
       ?yyy = http://topic.four/
       website: $l .

       ?yyy
       website: http://www.lennon5.com/ .
    end

    TEMP2 ("http://www.lennon4.com/") 

|);
#warn Dumper $ms;
    my $one = $ms->tids('http://topic.one/');
    like ($one, qr/uuid-\d{10}/,        'named wildcard in template');
    ok (eq_set([
		map  { $_->[0] }
		map  { $_->[TM->PLAYERS]->[1] }
		$ms->match_forall (char => 1, topic => $one)
		],
	       [
		'James Bond',
		'http://www.lennon1.com/'
		]), '  one chars');

    my $two = $ms->tids('http://topic.two/');
    like ($two, qr/uuid-\d{10}/,        '  instantiated topic');
    ok (eq_set([
		map  { $_->[0] }
		map  { $_->[TM->PLAYERS]->[1] }
		$ms->match_forall (char => 1, topic => $two)
		],
	       [
		'http://www.lennon2.com/',
		'http://www.lennon3.com/',
#		'http://www.lennon4.com/'
		]), '  two chars');

    my $thr = $ms->tids( \ 'http://topic.three/');
    isnt ($thr, $two,                   '  wildcarded different');
    like ($thr, qr/uuid-\d{10}/,        '  instantiated topic');
    ok (eq_set([
		map  { $_->[0] }
		map  { $_->[TM->PLAYERS]->[1] }
		$ms->match_forall (char => 1, topic => $thr)
		],
	       [
		'http://www.lennon4.com/',
		]), '  thr chars');

    my $fou = $ms->tids( 'http://topic.four/');
    isnt ($fou, $two,                   '  wildcarded different');
    isnt ($fou, $thr,                   '  wildcarded different');
    like ($fou, qr/uuid-\d{10}/,        '  instantiated topic');
    ok (eq_set([
		map  { $_->[0] }
		map  { $_->[TM->PLAYERS]->[1] }
		$ms->match_forall (char => 1, topic => $fou)
		],
	       [
		'http://www.lennon4.com/',
		'http://www.lennon5.com/',
		]), '  fou chars');

    is ($ms->toplets,          $npt+5,   '  additional');
    is ($ms->asserts,          $npa+8,   '  additional');
}

if (DONE)
{
    my $ms = _parse (q|

    xxx .

    %include inline:aaa .

    yyy .

|);
#warn Dumper $ms;
    ok ($ms->tids('xxx'), 'include: topics');
    ok ($ms->tids('aaa'), 'include: topics');
    ok ($ms->tids('yyy'), 'include: topics');

}


__END__



3.7.1. Singe line comment
-------------------------

    ::ctm
    # a single line with comments


3.7.2. Multiline comment
------------------------

	::ctm
    #( one comment
     line 2
    )#



  map reify

  wildcard




__END__


require_ok( 'TM::Materialized::LTM' );

{
  my $tm = new TM::Materialized::LTM (inline => '
');

  ok ($tm->isa('TM::Materialized::Stream'),  'correct class');
  ok ($tm->isa('TM::Materialized::LTM'),   'correct class');

}

{ # comments
    my $ms = _parse (q|
[ aaa ]

/* some comment [ bbb ] 

*/

[ ccc ]
|);
#warn Dumper $ms;
    ok ($ms->tids ('aaa'), 'comment: outside');
    ok (!$ms->tids ('bbb'), 'comment: inside');
    ok ($ms->tids ('ccc'), 'comment: outside');
}

die_ok (q{
/*  [ aaa ]
     */  */ 
}, 'unparseable', 'invalid comment nesting');

{ # encoding
    my $ms = _parse (q|

@"utf-8"

[ aaa ]

|);
ok (1, 'encoding: ignored');
}

{ # topic address
    my $ms = _parse (q|
 [aaa % "urn:aaa" ]
|);
#    warn Dumper $ms;
    is ($ms->tids ('aaa'), $ms->tids ('urn:aaa'), 'reification: subject identifier ok');
}


{ # subject indicators
    my $ms = _parse (q|
 [aaa % "urn:aaa" @ "urn:xxx" @ "urn:yyy" ]
|);
#    warn Dumper $ms;

    ok (eq_set ($ms->midlet ($ms->tids ('urn:aaa'))->[TM->INDICATORS],
		[ 'urn:xxx', 'urn:yyy' ]),                          'indication: all found');
}

{ # topics types
    my $ms = _parse (q|
 [aaa: bbb ccc ]
|);
#warn Dumper $ms;

    my @res = $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:aaa');
    ok (eq_set ([ map { $_->[TM->PLAYERS]->[0]  } @res ],
		[ 'tm:bbb', 'tm:ccc' ]), 'topic: class values');
}

{ # topic basename
    my $ms = _parse (q|
 [aaa: bbb ccc = "AAA" ]
|);
#warn Dumper $ms;

    ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'name', iplayer => 'tm:aaa' ) ] ,
		[ 'AAA' ]), 'topic: AAA basename');
}

{ # topic scoped basename
   my $ms = _parse (q|
[aaa: bbb ccc = "AAAS" / sss ]
		    |);
#warn Dumper $ms;
    ok (eq_set ([ map {$_->[0]}  map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, scope => 'tm:sss', type => 'name', iplayer => 'tm:aaa' ) ] ,
		[ 'AAAS' ]), 'topic: AAA basename (scoped)');

    ok (scalar $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:sss' ) == 1, 'scope isa scope');
}

{ # topic, basename, sortname
my $ms = _parse (q|
[aaa: bbb ccc = "AAA" ; "SORTAAA" ]

[xxx: yyy = "XXX";  "SORTXXX"; "DISPXXX" ]

[uuu = "UUU";  "SORTUUU"; "DISPUUU" ]

[vvv = "VVV";  "SORTVVV"; "DISPVVV" / sss ]
|);
#warn Dumper $ms;
    ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'name', iplayer => 'tm:aaa' ) ] ,
		[ 'AAA' ]), 'topic: AAA basename');
#    ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'name', iplayer => 'tm:aaa' ) ] ,
#		[ 'SORTAAA' ]), 'topic: SORTAAA basename');
}

{ # topic external occurrence (typed)
    my $ms = _parse (q|
{aaa, bbb, "http://xxxt/" }
		  |);
#warn Dumper $ms;
  ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'tm:bbb',        iplayer => 'tm:aaa' ) ] ,
	      [ 'http://xxxt/' ]), 'topic: occurr typed');
  ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:aaa' ) ] ,
	      [ 'http://xxxt/' ]), 'topic: occurr (typed)');
}


# untyped is not allowed in LTM?

{ # topic internal occurrence
    my $ms = _parse (q|
{aaa, bbb, [[http://xxxt/]] }
		  |);
#warn Dumper $ms;
  ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'tm:bbb',        iplayer => 'tm:aaa' ) ] ,
	      [ 'http://xxxt/' ]), 'topic: int occurr typed');
  ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:aaa' ) ] ,
	      [ 'http://xxxt/' ]), 'topic: int occurr (typed)');
}

{ # mix occurrences with topics
    my $ms = _parse (q|
[ aaa : bbb ]
{ aaa, xxx, "http://xxx/" }

{ ccc, yyy, "http://yyy/" }
[ ccc : ddd ]

|);

#warn Dumper $ms;

   ok (scalar $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:aaa' ) == 1, 'topic+occur: class');
   ok (scalar $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:ccc' ) == 1, 'topic+occur: class');

   ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:aaa' ) ] ,
	       [ 'http://xxx/' ]), 'topic+occur: occurr');
   ok (eq_set ([ map {$_->[0]} map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:ccc' ) ] ,
	       [ 'http://yyy/' ]), 'topic+occur: occurr');
}

#-- assocs --------------

{
    my $ms = _parse (q|
aaa (play1: role1, play2: role2)

bbb (play1: role1, play2: role2)

ccc (play1, play2: role2)
|);
#warn Dumper $ms;

    my @res = $ms->match (TM->FORALL, type => 'tm:aaa');
    ok (eq_set ([ map { @{$_->[TM->PLAYERS]}  } @res ],
		[ 'tm:play1', 'tm:play2' ]), 'assoc: players');
    ok (eq_set ([ map { @{$_->[TM->ROLES]}  } @res ],
		[ 'tm:role1', 'tm:role2' ]), 'assoc: roles');

       @res = $ms->match (TM->FORALL, type => 'tm:bbb');
    ok (scalar @res == 1, 'assoc: separate');


       @res = $ms->match (TM->FORALL, type => 'tm:ccc');
    ok (eq_set ([ map { @{$_->[TM->PLAYERS]}  } @res ],
		[ 'tm:play1', 'tm:play2' ]), 'assoc: players');
    ok (eq_set ([ map { @{$_->[TM->ROLES]}  } @res ],
		[ 'thing', 'tm:role2' ]), 'assoc: roles (default)');
}

{ # scoped assoc
    my $ms = _parse (q|
aaa (play1: role1, play2: role2) / sss

aaa (play1: role1, play2: role2)

aaa (play1: role1, play2: role2) / ttt

		     |);
##warn Dumper $ms;

    my @res = $ms->match (TM->FORALL, type => 'tm:aaa');
    ok (scalar @res == 3, 'scoped mixed assoc: number');

    ok (grep ($_->[TM->SCOPE] eq 'tm:ttt', @res), 'scoped mixed assoc: scoping');
    ok (grep ($_->[TM->SCOPE] eq 'tm:sss', @res), 'scoped mixed assoc: scoping');
    ok (grep ($_->[TM->SCOPE] eq 'us',  @res), 'scoped mixed assoc: scoping');

    foreach my $r (@res) {
	ok (eq_set ([ @{$r->[TM->PLAYERS]} ],
		    [ 'tm:play1', 'tm:play2' ]), 'scoped mixed assoc: players');
	ok (eq_set ([ @{$r->[TM->ROLES]} ],
		    [ 'tm:role1', 'tm:role2' ]), 'scoped mixed assoc: roles');
    }
}

{ # assoc with nested topic
    my $ms = _parse (q|
aaa ( [ play1: ccc ]:  role1, play2: role2)
|);
#warn Dumper $ms;

    my @res = $ms->match (TM->FORALL, type => 'tm:aaa');
    ok (eq_set ([ map { @{$_->[TM->PLAYERS]}  } @res ],
		[ 'tm:play1', 'tm:play2' ]), 'assoc + embed: players');
    ok (eq_set ([ map { @{$_->[TM->ROLES]}  } @res ],
		[ 'tm:role1', 'tm:role2' ]), 'assoc + embed: roles');

    @res = $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:play1');
    ok (eq_set ([ map { @{$_->[TM->PLAYERS]}  } @res ],
		[ 'tm:play1', 'tm:ccc' ]), 'assoc + embed: types');
}

# reifications

{ # reified assocs
    my $ms = _parse (q|
aaa ( play1: role1, play2: role2) ~ xxx

|);
#warn Dumper $ms;
    my ($a) = $ms->match (TM->FORALL, type => 'tm:aaa');
    is ($a->[TM->LID], $ms->midlet ('tm:xxx')->[TM->ADDRESS], 'assoc reification');
}

{ # reified occurrence
    my $ms = _parse (q|
{aaa, bbb, "http://xxxt/" } ~ xxx
		     |);
#warn Dumper $ms;
    my ($a) = $ms->match (TM->FORALL, type => 'tm:bbb');
    is ($a->[TM->LID], $ms->midlet ('tm:xxx')->[TM->ADDRESS], 'occurrence reification');
}

{ # reified basename
    my $ms = _parse (q|
[ aaa = "AAA" ~ xxx ]
		     |);
#warn Dumper $ms;
    my ($a) = $ms->match (TM->FORALL, type => 'name');
    is ($a->[TM->LID], $ms->midlet ('tm:xxx')->[TM->ADDRESS], 'basename reification');
}

#== Directives ========================

{ # wrong VERSION format
    die_ok (q|
#VERSION "123"
|, 'not supported');
}


{ # wrong VERSION
    die_ok (q|
#VERSION "1.4"
|, 'not supported');
}

{ # VERSION
    my $ms = _parse (q|

#VERSION "1.3"

[ aaa ]
|);

ok (1, 'version supported');
}

{ # TOPICMAP
    die_ok (q|
#TOPICMAP ~ xxxx
|, 'use proper');
}


{ # INCLUDE
    die_ok (q|
[aaa]

#INCLUDE "xyz:abc"
|, 'unable to load');

}

{ # INCLUDE
    my $ms = _parse (q|
[ aaa ]

#INCLUDE "inline: [ bbb ]"

[ ccc ]
|);
#    warn Dumper $ms;

    ok ($ms->midlet ('tm:aaa'), 'include: topic');
    ok ($ms->midlet ('tm:bbb'), 'include: topic');
    ok ($ms->midlet ('tm:ccc'), 'include: topic');
}

{
    die_ok (q|

aa:uuu (bbb:play: bbb:role)

|, 'unparseable');
}

{ # PREFIXES
    my $ms = _parse (q|

#PREFIX aaa @ "http://xxxx/#"
#PREFIX bbb @ "http://yyyy/#"

aaa:uuu (play: bbb:role)

|);

#    warn Dumper $ms;
    
    my @res = $ms->match (TM->FORALL, type => $ms->tids ('http://xxxx/#uuu'));
    ok (scalar @res == 1, 'prefixed assoc name: found');
    ok (eq_set ([ map { @{$_->[TM->PLAYERS]}  } @res ],
		[ 'tm:play' ]), 'unprefixed player name');

    my $id = $ms->tids ('http://yyyy/#role');
    ok (eq_set ([ map { @{$_->[TM->ROLES]}  } @res ],
		[ $id ]), 'prefixed role name');
}

die_ok (q{
#MERGEMAP "inline: [ bbb ]" "rumsti"
}, 'unsupported', 'invalid TM format');

{ # MERGEMAP
    my $ms = _parse (q|
#MERGEMAP "inline: [ bbb ]" "ltm"

[ aaa ]

[ ccc ]
|);
#    warn Dumper $ms;

TODO: {
    local $TODO = "merging";
    ok ($ms->tids ('aaa'), 'merge: topic');
    ok ($ms->tids ('bbb'), 'merge: topic');
    ok ($ms->tids ('ccc'), 'merge: topic');
}
}

{ # MERGEMAP (default
    my $ms = _parse (q|
#MERGEMAP "inline: [ bbb ]"

[ aaa ]

[ ccc ]
|);
#    warn Dumper $ms;

TODO: {
    local $TODO = "merging (default)";
    ok ($ms->tids ('aaa'), 'merge: topic');
    ok ($ms->tids ('bbb'), 'merge: topic');
    ok ($ms->tids ('ccc'), 'merge: topic');
}
}


__END__



__END__

die_ok (q{
format-for ([ ltm ] : standard, topic-maps )

@"abssfsdf"

}, 1, 'invalid encoding');

$tm = new XTM (tie => new XTM::LTM ( text => q{
  

@"iso8859-1"

 { ltm , test , [[Ich chan Glaas ässe, das tuet mir nöd weeh]] }

}));

like ($tm->topic ('ltm')->occurrences->[0]->resource->data, qr/\x{E4}sse/, 'encoding from iso8859-1');



die_ok (q{
format-for ([ ltm ] : standard, topic-maps )

xxxx

{ ltm , test , "http://rumsti/" }
}, 1, 'unknown keyword');

die_ok (q{
format-for ([ ltm ] : standard, topic-maps 
}, 1, 'missing terminator 1');

die_ok (q{
[ ltm : format <= "The linear topic map notation" @ "http://something1/" @ "http://something2/" ]
}, 1, 'invalid terminator 1');

die_ok ('
{ ltm , test , "http://rumsti/" '
, 1, 'missing terminator 2');

die_ok ('
{ ltm , test , "http://rumsti/" } abc'
, 1, 'additional nonparsable text');


$tm = new XTM (tie => new XTM::LTM ( text => q{
  [ ltm ]
  { ltm , test , [[http://rumsti/
ramsti romsti ]] }
}));
is (@{$tm->topics('occurrence regexps /rumsti/')}, 1, 'occurrence with topic');
is (@{$tm->topics('occurrence regexps /romsti/')}, 1, 'occurrence with topic, multiline');

#print Dumper $tm;

$tm = new XTM (tie => new XTM::LTM ( text => q{
  [ ltm ]
  { ltm , test , "http://rumsti/" }
}));
is (@{$tm->topics('occurrence regexps /rumsti/')}, 1, 'occurrence with topic');
is (@{$tm->topics()},                              2, 'occurrence with topic, 2');

#print Dumper $tm;

$tm = new XTM (tie => new XTM::LTM ( text => q{
  { ltm , test ,  "http://rumsti/" }
  { ltm , test2 , "http://ramsti/" }
  { ltm2, test ,  "http://rumsti/" }
}));
is (@{$tm->topics('occurrence regexps /rumsti/')}, 2, 'occurrence wo topic');


$tm = new XTM (tie => new XTM::LTM ( text => q{
[ ltm : format = "The linear topic map notation" @ "http://something1/" @ "http://something2/" ]
}));
is (@{$tm->topics('indicates regexps /something1/')}, 1, 'subject indication1');
is (@{$tm->topics('indicates regexps /something2/')}, 1, 'subject indication2');

$tm = new XTM (tie => new XTM::LTM ( text => q{
[ ltm : format = "The linear topic map notation" % "http://something/" ]
}));
is (@{$tm->topics('reifies regexps /something/')}, 1, 'subject reification');



#__END__

$tm = new XTM (tie => new XTM::LTM ( text => q{
[ ltm : format = "The linear topic map notation"  ]
}));
is (@{$tm->topics('baseName regexps /linear/')}, 1, 'basename wo scope');

$tm = new XTM (tie => new XTM::LTM ( text => q{
[ ltm : format = "The linear topic map notation / scope1"  ]
}));
is (@{$tm->topics('baseName regexps /linear/')}, 1, 'basename with scope');


#__END__



# with types
my @types = qw(format1 format2 format3);
$tm = new XTM (tie => new XTM::LTM ( text => q{
[ ltm : }.join (" ", @types).q{  ]
}));
is (@{$tm->topics()}, 4, 'topic with types');
foreach my $t (@types) {
  is (@{$tm->topics("is-a $t")}, 1, "finding $t");
}



__END__


use strict;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;

sub _chomp {
    my $s = shift;
    chomp $s;
    return $s;
}

use TM;
use TM::PSI;

ok (1);

__END__

sub _parse {
  my $text = shift;
  my $ms = new TM (baseuri => 'tm:');
  my $p  = new TM::AsTMa::Fact (store => $ms);
  my $i  = $p->parse ("$text\n");
  return $ms;
}

sub _q_players {
    my $ms = shift;
#    my @res = $ms->match (TM->FORALL, @_);
#    warn "res no filter ".Dumper \@res;
    my @res = grep ($_ !~ m|^tm:|, map { ref($_) ? $_->[0] : $_ } map { @{$_->[TM->PLAYERS]} } $ms->match (TM->FORALL, @_));
#    warn "res ".Dumper \@res;
    return \@res;
}

##===================================================================================

#== TESTS ===========================================================================

require_ok( 'TM::AsTMa::Fact' );

{ # class ok
    my $p = new TM::AsTMa::Fact;
    ok (ref($p) eq 'TM::AsTMa::Fact', 'class ok');
}

{ #-- structural
    my $ms = _parse ('aaa (bbb)

ccc (bbb)
');
#warn Dumper $ms; exit;

    is (scalar $ms->match_forall (type => 'isa', irole => 'class', iplayer => 'tm:bbb'), 2, 'two types for bbb');
    ok (eq_array ([
                   $ms->mids ('aaa', 'bbb', 'ccc')
                   ],
                  [
                   'tm:aaa', 'tm:bbb', 'tm:ccc'
                   ]), 'aaa, bbb, ccc internalized');
}

{ #-- structural
    my $ms = _parse ('aaa (bbb)
');
#warn Dumper $ms;
    is (scalar $ms->match (TM->FORALL, type => 'isa', arole => 'instance', aplayer => 'tm:aaa', 
			                              brole => 'class',    bplayer => 'tm:bbb'), 1, 'one type for aaa');
    ok (eq_array ([
		   $ms->mids ('aaa', 'bbb')
		   ],
		  [
		   'tm:aaa', 'tm:bbb'
		   ]), 'aaa, bbb internalized');
}

{
    my $ms = _parse ('aaa
');
#warn Dumper $ms;
    is ($ms->mids ('aaa'), 'tm:aaa', 'aaa implicitely internalized');
}

{ # structural topic
  my $ms = _parse (q|
aaa is-a bbb
bn: AAA
oc: http://BBB
in: blabla bla
|);
#warn Dumper $ms;
  is (scalar $ms->match (TM->FORALL, type => 'isa',        irole => 'instance', iplayer => 'tm:aaa' ), 1, 'one type for aaa');
  is (scalar $ms->match (TM->FORALL,                       irole => 'thing',    iplayer => 'tm:aaa' ), 4, 'chars for aaa');
  is (scalar $ms->match (TM->FORALL, type => 'name',       irole => 'thing',    iplayer => 'tm:aaa' ), 1, 'basenames for aaa');
  is (scalar $ms->match (TM->FORALL, type => 'occurrence', irole => 'thing',    iplayer => 'tm:aaa' ), 2, 'occurrences for aaa 1');
}

#-- syntactic issues ----------------------------------------------------------------

my $npa = scalar keys %{$TM::infrastructure->{assertions}};
my $npt = scalar keys %{$TM::infrastructure->{mid2iid}};

{
  my $ms = _parse (q|
# this is AsTMa

|);
#warn Dumper $ms;
  is (scalar $ms->match(), $npa, 'empty map 1 (assertions)');
  is ($ms->toplets,        $npt, 'empty map 2 (toplets)');
}

{ # empty line with blanks
  my $ms = _parse (q|
topic1
   
topic2

|);
##warn Dumper $ms;
  is (scalar $ms->toplets(), $npt+2, 'empty line contains blanks');
}

{ # empty lines with \r
    my $ms = _parse (q|
topic1
topic2
topic3
|);

    is (scalar $ms->toplets(), $npt+3, 'empty line \r contains blanks');
}

{ # using TABs as separators
    my $ms = _parse (q|
topic1	(	topic2	)
	# comment
|);
#warn Dumper $ms;
    is (scalar $ms->toplets, $npt+2, 'using TABs as separators');
}

{
  my $ms = _parse (q|
# comment1

aaa (bbbbb cccc dddd)

#comment2

#comment4
ccc (bbb)
#comment3
#comment4
ddd (xxxx)
#comment5
|);
##warn Dumper $ms;

  is (scalar $ms->toplets, $npt+8, 'test comment/separation');
  is (scalar $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:aaa' ), 3, 'types for aaa');
  is (scalar $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:ccc' ), 1, 'type  for ccc');
  is (scalar $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:ddd' ), 1, 'type  for ddd');
}

{ # line continuation with comments
    my $ms = _parse (q|

topic1
# comment \
topic2

|);
    is (scalar $ms->toplets, $npt+1, 'continuation in comment');
}

{ # line continuation with comments
    my $ms = _parse (q|

topic1
# comment \

topic2

|);
    is (scalar $ms->toplets, $npt+2, 'continuation in comment, not 1');
}

{ # line continuation with comments
    my $ms = _parse (q|
topic1
# comment \ 
topic2

|);
    is (scalar $ms->toplets, $npt+2, 'continuation in comment, not 2');
}

{ # line continuation
  my $ms = _parse (q|
aaa (bbbbb \
cccc \
dddd)

|
);
  is (scalar $ms->toplets, $npt+4, 'line continuation');
  is (scalar $ms->match (TM->FORALL, type => 'isa', irole => 'instance', iplayer => 'tm:aaa' ), 3, 'types for aaa');
}

{ # line continuation, not
  my $ms = _parse (q|
aaa
 bn: AAA
 in: a \ within the text is ok
 in: also one with a \\ followed by a blank: \\ 
 in: this is a new one \\
 in: this is not a new one
|);
##warn Dumper $ms;

  my @res = $ms->match (TM->FORALL, type => 'occurrence', irole => 'thing', iplayer => 'tm:aaa' );
  is (scalar @res, 3, 'ins for aaa');
##warn Dumper \@res;
##warn Dumper [ map { ${$_->[TM->PLAYERS]->[1]}} @res ];
  ok (eq_set ([ 
		map { $_->[0] }
		map { $_->[TM->PLAYERS]->[1] } @res ],
	      [ 'a \ within the text is ok',
		'also one with a \ followed by a blank: \\',   # blank is gone now
		'this is a new one  in: this is not a new one']), 'same text');
}

{ # line continuation, not \\
  my $ms = _parse (q|
aaa (bbbb \
) # this is a continuation
bn: but not this \\\\
in: should be separate

|
);
##warn Dumper $ms;
  is (scalar $ms->match, $npa+3, 'line continuation, =3');
}

{ # string detection
  my $ms = _parse (q|
aaa
in: AAA

bbb
in: <<<
xxxxxxxxxxxxx
yyyyyyyyyy
zzzzzz
<<<

ccc
in: <<EOM
rumsti
ramsti
romsti
<<EOM

|);
##  warn Dumper $ms;
  is (scalar $ms->match, $npa+3, 'string detection');
  my @res = $ms->match (TM->FORALL, type => 'occurrence', irole => 'thing', iplayer => 'tm:bbb' );
  ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } @res ],
	      [ 'xxxxxxxxxxxxx
yyyyyyyyyy
zzzzzz',
		]), 'same text [<<<]');

  @res = $ms->match (TM->FORALL, type => 'occurrence', irole => 'thing', iplayer => 'tm:ccc' );
  ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } @res ],
	      [ 'rumsti
ramsti
romsti',
		]), 'same text [<<EOM]');
}

#-- line separation -----------------------------------------------

{ # line separation
  my $ms = _parse (q|
aaa (bbb) ~ bn: AAA ~ in: rumsti

ccc (ddd) ~ bn: CCC
|);
##  warn Dumper $ms;

  is (scalar $ms->match, $npa+5, '~ separation: assertion');
  ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'name', iplayer => 'tm:aaa' ) ] ,
	      [ 'AAA' ]), '~ separation: AAA basename');
}

{ # line no separation
  my $ms = _parse (q|
aaa (bbb) ~ bn: AAA ~ in: rumsti is using ~~ in: text
|);
##  warn Dumper $ms;
  is (scalar $ms->match, $npa+3, '~~ no-separation: assertions');
  ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL,  type => 'occurrence', iplayer => 'tm:aaa' ) ] ,
	      [ 'rumsti is using ~ in: text' ]), 'getting back ~ text');
}

{ # inline comments
  my $ms = _parse (q|
aaa
bn: AAA  # comment
bn: AAA# no-comment
oc: http://rumsti#no-comment
|);
##  warn Dumper $ms;

  is (scalar $ms->match, $npa+3, 'comment + assertions');
  ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'name', iplayer => 'tm:aaa' ) ] ,
	      [ 'AAA',
		'AAA# no-comment' ]), 'getting back commented basename');
  ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:aaa' ) ] ,
	      [ 'http://rumsti#no-comment' ]), 'getting back commented occ');
}

#-- structural: assocs ----------------------------------------------------------

{
    my $ms = _parse (q|
(xxx)
role : player

|);
##warn Dumper $ms;

  is (scalar $ms->match,                                                                               $npa+1, 'basic association');
  is (scalar $ms->match (TM->FORALL,                                       iplayer => 'tm:player' ), 1, 'finding basic association 1');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx',                     iplayer => 'tm:player' ), 1, 'finding basic association 2');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx', irole => 'tm:role', iplayer => 'tm:player' ), 1, 'finding basic association 3');
}

{
  my $ms = _parse (q|
(xxx)
role : p1 p2 p3
|);
##  warn Dumper $ms;

  is (scalar $ms->match,                                                                           $npa+1, 'basic association');
  is (scalar $ms->match (TM->FORALL,                                       iplayer => 'tm:p1' ), 1, 'finding basic association 4');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx',                     iplayer => 'tm:p2' ), 1, 'finding basic association 5');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx', irole => 'tm:role', iplayer => 'tm:p3' ), 1, 'finding basic association 6');
}

{
  my $ms = _parse (q|
(xxx)
  role : aaa bbb

(xxx)
  role : aaa

|);
##  warn Dumper $ms;

  is (scalar $ms->match,                                                                            $npa+2, 'basic association');
  is (scalar $ms->match (TM->FORALL,                                       iplayer => 'tm:aaa' ), 2, 'finding basic association 7');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx',                     iplayer => 'tm:bbb' ), 1, 'finding basic association 8');
}

{
  my $ms = _parse (q|
(xxx)
  role1 : aaa bbb
  role2 : ccc

|);
##warn Dumper $ms;

  is (scalar $ms->match, $npa+1, 'basic association');
  is (scalar $ms->match (TM->FORALL,                                        iplayer => 'tm:aaa' ), 1, 'finding basic association 10');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx',                      iplayer => 'tm:ccc' ), 1, 'finding basic association 11');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx', irole => 'tm:role2', iplayer => 'tm:ccc' ), 1, 'finding basic association 12');
}

{
  my $ms = _parse (q|
(aaa) @ sss
  role : player

|);
#warn Dumper $ms;

#  ok ($ms->is_subclass ('aaa', 'association'), 'association: subclassed');
# is (scalar $ms->match (TM->FORALL, type=> 'isa',                        iplayer => 'tm:sss'    ),   1, 'association scoped 1');

  is (scalar $ms->match, $npa+2, 'association scoped');
  is (scalar $ms->match (TM->FORALL,                                      iplayer => 'tm:player' ),   1, 'association scoped 2');
  is (scalar $ms->match (TM->FORALL, scope => 'tm:sss',                   iplayer => 'tm:player' ),   1, 'association scoped 3');
}

#-- reification --------------------------------------

{
  my $ms = _parse (q|
http://rumsti.com/ is-a website

urn:x-rumsti:xxx is-a rumsti
|);
#warn Dumper $ms;

  ok (eq_array ([
		 $ms->mids ('http://rumsti.com/','urn:x-rumsti:xxx')
		 ],
		[
		 'tm:uuid-0000000000', 'tm:uuid-0000000001'
		 ]),
		'reification: identifiers');
  is (scalar $ms->match, $npa+2, 'external reification: association');
  is (scalar $ms->match (TM->FORALL,                                       iplayer => 'tm:uuid-0000000001' ), 1, 'reification: finding');
  is (scalar $ms->match (TM->FORALL,                     type => 'isa',    iplayer => 'tm:uuid-0000000000' ), 1, 'finding basic association');
}

{
  my $ms = _parse (q|
cpan reifies http://cpan.org/

(xxx)
aaa: cpan
bbb: ccc

|);
#warn Dumper $ms;

  is (scalar $ms->match, $npa+1,                                                                                        'reification: association');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx',               iplayer => $ms->mids ('http://cpan.org/') ), 1, 'reification: finding basic association');
  is (scalar $ms->match (TM->FORALL, type => 'tm:xxx',               iplayer => 'tm:cpan' ),  1, 'reification: finding basic association');

  ok (eq_set (
	      [ $ms->match (TM->FORALL, type => 'tm:xxx',            iplayer => $ms->mids ('http://cpan.org/') ) ],
	      [ $ms->match (TM->FORALL, type => 'tm:xxx',            iplayer => 'tm:cpan' )          ]
	      ), 'reification: finding, same');
}

{
  my $ms = _parse (q|
(http://xxx)
  http://role1 : aaa http://bbb
  http://role2 : ccc
|);
#warn Dumper $ms;
  is (scalar $ms->match, $npa+1, 'reification: association');
  is (scalar $ms->match (TM->FORALL, type    =>   $ms->mids('http://xxx'), 
			             roles   => [ $ms->mids ('http://role1', 'http://role2', 'http://role1') ],
			             players => [ $ms->mids ('tm:aaa', undef, 'http://bbb') ] ), 1, 'reification: association');
}

{ # reification explicit
  my $ms = _parse (q|
xxx (http://www.topicmaps.org/xtm/1.0/#psi-topic)
|);
#warn Dumper $ms;
  is (scalar $ms->match, $npa+1, 'reification: type');

  ok ($ms->is_asserted (Assertion->new (scope   => 'us',
					type    => 'isa',
					roles   => [ 'class', 'instance' ],
					players => [ 'http://www.topicmaps.org/xtm/1.0/#psi-topic', 'tm:xxx' ])), 'xxx is-a found');
  my $m = $ms->tids ('http://www.topicmaps.org/xtm/1.0/#psi-topic');
  ok ($ms->is_asserted (Assertion->new (scope   => 'us',
					type    => 'isa',
					roles   => [ 'class', 'instance' ],
					players => [ $m, 'tm:xxx' ])), 'xxx is-a found (via mids)');
}

{
  my $ms = _parse (q|
(xxx) is-reified-by aaa
  role : player
|);
#warn Dumper $ms;
  my ($a) = $ms->match (TM->FORALL, type => 'tm:xxx');
  is_deeply ([ $ms->is_reified ($a) ], [ 'tm:aaa' ], 'assoc reified: regained');
  is ($ms->reifies ('tm:aaa'), $a,                   'assoc reified: regained 2');
}

eval {
  my $ms = _parse (q|
(xxx) reifies aaa
  role : player
|);
}; like ($@, qr/must be a URI/i, _chomp($@));

#{
#  my $ms = _parse (q|
#(xxx) reifies http://rumsti/
#  role : player
#|);
##warn Dumper $ms;
#
#  my ($a) = $ms->match (TM->FORALL, type => 'tm:xxx');
#  is ($ms->reified_by ($a->[TM->LID]), 'http://rumsti/', 'assoc reified: regained 3');
#}

eval {
  my $ms = _parse (q|
(xxx) is-reified-by http://aaa/
  role : player
|);
}; like ($@, qr/local identifier/i, _chomp($@));

#-- syntax errors -------------------------------------------------------------------

eval {
  my $ms = _parse (q|
(xxx zzz)
member : aaa
|);
}; like ($@, qr/syntax error/i, _chomp($@));

eval {
  my $ms = _parse (q|
(xxx)
|);
}; like ($@, qr/syntax error/i, _chomp($@));

eval {
  my $ms = _parse (q|
(xxx)
role : aaa
role2 : 
|);
}; like ($@, qr/syntax error/i, _chomp($@));

eval {
  my $ms = _parse (q|
(xxx)

rumsti

|);
}; like ($@, qr/syntax error/i, _chomp($@));

eval {
  my $ms = _parse (q|
()
role : player
|);
}; like ($@, qr/syntax error/i, _chomp($@));

#-- autogenerating ids

{
  my $ms = _parse (q|
* (aaa)

* (aaa)
|);
## warn Dumper $ms;

  is (scalar $ms->match, $npa+2, 'autogenerating ids');
  is (scalar (
              grep /tm:uuid-\d{10}/, 
	      map {$_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'isa', iplayer => 'tm:aaa' ) ), 2, 'generated ids ok');
}

#-- structural: toplets/characteristics -----------------------------------------

#- negative tests

eval {
   my $ms = _parse (q|
ttt
bn:    
|);
warn Dumper $ms;
}; ok ($@, "raises except on empty bn:");

eval {
   my $ms = _parse (q|
ttt
oc: 
|);
}; ok ($@, "raises except on empty oc:");

eval {
   my $ms = _parse (q|
ttt
in: 
|);
}; ok ($@, "raises except on empty in:");

eval {
   my $ms = _parse (q|
(aaa)
aaa :
|);
   fail ("raises except on empty role");
}; ok ($@, "raises except on empty role");

eval {
   my $ms = _parse (q|
(aaa)
aaa:bbb
|);
fail ("raises except on empty role 2");
}; ok ($@, "raises except on empty role 2");

eval {
   my $ms = _parse (q|
(ddd)
bbb:aaa:ccc
|);
fail ("raises except on empty role 3");
}; ok ($@, "raises except on empty role 3");


eval {
   my $ms = _parse (q|
aaa
sin (ttt): urn:xxx
|);
fail ("raises except on subject indicator");
}; ok ($@, "raises except on subject indicator");

eval {
   my $ms = _parse (q|
aaa
sin @ sss : urn:xxx
|);
fail ("raises except on subject indicator");
}; ok ($@, "raises except on subject indicator");

#-- positive tests -----------------------------------

{
  # testing toplets with characteristics
  my $ms = _parse (q|
xxx
bn: XXX
|);
##warn Dumper $ms;

  is (scalar $ms->match (TM->FORALL, type => 'name', roles => [ 'value', 'thing' ], players => [ undef, 'tm:xxx' ]), 1, 'basename characteristics');
}

{
  # testing toplets with URI
  my $ms = _parse (q|
http://xxx
bn: XXX
|);
##warn Dumper $ms;

  is (scalar $ms->match (TM->FORALL, type => 'name', roles => [ 'value', 'thing' ], 
			                             players => [ $ms->mids (undef, 'http://xxx') ]), 1, 'basename characterisistics (reification)');
}

{
my $ms = _parse (q|
aaa (bbbbb)
bn: AAA
in:         blabla  
|);
##warn Dumper $ms;

  ok (eq_set ([ map { map { $_->[0] } $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:aaa' ) ] ,
	      [ 'blabla' ]), 'test blanks in resourceData 1');
}

{
  my $ms = _parse (q|
xxx
bn: XXX
oc: http://xxx.com
ex: http://yyy.com
|);
##warn Dumper $ms;

  ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:xxx' ) ] ,
	      [ 'http://yyy.com', 'http://xxx.com' ]), 'occurrence char, value ok');
}


#- adding types

{
  my $ms = _parse (q|
aaa
 bn: AAA
 bn (rumsti) : AAAT
 in: III
 in (bumsti) : IIIT
 oc: http://xxx/
 oc (ramsti) : http://xxxt/
 oc (rimsti) : http://yyy/
 bn (remsti) : http://zzz/
 in (remsti) : bla
|);
#warn Dumper $ms;
#warn "occurrences of aaa ".Dumper [ $ms->match (TemplateIPlayerType->new ( type => 'tm:occurrence',   iplayer => 'tm:aaa' )) ];

  ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } 
                grep ($_->[TM->TYPE] eq 'name', 
                      $ms->match (TM->FORALL, type => 'name',   iplayer => 'tm:aaa' )) ] ,
	      [ 'AAA' ]), 'basename untyped char, value ok');

  ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'tm:rumsti',  iplayer => 'tm:aaa' ) ] ,
	      [ 'AAAT' ]), 'basename typed char, value ok');

  ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'occurrence', iplayer => 'tm:aaa' ) ] ,
	      [ 'http://xxxt/',
		'http://yyy/',
		'http://zzz/', # yes, this is also now an occurrence, since remsti is that too!
		'III',
		'IIIT',
		'bla',
		'http://xxx/' ]), 'occurr typed char, value ok');

  ok (eq_set ([ map { $_->[0] } map { $_->[TM->PLAYERS]->[1] } $ms->match (TM->FORALL, type => 'tm:bumsti',         iplayer => 'tm:aaa' ) ] ,
	      [ 'IIIT' ]), 'occurr typed char, value ok');
  ok (eq_set (_q_players ($ms, type => 'tm:ramsti',         iplayer => 'tm:aaa' ) ,
	      [ 'http://xxxt/' ]), 'occurr typed char, value ok');
  ok (eq_set (_q_players ($ms, type => 'tm:remsti',         iplayer => 'tm:aaa' ) ,
	      [ 
		'http://zzz/',
		'bla' ]), 'occurr typed char, value ok');
}

{ # subject indication 
    my $ms = _parse (q|
aaa
bn: AAA
sin: http://AAA
sin: http://BBB

|);
#warn Dumper $ms;

    my $t = $ms->midlet ('tm:aaa');
    ok (eq_set (
		$t->[TM->INDICATORS],
		[
		 'http://AAA',
		 'http://BBB',
		 ]), 'indicators');

    is (scalar $ms->match (TM->FORALL, type => 'name', irole => 'thing',    iplayer => $ms->mids (\ 'http://AAA') ), 1, 'names for aaa via indication');
    is (scalar $ms->match (TM->FORALL, type => 'name', irole => 'thing',    iplayer => $ms->mids (\ 'http://BBB') ), 1, 'names for aaa via indication');
}

#-- associations with URIs

{
  my $ms = _parse (q|
(aaa)
aaa:bbb : ccc

(ddd)
bbb: aaa:ccc
|);
##  warn Dumper $ms;

  ok (eq_set ([ map { $_->[TM->PLAYERS]->[0] } $ms->match (TM->FORALL, type => 'tm:aaa',         irole => $ms->mids ('aaa:bbb') ) ] ,
	      [ 'tm:ccc' ]), 'assoc with URIs 1');
  ok (eq_set ([ map { $_->[TM->PLAYERS]->[0] } $ms->match (TM->FORALL, type => 'tm:ddd',         irole => 'tm:bbb' ) ] ,
	      [ $ms->mids ('aaa:ccc') ]), 'assoc with URIs 2');

}

#- adding scopes

{
  my $ms = _parse (q|
aaa
 bn: AAA
 bn @ sss : AAAS
 in: III
 in @ sss : IIIS
 oc: http://xxx/
 oc @ sss : http://xxxs/
|);
##  warn Dumper $ms;

  ok (eq_set (_q_players ($ms, type => 'name',   iplayer => 'tm:aaa' ),
	      [ 'AAA', 'AAAS' ]), 'basename untyped, scoped, value ok');
  ok (eq_set (_q_players ($ms, scope => 'us', type => 'name',   iplayer => 'tm:aaa' ),
	      [ 'AAA' ]), 'basename untyped, scoped, value ok');
  ok (eq_set (_q_players ($ms, scope => 'tm:sss', type => 'name',   iplayer => 'tm:aaa' ),
	      [ 'AAAS' ]), 'basename untyped, scoped, value ok');

  ok (eq_set (_q_players ($ms, type => 'occurrence',   iplayer => 'tm:aaa' ),
	      [ 'III', 'IIIS', 'http://xxx/', 'http://xxxs/' ]), 'occurrences untyped, mixscoped, value ok');
  ok (eq_set (_q_players ($ms, scope => 'tm:sss', type => 'occurrence',   iplayer => 'tm:aaa' ),
	      [ 'IIIS', 'http://xxxs/' ]), 'occurrences untyped, scoped, value ok');
}

{ # typed and scoped characteristics
  my $ms = _parse (q|
aaa
 bn (ramsti): AAA
 bn @ sss (rumsti): AAAS
 in: III
 in @ sss (ramsti): IIIS
 oc: http://xxx/
 oc @ sss (ramsti): http://xxxs/

xxx (yyy)
|);
#  warn Dumper $ms;

  ok (eq_set (_q_players ($ms, type => 'tm:ramsti',   iplayer => 'tm:aaa' ),
	      [ 'AAA', 'IIIS', 'http://xxxs/' ]), 'basename typed, mixscoped, value ok');
  ok (eq_set (_q_players ($ms, scope => 'us', type => 'tm:ramsti',   iplayer => 'tm:aaa' ),
	      [ 'AAA' ]), 'basename untyped, scoped, value ok');
  ok (eq_set (_q_players ($ms, scope => 'tm:sss', type => 'tm:rumsti',   iplayer => 'tm:aaa' ),
	      [ 'AAAS' ]), 'basename untyped, scoped, value ok');

  ok (eq_set (_q_players ($ms, type => 'name',   iplayer => 'tm:aaa' ),
	      [   'http://xxxs/',  'AAA',  'IIIS',  'AAAS' ]), 'basenames typed, mixscoped, value ok');
  ok (eq_set (_q_players ($ms, type => 'occurrence',   iplayer => 'tm:aaa' ),
	      [ 'http://xxxs/',  'http://xxx/', 'AAA',  'IIIS',  'III' ]), 'occurrences typed, mixscoped, value ok');
  ok (eq_set (_q_players ($ms, kind => TM->OCC, type => 'occurrence',   iplayer => 'tm:aaa' ),
	      [ 'http://xxx/', 'http://xxxs/', 'IIIS',  'III' ]), 'occurrences untyped, mixscoped, value ok');
}

#-- inlined

{ # checking inlined subclassing
  my $ms = _parse (q|
aaa is-subclass-of bbb

(is-subclass-of)
 superclass: ddd
 subclass: ccc

eee is-subclass-of fff is-subclass-of ggg

hhh subclasses iii is-subclass-of jjj

|);
##warn Dumper $ms;

  is (scalar $ms->match(TM->FORALL, type => 'is-subclass-of', roles => [ 'subclass', 'superclass' ], players => [ 'tm:aaa', 'tm:bbb' ] ), 1, 'intrinsic is-subclass-of, different forms 1');

  is (scalar $ms->match(TM->FORALL, type => 'is-subclass-of', roles => [ 'subclass', 'superclass' ], players => [ 'tm:ccc', 'tm:ddd' ] ), 1, 'intrinsic is-subclass-of, different forms 2');

  is (scalar $ms->match(TM->FORALL, type => 'is-subclass-of', roles => [ 'subclass', 'superclass' ], players => [ 'tm:eee', 'tm:fff' ] ), 1, 'intrinsic is-subclass-of, different forms 3');

  is (scalar $ms->match(TM->FORALL, type => 'is-subclass-of', roles => [ 'subclass', 'superclass' ], players => [ 'tm:eee', 'tm:ggg' ] ), 1, 'intrinsic is-subclass-of, different forms 4');

  is (scalar $ms->match(TM->FORALL, type => 'is-subclass-of', roles => [ 'subclass', 'superclass' ], players => [ 'tm:hhh', 'tm:iii' ] ), 1, 'intrinsic is-subclass-of, different forms 5');

  is (scalar $ms->match(TM->FORALL, type => 'is-subclass-of', roles => [ 'subclass', 'superclass' ], players => [ 'tm:hhh', 'tm:jjj' ] ), 1, 'intrinsic is-subclass-of, different forms 6');

}


{
  my $ms = _parse (q|
aaa

bbb is-a thing

bbb is-a ccc

ddd (  )

eee is-a bbb is-a ccc is-a ddd

xxx has-a aaa
|);
##warn Dumper $ms;

  is (scalar $ms->match(TM->FORALL, type => 'isa', roles => [ 'class', 'instance'  ], players => [ 'tm:xxx',   'tm:aaa' ] ), 1, 'explicit is-a');
  is (scalar $ms->match(TM->FORALL, type => 'isa', roles => [ 'class', 'instance'  ], players => [ 'tm:ccc',   'tm:bbb' ] ), 1, 'explicit is-a 2');

  is (scalar $ms->match(TM->FORALL, type => 'isa', roles => [ 'class', 'instance'  ], players => [ 'tm:ddd',   'tm:eee' ] ), 1, 'explicit is-a 3');
  is (scalar $ms->match(TM->FORALL, type => 'isa', roles => [ 'class', 'instance'  ], players => [ 'tm:ccc',   'tm:eee' ] ), 1, 'explicit is-a 4');
  is (scalar $ms->match(TM->FORALL, type => 'isa', roles => [ 'class', 'instance'  ], players => [ 'tm:bbb',   'tm:eee' ] ), 1, 'explicit is-a 5');
}

#-- templates --------------------

eval {
   my $ms = _parse (q|
xxx bbb zzz

|);
}; ok ($@, "raises except on undefined inline assoc");

{
  my $ms = _parse (q|
[ (bbb)
ccc: ddd
eee: fff  ]

xxx bbb zzz

uuu bbb vvv

|);
#warn Dumper $ms;
  is (scalar $ms->match(TM->FORALL, type => 'tm:bbb', roles => [ 'tm:ccc', 'tm:eee'  ], players => [ 'tm:ddd',   'tm:fff' ] ), 1, 'template: static');
}

{
  my $ms = _parse (q|
[ (bbb)
ccc: http://psi.tm.bond.edu.au/astma/1.0/#psi-left
eee: fff  ]

xxx bbb zzz

[ (bbb2)
ccc: http://psi.tm.bond.edu.au/astma/1.0/#psi-left
eee: http://psi.tm.bond.edu.au/astma/1.0/#psi-right  ]

xxx bbb2 zzz

[ (bbb3)
http://psi.tm.bond.edu.au/astma/1.0/#psi-left : ccc
http://psi.tm.bond.edu.au/astma/1.0/#psi-right : eee  ]

xxx bbb3 zzz

|);

#warn Dumper $ms;
  is (scalar $ms->match(TM->FORALL, type => 'tm:bbb',  roles => [ 'tm:ccc', 'tm:eee'  ], players => [ 'tm:xxx',   'tm:fff' ] ), 1, 'template: dyn left');
  is (scalar $ms->match(TM->FORALL, type => 'tm:bbb2', roles => [ 'tm:ccc', 'tm:eee'  ], players => [ 'tm:xxx',   'tm:zzz' ] ), 1, 'template: dyn both, players');
  is (scalar $ms->match(TM->FORALL, type => 'tm:bbb3', roles => [ 'tm:xxx', 'tm:zzz'  ], players => [ 'tm:ccc',   'tm:eee' ] ), 1, 'template: dyn both, roles');
}

#-- scopes as dates

{
  my $ms = _parse (q|
aaa
 bn : AAA
 bn @ 2004-01-12 : XXX
 bn @ 2004-01-12 12:23 : YYY
|);
#  warn Dumper $ms;

  ok (eq_set (_q_players ($ms, scope => $ms->mids ('urn:x-date:2004-01-12:00:00'), type => 'name',   iplayer => 'tm:aaa' ),
	      [ 'XXX' ]), 'date scoped 1');
  ok (eq_set (_q_players ($ms, scope => $ms->mids ('urn:x-date:2004-01-12:12:23'), type => 'name',   iplayer => 'tm:aaa' ),
	      [ 'YYY' ]), 'date scoped 2');

}

#-- directives ------------------------------------------------------------

#-- encoding

{ #-- default
  my $ms = _parse (q|
aaa
in: Ich chan Glaas ässe, das tuet mir nöd weeh

bbb
in: Mohu jíst sklo, neublí?í mi


|);

  ok (eq_set (_q_players ($ms, type => 'occurrence',         iplayer => 'tm:aaa' ),
	      [ 'Ich chan Glaas ässe, das tuet mir nöd weeh' ]), 'encoding: same text');

  ok (eq_set (_q_players ($ms, type => 'occurrence',         iplayer => 'tm:bbb' ),
	      [ 'Mohu jíst sklo, neublí?í mi' ]),                'encoding: same text');

}

{ # -- explicit
  my $ms = _parse (q|
%encoding iso-8859-1

aaa
in: Ich chan Glaas ässe, das tuet mir nöd weeh
|);

##warn Dumper $ms;

  ok (eq_set (_q_players ($ms, type => 'occurrence',         iplayer => 'tm:aaa' ),
	      [ 'Ich chan Glaas ässe, das tuet mir nöd weeh' ]), 'encoding: same text');


#   ok (eq_set ([ $ms->toplets (new Toplet (characteristics => [ [ 'universal-scope',
# 								 'xtm-psi-occurrence',
# 								 TM::Maplet::KIND_IN,
# 								 '\x{E4}sse' ]])) ],
# 	       [   'aaa' ]), 'encoding: match in with umlaut');
}

{ #-- explicit different
  my $ms = _parse (q|
%encoding iso-8859-2

aaa
in: Ich chan Glaas ässe, das tuet mir nöd weeh

|);

  ok (eq_set (_q_players ($ms, type => 'occurrence',         iplayer => 'tm:aaa' ),
	      [ 'Ich chan Glaas ässe, das tuet mir nöd weeh' ]), 'encoding: same text');

}

my ($tmp);
use IO::File;
use POSIX qw(tmpnam);
do { $tmp = tmpnam() ;  } until IO::File->new ($tmp, O_RDWR|O_CREAT|O_EXCL);
END { unlink ($tmp) ; }

open (STDERR, ">$tmp");

{
  my $ms = _parse (q|
aaa

%cancel

bbb
|);

 is (scalar $ms->toplets, $npt+1, 'cancelling');
 ERRexpect ("Cancelled");
##warn Dumper $ms;
}

{
  my $ms = _parse (q|
aaa

%log xxx

bbb
|);

 is (scalar $ms->toplets, $npt+2, 'logging');
 ERRexpect ("Logging xxx");
}

{
my $ms = _parse (q|

aaa

%trace 1

bbb

(ddd)
eee : fff

%trace 0

ccc

|);

ERRexpect ("start tracing: level 1");
ERRexpect ("added toplet");
ERRexpect ("added assertion");
ERRexpect ("start tracing: level 0");
}

sub ERRexpect {
    my $expect = shift;

    open (ERR, $tmp);
    undef $/;  my $s = <ERR>;
    like ($s, qr/$expect/, "STDERR: expected '$expect'");
    close (ERR);
}

__END__



__END__

# testing corrupt TM
# testing TNC

my $text = '

aaa (bbb)
bn: AAA
';
  foreach my $i (1..100) {
    $text .= "

aaa$i (bbb)
bn: AAA$i
";
  }


$tm = new TM (tie => new TM::Driver::AsTMa (auto_complete => 0, text => $text));

warn "Parse RecDescent inclusive: $Parse::RecDescent::totincl";
warn "Parse RecDescent exclusive: $Parse::RecDescent::totexcl";

#warn "instartrule: $Parse::RecDescent::namespace000001::totincl";
warn "instartrule: $TM::Driver::AsTMa::Parser::totincl";

#warn "instartrule: $TM::AsTMa::Parser::totexcl";
warn "namespace0001 instartrule: $Parse::RecDescent::namespace000001::astma";
warn "namespace0001 cparserincl: $Parse::RecDescent::namespace000001::cparserincl";

__END__

TODO: { # assoc with multiple scope
   local $TODO = "assoc with multiple scope";

   eval {
      my $tm = new TM (tie => new TM::Driver::AsTMa (text => '
@ aaa bbb (is-ramsti-of)
ramsti : xxx
rumsti : yyy;
'));
   };

   ok (!$@);
} 

__END__

##=========================================================


