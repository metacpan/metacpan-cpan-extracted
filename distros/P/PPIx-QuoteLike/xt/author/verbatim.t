package main;

use 5.010;

use strict;
use warnings;

use ExtUtils::Manifest qw{ maniread };
use Module::Load::Conditional qw{ check_install };
use Test2::V0;

use constant VERBATIM	=> '## VERBATIM ';
use constant VERBATIM_END	=> VERBATIM . 'END';

my $manifest = maniread();

my %original;

foreach ( sort keys %{ $manifest } ) {
    next unless m| \A lib/ .* [.] pm \z |smx;

    open my $fh, '<', $_
	or die "Unable to open $_: $!";

    my %context = (
	file_handle	=> $fh,
	file_name	=> $_,
    );

    while ( <$fh> ) {

	index $_, VERBATIM
	    and next;

	my ( undef, undef, $kind, $arg ) = split qr< \s+ >smx, $_, 4;
	chomp;
	defined $kind
	    or die "Bug - \$kind not defined from '$_'";

	my $code = __PACKAGE__->can( "verbatim_$kind" )
	    or die sprintf '%s %s not recognized', VERBATIM, $kind;

	$code->( $arg, \%context );

    }

    if ( defined $context{expect} ) {
	is $context{count}, $context{expect},
	    "$context{file_name} contains expected number of verbatim sections";
    } elsif ( ! $context{count} ) {
	SKIP: {
	    skip "$context{file_name} contains no verbatim sections";
	}
    }

}

done_testing;

sub read_verbatim_section {
    my ( $context ) = @_;
    my $fh = $context->{file_handle};
    my $line = $.;

    my $content = '';

    local $_ = undef;
    while ( <$fh> ) {
	index $_, VERBATIM_END
	    or return $context->{trim} ? trim_text( $content ) : $content;
	$content .= $_;
    }

    die "Unterminated VERBATIM BEGIN at $context->{file_name} line $line";
}

sub slurp_module {
    my ( $module, $context ) = @_;

    state $content = {};

    return $content->{$module} ||= do {

	my $data = check_install( module => $module )
	    or die "Module $module not installed";

	my $content;
	local $/ = undef;
	open my $fh, '<', $data->{file}
	    or die "Unable to open $data->{file}: $!";
	$content = <$fh>;
	close $fh;

	$context->{trim}
	    and $content = trim_text( $content );

	$content;
    };
}

sub trim_text {
    local $_ = $_[0];
    s/ ^ \s+ //mxg;
    s/ \s+ $ //mxg;
    return $_;
}

sub verbatim_BEGIN {
    my ( $arg, $context ) = @_;

    $context->{count}++;
    my ( $module, $comment ) = split qr< \s+ >smx, $arg, 2;
    my $line = $.;
    my $content = read_verbatim_section( $context );

    my $name = "$context->{file_name} line $line verbatim section found in $module";
    if ( index( slurp_module( $module, $context ), $content ) >= 0 ) {
	pass $name;
    } else {
	fail $name;
    }

    return;
}

sub verbatim_EXPECT {
    my ( $arg, $context ) = @_;

    ( $context->{expect} ) = split qr< \s+ >smx, $arg, 2;
    return;
}

sub verbatim_TRIM {
    my ( $arg, $context ) = @_;
    $context->{count}
	and die "## VERBATIM TRIM must be before first ## VERBATIM BEGIN at $context->{file_name} line $.\n";
    $context->{trim} = $arg || 0;
    return;
}

1;

=begin comment

This test ensures that sections of code copied verbatim from other
modules remain consistent with those modules. It checks any .pm file in
the lib/ directory, as determined from the MANIFEST.

The testing of individual files is driven by annotations in those files.
All annotations must be at the beginning of the line, and start with the
literal string '## VERBATIM '. Annotations are implemented using
subroutines named 'verbatim_*', where the '*' is the third field in the
annotation (counting '##' as the first). For example, '## VERBATIM
BEGIN' is implemented by subroutine verbatim_BEGIN{}. All such
subroutines will be passed the argument of the annotation (the fourth
field, which consists of everything to the end of the input line) and a
reference to a context hash. This context hash may contain the following
keys:

 count - The number of BEGIN blocks found to this point;
 expect - The value of the latest EXPECT annotation, if any;
 file_handle - The input handle to the file being processed;
 file_name - The name of the file being processed.

The following annotations are currently implemented:

## VERBATIM BEGIN module-name ...

This annotation marks the beginning of a verbatim section, which starts
on the next line and continues to the next '## VERBATIM END' annotation.
The module-name is the name of the module from which the section was
copied. This generates a test to ensure that the section actually occurs
in the specified module. Any extra text on the line is ignored.

## VERBATIM END

See '## VERBATIM BEGIN'

## VERBATIM EXPECT number

This annotation specifies the number of verbatim sections to expect in
the file. The actual test this specifies is done after the entire input
file has been processed. This is optional, but recommended to ensure
that '## VERBATIM' annotations have not been clobbered.

If specified more than once, the last specification rules.

## VERBATIM TRIM Boolean-value

This annotation specifies whether leading and trailing white space
should be ignored. It is a fatal error to specify this after the first
'## VERBATIM BEGIN'.

If specified more than once, the last specification rules.

=end comment

=cut

# ex: set textwidth=72 :
