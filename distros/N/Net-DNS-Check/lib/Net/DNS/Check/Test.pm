package Net::DNS::Check::Test;

use strict;
use vars qw($VERSION);

use Carp;
use Net::DNS::Check::Config;
use Net::DNS::Check::Test::unknown;

# use vars qw( %_LOADED );

my %PUBLIC_ARGS = map { $_ => 1 } qw(
	config
	domain
	type
	nsquery
	nsauth
	hostslist
	debug
);


sub new {
	my ($class) 	= shift;

	unless ( @_ ) {
		# Some error 
		return;
	}
   
	my (%args)	= @_;


	my $subclass = _get_subclass($class, $args{type} );
        
	if ($subclass) {
		my $self =  $subclass->new(@_);
# 		$self->{test_detail} = {};
		return $self;
	} else { 
		return new Net::DNS::Check::Test::unknown();
	}
}


# Defined in subclass 
sub test {

}



# 
sub test_status {
	my $self = shift;
	return $self->{test_status};
}


# 
sub test_detail {
	my $self = shift;
	my $key = shift;

	if ($key) {
		if ( exists $self->{test_detail}->{$key} ) {
			return %{ $self->{test_detail}->{$key} };
		} else {
			return (); 
		}
	} else {
		return %{ $self->{test_detail} };

	}
}


sub test_detail_desc {
	my $self = shift;
	my $key = shift;

	if ($key && exists $self->{test_detail}->{$key} ) {
		return $self->{test_detail}->{$key}->{desc};
	} else {
		return; 
	}
}

sub test_detail_status {
	my $self = shift;
	my $key = shift;

	if ($key && exists $self->{test_detail}->{$key} ) {
		return $self->{test_detail}->{$key}->{status};
	} else {
		return; 
	}
}




sub _process_args {
	my ($self, %args) = @_;

	foreach my $attr ( keys %args) {
		next unless $PUBLIC_ARGS{$attr};
		
		# Controllare se effettivamente funziona questo test
		if ($attr eq 'nsquery' || $attr eq 'nsauth') {
			unless ( UNIVERSAL::isa($args{$attr}, 'ARRAY') )  { 
				die "Net::DNS::Check::Test->new(): $attr must be an arrayref\n";
			}
		}

		$self->{$attr} = $args{$attr};
	}

	$self->{config} ||= new Net::DNS::Check::Config();

	$self->{debug} 	||=  $self->{config}->debug_default();
}


sub _get_subclass {
	my ($class, $type) = @_;

	return unless $type; 

	my $subclass = join('::', $class, $type);

	# probably this is useless because "require" function 
	# load files only once
	#unless ($_LOADED{$subclass}) {
		eval "require $subclass";
		if ( $@ ) {
			carp $@;	
			$subclass = '';
		} #else {
		#	$_LOADED{$subclass}++;
		#}
	#}

	return $subclass;
}


sub DESTROY {}

1;

__END__

=head1 NAME

Net::DNS::Check::Test - base class for all type of tests 

=head1 SYNOPSIS

C<use Net::DNS::Check::Test>

=head1 DESCRIPTION

This is the base class for all type of tests. 


=head1 METHODS

=cut

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

