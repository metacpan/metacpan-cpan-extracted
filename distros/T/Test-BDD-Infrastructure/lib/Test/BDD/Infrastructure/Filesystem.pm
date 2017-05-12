package Test::BDD::Infrastructure::Filesystem;

use strict;
use warnings;

our $VERSION = '1.005'; # VERSION
# ABSTRACT: cucumber step definitions for checking file systems
 
use Test::More;
use Test::BDD::Cucumber::StepFile qw( Given When Then );

sub S { Test::BDD::Cucumber::StepFile::S }

use Test::BDD::Infrastructure::Utils qw(
	convert_unit convert_cmp_operator $CMP_OPERATOR_RE convert_interval);


use IPC::Run;

sub check_df_ok {
	my $path = shift;
	my @cmd = ( 'df', '-P', '-T' );
	my ( $in, $out, $err );
	my $stats = {
		path => $path,
	};
	my $ret = IPC::Run::run( \@cmd, \$in, \$out, \$err );
	if( ! $ret ) {
		fail('error running df: '.$err);
		return;
	}
	my @lines = split("\n", $out);
	shift @lines; # remove header

	@$stats{'device', 'type', 'blocks', 'used space', 'free space', 'usage', 'mount point'}
		= split(/\s+/, $lines[0]);
	$stats->{'used space'} *= 1024;
	$stats->{'free space'} *= 1024;
	$stats->{'usage'} =~ s/%$//;
	$stats->{'usage'} /= 100;
	$stats->{'size'} = $stats->{'used space'} + $stats->{'free space'};

	return( $stats );
}

Given qr/a filesystem is mounted on (.*)$/, sub {
	my $path = $1;

	if( ! -e $path ) {
		fail("the file $path does not exist");
	}
	S->{'fs'} = check_df_ok( $path );
};

Then qr/the filesystems? (device|type|mount point) must be(?: like)? (.*)$/, sub {
	like(S->{'fs'}->{$1}, qr/$2/, "the $1 must be like $2");
};
Then qr/the filesystems? (device|type|mount point) must be(?: unlike|not like)? (.*)$/, sub {
	unlike(S->{'fs'}->{$1}, qr/$2/, "the $1 must be unlike $2");
};

Then qr/the filesystems? (blocks|size|used space|free space|usage) must be $CMP_OPERATOR_RE (\d+) (\S+)?/, sub {
	my $key = $1;
	my $op = convert_cmp_operator( $2 );
	my $count = $3;
	if( defined $4 ) {
	  $count = convert_unit( $3, $4 );
  	}
	cmp_ok( S->{'fs'}->{$key}, $op, $count, "the filesystems $key $op $count");
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure::Filesystem - cucumber step definitions for checking file systems

=head1 VERSION

version 1.005

=head1 Description

This step definitions use the output of the df(1) command to check filesystems.

=head1 Synopsis

  Scenario: There must be enought space for the mail queue
    Given a filesystem is mounted on /var/spool/postfix
    Then the filesystems type must be rootfs
    And the filesystems free space must be more than 200 megabyte
    And the filesystems usage must be less than 90 percent

=head1 Step definitions

First select an path to check:

  Given a filesystem is mounted on <path>

Then check parameters with:

  Then the filesystem(s) (device|type|mount point) must be (like) <regex>
  Then the filesystem(s) (device|type|mount point) must be (unlike|not like) <regex>

  Then the filesystem(s) (blocks|size|used space|free space|usage) must be <compare> <count>
  Then the filesystem(s) (blocks|size|used space|free space|usage) must be <compare> <count> <unit>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
