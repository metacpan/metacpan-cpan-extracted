package Padre::Plugin::XS::PerlXS;

use v5.10.1;
use warnings;
use strict;

use Padre::Current;
use Padre::Logger;
our $VERSION = '0.12';
use parent qw(Padre::Plugin);

sub colorize {
#	my $self = shift;
	TRACE("PerlXS colorize called") if DEBUG;
	# these are arguments: (maybe use for from/to?)
	#$current->editor->GetEndStyled,
	#$event->GetPosition

	my $doc = Padre::Current->document;

	#my $mime_type = $doc->get_mimetype;
	my $editor = $doc->editor;

	# TODO we might need not remove all the color, just from a certain section
	# TODO reuse the $first passed to the method
	#$doc->remove_color;

	my $c_keywords = join(
		' ', qw(
			auto break case char const continue default do
			double else enum extern float for goto if
			int long register return short signed sizeof static
			struct switch typedef union unsigned void volatile while
			)
	);
	my $pp_keywords = join(
		' ',
		'#define', '#include', '#if', '#ifdef', '#endif', '#undef',
		qw(
			__FILE__ __LINE__ __DATE__ __TIME__
			__STDC__ __STDC_VERSION__ __STDC_HOSTED__
			__cplusplus __OBJC__ __ASSEMBLER__
			__GNUC__ __COUNTER__ __GFORTRAN__
			__GNUC_MINOR__ __GNUC_PATCHLEVEL__
			__GNUG__ __STRICT_ANSI__ __ELF__ __VERSION__
			__OPTIMIZE__ __OPTIMIZE_SIZE__ __NO_INLINE__
			__GNUC_PATCHLEVEL__
			)
	);

	# TODO: there are lots more gnu specific pp keywords...

	my $perl_simple_types = join(
		' ', qw(
			I32 U32 STRLEN
			)
	);
	my $perlapi_structs = join(
		' ', qw(
			SV AV HV HE IV NV PV OP
			)
	);

	# TODO: Add colon where appropriate? Does that work at all?
	my $xs_keywords = join(
		' ', qw(
			MODULE PACKAGE ALIAS
			OUTPUT RETVAL
			CODE PPCODE PREFIX
			INIT NO_INIT PREINIT
			POSTCALL NO_OUTPUT CLEANUP
			INPUT SCOPE C_ARGS
			OUTLIST IN IN_OUTLIST IN_OUT
			BOOT REQUIRE VERSIONCHECK
			PROTOTYPES ENABLE DISABLE
			OVERLOAD FALLBACK INTERFACE
			INTERFACE_MACRO INCLUDE CASE
			THIS NO_INIT DESTROY
			)
	);

	my $c_keywords_docs = 'FIXME TODO';

	# TODO: cache
	my $perlapi_keywords = join( ' ', keys %{ $doc->keywords } );

#	$editor->SetLexer(Wx::Scintilla::Constant::SCLEX_CPP);
	$editor->SetProperty( "styling.within.preprocessor", 1 );

	# normal keywords (here: C)
	$editor->SetKeyWords( 0, $c_keywords . ' ' . $pp_keywords . ' ' . $perl_simple_types );

	# perlapi stuff and xs stuff
	$editor->SetKeyWords( 1, $perlapi_structs . ' ' . $xs_keywords . ' ' . $perlapi_keywords );
	$editor->SetKeyWords( 2, $c_keywords_docs );
	$editor->SetProperty( "braces.cpp.style", 10 );

	return ();
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Padre::Plugin::XS::PerlXS - previous code needs to be removed, but checked before hand.

=head1 VERSION

version: 0.12

=head1 METHODS

=over 4

=item * colorize


=back

=head1 AUTHOR

See L<Padre::Plugin::XS>

=head2 CONTRIBUTORS

See L<Padre::Plugin::XS>

=head1 COPYRIGHT

See L<Padre::Plugin::XS>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
