package SQL::Smart;

use 5.006;
#use strict;
use warnings FATAL => 'all';
use DBI;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw / for_dbh sql /;
our $dbh_cache;

=head1 NAME

SQL::Smart - A new smart way to do SQL query

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.06';


=head1 SYNOPSIS

    use SQL::Smart;
	use DBI;	

	for_dbh(DBI->connect('DBI:mysql:dbname;host=hostname', 'username', 'password'));

    $name = sql('select name from users where id=?', $id); # $name = 'Tom'
    @names = sql('select name from users'); # @names = ('Tom', 'Jerry'...)
	$rh_user = sql('select * from users where id=?', $id); # $rh_user = {id=>1, name=>'Tom'}
	@users = sql('select * from users'); # @users = ({id=>1, name=>'Tom'}, {id=>2, name=>'Jerry'}...)
	$last_insert_id = sql('insert into users (name) values (?)', 'Mary');
	sql('update users set name=? where id=?', $id);
	sql('delete from users where id=?', $id);

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 for_dbh

=cut

sub get_dbh{
	unless($dbh_cache){
		die "Need to call for_dbh first!";
	}
	return $dbh_cache;
}

sub for_dbh {
	$dbh_cache = shift;
}

=head2 sql

=cut

sub flatten_result{
	my @input = @_;
	my $has_more_than_one_key = (scalar(keys %{$input[0]}) > 1);
	my @output = map {
		$has_more_than_one_key ? $_ : ((values %$_)[0])
	} @input;
	if(wantarray){
		return @output;
	}else{
		return $output[0];
	}
}

sub sql{
	my $sql_statement = shift;
	my @binds = @_;
	my $dbh = get_dbh();
	unless($sql_statement =~ /^\s*(?:select|describe)/i){
		my $sth = $dbh->prepare($sql_statement);
		$sth->execute(@binds);
		#$dbh->commit();
		if($sql_statement =~ /^\s*insert\b/i){
			return $dbh->last_insert_id(undef, undef, undef, undef);
		}
	}else{
		my $sth = $dbh->prepare($sql_statement);
		$sth->execute(@binds);
		my $ra_result = $sth->fetchall_arrayref({});
		if(wantarray){
			return flatten_result(@$ra_result);
		}else{
			return undef if scalar(@$ra_result) == 0;
			my $one_result = flatten_result($ra_result->[0]);
			return $one_result;
		}
	}
}

=head1 AUTHOR

Priezt, C<< <vegetabird at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sql-smart at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SQL-Smart>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SQL::Smart


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SQL-Smart>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SQL-Smart>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SQL-Smart>

=item * Search CPAN

L<http://search.cpan.org/dist/SQL-Smart/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Priezt.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of SQL::Smart
