package Puzzle::DBIx::Crud;

our $VERSION = '0.20';

use base 'Class::Container';

use HTML::Mason::MethodMaker(
	read_write	=> qw/rr cbs opt/
);

sub process {
	my $s		= shift;
	my $rr		= shift;
	my $cbs		= shift;
	my $opt		= shift;

	my $puzzle	= $s->puzzle;
	my $args	= $puzzle->args;
	my $post	= $puzzle->post;

	my $op		= $rr->{op} || $post->op;
	delete $rr->{op};

	my $rec		= $rr->{rec};
	$op = 'r' unless $op =~ /^[fSsCcrudD]$/;
	$op eq 'D' && !($rec) && die "Non posso cancellare un record che non esiste";
	$op eq 'u' && !($rec) && die "Non posso editare un record che non esiste";
	$op eq 'r' && !($rec) && ($op = 'c');
	$op eq 'r' && ($rec) && ($rec->isa('DBIx::Class::ResultSet')) && ($rec->count == 0) && ($op = 'c');

	my $method = "op_$op";
	$s->$method($rr,$cbs,$opt);
}

sub op_r {
	my $s		= shift;
	my $rr		= shift;
	my $cbs		= shift;
	my $opt		= shift;

	$s->_call_callback($cbs,"defaults", $rr, $opt);
	$s->_call_callback($cbs,"pre_r", $rr, $opt);
	$s->puzzle->args->set($rr->{rec},undef,{relship => $rr->{rel}});
	$s->_call_callback($cbs,"post_r", $rr, $opt);
	$s->puzzle->args->op($rr->{op} ||'u');
}

sub op_c {
	my $s		= shift;
	my $rr		= shift;
	my $cbs		= shift;
	my $opt		= shift;

	$s->_call_callback($cbs,"defaults", $rr, $opt);
	$s->_call_callback($cbs,"pre_c", $rr, $opt);
	$s->_call_callback($cbs,"post_c", $rr, $opt);
	$s->puzzle->args->op($rr->{op} ||'C');
}

sub op_C {
	my $s		= shift;
	my $rr		= shift;
	my $cbs		= shift;
	my $opt		= shift;


	my $puzzle	= $s->puzzle;
	my $source	= $rr->{src};
	my @columns = $source->columns;
	my %rec_updates;
	my $args	= $puzzle->post->{args};
	@rec_updates{@columns} = @$args{@columns};

	$rr->{rec_updates} = \%rec_updates;

	$s->_call_callback($cbs,"defaults", $rr, $opt);
	$s->_call_callback($cbs,"pre_C", $rr, $opt);
	$rr->{rec} = $source->resultset->create($rr->{rec_updates});
	$s->_call_callback($cbs,"post_C", $rr, $opt);
	my $func = 'op_' . ($rr->{op} || 'r');
	delete $rr->{op};
	$s->$func($rr,$cbs,$opt);
}

sub op_u {
	my $s		= shift;
	my $rr		= shift;
	my $cbs		= shift;
	my $opt		= shift;


	my $puzzle	= $s->puzzle;
	my $rec		= $rr->{rec};
	my @columns = $rec->result_source->columns;
	my %rec_updates;
	my $args	= $puzzle->post->args;
	foreach (@columns) {
		if (exists $args->{$_}) {
			$rec_updates{$_} = $args->{$_};
		}
	}

	$rr->{rec_updates} = \%rec_updates;

	$s->_call_callback($cbs,"defaults", $rr, $opt);
	$s->_call_callback($cbs,"pre_u", $rr, $opt);
	$rr->{rec} = $rec->update($rr->{rec_updates});
	$s->_call_callback($cbs,"post_u", $rr, $opt);
	my $func = 'op_' . ($rr->{op} || 'r');
	delete $rr->{op};
	$s->$func($rr,$cbs,$opt);
}

sub op_d {
	my $s		= shift;
	my $rr		= shift;
	my $cbs		= shift;
	my $opt		= shift;

	$s->_call_callback($cbs,"pre_d", $rr, $opt);
	$s->_call_callback($cbs,"post_d", $rr, $opt);
	$s->puzzle->args->op($rr->{op} || 'D');
}

sub op_D {
	my $s		= shift;
	my $rr		= shift;
	my $cbs		= shift;
	my $opt		= shift;

	my $puzzle	= $s->puzzle;
	my $rec		= $rr->{rec};
	$s->_call_callback($cbs,"pre_D", $rr, $opt);
	$rec->delete;
	undef $rr->{rec};
	$s->_call_callback($cbs,"post_D", $rr, $opt);
	$puzzle->post->clear;
	my $func = 'op_' . ($rr->{op} || 'c');
	delete $rr->{op};
	$s->$func($rr,$cbs,$opt);
}

sub op_s {
	my $s		= shift;
	my $rr		= shift;
	my $cbs		= shift;
	my $opt		= shift;

	$s->_call_callback($cbs,"defaults", $rr, $opt);
	$s->_call_callback($cbs,"pre_s", $rr, $opt);
	$s->puzzle->args->set($rr->{rec},$rr->{rel});
	$s->_call_callback($cbs,"post_s", $rr, $opt);
	$s->puzzle->args->op($rr->{op} || 'S');
}

sub op_S {
	my $s		= shift;
	my $rr		= shift;
	my $cbs		= shift;
	my $opt		= shift;

	$s->_call_callback($cbs,"defaults", $rr, $opt);
	$s->_call_callback($cbs,"pre_S", $rr, $opt);
	$s->puzzle->args->set($rr->{rec},$rr->{rel});
	$s->_call_callback($cbs,"post_S", $rr, $opt);
	$s->puzzle->args->op($rr->{op} || 'r');
}

sub op_f {
	my $s		= shift;
	my $rr		= shift;
	my $cbs		= shift;
	my $opt		= shift;

	$s->_call_callback($cbs,"defaults", $rr, $opt);
	$s->_call_callback($cbs,"pre_f", $rr, $opt);
	$s->puzzle->args->set($rr->{rec},$rr->{rel});
	$s->_call_callback($cbs,"post_f", $rr, $opt);
	$s->puzzle->args->op($rr->{op} || 'F');
}

sub _call_callback {
	my $s		= shift;
	my $cbs		= shift;
	my $cbName	= shift;
	my $rr		= shift;
	my $opt		= shift;

	if (exists $cbs->{$cbName} && defined $cbs->{$cbName}) {
		return $cbs->{$cbName}->($s,$rr,$opt);
	}

	return undef;
}


sub puzzle {
	my $s	= shift;
	return $s->container;
}


1;
