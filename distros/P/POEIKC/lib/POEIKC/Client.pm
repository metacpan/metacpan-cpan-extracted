package POEIKC::Client;

use strict;
use 5.008_001;

use warnings;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;
use Sys::Hostname ();
use UNIVERSAL::require;
use Best [ [ qw/YAML::XS YAML::Syck YAML/ ], qw/Dump/ ];
use POE::Component::IKC::ClientLite;

our $DEBUG;

sub DEBUG {
	my $self = shift;
	$DEBUG = shift if @_;;
}

sub new {
    my $class = shift ;
    my $self = {
        @_
        };
    $class = ref $class if ref $class;
    bless  $self,$class ;
    return $self ;
}

sub ikc_client_format {
	my $self = shift;
	my ($options, @argv) = @_;

	my $args = \@argv;
	if (exists $options->{debug}) {
		$DEBUG = 1;
		_DEBUG_log($options);
		_DEBUG_log($args);
	}
	$options->{help}  and return;
	$options->{alias} ||= 'POEIKCd';
	$options->{port}  ||= 47225;
	
	### state_name vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
	$options->{state_name} ||= '';

	if (exists $options->{Utility}) {
		my $commoand = $options->{Utility};
		$commoand = $options->{Utility};
		$options->{state_name} = 'method_respond';
		@{$args} = ('POEIKC::Daemon::Utility', $commoand, @{$args});
		_DEBUG_log($args);
	}

	if (exists $options->{INC}) {
		my @inc;
		@inc = 
			map {split(/:/=>$_)} 
			map {ref $_ ? @{$_} : $_} 
			($options->{INC});
		$options->{state_name} = 'method_respond';
		@{$args} = (qw(POEIKC::Daemon::Utility unshift_INC), @inc);
		$options->{output} ||= 'd';
		_DEBUG_log($args);
	}

	if (exists $options->{inc_}) {
		my $commoand = $options->{inc_};
		$commoand = 
			$commoand =~ /^del$|^delete$|^delete_INC$/ ? 'delete_INC' :
			$commoand =~ /^reset$|^reset_INC$/ ? 'reset_INC' : $commoand;
		$options->{state_name} = 'method_respond';
		@{$args} = ('POEIKC::Daemon::Utility', $commoand, @{$args});
		$options->{output} ||= 'd';
		_DEBUG_log($args);
	}

	$options->{state_name} = 
		$options->{state_name} =~ /^method|^m$/     ? 'method_respond' : 
		$options->{state_name} =~ /^function|^f$/   ? 'function_respond' : 
		$options->{state_name} =~ /^event|^e$/      ? 'event_respond' : 
		$options->{state_name};

	if ( grep {/^shutdown$/i} @{$args}) {
		$options->{state_name} = 'method_respond';
		@{$args} = ('POEIKC::Daemon::Utility', 'shutdown');
	};


	if ($args and @{$args} and not $options->{state_name}) {
		$options->{state_name} ||= 'something_respond';
	}

	$options->{state_name} or return;

	###^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	$options->{HOST} ||= '127.0.0.1';

#	if( Proc::ProcessTable->use ){
#		for my $ps( @{Proc::ProcessTable->new->table} ) {
#			if ($ps->{fname} eq 'poikc'){
#				$ps->{cmndline} =~ /poikc/;
#				$0 = $ps->{fname}. $';
#			}
#		}
#	}

	if (exists $options->{debug}) {
		_DEBUG_log($options);
		_DEBUG_log($options->{HOST});
		_DEBUG_log($options->{port});
		_DEBUG_log($args);
	}

	my $state_name = $options->{alias}.'/'.$options->{state_name};

	$DEBUG and _DEBUG_log($state_name, $args);
	
	return ($state_name => $args);
}


