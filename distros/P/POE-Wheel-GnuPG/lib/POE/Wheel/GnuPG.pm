package POE::Wheel::GnuPG;

=head1 NAME

POE::Wheel::GnuPG - offer GnuPG interaction through POE

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

POE-Wheel-GnuPG provides a GPG interface to your POE Session. Its main benefits
are that it allows asynchronous encryption and decryption, and allow you to
encrypt or decrypt on the fly, without having to store data in a file, even
when the data is huge.

I recommend using this module :

=over

=item *
when you use POE and want to use GPG.

=item *
for security reason, when you have huge data to decrypt and you don't want it to be stored in a file

=back

POE-Wheel-GnuPG inherits from GnuPG::Interface, and uses it for GPG actions. It
has a different constructor, but apart from that, you can use POE-Wheel-GnuPG
as you would use GnuPG::Interface, except for the POE signals of course.

=head1 SYNOPSIS

  # Example 0 :
  # Quickly encrypt some text

  use POE qw(Wheel::GnuPG);

  POE::Session->create(
    inline_states => {
      _start => sub {

        my $gnupg = POE::Wheel::GnuPG->new(
          ready_to_input_data => 'ready_to_input_data',
          something_on_stdout => 'something_on_stdout',
          end_of_process => 'the_end',
        );
        $_[HEAP]{gnupg} = $gnupg;

        $gnupg->options->hash_init( armor   => 1,
                                    homedir => '/home/dams/.gnupg' );
		$gnupg->options->push_recipients( 'foo@bar.org' );
        $gnupg->options->meta_interactive( 0 );

        $gnupg->encrypt();
      },

      ready_to_input_data => sub {
        my $input_fh = $_[ARG0];
        print $input_fh "This is the secret data!";

        $_[HEAP]{gnupg}->finished_writing_input();
      },

      something_on_stdout => sub {
		  my $stdout_fh = $_[ARG0];
          return if eof $stdout_fh;
          my @output = <$stdout_fh>;
          print "Received crypted data : @output\n";
      },
      the_end => sub {
          # clean up
          $_[HEAP]{gnupg}->destroy();
          exit();
      },
    }
  );

  POE::Kernel->run();
  exit;


  # Example 1 :
  # decrypt a file bits by bits asynchronously
  # without storing decrypted data on the filesystem.
  # Display decrypted data uppercased on the fly.

  use POE qw(Wheel::GnuPG);

  POE::Session->create(
    inline_states => {
      _start => sub {

        # Let's say we have a file we want to decrypt
        use IO::File;
        $_[HEAP]{encrypted_fh} = IO::File->new('encrypted_file.asc', 'r');

        # Initialize the gnupg object.
        # stdout, status, error, logger are optional
        my $gnupg = POE::Wheel::GnuPG->new(
          ready_to_input_data => 'ready_to_input_data',
          ready_to_input_passphrase => 'ready_to_input_passphrase',
          something_on_stdout => 'something_on_stdout',
          something_on_status => 'something_on_status',
          something_on_error => 'something_on_error',
          something_on_logger => 'something_on_logger',
          end_of_process => 'the_end',
        );
        # save the gnupg object
        $_[HEAP]{gnupg} = $gnupg;
        # Set some options (see GnuPG::Interface). All options are supported,
        # except 'direct'.
        $gnupg->options->hash_init( armor   => 1,
                                    homedir => '/Users/dams/.gnupg' );
        $gnupg->options->meta_interactive( 0 );
        $gnupg->decrypt();
      },

      # This is called when you can input the passphrase
      ready_to_input_passphrase => sub {
        my $passphrase_fh = $_[ARG0];
        print $passphrase_fh "my passphrase";

        # this is important to let the decryption start. It means you have
        # finished entering the passphrase.
		$_[HEAP]{gnupg}->finished_writing_passphrase();
      },

      # This is called when you can feed input data
      ready_to_input_data => sub {
        my $input_fh = $_[ARG0];
        # In our case, we get the encrypted file handle,
        # read from it and feed the gpg input with it
        my $encrypted_fh = $_[HEAP]{encrypted_fh};
        if (eof($encrypted_fh)) {
          # if it's the end of the encrypted file, we signify to the gnupg object
          # that it's the end of input
          $_[HEAP]{gnupg}->finished_writing_input();
        } else {
          # otherwise we feed the input
		  my $line = <$encrypted_fh>;
          print $input_fh $line;
        }
      },
      # gnupg returned decrypted data, do something with it
      something_on_stdout => sub {
		  my $stdout_fh = $_[ARG0];
          return if eof $stdout_fh;
          my @output = <$stdout_fh>;
          my @uppercased_output = map { uc } @output;
          print "got some bits of decrypted data, I uppercased it : @uppercased_output\n";
      },
      the_end => sub {
          # clean up
          $_[HEAP]{gnupg}->destroy();
          exit();
      },

      ### These are optional but useful for diagnostic
      something_on_status => sub {
          my $status_fh = $_[ARG0];
          return if eof $status_fh; # nothing to report
          my @status = <$status_fh>;
          print STDERR "got status : @status\n";
      },
      something_on_error => sub {
          my $err_fh = $_[ARG0];
          return if eof $err_fh; # nothing to report
          my @errors = <$err_fh>;
          print STDERR "got errors : @errors\n";
      },
      something_on_logger => sub {
		  my $logger_fh = $_[ARG0];
          return if eof $logger_fh; # nothing to report
          my @logger = <$logger_fh>;
          print STDERR "got logger : : @logger\n";
      },
    }
  );

  POE::Kernel->run();
  exit;



  # Example 2 :
  # encrypt a file bits by bits asynchronously

  use POE qw(Wheel::GnuPG);

  POE::Session->create(
    inline_states => {
      _start => sub {

        # let's say we have a file we want to crypt
        use IO::File;
        $_[HEAP]{unencrypted_fh} = IO::File->new('file.txt', 'r');

        my $gnupg = POE::Wheel::GnuPG->new(
          ready_to_input_data => 'ready_to_input_data',
          something_on_stdout => 'something_on_stdout',
          something_on_status => 'something_on_status',
          something_on_error => 'something_on_error',
          something_on_logger => 'something_on_logger',
		  end_of_process => 'the_end',
        );
        $_[HEAP]{gnupg} = $gnupg;
        $gnupg->options->hash_init( armor   => 1,
                                    homedir => '/Users/dams/.gnupg' );
        # we are encrypting against this GPG key
		$gnupg->options->push_recipients( 'foo@bar.org' );
        $gnupg->options->meta_interactive( 0 );
        $gnupg->encrypt();
      },
      ready_to_input_data => sub {
        my $input_fh = $_[ARG0];
        my $unencrypted_fh = $_[HEAP]{unencrypted_fh};
        if (eof($unencrypted_fh)) {
          # it's the end of the unencrypted file
          $_[HEAP]{gnupg}->finished_writing_input();
        } else {
		  my $line = <$unencrypted_fh>;
          print $input_fh $line;
        }
      },
      something_on_stdout => sub {
		  my $stdout_fh = $_[ARG0];
          return if eof $stdout_fh;
          my @output = <$stdout_fh>;
          print "got some bits of encrypted output : @output\n";
      },
      the_end => sub {
          $_[HEAP]{gnupg}->destroy();
		  exit();
      },

      ### These are optional but useful for diagnostic
      something_on_status => sub {
          my $status_fh = $_[ARG0];
          return if eof $status_fh; # nothing to report
          my @status = <$status_fh>;
          print STDERR " got status : @status\n";
      },
      something_on_error => sub {
          my $err_fh = $_[ARG0];
          return if eof $err_fh; # nothing to report
          my @errors = <$err_fh>;
          print STDERR " got errors : @errors\n";
      },
      something_on_logger => sub {
		  my $logger_fh = $_[ARG0];
          return if eof $logger_fh; # nothing to report
          my @logger = <$logger_fh>;
          print STDERR "got logger : : @logger\n";
      },
    }
  );

