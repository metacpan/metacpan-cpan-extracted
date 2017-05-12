package SQL::Exec::Statement;
use strict;
use warnings;
use Scalar::Util 'reftype', 'openhandle';

use parent 'SQL::Exec';

=encoding utf-8

=head1 NAME

SQL::Exec::Statement - Prepared statements support for SQL::Exec

=head1 SEE ALSO

For the documentation of this distribution please check the L<SQL::Exec> module.

=head1 COPYRIGHT & LICENSE

Copyright 2013 © Mathias Kende.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

our @CARP_NOT = ('DBIx::Connector');

# Return a reference of a new copy of the empty_handle hash, used by the
# constructors of the class.
sub get_empty {
	my $new_empty = SQL::Exec->get_empty();
	delete $new_empty->{auto_handle};
	return $new_empty;
}

# ->new($parent, {options})
# appeler seulement depuis Exec::prepare
sub new {
	my ($class) = shift @_;
	my $parent = &SQL::Exec::just_get_handle;

	my $c = get_empty();
	$c->{parent} = $parent;
	bless $c, $class;
	$c->set_options(%{$parent->{options}});
	$c->{db_con} = $parent->{db_con};
	$c->{is_connected} = $parent->{is_connected};
	$c->{is_statement} = 1;
	# on ne copie pas les restore options exprès, ce qui est en vigueur quand
	# on crée l'objet le reste.
	# TODO: faire un cas de test pour ça.

	$c->check_conn() or return;
	
	my $req = $c->get_one_query(shift @_);

	my $proc = sub {
			if (!$c->low_level_prepare($req)) {
				die "EINT\n";
			}
		};

	if ($c->{options}{auto_transaction}) {
		eval { $c->{db_con}->txn($proc) };
	} else {
		eval { $proc->() };
	}
	if ($@ =~ m/^EINT$/) {
		return;
	} elsif ($@) {
		die $@;
	} else {
		return $c;
	}
}

sub DESTROY {
	my ($c) = shift;
	$c->low_level_finish() if defined $c->{last_req} && !$c->{req_over};
	# we need to override the DESTROY function from SQL::Exec which disconnect
	# the library...
}

################################################################################
################################################################################
##                                                                            ##
##                            INTERNAL METHODS                                ##
##                                                                            ##
################################################################################
################################################################################


# The function below are responsible for the effective works of the library.
# Pretty much self-descriptive.

# Prepare a statement, return false on error (if die_on_error is false)
# only one statement may be prepared at a time in a database handle.
sub low_level_prepare {
	my ($c, $req_str) = @_;
	
	$req_str = $c->query($req_str) or return $c->error('No query to prepare');

	my $s = sub { 
			my $req = $_->prepare($req_str);
			if (!$req) {
				die $c->format_dbi_error("Cannot prepare the statement");
			} else {
				return $req;
			}
		};
	my $req = eval { $c->{db_con}->run($s) };
	if ($@) {
		return $c->error($@);
	}
	$c->{last_req} = $req;
	$c->{req_over} = 0;
	return 1;
}

sub low_level_bind {
	my $c = shift;

	if ($c->{last_req}->{NUM_OF_PARAMS} != @_) {
		$c->error("Invalid number of parameter (%d), expected %d", scalar(@_), $c->{last_req}->{NUM_OF_PARAMS});
	}

	my $i = 0;
	for (@_) {
		#TODO: gérer les différents type de paramètres
		if (not $c->{last_req}->bind_param(++$i, $_)) {
			$c->dbi_error("Cannot bind the parameters");
			return;
		}
	}

	return 1;
}

# execute the prepared statement of the handle. Return undef on failure (0 may
# be returned on success).
sub low_level_execute {
	my ($c) = @_;
	#confess "No statement currently prepared" if $c->{req_over};

	my $v = $c->{last_req}->execute();
	if (!$v) {
		$c->dbi_error("Cannot execute the statement");
		return;
	}
	
	return $v;
}


# Return one raw of result. The same array ref is returned for each call so
# its content must be copied somewhere before the next call.
sub low_level_fetchrow_arrayref {
	my ($c) = @_;
	#confess "No statement currently prepared" if $c->{req_over};

	my $row = $c->{last_req}->fetchrow_arrayref();
	if (!$row && $c->{last_req}->err) {
		$c->dbi_error("A row cannot be fetched");
		return;
	} elsif (!$row) {
		return 0;
	} else {
		return $row;
	}
}

