# Perl 
#
# Class Report::Porf::Table::Simple::AutoColumnConfigurator
#
# Perl Open Report Framework (Porf)
#
# Configure Report columns automatically
#
# Ralf Peine, Wed May 14 10:39:50 2014
#
# More documentation at the end of file
#------------------------------------------------------------------------------

$VERSION = "2.000";

use strict;
use warnings;

#--------------------------------------------------------------------------------
#
#  Report::Porf::Table::Simple::AutoColumnConfigurator
#
#--------------------------------------------------------------------------------

package Report::Porf::Table::Simple::AutoColumnConfigurator;

# --- new Instance, Do NOT call direct!!! -----------------
sub new
{
    my $caller = $_[0];
    my $class  = ref($caller) || $caller;
    
    # let the class go
    my $self = {};
    bless $self, $class;

    $self->{Configurators} = {};
    $self->{max_column_width} = 60;

    return $self;
}

# --- create_report_configuration as string list ---
sub report_configuration_as_string {
    my ($self,
		$list_ref,
		$max_rows_to_inspect
	) = @_;
	
	my $config_list = $self->create_report_configuration($list_ref, $max_rows_to_inspect);
	my @result;
	
	foreach my $config (@$config_list) {
		my $line = '$report->cc( ';
		foreach my $key (sort(keys(%$config))) {
			$line .= " $key => ". $config->{$key}.', ';
		}
		$line .= ");";
		push (@result, $line);
	}
	return \@result;
}

# --- create_report_configuration ---
sub create_report_configuration {
    my ($self,
		$list_ref,
		$max_rows_to_inspect
	) = @_;

    return [] unless $list_ref && scalar @$list_ref;

    my $ref_info = ref($list_ref->[0]);
    
    return $self->create_hash_report_configuration($list_ref, $max_rows_to_inspect)
		if uc($ref_info) eq 'HASH';

	return $self->create_array_report_configuration($list_ref, $max_rows_to_inspect)
		if uc($ref_info) eq 'ARRAY';
	
    die "cannot create auto configuration for '$ref_info' elements.";
}

# --- crate the default report configuration for a list of hashes --------
sub create_hash_report_configuration {
    my ($self,
		$list_ref,
		$max_rows_to_inspect
	) = @_;

    return [] unless $list_ref && scalar @$list_ref;
    
    my @config_list;
    
    my %hash_key_store   = ();
    $max_rows_to_inspect = 10 unless defined $max_rows_to_inspect;
    $max_rows_to_inspect = $#$list_ref if $max_rows_to_inspect == -1;
    
    my $row_count = 0;
    foreach my $data (@$list_ref) {
		foreach my $key (sort(keys(%$data))) {
			next unless defined $key;
			$hash_key_store{$key} = length ($key) unless $hash_key_store{$key};
			my $text_length = length ($data->{$key} || '0');
			$hash_key_store{$key} = $text_length 
				if $hash_key_store{$key} < $text_length;
		}
		last if $row_count++ >= $max_rows_to_inspect;
    }
    
    foreach my $key (sort(keys(%hash_key_store))) {
		my $width = $hash_key_store{$key};
		$width = $self->{max_column_width} if $width > $self->{max_column_width};
		push (@config_list, {-h => $key, -vn => $key, -w => $width, -a => 'l'});
    }
    
    return \@config_list;
}

# --- crate the default report configuration for a list of arrays --------
sub create_array_report_configuration {
    my ($self,
		$list_ref,
		$max_rows_to_inspect
	) = @_;

    return [] unless $list_ref && scalar @$list_ref;
    
    my @config_list;
    
    $max_rows_to_inspect = 10 unless defined $max_rows_to_inspect;
    $max_rows_to_inspect = $#$list_ref if $max_rows_to_inspect == -1;
    
    my $row_count = 0;
	my $max_columns = 0;
	my @column_lengths;
    foreach my $data (@$list_ref) {
		my $columns = scalar @$data;
		$max_columns = $columns if $columns > $max_columns;
		foreach my $idx (0..($columns-1)) {
			$column_lengths[$idx] = $column_lengths[$idx] || '0';
			my $text_length = length ($data->[$idx] || '0');
			$column_lengths[$idx] = $text_length 
				if $column_lengths[$idx] < $text_length;
		}
		
		last if $row_count++ >= $max_rows_to_inspect;
    }
    
	foreach my $idx (0..($max_columns-1)) {
		my $width = $column_lengths[$idx];
		$width = $self->{max_column_width} if $width > $self->{max_column_width};
		push (@config_list, {-h => ($idx+1).'. Column', -vi => $idx, -w => $width, -a => 'l'});
    }
    
    return \@config_list;
}

# --- create report with automatic configured columns ------------------
sub create_report {
    my ($self,
		$list_ref,
		$report_framework,
		$format
	) = @_;

    return undef unless $list_ref && scalar @$list_ref;

    my $first_element = $list_ref->[0];

    $report_framework = Report::Porf::Framework::get() unless $report_framework;
    my $report        = $report_framework->create_report($format);

	$report->set_default_cell_value('');
    
    foreach my $config_option (@{$self->create_report_configuration($list_ref)}) {
		$report->cc (%$config_option);
    }

    $report->configure_complete();

    return $report;
}
