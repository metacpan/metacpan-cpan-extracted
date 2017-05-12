package Ravenel::SubScraper;

use strict;
use PPI;
use PPI::Dumper;
use Data::Dumper;
use Carp qw(cluck confess);
use FindBin;
use File::Basename;

our $debug  = 0;
our $debug2 = 0;
our $debug3 = 0;
#####################

sub _cleanup_sub_name {
	my $sub_name = shift;

	if ( $sub_name =~ /^qq\(/ ) {
		$sub_name =~ s/^qq\(//;
		$sub_name =~ s/\)$//;
	} elsif ( $sub_name =~ /^['"].*['"]$/ ) {
		$sub_name =~ s/^['"]//;
		$sub_name =~ s/['"]$//;
	}

	return $sub_name;
}

sub get_sub {
	my $token    = shift;
	my $sub_name = shift;

	print "(get_sub): Before while loop: " . $token->content() . ", sub_name=$sub_name\n" if ( $debug );

	if ( not $sub_name ) {
		my $sub_name_tag = &rewind_look_for(undef, "PPI::Token::Quote::Single", $token);
		$sub_name = &_cleanup_sub_name($sub_name_tag->content());
	}

	while ( 1 ) {
		my $previous_token = $token;
		$token = $token->next_token();
		
		print "(get_sub): while loop token: " . $token->content() . "\n" if ( $debug );
		my $FOO = <STDIN> if ( $debug3 );

		if ( $token ) {
                        #if ( $token->isa("PPI::Token::Quote::Single") ) {
			# This is needed when the value of function is 
                        #        $sub_name = &_cleanup_sub_name($token->content());
			#	print "(get_sub): have sub name: $sub_name\n" if ( $debug );
			#} elsif ( $token->isa("PPI::Token::Structure") and $token->content() =~ /^\s*\{\s*$/ ) {
			if ( $token->isa("PPI::Token::Structure") and $token->content() =~ /^\s*\{\s*$/ ) {
				print "found sub start\n" if ( $debug );
				$token = $previous_token;
				last;
			}
		} else {
			confess("Uhh, help?!");
		}
	}

	print "(get_sub): Begin sub routine content! (sub_name=$sub_name)\n" if ( $debug );

	my $nest_level  = 1;
	my $sub_content = '';

	while ( 1 ) {
		$token = $token->next_token();
		confess("Sub started, but no content afterwards?") if ( not $token );

		$sub_content .= $token->content();

		if ( $debug ) {
			printf( "(%d) %-30s %-10s\n", $nest_level, ref($token), $token->content() );
			print "\n---------------------$sub_name\n";
			print $sub_content . "\n";
			my $foo = <STDIN> if ( $debug2 );
		}

		if ( $token->isa("PPI::Token::Structure") and $token->content() =~ /[\{\}]/ ) {
			if ( $token->content() eq '{' ) {
				$nest_level++;
			} elsif ( $token->content() eq '}' ) {
				$nest_level--;
				if ( $nest_level == 1 ) {
					last;
				}
			}
		}
	}
	return ( $sub_name, $sub_content, $token );
}

# This function allows you to look for a type (and with specific content, but not required)
sub rewind_look_for {
	my $look_for = shift;
	my $type     = shift;
	my $token    = shift;

	while ( 1 ) {
		my $t = $token->previous_token();
		print "(rewind_look_for): " . $t->content() . " " . ref($t) . "\n" if ( $debug );

		if ( 
			( not $type or ( $type and $t->isa($type) ) )
			and 
			( not $look_for or ( $look_for and $t->content() eq $look_for ) ) 
		) {
			return $t;
		} elsif ( ( $t->isa("PPI::Token::Operator") and $t->content() eq '=>' ) or $t->isa("PPI::Token::Whitespace") ) {
			$token = $t;
		} else {
			return undef;
		}
	}
}

sub find_sub {
	my $function_name   = shift;
	my $doc             = shift;
	my $actual_sub_name = shift;

	my ( $line_num, $col_num ) = ( 0, 0 );
	while ( 1 ) {
		# I think this has to be really, really smart (know your position, and don't match if it is less than or equal to the current match
		my $ref_tok = $doc->find( sub { 
			$_[1]->content() eq $function_name
			and ( 
				$_[1]->line_number() >= $line_num
				or ( $_[1]->line_number() == $line_num and $_[1]->column_number() > $col_num )
			)
			
		} );
		if ( $ref_tok and ref($ref_tok) eq 'ARRAY' ) {
			if ( my $sub_token = &rewind_look_for('sub', "PPI::Token::Word", $ref_tok->[0]) ) {
				print "(find_sub): rewind found a sub! line=" . $ref_tok->[0]->line_number() . " col=" . $ref_tok->[0]->column_number() . "\n" if ( $debug );
				return &get_sub($sub_token, ( $function_name eq $actual_sub_name ? $function_name : $actual_sub_name ) );
			} else {
				$line_num = $ref_tok->[0]->line_number();
				$col_num  = $ref_tok->[0]->column_number();
			}
		}
	}
}

sub scrape_subs {
	my $class = shift if ( $_[0] eq __PACKAGE__ );
	my $file  = shift;
	$file = basename($file);

	my $doc;
	if ( $file ) {
		if ( $file ne 'Ravenel.pm' and $file ne $FindBin::RealScript ) {
			confess("Please stop trying to confuse the sub scraper (file=$file,RealScript=$FindBin::RealScript");
		}
	}

	$doc = new PPI::Document("$FindBin::Bin/$FindBin::RealScript");

	# Find Ravenel::Document first, then find functions from there
	my $token = $doc->find(sub { $_[1]->content() eq "Ravenel::Document" });
	$token = $token->[0] if ( $token and ref($token) eq 'ARRAY' );

	while ( 1 ) {
		print "(scrape_subs): Looking for functions. " . $token->content() . "\n" if ( $debug );
		$token = $token->next_token();
		confess("Could not find local functions in $0") if ( not $token );
		last if ( $token->content() =~ /['"]functions['"]/ );
	}

	# Now move forward to the opening curly brace of the function structure
	while ( 1 ) {
		print "Skipping " . $token->content() . "\n" if ( $debug );
		$token = $token->next_token();
		if ( $token->isa("PPI::Token::Structure") and $token->content() eq '{' ) {
			$token = $token->next_token();
			last;
		}
	}

	my %subs;
	while ( 1 ) {
		print "(scrape_subs): Looking for sub, }, or &. " . ref($token) . " " . $token->content() . "\n" if ( $debug );
		my $FOO = <STDIN> if ( $debug2 );
		
		#if ( $token->isa("PPI::Token::Structure") and $token->content() eq '{' ) {
		 
		if ( $token->isa("PPI::Token::Word") and $token->content() eq 'sub' ) {
			print "(scrape_subs): before while loop/get_sub\n" if ( $debug );

			my ( $sub_name, $sub_content, $t ) = &get_sub($token);

			if ( $debug ) {
				print "================$sub_name===\n";
				print $sub_content . "\n";
				print "================\n";
			}

			confess("Sub ($sub_name) defined multiple times as a local function") if ( $subs{$sub_name} );
			$subs{$sub_name} = "sub $sub_name $sub_content";

			$token = $t->next_token();

		} elsif ( $token->isa("PPI::Token::Cast") and $token->next_token()->isa("PPI::Token::Symbol") ) {

			$token = $token->next_token();

			if ( my ( $function_name ) = $token->content() =~ /^\&(.*)/ ) {

				my $actual_sub_name_tag = &rewind_look_for(undef, "PPI::Token::Quote::Single", $token->previous_token());
				my $actual_sub_name = &_cleanup_sub_name($actual_sub_name_tag->content());

				confess("Illegal local function '$function_name', just use it directly in your tag!") if ( $function_name =~ /::/ );
				
				print "Entering find sub\n" if ( $debug );

				my ( $sub_name, $sub_content, $t ) = &find_sub($function_name, $doc, $actual_sub_name);

				confess("Sub ($sub_name) defined multiple times as a local function") if ( $subs{$sub_name} );
				$subs{$sub_name} = "sub $sub_name $sub_content";
			}
			$token = $token->next_token();
		} elsif ( $token->isa("PPI::Token::Structure") and $token->content() eq '}' ) {
			last;

		} else {
			$token = $token->next_token();
		}
		if ( $debug3 ) {
			print "Sub scraper loop\n";
			my $foooo = <STDIN>;
		}
	}
	return \%subs;
}

1;