# The returned hashref is safe: it will not be erased at the next call.
sub low_level_fetchrow_hashref {
	my ($c) = @_;
	#confess "No statement currently prepared" if $c->{req_over};

	my $row = $c->{last_req}->fetchrow_hashref('NAME_lc');
	if (!$row && $c->{last_req}->err) {
		$c->dbi_error("A row cannot be fetched");
		return;
	} elsif (!$row) {
		return 0;
	} else {
		return $row;
	}
}

sub low_level_finish {
	my ($c) = @_;
	#confess "No statement currently prepared" if $c->{req_over};

	$c->{last_req}->finish;
	$c->{req_over} = 1;

	return $1;
}

# Test whether there is one raw available in the prepared statement.
# this function destroy the raw so it should not be called if you actually
# want to read to raw.
sub test_next_row {
	my ($c) = @_;
	#confess "No statement currently prepared" if $c->{req_over};
	
	return $c->{last_req}->fetchrow_arrayref() || $c->{last_req}->err
}

sub __prepare_bind_params {
	my ($c, @p) = @_;

	my ($param, $d1);
	if (not @p or not ref $p[0]) {
		$param = [ \@p ];
		$d1 = 1;
	} elsif (reftype($p[0]) eq 'ARRAY' and (not @{$p[0]} or not ref $p[0][0])) {
		$param = [ @p ];
	} elsif (reftype($p[0]) eq 'ARRAY' and reftype($p[0][0]) eq 'ARRAY') {
		$param = $p[0];
	} else {
		$c->error('Invalid argument geometry');
	}
	
	return wantarray ? ($param, $d1) : $param
}


################################################################################
################################################################################
##                                                                            ##
##                          STANDARD QUERY FUNCTIONS                          ##
##                                                                            ##
################################################################################
################################################################################

=for comment

sub __bind_params {
	my ($c, @p) = @_;

	$c->check_conn() or return;

	if (not $c->low_level_bind(@p)) {
		$c->low_level_finish();
		return;
	}

	return $c;
}

sub bind_params {
	my $c = &SQL::Exec::check_options or return;
	return $c->__bind_params(@_);
}

=cut

sub __execute {
	my ($c, @pp) = @_;

	$c->check_conn() or return;

	my ($param, $d1) = $c->__prepare_bind_params(@pp);

	my $proc = sub {
			my $a = 0;
			
			if ($c->{last_req}->{NUM_OF_PARAMS} == 1 and $d1) {
				$param = [ map { [ $_ ] } @{$param->[0]} ];
			}

			for my $p (@{$param}) {
			# TODO: lever l'erreur strict seulement dans le mode stop_on_error
			# et s'il reste des requête à exécuter.
				if (not $c->low_level_bind(@{$p})) {
					$c->low_level_finish();
					$c->strict_error("The query has not been executed for all value due to an error") and die "EINT\n";
					die "ESTOP:$a\n" if $c->{options}{stop_on_error};
					next;
				}
				my $v = $c->low_level_execute();
				$c->low_level_finish();
				if (not defined $v) {
					$c->strict_error("The query has not been executed for all value due to an error") and die "EINT\n";
					die "ESTOP:$a\n" if $c->{options}{stop_on_error};
					next;
				}
				$a += $v;
			}
			return $a;
		};

	my $v;
	if ($c->{options}{auto_transaction}) {
		$v = eval { $c->{db_con}->txn($proc) };
	} else {
		$v = eval { $proc->() };
	}
	$c->low_level_finish() unless $c->{req_over}; # ???
	if ($@ =~ m/^EINT$/) {
		return;
	} elsif ($@ =~ m/^ESTOP:(\d+)$/) {
		return $c->{options}{auto_transaction} ? 0 : $1;
	} elsif ($@) {
		die $@;
	} else {
		return $v;
	}
}

sub execute {
	my $c = &SQL::Exec::check_options or return;
	return $c->__execute(@_);
}

sub execute_multiple { goto &execute; }

