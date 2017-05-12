package PGP::Mail;

use strict;

use Fcntl;
use IO::Handle;
use GnuPG::Interface;
use MIME::Parser;

=head1 NAME

PGP::Mail - Signature checking for PGP-signed mail messages

=head1 SYNOPSIS

  use PGP::Mail;
  my $pgpmail=new PGP::Mail($mail, {default-keyring=>"kr.gpg"});
  $status=$pgpmail->status();
  $keyid=$pgpmail->keyid();
  $data=$pgpmail->data();

=head1 DESCRIPTION

This module operates on PGP-signed mail messages. It checks the signature of
either a standard clearsigned, a signed message or a PGP/MIME style message.

It returns an object which can be used to check what the signed data was,
whether the signature verification succeeded, and what keyid did the
signature.

=cut

use vars qw($VERSION);

$VERSION=('$Revision: 1.7 $'=~/(\d+\.\d+)/)[0];

=head2 my I<$pgpmail>=B<new> PGP::Mail(I<$mesg>, I<$args>);

Creates a new PGP::Mail object using the RFC2822 message specified in
I<$mesg>. It will do the signature verification itself. I<$args> is a
hashref which gets passed to GnuPG::Interface's options. It is particularly
worth looking at L<GnuPG::Options> for this.

=cut

sub new {
    my $class=shift;
    $class = ref($class) || $class;

    my $self=bless{},$class;
    $self->init(@_);
    $self;
}

=head2 I<$pgpmail>->B<status>();

Returns the status of the signature verification (currently C<good>, C<bad>
or C<unverified>).

=cut

sub status {
    my $self=shift;

    return $self->{'status'}
}

=head2 I<$pgpmail>->B<keyid>();

Returns the keyid of this signature, in the format "0xI<64-bit_key_id>".

=cut

sub keyid {
    my $self=shift;

    return $self->{'keyid'}
}

=head2 I<$pgpmail>->B<data>();

Returns the signed data, run through MIME::Parser if necessary.

=cut

sub data {
    my $self=shift;

    return $self->{'data'}
}

sub init {
    my $self = shift;
    my $data = shift;
    my $args = shift || {};

    my @lines=map {$_."\n"} split /\r?\n/, $data;

    my @header=();
    my $finished=0;
    while(!$finished) {
	my $line=shift(@lines);

	if(!defined $line) {
	    $finished=1;
	}
	elsif(defined $line && $line=~/^$/) {
	    $finished=1;
	}
	elsif($line=~/^[ \t]+/) {
	    $header[-1].=$line;
	}
	else {
	    push(@header,$line);
	}
    }

    # we should now have the header in @header and the body
    # in @lines

    for my $header (@header) {
	if($header=~/^content-type:\s+(\S+\/\S+)(;.*)?$/si) {
	    if(lc $1 eq "multipart/signed") {
		if($header=~/protocol="?application\/pgp/i) {
		    $self->{PGPMIME}=1;
		    $self->{PGPMIMEBOUND} =
			($header=~/boundary=\"([^\"]+)\"(;.*)?$/i)[0];
		}
	    }
	}
    }

    if(!$self->{PGPMIME}) {
	for my $line (@lines) {
	    if($line=~/^-----BEGIN PGP SIGNED MESSAGE-----\s*$/) {
		$self->{PGPTEXT}=1;
		last;
	    }
	}
    }

    $self->{status}="unverified";
    $self->{keyid}="0x0000000000000000";
    $self->{data}=join("",@lines);

    if(!$self->{PGPTEXT} && !$self->{PGPMIME}) {
	return 0;
    }

    $self->{gpg}=new GnuPG::Interface;
    $self->{gpg}->options->hash_init( %$args );
    $self->{gpg}->options->meta_interactive( 0 );

    if($self->{PGPTEXT}) {
	$self->textpgp(\@lines);
    }
    else {
	$self->mimepgp(\@lines, $self->{PGPMIMEBOUND});
    }
    return 1;
}

sub textpgp {
    my $self=shift;
    my $data=shift;

    my $input=new IO::Handle;
    my $output=new IO::Handle;
    my $error=new IO::Handle;
    my $status=new IO::Handle;
    my $pp=new IO::Handle;
    my $handles=GnuPG::Handles->new(
	stdin=>$input,
	stdout=>$output,
	stderr=>$error,
	status=>$status,
	passphrase=>$pp
	);
    my $pid=$self->{gpg}->decrypt(handles=>$handles);
    close $pp;

    print $input join "",@$data;
    close $input;

    $self->{data}=join "",<$output>;
    close $output;

    $self->get_status($status);
    waitpid $pid, 0;
}

sub get_status {
    my $self=shift;
    my $statusfh=shift;

    for my $line (<$statusfh>) {
	if($line =~ /^\[GNUPG:\] GOODSIG (\w+) /) {
	    $self->{status}="good";
	    $self->{keyid}="0x$1";
	}
	elsif($line =~ /^\[GNUPG:\] BADSIG (\w+) /) {
	    $self->{status}="bad";
	    $self->{keyid}="0x$1";
	}
    }
}

sub mimepgp {
    my $self=shift;
    my $data=shift;
    my $bound=shift;

    my $state="before";
    my $sigdata="";
    my $signature="";
    for my $line (@$data) {
	if($state eq "before" &&
	    $line eq "--$bound\n") {
	    $state="data";
	    next;
	}
	elsif($state eq "data" &&
	    $line eq "--$bound\n") {
	    $state="sig";
	    next;
	}
	elsif($state eq "sig" &&
	    $line eq "--$bound--\n") {
	    $state="finished";
	    next;
	}
	elsif($state eq "data") {
	    my $l=$line;
	    chomp $l;
	    $sigdata.=$l."\r\n";
	}
	elsif($state eq "sig") {
	    $signature.=$line;
	}
    }
    chomp $signature;
    $sigdata=~s/\r\n$//;

    my $parser=new MIME::Parser;
    $parser->output_to_core(1);
    $signature=$parser->parse_data($signature)->bodyhandle->as_string;

    my $fn="";
    for my $i (0..3) {
	if(sysopen(SIGNATURE,
	    $fn="/tmp/file-$$-$i-" . time() . ".dat",
	    O_EXCL | O_RDWR | O_CREAT, 0666)) {
	    last;
	}
	else {
	    $fn="";
	}
    }

    if(!length $fn) {
	return 0;
    }

    print SIGNATURE $sigdata;
    close SIGNATURE;

    my $input=new IO::Handle;
    my $output=new IO::Handle;
    my $error=new IO::Handle;
    my $status=new IO::Handle;
    my $handles=GnuPG::Handles->new(
	stdin=>$input,
	stdout=>$output,
	stderr=>$error,
	status=>$status
	);
    my $pid=$self->{gpg}->verify(handles=>$handles, command_args=>["-",$fn]);

    print $input $signature;
    close $input;

    $parser=new MIME::Parser;
    $parser->output_to_core(1);
    $self->{data}=$parser->parse_data($sigdata)->bodyhandle->as_string;

    $self->get_status($status);

    waitpid $pid, 0;
    unlink $fn;
}

=head1 BUGS

The style of this module leaves quite a bit to be desired, and it only
supports verifying signatures at the moment, rather than the full encryption,
decryptions, and creating the messages.

=head1 AUTHOR

Matthew Byng-Maddick E<lt>mbm@colondot.netE<gt>

=head1 SEE ALSO

L<perl>, L<GnuPG::Interface>, L<GnuPG::Options>, L<MIME::Tools>.

=cut

1;
