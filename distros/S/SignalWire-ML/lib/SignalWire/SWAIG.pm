package SignalWire::SWAIG;

use strict;
use warnings;
use JSON;
use CGI;
use Data::Dumper;
use SignalWire::ML;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

our $VERSION = '1.12';
our $AUTOLOAD;

sub new {
    my $proto = shift;
    my $args  = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    $self->{cgi}          = CGI->new();
    $self->{swml}         = SignalWire::ML->new();
    $self->{data}         = $self->{cgi}->param('POSTDATA');
    $self->{json}         = JSON->new->allow_nonref;
    $self->{_data}        = $self->{json}->decode($self->{data});
    $self->{call_log}     = $self->{_data}->{call_log};
    $self->{content_type} = $self->{_data}->{content_type};
    $self->{SWMLVars}     = $self->{_data}->{SWMLVars};
    $self->{argument}     = $self->{_data}->{argument};
    $self->{function}     = $self->{_data}->{function};
    $self->{version}      = $self->{_data}->{version};
    $self->{app_name}     = $self->{_data}->{app_name};
    $self->{purpose}      = $self->{_data}->{purpose};
    return bless($self, $class);
}

sub response {
    my $self = shift;
    my $response = shift;
    my $cgi  = $self->{cgi};
    my $json = $self->{json};
    print $cgi->header('application/json');
    print $json->encode({ response => $response});
}

sub get_call_log {
	my $self = shift;
	return $self->{call_log};
}

sub content_type {
	my $self = shift;
	return $self->{content_type};
}

sub SWMLVars {
	my $self = shift;
	return $self->{SWMLVars};
}

sub argument {
	my $self = shift;
	return $self->{argument};
}

sub argument_parsed {
	my $self = shift;
	return $self->{argument}->{parsed}[0]
}

sub argument_subtituted {
	my $self = shift;
	return $self->{argument}->{subtituted}
}

sub argument_raw {
	my $self = shift;
	return $self->{argument}->{raw};
}

sub function {
	my $self = shift;
	return $self->{function};
}

sub version {
	my $self = shift;
	return $self->{version};
}

sub app_name {
	my $self = shift;
	return $self->{app_name};
}

sub purpose {
	my $self = shift;
	return $self->{purpose};
}

sub data {
	my $self = shift;
	return $self->{data};
}

sub json {
	my $self = shift;
	return $self->{json};
}

sub cgi {
	my $self = shift;
	return $self->{cgi};
}

1;
