use strict;
use warnings FATAL => 'all';

package SVN::Agent;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors('path', 'changes');
use Carp;

our $VERSION = 0.04;

=head1 NAME

SVN::Agent - simple svn manipulation.

=head1 SYNOPSIS

  use SVN::Agent;

  my $sa = SVN::Agent->load({ path => 'my_checkout_dir' });

  # find out modified files
  print join(',', @{ $sa->modified }) . "\n";

  # usual svn operations
  $sa->add('file.pl');
  $sa->commit("Message");

=head1 DESCRIPTION

This module provides regular svn operations on check out directory. It tries
to do this in a simplest form possible.

All operations are currently performed by running svn binary directly. Thus
it is probably unportable.

For a much more powerful way of working with svn repository see SVN::Client.

=cut

sub _svn_command {
	my ($self, $cmd, @params) = @_;
	my $cmd_line = "cd " . $self->path . " && svn $cmd ";
	$cmd_line .= join(' ', map { quotemeta($_) } @params) if @params;
	my @res = `$cmd_line 2>&1`;
	confess "Unable to do $cmd_line\n" . join('', @res) if $?;
	return @res;
}

sub _load_status {
	my $self = shift;
	foreach ($self->_svn_command('status')) {
		chomp;
		# on Leopard we may have additional space before filename
		/^(.).{6}\s?(.+)$/;
		push @{ $self->{$1} }, $2;
	}
}

=head1 METHODS

=head2 load OPTIONS

Constructs SVN::Agent instance. Loads current status of the directory
given by C<path> option.

=cut

sub new {
	my $self = shift()->SUPER::new(@_);
	$self->changes([]) unless $self->changes;
	return $self;
}

sub load {
	my $self = shift()->new(@_);
	$self->_load_status;
	return $self;
}

=head2 modified

Returns array of files which are currently modified.

=cut
sub modified { return shift()->{M} || []; }

=head2 added

Returns array of file which are scheduled for addition.

=cut

sub added { return shift()->{A} || []; }

=head2 unknown

Returns array of files which do not exist in svn repository. 

=cut

sub unknown { return shift()->{'?'} || []; }

=head2 deleted

Returns array of files which are scheduled for deletion.

=cut

sub deleted { return shift()->{D} || []; }

=head2 missing

Returns array of files which are missing from the working directory.

=head2 changes

Returns array of files which are changes for the next commit. Note that
you can also modify this array to change next commit files.

=cut

sub missing { return shift()->{'!'} || []; }

=head2 add FILE

Adds a file into repository. If the file's directory is not under svn control,
L<SVN::Agent> adds it also.

=cut

sub add {
	my ($self, $file) = @_;
	my $p = '.';
	my $res = '';
	for (split('/', $file)) {
		$p .= "/$_";
		my $r = join('', $self->_svn_command('add -N', $p));
		next if $r =~ /already under version/;
		$res .= $r;
		push @{ $self->changes }, $p;
	}
	return $res;
}

=head2 revert

Runs revert command.

=cut

sub revert {
	return shift()->_svn_command("revert", @_);
}

=head2 prepare_changes

Rolls modified, added and deleted arrays into changes array.

=cut

sub prepare_changes {
	my $self = shift;
	push @{ $self->changes }, @{ $self->$_ }
		for qw(modified added deleted);
}

=head2 commit MESSAGE

Commits current changes using MESSAGE as a log message. The changes should
be listed in the changes array. Returns list of the output lines.

=cut
sub commit {
	my ($self, $msg) = @_;
	die "No message given" unless $msg;
	my $ch = $self->changes;
	confess "Empty commit" unless @$ch;
	my @res = $self->_svn_command('commit -m', $msg, @$ch);
	$self->changes([]);
	return @res;
}

=head2 update

Updates current working directory from the latest repository contents.

=cut
sub update { return shift()->_svn_command('update'); }

=head2 remove FILE

Schedules FILE for removal. Note, that it doesn't physically removes the file
from the working directory.

=cut
sub remove {
	my ($self, $file) = @_;
	my $res = $self->_svn_command('remove', $file);
	push @{ $self->changes }, $file;
	return $res;
}

=head2 diff FILE

Diffs the file against the repository.

=cut
sub diff { return join('', shift()->_svn_command('diff', @_)); }

=head2 checkout REPOSITORY

Checks-out working copy from the REPOSITORY into directory given by C<path>
option.

=cut
sub checkout {
	my ($self, $repository) = @_;
	mkdir($self->path) or confess "Unable to create " . $self->path;
	return $self->_svn_command('checkout', $repository, '.');
}

1;

=head1 AUTHOR

Boris Sukholitko <boriss@gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<SVN::Client>, SVN manual.

=cut

