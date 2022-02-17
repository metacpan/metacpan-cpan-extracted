package Net::Curl::Compat;
=head1 NAME

Net::Curl::Compat -- compatibility layer for WWW::Curl

=head1 SYNOPSIS

 --- old.pl
 +++ new.pl
 @@ -2,6 +2,8 @@
  use strict;
  use warnings;

 +# support both Net::Curl (default) and WWW::Curl
 +BEGIN { eval { require Net::Curl::Compat; } }
  use WWW::Curl::Easy 4.15;
  use WWW::Curl::Multi;

=head1 DESCRIPTION

Net::Curl::Compat lets you use Net::Curl in applications and modules
that normally use WWW::Curl. There are several ways to accomplish it:

=head2 EXECUTION

Execute an application through perl with C<-MNet::Curl::Compat> argument:

 perl -MNet::Curl::Compat APPLICATION [ARGUMENTS]

=head2 CODE, use Net::Curl by default

Add this line before including any WWW::Curl modules:

 BEGIN { eval { require Net::Curl::Compat; } }

This will try to preload Net::Curl, but won't fail if it isn't available.

=head2 CODE, use WWW::Curl by default

Add those lines before all the others that use WWW::Curl:

 BEGIN {
     eval { require WWW::Curl; }
     require Net::Curl::Compat if $@;
 }

This will try WWW::Curl first, but will fallback to Net::Curl if that fails.

=head1 NOTE

If you want to write compatible code, DO NOT USE Net::Curl::Compat during
development. This module hides all the incompatibilities, but does not disable
any of the features that are unique to Net::Curl. You could end up using
methods that do not yet form part of official WWW::Curl distribution.

=cut

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = 4.15;

=for Pod::Coverage
VERSION
=cut

# Dirty hack so Test::ConsistentVersion passes
sub VERSION {
	return (caller)[0] eq 'Test::ConsistentVersion'
		? '0.50'
		: $VERSION;
}

my %packages = (
	'WWW/Curl.pm' => 0,
	'WWW/Curl/Easy.pm' => 420,
	'WWW/Curl/Form.pm' => 4289,
	'WWW/Curl/Multi.pm' => 5193,
	'WWW/Curl/Share.pm' => 6272,
);

my $start = tell *DATA;
unshift @INC, sub {
	my $pkg = $packages{ $_[1] };
	return unless defined $pkg;
	## no critic (RequireUseOfExceptions)
	open(my $fh, '<&', *DATA) or croak "can't read from __DATA__";
	seek $fh, $start + $pkg, 0;
	return $fh;
};

1;

=head1 COPYRIGHT

Copyright (c) 2011-2015 Przemyslaw Iskra <sparky at pld-linux.org>.

You may opt to use, copy, modify, merge, publish, distribute and/or sell
copies of the Software, and permit persons to whom the Software is furnished
to do so, under the terms of the MPL or the MIT/X-derivate licenses. You may
pick one of these licenses.

=cut

__DATA__
package WWW::Curl;

use strict;
use warnings;
use Net::Curl ();

our $VERSION = 4.15;

# copies constants to current namespace
sub _copy_constants
{
	my $EXPORT = shift;
	my $dest = (shift) . "::";
	my $source = shift;

	no strict 'refs';
	my @constants = grep /^CURL/, keys %{ "$source" };
	push @$EXPORT, @constants;

	foreach my $name ( @constants ) {
		*{ $dest . $name } = \*{ $source . $name };
	}
}

1;

__END__

package WWW::Curl::Easy;

use strict;
use warnings;
use WWW::Curl ();
use Net::Curl::Easy ();
use Exporter ();
our @ISA = qw(Net::Curl::Easy Exporter);

our $VERSION = 4.15;
our @EXPORT;

BEGIN {
	# in WWW::Curl almost all the constants are thrown into WWW::Curl::Easy
	foreach my $pkg ( qw(Net::Curl:: Net::Curl::Easy::
			Net::Curl::Form:: Net::Curl::Share::
			Net::Curl::Multi::) ) {
		WWW::Curl::_copy_constants(
			\@EXPORT, __PACKAGE__, $pkg );
	}
}

