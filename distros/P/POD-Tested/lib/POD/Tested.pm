
package POD::Tested ;

use base qw(Pod::Parser) ;

use strict;
use warnings ;
use Carp ;

BEGIN 
{
use Sub::Exporter -setup => { exports => [ qw() ] } ;

use vars qw ($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
$VERSION  = '0.06' ;
}

#-------------------------------------------------------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use Carp qw(carp croak confess) ;

use  Lexical::Persistence ;
use IO::String ;

#-------------------------------------------------------------------------------------------------------------------------------

=head1 NAME

POD::Tested - Test the code in your POD and generates POD.

=head1 SYNOPSIS

	my $parser = POD::Tested->new(@options);
	
	$parser->parse_from_file($input_file) ;
	
	#or 
	
	$parser->parse_from_filehandle($input_filehandle) ;
	
	write_file($output, $parser->GetPOD()) ;

=head1 DESCRIPTION

This module lets you write POD documents that are testable. It also let's you generate pod sections dynamically.

Any verbatim section (indented section) is considered part of the POD and the code to be tested. See the I<not_tested>
tag for verbatim sections that are not code.

=head1 DOCUMENTATION

I wrote this module because I wanted a mechanism to verify the code I write in my POD. Code changes, output
changes and I would like my documentation to always be up to date.

The installation procedure should install a B<pod_tested.pl> that you can use to verify your POD. This module is 
very simple to use and has but a few commands. Since it's rather difficult to explain simple things, I'll use an
example based approach. 

Please give me feedback on the documentation or some examples and I'll integrate them in
module's documentation.

=head2 From POD to POD

	=head1 Config::Hierarchical cookbook
	
	=head2 Simple usage
	
	Some Text
	
	=cut

Let's run the above POD through B<pod_tested.pl>.

	$> perl pod_tested.pl -input simple.pod -output simple.tested.pod
	
	# Generating POD in 'simple.tested.pod'.
	# No tests run!

	$> cat simple.tested.pod
	
	=head1 cookbook
	
	=head2 Simple usage
	
	Some Text
	
	=cut	

=head2 Testing your code

	=head1 cookbook
	
	=head2 Simple usage
	
	Some Text
	
	=begin hidden
	
	  my $cc = 'cc' ;
	  my $expected_cc = 'cc' ;
	  
	  is($cc, $expected_cc, 'expected value') ;
	
	=end hidden

Let's run the above POD through B<pod_tested.pl>.

	$> perl pod_tested.pl -input test.pod -output test.tested.pod
	# output from 'script/test.pod:9':
	
	ok 1 - expected value
	
	# Generating POD in 'test.tested.pod'.
	1..1

The Generated POD output goes to the output file you specified. You get the test output on your terminal. The POD
would look like:

	=head1 cookbook
	
	=head2 Simple usage
	
	Some Text
	
	=cut

Note that your test code is not part of the generated POD.

=head2 Section common to your POD and tests

Most often we want to show an example in the POD and verify it.

	=head1 Config::Hierarchical cookbook
	
	=head2 Simple usage
	
	Some text
	
	  use Config::Hierarchical ;
	   
	  my $config = new Config::Hierarchical(); 
	  
	  $config->Set(NAME => 'CC', VALUE => 'acc') ;
	  $config->Set(NAME => 'CC', VALUE => 'gcc') ;
	  
	  my $cc_value = $config->Get(NAME => 'CC') ;
	  
	  print "CC = '$cc_value'\n" ;
	
	=begin hidden
	
	  my $expected_output = 'gcc' ;
	  is($cc_value, $expected_output, 'expected value') ;
	
	=end hidden
	
	=cut 

Let's run the above POD through B<pod_tested.pl>.

	$> perl pod_tested.pl -input common.pod -output common.tested.pod
	# output from 'script/common.pod:9':
	
	CC = 'gcc'
	
	# output from 'script/common.pod:24':
	
	ok 1 - expected value
	
	# Generating POD in 'common.tested.pod'.
	1..1

The POD is:

	=head1 Config::Hierarchical cookbook
	
	=head2 Simple usage
	
	Some text
	
	  use Config::Hierarchical ;
	  
	  my $config = new Config::Hierarchical();
	  
	  $config->Set(NAME => 'CC', VALUE => 'acc') ;
	  $config->Set(NAME => 'CC', VALUE => 'gcc') ;
	  
	  my $cc_value = $config->Get(NAME => 'CC') ;
	  
	  print "CC = '$cc_value'\n" ;
	
	=cut

=head2 When things go wrong

	=head1 cookbook
	
	=head2 Simple usage
	
	Some Text
	
	=begin hidden
	
	  my $cc = 'cc' ;
	  my $expected_cc = 'cc' ;
	  
	  is($cc_value, $expected_output) ;
	
	=end hidden

Let's run the above POD through B<pod_tested.pl>.

	$> perl pod_tested.pl -input test.pod -output test.tested.pod
	Global symbol "$cc_value" requires explicit package name at 'script/test.pod' line 12, <$in_fh> line 15.
	Global symbol "$expected_output" requires explicit package name at 'script/test.pod' line 12, <$in_fh> line 15.
	 at script/pod_tested.pl line 31
	# Looks like your test died before it could output anything.

Oops! This is a rather common error, copy/pasting code and modifying it for pod.

The following pod:

	=head1 HEADER
	
	  my $cc =  ;
	  my $expected_cc = 'cc' ;
	  
	  is($cc, $expected_cc) ;
	
	=cut 

produces:

	syntax error at 'script/error_1.pod' line 9, at EOF
	 at script/pod_tested.pl line 31
	# Looks like your test died before it could output anything.

while:

	=head1 HEADER
	
	  sub error { 1/0 }
	  
	  error() ;
	
	=cut 

produces:

	Illegal division by zero at 'script/error_2.pod' line 5, <$in_fh> line 10.
	 at script/pod_tested.pl line 31
	# Looks like your test died before it could output anything.

=head2 keeping your context together

	=head1 HEADER
	
	Some text
	
	  my $cc_value = 'CC' ;
	  
	  print "CC = '$cc_value'\n" ;
	
	More text or code examples. 
	
	=begin not_tested
	
	  # this section is not part of the test but is part of the POD
	  
	  my $non_tested_code = 1 ;
	  DoSomething() ;
	
	=end not_tested
	
	=begin hidden
	
	  my $expected_output = 'gcc' ;
	  is($cc_value, $expected_output) ;
	
	=end hidden
	
	=cut 

The example above defines a variable in a section and uses it in another section.

the output would be:

	# output from 'script/context.pod:7':
	
	CC = 'CC'
	
	# output from 'script/context.pod:20':
	
	not ok 1
	#   Failed test at 'script/context.pod' line 21.
	#          got: 'CC'
	#     expected: 'gcc'
	
	# No POD output will be generated.
	# Failed tests: 1.
	1..1
	# Looks like you failed 1 test of 1.

Note that any test fails and the output file already exists, pod_tested will rename the existing file
so there is little risk for using an invalid file.

=head2 Resetting your context

	=head1 HEADER
	
	=head2 Example 1
	
	  my $cc_value = 'CC' ;
	
	<Some explaination about test 1 here>
	
	=begin hidden
	
	  is($cc_value, 'CC') ;
	
	=end hidden
	
	=head2 Example 2
	
	  my $cc_value = 'ABC' ;
	
	<Some explaination about test 2 here>
	
	=begin hidden
	
	  is($cc_value, 'ABC') ;
	
	=end hidden
	
	=cut

Running the above pod gives the following output:

	# output from 'script/new_context_error.pod:7':
	
	
	# output from 'script/new_context_error.pod:16':
	
	ok 1 - expected value
	
	"my" variable $cc_value masks earlier declaration in same scope at 'script/new_context_error.pod' line 24, <$in_fh> line 27.
	# output from 'script/new_context_error.pod:24':
	
	
	# output from 'script/new_context_error.pod:32':
	
	ok 2 - expected value
	
	# Generating POD in 'new_context_error.tested.pod'.
	1..2

Local variables are kept between test sections. What we want is two separate section. This can be achieved with
B<=for POD::Tested reset>

	=head1 HEADER
	
	= head2 Example 1
	
	  my $cc_value = 'CC' ;
	
	<Some explaination about test 1 here>
	
	=begin hidden
	
	  is($cc_value, 'CC') ;
	
	=end hidden
	
	=head2 Example 2
	
	=for POD::Tested reset
	
	  my $cc_value = 'ABC' ;
	
	<Some explaination about test 2 here>
	
	=begin hidden
	
	  is($cc_value, 'ABC') ;
	
	=end hidden
	
	=cut

Gives:

	# output from 'script/new_context.pod:7':
	
	
	# output from 'script/new_context.pod:15':
	
	ok 1 - expected value
	
	# output from 'script/new_context.pod:25':
	
	
	# output from 'script/new_context.pod:33':
	
	ok 2 - expected value
	
	# Generating POD in 'new_contex.tested.pod'.
	1..2

and this POD:

	=head1 HEADER
	
	= head2 Example 1
	
	  my $cc_value = 'CC' ;
	
	<Some explaination about test 1 here>
	
	=head2 Example 2
	
	  my $cc_value = 'ABC' ;
	
	<Some explaination about test 2 here>
	
	=cut

=head2 Generating POD

So far we have code in pod that we can test and the code itself is kept as part of the generated POD. Let's add the 
result of some code execution to the POD. We'll use B<generate_pod> to achieve that.

	=head1 Config::Hierarchical cookbook
	
	=head2 Simple usage
	
	  use Config::Hierarchical ;
	   
	  my $config = new Config::Hierarchical(); 
	  $config->Set(NAME => 'CC', VALUE => 'acc') ;
	  
	  my $cc_value = $config->Get(NAME => 'CC') ;
	  print "CC = '$cc_value'\n" ;
	
	Result:
	
	=begin hidden
	
	  my $expected_output = 'acc' ;
	  is($cc_value, $expected_output) ;
	  
	  generate_pod("  CC = '$expected_output'\n\n") ;
	  generate_pod($config->GetHistoryDump(NAME => 'CC')) ;
	
	=end hidden
	
	=cut

running this gives this output:

	# output from 'script/generate_pod.pod:10':
	
	CC = 'acc'
	
	# output from 'script/generate_pod.pod:24':
	
	ok 1 - expected value
	
	# Generating POD in 'generate_pod.tested.pod.pod'.
	1..1

and the generated POD looks like:

	=head1 Config::Hierarchical cookbook
	
	=head2 Simple usage
	
	  use Config::Hierarchical ;
	
	  my $config = new Config::Hierarchical();
	  $config->Set(NAME => 'CC', VALUE => 'acc') ;
	
	  my $cc_value = $config->Get(NAME => 'CC') ;
	  print "CC = '$cc_value'\n" ;
	
	Result:
	
	  CC = 'acc'
	
	History for variable 'CC' from config 'Anonymous' created at ''script/generate_pod.pod':13':
	`- 0
	   |- EVENT = CREATE AND SET. value = 'acc', category = 'CURRENT' at ''script/generate_pod.pod':14', status = OK.
	   `- TIME = 0
	
	=cut

you don't need to copy/paste output from your modules into your POD as you can generate it directly.

=head2 Using more test modules than the default ones

simply use the modules you need in a B<=begin hidden> section.

	=begin hidden
	
		use Test::Some::Great::Module ;
	
	=end hidden

=head1 SUBROUTINES/METHODS

=cut

#-------------------------------------------------------------------------------------------------------------------------------

my $global_current_active_parser ;

#-------------------------------------------------------------------------------------------------------------------------------

sub new
{
	
=head2 new

=head3 Options

You must, in the new sub, pass what your POD source is with one of the following options:

=over 4

=item * FILE_HANDLE


=item * FILE


=item * STRING


=back


Other options:

=over 2

=item * VERBOSE  

Set to true to display extra information when parsing and testing POD.

=item * VERBOSE_POD_GENERATION

Set to true to display the POD added through B<generate_pod()>.

=item * NOT_TESTED

The tag that is used to declare a section that are not common to the POD and the tests.

default value is:

	qr/\s*not_tested/xmi

=item * HIDDEN_TAG 

The tag that is used to declare a test section.

default value is:

	qr/\s*hidden/xmi

=item * RESET_TAG 

The tag that is used to reset the lexical context. Type is a B<qr>.

default value is:

	qr/\s*POD::Tested\s+reset/xmi

=item * DEFAULT_TEST_MODULES

the test modules loaded when B<POD::Tested> starts.

default value is:

	use Test::More ;
	use Test::Block qw($Plan);
	use Test::Exception ;
	use Test::Warn ;
	
	plan qw(no_plan) unless(defined Test::More->builder->has_plan());

if you use Test::More, which you should, the last line is necessary only when B<POD::Tested> is installed or
tested.

=back

=cut

my ($class, @setup_data) = @_ ;

confess 'Invalid constructor call!' if @setup_data % 2 ;

my $object = 
	{
	BLOCK_START => 0,
	VERBOSE     => 0,
	VERBOSE_POD_GENERATION => 0,
	STATE       => $EMPTY_STRING,
	CODE        => $EMPTY_STRING,
	POD         => $EMPTY_STRING,
	LP          => Lexical::Persistence->new(),
	
	NOT_TESTED_TAG  => 	qr/\s*not_tested/sxmi,
	HIDDEN_TAG    => qr/\s*hidden/sxmi,
	RESET_TAG   => qr/\s*POD::Tested\s+reset/sxmi,
	
	DEFAULT_TEST_MODULES => <<'EOM',
use Test::More ;
use Test::Block qw($Plan);
use Test::Exception ;
use Test::Warn ;

plan qw(no_plan) unless(defined Test::More->builder->has_plan());

EOM

	@setup_data,
	} ;

$global_current_active_parser = $object ;

my($code_as_text, $code) 
	= GetWrappedCode
		(
		$object->{LP},
		$object->{DEFAULT_TEST_MODULES},
		$EMPTY_STRING,
		$EMPTY_STRING,
		'POD::Test::new',
		0
		) ;
		
eval { $code->() } ;

my ($package, $file_name, $line) = caller() ;
bless $object, $class ;

$object->initialize() ;

if(defined $object->{FILE_HANDLE})
	{
	$object->parse_from_filehandle($object->{FILE_HANDLE}) ;	
	}
elsif(defined $object->{FILE})
	{
	$object->parse_from_file($object->{FILE}) ;	
	}
elsif(defined $object->{STRING})
	{
	$object->parse_from_filehandle( IO::String->new($object->{STRING})) ;	
	}
else
	{
	croak "Expecting input data through argument 'STRING', 'FILE' or 'FILE_HANDLE'!\n" ;
	}

$object->RunTestCode() ;

return($object) ;
}

#-------------------------------------------------------------------------------------------------------------------------------

sub command 
{ 
	
=head2 command

Handles POD commands. See Pod::Parser for more information.

=cut

my ($parser, $command, $paragraph, $line_num, $pod_para) = @_ ;

chomp($paragraph) ;
chomp($paragraph) ;
#~ print "<$command> <$paragraph><$line_num>" ;

for($command)
	{
	$_ eq 'for' and do
		{
		if($paragraph =~ $parser->{RESET_TAG})
			{
			$parser->{LP}= Lexical::Persistence->new() ;
			}
		else
			{
			$parser->{POD} .= "=$command $paragraph\n\n" ;
			}
			
		last ;
		} ;
		
	$_ eq 'begin' && do
		{
		$parser->{STATE} = $paragraph ;
		$parser->{BLOCK_START} = 0 ;
		
		 if($paragraph =~ $parser->{HIDDEN_TAG})
			{
			}
		else
			{
			$parser->{POD} .= "=$command $paragraph\n\n" ;
			}
			
		last ;
		} ;
		
	$_ eq 'end' && do
		{
		 if($paragraph =~ $parser->{HIDDEN_TAG})
			{
			$parser->RunTestCode() ;
			}
		else
			{
			$parser->{POD} .= "=$command $paragraph\n\n" ;
			}
			
		$parser->{BLOCK_START} = 0 ;
		$parser->{STATE} = $EMPTY_STRING;
		
		last ;
		} ;
		
	$parser->{POD} .= "=$command $paragraph\n\n" ;
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------------------------------------------------------

sub RunTestCode
{

=head2 RunTestCode

Not to be used directly.

=cut

my ($parser) = @_ ;

return(0) if $parser->{CODE} eq $EMPTY_STRING ;

my $input=  $parser->input_file() ;
$input = $global_current_active_parser->{INPUT} if defined $global_current_active_parser->{INPUT} ;

my $line = $parser->{BLOCK_START} ;
$line= $global_current_active_parser->{LINE} if defined $global_current_active_parser->{LINE} ;

EvalInContext
	(
	$parser->{LP},
	$parser->{CODE},
	$parser->{VERBOSE},
	$input ,
	$line,
	) ;

$parser->{CODE} = $EMPTY_STRING ;

return(1) ;
}

#-------------------------------------------------------------------------------------------------------------------------------

sub verbatim 
{
	
=head2 verbatim

Handles POD verbatim sections. See Pod::Parser for more information.

=cut

my ($parser, $paragraph, $line_num, $pod_para) = @_;

$parser->{BLOCK_START} =  $line_num if $parser->{BLOCK_START} == 0;

#~ print "verbatim $parser->{STATE} >>$paragraph<<\n" ;

if($parser->{STATE} =~ $parser->{HIDDEN_TAG})
	{
	$parser->{CODE} .= $paragraph ;
	}
elsif($parser->{STATE} eq $EMPTY_STRING)
	{
	$parser->{CODE} .= $paragraph ;
	$parser->{POD} .= $paragraph ;
	
	$parser->{BLOCK_START} = 0 ;
	}
else
	{
	$parser->{POD} .= $paragraph ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------------------------------------------------------

sub textblock 
{
	
=head2 textblock

Handles POD textblocks. See Pod::Parser for more information.

=cut

my ($parser, $paragraph, $line_num, $pod_para) = @_;

#~ print "textblock $parser->{STATE} >>$paragraph<<\n" ;

$parser->RunTestCode() ;

$parser->{BLOCK_START} =  $line_num if $parser->{BLOCK_START} == 0;

if($parser->{STATE} =~ $parser->{HIDDEN_TAG})
	{
	$parser->{CODE} .= $paragraph ;
	}
else
	{
	$parser->{POD} .= $paragraph ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------------------------------------------------------

sub generate_pod
{
	
=head2 generate_pod

=cut

my (@pod_snippets) = @_ ;

my ($pod) = join ($EMPTY_STRING, @pod_snippets) ;

if($global_current_active_parser->{VERBOSE_POD_GENERATION})
	{
	my ($package, $file_name, $line) = caller() ;
	
	my $input = '(unknown)';
	$input = $global_current_active_parser->{FILE} if defined $global_current_active_parser->{FILE} ;
	$line= $global_current_active_parser->{LINE} if defined $global_current_active_parser->{LINE} ;
	
	OutputStrings("# Generating POD at '$input' line $line:\n$pod") ;
	}

$global_current_active_parser->{POD} .= $pod ;

return(1) ;
}

#-------------------------------------------------------------------------------------------------------------------------------

sub GetPOD
{
	
=head2 GetPOD

Returns the result of parsing and testing your POD. You can pass the result to L<pod2html> or other pod
transformers.

=cut

my ($parser) = @_;

Readonly my $PADDING_SIZE => 2 ;

my $pod_end = substr($parser->{POD}, -2, 2) ;

my $amount_of_nl = $pod_end =~ tr[\n][\n] ;
my $padding_nl = "\n" x ($PADDING_SIZE - $amount_of_nl) ;

return($parser->{POD} . $padding_nl . "=cut\n") ;
}

#-------------------------------------------------------------------------------------------------------------------------------

sub EvalInContext
{
	
=head2 EvalInContext

Not to be used directly.

=cut

my ($lp, $original_code, $verbose, $file, $line) = @_ ;

OutputStrings("# output from '$file:$line':\n\n") ;

if($verbose)
	{
	OutputStrings(<<"EOC") ;
running code from '$file:$line':

$original_code

EOC
	}
	
my($code_as_text, $code) = GetWrappedCode($lp, $EMPTY_STRING, $original_code, $EMPTY_STRING, $file, $line) ;

eval { $code->() } ;
if($EVAL_ERROR)
	{
	croak $EVAL_ERROR  ;
	}	
	
OutputStrings("\n") ;

return(1) ;
}

#-------------------------------------------------------------------------------------------------------------------------------

sub GetWrappedCode
{ ## no critic (Subroutines::ProhibitManyArgs)
	
=head2 GetWrappedCode

Not to be used directly.

=cut

my ($lp, $code_header, $code, $code_footer, $file, $line) = @_ ;

my $lexical_variables = join($EMPTY_STRING, map { "my $_;\n" } keys %{$lp->get_context('_')}) ;

my $subified = <<"EOC" ;
#line 0 'GetWrappedCode'
sub
{
$lexical_variables

$code_header

#line $line '$file'
$code

$code_footer
} ;
EOC

my $compiled = eval $subified ; ## no critic (eval)
croak $EVAL_ERROR if $EVAL_ERROR ;

my $wrapped_code = $lp->wrap($compiled) ;

return($subified, $wrapped_code) ;
}

#-------------------------------------------------------------------------------------------------------------------------------

sub OutputStrings
{

=head2 OutputStrings

Not to be used directly.

=cut

my (@strings) = @_ ;

print(@strings) or croak $ERRNO ;

return ;
} 

#-------------------------------------------------------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POD::Tested

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POD-Tested>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-pod-tested@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/POD-Tested>

=back

=head1 SEE ALSO

L<Test::Inline>

L<Test::Pod::Snippets>

L<Lexical::Persistence>

L<http://chainsawblues.vox.com/library/post/writing-a-perl-repl-part-3---lexical-environments.html>

=cut
