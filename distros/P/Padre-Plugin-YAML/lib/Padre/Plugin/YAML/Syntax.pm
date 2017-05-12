package Padre::Plugin::YAML::Syntax;

use v5.10.1;
use strict;
use warnings;

# turn off experimental warnings
no if $] > 5.017010, warnings => 'experimental::smartmatch';

use English qw( -no_match_vars ); # Avoids reg-ex performance penalty
use Padre::Logger;
use Padre::Task::Syntax ();
use Padre::Wx           ();
use Try::Tiny;

our $VERSION = '0.10';
use parent qw(Padre::Task::Syntax);

sub new {
	my $class = shift;
	return $class->SUPER::new(@_);
}

sub run {
	my $self = shift;

	# Pull the text off the task so we won't need to serialize
	# it back up to the parent Wx thread at the end of the task.
	my $text = delete $self->{text};

	# Get the syntax model object
	$self->{model} = $self->syntax($text);

	return 1;
}

sub syntax {
	my $self = shift;
	my $text = shift;

	TRACE("\n$text") if DEBUG;

	try {
		if ( $OSNAME =~ /Win32/i )
		{
			require YAML;
			YAML::Load($text);
		} else {
			require YAML::XS;
			YAML::XS::Load($text);
		}
		# No errors...
		return {};
	}
	catch {
		TRACE("\nInfo: from YAML::XS::Load:\n $_") if DEBUG;
		if ( $OSNAME =~ /Win32/i ) {
			# send errors to syantax panel
			return $self->_parse_error_win32($_);
		} else {
			# send errors to syantax panel
			return $self->_parse_error($_);
		}
	};
	return;
}

sub _parse_error {
	my $self  = shift;
	my $error = shift;

	my @issues = ();
	my ( $type, $message, $code, $line, $column ) = (
		'Error',
		Wx::gettext('Unknown YAML error'),
		undef,
		1
	);

	# from the following in scanner.c inside YAML::XS
	foreach ( split '\n', $error ) {
		when (/YAML::XS::Load (\w+)\: .+/) {
			$type = $1;
		}
		when (/^\s+(block.+)/) {
			$message = $1;
		}
		when (/^\s+(cannot.+)/) {
			$message = $1;
		}
		when (/^\s+(could not.+)/) {
			$message = $1;
		}
		when (/^\s+(did not.+)/) {
			$message = $1;
		}
		when (/^\s+(found.+)/) {
			$message = $1;
		}
		when (/^\s+(mapping.+)/) {
			$message = $1;
		}
		when (/^\s+Code: (.+)/) {
			$code = $1;
		}
		when (/line:\s(\d+), column:\s(\d+)/) {
			$line   = $1;
			$column = $2;
		}
	}

	if (DEBUG) {
		say "type = $type"       if $type;
		say "message = $message" if $message;
		say "code = $code"       if $code;
		say "line = $line"       if $line;
		say "column = $column"   if $column;
	}

	push @issues,
		{
		# YAML::XS dose not produce error codes, hence we can use defined or //
		# message => $message . ( defined $code ? " ( $code )" : q{} ),
		message => $message . ( $code // q{} ),
		line => $line,
		type => $type eq 'Error' ? 'F' : 'W',
		file => $self->{filename},
		};

	return {
		issues => \@issues,
		stderr => $error,
	};

}

sub _parse_error_win32 {
	my $self  = shift;
	my $error = shift;

	my @issues = ();
	my ( $type, $message, $code, $line ) = (
		'Error',
		Wx::gettext('Unknown YAML error'),
		undef,
		1
	);
	for ( split '\n', $error ) {
		if (/YAML (\w+)\: (.+)/) {
			$type    = $1;
			$message = $2;
		} elsif (/^\s+Code: (.+)/) {
			$code = $1;
		} elsif (/^\s+Line: (.+)/) {
			$line = $1;
		}
	}
	push @issues,
		{
		message => $message . ( defined $code ? " ( $code )" : q{} ),
		line => $line,
		type => $type eq 'Error' ? 'F' : 'W',
		file => $self->{filename},
		};

	return {
		issues => \@issues,
		stderr => $error,
		}

}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::YAML::Syntax - YAML document syntax-checking in the background


=head1 VERSION

version: 0.10


=head1 DESCRIPTION

This class implements syntax checking of YAML documents in
the background. It inherits from L<Padre::Task::Syntax>.
Please read its documentation.


=head1 BUGS AND LIMITATIONS

Now using YAML::XS

    supports %TAG = %YAML 1.1 or no %TAG

If you receive "Unknown YAML error" please inform dev's with sample code that causes this, Thanks.

=head1 METHODS

=over 3

=item * new

=item * run

=item * syntax

=back

=head1 AUTHOR

See L<Padre::Plugin::YAML>

=head2 CONTRIBUTORS

See L<Padre::Plugin::YAML>

=head1 COPYRIGHT

See L<Padre::Plugin::YAML>

=head1 LICENSE

See L<Padre::Plugin::YAML>

=cut
