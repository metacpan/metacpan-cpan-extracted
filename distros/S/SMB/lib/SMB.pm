# SMB-Perl library, Copyright (C) 2014 Mikhael Goikhman, migo@cpan.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package SMB;

use strict;
use warnings;

our $VERSION = 0.06;

use constant {
	STATUS_SUCCESS                  => 0x00000000,
	STATUS_PENDING                  => 0x00000103,
	STATUS_NOTIFY_ENUM_DIR          => 0x0000010c,
	STATUS_SMB_BAD_TID              => 0x00050002,
	STATUS_OS2_INVALID_LEVEL        => 0x007c0001,
	STATUS_NO_MORE_FILES            => 0x80000006,
	STATUS_INVALID_PARAMETER        => 0xc000000d,
	STATUS_NO_SUCH_DEVICE           => 0xc000000e,
	STATUS_NO_SUCH_FILE             => 0xc000000f,
	STATUS_END_OF_FILE              => 0xc0000011,
	STATUS_MORE_PROCESSING_REQUIRED => 0xc0000016,
	STATUS_NO_FREE_MEMORY           => 0xc0000017,
	STATUS_ACCESS_DENIED            => 0xc0000022,
	STATUS_BUFFER_TOO_SMALL         => 0xc0000023,
	STATUS_OBJECT_NAME_NOT_FOUND    => 0xc0000034,
	STATUS_OBJECT_NAME_COLLISION    => 0xc0000035,
	STATUS_OBJECT_PATH_NOT_FOUND    => 0xc000003a,
	STATUS_SHARING_VIOLATION        => 0xc0000043,
	STATUS_DELETE_PENDING           => 0xc0000056,
	STATUS_PRIVILEGE_NOT_HELD       => 0xc0000061,
	STATUS_LOGON_FAILURE            => 0xc000006d,
	STATUS_DISK_FULL                => 0xc000007f,
	STATUS_FILE_IS_A_DIRECTORY      => 0xc00000ba,
	STATUS_BAD_NETWORK_NAME         => 0xc00000cc,
	STATUS_DIRECTORY_NOT_EMPTY      => 0xc0000101,
	STATUS_NOT_A_DIRECTORY          => 0xc0000103,
	STATUS_CANCELLED                => 0xc0000120,
	STATUS_CANNOT_DELETE            => 0xc0000121,
	STATUS_FILE_CLOSED              => 0xc0000128,
	STATUS_INVALID_LEVEL            => 0xc0000148,
	STATUS_FS_DRIVER_REQUIRED       => 0xc000019c,
	STATUS_NOT_A_REPARSE_POINT      => 0xc0000275,
};

sub new ($%) {
	my $class = shift;
	my %options = @_;

	my $self = {
		disable_log => $options{quiet} ? 1 : 0,
		%options,
	};

	bless $self, $class;
}

sub log ($$@) {
	my $self = shift;
	my $is_err = shift;
	my $format = shift;
	return if $self->disable_log;
	print sprintf("%s $format\n", $is_err ? '!' : '*', @_);
}

sub msg ($@) { shift()->log(0, @_) }
sub err ($@) { shift()->log(1, @_); return }

my $MAX_DUMP_BYTES = 8 * 1024;
my $dump_line_format = "%03x | 00 53 54 52 49 4E 47 aa  aa aa aa aa aa aa       | _STRING. ......   |\n";

sub mem ($$;$) {
	my $self = shift;
	my $data = shift;
	my $label = shift || "Data dump";
	return if $self->disable_log;

	if (!defined $data) {
		$self->msg("$label (undef)");
		return;
	}

	my $len = length($data);
	$self->msg(sprintf("%s (%lu bytes%s):", $label, $len, $len > $MAX_DUMP_BYTES ? ", shorten" : ""), @_);
	$len = $MAX_DUMP_BYTES if $len > $MAX_DUMP_BYTES;

	for (my $n = 0; $n < ($len + 15) / 16; $n++) {
		for (my $i = 0; $i < 16; $i++) {
			my $valid = $n * 16 + $i < $len;
			my $b = $valid ? ord(substr($data, $n * 16 + $i, 1)) : undef;
			substr($dump_line_format, 7 + $i * 3 + ($i >= 8), 2) = $valid ? sprintf("%02x", $b) : "  ";
			substr($dump_line_format, 58 + $i + ($i >= 8), 1) = $valid ? $b == 0 ? '_' : $b <= 32 || $b >= 127 || $b == 37 ? '.' : chr($b) : ' ';
		}
		printf $dump_line_format, $n;
	}
}

