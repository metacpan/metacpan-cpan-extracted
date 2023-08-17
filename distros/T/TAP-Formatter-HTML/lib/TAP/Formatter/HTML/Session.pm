=head1 NAME

TAP::Formatter::HTML::Session - TAP Test Harness output delegate for html output

=head1 SYNOPSIS

 # see TAP::Formatter::HTML

=cut

package TAP::Formatter::HTML::Session;

use strict;
use warnings;

# DEBUG:
#use Data::Dumper 'Dumper';

use base qw( TAP::Base );
use accessors qw( test formatter parser results html_id meta closed );

our $VERSION = '0.13';

sub _initialize {
    my ($self, $args) = @_;

    $args ||= {};
    $self->SUPER::_initialize($args);

    $self->results([])->meta({})->closed(0);
    foreach my $arg (qw( test parser formatter )) {
	$self->$arg($args->{$arg}) if defined $args->{$arg};
    }

    # make referring to it in HTML easy:
    my $html_id = $self->test;
    $html_id    =~ s/[^a-zA-Z\d-]/-/g;
    $self->html_id( $html_id );

    $self->info( $self->test, ':' );

    return $self;
}

# Called by TAP::Parser to create a result after a session is opened
# TODO: override TAP::Parser::ResultFactory and add html-aware results?
# OR: mixin some methods to the results.
# this logic is getting cumbersome. :-/
sub result {
    my ($self, $result) = @_;
    #warn ref($self) . "->result called with args: " . Dumper( $result );

    my $iter = $self->html_id_iterator;
    if ($result->is_test) {
	$self->log( $result->as_string );
	# make referring to it in HTML easy:
	$result->{html_id} = $iter ? $iter->() : $self->html_id . '-' . $result->number;

	# set test status to avoid the hassle of recalculating it in the template:
	$result->{test_status}  = $result->has_todo ? 'todo-' : '';
	$result->{test_status} .= $result->has_skip ? 'skip-' : '';
	$result->{test_status} .= $result->is_actual_ok ? 'ok' : 'not-ok';

	# also provide a 'short' status name to reduce size of html:
	my $short;
	if ($result->has_todo) {
	    if ($result->is_actual_ok) {
		$short = 'u'; # todo-ok = "unexpected" ok
	    } else {
		$short = 't'; # todo-not-ok
	    }
	} elsif ($result->has_skip) {
	    $short = 's'; # skip-ok
	} elsif ($result->is_actual_ok) {
	    $short = 'k'; # ok
	} else {
	    $short = 'n'; # not-ok
	}
	$result->{short_test_status} = $short;

	# keep track of passes for percent_passed calcs:
	if ($result->is_ok) {
	    $self->meta->{passed}++;
	}

	# keep track of passes (including unplanned!) for actual_percent_passed calcs:
	if ($result->is_ok || $result->is_unplanned && $result->is_actual_ok) {
	    $self->meta->{passed_including_unplanned}++;
	}

	# mark passed todo tests for easy reference:
	if ($result->has_todo && $result->is_actual_ok) {
	    $result->{todo_passed} = 1;
	}
    } else {
	$self->info( $result->as_string );
    }

    $self->set_result_css_type( $result );

    push @{ $self->results }, $result;
    return;
}

# TODO: inheritance was created for a reason... use it
use constant result_css_type_map =>
  {
   plan    => 'pln',
   pragma  => 'prg',
   test    => 'tst',
   comment => 'cmt',
   bailout => 'blt',
   version => 'ver',
   unknown => 'unk',
   yaml    => 'yml',
  };

sub set_result_css_type {
    my ($self, $result) = @_;
    my $type = $result->type || 'unknown';
    my $css_type = $self->result_css_type_map->{$type} || 'unk';
    $result->{css_type} = $css_type;
    return $self;
}

