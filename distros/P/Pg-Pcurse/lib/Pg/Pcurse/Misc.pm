# Copyright (C) 2008 Ioannis Tambouras <ioannis@cpan.org>. All rights reserved.
# LICENSE:  GPLv3, eead licensing terms at  http://www.fsf.org .
package Pg::Pcurse::Misc;
use v5.8;
use Carp::Assert;
use Getopt::Long;
use Data::Dumper;
use User::pwent;
use File::Slurp qw( slurp );
use strict;
use warnings;
use base 'Exporter';
our $VERSION = '0.08';

our @EXPORT = qw(
	get_getopt
	process_options
	$bucardo_defaults
	schema_sorter
);

Getopt::Long::Configure qw(  auto_version auto_help );

sub get_getopt {
	my $o;
	GetOptions ( 'dbname:s' => \$o->{dbname},
		     'host:s'   => \$o->{host},
		     'user:s'   => \$o->{user},
		     'verbose'  => \$o->{verbose},
		     'passwd:s' => \$o->{passwd},
		     'port:i'   => \$o->{port},
		) or exit(1) ;
	$o;
}


sub passwd_from_pgpass {
	my $o  = shift;
	my $pw = getpwnam getlogin;
	my $pgpass = $pw->dir . '/.pgpass';
	return unless -r $pgpass;
	for (slurp $pgpass) {
		next if /^ \s*#/o ;
		chomp;
		next unless / $o->{user}:.*? $/xo ;
		my ($h,$p,$d,$u,$passwd) = split ':';
		next unless $passwd;
		next unless $h =~ /^ ($o->{host}|\*) $/xo;
		next unless $p =~ /^ ($o->{port}|\*) $/xo;
		next unless $d =~ /^ ($o->{dbname}|\*) $/xo;
		return $passwd ;
	};
	return;
}

sub process_options {
	my ($o, @argv) = @_;
	assert( ref$o, 'HASH' );
	$o->{user}   = $o->{user}   || $argv[1] || getlogin   ;
	$o->{host}   = $o->{host}   || 'localhost'            ;
	$o->{dbname} = $o->{dbname} || $argv[0] || 'template1';
	$o->{port}   = $o->{port}   || 5432                   ; 
	#$o->{verbose};
	$o->{passwd} = $o->{passwd} || passwd_from_pgpass($o) ;
	$o;
}
sub schema_sorter($$) {
	my ($aa,$bb) =  @_;
	($aa) = $aa =~ /(\w+)/g;
         $aa eq 'public'    and return -1;
         $aa =~ /^pg_/o     and return  1;
         $aa =~ /^inform/o  and return  1;
         -1;
}

our $bucardo_defaults = {
	ctl_checkabortedkids_time => 30  ,
	ctl_checkonkids_time      => 10  ,
	ctl_createkid_time        => 0.5 , 
	ctl_nothingfound_sleep    => 1.0 ,
	ctl_nothingfound_sleep    => 1.0 ,
	ctl_pingtime              => 600 ,
	default_email_from        => 'nobody@example.com',
	default_email_to          => 'nobody@example.com',
	endsync_sleep             =>  1.0 ,
	endsync_sleep             =>  1.0 ,
	kick_sleep                =>  0.2 ,
	kick_sleep                =>  0.2 ,
	kid_abort_limit           =>  3   ,
	kid_nodeltarows_sleep     =>  0.8 ,
	kid_nodeltarows_sleep     =>  0.8 ,
	kid_nothingfound_sleep    =>  0.1 ,
	kid_nothingfound_sleep    =>  0.1 ,
	kid_pingtime              =>  60  ,
	kid_serial_sleep          =>  10  ,
	kid_serial_sleep          =>  10  ,
	log_showline              =>  0   ,
	log_showpid               =>  0   ,
	log_showtime              =>  1   ,
	max_delete_clause         =>  200 ,
	max_select_clause         =>  500 ,
	mcp_dbproblem_sleep       =>  15  ,
	mcp_dbproblem_sleep       =>  15  ,
	mcp_loop_sleep            =>  0.1 ,
	mcp_loop_sleep            =>  0.1 ,
	mcp_pingtime              =>  60  ,
	piddir                    =>  '/var/run/bucardo',
	pidfile                   =>  'bucardo.pid',
	reason_file               =>  '/home/bucardo/restart.reason', 
	stats_script_url          =>  'http://www.bucardo.org/', 
	stopfile                  =>  'fullstopbucardo',
	syslog_facility           =>  'LOG_LOCAL1',
	tcp_keepalives_count      =>   2  ,
	tcp_keepalives_idle       =>   10 ,
	tcp_keepalives_interval   =>   5  ,
	upsert_attempts           =>   3  ,
};

1;
__END__
=head1 NAME

Pg::Pcurse::Misc  - Support module for Pg::Pcurse

=head1 SYNOPSIS

  use Pg::Pcurse::Query0;

=head1 DESCRIPTION

Support moule for Pg::Pcurse


=head1 SEE ALSO

Pg::Pcurse, pcurse(1)

=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms of GPLv3


=cut
