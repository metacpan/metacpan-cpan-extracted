package MyTest;

my $CLASS = __PACKAGE__;

use open ':std', ':encoding(utf8)';

use parent qw(Test::Builder::Module);
@EXPORT
	= qw(license_is license_isnt TODO_license_is TODO_license_isnt license_covered done_testing);

use strict;
use warnings;

use Try::Tiny;
use Regexp::Pattern::License;
use Regexp::Pattern;

my %coverage = (
	name    => { hit => [qw(name)],  miss => [qw(iri)] },
	iri     => { hit => [qw(iri)],   miss => [qw(grant license)] },
	grant   => { hit => [qw(grant)], miss => [qw(iri name)] },
	license => { hit => [qw(text)],  miss => [qw(iri name)] },
);
my @subjects = sort keys %coverage;

# main pattern is the "best" available, according to this custom priority list
my @subjectstack = qw(license grant name iri trait);
my @scopestack   = qw(line sentence paragraph);

#my $defaultsubject = 'anydistinct';

sub license_covered (@)
{
	my ( $id, %data ) = @_;
	my $tb = $CLASS->builder;

#	$tb->todo_start( join ' ', @{ $data{TODO} } )
#		if ( $data{TODO} and @{ $data{TODO} } );
	$tb->subtest( "license $id; check coverage", \&_license_covered, @_ );

#	$tb->todo_end
#		if ( $data{TODO} and @{ $data{TODO} } );
}

sub _license_covered (@)
{
	my ( $id, %data ) = @_;
	my $tb = $CLASS->builder;

	my %todo;
	for ( @{ $data{TODO} } ) {
		$todo{$_} = 1;
	}

	my $pat = $Regexp::Pattern::License::RE{$id};
	$tb->ok( $pat, 'pattern object exists' )
		or return;
	$tb->is_eq( ref($pat), 'HASH', 'pattern object is a hash' )
		or return;

	my @pat = grep {/^pat(?:\.alt\.|[(])?/} keys %{$pat};
	$tb->isnt_num( scalar @pat, 0, "license $id: pattern(s) exist" )
		or return;

	my @pat_subject = grep { $$pat{"pat.alt.subject.$_"} } @subjectstack;
	$tb->ok( scalar @pat_subject, "license $id; subject pattern(s) exist" )
		or return;

	my $gen_subjects = $$pat{gen_args}{subject}{schema}[2];
	$tb->ok( scalar @{$gen_subjects}, 'dynamic pattern list exists' )
		or return;

	# TODO: check for uncovered subjects

	my $re = try { re("License::$id") };
	unless ( $tb->ok( $re, "license $id; use" ) ) {
		return;
	}

	$tb->is_eq( ref($re), 'Regexp', "license $id; pattern is a Regexp" )
		or $re = qr/$re/;

	for my $subject (@subjects) {
		unless ( $coverage{$subject} ) {
			if ( $todo{"subject_$subject"} ) {
				$tb->todo_skip(
					"license $id; subject $subject not yet supported");
			}
			else {
				$tb->ok( 0, "dynamic pattern $subject is supported" );
			}
			next;
		}

		my $re_subject = try { re( "License::$id", subject => $subject ) };

		$tb->todo_start
			if ( $todo{"subject_$subject"} );
		unless ( $tb->ok( $re_subject, "license $id; use subject_$subject" ) )
		{
			$tb->todo_end
				if ( $todo{"subject_$subject"} );
			next;
		}
		$tb->todo_end
			if ( $todo{"subject_$subject"} );

		$tb->is_eq(
			ref($re_subject), 'Regexp',
			"license $id; pattern is a Regexp"
		) or $re_subject = qr/$re_subject/;

		_covered( $id, 'subject', $re_subject, $subject, \%data, \%todo );
	}
}

sub _covered (@)
{
	my ( $id, $type, $re, $subject, $dataref, $todoref ) = @_;
	my %data = %{$dataref};
	my %todo = %{$todoref};
	my $tb   = $CLASS->builder;

	for ( @{ $coverage{$subject}{hit} } ) {
		unless ( $data{$_} ) {
			$tb->todo_skip("license $id; dataset $_ missing");
			next;
		}
		$tb->todo_start
			if ( $type eq 'main' ? $todo{$_} : $todo{"${_}_$subject"} );
		$tb->like(
			$data{$_}, $re,
			$type eq 'main'
			? "license $id; matches pattern $_"
			: "license $id; matches pattern ${_}_$subject"
		);
		$tb->todo_end
			if ( $type eq 'main' ? $todo{$_} : $todo{"${_}_$subject"} );
	}
	for ( @{ $coverage{$subject}{miss} } ) {
		unless ( $data{$_} ) {
			$tb->todo_skip("license $id; dataset $_ missing");
			next;
		}
		$tb->todo_start
			if (
			$type eq 'main' ? $todo{"not_$_"} : $todo{"not_${_}_$subject"} );
		$tb->unlike(
			$data{$_}, $re,
			$type eq 'main'
			? "license $id; misses pattern not_$_"
			: "license $id; misses pattern not_${_}_$subject"
		);
		$tb->todo_end
			if (
			$type eq 'main' ? $todo{"not_$_"} : $todo{"not_${_}_$subject"} );
	}
}

sub license_is ($$;@)
{
	my ( $corpus, $expected, %args ) = @_;

	for ( ref($expected) eq 'ARRAY' ? @{$expected} : $expected ) {
		_license( $corpus, $_, %args );
	}
}

sub license_isnt ($$;@)
{
	my ( $corpus, $expected, %args ) = @_;

	for ( ref($expected) eq 'ARRAY' ? @{$expected} : $expected ) {
		_license( $corpus, undef, $_, %args );
	}
}

sub TODO_license_is ($$;@)
{
	my ( $corpus, $expected, %args ) = @_;
	my $tb = $CLASS->builder;

	$tb->todo_start;
	for ( ref($expected) eq 'ARRAY' ? @{$expected} : $expected ) {
		_license( $corpus, $_, %args );
	}
	$tb->todo_end;
}

sub TODO_license_isnt ($$;@)
{
	my ( $corpus, $expected, %args ) = @_;
	my $tb = $CLASS->builder;

	$tb->todo_start;
	for ( ref($expected) eq 'ARRAY' ? @{$expected} : $expected ) {
		_license( $corpus, undef, $_, %args );
	}
	$tb->todo_end;
}

sub _license ($$;@)
{
	my ( $corpus, $expected, $unexpected, %args ) = @_;
	my $tb = $CLASS->builder;

	# corpus is either scalar (string), array (list of strings)
	for ( ref($corpus) eq 'ARRAY' ? @{$corpus} : $corpus ) {
		$tb->croak($expected) if !$_ and $expected;
		$tb->like(
			$_, _re( $expected, %args ),
			"match for licensepattern $expected"
		) if $expected;

		$tb->unlike(
			$_, _re( $unexpected, %args ),
			"no match for licensepattern $unexpected"
		) if ($unexpected);
	}
}

sub _re ($;$)
{
#	my ( $id, %args ) = @_;
#	my $re = re( "License::$id", %args );
	my ( $id, $subject ) = @_;

#	my $re = re( "License::$id", $subject ? { subject => $subject } : () );
	my $re = re( "License::$id", subject => $subject );
	return '' unless $re;
	return ( ref($re) eq 'Regexp' ) ? $re : qr/$re/;
}

sub done_testing ()
{
	my $tb = $CLASS->builder;

	$tb->done_testing;
}

1;
