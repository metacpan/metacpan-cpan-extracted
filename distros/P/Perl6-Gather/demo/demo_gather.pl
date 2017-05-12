use Perl6::Gather;
use Data::Dumper 'Dumper';

chomp(my @data = <DATA>);

my @default = qw(No repeated words);
@_ = qw(dollar underscore);

my @list = gather {
	for (@data) {
		take if /^[aeiou]/;
		take ">$_<"  if tr/aeiou// > tr/bcdfghjklmnpqrstvwxyz//;
		take [ gather {
						my @words = split;
						my ($word, $lastword) = ("","");
						while (@words) {
							($lastword,$word) = ($word,shift @words);
							redo if $word =~ /^(and|or|of|the|a)$/;
							take $word if $word eq $lastword;
							$lastword = $word;
						}
						take @default unless @_;
		              }
			 ] if /\s/;
	}
};

print Dumper \@list;

__DATA__
apple
data
betterment
two or or more more repeated words
two or or more repeated words
eerie
loose
lose

