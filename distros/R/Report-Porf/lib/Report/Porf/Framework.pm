# Perl 
#
# Class Report::Porf::Framework
#
# Perl Open Report Framework (Porf)
#
# Framework to create/configure Reports for any output format.
#
# Ralf Peine, Tue May 27 11:30:17 2014
#
# More documentation at the end of file
#------------------------------------------------------------------------------

$VERSION = "2.001";

#------------------------------------------------------------------------------
#
# Example list with 10 lines (html)
# 
# <html>
# <table border='1' rules='groups'>
#                                         
# <thead>
# <tr><th>Coun</th><th>TimeStamp </th><th>Age    </th><th>Prename    </th><th>Surname </th></tr>
# </thead>
#                                         
# <tr><td>1   </td><td>0.000433  </td><td>10     </td><td>Vorname 1  </td><td>Name 1  </td></tr>
# <tr><td>2   </td><td>0.000638  </td><td>20     </td><td>Vorname 2  </td><td>Name 2  </td></tr>
# <tr><td>3   </td><td>0.000781  </td><td>30     </td><td>Vorname 3  </td><td>Name 3  </td></tr>
# <tr><td>4   </td><td>0.000922  </td><td>40     </td><td>Vorname 4  </td><td>Name 4  </td></tr>
# <tr><td>5   </td><td>0.001062  </td><td>50     </td><td>Vorname 5  </td><td>Name 5  </td></tr>
# <tr><td>6   </td><td>0.001203  </td><td>60     </td><td>Vorname 6  </td><td>Name 6  </td></tr>
# <tr><td>7   </td><td>0.001346  </td><td>70     </td><td>Vorname 7  </td><td>Name 7  </td></tr>
# <tr><td>8   </td><td>0.001486  </td><td>80     </td><td>Vorname 8  </td><td>Name 8  </td></tr>
# <tr><td>9   </td><td>0.001631  </td><td>90     </td><td>Vorname 9  </td><td>Name 9  </td></tr>
# <tr><td>10  </td><td>0.001773  </td><td>100    </td><td>Vorname 10 </td><td>Name 10 </td></tr>
#                                         
# </table><p/>
# # Time needed for export of 10 data lines: 0.002013
# 
# </html>
# 

use strict;
use warnings;

#--------------------------------------------------------------------------------
#
#  Report::Porf::Framework
#
#--------------------------------------------------------------------------------

package Report::Porf::Framework;

use Carp;
use Data::Dumper;

use Report::Porf::Table::Simple;
use Report::Porf::Table::Simple::AutoColumnConfigurator;

# only for default creation
use Report::Porf::Table::Simple::HtmlReportConfigurator;
use Report::Porf::Table::Simple::TextReportConfigurator;
use Report::Porf::Table::Simple::CsvReportConfigurator;

our %store; # of named frameworks

our $DefaultFramework = '';

#--------------------------------------------------------------------------------
#
#  Creation / Filling Of Instances
#
#--------------------------------------------------------------------------------

# --- new Instance, Do NOT call direct!!! -----------------
sub _new
{
    my $caller = $_[0];
    my $class  = ref($caller) || $caller;
    
    # let the class go
    my $self = {};
    bless $self, $class;

    $self->{Configurators} = {};

    return $self;
}

# --- CreateInstance --------------------------------------
sub create {
	my %options = @_ if scalar @_;

	my $framework = Report::Porf::Framework->_new();
	$framework->use_default_configurator_creators();

	$framework->set_name($options{-name}) if $options{-name};
	$framework->set_description($options{-description}) if $options{-description};
	$framework->set_default_format('text');
	$framework->set_max_rows(10);

	foreach my $key (sort(keys(%options))) {
	    if ($key =~ /^\-create(\w+)ConfiguratorAction$/) {
			my $format = $1;
			$framework->set_configurator_action($format => $options{$key});
	    }
	}

	$framework->store();

	return $framework;
}

