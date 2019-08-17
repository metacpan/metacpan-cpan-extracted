
package Net::Connection::lsof;

use 5.006;
use strict;
use warnings;
use Net::Connection;
use Proc::ProcessTable;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT=qw(lsof_to_nc_objects);

=head1 NAME

Net::Connection::lsof - This uses lsof to generate a array of Net::Connection objects.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';


=head1 SYNOPSIS

    use Net::Connection::lsof;

    my @objects;
    eval{ @objects = &lsof_to_nc_objects; };

    # this time don't resolve ports, ptrs, or usernames
    my $args={
             ports=>0,
             ptrs=>0,
             uid_resolve=>0,
             };
    eval{ @objects = &lsof_to_nc_objects($args); };

=head1 SUBROUTINES

=head2 lsof_to_nc_objects

This runs 'lsof -i UDP -i TCP -n -l -P' and parses the output
returns a array of L<Net::Connection> objects. If a non-zero exit code is
returned, it will die.

There is one optional argument and that is hash reference that can take
several possible keys.

=head3 args hash

=head4 ports

Attempt to resolve the port names.

Defaults to 1.

=head4 ptrs

Attempt to resolve the PTRs.

Defaults to 1.

=head4 uid_resolve

Attempt to resolve the UID to a username.

Defaults to 1.

=head4 proc_info

Add assorted process information to the objects.

Defaults to 1.

    my @objects;
    eval{ @objects = &lsof_to_nc_objects( $args ); };

=cut

