
	use strict ;
	use warnings ;

	use Data::TreeDumper ;
	use Spreadsheet::Perl ;

	my $ss = tie my %ss, "Spreadsheet::Perl", NAME => 'TEST' ;

	# set some debugging flags so we can see what is happening in the spreadsheet

	# show when a value is fetched from one of the following cells
	# we could also have used "$ss->{DEBUG}{FETCH}++; " but it doesn't show the details of the fetch operation
	$ss->{DEBUG}{FETCH_TRIGGER}{A1}++ ;
	$ss->{DEBUG}{FETCH_TRIGGER}{A2}++ ;
	$ss->{DEBUG}{FETCH_TRIGGER}{A3}++ ;
	
	# show which formulas are applied
	$ss->{DEBUG}{FETCH_SUB}++ ;
	
	# show when something is stored in a cell, tht can be a value, a formula, ...
	$ss->{DEBUG}{STORE}++;

	# show when dependencies are marked for recalculation
	$ss->{DEBUG}{MARK_ALL_DEPENDENT}++ ;
	 
	# plain perl variables
	my $variable = 25 ;
	my $variable_2 = 30 ;
	my $struct = {result => 'hello world'} ;
	
	# make cells refer to perl scalars. Note that this is a two way relationship

=pod
	# we can set all the references in one call
	$ss->Ref
		(
		'Ref and formulas',
		'A1' => \$variable,
		'A2' => \$variable_2,
		'A3' => \$struct->{result},
		) ;

	# or set each cell separately and be able to 
	# set individual information. setting individual
	# information allows us to extract the label names
	# as shown in the example bellow
=cut
	$ss{'A1'} = Ref('$variable', \$variable) ;
	$ss{'A2'} = Ref('$variable_2', \$variable_2) ;
	$ss{'A3'} = Ref('$struct->{result}', \$struct->{result}) ;

	# set formulas over the perl scalars. the initial value is fetched from the perl scalar, then 
	# the formulas are applied. dependencies and cyclic dependencies are handled 
	$ss->PerlFormula
		(
		'A2' => '$ss{A1} * 2',	
		'A3' => '$ss{A2} * 2',	
		) ;

	# fetch the values, running the formulas as necessary
	print "$ss{A1} $ss{A2} $ss{A3}\n" ;

	# fetch the values, running the formulas as necessary, here some results will be cached
	print "$ss{A1} $ss{A2} $ss{A3}\n" ;

	# show the values of the perl scalars
	print DumpTree 
		{
		'$variable' => $variable,
		'$variable_2' => $variable_2,
		'$struct'=> $struct,
		}, 'scalars:' ;

	# set a cell and the perl scalar underneath 
	$ss{A1} = 10 ;

	# fetch the values, running the formulas as necessary
	print "$ss{A1} $ss{A2} $ss{A3}\n" ;

	# show the values of the perl scalars
	print DumpTree 
		{
		'$variable' => $variable,
		'$variable_2' => $variable_2,
		'$struct'=> $struct,
		}, 'scalars:' ;
		
	# label the spreadsheet
	$ss->label_column('A'=> 'Value') ;

	$ss->label_row(1 => $ss->get_reference_description('A1')) ;
	$ss->label_row(2 => $ss->REF_INFO('A2')) ;
	$ss->label_row(3 => $ss->REF_INFO('A3')) ;

	print $ss->Dump() ;
	print $ss->DumpTable() ;



