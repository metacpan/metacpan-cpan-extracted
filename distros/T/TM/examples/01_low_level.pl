use TM;
my $tm = new TM ();    # create an empty map

use Data::Dumper;
#warn Dumper $tm;

$tm->internalize ('pony' => \ 'http://en.wikipedia.org/wiki/Pony');

warn Dumper [ $tm->toplets (\ '+all -infrastructure') ];

my ($t) = $tm->toplets ('tm://nirvana/pony');
warn Dumper $t->[TM->INDICATORS];


my $a = Assertion->new (kind    => TM->ASSOC,
                        type    => 'isa',
                        roles   => [ 'instance', 'class' ],
                        players => [ 'sacklpicka', 'cat' ]);
$tm->assert ($a);

use TM::Literal;
$tm->assert (Assertion->new (kind    => TM->NAME,
			     type    => 'name',
			     scope   => 'en',
			     roles   => [ 'thing', 'value' ],
			     players => [ 'sacklpicka', 
                                          new TM::Literal ('Der Sacklpicka') ]),
	     Assertion->new (kind    => TM->OCC,
			     type    => 'occurrence',
			     scope   => 'us',
			     roles   => [ 'thing', 'value' ],
			     players => [ 'sacklpicka', 
                                          new TM::Literal ('http://devc.at', 
                                                           TM::Literal->URI) ])
	     );

my @cats;

@cats = $tm->match_forall (
			      type => 'isa',
			      roles   => [ 'instance', 'class' ],
			      players => [ undef,      'cat' ]
			      );

@cats = $tm->match_forall (type => 'isa',
			   class => $tm->tids ('cat'));

warn Dumper \@cats;
warn Dumper [ map { $tm->get_players ($_, 'instance') } @cats ];

warn Dumper [
	     map { $_->[0] }
	     map { $tm->get_players ($_, 'value') }
	     grep { $_->[TM->KIND] == TM->OCC }
	     $tm->match_forall ('topic' => $tm->tids ('sacklpicka'),
				'char' => '1')
	     ];

warn Dumper [
	     map { $tm->get_x_players ($_, 'thing') }
	     $tm->match_forall ('value' => new TM::Literal ('Der Sacklpicka'),
				'char' => '1')
	     ];

#warn Dumper $tm;

warn "I knew it"
    if $tm->is_a ($tm->tids ('sacklpicka', 'cat'));

warn "Not sure about that"
    unless $tm->is_subclass ($tm->tids ('cat', 'thing'));

__END__





__END__



