package Spreadsheet::Wright::JSON;

use 5.010;
use strict;
use warnings;
no warnings qw( uninitialized numeric );

BEGIN {
	$Spreadsheet::Wright::JSON::VERSION   = '0.107';
	$Spreadsheet::Wright::JSON::AUTHORITY = 'cpan:TOBYINK';
}

use Carp;
use JSON;

use parent qw(Spreadsheet::Wright);

sub new
{
	my ($class, %args) = @_;
	my $self = bless { 'options' => \%args }, $class;
	$self->{'_FILENAME'} = $args{'file'} // $args{'filename'}
		or croak "Need filename.";
	$self->{'_WORKSHEET'} = $args{'sheet'} // 'Sheet1';
	return $self;
}

sub addsheet
{
	my ($self, $caption) = @_;
	$caption //= 'Sheet' . (1 + scalar keys %{$self->{'data'}});
	
	if (defined $self->{'data'}->{$caption})
	{
		my $i    = 2;
		my $base = $caption;
		
		ALTERNATIVE: while (1)
		{
			$caption = "$base ($i)";
			last ALTERNATIVE unless defined $self->{'data'}->{$caption};
			$i++;
		}
	}
	
	$self->{'_WORKSHEET'} = $caption;
	return $self;
}

sub _add_prepared_row
{
	my $self = shift;
	
	my @texts;
	foreach my $cell (@_)
	{
		my $content = $cell->{'content'};
		$content = sprintf($content, $cell->{'sprintf'})
			if $cell->{'sprintf'};
		push @texts, $content;
	}
	push @{ $self->{'data'}->{$self->{'_WORKSHEET'}} }, [@texts];
	
	return $self;
}

sub close
{
	my $self=shift;
	return if $self->{'_CLOSED'};
	
	if (1 == scalar keys %{$self->{'data'}})
	{
		$self->{'_FH'}->print(
			to_json($self->{'data'}->{$self->{'_WORKSHEET'}}, $self->{'json_options'})
			);
	}
	else
	{
		$self->{'_FH'}->print(
			to_json($self->{'data'}, $self->{'json_options'})
			);
	}
	
	$self->{'_FH'}->close if $self->{'_FH'};
	$self->{'_CLOSED'}=1;
	return $self;
}

1;
