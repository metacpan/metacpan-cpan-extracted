package SqlBatch::Plan;

# ABSTRACT: Class for execution plan

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;
use Data::Dumper;
use SqlBatch::RunState;
use parent "SqlBatch::AbstractPlan";

sub new {
    my $class  = shift;
    my $config = shift // croak("No configuration given");

    my $self = SqlBatch::AbstractPlan->new(
	$config,	
	filters       => [],
	instructions  => [],
	runstate      => SqlBatch::RunState->new(),
    );

    return bless $self, $class;
}

sub add_filter {
    my $self = shift;
    push @{$self->{filters}},shift;
}

sub add_instructions {
    my $self         = shift;
    my @instructions = @_;

    my $address = scalar(@{$self->{instructions}});

    my $new_instructions;
    if (scalar(@{$self->{filters}})) {
	my @filtered = grep {
	    my $ok_sum = 0;
	    
	    for my $filter (@{$self->{filters}}) {
		$ok_sum += 1 
		    if $filter->is_allowed_instruction($_);
	    }

	    $ok_sum;
	} @instructions;

	$new_instructions = \@filtered;
    } else {
	$new_instructions = \@instructions;
    }

    push @{$self->{instructions}},map {
	$_->address($address);
	$address++;
	$_
    } @$new_instructions;

}

sub run {
    my $self = shift;

    $self->{runstate} = SqlBatch::RunState->new();

    my $instructions_count = scalar(@{$self->{instructions}});
    $self->{former_instruction_address}  = 0;
    $self->{current_instruction_address} = 0;
    
    while ($self->{current_instruction_address} < $instructions_count) {
       
	my $instruction = $self->{instructions}->[$self->{current_instruction_address}];

	# Initialize runstate and environment for instruction before running
	$instruction->runstate($self->{runstate});
	$instruction->databasehandle($self->current_databasehandle());

	# Run it
	eval {
	    $instruction->run;

	    # Transport the runstate for the next instruction
	    my $last_runstate = $instruction->runstate();	
	    $self->{runstate} = SqlBatch::RunState->new($last_runstate);

	    # Count to next instruction
	    $self->{former_instruction_address} = $self->{current_instruction_address};
	    $self->{current_instruction_address}++;
	};
	if ($@) {
	    say STDERR "Error while executing instruction:";
	    say STDERR " instruction type:".ref($instruction);
	    say STDERR " file: ".$instruction->argument('file');
	    say STDERR " line: ".$instruction->argument('line_nr');
	    say STDERR " error: ".$@;	    
	    say STDERR " dump: ".Dumper($instruction->state_dump);
	    exit 1;
	}
    }
}

sub current_databasehandle {
    my $self = shift;

    my $dbhs = $self->configuration->database_handles;
    my $mode = $self->{runstate}->commit_mode();

    return $dbhs->{$mode};
}

1;

__END__

=head1 NAME

SqlBatch::Plan

=head1 DESCRIPTION

This class manages the sqlbatch-instruction sequence and it's execution.

=head1 AUTHOR

Sascha Dibbern (sascha at dibbern.info)

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
