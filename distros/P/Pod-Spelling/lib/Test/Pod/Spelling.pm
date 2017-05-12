use strict;
use warnings;
use utf8;

package Test::Pod::Spelling;
our $VERSION = '0.4';

=encoding utf8

=head1 NAME

Test::Pod::Spelling - A Test library to spell-check POD files

=head1 SYNOPSIS

	use Test::Pod::Spelling;
    add_stopwords(qw( Goddard inine ));
	all_pod_files_spelling_ok();
	done_testing();

	use Test::Pod::Spelling (
		spelling => {
				allow_words => [qw[ 
					Goddard LICENCE inline behaviour spelt
				]]
			},
		);
	};
	pod_file_spelling_ok( 't/good.pod' );
	all_pod_files_spelling_ok();
	done_testing();
	
=head1 DESCRIPTION

This module exports two routines, described below, to test POD for spelling errors,
using either Lingua::Ispell and Text::Aspell. One of those modules
must be installed on your system, with their binaries, unless you
plan to use the API to provide your own spell-checker.

As illustrated in L</SYNOPSIS>, above, configuration options for C<Pod::Spelling> can
be passed when the module is used.

A list of words that can be allowed even if not in the dictionary (a stop list)
can be supplied to the spell-checking module when this module is used, via
L</add_stopwords>.
To help keep this list short, common POD that would upset the spell-checker
is skipped - see L<Pod::Spelling/TEXT NOT SPELL-CHECKED> for details.
No support is offered for inlining stoplists into Perl modules, which the
author feels undermines testing. Patches to provide such an option will be
applied, though, if required.

=cut

use base qw( 
	Test::Builder::Module 
	Exporter 
);

my $CLASS = __PACKAGE__;

=head1 DEPENDENCIES

L<Test::Pod|Test::Pod>,
L<Pod::Spelling|Pod::Spelling>,
L<Test::Builder|Test::Builder>.

=cut

use Test::Builder;
require Test::Pod;
require Pod::Spelling;
use Carp;

my $Test = Test::Builder->new;
$Test->{_skip_files} = {};

=head1 EXPORTS

	all_pod_files_spelling_ok() 
	pod_file_spelling_ok() 

=cut

sub import {
    my $self = shift;
    my @args = @_;
    my $spelling_args = {};
    
    # Get the spelling argument:
    for my $i (0..$#args){
    	if ($args[$i] and $args[$i] eq 'spelling'){
    		confess 'During import, the "spelling" argument must point to a HASH or Pod::Spelling object'
    			if $i==$#args
    			or not ref($args[$i+1]) 
    			or ref($args[$i+1]) !~ /^(HASH|Pod::Spelling.*)$/; 
    		# Use to init obj later
    		$spelling_args = $args[$i+1];
			# Remove from args that will be passed to plan()
    		@args = @args[
				0..$i-1,
				$i+2 .. $#args
			];
    	}
    	if ($args[$i] and $args[$i] eq 'skip'){
    		confess 'During import, the "skip" argument must point to an ARRAY'
    			if $i==$#args
    			or not ref($args[$i+1]) 
    			or ref($args[$i+1]) ne 'ARRAY'; 
    		$Test->{_skip_files} = { map {$_=>1} $args[$i+1] };
			# Remove from args that will be passed to plan()
    		@args = @args[
				0..$i-1,
				$i+2 .. $#args
			];
		}
    }
    
    $Test->{_speller} = Pod::Spelling->new( $spelling_args );
    
    my $caller = caller;

    for my $func ( qw(
		add_stopwords all_pod_files_spelling_ok pod_file_spelling_ok
		skip_paths_matching
	)) {
        no strict 'refs';
        *{$caller."::".$func} = \&$func;
    }

    $Test->exported_to($caller);
    $Test->plan(@args);
}

=head1 EXPORTED SUBROUTINES

=head2 C<skip_paths_matching($re1 [, $reN])>

Supply a list of one or more pre-compiled regular
expressions to skip any file paths they match.

=cut

sub skip_paths_matching {
	my @res = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $rv = 1;
	# Make sure they are regex
	foreach my $i (@res){
		if (not ref $i or ref $i ne 'Regexp'){
			$rv = 0;
		}
		else {
			$Test->{_speller}->skip_paths_matching( $i );
		}
	}
	return $rv;
}

=head2 C<all_pod_files_spelling_ok( [@entries] )>

Exactly the same as L<Test::Pod/all_pod_files_ok( [@entries] )>
except that it calls L<Test::Pod/pod_file_ok( FILENAME[, TESTNAME ] )>
to check the spelling of POD files.

=cut

sub all_pod_files_spelling_ok {
	my @args = @_ ? @_ : Test::Pod::_starting_points();
    my @paths = map { -d $_ ? Test::Pod::all_pod_files($_) : $_ } @args;
    my @errors;
    
    PATH:
	foreach my $path (@paths){
		foreach my $re ($Test->{_speller}->skip_paths_matching){
			if ($path =~ $re){
				$Test->skip("path $path because of skip_paths_matching $re");
				next PATH;
			}
		}
        # local $Test::Builder::Level = $Test::Builder::Level + 1;
    	push @errors, pod_file_spelling_ok( $path );
    }

    return keys %{{
    	map {$_=>1} grep {defined} @errors
	}};
}

=head2 C<pod_file_spelling_ok( FILENAME[, TESTNAME ] )>

Exactly the same as L<Test::Pod/pod_file_ok( FILENAME[, TESTNAME ] )>
except that it checks the spelling of POD files.

=cut

sub pod_file_spelling_ok {
	my ($path, $name) = @_;
	return () if exists $Test->{_skip_files}->{$path};
	
	# All good POD has =head1 NAME\n\n$TITLE - $DESCRIPTION
	# so add that title to the dictionary. It may be a script name
	# without colons, so using the module name or path is not enough.
	open my $IN, $path or confess 'Could not open '.$path;
	read $IN, my $file, -s $IN;
	close $IN;
	my ($pod_name) = $file =~ /^=head1\s+NAME[\n\r\f]+\s*(\S+)\s*-\s*/m;
	undef $file;	
	
	if ($pod_name){
		my @words = $pod_name =~ s/:+/ /g;
		$Test->{_speller}->add_allow_words(
			$pod_name,
			split(/\s+/, @words)
		);
	}
	
	if (not $name){
		$name = 'POD spelling test for '. ( $pod_name || $path );
	}
	
	my @errors = $Test->{_speller}->check_file( $path );

	$Test->ok( not( scalar @errors), $name );

	if (@errors){
		foreach my $line ( 0 .. $#{ $Test->{_speller}->{errors} }){
			my $misspelt = $Test->{_speller}->{errors}->[$line];
			if ($misspelt and scalar @$misspelt){
				$Test->diag( sprintf
					'  Unknown word%s in %s (POD line %d): %s.',
					(scalar @$misspelt==1? '':'s'),
					$path, ($line+1), 
					join ', ', map("\"$_\"", @$misspelt)
				);
			}
		}
	}
	
	return @errors;
}

=head2 add_stopwords( @words )

Adds a list of stop-words to those already being used by the spell-checker.

=cut

sub add_stopwords {
	$Test->{_speller}->add_allow_words( @_ );
	return 1;
}

1;

__END__

=head1 TODO

Automatically skip the name of the author as described in 
F<Makefile.PL> or F<Build.PL> or similar.

=head1 AUTHOR AND COPYRIGHT

Copyright Lee Goddard (C) 2011. All Rights Reserved.

Made available under the same terms as Perl.

