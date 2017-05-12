package PerlIO::via::CBC;

use strict vars;
use warnings;

use Crypt::CBC ();

use vars '$VERSION';
$VERSION = '0.08';

my $Config = {};

sub config {
	my ($class, %args) = @_;
	if(%args) {
		$Config = {%args};
	} else {
		$Config = {};
	}
	return $Config;
}

sub PUSHED {
	return -1 if $_[1] ne 'r' and $_[1] ne 'w';

	my $cbc = Crypt::CBC->new($Config);
	unless($cbc) {
		require Carp;
		Carp::croak("Couldn't create CBC object");
	}

	if($_[1] eq 'r') { # open for reading: decrypt the data
		$cbc->start('decrypting');
	} else { # open for writing: encrypt the data
		$cbc->start('encrypting');
	}

	return (bless [$cbc, '', $_[1]], $_[0]);
}

sub FILL {
	my ($self, $fh) = @_;

	# Read the line from the handle
	my $line = readline($fh);

	my $cbc = $self->[0];

	# If there is something to be crypted, crypt it
	if(defined $line) {
        return ($cbc->crypt($line));

        # elsif we still have an object (and end of data reached)
        # Remove the object from PerlIO::via::Crypt object (so we'll really exit next)
        # and finish crypting
	} elsif($cbc) {
		$self->[0] = '';
		return ($cbc->finish());

		# else (end of data really reached)
		# return signalling end of data reached
	} else {
		return (undef);
	}
}

sub BINMODE {
	return (0);
}

sub READ {
	my ($self, $buffer, $len, $fh) = @_;

	# Read $len bytes from $fh into $buffer
	my $ret = read $fh, $buffer, $len;

	# On Error return undef
	return $ret unless defined $ret;

	my $cbc = $self->[0];

	# If there is something to be crypted, crypt it
	if($ret) {
		$buffer = $cbc->crypt($buffer);

		# elsif we still have an object (and end of data reached)
        # Remove the object from PerlIO::via::Crypt object (so we'll really exit next)
        # and finish crypting
	} else {
		$self->[0] = '';
		$buffer = $cbc->finish();
	}
	$self->[1] = '';

	# calc length
	$ret = length $buffer;

	# buffer is greater than required, shorten it but remember it
	if($ret > $len and $self->[0])
	{
		$self->[1] = substr($buffer, $len);
		$buffer = substr(0, $len);
		$ret = $len;
	}

	# return length of data (hopefully always less equal than $len)
	return $ret;
}

sub WRITE {
	my ($self, $buffer, $fh) = @_;

	my $buf = $self->[0]->crypt($buffer);
	return ((print {$fh} $buf) ? length ($buf) : -1);
}

sub FLUSH {
	my ($self, $fh) = @_;

	return 0 if $self->[2] eq 'r';

	my $buf = $self->[0]->finish();
	if($buf) {
		return ((print {$fh} $buf) ? 0 : -1);
	}

	return (0);
}

1;
__END__


=head1 NAME

PerlIO::via::CBC - PerlIO layer for reading/writing CBC encrypted files

=head1 SYNOPSIS

  use PerlIO::via::CBC;

  PerlIO::via::CBC->config(
    'key'             => 'my secret key',
    'cipher'          => 'Blowfish',
    'iv'              => '$KJh#(}q',
    'regenerate_key'  => 0,   # default true
    'padding'         => 'space',
    'prepend_iv'      => 0,
    'pcbc'            => 1  #default 0
  );

  my $fh;
  open($fh, '>:via(PerlIO::via::CBC)', $file)
    or die "Can't open $file for encryption: $!\n";
  print $fh $lots_of_secret_data;
  close($fh)
    or die "Error closing file: $!\n";

  open($fh, '<:via(PerlIO::via::CBC)', $file)
    or die "Can't open $file for decryption: $!\n";
  print <$fh>;
  close($fh)
    or die "Error closing file: $!\n";


=head1 DESCRIPTION

This module implements a PerlIO layer that can read and read CBC encrypted files.
It uses L<Crypt::CBC> to do the CBC. So check L<Crypt::CBC> for more information.

=head2 config(%args)

Allows the configuration of the CBC. Check L<Crypt::CBC>->new() for more information.

=head1 OVERRIDEN METHODS

This section lists the overriden PerlIO::via methods.

=head2 FILL

=head2 FLUSH

=head2 PUSHED

=head1 REQUIRED MODULES

    Crypt::CBC' => 2.12
    Crypt::DES' => 2.03

=head1 SEE ALSO

L<PerlIO::via>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
