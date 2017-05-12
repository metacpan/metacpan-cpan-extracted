
=head1 NAME

NetSDS::Util::FileImport - import table structure from file

=head1 SYNOPSIS

use NetSDS::Util::FileImport

=head1 DESCRIPTION

=cut

package NetSDS::Util::FileImport;

use 5.8.0;
use strict;
use warnings;

use File::MMagic;         # Determine MIME type of file
use Spreadsheet::Read;    # Parse spreadsheet files

use base 'Exporter';

use version; our $VERSION = "1.044";

our @EXPORT = qw(
  import_table
);

# TODO
use constant PREVIEW_LIMIT => 5;    # Number of records to process for previews

=head1 CLASS API

=over

=item B<import_table()> - import table data from file

takes $content of a file, $pre_parse (true or false it means: return all table or only 5 first rows

params it could be
	patterns => { qr#name#i   => { qr#last#i  => 'last_name', qr#first#i => 'first_name' } }
	separator => could be ,;\t:
	fields => [ email last_name ]
	substitute => { E-mail => email, Last Name => last_name, .. }

Depends of a params parse would be different

Returns a structure like this 
	[ { last_name => undef, first_name => yana, ... }, { last_name => kornienko, first_name => test, ... } .. ]

=back

=cut 

sub import_table($;$$) {
	my ( $file_name, $params, $pre_parse ) = @_;
	my ( $separator, $data, $rows ) = ( $params->{'separator'}, [], [] );
	return "Can't find file [$file_name]." unless -e $file_name;
	# [ { 'last_name' => 'my name', 'First Name' => 'my first name' ... }, {'last_name' => undef, 'First Name' => 'test_name'  ... } ... ]

	my @title = ();
	if ( File::MMagic->new->checktype_filename($file_name) eq 'text/plain' ) {

		open my $FILE, '<', $file_name or return $!;
		my @lines = <$FILE>;
		chomp for @lines;
		close $FILE;

		$lines[0] =~ s/^["']|["']$//;
		$separator ||= ( $lines[0] =~ m![\w\s"]+?([,;:\t])! )[0];
		return "Parse error while parsing csv file" unless $separator;

		$lines[0] =~ s/["']$//;
		@title = split /["']{0,1}$separator["']{0,1}/, $lines[0];

		my @rows = ( ( $pre_parse and @lines > PREVIEW_LIMIT ) ? @lines[ 1 .. PREVIEW_LIMIT + 1 ] : @lines );
		$rows = [ map { [ split /["']*$separator["']*/, $_ ] } grep { ( $_ and $_ =~ s/^['"]// ) or $_ } @rows ];

	} else {

		my $struct = ReadData($file_name);
		return "Parse error while parsing data xls file" unless $struct;

		my @content = @{ $struct->[1]{'cell'} };
		@title = map { $content[$_]->[1] } 1 .. $#content;
		my $count = ( ( $pre_parse and @{ $content[1] } > ( PREVIEW_LIMIT + 2 ) ) ? PREVIEW_LIMIT : scalar @{ $content[1] } - 1 );

		for my $i ( 2 .. $count ) {
			push @$rows, [ map { $content[$_]->[$i] } 1 .. @title ];
		}
	}

	my @original_fields = @title;
	if ( $params->{'patterns'} ) {
		_order_data_by_patterns( \@title, $params->{'patterns'} );
	} elsif ( $params->{'fields'} ) {    #return only specific fields that has the same name
		_order_data_by_fields( $data, \@title, $params->{'fields'}, $rows );
		return $data;
	} elsif ( $params->{'substitute'} ) {    #return only specific fields the names of which has been changed
		_order_data_with_substitute( $data, \@title, $params->{'substitute'}, $rows );
		return $data;
	}

	for my $row (@$rows) {
		push @$data, { map { ( $title[$_] => $row->[$_] ) } 0 .. $#title };
	}

	return wantarray ? ( $data, \@original_fields ) : $data;
} ## end sub import_table($;$$)

sub _order_data_by_patterns($$) {
	my ( $title, $patterns ) = @_;

	for ( my $i = 0 ; $title->[$i] ; $i++ ) {    #TODO multi
		for my $pattern ( keys %$patterns ) {
			if ( $title->[$i] =~ $pattern ) {
				if ( ref $patterns->{$pattern} ) {
					for my $subpattern ( keys %{ $patterns->{$pattern} } ) {
						if ( $title->[$i] =~ $subpattern ) {
							$title->[$i] = $patterns->{$pattern}{$subpattern};
							last;
						}
					}
				} else {
					$title->[$i] = $patterns->{$pattern};
				}
			}
		}
	}
} ## end sub _order_data_by_patterns($$)

sub _order_data_by_fields($$$$) {
	my ( $data, $title, $fields, $rows ) = @_;
	my @res = ();

	for my $field (@$fields) {
		for ( my $i = 0 ; $title->[$i] ; $i++ ) {
			if ( $title->[$i] eq $field ) {
				push @res, $i;
				last;
			}
		}
	}

	for my $row (@$rows) {
		push @$data, { map { ( $title->[$_] => $row->[$_] ) } @res };
	}
}

sub _order_data_with_substitute($$$$) {
	my ( $data, $title, $substitute, $rows ) = @_;
	my $pattern = join '|', map { quotemeta $_ } keys %$substitute;

	$_ =~ s/^($pattern)$/$substitute->{$1}/ for @$title;

	_order_data_by_fields( $data, $title, [ values %$substitute ], $rows );
}

1;