# --- Activate the default configurators for every known output format -------------
sub use_default_configurator_creators {
	my ($self,					# instance_ref
	) = @_;

	$self->set_configurator_action(HTML => sub {
		my $configurator = Report::Porf::Table::Simple::HtmlReportConfigurator->new();
		$configurator->set_alternate_row_colors('#DDDDDD', '#FFFFFF');
		return $configurator;
	});
	$self->set_configurator_action
	    (Text => sub { return Report::Porf::Table::Simple::TextReportConfigurator->new();});
	$self->set_configurator_action
	    (CSV => sub { return Report::Porf::Table::Simple::CsvReportConfigurator->new();});
	
	$self->set_auto_configurator_action(
		sub {return Report::Porf::Table::Simple::AutoColumnConfigurator->new();});
}

#--------------------------------------------------------------------------------
#
#  Attributes
#
#--------------------------------------------------------------------------------

# --- Name ----------------------------------------------------------------------------

sub set_name {
	my ($self,					# instance_ref
		$value					# value to set
	) = @_;

	if ($self->{Name}) {
		if ($self->{Name} ne $value) {
			die "Name of framework cannot be changed!";
		}
	}
	$self->{Name} = $value;
}

sub get_name {
	my ($self,					# instance_ref
	) = @_;
        
	return $self->{Name};
}

# --- Description ----------------------------------------------------------------------------

sub set_description {
	my ($self,					# instance_ref
		$value					# value to set
	) = @_;

	$self->{Description} = $value;
}

sub get_description {
	my ($self,					# instance_ref
	) = @_;
        
	return $self->{Description};
}

# --- Default Format ----------------------------------------------------------------------------

sub set_default_format {
	my ($self,					# instance_ref
		$value					# value to set
	) = @_;

	$self->{DefaultFormat} = $value;
}

sub get_default_format {
	my ($self,					# instance_ref
	) = @_;
        
	return $self->{DefaultFormat};
}

# --- MaxRows ----------------------------------------------------------------------------

sub set_max_rows {
	my ($self,					# instance_ref
		$value					# value to set
	) = @_;

	$self->{MaxRows} = $value;
}

sub get_max_rows {
	my ($self,					# instance_ref
	) = @_;
        
	return $self->{MaxRows};
}

# --- Configurator ---------------------------------------------------------------

sub set_configurator_action {
	my ($self,					# instance_ref
		$format,				# (html/text/csv)
		$action					# value to set
	) = @_;
        
	die "Format not set" unless $format;
	die "No action given" unless ref ($action) eq 'CODE';

	$self->{Configurators}->{lc($format)} = $action;
}

sub get_configurator_action {
	my ($self,					# instance_ref
		$format,				# (html/text/csv)
	) = @_;
        
	die "Format not set" unless $format;

	return $self->{Configurators}->{lc($format)};
}

# --- AutoConfigurator ---------------------------------------------------------------

sub set_auto_configurator_action {
	my ($self,					# instance_ref
		$action					# value to set
	) = @_;
        
	die "No action given" unless ref ($action) eq 'CODE';

	$self->{AutoConfigurator} = $action;
}

sub get_auto_configurator_action {
	my ($self,					# instance_ref
	) = @_;
        
	return $self->{AutoConfigurator};
}

#--------------------------------------------------------------------------------
#
#  Methods
#
#--------------------------------------------------------------------------------

# --- get framework --- Creates default, if not existing ------------------------
sub get {
	my ($name					# Optional: name of framework
	) = @_;

	my $framework;

	$name = $DefaultFramework unless $name;

	unless ($name) {
		$name = '-default';
		$framework = $store{$name};
		$framework = create(
			-name        => $name,
			-description => 'Automatic created default framework')
			->store()
				unless $framework;
	}

	$framework = $store{$name};

	confess "No report framework with name '$name' stored"
		unless $framework;

	return $framework;
}

# --- store Framework in internal %store ------------------------------------------

sub store {
	my ($self,					# instance_ref
	) = @_;

	my $name = $self->get_name();
        
	confess "cannot store unnamed framework" unless $name;

	$store{$name} = $self;
}

# --- Define the default framework to use --------------------------------------------------
sub set_default_framework {
	my ($name,					# instance_ref
	) = @_;

	get($name);					# dies if not existing 
	my $old = $DefaultFramework;
	$DefaultFramework = $name;

	return $old;
}

# --- create Report Configurator --------------------------------------------------

