package Spreadsheet::Wright::Excel;

use 5.010;
use strict;
use warnings;
no warnings qw( uninitialized numeric );

BEGIN {
	$Spreadsheet::Wright::Excel::VERSION   = '0.105';
	$Spreadsheet::Wright::Excel::AUTHORITY = 'cpan:TOBYINK';
}

use Carp;
use Spreadsheet::WriteExcel;

use parent qw(Spreadsheet::Wright);

sub new
{
	my ($class, %args) = @_;
	my $self = bless {}, $class;
	
	$self->{'_FILENAME'}  = $args{'file'} // $args{'filename'}
		or croak "Need filename.";
	$self->{'_SHEETNAME'} = $args{'sheet'}  // '';
	$self->{'_STYLES'}    = $args{'styles'} // {};
		
	return $self;
}

sub _prepare
{
	my $self = shift;
	my $worksheet = $self->{'_WORKSHEET'};
	my $workbook  = $self->{'_WORKBOOK'};
	
	if(!$worksheet)
	{
		$self->{'_FH'}->binmode();
		$workbook = Spreadsheet::WriteExcel->new($self->{'_FH'});
		$self->{'_WORKBOOK'} = $workbook;
		$worksheet = $workbook->add_worksheet($self->{'_SHEETNAME'});
		$self->{'_WORKSHEET'} = $worksheet;
		$self->{'_WORKBOOK_ROW'} = 0;
	}
	
	return $self;
}

sub freeze (@)
{
	my $self=shift;
	$self->_open() or return;
	$self->{'_WORKSHEET'}->freeze_panes(@_);
	return $self;
}

sub close
{
	my $self=shift;
	
	return if $self->{'_CLOSED'};
	
	$self->{'_WORKBOOK'}->close
		if $self->{'_WORKBOOK'};
		
	$self->{'_FH'}->close
		if $self->{'_FH'};
		
	$self->{'_CLOSED'} = 1;
	return $self;
}

sub _format_cache($$)
{
	my ($self, $format) = @_;

	my $cache_key='';
	foreach my $key (sort keys %$format)
	{
		$cache_key .= $key . $format->{$key};
	}

	if(exists($self->{'_FORMAT_CACHE'}{$cache_key}))
	{
		return $self->{'_FORMAT_CACHE'}{$cache_key};
	}

	return $self->{'_FORMAT_CACHE'}{$cache_key} = $self->{'_WORKBOOK'}->add_format(%$format);
}

sub addsheet ($$)
{
	my ($self,$name)=@_;

	$self->_open() or return;

	my $worksheet = $self->{'_WORKBOOK'}->add_worksheet($name);
	$self->{'_SHEETNAME'} = $name;
	$self->{'_WORKSHEET'} = $worksheet;
	$self->{'_WORKBOOK_ROW'} = 0;
	
	return $self;
}

sub _add_prepared_row
{
	my $self = shift;

	my $worksheet = $self->{'_WORKSHEET'};
	my $workbook  = $self->{'_WORKBOOK'};
	my $row       = $self->{'_WORKBOOK_ROW'};
	my $col       = 0;
	
	for (my $i=0; $i<scalar(@_); $i++)
	{
		my %props = %{ $_[$i] };
		my $value = $props{'content'};
		
		delete $props{'content'};
		my $props = \%props;

		my %format;
		if (%props)
		{
			if(my $style = $props->{'style'})
			{
				my $stprops = $self->{'_STYLES'}->{$style};
				if(!$stprops)
				{
					# warn "Style '$style' is not defined\n";
				}
				else
				{
					my %a;
					@a{keys %$stprops} = values %$stprops;
					@a{keys %$props} = values %$props;
					$props=\%a;
				}
			}

			if ($props->{'font_weight'} eq 'bold')
			{
				$format{'bold'} = 1;
			}
			if ($props->{'font_style'} eq 'italic')
			{
				$format{'italic'} = 1;
			}
			if ($props->{'font_decoration'} =~ m'underline')
			{
				$format{'underline'} = 1;
			}
			if ($props->{'font_decoration'} =~ m'strikeout')
			{
				$format{'font_strikeout'} = 1;
			}
			if (defined $props->{'font_color'})
			{
				$format{'color'} = $props->{'font_color'};
			}
			if (defined $props->{'font_face'})
			{
				$format{'font'}=$props->{'font_face'};
			}
			if (defined $props->{'font_size'})
			{
				$format{'size'}=$props->{'font_size'};
			}
			if (defined $props->{'align'})
			{
				$format{'align'}=$props->{'align'};
			}
			if (defined $props->{'valign'})
			{
				$format{'valign'}=$props->{'valign'};
			}
			if (defined $props->{'format'})
			{
				$format{'num_format'} = $props->{'format'};
			}
			if (defined $props->{'width'})
			{
				$worksheet->set_column($col,$col,$props->{'width'});
			}
		}

		my @params = ($row, $col++, $value);
		push @params, $self->_format_cache(\%format) if keys %format;

		my $type = defined $props->{'type'}
			? lc $props->{'type'}
			: 'auto';
		
		if ($type eq 'auto')       { $worksheet->write(@params); }
		elsif ($type eq 'string')  { $worksheet->write_string(@params); }
		elsif ($type eq 'text')    { $worksheet->write_string(@params); }
		elsif ($type eq 'number')  { $worksheet->write_number(@params); }
		elsif ($type eq 'blank')   { $worksheet->write_blank(@params); }
		elsif ($type eq 'formula') { $worksheet->write_formula(@params); }
		elsif ($type eq 'url')     { $worksheet->write_url(@params); }
		else {
			carp "Unknown cell type $type";
			$worksheet->write(@params);
		}
	}
	
	$self->{'_WORKBOOK_ROW'}++;
	
	return $self;
}


1;