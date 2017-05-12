package VCP::Filter::svncompactbranch;

=head1 NAME

VCP::Filter::svncompactbranch - compact branch to conserve memory

=head1 SYNOPSIS

  ## From the command line:
   vcp <source> svncompactbranch: ...options... -- <dest>

  ## In a .vcp file:

    SVNCompactBranch:

=head1 DESCRIPTION

=cut

$VERSION = 1 ;

use strict ;
use VCP::Logger qw( lg pr );
use VCP::Debug qw( :debug );
use VCP::Utils qw( empty );
use VCP::Filter;
use VCP::Rev;
use base qw( VCP::Filter );

use fields (
   'COMPACT_BRANCH',
   'COMPACT_BRANCH_TIME',
   'COMPACT_MAP',
   'COMPACT_REVS',
);

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $self = $class->SUPER::new( @_ ) ;

    return $self ;
}

sub handle_header {
    my $self = shift;
    $self->revs->set;  ## clear the list
    $self->SUPER::handle_header( @_ );
}

sub handle_rev {
    my $self = shift;
    my $r = shift;
    my @label = $r->labels;

    if ($r->action eq 'placeholder' && $#label == -1) {
	my $frombranch = $r->previous->branch_id || 'trunk';
	debug "merging revs for: $frombranch -> ".$r->branch_id if debugging;

	my $pr = $self->{COMPACT_BRANCH}{$r->branch_id}{$frombranch}[0];

	if ($r->branch_id =~ m/^_branch_/ || ($r->previous && $r->previous->time >= $r->time)) {
	    debug "don't join ".$r->id if debugging;
	    push @{$self->{COMPACT_REVS}}, $r;
	    return;
	}

	unless ($pr) {
	    debug "primary entry: ".$r->name."#".$r->rev_id if debugging;
	    $pr = $self->{COMPACT_BRANCH}{$r->branch_id}{$frombranch}[0] =$r;
	    $pr->set_svn_info([]);

	    push @{$self->{COMPACT_REVS}}, $pr;
	}

	debug "joining ".$r->id if debugging;
	push @{$pr->svn_info}, {
	    id		=> $r->id,
	    name	=> $r->name,
	    previous_id	=> $r->previous_id,
	    previous	=> $r->previous,
	    rev_id	=> $r->rev_id,
	    ref		=> $pr,
	};

	$self->{COMPACT_BRANCH_TIME}{$r->branch_id} = $r->time
	    if !defined $self->{COMPACT_BRANCH_TIME}{$r->branch_id}
	|| $self->{COMPACT_BRANCH_TIME}{$r->branch_id} > $r->time;

	++$self->{COMPACT_BRANCH}{$r->branch_id}{$frombranch}[1];

	$self->{COMPACT_MAP}{$r->id} = $pr;
    }
    else {
    	push @{$self->{COMPACT_REVS}}, $r;
    }
}

sub handle_footer {
    my $self = shift;

    for my $r (@{$self->{COMPACT_REVS}}) {
	next if $r->svn_info;
	if ((my $pr = $r->previous) &&
	    (my $compact = $self->{COMPACT_MAP}{$r->previous_id})) {
	    $r->previous ($compact);
	}
    }

=comment

    for my $branch (keys %{$self->{COMPACT_BRANCH}}) {
	my $branchrev = $self->{COMPACT_BRANCH}{$branch};
	my @branchpref = sort {$branchrev->{$b}[1] <=> $branchrev->{$a}[1]}
		keys %$branchrev;

	my $i = 1;
	for (@{$branchrev}{@branchpref}) {
	    $_->[0]->time($self->{COMPACT_BRANCH_TIME}{$branch} + $i);
	    ++$i;
	}
    }

=cut

    undef $self->{COMPACT_BRANCH};
    undef $self->{COMPACT_BRANCH_TIME};
    undef $self->{COMPACT_MAP};

    $self->SUPER::handle_rev( $_ ) for @{$self->{COMPACT_REVS}};
    $self->SUPER::handle_footer( @_ );
}

=head1 AUTHOR

Chia-liang Kao <clkao@clkao.org>

=head1 COPYRIGHT

Copyright (c) 2003 Chia-liang Kao. All rights reserved.

=cut

1