sub create_report_configurator {
	my ($self,					# instance_ref
		$format					# format of report
	) = @_;

	my $action = $self->get_configurator_action(lc($format));

	die "don't know how to configure report for format '$format'"
	    unless $action;

	return $action->();
}

# --- create Report ---------------------------------------------------------------

sub create_report {
	my ($self,					# instance_ref
		$format					# format of report
	) = @_;

	$format = $self->set_default_format('text') unless $format;

	my $report_configurator = $self->create_report_configurator($format);
	return $report_configurator->create_and_configure_report();
}

# --- extract format out of file name, if $file is an file name ---------------
sub extract_format_of_filename {
	my ($self,					# instance_ref
		$file_name				# format of report
	) = @_;

	my $format = '';

	if ($file_name && ref($file_name) eq '') {
		return 'Text' if $file_name =~ /\.(txt|text)$/io;
		return 'Html' if $file_name =~ /\.(htm|html)$/io;
		return 'Csv'  if $file_name =~ /\.csv$/io;
	}

	return '';
}


# --- create auto report configuration -----------------------------------------------------------------
sub create_auto_report_configuration {
    my $report_framework = Report::Porf::Framework::get();
    my $configurator     = $report_framework->get_auto_configurator_action()->();

	return $configurator->create_report_configuration(@_);
}

# --- create auto report configuration -----------------------------------------------------------------
sub report_configuration_as_string {
    my $report_framework = Report::Porf::Framework::get();
    my $configurator     = $report_framework->get_auto_configurator_action()->();

	return $configurator->report_configuration_as_string(@_);
}


# --- auto report -----------------------------------------------------------------
sub auto_report {
    my ($list_ref,				# what to print out
		@all_args				# named args
	) = @_;

    return 0 unless defined $list_ref;

	unless (ref($list_ref) eq 'ARRAY') {
		my $type = ref($list_ref) || "no reference";
		die "auto_report() needs ref to array as first arg but is $type";
	}

    return 0 unless scalar @$list_ref;

    my $report_framework = Report::Porf::Framework::get();
    my $configurator     = $report_framework->get_auto_configurator_action()->();

	my %args = ();
	my $file_item = '';
	my $format    = '';
	
	if (scalar @all_args == 1) {
		$file_item = $all_args[0];
	}
	else {
		%args = @all_args;
		$file_item = $args{-file} if $args{-file};
	}

    my $max_rows = '';
    $max_rows = $args{-max_rows} if defined $args{-max_rows};
	$max_rows = '' unless defined $max_rows;

	if (defined $args{-format}) {
		$format = $args{-format};
	}
	else {
		$format = $report_framework->extract_format_of_filename($file_item);
	}
	
	$format = $report_framework->get_default_format() unless $format;

    my $report = $configurator->create_report($list_ref, $report_framework, $format);

    # only max rows without file item set (print not too many rows to stdout)
    if (!$file_item || $max_rows) {
		$max_rows = $report_framework->get_max_rows() if $max_rows eq '' && !$file_item;
		if ($max_rows > 0 && scalar @$list_ref > $max_rows) {
			$max_rows--;
			my @rows = @{$list_ref}[0..$max_rows];
			$list_ref = \@rows;
		}
    }

    $report->write_all($list_ref, $file_item);

	return scalar @$list_ref; # rows printed out
}

1;

__END__

=head1 NAME

Report::Porf::Framework

Framework to create/configure Reports for any output format.

Part of Perl Open Report Framework (Porf).

=head1 VERSION

This documentation refers to version 2.001 of Report::Porf::Framework

All subs are no longer camel cased, so update your scripts, please.
A list for conversion can be find in Report/Porf/rename_list.pl

=head1 SYNOPSIS

=head2 Structure Of A Report

  Report
    Table
      Line (Conatining data of data row)
        Cell
  
  *============+============+============*  # Bold separator line
  |   Prename  |   Surname  |     Age    |  # The header line
  *------------+------------+------------*  # Separator line
  | Vorname 1  | <a cell>   | 7.69230769 |  # A data line with <cell>s
  | Vorname 2  | Name 2     | 15.3846153 |
  | Vorname 3  | Name 3     | 23.0769230 |
  | Vorname 4  | Name 4     | 30.7692307 |
  *============+============+============*

