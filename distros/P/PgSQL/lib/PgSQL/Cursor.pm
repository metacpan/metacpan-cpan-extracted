package PgSQL::Cursor;

# This perl module is Copyright (c) 1998 Göran Thyni, Sweden.
# All rights reserved.
# You may distribute under the terms of either 
# the GNU General Public License version 2 (or later)
# or the Artistic License, as specified in the Perl README file.
#
# $Id: Cursor.pm,v 1.5 1998/08/15 15:09:49 goran Exp $


use strict;

use vars qw($VERSION);

$VERSION = '0.51';


sub new 
  {
    my ($class,$socket,$name,$query) = @_;
    my $self = {};
    bless $self,$class;
    $self->{SOCKET} = $socket;
    $self->{NAME} = $name if $name;
    $self->{QUERY} = $query if $query;
    $self;
}

sub exec
  {
    my ($self, @params) = @_;
    my $sock =  $self->{SOCKET};
    my $query = $self->{QUERY};
    my $is_select = $query =~ /^\s*select\s/i;
    my $complete = 0;
    $sock->errmsg(0);
    $sock->flush_input;
    for (@params) { $query =~ s/\?/'$_'/; } 
    return 0 if !$sock->sendQuery($query);
    $sock->wait(1,0);
    my $lastResult = undef;
    while (1)
      {
	my ($result, @rest) = $sock->parseInput;
	# print STDERR "exec: $result\n" if $result;
	$complete++ if $result eq 'C' or $result eq 'I';
	last if $complete and $result eq 'Z';
	$lastResult = $result;
	# last if ($result == PGRES_COPY_IN || $result == PGRES_COPY_OUT);
      }
    my $err = $sock->errmsg;
    return $err ? 0 : 1;
  }
  
sub execute
  {
    shift->exec(@_);
  }

sub nfields
  {
    my ($self,$val) = @_;
    $self->{NFIELDS} = $val if defined $val;
    $self->{NFIELDS};
  }

sub fields
  {
    my ($self,$val) = @_;
    $self->{FIELDS} = $val if defined $val;
    $self->{NTUPLES} = 0;
    $self->{COUNT} = 0;
    $self->{FIELDS};
  }

sub add
  {
    my ($self,$tuple) = @_;
    $self->{NTUPLES}++;
    push @{$self->{TUPLES}}, $tuple;
  }

sub fetch
  {
    my $self = shift;
    my $aref = $self->{TUPLES};
    my $count = \$self->{COUNT};
    $$count ||= 0;
    return 0 unless $$count < $self->{NTUPLES};
    return $aref->[$$count++];
  }

sub finish
  {
    my $self = shift;
    $self->fields;
    $self->{NFIELDS} = $self->{NTUPLES} = 0;
    delete $self->{TUPLES};
    1;
  }

sub bind_param
  {
    my $self = shift;
    0; # dummy
  }

sub bind_columns
  {
    my $self = shift;
    0; # dummy
  }

sub rows
  {
    my $self = shift;
    $self->{NTUPLES};
  }

1;


