package Sql::Textify;

use 5.006;
use strict;
use warnings;
use Carp qw(croak);
use DBI;
use HTML::Entities;

=head1 NAME

Sql::Textify - Run SQL queries and get the result in text format (markdown, html)

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';
$VERSION = eval $VERSION;
our @EXPORT_OK = qw(textify);

=head1 SYNOPSIS

    use Sql::Textify;
    my $t = Sql::Textify->new;
    my $text = $t->textify( $sql );

    use Sql::Textify;
    my $t = Sql::Textify->new(
        conn => 'dbi:connection:string',
        username => 'username',
	    password => 'password',
        format => 'markdown',
    );
    my $text = $t->textify( $sql );

=head1 SYNTAX

This module executes SQL queries and produces text output (markdown, html).
Connection details, username and password can be specified in a C-style multiline
comment inside the SQL query:

    /*
        conn="dbi:SQLite:dbname=test.sqlite3"
        username="myusername"
        password="mypassword"
    */
    select * fom gardens;

or they can be specified using the constructor:

    my $t = new Sql::Textify(
        conn => 'dbi:SQLite:dbname=test.sqlite3',
        username => 'myusername',
        password => 'mypassword'
    );
    my $text = $t->textify('select * from gardens');

multiple queries can be separated by C<< ; >> and also insert/update/create/etc. queries are
supported. If the query doesn't return any row the string C<< 0 rows >> will be returned.

=head1 OPTIONS

Sql::Textify supports a number of options to its processor which control
the behaviour of the output document.

The options for the processor are:

=over

=item format

markdown (default), html

=item layout

table (default), record

=item conn

Specify the DBI connection string.

=item username

Specify the database username.

=item password

Specify the database password.

=item maxwidth

Set a maximum width for the columns when in markdown format mode. If any column contains
a string longer than maxwidth it will be cropped.

=back

=head1 METHODS

=head2 new

Sql::Textify constructor, see OPTIONS sections for more information.

=cut

sub new {
	my ($class, %p) = @_;
	my $self = {};

	$self->{format} = sanitize_string({ value => $p{format}, regexp => 'html|markdown', default => 'markdown' });
	$self->{layout} = sanitize_string({ value => $p{layout}, regexp => 'table|record',  default => 'table' });

	$self->{username} = $p{username};
	$self->{password} = $p{password};
	$self->{conn} = $p{conn};

	bless $self, ref($class) || $class;
	return $self;
}

=head2 textify

The main function as far as the outside world is concerned. See the SYNTAX
for details on use.

=cut

sub textify {
	my ( $self, $sql ) = @_;

	$self->_GetParametersFromSql($sql);
	$self->{dbh} = DBI->connect($self->{conn}, $self->{username}, $self->{password}) || die $DBI::errstr;

	return $self->_Textify($sql);
}

sub _GetParametersFromSql {
	my ($self, $sql) = @_;

	# FIXME: values from SQL string will take precedence
	# FIXME: the following regexps will usually work on most cases, but are over-simplified

	if ($sql =~ /conn=\"([^\""]*)\"\s/)     { $self->{conn} = $1;     }
	if ($sql =~ /username=\"([^\""]*)\"\s/) { $self->{username} = $1; }
	if ($sql =~ /password=\"([^\""]*)\"\s/) { $self->{password} = $1; }
	if ($sql =~ /maxwidth=\"([^\""]*)\"\s/) { $self->{maxwidth} = $1; }
	if ($sql =~ /format=\"([^\""]*)\"\s/)   { $self->{format} = $1;   }
	if ($sql =~ /layout=\"([^\""]*)\"\s/)   { $self->{layout} = $1;   }
}

sub _Do_Sql {
	my ($self, $sql_query) = @_;
	my %r;

	my $qry = $self->{dbh}->prepare($sql_query)	|| die "````\n", $sql_query, "\n````\n\n", ">", $DBI::errstr, "\n";
	$qry->execute()	|| die "````\n", $sql_query, "\n````\n\n", ">", $DBI::errstr;
	my $rows = $qry->fetchall_arrayref();
	$qry->finish();

	$r{fields} = $qry->{NAME};
	$r{rows} = $rows;

	return wantarray ? %r : \%r;
}

sub _Textify {
	my ($self, $sql) = @_;

	my $result;

	# strip C-style comments from source query
	# regexp from http://learn.perl.org/faq/perlfaq6.html#How-do-I-use-a-regular-expression-to-strip-C-style-comments-from-a-file

	$sql =~ s#/\*[^*]*\*+([^/*][^*]*\*+)*/|("(\\.|[^"\\])*"|'(\\.|[^'\\])*'|.[^/"'\\]*)#defined $2 ? $2 : ""#gse;

	foreach my $sql_query (split /;\s*/, $sql) {
		my $records = $self->_Do_Sql($sql_query);
		$result .= $self->_Do_Format($records);
 	}

	return $result;
}

sub _Do_Format {
	my ($self, $records) = @_;

	my %m = (
		"markdown" => {
			"table"  => sub { _Do_Sql_Markdown(@_) },
			"record" => sub { _Do_Sql_Markdown_Record(@_) }
		},
		"html" => {
			"table"  => sub { _Do_Sql_Html(@_) },
			"record" => sub { _Do_Sql_Html_Record(@_) }
		},
	);

	if ($m{ $self->{format} }->{ $self->{layout} }) {
		return $m{ $self->{format} }->{ $self->{layout} }->($self, $records);
	} else {
		die("Wrong format/layout (".$self->{format}."/".$self->{layout});
	}
}