=head2 Using Auto Configure

  use Report::Porf qw(:all);

  auto_report(\@data);        # prints to STDOUT
  auto_report(\@data, $file); # writes into $file

  auto_report(\@data, $file, -format => 'html');
  auto_report(\@data, -file => $file, -format => 'html', -max_rows => 13);

C< \@data> has to be a list of hashes or arrays. If C< $file> is a
filename (as string), then ending of filename defines format of
created table.

Filehandles don't know the filename, so format has to be select
explicit in this case.

C< -max_rows> defines maximum rows to print out. In case of printing
out at STDOUT there is a default max_rows as set to 10 rows. That
makes live easy for debugging.


=head2 create And Configure Report Explicit

  my $report_frame_work = Report::Porf::Framework::get();
  my $report            = $report_frame_work->create_report($format);

  # $report->set_verbose(3); # uncomment to see infos about configuring phase

Current supported formats:

  HTML
  Text
  Csv

=head2 Configure Report

After creation a report has to be configured. 

Call C<configure_column(%options)> to configure a report. Following
options are available:

=head3 Layout

  -header  -h   constant: Text
  -align   -a   constant: (left|center|right)
                          (l   |   c  |    r)
  -width   -w   constant: integer
  -format  -f   constant: string for sprintf
  -color   -c   constant / sub {...}

The sub {...} makes conditional coloring easy possible.

=head3 Value Manipulation

  -default_value        -def_val      -dv   constant: default value
  -escape_special_chars -esc_spec_chr -esc  constant: 1 or 0

Use default_cell_value if value is undef or ''.

To switch off special value escaping use

  escape_special_chars => 0

As next, access to the value has to be defined. There are 4 alternatives
to get the value of a cell depending of type (array, hash, object).

=head3 GetValue Alternative 1 --- ARRAY

  my $prename = 1;
  my $surname = 2;
  my $age     = 3;

  $report->configure_column(-header => 'Prename', -value_indexed => $prename ); # long
  $report->conf_col        (-h      => 'Surname', -val_idx       => $surname ); # short
  $report->cc             (-h      => 'Age',     -vi            => $age     ); # minimal

=head3 GetValue Alternative 2 --- HASH

  $report->configure_column(-header => 'Prename', -value_named => 'Prename' ); # long
  $report->conf_col        (-h      => 'Surname', -val_nam     => 'Surname' ); # short
  $report->cc             (-h      => 'Age',     -vn          => 'Age'     ); # minimal

=head3 GetValue Alternative 3 --- OBJECT

  $report->configure_column(-header => 'Prename', -value_object => 'get_prename()'); # long
  $report->conf_col        (-h      => 'Surname', -val_obj      => 'get_surname()'); # short
  $report->cc             (-h      => 'Age',     -vo           => 'get_age()'    ); # minimal

=head3 GetValue Alternative 4 --- Free 

  $report->configure_column(-h => 'Prename',  -value =>    '"Dr. " . $_[0]->{Surname}'    );
  $report->conf_col        (-h => 'Surname',    -val => sub { return $_[0]->{Prename}; }; );
  $report->cc             (-h => 'Age (Months)', -v =>     '(12.0 * $_[0]->get_age())'    );

=head2 When All Columns Are Configured

  $report->configure_complete(); 

=head2 Write Table Out Into File

  $report->write_all($person_rows, $out_file_name);

You can also put out single rows or single cells or start actions to do that.
[Needs to be explained more]

In "Report/Porf/examples" subdir you can find more examples.

=head1 Details

Here are the details for those, who want to modify an existing or
create a new ReportConfigurator. It's actually not complete. See
*ReportConfigurator.pm for more.

=head2 Report Attributes

There a following attributes of report, that can used by get*/Set*

  FileStart
    PageStart
      TableStart
        *============+====  # BoldSeparatorLine
        |   Prename  | ...  # HeaderRowStart HeaderStart <HeaderText> HeaderEnd ... HeaderRowEnd
        *------------+----  # SeparatorLine
        | Vorname 1  | ...  # RowStart       CellStart   <CellValue>  CellEnd   ... RowEnd
        | ...        | ...  # ...
        *============+====  # BoldSeparatorLine
      TableEnd
    PageEnd
  FileEnd

To be continued...

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 by Ralf Peine, Germany.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