sub __query_one_value {
	my ($c, @p) = @_;

	$c->check_conn() or return;

	if (not $c->low_level_bind(@p)) {
		$c->low_level_finish();
		return;
	}

	if (not defined $c->low_level_execute())
	{ 
		$c->low_level_finish();
		return;
	}

	my $row = $c->low_level_fetchrow_arrayref();

	my $tmr = $c->test_next_row() if defined $c->{options}{strict};
	$c->low_level_finish();

	if (!$row) {
		return $c->error("Not enough data");
	} elsif ($#$row < 0) {
		return $c->error("Not enough column");
	}

	if (defined  $c->{options}{strict}) {
		$c->strict_error("Too much columns") and return if $#$row > 0;
		$c->strict_error("Too much rows") and return if $tmr;
	}
	
	return $row->[0];
}

sub query_one_value {
	my $c = &SQL::Exec::check_options or return;
	return $c->__query_one_value(@_);
}

# array ou array-ref selon le contexte (sûr, pas écraser au prochain appel).
sub __query_one_line {
	my ($c, @p) = @_;

	$c->check_conn() or return;
	
	if (not $c->low_level_bind(@p)) {
		$c->low_level_finish();
		return;
	}

	if (not defined $c->low_level_execute()) {
		$c->low_level_finish();
		return;
	}
	my $row = $c->low_level_fetchrow_arrayref();
	if (!$row) {
		$c->low_level_finish();
		return $c->error("Not enough data");
	}

	my $tmr = $c->test_next_row() if defined $c->{options}{strict};

	$c->low_level_finish();

	$c->strict_error("Too much rows") and return if $tmr;

	return wantarray ? @{$row} : [ @{$row} ];
}

sub query_one_line {
	my $c = &SQL::Exec::check_options or return;
	return $c->__query_one_line(@_);
}


# ! Si une erreur ignorée se produit dans fetchraw alors on renvoie un tableau tronqué
# Et non pas undef ou autre, donc il n'y a pas de moyen de savoir que l'appel a échoué.
# En mode stricte cependant, cette situation lève une erreur elle même (et donc on a un message
# propre si on ignore cette erreur).
# return un tableau ou un array-ref (pour économiser une recopie).
# renvoie toujours un tableau 2D même s'il n'y a qu'une colonne (pour assurer la cohérence du type),
# il faut utiliser query_one_column pour avoir une colonne.
sub __query_all_lines {
	my ($c, @p) = @_;

	$c->check_conn() or return;
	
	if (not $c->low_level_bind(@p)) {
		$c->low_level_finish();
		return;
	}

	if (not defined $c->low_level_execute()) {
		$c->low_level_finish();
		return;
	}
	
	my @rows;	
	while (my $row = $c->low_level_fetchrow_arrayref()) {
		push @rows, [ @{$row} ]; # Pour recopier la ligne sans quoi elle est écrasée au prochain appel.
	}

	$c->low_level_finish();

	if (defined $c->{options}{strict} && $c->{last_req}->err) {
		$c->strict_error("The data have been truncated due to an error") and return;
	}

	return wantarray() ? @rows : \@rows;
}

sub query_all_lines {
	my $c = &SQL::Exec::check_options or return;
	return $c->__query_all_lines(@_);
}

sub __query_one_column {
	my ($c, @p) = @_;

	$c->check_conn() or return;

	if ($c->{last_req}->{NUM_OF_FIELDS} < 1) {
		$c->low_level_finish();
		return $c->error("Not enough column");
	}

	if (defined $c->{options}{strict} && $c->{last_req}->{NUM_OF_FIELDS} > 1) {
		if ($c->strict_error("Too much columns")) {
			$c->low_level_finish();
			return;
		}
	}

	if (not $c->low_level_bind(@p)) {
		$c->low_level_finish();
		return;
	}

	if (not defined $c->low_level_execute()) {
		$c->low_level_finish();
		return;
	}
	
	my @data;

	while (my $row = $c->low_level_fetchrow_arrayref()) {
		push @data, $row->[0];
	}

	$c->low_level_finish();

	if (defined $c->{options}{strict} && $c->{last_req}->err) {
		$c->strict_error("The data have been truncated due to an error") and return;
	}
	
	return wantarray() ? @data : \@data;
}

