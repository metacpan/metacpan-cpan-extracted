package Test2::Tools::LicenseObject;
use strict;
use warnings;

use Regexp::Pattern;
use Regexp::Pattern::License;
use Test2::API qw(context run_subtest);
use Test2::Todo;
use Test2::Util::Ref      qw(rtype);
use Test2::Tools::Compare qw(like unlike);
use Try::Tiny;

our @EXPORT = qw(license_covered);
use base 'Exporter';

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

sub license_covered (@)
{
	my ( $id, %data ) = @_;
	my $ctx  = context();
	my $name = "license $id; check coverage";
	my @diag;    # TODO

	my $bool = run_subtest( $name, \&_license_covered, 1, @_ );

	$ctx->release;
}

sub _license_covered (@)
{
	my ( $id, %data ) = @_;
	my $ctx = context();
	my $name;
	my @diag;    # TODO

	my %todo;
	for ( @{ $data{TODO} } ) {
		$todo{$_} = 1;
	}

	$name = 'pattern object exists';
	my $pat = $Regexp::Pattern::License::RE{$id};
	return $ctx->fail_and_release( $name, @diag ) unless $pat;
	$ctx->pass($name);

	$name = 'pattern object is a hash';
	return $ctx->fail_and_release( $name, @diag )
		unless rtype($pat) eq 'HASH';
	$ctx->pass($name);

	$name = "license $id: pattern(s) exist";
	my @pat = grep {/^pat(?:\.alt\.|[(])?/} keys %{$pat};
	return $ctx->fail_and_release( $name, @diag ) unless @pat;
	$ctx->pass($name);

	$name = "license $id; subject pattern(s) exist";
	my @pat_subject = grep { $$pat{"pat.alt.subject.$_"} } @subjectstack;
	return $ctx->fail_and_release( $name, @diag ) unless @pat_subject;
	$ctx->pass($name);

	$name = 'dynamic pattern list exists';
	my $gen_subjects = $$pat{gen_args}{subject}{schema}[2];
	return $ctx->fail_and_release( $name, @diag ) unless @{$gen_subjects};
	$ctx->pass($name);

	# TODO: check for uncovered subjects

	$name = "license $id; use";
	my $re = try { re("License::$id") };
	return $ctx->fail_and_release( $name, @diag ) unless $re;
	$ctx->pass($name);

	$name = "license $id; pattern is a Regexp";
	return $ctx->fail_and_release( $name, @diag )
		unless rtype($re) eq 'REGEXP';
	$ctx->pass($name);

	_license_subject_covered( $id, $_, \%data, \%todo ) for @subjects;

	$ctx->release;
}

sub _license_subject_covered ($$$$)
{
	my ( $id, $subject, $dataref, $todoref ) = @_;
	my %data = %{$dataref};
	my %todo = %{$todoref};
	my $ctx  = context();
	my $name;
	my @diag;    # TODO

	my $todo
		= Test2::Todo->new(
		reason => "license $id; subject $subject not yet supported" )
		if $todo{"subject_$subject"};

	$name = "license $id, subject $subject, pattern is supported";
	return $ctx->fail_and_release( $name, @diag )
		unless $coverage{$subject};
	$ctx->pass($name);

	my $re = try { re( "License::$id", subject => $subject ) };

	$name = "license $id, use subject_$subject";
	return $ctx->fail_and_release( $name, @diag )
		unless $re;
	$ctx->pass($name);

	like( ref($re), 'Regexp', "license $id; pattern is a Regexp" )
		or $re = qr/$re/;

	for ( @{ $coverage{$subject}{hit} } ) {
		unless ( $data{$_} ) {
			my $todo = Test2::Todo->new( reason => "not yet supported" );
			$ctx->fail("license $id; dataset $_ missing");
			next;
		}

		my $todo = Test2::Todo->new( reason => "not yet supported" )
			if ( $todo{"${_}_$subject"} );
		like(
			$data{$_}, $re,
			"license $id; matches pattern ${_}_$subject"
		);
	}
	for ( @{ $coverage{$subject}{miss} } ) {
		unless ( $data{$_} ) {
			my $todo = Test2::Todo->new( reason => "not yet supported" );
			$ctx->fail("license $id; dataset $_ missing");
			next;
		}
		my $todo = Test2::Todo->new( reason => "not yet supported" )
			if ( $todo{"not_${_}_$subject"} );
		unlike(
			$data{$_}, $re,
			"license $id; misses pattern not_${_}_$subject"
		);
	}

	$ctx->release;
}

1;