POE::Kernel->run();


=head1 DESCRIPTION

=cut

use strict;
use warnings;

use POE;
use IO::Handle ();

use parent qw(GnuPG::Interface);

my %signal_type_to_fhname = (
	ready_to_input_data => 'stdin',
	ready_to_input_passphrase => 'passphrase',
	something_on_stdout => 'stdout',
	something_on_status => 'status',
	something_on_error => 'stderr',
	something_on_logger => 'logger',
);

sub new {
	my $class = shift;
	my %params = @_;

	my %_struct = ();
	foreach my $signal_type (keys %signal_type_to_fhname) {
		if (exists $params{$signal_type}) {
			my $signal_name = delete $params{$signal_type};
			my $fh_name = $signal_type_to_fhname{$signal_type};
			$_struct{$fh_name} = [ IO::Handle->new(), $signal_name ];
		}
	}

	my $end_signal = delete $params{end_of_process};

	my $self = $class->SUPER::new(%params);
	$self->{_struct} = \%_struct;
	$self->{_handles} = GnuPG::Handles->new( map { $_, $self->{_struct}->{$_}->[0] } keys %{$self->{_struct}} );
	if (defined $end_signal) {
		$self->{_end_signal} = $end_signal;
	}
	return $self;
}

sub destroy {
	my ($self) = @_;
	foreach (values %{$self->{_struct}}) {
		my $fh = $_->[0];
		$poe_kernel->select_read( $fh );
		close $fh;
	}
	return;
}

sub wrap_call {
	my $self = shift;
	# pass our handles, but can be overwritten
	my $pid = $self->SUPER::wrap_call(
									  handles => $self->{_handles},
									  @_,
									 );
	while ( my ($fh_name, $s ) = each %{$self->{_struct}}) {
		my ($handle, $signal_name) = @$s;
		if ($fh_name =~ /^(?:stdin|passphrase)$/) {
			$poe_kernel->select_write( $handle, $signal_name );
		} else {
			$poe_kernel->select_read( $handle, $signal_name );
		}
	}
	$poe_kernel->sig_child($pid, $self->{_end_signal});
	return $pid;
}

sub finished_writing_passphrase { shift->_finished_writing('passphrase') }
sub finished_writing_input      { shift->_finished_writing('stdin')      }

sub _finished_writing {
	my ($self, $fh_name) = @_;
	my $fh = $self->{_struct}->{$fh_name}->[0];
	$poe_kernel->select_write($fh);
	close $fh;
	return;
}

1;
