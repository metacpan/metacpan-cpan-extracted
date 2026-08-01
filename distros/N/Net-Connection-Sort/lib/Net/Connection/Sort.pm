package Net::Connection::Sort;

use 5.006;
use strict;
use warnings;

=head1 NAME

Net::Connection::Sort - Sorts array of Net::Connection objects.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';


=head1 SYNOPSIS

    use Net::Connection::Sort;
    use Net::Connection;
    use Data::Dumper;
    
     my @objects=(
                  Net::Connection->new({
                                        'foreign_host' => '3.3.3.3',
                                        'local_host' => '4.4.4.4',
                                        'foreign_port' => '22',
                                        'local_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4'
                                        }),
                  Net::Connection->new({
                                        'foreign_host' => '1.1.1.1',
                                        'local_host' => '2.2.2.2',
                                        'foreign_port' => '22',
                                        'local_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4'
                                        }),
                  Net::Connection->new({
                                        'foreign_host' => '5.5.5.5',
                                        'local_host' => '6.6.6.6',
                                        'foreign_port' => '22',
                                        'local_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4'
                                        }),
                  Net::Connection->new({
                                        'foreign_host' => '3.3.3.3',
                                        'local_host' => '4.4.4.4',
                                        'foreign_port' => '22',
                                        'local_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4'
                                        }),
                 );
    
    my $sort_args={
                  type=>'host_f',
                  invert=>0,
                  };
    
    my $mcs;
    eval{
        $mcs=Net::Connection::Sort->new( $sort_args );
    };
    
    if ( ! defined( $mcs ) ){
        print "Failed to init the sorter... ".$@;
    }
    
    my @sorted=$mcs->sorter( \@objects );
    
    print Dumper( \@sorted );

=head1 METHODS

=head2 new

This initiates the module.

One argument is taken and that is a hash ref with two possible keys,
'type' and 'invert'. If not passed or any of the keys are undef, then
the defaults will be used.

'type' is the module to use. It is relative to 'Net::Connection::Sort',
so 'host_f' becomes 'Net::Connection::Sort::host_f'. Only word characters
are accepted here and anything else will result in it dying. See
L</SORT TYPES> below for the list of what may be used.

'invert' reverses the order returned by the sorter if set to true.

    my $sort_args={
                  type=>'host_f',
                  invert=>0,
                  };
    
    my $mcs;
    eval{
        $mcs=Net::Connection::Sort->new( $sort_args );
    };
    
    if ( ! defined( $mcs ) ){
        print "Failed to init the sorter... ".$@;
    }

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};


	my $self = {
				testing=>0,
				type=>'host_f',
				invert=>0,
				sorter=>undef,,
				};
    bless $self;

	# real in the args if needed
	if (defined( $args{type} )){
		$self->{type}=$args{type};
	}
	if (defined( $args{invert} )){
		$self->{invert}=$args{invert};
	}

	# The type is used to build a module name and path below, so make sure it
	# is nothing more than a bare module name. Anything else is a injection
	# attempt and the type is likely to have come from something such as a
	# command line switch. The capture is also used to untaint it.
	if ( $self->{type} =~ /^([A-Za-z0-9_]+)$/ ){
		$self->{type}=$1;
	}else{
		die( '"'.$self->{type}.'" is not a usable sort type name');
	}

	my $module='Net::Connection::Sort::'.$self->{type};

	# see of we amd reel in the module
	eval{
		require 'Net/Connection/Sort/'.$self->{type}.'.pm';
		$self->{sorter}=$module->new;
	};
	if ( $@ ){
		die('Failed to use or invoke '.$module.'->new... '.$@);
	}

	# make sure we did get it
	if (!defined( $self->{sorter} )){
		die( $module.'->new returned undef');
	}

	return $self;
}

=head2 sorter

This sorts the array of Net::Connection objects.

One object is taken and that is a array of objects. Anything else will
result in it dying.

    my @sorted=$mcs->sorter( \@objects );

    print Dumper( \@sorted );

=cut

sub sorter{
	my $self=$_[0];
	my @objects;
	if (
		defined( $_[1] ) &&
		( ref($_[1]) eq 'ARRAY' )
		){
		@objects=@{ $_[1] };
	}else{
		die 'The passed item is either not a array or undefined';
	}

	my @sorted=$self->{sorter}->sorter( \@objects );

	if ( $self->{invert} ){
		return reverse( @sorted );
	}

	return @sorted;
}

=head1 SORT TYPES

Any of the below may be used as the 'type' when calling new. Anything else
will result in new dying.

=over 4

=item host_f - Host, foreign

=item host_fl - Host, foreign then local

=item host_l - Host, local

=item host_lf - Host, local then foreign

=item pid - Process ID

=item port_f - Port, foreign, numeric

=item port_fa - Port, foreign, alpha

=item port_l - Port, local, numeric

=item port_la - Port, local, alpha

=item proto - Network connection protocol

=item ptr_f - PTR, foreign

=item ptr_l - PTR, local

=item state - Connection state

=item uid - User ID

=item unsorted - Leaves the order as is

=item user - Username

=back

The alpha port types sort on the service name where there is one. Ports
without a service name sort after those with one, numerically.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-connection-sort at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Connection-Sort>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Connection::Sort


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Connection-Sort>

=item * Search CPAN

L<https://metacpan.org/release/Net-Connection-Sort>

=item * Git Repo

L<https://gitea.eesdp.org/vvelox/Net-Connection-Sort>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::Connection::Sort