sub post_respond {
	my $self = shift;
	my ($options, $state_name, $args) = @_;

	my ($name) = join('_'=>Sys::Hostname::hostname, ($0 =~ /(\w+)/g), $$);
	my $ikc = $self->{ikc} ||= create_ikc_client(
		ip   => $options->{HOST},
		port => $options->{port},
		name => $name,
	);
	$ikc or do{
		return sprintf "%s\n\n",$POE::Component::IKC::ClientLite::error; 
	};

	my $ret = $ikc->post_respond($state_name => $args);
	$ikc->error and undef $self->{ikc}, return ($ikc->error), ;
	no warnings;
	if (my $r = ref $ret) {
		$DEBUG and _DEBUG_log($r);
		if ( $options->{output} and $options->{output} =~ /^H[YD]$/i and  $r eq 'HASH'){
			$DEBUG and _DEBUG_log($ret);
			$options->{output} =~ s/^H//i;
			my %ret = %{$ret};
			my $max = 0;
			for(sort keys %ret){length($_) > $max and $max = length($_);}
			my $format = "%-${max}s= %s";
			for(sort keys %ret){printf $format, $_, output($options->{output}, $ret{$_})}
			print "\n";
		}elsif ($options->{output}) {
			$DEBUG and _DEBUG_log($ret);
			return (output($options->{output},$ret));
		}elsif (ref $ret) {
			$DEBUG and _DEBUG_log($ret);

			local $Data::Dumper::Terse    = 1; 
			local $Data::Dumper::Sortkeys = 1; 
			local $Data::Dumper::Indent   = 1; 

			return(Dumper($ret));
		}else{
			$DEBUG and _DEBUG_log($ret);
			return $ret;
		}
	}else{
		$DEBUG and _DEBUG_log($ret);
		return output($options->{output}, $ret);
	}
}

sub output {
	my $output_flag = shift;
	$DEBUG and _DEBUG_log(join "\t"=> grep {defined $_} caller(1));
	return unless @_;

		local $Data::Dumper::Terse    = 1; 
		local $Data::Dumper::Sortkeys = 1; 
		local $Data::Dumper::Indent   = 1; 

	for ($output_flag || ()) {
		/^D$|^Dumper$/i and return Dumper(@_);
		/^Y$|^YAML$/i   and return Dump(@_);
	}
	return @_;
}

sub _DEBUG_log {
	$DEBUG or return;
	Date::Calc->use or return;
	#YAML->use or return;
	my ($pack, $file, $line, $subroutine) = caller(0);
	my $levels_up = 0 ;
	($pack, $file, $line, ) = caller($levels_up);
	$levels_up++;
	(undef, undef, undef, $subroutine, ) = caller($levels_up);
	{
		(undef, undef, undef, $subroutine, ) = caller($levels_up);
		if(defined $subroutine and $subroutine eq "(eval)") {
			$levels_up++;
			redo;
		}
		$subroutine = "main::" unless $subroutine;
	}
	my $log_header = sprintf "[DEBUG %04d/%02d/%02d %02d:%02d:%02d %s %d %s %d %s] - ",
			Date::Calc::Today_and_Now() , $ENV{HOSTNAME}, $$, $file, $line, $subroutine;
	my @data = @_;
	print(
		$log_header, (join "\t" => map {
			ref($_) ? Dumper($_) : 
			defined $_ ? $_ : "`'" ; 
		} @data ),"\n"
	);
}

1;
__END__

=head1 NAME

POEIKC::Client - Client for POE IKC daemon

=head1 SYNOPSIS

	use POEIKC::Client;

	my $client = POEIKC::Client->new();

	my $options = {
		'alias' => 'POEIKCd',
		'port' => 47225
	};

	my ($state_name, $args) = $client->ikc_client_format($options, @ARGV) or die;

	$client->post_respond($options, $state_name, $args);


=head1 DESCRIPTION

POEIKC::Client is for poikc

=head1 AUTHOR

Yuji Suzuki E<lt>yujisuzuki@mail.arbolbell.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<POE::Component::IKC::ClientLite>

=cut
