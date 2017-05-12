#line 1 "SVN/Agent/Dummy.pm"
use strict;
use warnings FATAL => 'all';

package SVN::Agent::Dummy;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors('path', 'changes');
use Carp;

our $VERSION = 0.04;

#line 39

sub _svn_command {
	my ($self, $cmd, @params) = @_;
	my $cmd_line = "cd " . $self->path . " && svn $cmd ";
	if (@params) {
       map { $_ =~ s/ /\\ /g } @params;
        $cmd_line .= join(' ', map { $_ } @params) ;
      }
	my @res;
      if ($cmd eq 'add -N' || $cmd eq 'remove' || $cmd eq 'commit -m') {
        @res = ("$cmd_line 2>&1\n");
      }
      elsif ($cmd eq 'update') {
        @res = "$cmd_line 2>&1$/";
      }
      else {
        @res = `$cmd_line 2>&1`;
      }
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

#line 76

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

#line 94
sub modified { return shift()->{M} || []; }

#line 101

sub added { return shift()->{A} || []; }

#line 109

sub unknown { return shift()->{'?'} || []; }

#line 117

sub deleted { return shift()->{D} || []; }

#line 130

sub missing { return shift()->{'!'} || []; }

#line 139

sub add {
	my ($self, $file) = @_;
	#my $p = '.';
	my $p = '';
	my $res = '';
	for (split('/', $file)) {
		#$p .= "/$_";
		$p .= "$_";
		my $r = join('', $self->_svn_command('add -N', $p));
		next if $r =~ /already under version/;
		$res .= $r;
		push @{ $self->changes }, $p;
	}
	return $res;
}

#line 161

sub revert {
	return shift()->_svn_command("revert", @_);
}

#line 171

sub prepare_changes {
	my $self = shift;
	push @{ $self->changes }, @{ $self->$_ }
		for qw(modified added deleted);
}

#line 184
sub commit {
	my ($self, $msg) = @_;
	die "No message given" unless $msg;
	my $ch = $self->changes;
	confess "Empty commit" unless @$ch;
	my @res = $self->_svn_command('commit -m', '"'.$msg.'"'); # , @$ch
	$self->changes([]);
	return @res;
}

#line 199
sub update { return shift()->_svn_command('update'); }

#line 207
sub remove {
	my ($self, $file) = @_;
	my $res = $self->_svn_command('remove', $file);
	push @{ $self->changes }, $file;
	return $res;
}

#line 219
sub diff { return join('', shift()->_svn_command('diff', @_)); }

#line 227
sub checkout {
	my ($self, $repository) = @_;
	mkdir($self->path) or confess "Unable to create " . $self->path;
	return $self->_svn_command('checkout', $repository, '.');
}

1;

#line 249

