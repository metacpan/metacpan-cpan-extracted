package SQL::Loader;

use strict;
use warnings;

use LWP::Simple;
use DBI;

our $VERSION = '0.02';

=head1 NAME

SQL::Loader

=head1 SYNOPSIS

use base qw( SQL::Loader );

=head1 DESCRIPTION

Base class for L<SQL::Loader::MySQL>

=head1 SEE ALSO

L<SQL::Loader::MySQL>

=head1 METHODS

=cut

=head2 new

constructor

=cut
sub new {
	my $class = shift;
	if ( $class eq 'SQL::Loader' ) {
		die __PACKAGE__ . "cannot be called directly\n";
	}
	my $self = {};
	bless $self, $class;
	$self->_init(@_);
	return $self;
}

=head2 run

main app loop

=cut
sub run {
	my $self = shift;

	my $tcounter = 0;
	my $tcounted = 0;
	my $purpose = 0;
	my $table = 0;
	my $content;
	my $title = undef;

	# sql
	my $titles = [];
	my $col_vals = [];
	my $table_col = [];

	my $url = $self->{url};
	my $print_http_headers = $self->print_http_headers();

	# server response test only and quit
	return $self->_print_http_headers if $print_http_headers;

	$content = get($url);
	die "couldn't get URL $url: $!\n" if !$content;
	
	my @arr = split(/\n+/, $content);

	# start loop - find each table
	LINE: foreach my $line (@arr) {
		chomp($line);

		# find title
		if (!defined($title)) {
			$title = $self->_set_table_title($line, $titles, $title);
			next LINE;
		}

		# find the 'purpose' keyword and start of new table, indicating new, valid table
		($purpose, $table) = $self->_set_purpose_and_table($line, $purpose, $table);
		next LINE unless ($purpose && $table);

		# we've found title, purpose and hit start of a table for db
		if ($purpose && $table) {
			# get all the column names
			$self->_work_out_table_cols($line, $col_vals, $table_col);
			$col_vals = [];

 			if ($line =~ /^<\/table/) {
 				# end of table - create this one
 				$self->create_table($titles, $table_col);
				$purpose = 0;
				$table = 0;
				$title = undef;
				$titles = [];
				$table_col = [];
				next LINE;
 			}
		}
	}
	$self->dbh->disconnect();
}

=head2 create_table

create the sql tables. must be overridden in subclass.

=cut
sub create_table {
	my $self = shift;
	die __PACKAGE__ . "->create_table is abstract\n";
}

=head2 _work_out_table_cols

define the columns of the given table

=cut
sub _work_out_table_cols {
	my $self = shift;
	my $line = shift;
	my $col_vals = shift;
	my $table_col = shift;

	if ($line =~ /^<tr><td/) {
		# print "found new col..\n";
		my @row_items = split(/<\/td>/, $line);
		ROW: for (my $i=0;$i<$#row_items;$i++) {
			if ($row_items[$i] =~ /">\s*([\w -\\\/]+)\s*$/) {
				my $rname = $1;
				$rname = $self->_clean($rname);
				push @{$col_vals}, $rname; # sql
			}
		}
		push @{$table_col}, $col_vals;
	}
	return $table_col;
}

=head2 _set_purpose_and_table

helper sub to determine if a table is valid and should be created. a table is considered valid if it has
a 'Purpose' defined on the twiki page.

This sub gets called repeatedly once a purpose has been found until a <table> line is found,
indicating start of a db table.

=cut
sub _set_purpose_and_table {
	my $self = shift;
	my $line = shift;
	my $purpose = shift;
	my $table = shift;

	if ($line =~ /Purpose\s*<\/h3>/) {
		# <h3> line indicates purpose
		$purpose = 1;
	}
	if (($purpose) && ($line =~ /<table/)) {
		$table = 1;
	}

	return ($purpose, $table);
}

=head2 _set_table_title

helper sub to extract the name that should be used for the table currently being created.

=cut
sub _set_table_title {
	my $self = shift;
	my $line = shift;
	my $titles = shift;
	my $title = shift;

	if ($line =~ /(\w+)\s*<\/h2>$/) {
		# <h2> line is considered title of table
		$title = $1;
		$self->_clean($title);
		push @{$titles}, $title;
	}

	return $title;
}

