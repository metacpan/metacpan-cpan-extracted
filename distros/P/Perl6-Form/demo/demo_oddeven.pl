use Perl6::Form;

my @text = <DATA>;

my @title = ("Hamlet's Soliloquy","W. Shakespeare");

my %header = (
	first => sub { form({ page => {width=>$_[0]{page}{width}}},
				        "{II{*}II}", \@title) . "\n";
				 },
	  odd => sub { form({ page => {width=>$_[0]{page}{width}}},
				        "{]]{*}]]}", $title[0]) . "\n";
				 },
	 even => sub { form({ page => {width=>$_[0]{page}{width}}},
				        "{[[{*}[[}", $title[1]) . "\n";
				 },
);

sub footer {
	form { page => {width=>$_[0]{page}{width}} },
		 "\n{|{*}|}",
		 "(page $_[0]{page}{number})"
}

my %page = (
	header => \%header,
	footer => \&footer,
	length => 15,
	width  => 72,
	feed   => ('_'x72)."\n",
);

print form {page=>\%page},
	 '{]]]]]}  {"{*}"}  {[[[[[}',
	 [1..@text], \@text,  [1..@text];

__DATA__
To be, or not to be -- that is the question:
Whether 'tis nobler in the mind to suffer
The slings and arrows of outrageous fortune
Or to take arms against a sea of troubles
And by opposing end them. To die, to sleep --
No more -- and by a sleep to say we end
The heartache, and the thousand natural shocks
That flesh is heir to. 'Tis a consummation
Devoutly to be wished. To die, to sleep --
To sleep -- perchance to dream: ay, there's the rub,
For in that sleep of death what dreams may come
When we have shuffled off this mortal coil,
Must give us pause. There's the respect
That makes calamity of so long life.
For who would bear the whips and scorns of time,
Th' oppressor's wrong, the proud man's contumely
The pangs of despised love, the law's delay,
The insolence of office, and the spurns
That patient merit of th' unworthy takes,
When he himself might his quietus make
With a bare bodkin? Who would fardels bear,
To grunt and sweat under a weary life,
But that the dread of something after death,
The undiscovered country, from whose bourn
No traveller returns, puzzles the will,
And makes us rather bear those ills we have
Than fly to others that we know not of?
Thus conscience does make cowards of us all,
And thus the native hue of resolution
Is sicklied o'er with the pale cast of thought,
And enterprise of great pitch and moment
With this regard their currents turn awry
And lose the name of action. -- Soft you now,
The fair Ophelia! -- Nymph, in thy orisons
Be all my sins remembered.
