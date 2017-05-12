# Copyright (C) 2008 Ioannis Tambouras <ioannis@cpan.org>. All rights reserved.
# LICENSE:  GPLv3, eead licensing terms at  http://www.fsf.org .

package Pg::Loader::Columns;

use 5.010000;
use Data::Dumper;
use strict;
use warnings;
use Text::CSV;
use List::MoreUtils  qw( firstidx );
use Log::Log4perl qw( :easy );
use base 'Exporter';

our $VERSION = '0.12';

our @EXPORT = qw(
	range2list                  ranges2set	        data_fields
        init_csv                    combine             requested_cols 
);

sub range2list {
	my $_ = shift;
	given ($_) {
		when (/^(\d)\-(\d)$/o )   { return "$1..$2" }
		when (/^\d\.\.\d$/o )     { return "$_" }
		when (/^\d$/o )           { return $_}
		when (/^(.*?),(.*)$/o )   { return range2list($1). ','
                                                  .range2list($2)}
		default                   { return ''}
	}
}

sub ranges2set {
        my @unit = (0..20);
        my $tmp = range2list( shift||return) ;
        {  no warnings 'deprecated';
	  $[=0; no warnings; %_= map { ($_=>undef)} eval ' @unit['.$tmp.']' }
        [ sort keys %_ ];
}

sub init_csv {
	my ($s) = @_ ;
 	new Text::CSV       {
 	     quote_char          => $s->{quotechar}        ,
 	     escape_char         => $s->{escapechar}       , 
 	     sep_char            => $s->{field_sep}        , 
 	     eol                 => $s->{eol}              , 
 	     allow_whitespace    => $s->{skipinitialspace} , 
 	}   or   die Text::CSV->error_diag ;
}


sub combine {
	my ( $s, $csv, $d, @col )  = @_;
	return '' unless @col;
	for ( @col ) {
		 my $h    = $s->{rfm}{$_};
		 my $val  = $d->{$_};
		 exists $s->{ "udc_$_"} and $d->{$_} = $s->{ "udc_$_"};
		 next unless $h->{ref};
		 my $ref = UNIVERSAL::can( $h->{pack}, $h->{fun} );
		 $d->{$_} =  $ref->( $val );
	} 
	join $csv->{sep_char}//'',  map { $_ // '' } @{$d}{@col};
}

sub  field_nums_reqe {
	my ( $s, $max )  = @_;
	return 0..$max  unless $s->{only_cols} ;
	return 0..$max  if  $s->{only_cols} =~ /^\s*[*]\s*$/o ;
	my $range_str = $s->{only_cols} ;
        ( ref $range_str eq 'ARRAY')  and $range_str = join ',', @$range_str;
 	map   { --$_ ; 
		$_>$max    and LOGDIE('column index is larger than columns');
		$_<0       and LOGDIE('column index is negatve');
		$_ ;
              } @{ranges2set($range_str)};
}

sub pack_cols {
	my @col = @_ ;
	my $col_str   = '('. join(', ', @col) . ')'; 
	( $col_str, @col );
}

sub requested_cols {
	# select colomns from $all
	# Assumption:  Only one of $s->{copy_columns}  or $s->{only_cols}
	# Assumption:  the user specified a valid "copy" parameter
	# are defined. If none are defined, it returns all columns.
	my  $s = shift || return;
	my  $all = $s->{attributes};
	die 'missing $all columns'  unless $all ;
	die 'missing $all columns'  unless @$all;
	die 'mutually exclusive'    if $s->{copy_columns} && $s->{only_cols} ;

	return pack_cols(@$all)    unless $s->{copy_columns} || $s->{only_cols};
	return pack_cols @{$s->{copy_columns}} if $s->{copy_columns}           ;
	return pack_cols @$all    if ($s->{copy_columns}||'') =~ /^\s*[*]\s*$/o;

        pack_cols +($s->{copy_columns}) 
			? @{$s->{copy_columns}}
			: @$all[  field_nums_reqe $s, $#{$all} ]   ;
}


1;
__END__
my $att = {
     quote_char          => '"',
     escape_char         => '"',
     sep_char            => ',',
     eol                 => '',
     always_quote        => 0,
     binary              => 0,
     keep_meta_info      => 0,
     allow_loose_quotes  => 0,
     allow_loose_escapes => 0,
     allow_whitespace    => 0,
     blank_is_undef      => 0,
     verbatim            => 0,
};

=head1 NAME

Pg::Loader::Columns - Helper module for Pg::Loader

=head1 SYNOPSIS

  use Pg::Loader::Columns;

=head1 DESCRIPTION

This is a helper module for pgloader.pl(1), which loads tables to
a Postgres database. It is similar in function to the pgloader(1)
python program (written by other authors).


=head2 EXPORT


Pg::Loader::Columns - Perl extension for loading Postgres tables


=head1 SEE ALSO

http://pgfoundry.org/projects/pgloader/  hosts the original python
project.


=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

