use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use t::scan::Util;

test(<<'TEST'); # AUTRIJUS/Lingua-ZH-Summarize-0.01/Summarize.pm
my %punct = map { $_ => $_ } qw(¡C ¡H ¡I ¡F ...);
TEST

test(<<'TEST'); # OVID/Data-Record-0.02/lib/Data/Record.pm
sub _fields {
    my $self = shift;
    return $self->{fields} unless @_;

    my $fields = ref($self)->new(shift);
    if ( defined( my $token = $self->token ) ) {
        $fields->token($token);
    }
    $self->{fields} = $fields;
    return $self;
}

my @tokens = map { $_ x 6 } qw( ~ ` ? " { } ! @ $ % ^ & * - _ + = );
TEST

test(<<'TEST'); # MSULLIVA/String-EscapeCage-0.02/lib/String/EscapeCage.pm
  cstring => do {  # or maybe use String::Escape
	my %ESCAPE_OF = map { eval qq| "\\$_" | => "\\$_" }
	  qw( 0 a b t n f r \ " );
	my $RE = eval 'qr/[' . join( '', keys(%ESCAPE_OF) ) . ']/';
	sub {
		my $string = shift;
		$string =~ s/$RE/$ESCAPE_OF{$&}/xg;
		return $string;
	}
  },
TEST

done_testing;