# what is that anyways ?
$WWW::Curl::Easy::headers = "";
$WWW::Curl::Easy::content = "";

sub new
{
	my $class = shift || __PACKAGE__;
	return $class->SUPER::new();
}

*init = \&new;
*errbuf = \&Net::Curl::Easy::error;
*strerror = \&Net::Curl::Easy::strerror;

*version = \&Net::Curl::version;

sub cleanup { 0 };

sub internal_setopt { die };

sub duphandle
{
	my ( $source ) = @_;
	my $clone = $source->SUPER::duphandle;
	bless $clone, "WWW::Curl::Easy"
}

sub const_string
{
	my ( $self, $constant ) = @_;
	return constant( $constant );
}

# this thing is weird !
sub constant
{
	my $name = shift;
	undef $!;
	my $value = eval "$name()";
	if ( $@ ) {
		require POSIX;
		$! = POSIX::EINVAL();
		return undef;
	}
	return $value;
}

sub setopt
{
	# convert options and provide wrappers for callbacks
	my ($self, $option, $value, $push) = @_;

	if ( $push ) {
		return $self->pushopt( $option, $value );
	}

	if ( $option == CURLOPT_PRIVATE ) {
		# stringified
		$self->{private} = "$value";
		return 0;
	} elsif ( $option == CURLOPT_ERRORBUFFER ) {
		# I don't even know how was that supposed to work, but it does
		$self->{errorbuffer} = $value;
		return 0;
	}

	# wrappers for callbacks
	if ( $option == CURLOPT_WRITEFUNCTION ) {
		my $sub = $value;
		$value = sub {
			my ( $easy, $data, $uservar ) = @_;
			return $sub->( $data, $uservar );
		};
	} elsif ( $option == CURLOPT_HEADERFUNCTION ) {
		my $sub = $value;
		$value = sub {
			my ( $easy, $data, $uservar ) = @_;
			return $sub->( $data, $uservar );
		};
	} elsif ( $option == CURLOPT_READFUNCTION ) {
		my $sub = $value;
		$value = sub {
			my ( $easy, $maxlen, $uservar ) = @_;
			return \( $sub->( $maxlen, $uservar ) );
		};
	} elsif ( $option == CURLOPT_PROGRESSFUNCTION ) {
		my $sub = $value;
		$value = sub {
			my ( $easy, $dltotal, $dlnow, $ultotal, $ulnow, $uservar ) = @_;
			return $sub->( $uservar, $dltotal, $dlnow, $ultotal, $ulnow );
		};
	} elsif ( $option == CURLOPT_DEBUGFUNCTION ) {
		my $sub = $value;
		$value = sub {
			my ( $easy, $type, $data, $uservar ) = @_;
			return $sub->( $data, $uservar, $type );
		};
	}
	eval {
		$self->SUPER::setopt( $option, $value );
	};
	return 0 unless $@;
	return 0+$@ if ref $@ eq "Net::Curl::Easy::Code";
	die $@;
}

sub pushopt
{
	my ($self, $option, $value) = @_;
	eval {
		$self->SUPER::pushopt( $option, $value );
	};
	return 0 unless $@;
	if ( ref $@ eq "Net::Curl::Easy::Code" ) {
		# WWW::Curl allows to use pushopt on non-slist arguments
		if ( $@ == CURLE_BAD_FUNCTION_ARGUMENT ) {
			return $self->setopt( $option, $value );
		}
		return 0+$@;
	}
	die $@;
}

sub getinfo
{
	my ($self, $option) = @_;

	my $ret;
	if ( $option == CURLINFO_PRIVATE ) {
		$ret = $self->{private};
	} else {
		eval {
			$ret = $self->SUPER::getinfo( $option );
		};
		if ( $@ ) {
			return undef if ref $@ eq "Net::Curl::Easy::Code";
			die $@;
		}
	}
	if ( @_ > 2 ) {
		$_[2] = $ret;
	}
	return $ret;
}

