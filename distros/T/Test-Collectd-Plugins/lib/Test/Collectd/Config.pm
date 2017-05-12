package Test::Collectd::Config;

use Test::Collectd::Config::Parse;
use Parse::Lex;
use IO::File;
use strict;
use warnings;

=head1 NAME

Test::Collectd::Config - Reimplementation of L<collectd/liboconfig> in perl.

=head1 VERSION

Version 0.1001

=head1 SYNOPSOS

	use Test::Collectd::Config;

	my $config = parse ( "/etc/collectd.conf" );

This module reimplements the config parser of collectd in perl. It's being used by L<Test::Collectd::Plugins>. The only exported function is L</parse>.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT_OK @EXPORT $BFALSE $IGNORE_mlWHITE_SPACE $CLOSEBRAC $IGNORE_COL $NUMBER $EOL $IGNORE_CONT_QUOTED_STRING $SLASH $ERROR $IGNORE_WHITE_SPACE $OPENBRAC $BTRUE $IGNORE_COMMENT $IGNORE_START_QUOTED_STRING $QUOTED_STRING $DUPE_0_QUOTED_STRING $DUPE_0_UNQUOTED_STRING $UNQUOTED_STRING);
push @ISA, qw(Exporter);
@EXPORT_OK = qw(
	parse
);
@EXPORT = qw(
	parse
);

$VERSION = "0.1001";

my $EOL = '\r?\n';
my $IP_BYTE = '(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])';
my $PORT = '(6(5(5(3[0-5]|[0-2][0-9])|[0-4][0-9][0-9])|[0-4][0-9][0-9][0-9])|[1-5][0-9][0-9][0-9][0-9]|[1-9][0-9]?[0-9]?[0-9]?)';
my $IPV4_ADDR = "$IP_BYTE\\.$IP_BYTE\\.$IP_BYTE\\.$IP_BYTE(:$PORT)?";
my $HEX_NUMBER = '0[xX][0-9a-fA-F]+';
my $OCT_NUMBER = '0[0-7]+';
my $DEC_NUMBER = '[\+\-]?[0-9]+';
my $FLOAT_NUMBER = '[\+\-]?[0-9]*\.[0-9]+([eE][\+\-][0-9]+)?';
my $NUMBER = "($FLOAT_NUMBER|$HEX_NUMBER|$OCT_NUMBER|$DEC_NUMBER)";
my $QUOTED_STRING = '([^\\"]+|\\.)*';
#$QUOTED_STRING = '((?<!\\\)"|.)*';
my $UNQUOTED_STRING = '[0-9A-Za-z_]+';
my $WHITE_SPACE = '[\ \t\b]';
my $NON_WHITE_SPACE = '[^\ \t\b]';

my $ml_buffer;

my @lex = (
	qw(IGNORE_WHITE_SPACE), $WHITE_SPACE,
	qw(IGNORE_COMMENT), '#.*',
	qw(IGNORE_COL), "\\$EOL",
	qw(EOL), $EOL,
	qw(SLASH /),
	qw(OPENBRAC <),
	qw(CLOSEBRAC >),
	qw(BTRUE), '(true|yes|on)$', sub { 1 },
	qw(BFALSE), '(false|no|off)$', sub { 0 },
	qw(UNQUOTED_STRING), ${IPV4_ADDR},
	qw(NUMBER), $NUMBER,
	qw(QUOTED_STRING), "\"$QUOTED_STRING\"",
	qw(DUPE_0_UNQUOTED_STRING), ${UNQUOTED_STRING},
	qw(IGNORE_START_QUOTED_STRING), "\"$QUOTED_STRING\\$EOL", \&_start_string,
	qw(ML:IGNORE_mlWHITE_SPACE), "^${WHITE_SPACE}+",
	qw(ML:IGNORE_CONT_QUOTED_STRING), "${NON_WHITE_SPACE}${QUOTED_STRING}\\${EOL}", \&_cont_string,
	qw(ML:DUPE_0_QUOTED_STRING), "${NON_WHITE_SPACE}${QUOTED_STRING}\"", \&_end_string,
	qw(ERROR .*), \&_error,
);

sub _error {
	die qq!can\'t analyze: "$_[1]"!;
}
sub _start_string {
	$ml_buffer = "";
	($ml_buffer.= $_[1]) =~ s/\\\r?\n$//;
	$_[0] -> lexer -> start ("ML");
}
sub _cont_string {
	($ml_buffer.= $_[1]) =~ s/\\$//;
	return @_;
}
sub _end_string {
	_cont_string (@_);
	$_[0] -> lexer -> start ("INITIAL");
	return $ml_buffer;
}

Parse::Lex->exclusive('ML');
my $lexer = Parse::Lex->new(@lex);
#$lexer -> trace;
$lexer -> skip('');

sub _lex {
	while (my $token = $lexer -> next) {
		return ('', undef) if $lexer->eoi;
		next if $token -> name =~ /^IGNORE_/;
		(my $name = $token->name) =~ s/^DUPE_[^_]+_//;
		return ($name, $token->text);
	}
}

sub _parse_error {die "parser failed ", join ", ", map { "$_: ".${$_[0] -> {$_}}} qw(TOKEN VALUE)}

=head2 parse ( $config_in )

Parses $config_in and returns the compiled configuration in the form of a nested structure identical to the one returned to the plugin's config callback. The 

=cut

sub parse {
	my $in = shift || die "usage: __PACKAGE__->parse(\$config_in)";
	my $config;
	if (ref $in && $in->isa("GLOB")) {
		$config = $in;
	} elsif (!ref $in) {
		my $fh = IO::File -> new ( $in, 'r' ) or die $!;
		local $/;
		$config = $fh;
	} else {
		die 'parse($config_in) must be either a string (filename) or a GLOB (handle).';
	}
	$lexer->from($config);
	my $parser = Test::Collectd::Config::Parse -> new;
	my $value = $parser -> YYParse(yylex => \&_lex, yyerror => \&_parse_error, yydebug => 0x00);
}

1;

