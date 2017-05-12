package Test::BDD::Infrastructure::Process;

use strict;
use warnings;

our $VERSION = '1.005'; # VERSION
# ABSTRACT: cucumber step definitions for checking processes
 
use Test::More;
use Test::BDD::Cucumber::StepFile qw( Given When Then );

sub S { Test::BDD::Cucumber::StepFile::S }

use Test::BDD::Infrastructure::Utils qw(
	convert_unit convert_cmp_operator $CMP_OPERATOR_RE );

use Proc::ProcessTable;


Given qr/there (?:is|are) $CMP_OPERATOR_RE (\d+) process(?:es)? like (.*)/, sub {
	my $op = convert_cmp_operator( $1 );
	my $count = $2;
	my $procname = $3;
	my $t = Proc::ProcessTable->new;
	my @procs = grep {
		$_->cmndline =~ /$procname/
	} @{$t->table};

	cmp_ok( scalar(@procs), $op, $count, "$op $count processes with process name like $procname");

	S->{'proc'} = \@procs;
};

Given qr/a parent process like (\S+) is running/, sub {
	my $procname = $1;
	my $t = Proc::ProcessTable->new;

	my @procs = grep {
		$_->cmndline =~ /$procname/
		&& $_->ppid == 1
	} @{$t->table};
	cmp_ok( scalar(@procs), '==', 1, "parent process of $procname must be running");

	S->{'parent'} = $procs[0];
	S->{'procs'} = \@procs;
};

When qr/there (?:is|are) $CMP_OPERATOR_RE (\d+) child process(?:es)?/, sub {
	my $op = convert_cmp_operator( $1 );
	my $count = $2;
	my $parent = S->{'parent'};
	my $t = Proc::ProcessTable->new;
	my @childs = grep {
		$_->ppid == $parent->pid,
	} @{$t->table};

	cmp_ok( scalar(@childs), $op, $count, "$op $count child processes of parent pid ".$parent->pid);

	S->{'childs'} = \@childs;
	S->{'procs'} = \@childs;
};

When qr/there (?:is|are) $CMP_OPERATOR_RE (\d+) child process(?:es)? like (.*)/, sub {
	my $op = convert_cmp_operator( $1 );
	my $count = $2;
	my $procname = $3;
	my $parent = S->{'parent'};
	my $t = Proc::ProcessTable->new;
	my @childs = grep {
		$_->cmndline =~ /$procname/
		&& $_->ppid == $parent->pid,
	} @{$t->table};

	cmp_ok( scalar(@childs), $op, $count, "$op $count child processes of parent pid ".$parent->pid.' with process name like '.$procname);

	S->{'childs'} = \@childs;
	S->{'proc'} = \@childs;
};


Then qr/the uid of the (?:child )?process(?:es)? must be (\S+)/, sub {
	my $uid = $1;
	if( $uid !~ /^\d+$/) {
		$uid = getpwnam($uid);
	}
	foreach my $proc ( @{S->{'procs'}} ) {
		cmp_ok( $proc->uid, '==', $uid, "uid of process must be $uid");
	}
};

Then qr/the gid of the (?:child )?process(?:es)? must be (\S+)/, sub {
	my $gid = $1;
	if( $gid !~ /^\d+$/) {
		$gid = getgrnam($gid);
	}
	foreach my $proc ( @{S->{'procs'}} ) {
		cmp_ok( $proc->gid, '==', $gid, "gid of process must be $gid");
	}
};

Then qr/the priority of the (?:child )?process(?:es)? must be ([+-]?\d+)/, sub {
	my $prio = $1;
	foreach my $proc ( @{S->{'procs'}} ) {
		cmp_ok( $proc->priority, '==', $prio, "priority of process must be $prio");
	}
};

Then qr/the virtual size of the (?:child )?process(?:es)? must be $CMP_OPERATOR_RE (\d+) (\S+)/, sub {
	my $op = convert_cmp_operator( $1 );
	my $size = $2;
	my $unit = $3;
	$size = convert_unit( $size, $unit );
	foreach my $proc ( @{S->{'procs'}} ) {
		cmp_ok( $proc->size, $op, $size, "virtual size of process must $op $size");
	}
};

Then qr/the RSS size of the (?:child )?process(?:es)? must be $CMP_OPERATOR_RE (\d+) (\S+)/, sub {
	my $op = convert_cmp_operator( $1 );
	my $size = $2;
	my $unit = $3;
	$size = convert_unit( $size, $unit );
	foreach my $proc ( @{S->{'procs'}} ) {
		cmp_ok( $proc->rss, $op, $size, "rss size of process must be $op $size");
	}
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure::Process - cucumber step definitions for checking processes

=head1 VERSION

version 1.005

=head1 Synopis

  Scenario: mtpolicyd must be running
    Given a parent process like ^/usr/bin/mtpolicyd is running
    Then the uid of the process must be mtpolicyd
    Then the gid of the process must be mtpolicyd
    Then the priority of the process must be 20
    Then the RSS size of the process must be smaller than 67108864 byte
    When there are at least 3 child processes
    Then the uid of the child processes must be mtpolicyd
    Then the gid of the child processes must be mtpolicyd
    Then the priority of the child processes must be 20
    Then the RSS size of the child processes must be smaller than 64 MB

=head1 Step definitions

First one or more processes must be selected with the following step definitions:

  Given a parent process like <regex> is running
  ...test parent...
  When there is/are <compare> <count> child process(es)
  ...test childs...

or

  When there is/are <compare> <count> child process(es) like <regex>
  ...test childs...

To test just a flat process structure:

  Given there is/are <compare> <count> process(es) like <regex>

=head2 Test process attributes

  Then the uid of the (child )process(es) must be <uid|username>
  Then the gid of the (child )process(es) must be <gid|groupname>
  Then the priority of the (child )process(es) must be <prio>
  Then the virtual size of the (child )process(es) must be <compare> <count> <byteunit>
  Then the RSS size of the (child )process(es) must be <compare> <count> <byteunit>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