sub lsof_to_nc_objects{
	my %func_args;
	if(defined($_[0])){
		%func_args= %{$_[0]};
	};

	if ( !defined( $func_args{ptrs} ) ){
		$func_args{ptrs}=1;
	}
	if ( !defined( $func_args{ports} ) ){
		$func_args{ports}=1;
	}
	if ( !defined( $func_args{uid_resolve} ) ){
		$func_args{uid_resolve}=1;
	}
	if ( !defined( $func_args{proc_info} ) ){
		$func_args{proc_info}=1;
	}

	my $output_raw=`lsof -i UDP -i TCP -n -l -P`;
	if (
		( $? ne 0 ) &&
		(
		 ( $^O =~ /linux/ ) &&
		 ( $? ne 256 )
		 )
		){
		die('"lsof -i UDP -i TCP -n -l -P" exited with a non-zero value or in the case of some linux distros a non-1 value');
	}
	my @output_lines=split(/\n/, $output_raw);

	my @nc_objects;

	# process info caches
	my %pid_proc;
	my %pid_pctmem;
	my %pid_pctcpu;
	my %pid_wchan;
	my %pid_start;

	my $proc_table;
	my $physmem;
	if ( $func_args{proc_info} ){
		my $pt=Proc::ProcessTable->new;
		$proc_table=$pt->table;
		if ( $^O =~ /bsd/ ){
			$physmem=`/sbin/sysctl -a hw.physmem`;
			chomp( $physmem );
			$physmem=~s/^.*\: //;
		}
	}

	my $line_int=1;
	while ( defined( $output_lines[$line_int] ) ){
		my $command=substr $output_lines[$line_int], 0, 9;
		my $line=substr $output_lines[$line_int], 10;

		$line=~s/^[\t ]*//;

		my @line_split=split(/[\ \t]+/, $line );

		my $args={
				  pid=>$line_split[0],
				  uid=>$line_split[1],
				  ports=>$func_args{ports},
				  ptrs=>$func_args{ptrs},
				  uid_resolve=>$func_args{uid_resolve},
				  };

		my $type=$line_split[3];
		my $mode=$line_split[6];
		my $name=$line_split[7];

		# Use the name and type to build the proto.
		my $proto='';
		if ( $type =~ /6/ ){
			$proto='6';
		}elsif( $type =~ /4/ ){
			$proto='4';
		}
		if ( $mode =~ /[Uu][Dd][Pp]/ ){
			$proto='udp'.$proto;
		}elsif( $mode =~ /[Tt][Cc][Pp]/ ){
			$proto='tcp'.$proto;
		}
		$args->{proto}=$proto;

		my ( $local, $foreign )=split( /\-\>/, $name );

		my $ip;
		my $port;

		if ( ! defined( $foreign ) ){
			$args->{foreign_host}='*';
			$args->{foreign_port}='*';
		}else{
			if ( $foreign =~ /\]/ ){
				( $ip, $port ) = split( /\]/, $foreign );
				$ip=~s/^\[//;
				$port=~s/\://;
			}else{
				( $ip, $port ) = split( /\:/, $foreign );
			}

			$args->{foreign_host}=$ip;
			$args->{foreign_port}=$port;
		}

		if ( $local =~ /\]/ ){
			( $ip, $port ) = split( /\]/, $local );
			$ip=~s/^\[//;
			$port=~s/\://;
		}else{
			( $ip, $port ) = split( /\:/, $local );
		}
		$args->{local_host}=$ip;
		$args->{local_port}=$port;

		$args->{state}='';
		if ( defined( $line_split[8] ) ){
			$args->{state}=$line_split[8];
			$args->{state}=~s/[\(\)]//g;
		}

		#
		# put together process info if requested
		#
		if ( $func_args{proc_info} ){
			if ( defined( $pid_proc{ $args->{pid} } ) ){
				$args->{proc}=$pid_proc{ $args->{pid} };
				$args->{wchan}=$pid_wchan{ $args->{pid} };
				$args->{pctmem}=$pid_pctmem{ $args->{pid} };
				$args->{pctcpu}=$pid_pctcpu{ $args->{pid} };
				$args->{pid_start}=$pid_start{ $args->{pid} };
			}else{
				my $loop=1;
				my $proc_int=0;
				while(
					  defined( $proc_table->[ $proc_int ] ) &&
					  $loop
					  ){

					# matched
					if ( $proc_table->[ $proc_int ]->{pid} eq $args->{pid} ){
						# exit the loop
						$loop = 0;

						# fetch and save the proc info
						if ( $proc_table->[ $proc_int ]->cmndline =~ /^$/ ){
							# kernel proc
							$args->{proc}='['.$proc_table->[ $proc_int ]->{fname}.']';
						}else{
							# non-kernel proc
							$args->{proc}=$proc_table->[ $proc_int ]->{cmndline};
						}
						$pid_proc{ $args->{pid} }=$args->{proc};

						# linux has shit wchan reporting and apparently if you want more than
						# the address you need to use the ass backwards /proc
						if ( $^O =~ /linux/ ){
							if ( -e '/proc/'.$args->{pid}.'/wchan'){
								open( my $wchan_fh, '<', '/proc/'.$args->{pid}.'/wchan' );
								$args->{wchan}=readline( $wchan_fh );
								close( $wchan_fh );
								$pid_wchan{ $args->{pid} }=$args->{wchan};
							}
						}else{
							$args->{wchan}=$proc_table->[ $proc_int ]->{wchan};
							$pid_wchan{ $args->{pid} }=$args->{wchan};
						}

						$args->{pid_start}=$proc_table->[ $proc_int ]->{pid_start};
						$pid_start{ $args->{pid} }=$args->{pid_start};

						$args->{pctcpu}=$proc_table->[ $proc_int ]->{pctcpu};
						$pid_pctcpu{ $args->{pid} }=$args->{pctcpu};

						if ($^O =~ /bsd/){
							$args->{pctmem}= (( $proc_table->[ $proc_int ]->{rssize} * 1024 * 4 ) / $physmem) * 100;
						}else{
							$args->{pctmem}=$proc_table->[ $proc_int ]->{pctmem};
						}
						$pid_pctmem{ $args->{pid} }=$args->{pctmem};
					}

					$proc_int++;
				}
			}
		}

		push( @nc_objects, Net::Connection->new( $args ) );

		$line_int++;
	}

	return @nc_objects;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-connection-lsof at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Connection-lsof>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Connection::lsof


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Connection-lsof>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Connection-lsof>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-Connection-lsof>

=item * Search CPAN

L<https://metacpan.org/release/Net-Connection-lsof>

=item * Git Repo

L<https://gitea.eesdp.org/vvelox/Net-Connection-lsof>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::Connection::lsof