sub _Do_Sql_Markdown {
	my ($self, $records) = @_;

	my $max_width = $self->{maxwidth};
	my $max_format = '';

	my $result = '';

	if (($max_width) && ($max_width> 0))
	{
		$max_format = ".$max_width";
	}

	my @width = map { min(length(quote_markdown($_)), $max_width) } @{$records->{fields}};

	if (scalar @{ $records->{rows} }>0) {

		foreach my $row ( @{ $records->{rows} }) {
			# <- for each row, and for each column -> calculate the maximum width
			foreach my $i (0 .. (scalar @{ $row }-1)) {
				$width[$i] = max($width[$i], length(quote_markdown($row->[$i])));
			}
		}
		# then "strip" the width to the $max_width
		@width = map { min($_, $max_width) } @width;

		# create format string
		my $f = join(' | ', map { "%-".$_.$max_format."s"} @width) . "\n";

		# print header
		$result .= "\n" . sprintf( $f, map { quote_markdown($_) } @{$records->{fields}} );

		# print sub header -|-
		$result .= join("-|-", map { '-'x$_ } @width ) . "\n";

		# print rows
		foreach my $row (@{ $records->{rows} }) {
			$result .= sprintf( $f, map { quote_markdown($_) } @{$row} );
		}
	} else {
		$result .= "0 rows\n";
	}

	return $result;
}

sub _Do_Sql_Markdown_Record {
	my ($self, $records) = @_;

	my $max_width = $self->{maxwidth};

	my $max_format = '';
	my $nr = 1;

	my $result = '';

	if (($max_width) && ($max_width > 0))
	{
		$max_format = ".$max_width";
	}

	# rows
	foreach my $row (@{ $records->{rows} }) {
		$result .= "# Record $nr\n\n";

		my @width = (min(length('Column'),$max_width),min(length('Value'),$max_width));

		foreach my $i (0 .. (scalar @{ $row }-1)) {
			$width[0]=max($width[0], length(quote_markdown($records->{fields}[$i])));
			$width[1]=max($width[1], length(quote_markdown($row->[$i])),$max_width);
		}
		$width[0] = min($width[0], $max_width);
		$width[1] = min($width[1], $max_width);

		# %-x.ys    %s string, - left-justify, x minimum widht, y maximum width
		my $f = join(' | ', map { "%-".$_.$max_format."s"} @width) . "\n";

		$result .= sprintf $f, ("Column", "Value");

		$result .= '-'x$width[0] . '-|-' . '-'x$width[1] . "\n";

		foreach my $i (0 .. (scalar @{ $row }-1)) {
				$result .= sprintf $f, (quote_markdown($records->{fields}[$i]), quote_markdown($row->[$i]));
		}

		$result .= "\n";
		$nr++;
	}

	if ($nr == 1) { # no rows returned, empty rowset or create/update query
		$result .= "0 rows\n";
	}

	return $result;
}

sub _Do_Sql_Html {
	my ($self, $records) = @_;
	my $result;

	if (scalar @{ $records->{rows} }>0) {

		$result  = "<table>\n";
		$result .= "<thead>\n";

		$result .= join("\n", map { '  <th>' . encode_entities($_) . '</th>'} @{$records->{fields}}) . "\n";

		$result .= "</thead>\n";
		$result .= "<tbody>\n";

		foreach my $row (@{ $records->{rows} }) {
			$result .= "<tr>\n";
			$result .= join("\n", map { '  <td>' . encode_entities($_) . '</td>'} @{ $row }) . "\n";
			$result .= "</tr>\n";
		}

		$result .= "</tbody>\n";
		$result .= "</table>\n\n";
	} else {
		$result .= "<p>\n0 rows</p>\n\n";
	}

	return $result;
}

sub _Do_Sql_Html_Record {
	my ($self, $records) = @_;
	my $result;
	my $nr = 1;

	if (scalar @{ $records->{rows} }>0) {
		foreach my $row (@{ $records->{rows} }) {
			$result .= "<h1>Record $nr</h1>\n\n";

			$result .= "<table>\n";

			foreach my $i (0 .. (scalar @{ $row }-1)) {
				$result .= "<tr>\n";
				$result .= "  <th>" . encode_entities($records->{fields}[$i]) . "</th>\n";
				$result .= "  <td>" . encode_entities($row->[$i]) . "</td>\n";
				$result .= "</tr>\n";
			}

			$result .= "</table>\n\n";

			$nr++;
		}
	} else {
		$result .= "<p>\n0 rows</p>\n\n";
	}

	return $result;
}

# internal functions

sub sanitize_string {
    my $p = shift;

	return $p->{default} unless $p->{value};
	return $p->{value}   if $p->{value} =~ /^$p->{regexp}$/;
	croak("Invalid value *$p->{value}* provided.");
}

sub quote_markdown {
	# there's not a standard way to quote markdown
	my $s = shift;

	if (defined $s) {
		# quote |
		$s =~ s/\|/\\\|/g;

		# replace non-printable characters with space
		$s =~ s/[^[:print:]]/ /g;
	} else {
		$s = '';
	}
	return $s;
}

sub max ($$) {
	# if second parameter is defined then return max(p1, p2) otherwise return p1
	if ($_[1]) {
		$_[$_[0] < $_[1]];
	} else {
		$_[0];
	}
}

sub min ($$) {
	# if second parameter is defined then return min(p1, p2) otherwise return p1
	if ($_[1]) {
		$_[$_[0] > $_[1]];
	} else {
		$_[0];
	}
}

=head1 AUTHOR

Federico, Thiella, C<< <fthiella at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sql-textify at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sql-Textify>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sql::Textify


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sql-Textify>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sql-Textify>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sql-Textify>

=item * Search CPAN

L<http://search.cpan.org/dist/Sql-Textify/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Federico, Thiella.

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

1; # End of Sql::Textify
