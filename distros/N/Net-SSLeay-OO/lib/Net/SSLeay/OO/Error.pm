
package Net::SSLeay::OO::Error;

use Net::SSLeay;
use Moose;

has 'err'        => isa => 'Int',
	is       => 'ro',
	required => 1,
	default  => sub {
	Net::SSLeay::ERR_get_error
		or die "no OpenSSL error to get";
	};

sub ssl_error_pending {
	Net::SSLeay::ERR_peek_error;
}

has 'error_code' => isa => "Int",
	is       => "ro",
	;

has 'library_name' => isa => "Str",
	is         => "ro",
	;

has 'function_name' => isa => "Str",
	is          => "ro",
	;

has 'reason_string' => isa => "Str",
	is          => "ro",
	;

has 'next' => isa => __PACKAGE__,
	is => "ro",
	;

sub BUILD {
	my $self      = shift;
	my $ssl_error = $self->error_string;
	( undef, my @fields ) = split ":", $ssl_error, 5;
	$self->{error_code}    ||= hex( shift @fields );
	$self->{library_name}  ||= shift @fields;
	$self->{function_name} ||= shift @fields;
	$self->{reason_string} ||= shift @fields;

	# OpenSSL throws an entire stack backtrace, so capture all the
	# outstanding SSL errors and chain them off this one.
	if (ssl_error_pending) {
		$self->{next} = ( ref $self )->new();
	}
}

has 'message' => isa => "Str",
	is    => "rw",
	;

sub die_if_ssl_error {
	my $message = shift;
	if (ssl_error_pending) {
		die __PACKAGE__->new( message => $message );
	}
}

sub as_string {
	my $self    = shift;
	my $message = $self->message;
	if ($message) {
		unless ( $message =~ / / ) {
			$message = "During `$message'";
		}
		$message .= ": ";
	}
	else {
		$message = "";
	}
	my $reason_string = $self->reason_string;
	my $result        = do {
		if ( $reason_string eq "system lib" ) {    # FIXME: lang
			sprintf( "%s%.8x: trace: %s (%s)",
				$message, $self->error_code,
				$self->function_name, $self->library_name );
		}
		else {
			sprintf("%sOpenSSL error %.8x: %s during %s (%s)",
				$message,             $self->error_code,
				$self->reason_string, $self->function_name,
				$self->library_name
			);
		}
	};
	if ( $self->next ) {
		$result .= "\n" . "    then " . $self->next->as_string;
	}
	if ( $result =~ m{\n} and $result !~ m{\n\Z} ) {
		$result .= "\n";
	}
	$result;
}

use overload
	'""' => \&as_string,
	;

use Sub::Exporter -setup =>
	{ exports => [qw(die_if_ssl_error ssl_error_pending)], };

use Net::SSLeay::OO::Functions sub {
	my $code = shift;
	sub {
		my $self = shift;
		$code->( $self->err, @_ );
		}
};

1;

__END__

=head1 NAME

Net::SSLeay::OO::Error - encapsulated SSLeay errors

=head1 SYNOPSIS

 use Scalar::Util qw(blessed);
 eval {
    $ctx->use_PrivateKey_file($filename, FILETYPE_PEM);
 };
 my $error = $@;
 if (blessed $error and
      ( $error->error_code == 0x0B080074 or
        $error->reason_string =~ /key.*mismatch/i ) ) {
    # deal with some known error condition differently..
    die "Private key file mismatches certificate file, did "
        ."you update both settings?";
 }
 elsif ($error) {
    die $error;
 }

 # if you need to manually check for errors ever
 use Net::SSLeay::OO::Error qw(die_if_ssl_error ssl_error_pending);
 die_if_ssl_error("Initialization");

=head1 DESCRIPTION

Unlike L<Net::SSLeay>, with L<Net::SSLeay::OO> functions, if an error
occurs in a low level library an exception is raised via C<die>.

OpenSSL has an 'error queue', which normally represents something like
a stack trace indicating the context of the error.  The first error
will be the "deepest" error and usually has the most relevant error
message.  To represent this, the Net::SSLeay::OO::Error object has a
B<next> property, which represents a level further up the exception
heirarchy.

=head1 METHODS

The following methods are defined (some via L<Moose> attributes):

=over

=item B<error_string()>

Returns the error string from OpenSSL.

=item B<as_string()>

Returns the error string, turned into a marginally more user-friendly
message.  Also available as the overloaded '""' operator (ie, when
interpreted as a string you will get a message)

=item B<error_code()>

A fixed error code corresponding to the error.

=item B<reason_string()>

The human-readable part, or (apparently) "system lib" if the error is
part of a stack trace.

=item B<library_name()>

=item B<function_name()>

Where the error occurred, or where this part of the stack trace
applies.

=item B<next()>

The next (shallower) Net::SSLeay::OO::Error object, corresponding to the
next level up the stack trace.

=item B<message( [$message] )>

The caller-supplied message that this error will be prefixed with.  If
this is a single word (no whitespace) then it will be printed as
C<During `$message':>.

=back

=head1 FUNCTIONS

These functions are available for export.

=over

=item B<die_if_ssl_error($message)>

This is similar to L<Net::SSLeay>'s function of the same name, except;

=over

=item 1.

The entire error queue is cleared, and wrapped into a single
chain of exception objects

=item 2.

The message is parceled to be hopefully a little more human-readable.

=back

Here is an example, an error raised during the test suite script
F<t/03-ssl.t>:

  During `use_certificate_file': OpenSSL error 02001002: No such file or directory during fopen (system library)
      then 20074002: trace: FILE_CTRL (BIO routines)
      then 140c8002: trace: SSL_use_certificate_file (SSL routines)

The function was called as:
C<die_if_ssl_error("use_certificate_file")>

The strings returned from OpenSSL as a "human readable" error messages
were:

  error:02001002:system library:fopen:No such file or directory
  error:20074002:BIO routines:FILE_CTRL:system lib
  error:140C8002:SSL routines:SSL_use_certificate_file:system lib

=item B<ssl_error_pending()>

Returns a non-zero integer if there is an error pending.  To fetch it,
just create a new L<Net::SSLeay::OO::Error> object.

=back

=head1 AUTHOR

Sam Vilain, L<samv@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2009  NZ Registry Services

This program is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0 or later.  You should
have received a copy of the Artistic License the file COPYING.txt.  If
not, see <http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

L<Net::SSLeay::OO>

=cut

# Local Variables:
# mode:cperl
# indent-tabs-mode: t
# cperl-continued-statement-offset: 8
# cperl-brace-offset: 0
# cperl-close-paren-offset: 0
# cperl-continued-brace-offset: 0
# cperl-continued-statement-offset: 8
# cperl-extra-newline-before-brace: nil
# cperl-indent-level: 8
# cperl-indent-parens-as-block: t
# cperl-indent-wrt-brace: nil
# cperl-label-offset: -8
# cperl-merge-trailing-else: t
# End:
# vim: filetype=perl:noexpandtab:ts=3:sw=3
