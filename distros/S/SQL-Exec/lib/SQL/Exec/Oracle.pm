package SQL::Exec::Oracle;
use strict;
use warnings;
use Exporter 'import';
use SQL::Exec '/.*/', '!connect', '!table_exists';

our @ISA = ('SQL::Exec');

our @EXPORT_OK = ('test_driver', @SQL::Exec::EXPORT_OK);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub test_driver {
	return SQL::Exec::test_driver('Oracle');
}

sub build_connect_args {
	my ($class, $server, $instance, $user, $pwd, @opt) = @_;
	
	my $port = 1521;
	if ($server =~ m/^(.*):(.*)$/) {
		$server = $1;
		$port = $2;
	}

	return ("dbi:Oracle:host=${server};sid=${instance};port=${port}", $user, $pwd, @opt);
}


sub get_default_connect_option {
	my $c = shift;
	return $c->SUPER::get_default_connect_option();
}

sub connect {
	my $c = &SQL::Exec::check_options;

	if (!test_driver()) {
		$c->error("You must install the DBD::Oracle Perl module");
		return;
	}

	if (not $c->isa(__PACKAGE__)) {
		bless $c, __PACKAGE__;
	}

	return $c->__connect($c->build_connect_args(@_));
}

sub table_exists {
	my $c = &check_options;
	my ($table) = @_;

	$table = $c->__replace($table);

	return $c->__count_lines("select * from user_tables where table_name = '$table'") == 1;
}

=for comment

select 'drop function ' || object_name from user_procedures where object_type = 'FUNCTION'
union all
select 'drop procedure ' || object_name from user_procedures where object_type = 'PROCEDURE'
union all
select 'drop sequence ' || sequence_name from user_sequences
union all
select 'drop view ' || view_name from user_views
union all
select 'drop table ' || table_name || ' cascade constraints' from user_tables
union all
select 'drop package ' || object_name from user_procedures where object_type = 'PACKAGE'

=cut

1;


=encoding utf-8

=head1 NAME

SQL::Exec::Oracle - Specific support for the DBD::Oracle DBI driver in SQL::Exec

=head1 SYNOPSIS

  use SQL::Exec::Oracle;
  
  SQL::Exec::Oracle::connect($server, $instance, $user, $password);

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-puresql@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-PureSQL>.

=head1 SEE ALSO

L<SQL::Exec>

=head1 AUTHOR

Mathias Kende (mathias@cpan.org)

=head1 COPYRIGHT & LICENSE

Copyright 2013 © Mathias Kende.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


