# test

use strict ;
use warnings ;

use Data::TreeDumper ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
use Test::Block qw($Plan);

use POD::Tested ; 
use IO::String;
use Directory::Scratch ;

{
local $Plan = {'real empty POD' => 1} ;

my $parser = POD::Tested->new(FILE_HANDLE => IO::String->new(''));

my $expected_text = <<"EOE" ;


=cut
EOE

is($parser->GetPOD(), $expected_text, 'real empty POD') ;
}

{
local $Plan = {'empty POD' => 1} ;

my $parser = POD::Tested->new(FILE_HANDLE => IO::String->new(<<"EOT")) ;	

EOT

my $expected_text = <<"EOE" ;


=cut
EOE

is($parser->GetPOD(), $expected_text, 'empty POD') ;
}

{
local $Plan = {'heads POD' => 1} ;

my $parser = POD::Tested->new(FILE_HANDLE => IO::String->new(<<"EOT")) ;
=head1 HEAD1

=head2 HEAD2

=cut
EOT

my $expected_text = <<"EOE" ;
=head1 HEAD1

=head2 HEAD2

=cut
EOE

is($parser->GetPOD(), $expected_text, 'heads POD') ;
}

{
local $Plan = {'text POD' => 1} ;

my $parser = POD::Tested->new(FILE_HANDLE => IO::String->new(<<"EOT")) ;
=head1 HEAD1

some text

=head2 HEAD2

more text

=cut
EOT

my $expected_text = <<"EOE" ;
=head1 HEAD1

some text

=head2 HEAD2

more text

=cut
EOE

is($parser->GetPOD(), $expected_text, 'text POD') ;
}

{
local $Plan = {'test POD' => 2} ; # the one in this test plust the one in the POD

my $parser = POD::Tested->new(FILE_HANDLE => IO::String->new(<<'EOT')) ;
=head1 HEAD1

some text

  my $cc = 'gcc' ;

# some text
# more

  my $ar = 'ar' ;

=begin hidden

  is($cc,'gcc') ;

=end hidden

=cut
EOT


my $expected_text = <<'EOE' ;
=head1 HEAD1

some text

  my $cc = 'gcc' ;

# some text
# more

  my $ar = 'ar' ;

=cut
EOE

is($parser->GetPOD(), $expected_text, 'test POD') ;
}

{
local $Plan = {'common POD' => 2} ; # the one in this test plust the one in the POD

my $parser = POD::Tested->new(FILE_HANDLE =>IO::String->new(<<'EOT')) ;
=head1 HEAD1

some text

  my $cc = 'gcc' ;
  is($cc,'gcc') ;

=cut
EOT

my $expected_text = <<'EOE' ;
=head1 HEAD1

some text

  my $cc = 'gcc' ;
  is($cc,'gcc') ;

=cut
EOE

is($parser->GetPOD(),$expected_text, 'common POD') ;
}

{
local $Plan = {'generate POD' => 1} ; # the one in this test plust the one in the POD

my $parser = POD::Tested->new(FILE_HANDLE =>IO::String->new(<<'EOT')) ;
=head1 HEAD1

some text

  my $cc = 'gcc' ;

=begin hidden

  generate_pod("generates: '$cc'\n") ;

=end hidden

=cut
EOT

my $parsed_text = $parser->GetPOD() ;

my $expected_text = <<'EOE' ;
=head1 HEAD1

some text

  my $cc = 'gcc' ;

generates: 'gcc'

=cut
EOE

is($parsed_text,$expected_text, 'generate POD') ;
}

{
local $Plan = {'share variables' => 1} ; # the one in this test plust the one in the POD

my $parser = POD::Tested->new(FILE_HANDLE =>IO::String->new(<<'EOT')) ;
=head1 HEAD1

some text

=begin hidden

  my $cc = 'gcc' ;

=end hidden

=begin hidden

  generate_pod("generates: '$cc'\n\n") ;

=end hidden

=begin something

something

  something

=end something

=cut
EOT

my $parsed_text = $parser->GetPOD() ;

my $expected_text = <<'EOE' ;
=head1 HEAD1

some text

generates: 'gcc'

=begin something

something

  something

=end something

=cut
EOE

is($parsed_text,$expected_text, 'share variables') ;
}

{
local $Plan = {'verbose' => 1} ; # the one in this test plust the one in the POD

my $parser = POD::Tested->new(VERBOSE => 1, FILE_HANDLE =>IO::String->new(<<'EOT')) ;
=head1 HEAD1

some text

=begin hidden

  my $cc = 'gcc' ;

=end hidden

=begin hidden

  generate_pod("generates: '$cc'\n\n") ;

=end hidden

=begin something

=end something

=cut
EOT

my $parsed_text = $parser->GetPOD() ;

my $expected_text = <<'EOE' ;
=head1 HEAD1

some text

generates: 'gcc'

=begin something

=end something

=cut
EOE

is($parsed_text,$expected_text, 'verbose does not affect generated POD') ;
}

{
local $Plan = {'for' => 1} ; # the one in this test plust the one in the POD

my $parser = POD::Tested->new(FILE_HANDLE =>IO::String->new(<<'EOT')) ;
=head1 HEAD1

some text

=for something ignored

=for POD::Tested reset

=cut
EOT

my $parsed_text = $parser->GetPOD() ;

my $expected_text = <<'EOE' ;
=head1 HEAD1

some text

=for something ignored

=cut
EOE

is($parsed_text,$expected_text, 'for') ;
}