sub perform
{
	my $self = shift;
	eval {
		$self->SUPER::perform( @_ );
	};
	if ( defined $self->{errorbuffer} ) {
		my $error = $self->error();

		no strict 'refs';

		# copy error message to specified global variable
		# not really sure where that should go
		*{ "main::" . $self->{errorbuffer} } = \$error;
		*{ "::" . $self->{errorbuffer} } = \$error;
		*{ $self->{errorbuffer} } = \$error;
	}
	return 0 unless $@;
	return 0+$@ if ref $@ eq "Net::Curl::Easy::Code";
	die $@;
}

1;

__END__

package WWW::Curl::Form;

use strict;
use warnings;
use WWW::Curl ();
use Net::Curl::Form ();
use Exporter ();
our @ISA = qw(Net::Curl::Form Exporter);

our $VERSION = 4.15;

our @EXPORT;

BEGIN {
	WWW::Curl::_copy_constants(
		\@EXPORT, __PACKAGE__, "Net::Curl::Form::" );
}

# this thing is weird !
sub constant
{
	my $name = shift;
	undef $!;
	my $value = eval "$name()";
	if ( $@ ) {
		require POSIX;
		$! = POSIX::EINVAL();
		return undef;
	}
	return $value;
}

sub new
{
	my $class = shift || __PACKAGE__;
	return $class->SUPER::new();
}

sub formadd
{
	my ( $self, $name, $value ) = @_;
	eval {
		$self->add(
			CURLFORM_COPYNAME, $name,
			CURLFORM_COPYCONTENTS, $value
		);
	};
}

sub formaddfile
{
	my ( $self, $filename, $description, $type ) = @_;
	eval {
		$self->add(
			CURLFORM_FILE, $filename,
			CURLFORM_COPYNAME, $description,
			CURLFORM_CONTENTTYPE, $type,
		);
	};
}

1;

__END__

package WWW::Curl::Multi;

use strict;
use warnings;
use WWW::Curl ();
use Net::Curl::Multi ();
our @ISA = qw(Net::Curl::Multi);

*strerror = \&Net::Curl::Multi::strerror;

sub new
{
	my $class = shift || __PACKAGE__;
	return $class->SUPER::new();
}

sub add_handle
{
	my ( $multi, $easy ) = @_;
	eval {
		$multi->SUPER::add_handle( $easy );
	};
}

sub remove_handle
{
	my ( $multi, $easy ) = @_;
	eval {
		$multi->SUPER::remove_handle( $easy );
	};
}

sub info_read
{
	my ( $multi ) = @_;
	my @ret;
	eval {
		@ret = $multi->SUPER::info_read();
	};
	return () unless @ret;

	my ( $msg, $easy, $result ) = @ret;
	$multi->remove_handle( $easy );

	return ( $easy->{private}, $result );
}

sub fdset
{
	my ( $multi ) = @_;
	my @vec;
	eval {
		@vec = $multi->SUPER::fdset;
	};
	my @out;
	foreach my $in ( @vec ) {
		my $max = 8 * length $in;
		my @o;
		foreach my $fn ( 0..$max ) {
			push @o, $fn if vec $in, $fn, 1;
		}
		push @out, \@o;
	}

	return @out;
}

sub perform
{
	my ( $multi ) = @_;

	my $ret;
	eval {
		$ret = $multi->SUPER::perform;
	};

	return $ret;
}

1;

__END__

package WWW::Curl::Share;

use strict;
use warnings;
use WWW::Curl ();
use Net::Curl::Share ();
use Exporter ();
our @ISA = qw(Net::Curl::Share Exporter);

our @EXPORT;

BEGIN {
	WWW::Curl::_copy_constants(
		\@EXPORT, __PACKAGE__, "Net::Curl::Share::" );
}

*strerror = \&Net::Curl::Share::strerror;

sub new
{
	my $class = shift || __PACKAGE__;
	return $class->SUPER::new();
}

# this thing is weird !
sub constant
{
	my $name = shift;
	undef $!;
	my $value = eval "$name()";
	if ( $@ ) {
		require POSIX;
		$! = POSIX::EINVAL();
		return undef;
	}
	return $value;
}

sub setopt
{
	my ($self, $option, $value) = @_;
	eval {
		$self->SUPER::setopt( $option, $value );
	};
	return 0 unless $@;
	return 0+$@ if ref $@ eq "Net::Curl::Share::Code";
	die $@;
}

1;

__END__

