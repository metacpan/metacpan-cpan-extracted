package VCP::Filter::cvslabelonbranch;

=head1 NAME

VCP::Filter::cvslabelbranch - put cvs label on apropriate branch

=head1 SYNOPSIS

  ## From the command line:
   vcp <source> cvslabelbranch: ...options... -- <dest>

  ## In a .vcp file:

    CVSLabelonBranch:

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
   'WHICH_BRANCH',
);

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $self = $class->SUPER::new( @_ ) ;

    return $self ;
}

sub handle_header {
    my VCP::Filter::cvslabelonbranch $self = shift;
    $self->revs->set;  ## clear the list
    $self->SUPER::handle_header( @_ );
}

## WHICH_BRANCH { labelname } { from_branch } = [ rev, ... ]

sub handle_rev {
    my VCP::Filter::cvslabelonbranch $self = shift;
    my $r = shift;

    if ($r->action eq 'placeholder' && $r->previous) {
	if (my @l = $r->previous->labels) {
	    push @{$self->{WHICH_BRANCH}{$_}{$r->branch_id}}, $r
		for @l;
	}
    }
    elsif (my @l = $r->labels) {
	push @{$self->{WHICH_BRANCH}{$_}{$r->branch_id || 'trunk'}}, $r
	    for @l;
    }

    $self->revs->add($r);
}

sub handle_footer {
    my VCP::Filter::cvslabelonbranch $self = shift;

    for my $label (keys %{$self->{WHICH_BRANCH}}) {
	debug "deciding primary branch of the label $label"
	    if debugging;

	my @branches = sort {$#{$self->{WHICH_BRANCH}{$label}{$b}} <=>
				 $#{$self->{WHICH_BRANCH}{$label}{$a}}}
	keys %{$self->{WHICH_BRANCH}{$label}};

	for my $r (@{$self->{WHICH_BRANCH}{$label}{$branches[0]}}) {
	    next unless $r->action eq 'placeholder';
	    debug "stealing label $label to branch $branches[0] from ".
		$r->previous->as_string if debugging;

	    $r->previous->set_labels([grep{$_ ne $label}$r->previous->labels]);
	    $r->set_labels([$r->labels, $label]);
	}
    }

    undef $self->{WHICH_BRANCH};

    $self->SUPER::handle_rev( $_ ) for $self->revs->get;
    $self->revs->remove_all;
    $self->SUPER::handle_footer( @_ );
}

=head1 AUTHOR

Chia-liang Kao <clkao@clkao.org>

=head1 COPYRIGHT

Copyright (c) 2003 Chia-liang Kao. All rights reserved.

=cut

1