=head2 _clean

helper sub to clean leading, tailing and excessive whitespace from a string.

=cut
sub _clean {
	my $self = shift;
	my $s = shift;
	$s =~ s/^\s+//;
	$s =~ s/\s+$//;
	$s =~ s/\s+/ /;
	$s;
}

=head2 _print_http_headers

print headers option, invoked if the --print-http-headers switch is used. Use to test server response for example. Does not rebuild database.

=cut
sub _print_http_headers {
	my $self = shift;
	my $url = $self->{url};

	my @head = head($url);
	if (!@head) {
		die "couldn't get URL $url: $!\n";
	}
	else {
		foreach (@head) {
			next if !defined($_);
			chomp();
			next if /^\s*$/;
			print $_, "\n";
		}
	}
}

=head2 _init

initialize class

=cut
sub _init {
	my $self = shift;
	my (%args) = @_;

	$self->print_http_headers( $args{print_http_headers} );
	$self->url( $args{url} );
	die "no URL specified\n" if ( !$self->url() );
	if ( $self->print_http_headers() ) {
		$self->initialized( 1 );
		return $self;
	}
	
	$self->dbname( $args{dbname} );
	die "no dbname specified\n" if ( !$self->dbname );
	$self->dbuser( $args{dbuser} );
	die "no dbuser specified\n" if ( !$self->dbuser );
	$self->dbpass( $args{dbpass} );
	die "no dbpass specified\n" if ( !$self->dbpass );
	$self->quiet( $args{quiet} );

	$self->initialized( 1 );

	return $self;	
}

=head2 initialized

get/set initialized param

=cut
sub initialized {
	my ( $self, $initialized ) = @_;
	if ( $initialized ) {
		$self->{initialized} = $initialized;
	}
	return $self->{initialized};
}

=head2 print_http_headers

get/set print_http_headers param

=cut
sub print_http_headers {
	my ( $self, $print_http_headers ) = @_;
	if ( $print_http_headers ) {
		$self->{print_http_headers} = $print_http_headers;
	}
	return $self->{print_http_headers};
}

=head2 url

get/set url to be scraped

=cut
sub url {
	my ( $self, $url ) = @_;
	if ( $url ) {
		$self->{url} = $url;
	}
	return $self->{url};
}

=head2 dbname

get/set dbname

=cut
sub dbname {
	my ( $self, $dbname ) = @_;
	if ( $dbname ) {
		$self->{dbname} = $dbname;
	}
	return $self->{dbname};
}

=head2 dbuser

get/set dbuser

=cut
sub dbuser {
	my ( $self, $dbuser ) = @_;
	if ( $dbuser ) {
		$self->{dbuser} = $dbuser;
	}
	return $self->{dbuser};
}

=head2 dbpass

get/set dbpass

=cut
sub dbpass {
	my ( $self, $dbpass ) = @_;
	if ( $dbpass ) {
		$self->{dbpass} = $dbpass;
	}
	return $self->{dbpass};
}

=head2 dbh

get/set database handle

=cut
sub dbh {
	my $self = shift;
	if ( !defined( $self->{dbh} ) ) {
		my $dbh = DBI->connect( $self->connect_string(),
														{ RaiseError	=> 1,
															AutoCommit	=> 0,
															ChopBlanks	=> 1
														}
		) || die DBI->errstr;
		$self->{dbh} = $dbh;
	}
	return $self->{dbh};
}

=head2 quiet

get/set quiet param

=cut
sub quiet {
	my ( $self, $quiet ) = @_;
	if ( $quiet ) {
		$self->{quiet} = $quiet;
	}
	return $self->{quiet};
}

=head2 connect_string

return dbh connect string. must be overridden in subclass.

=cut
sub connect_string {
	my $self = shift;
	die __PACKAGE__ . "->connect_string() is abstract\n";
}

1;

__END__

=head1 AUTHOR

Ben Hare for www.strategicdata.com.au

benhare@gmail.com

=head1 COPYRIGHT

(c) Copyright Strategic Data Pty. Ltd.

This module is free software. You can redistribute it or modify it under the same terms as Perl itself.

=cut