{
local $Plan = {'compile error' => 1} ; # the one in this test plust the one in the POD

throws_ok
	{
	my $parser = POD::Tested->new(FILE_HANDLE =>IO::String->new(<<'EOT')) ;

=begin hidden

$a = ;

=end hidden

EOT
	}
	qr/syntax error at/, 'compile error' ;
}

{
local $Plan = {'run time error' => 1} ; # the one in this test plust the one in the POD

throws_ok
	{
	my $parser = POD::Tested->new(FILE_HANDLE =>IO::String->new(<<'EOT')) ;

=begin hidden

sub div_by_zero { my $a = 1; $a/0} ;

=end hidden

=begin hidden

div_by_zero() ;

=end hidden

EOT
	}
	qr/Illegal division by zero/, 'run time error' ;
}


{
local $Plan = {'no error' => 1} ; # the one in this test plust the one in the POD

lives_ok
	{
	my $parser = POD::Tested->new(FILE_HANDLE =>IO::String->new(<<'EOT')) ;

=begin hidden

  $a = 1 ;


  $b = '2' ;

=end hidden

EOT
	} 'no syntax error' ;
}

{
local $Plan = {'no error' => 1} ; # the one in this test plust the one in the POD

lives_ok
	{
	my $parser = POD::Tested->new(FILE_HANDLE =>IO::String->new(<<'EOT')) ;

#something

  $a = 1 ;

=begin hidden

#something

  $b = '2' ;

=end hidden

EOT
	} 'no syntax error' ;
}

{
local $Plan = {'verbose pod generation' => 1} ;

lives_ok
	{
	my $parser = POD::Tested->new(VERBOSE_POD_GENERATION => 1, FILE_HANDLE =>IO::String->new(<<'EOT')) ;

#something

  $a = 1 ;

=begin hidden

#something

  $b = '2' ;
  
  generate_pod() ;

=end hidden

EOT
	} 'no syntax error' ;
}

{
local $Plan = {'input' => 1} ;

lives_ok
	{
	my $parser = POD::Tested->new
				(
				VERBOSE_POD_GENERATION=> 1,
				FILE => 'local string IO',
				FILE_HANDLE =>IO::String->new(<<'EOT')) ;

#something

  $a = 1 ;

=begin hidden

#something

  $b = '2' ;
  
  generate_pod() ;

=end hidden

EOT
	} 'no syntax error' ;
}

{
local $Plan = {'all pod is test' => 1} ;

my $parser = POD::Tested->new(FILE_HANDLE =>IO::String->new(<<'EOT')) ;
=head1 HEAD1

  my $cc = 'gcc' ;
  is($cc,'gcc') ;
  
=cut
EOT

}

{
local $Plan = {'multiline verbatim block' => 3} ;

my $parser = POD::Tested->new(FILE_HANDLE =>IO::String->new(<<'EOT')) ;
=head1 HEAD1

some text

  my $cc = 'gcc' ;
  
  
  
  my $v = 1 ;

# some text
# more

  my $ar = 'ar' ;

=begin hidden

  is($cc,'gcc') ;
  is($v,'1') ;

=end hidden

=cut
EOT


my $expected_text = <<'EOE' ;
=head1 HEAD1

some text

  my $cc = 'gcc' ;
  
  
  
  my $v = 1 ;

# some text
# more

  my $ar = 'ar' ;

=cut
EOE

is($parser->GetPOD(),$expected_text, 'multiline verbatim block') ;
}

{
local $Plan = {'multiline verbatim block taken as single test' => 3} ;

lives_ok
	{
	my $parser = POD::Tested->new(FILE_HANDLE =>IO::String->new(<<'EOT')) ;
=head1 HEAD1

some text

  for my $v (qw(1 2))
	{
	# test if blank lines split the test block
	
	
	my $v1 = $v ;
	
	my $v2 = $v1 ;
	
	is($v2, $v) ;
	
	}

=cut
EOT
	}

}

{
local $Plan = {'input through string' => 3} ;

#also does coverage test for INPUT and LINE

lives_ok
	{
	my $parser = POD::Tested->new(STRING => <<'EOT', VERBOSE_POD_GENERATION => 1, INPUT => 'input name from test', LINE => 'input line from a test') ;
=head1 HEAD1

some text

  for my $v (qw(1 ))
	{
	
	is($v, 1) ;
	
	}

  generate_pod("  #test\n") ;

=cut
EOT


	is($parser->GetPOD(),<<'EOT', 'strin input with input and line') ;
=head1 HEAD1

some text

  for my $v (qw(1 ))
	{
	
	is($v, 1) ;
	
	}

  generate_pod("  #test\n") ;

  #test

=cut
EOT
	}

}

{
local $Plan = {'input through file' => 2} ;

lives_ok
	{
	my $scratch = new Directory::Scratch();
	my ($fh,$file_name) = $scratch->tempfile() ;
	
	print $fh <<'EOT';
=head1 HEAD1

some text

=for something ignored

=for POD::Tested reset

=cut
EOT
	close($fh) ;

	my $parser = POD::Tested->new(FILE => "$file_name") ;

	my $parsed_text = $parser->GetPOD() ;

	my $expected_text = <<'EOE' ;
=head1 HEAD1

some text

=for something ignored

=cut
EOE

	is($parsed_text,$expected_text, 'for') ;
	}

}