sub query_one_column {
	my $c = &SQL::Exec::check_options or return;
	return $c->__query_one_column(@_);
}


# low_level_query_to_file(req, FH, sep, nl)
# s'il n'y a qu'un argument effectif c'est la requête
# le suivant est le FH, etc. Ils peuvent être omis en partant de la fin.
# FH peut être une chaîne, éventuellement préfixé par '>>' pour append et non pas troncation
# du fichier. Sinon c'est STDOUT. sinon une ref à un IO ou GLOB
# sep est ";" par défaut et nl est '\n' par défaut).
# renvoie le nombre de lignes lues.
# On a les même limitations en cas d'erreur que pour la fonction request_all
# Particulièrement, on renvoie toujours le  nombre de lignes lues
# même si une erreur se produit (à condition qu'on l'ignore, of course).
# Par contre on renvoie undef si on ne peut pas ouvrir le fichier demandé.
# ou pas écrire dedans.
sub __query_to_file {
	my ($c, $fh, @p) = @_;

	my ($fout, $to_close);
	if (not defined $fh) {
		$fout = \*STDOUT;
	} elsif (openhandle($fh)) {
		$fout = $fh;
	} elsif (!ref($fh)) {
		$fh =~ m{^\s*(>{1,2})?\s*(.*)$};
		if (!open $fout, ($1 // '>'), $2) { # //
			return $c->error("Cannot open file '$fh': $!");
		}
		$to_close = 1;
	} else {
		return $c->error("Don't know what to do with fh argument '$fh'");
	}
	
	$c->check_conn() or return;

	if (not $c->low_level_bind(@p)) {
		$c->low_level_finish();
		return;
	}

	if (not defined $c->low_level_execute()) {
		$c->low_level_finish();
		return;
	}

	my $count = 0;
	{
		local $, = $c->{options}{value_separator} // ';';
		local $\ = $c->{options}{line_separator} // "\n";
		while (my $row = $c->low_level_fetchrow_arrayref()) {
			if (not (print $fout @{$row})) {
				close $fout if $to_close;
				$c->low_level_finish();
				$c->error("Cannot write to file: $!");
				return $count;
			}
			$count++;
		}
		close $fout if $to_close;
	}

	$c->low_level_finish();

	if (defined $c->{options}{strict} && $c->{last_req}->err) {
		$c->strict_error("The data have been truncated due to an error") and return;
	}
	
	return $count;
}

sub query_to_file {
	my $c = &SQL::Exec::check_options or return;
	return $c->__query_to_file(@_);
}

sub __query_one_hash {
	my ($c, @p) = @_;

	$c->check_conn() or return;
	
	if (not $c->low_level_bind(@p)) {
		$c->low_level_finish();
		return;
	}

	if (not defined $c->low_level_execute()) {
		$c->low_level_finish();
		return;
	}
	my $row = $c->low_level_fetchrow_hashref();
	if (!$row) {
		$c->low_level_finish();
		return $c->error("Not enough data");
	}

	my $tmr = $c->test_next_row() if defined $c->{options}{strict};

	$c->low_level_finish();

	$c->strict_error("Too much rows") and return if $tmr;

	return wantarray ? %{$row} : $row; # no need to copy the pointer has for array (Cf DBI doc).
}

sub query_one_hash {
	my $c = &SQL::Exec::check_options or return;
	return $c->__query_one_hash(@_);
}

sub __query_all_hashes {
	my ($c, @p) = @_;

	$c->check_conn() or return;
	
	if (not $c->low_level_bind(@p)) {
		$c->low_level_finish();
		return;
	}

	if (not defined $c->low_level_execute()) {
		$c->low_level_finish();
		return;
	}
	
	my @rows;	
	while (my $row = $c->low_level_fetchrow_hashref()) {
		push @rows, $row; # pas besoin de recopier le hash.
	}

	$c->low_level_finish();

	if (defined $c->{options}{strict} && $c->{last_req}->err) {
		$c->strict_error("The data have been truncated due to an error") and return;
	}

	return wantarray() ? @rows : \@rows;
}

sub query_all_hashes {
	my $c = &SQL::Exec::check_options or return;
	return $c->__query_all_hashes(@_);
}

1;



