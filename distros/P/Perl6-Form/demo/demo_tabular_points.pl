use Perl6::Form;

my @play = (
	"Hamlet",
	"Othello",
	"Richard III",
);

my @name = (
	"Claudius, King of Denmark\r\r",
	"Iago\r\r",
	"Henry, Earl of Richmond\r\r",
);


print form
	 {layout=>'down', bullet=>'.'},
	 "Index  Character     Appears in",
	 {under=>"_"},
	 "{]]}.  {[[[[[[[[[[}  {[[[[[[[[[[}",
      [1..@name], \@name,       \@play;

print "\n\n=================\n\n";

print form
	 {layout=>'tabular', bullet=>'.'},
	 "Index  Character     Appears in",
	 {under=>"_"},
	 "{]]}.  {[[[[[[[[[[}  {[[[[[[[[[[}",
      [1..@name], \@name,       \@play;