# Called by TAP::?? to indicate there are no more test results coming
sub close_test {
    my ($self, @args) = @_;
    # warn ref($self) . "->close_test called with args: " . Dumper( [@args] );
    #print STDERR 'end of: ', $self->test, "\n\n";
    $self->closed(1);
    return;
}

sub as_report {
    my ($self) = @_;
    my $p = $self->parser;
    my $r = {
	     test => $self->test,
	     html_id => $self->html_id,
	     results => $self->results,
	    };

    # add parser info:
    for my $key (qw(
		    tests_planned
		    tests_run
		    start_time
		    end_time
		    skip_all
		    has_problems
		    passed
		    failed
		    todo_passed
		    actual_passed
		    actual_failed
		    wait
		    exit
		   )) {
	$r->{$key} = $p->$key;
    }

    $r->{num_parse_errors} = scalar $p->parse_errors;
    $r->{parse_errors} = [ $p->parse_errors ];
    $r->{passed_tests} = [ $p->passed ];
    $r->{failed_tests} = [ $p->failed ];

    # do some other handy calcs:
    $r->{test_status} = $r->{has_problems} ? 'failed' : 'passed';
    $r->{elapsed_time} = $r->{end_time} - $r->{start_time};
    $r->{severity} = '';
    if ($r->{tests_planned}) {
	# Calculate percentage passed as # passes *excluding* unplanned passes
	# so we can't get > 100%.  Also calc # passes _including_ unplanned
	# in case that's useful for someone.
	my $num_passed = $self->meta->{passed} || 0;
	my $num_actual_passed = $self->meta->{passed_including_unplanned} || 0;
	my $p = $r->{percent_passed} = sprintf('%.1f', $num_passed / $r->{tests_planned} * 100);
	$r->{percent_actual_passed}  = sprintf('%.1f', $num_actual_passed / $r->{tests_planned} * 100);
	if ($p != 100) {
	    my $s;
	    if ($p < 25)    { $s = 'very-high' }
	    elsif ($p < 50) { $s = 'high' }
	    elsif ($p < 75) { $s = 'med' }
	    elsif ($p < 95) { $s = 'low' }
	    else            { $s = 'very-low' }
	    # classify >100% as very-low
	    $r->{severity} = $s;
	}
    } elsif ($r->{skip_all}) {
	; # do nothing
    } else {
	$r->{percent_passed} = 0;
	$r->{severity} = 'very-high';
    }

    if (my $num = $r->{num_parse_errors}) {
	if ($num == 1 && ! $p->is_good_plan) {
	    $r->{severity} ||= 'low'; # prefer value set calculating % passed
	} else {
	    $r->{severity} = 'very-high';
	}
    }

    # check for scripts that died abnormally:
    if ($r->{exit} && $r->{exit} == 255 && $p->is_good_plan) {
	$r->{severity} ||= 'very-high';
    }

    # catch-all:
    if ($r->{has_problems}) {
	$r->{severity} ||= 'high';
    }

    return $r;
}

sub html_id_iterator {
    shift->formatter->html_id_iterator;
}

sub log {
    my ($self, @args) = @_;
    $self->formatter->log_test(@args);
}

sub info {
    my ($self, @args) = @_;
    $self->formatter->log_test_info(@args);
}


1;

__END__


=head1 DESCRIPTION

This module is part of L<TAP::Formatter::HTML>, which provides HTML output
formatting for L<TAP::Harness>.  It handles individual test I<sessions>, eg.
output from an individual test script.

As documentation is a bit sparse at the moment, you'll need to read the source
if you need to inherit/hack on the module at all.

=head1 BUGS

Please use http://rt.cpan.org to report any issues.

=head1 AUTHOR

Steve Purkis <spurkis@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2008-2010 Steve Purkis <spurkis@cpan.org>, S Purkis Consulting Ltd.
All rights reserved.

This module is released under the same terms as Perl itself.

=head1 SEE ALSO

L<TAP::Formatter::HTML>

L<TAP::Formatter::Console::Session> - the default TAP formatter used by L<TAP::Harness>

=cut

