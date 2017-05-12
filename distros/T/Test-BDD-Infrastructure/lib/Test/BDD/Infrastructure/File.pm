package Test::BDD::Infrastructure::File;

use strict;
use warnings;

our $VERSION = '1.005'; # VERSION
# ABSTRACT: cucumber step definitions for checking files
 
use Test::More;
use Test::BDD::Cucumber::StepFile qw( Given When Then );

sub S { Test::BDD::Cucumber::StepFile::S }

use Test::BDD::Infrastructure::Utils qw(
	convert_unit convert_cmp_operator $CMP_OPERATOR_RE convert_interval);

use File::Slurp;


Given qr/the (?:file|directory) (\S+) exists/, sub {
	my $path = $1;

	if( ! -e $path ) {
		fail("the file $path does not exist");
	}
	S->{'path'} = $path;
};


# perl file test operators
Then qr/the file must be empty/, sub {
	my $path = S->{'path'};
	ok( -z $path, "file $path must be empty");
};
Then qr/the file must be non-zero size/, sub {
	my $path = S->{'path'};
	ok( -s $path, "file $path must be non-zero size");
};
Then qr/the file must be non-zero size/, sub {
	my $path = S->{'path'};
	ok( -s $path, "file $path must be non-zero size");
};
Then qr/the file type must be plain file/, sub {
	my $path = S->{'path'};
	ok( -f $path, "file $path must be a plain file");
};
Then qr/the file type must be directory/, sub {
	my $path = S->{'path'};
	ok( -d $path, "file $path must be a directory");
};
Then qr/the file type must be symbolic link/, sub {
	my $path = S->{'path'};
	ok( -l $path, "file $path must be a symbolic link");
};
Then qr/the file type must be socket/, sub {
	my $path = S->{'path'};
	ok( -S $path, "file $path must be a socket");
};
Then qr/the file type must be pipe/, sub {
	my $path = S->{'path'};
	ok( -p $path, "file $path must be a pipe");
};
Then qr/the file type must be block device/, sub {
	my $path = S->{'path'};
	ok( -b $path, "file $path must be a block device");
};
Then qr/the file type must be character device/, sub {
	my $path = S->{'path'};
	ok( -c $path, "file $path must be a character device");
};


# stat()
Then qr/the file mode must be (\d+)/, sub {
	my $mode = $1;
	my $path = S->{'path'};
	my $file_mode = sprintf("%04o", (stat($path))[2] & oct(7777) );
	cmp_ok( $file_mode, 'eq', $mode, "file mode of $path must be $mode");
};
Then qr/the file must be owned by user (\S+)/, sub {
	my $uid = $1;
	if( $uid !~ /^\d+$/) {
		$uid = getpwnam( $uid );
	}
	my $path = S->{'path'};
	cmp_ok( (stat($path))[4], 'eq', $uid, "file owner of $path must be uid $uid");
};
Then qr/the file must be owned by group (\S+)/, sub {
	my $gid = $1;
	if( $gid !~ /^\d+$/) {
		$gid = getgrnam( $gid );
	}
	my $path = S->{'path'};
	cmp_ok( (stat($path))[5], 'eq', $gid, "file owner of $path must be gid $gid");
};
Then qr/the file size must be $CMP_OPERATOR_RE (\d+) (\S+)/, sub {
	my $op = convert_cmp_operator( $1 );
	my $size = convert_unit( $2, $3 );
	my $path = S->{'path'};
	cmp_ok( (stat($path))[7], $op, $size, "size of file $path must be $op $size");
};
Then qr/the file ([acm]time) must be $CMP_OPERATOR_RE (\d+) (\S+)/, sub {
	my $path = S->{'path'};
	my $field = $1;
	my $time;
	if( $field eq 'atime' ) {
		$time = (stat($path))[8]; # atime
	} elsif( $field eq 'ctime' ) {
		$time = (stat($path))[10]; # ctime
	} else {
		$time = (stat($path))[9]; # mtime
	}
	my $op = convert_cmp_operator( $2 );
	my $seconds = convert_interval( $3, $4 );
	my $age = time - $time;
	cmp_ok( $age, $op, $seconds, "the $field age of file $path must be $op $seconds");
};


# lines
Then qr/the file must contain $CMP_OPERATOR_RE (\d+) lines/, sub {
	my $path = S->{'path'};
	my $op = convert_cmp_operator( $1 );
	my $count = $2;
	my @content = read_file( $path );
	cmp_ok( scalar(@content), $op, $count, "the file $path must contain $op $count lines");
};

Then qr/the files? content must (not match|match) (.*)$/, sub {
	my $path = S->{'path'};
	my $regex = $2;
	my $content = read_file( $path );
	if( $1 eq 'not match' ) {
		unlike( $content, qr/$regex/, "files content must not match $regex");
	} else {
		like( $content, qr/$regex/, "files content must match $regex");
	}
};


# directory
Then qr/the directory must contain $CMP_OPERATOR_RE (\d+) files/, sub {
	my $path = S->{'path'};
	my $op = convert_cmp_operator( $1 );
	my $count = $2;
	my @content = read_dir( $path );
	cmp_ok( scalar(@content), $op, $count, "the directory $path must contain $op $count files");
};
Then qr/the directory must contain (a|no) file like (.*)$/, sub {
	my $path = S->{'path'};
	my $regex = $2;
	my @files = read_dir( $path );
	my $matched = 0;
	foreach my $file ( @files ) {
		if( $file =~ /$regex/ ) {
			$matched++;
			diag('file matched: '.$file);
		}
	}
	if( $1 eq 'no' ) {
		cmp_ok($matched, '==', 0, "no file in the directory must match $regex");	
	} else {
		cmp_ok($matched, '>', 0, "a file in the directory must match $regex");	
	}
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure::File - cucumber step definitions for checking files

=head1 VERSION

version 1.005

=head1 Synopsis

  Scenario: Check /etc/hosts file
    Given the file /etc/hosts exists
    Then the file must be non-zero size
    And the file type must be plain file
    And the file mode must be 0644
    And the file must be owned by user root
    And the file must be owned by group root
    And the file size must be at least 200 byte
    And the file mtime must be newer than 20 years
    And the file mtime must be older than 30 seconds
    And the file must contain at least 10 lines

  Scenario: test /etc directory
    Given the directory /etc exists
    Then the file type must be directory
    And the directory must contain at least 100 files

=head1 Step definitions

The path of the directory or file must be specified with:

  Given the file <path> exists

or

  Given the directory <path> exists

=head2 Basic file checks

  Then the file must be empty
  Then the file must be non-zero size
  Then the file must be non-zero size
  Then the file type must be plain file
  Then the file type must be directory
  Then the file type must be symbolic link
  Then the file type must be socket
  Then the file type must be pipe
  Then the file type must be block device
  Then the file type must be character device

=head2 File attribute checks

  Then the file mode must be <octal mode>
  Then the file must be owned by user <uid|username>
  Then the file must be owned by group <gid|groupname>
  Then the file size must be <compare operator> <count> <byte unit>
  Then the file atime must be <compare operator> <count> <interval>
  Then the file ctime must be <compare operator> <count> <interval>
  Then the file mtime must be <compare operator> <count> <interval>

=head3 Examples

  Then the file must be owned by user root
  Then the file mtime must be newer than 20 years
  Then the file size must be at least 200 bytes

=head2 File content checks

  Then the file must contain <compare> <count> lines
  Then the files content must match <regex>
  Then the files content must not match <regex>

=head2 Directory content checks

  Then the directory must contain <compare> <count> files
  Then the directory must contain a file like <regex>
  Then the directory must contain no file like <regex>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
