package Test::BDD::Cucumber::Harness::Nagios;

use Moose;

# ABSTRACT: Nagios output for Test::BDD::Cucumber
our $VERSION = '1.002'; # VERSION

use Time::HiRes qw ( time );
use Time::Piece;

use Getopt::Long;

extends 'Test::BDD::Cucumber::Harness::Data';

use Test::BDD::Cucumber::Harness::Nagios::Result;

has all_scenarios => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );
has current_feature  => ( is => 'rw', isa => 'HashRef' );
has current_scenario => ( is => 'rw', isa => 'HashRef' );
has step_start_at    => ( is => 'rw', isa => 'Num' );

sub scenario {
    my ( $self, $scenario, $dataset ) = @_;
    $self->current_scenario( $self->format_scenario($scenario) );
    push @{ $self->all_scenarios }, $self->current_scenario;
}

sub step {
    my ( $self, $context ) = @_;
    $self->step_start_at( time() );
}

sub step_done {
    my ( $self, $context, $result ) = @_;
    my $duration = time() - $self->step_start_at;
    my $step_data = $self->format_step( $context, $result, $duration );
    my $status = $step_data->{'result'}->{'status'};

    push @{ $self->current_scenario->{steps} }, $step_data;
}


sub get_keyword {
    my ( $self, $line_ref ) = @_;
    my ($keyword) = $line_ref->content =~ /^(\w+)/;
    return $keyword;
}

sub format_tags {
    my ( $self, $tags_ref ) = @_;
    return [ map { { name => '@' . $_ } } @$tags_ref ];
}

sub format_description {
    my ( $self, $feature ) = @_;
    return join "\n", map { $_->content } @{ $feature->satisfaction };
}

sub format_scenario {
    my ( $self, $scenario, $dataset ) = @_;
    return {
        keyword => $self->get_keyword( $scenario->line ),
        id      => "scenario-" . int($scenario),
        name    => $scenario->name,
        line    => $scenario->line->number,
        tags    => $self->format_tags( $scenario->tags ),
        type    => $scenario->background ? 'background' : 'scenario',
        steps   => [],
    };
}

sub format_step {
    my ( $self, $step_context, $result, $duration ) = @_;
    my $step = $step_context->step;
    my $rand = int( rand() * 10000000);
    return {
        keyword => $step ? $step->verb_original : $step_context->verb,
        id => "step-".$rand, 
        name => $step_context->text,
        background => $step_context->background,
        line => $step ? $step->line->number : 0,
        result => $self->format_result( $result, $duration )
    };
}

has '_output_status' => ( is => 'ro', isa => 'HashRef', lazy => 1,
	    default => sub { {
	    passing   => 'passed',
	    failing   => 'failed',
	    pending   => 'pending',
	    undefined => 'skipped',
    } },
);

sub format_result {
    my ( $self, $result, $duration ) = @_;
    my $ret;

    if( $result ) {
	    $ret = {
		status        => $self->_output_status->{ $result->result },
		error_message => $result->output,
		defined $duration
		? ( duration => int( $duration * 1_000_000_000 ) )
		: (),    # nanoseconds
	    };
    } else {
    	$ret = { status => "undefined" };
    }

    return $ret;
}

sub generate_steps_output {
	my ( $self, $scenario ) = @_;
	my $message = '';
	foreach my $step ( @{$scenario->{'steps'}} ) {
		# append error message, but limit to 10 lines
		if( $step->{'result'}->{'status'} eq 'failed' ) {
			$message .= 'line '.$step->{'line'}.': '
				.$step->{'keyword'}.' '.$step->{'name'}.': '
				.$step->{'result'}->{'status'}."\n";
			my $err = $step->{'result'}->{'error_message'};
			$err =~ s/^/  /mg;
			$message .= $err;
		}
	}
	return( $message );
}

sub result {
    my ($self) = @_;
        my $total = scalar @{$self->all_scenarios};
        my $failed_critical = 0;
        my $failed_warn = 0;
	my $output = '';
	my $code = 2;
        foreach my $scenario ( @{$self->all_scenarios} ) {
                if( grep { $_->{'result'}->{'status'} ne 'passed' } @{$scenario->{'steps'}} ) {
                        if( grep { $_->{'name'} eq '@warn' }  @{$scenario->{'tags'}} ) {
                                $failed_warn++;
                        } else {
                                $failed_critical++;
                        }
                	$output .= $self->generate_steps_output( $scenario );
                }
        }
	if( $failed_critical ) {
		$output .= "CRITICAL - $failed_critical (critical) / $failed_warn (warn) out of $total scenarios failed\n";
		$code = 2;
	} elsif ( $failed_warn ) {
		$output .= "WARN - :$failed_critical (critical) / $failed_warn (warn) out of $total scenarios failed\n";
		$code = 1;
	} else {
		$output .= "OK - all $total scenarios passed\n";
		$code = 0;
	}

	return Test::BDD::Cucumber::Harness::Nagios::Result->new(
		nagios_code => $code,
		output => $output,
	);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Cucumber::Harness::Nagios - Nagios output for Test::BDD::Cucumber

=head1 VERSION

version 1.002

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
