use Perl6::Form;

@task = ('Acquire data', 'Sort', 'Prioritize', 'Decode', 'Analyse', 'Report');
@proc = (1..3);

print form
	 {tfill=>'[done]', bfill=>'[unallocated]'},
	 'Task                Processor',
	 {under=>'='},
	 '{[[[[[[[[[[[[[[}  {=IIIIIIIII=}',
	 \@task,               \@proc;