sub parse_share_uri ($$) {
	my $self = shift;
	my $share_uri = shift;

	unless ($share_uri) {
		$self->err("No share uri supplied");
		return;
	}
	unless ($share_uri =~ m~^([/\\])\1([\w.]+(?::\d+)?)\1([^/\\]+)(?:$|\1)~) {
		$self->err("Invalid share uri ($share_uri)");
		return;
	}

	return wantarray ? ($2, $3) : $share_uri;
}

our %dump_seen;
our $dump_is_newline = 1;
our $dump_level_limit = 7;
our $dump_array_limit = 20;
our $dump_string_limit = 50;

sub _dump_prefix ($) {
	my $level = shift;

	return "" unless $dump_is_newline;
	$dump_is_newline = 0;

	return " " x (4 * $level);
}

sub _dump_eol () {
	$dump_is_newline = 1;

	return "\n";
}

sub _dump_string ($) {
	my $value = shift;

	my $len = length($value);
	if ($len > $dump_string_limit) {
		my $llen = length($len);
		substr($value, $dump_string_limit - 3 - $llen) =
			"..+" . ($len - $dump_string_limit + 3 + $llen);
	}

	$value =~ s/([\\"])/\\$1/g;
	$value =~ s/([^\\" -\x7e])/sprintf("\\x%02x", ord($1))/ge;

	return $value;
}

sub _dump_value ($) {
	my $value = shift;
	my $level  = shift || 0;
	my $inline = shift || 0;

	return '' if $level >= $dump_level_limit;

	my $type = ref($value);
	my $dump = _dump_prefix($level);
	my $is_seen = $type && $dump_seen{$value};
	$dump_seen{$value} = 1 if $type;

	if (! $type) {
		$dump .= defined $value
			? $value =~ /^-?\d+$/ ||$inline == 2 && $value =~ /^-?\w+$/
				? $value : '"' . _dump_string($value) . '"'
			: 'undef';
	} elsif ($type eq 'ARRAY') {
		if ($is_seen) {
			$dump .= "ARRAY (seen)";
		} else {
			$dump .= "[" . _dump_eol();
			my @array = @$value > $dump_array_limit ? (@$value)[0 .. $dump_array_limit - 2] : @$value;
			my $prev_elem = '';
			foreach (@array) {
				# compress equal consecutive elements
				my $elem = &_dump_value($_, $level + 1, 1);
				if ($elem eq $prev_elem) {
					$dump =~ s/^(\s+)(?:\()?(.*?)(?:\) x (\d+))?,$(\n)\z/my $c = ($3 || 1) + 1; "$1($2) x $c," . _dump_eol()/me;
					next;
				}
				$dump .= _dump_prefix($level + 1);
				$dump .= $prev_elem = $elem;
				$dump .= "," . _dump_eol();
			}
			if (@$value > $dump_array_limit) {
				$dump .= _dump_prefix($level + 1);
				$dump .= "...[+" . (@$value - $dump_array_limit + 1) . "]," . _dump_eol();
			}
			$dump .= _dump_prefix($level) . "]";
		}
	} elsif ($type eq 'HASH') {
		if ($is_seen) {
			$dump .= "HASH (seen)";
		} else {
			$dump .= "{" . _dump_eol();
			my $idx = 0;
			my @keys = sort keys %$value;
			my $size = @keys;
			foreach my $key (@keys) {
				my $val = $value->{$key};
				last if ++$idx == $dump_array_limit && $size > $dump_array_limit;
				$dump .= _dump_prefix($level + 1);
				$dump .= &_dump_value($key, $level + 1, 2);
				$dump .= " => ";
				$dump .= &_dump_value($val, $level + 1, 1);
				$dump .= "," . _dump_eol();
			}
			if ($size > $dump_array_limit) {
				$dump .= _dump_prefix($level + 1);
				$dump .= "...[+" . ($size - $dump_array_limit + 1) . "]," . _dump_eol();
			}
			$dump .= _dump_prefix($level) . "}";
		}
	} elsif ($type eq 'REF') {
		$dump .= "REF";
	} elsif ($type eq 'CODE') {
		$dump .= "CODE";
	} elsif ($type eq 'GLOB') {
		$dump .= "GLOB";
	} elsif ($type eq 'SCALAR') {
		$dump .= "\\";
		$dump .= &_dump_value($$value, $level + 1, 1);
	} else {
		$dump .= "$type ";
		my $native_type;
		foreach ('SCALAR', 'ARRAY', 'HASH', 'CODE', 'GLOB') {
			$native_type = $_ if $value->isa($_);
		}
		die "Non-standard perl ref type to dump in $value\n" unless $native_type;

		$dump_seen{$value} = 0;
		bless($value, $native_type);
		$dump .= &_dump_value($value, $level, 1);
		bless($value, $type);
	}

	$dump .= _dump_eol() unless $inline;

	return $dump;

}

sub dump ($;$) {
	my $self = shift;
	my $level = 0;

	my $dump = _dump_value($self);

	%dump_seen = ();

	return $dump;
}

our $AUTOLOAD;

sub AUTOLOAD ($;@) {
	my $self = shift;
	my @params = @_;

	my $method = $AUTOLOAD;
	$method =~ s/.*://g;

	return if $method eq 'DESTROY';  # ignore DESTROY messages

	die "Calling method $method for non-object '$self'\n"
		unless ref($self);

	if (exists $self->{$method}) {
		# define this accessor method explicitely if not yet
		no strict 'refs';
		*{$AUTOLOAD} = sub {
			my $self = shift;
			warn "Skipping extraneous params (@_) on access of field '$method' in $self\n"
				if @_ > 1;
			$self->{$method} = shift if @_;
			return $self->{$method};
		} unless $self->can($AUTOLOAD);

		return *{$AUTOLOAD}->($self, @params);
	}

	die "Unknown method or field '$method' in $self\n";
}

1;

__END__
# ----------------------------------------------------------------------------

=head1 NAME

SMB - A humble SMB network protocol implementation in Perl

=head1 SYNOPSIS

	use SMB::Server;

	my $server = SMB::Server->new(port => 10445);
	$server->run;


	use SMB::Client;

	my $client = SMB::Client->new('//10.0.2.2/test',
		username => 'test',
		password => 'secret',
	);
	my $tree = $client->connect_tree;
	$tree = $client->connect_tree('/test2');

	for my $file ($tree->find("*.txt")) {
		printf "%-40s %s\n", $file->name, $file->mtime_string;
	}

=head1 ABSTRACT

SMB is a network protocol created by Microsoft used to provide shared
access to files. It stands for Server Message Block, also called CIFS -
Common Internet File System.

This SMB framework in written in pure perl. It allows to receive and send
SMB commands, implements authentication protocols used in SMB, provides
an object model to conveniently work with local and remote files, trees
and more. Some basic SMB server and client functionality is available.

The main purpose of this framework is to simplify creation of automatic
tools for serving and fetching files using SMB protocol and for testing
existing SMB server and client implementations.

=head1 DESCRIPTION

SMB-Perl library is an implementation of SMB protocol, including simple
SMB client and server functionality.

SMB is a base class for many SMB::* classes.

It provides a common logging and debugging functionality and some sugar,
like auto-created getter and setter methods for all object fields.
It also defines some core SMB protocol constants, like status codes.

=head1 METHODS

=over 4

=item new [FIELDS]

Class constructor. Creates an instance of the concrete class and
initilizes it from FIELDS hash.

The sub-classes may omit a constructor, then this one is used, or they
may overload it and call $class->SUPER::new(%options) to obtain the newly
created object.

=item log IS_ERROR FORMAT [ARGS]

This method is used for logging. The message is composed by "sprintf"
FORMAT and ARGS, and is by default written to standard output.

The logging is enabled by default, unless (quiet => 1) is passed in
constructor.

The error messages (IS_ERROR=1) are prefixed with "! ", the normal
messages are prefixed with "* ".

=item msg FORMAT [ARGS]

The same as B<log> with IS_ERROR=0.

=item err FORMAT [ARGS]

The same as B<log> with IS_ERROR=1.

=item mem BUFFER [LABEL]

If the logging is enabled, logs a message containg LABEL and BUFFER size
in bytes and then a nice memory dump, looking like:

 * NBSS + SMB Negotiate Request (216 bytes):
 000 | 00 00 00 d4 ff 53 4d 42  72 00 00 00 00 18 43 c8 | ___..SMB r____.C. |
 001 | 00 00 00 00 00 00 00 00  00 00 00 00 00 00 fe ff | ________ ______.. |
 002 | 00 00 00 00 00 b1 00 02  50 43 20 4e 45 54 57 4f | _____._. PC NETWO |
 003 | 52 4b 20 50 52 4f 47 52  41 4d 20 31 2e 30 00 02 | RK PROGR AM 1.0_. |
 004 | 4d 49 43 52 4f 53 4f 46  54 20 4e 45 54 57 4f 52 | MICROSOF T NETWOR |
 005 | 4b 53 20 31 2e 30 33 00  02 4d 49 43 52 4f 53 4f | KS 1.03_ .MICROSO |
 006 | 46 54 20 4e 45 54 57 4f  52 4b 53 20 33 2e 30 00 | FT NETWO RKS 3.0_ |
 007 | 02 4c 41 4e 4d 41 4e 31  2e 30 00 02 4c 4d 31 2e | .LANMAN1 .0_.LM1. |
 008 | 32 58 30 30 32 00 02 44  4f 53 20 4c 41 4e 4d 41 | 2X002_.D OS LANMA |
 009 | 4e 32 2e 31 00 02 4c 41  4e 4d 41 4e 32 2e 31 00 | N2.1_.LA NMAN2.1_ |
 00a | 02 53 61 6d 62 61 00 02  4e 54 20 4c 41 4e 4d 41 | .Samba_. NT LANMA |
 00b | 4e 20 31 2e 30 00 02 4e  54 20 4c 4d 20 30 2e 31 | N 1.0_.N T LM 0.1 |
 00c | 32 00 02 53 4d 42 20 32  2e 30 30 32 00 02 53 4d | 2_.SMB 2 .002_.SM |
 00d | 42 20 32 2e 3f 3f 3f 00                          | B 2.???_          |

=item dump

Returns a neat object's presentation as a multi-line string, like:

 SMB::v2::Command::Close {
     disable_log => 0,
     fid => [
         2,
         0,
     ],
     flags => 0,
     header => SMB::v2::Header {
         aid => 0,
         code => 6,
         credit_charge => 1,
         credits => 7802,
         disable_log => 0,
         flags => 0,
         mid => 15,
         signature => [
             ("\x00") x 16,
         ],
         status => 0,
         struct_size => 24,
         tid => 2,
         uid => 1,
     },
     name => "Close",
     openfile => undef,
     smb => 2,
 }

The returned string looks mostly as a valid perl with a minimal overhead.
Huge arrays, hashes and strings are neatly cut with some info preserved
about what was omitted.

=item FIELD

=item FIELD NEW_VALUE

For each field in the object, the method of this name is auto-create on
demand. This method returns the field value if there are no arguments
(getter) and sets NEW_VALUE if there is a single argument (setter).

=back

=head1 SEE ALSO

http://migo.sixbit.org/software/smb-perl/

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Mikhael Goikhman <migo@cpan.org>

