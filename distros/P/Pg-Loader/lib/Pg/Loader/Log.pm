
# Copyright (C) 2008 Ioannis Tambouras <ioannis@cpan.org>. All rights reserved.
# LICENSE:  GPLv3, eead licensing terms at  http://www.fsf.org .

package Pg::Loader::Log;

use 5.010000;
use Data::Dumper;
use Log::Log4perl qw( :easy );
use Log::Log4perl::Layout;
use Log::Log4perl::Level;
use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.12';
our @EXPORT = qw(
              l4p_config                _main_logger
	      log_rejected_data         log_reject_errors
);

sub l4p_config {
        my ($c, $rej_data, $rej_log)     =  @_ ;
        $c->{loglevel} //= 2;
        $c->{loglevel} < 1  and $c->{loglevel} = 1;
        $c->{loglevel} > 4  and $c->{loglevel} = 4;
        $c->{verbose}       and $c->{loglevel} = 3;
        $c->{debug}         and $c->{loglevel} = 4;
        $c->{quiet}         and $c->{loglevel} = 1;
        my $level = (5-$c->{loglevel})*10_000 ;
        _main_logger() ->level( $level//$INFO ); 
}

sub _main_logger {
	my $main     = get_logger('Pg::Loader');
	my $layout   = Log::Log4perl::Layout::PatternLayout->new( '%m%n' ); 
	my $appender = Log::Log4perl::Appender->new( 
                                             'Log::Log4perl::Appender::File',
                                              mode      => 'append',
                                              name      => 'stdio',
                                              filename  => '/dev/tty');
           # config logger
           $appender->layout( $layout );
           $main->add_appender( $appender);
	   $main;
}

sub  _stack_logger {
	my ($file, $mode, $pattern)  =  @_ ;
	return unless $file || $mode ;
	$pattern //= '%m%n'; 

        ### Set each logger to a different name
	state $name++;
	my $l        = get_logger( $name );
	my $layout   = Log::Log4perl::Layout::PatternLayout->new( $pattern ); 
	my $appender = new Log::Log4perl::Appender
                                             'Log::Log4perl::Appender::File',
                                              mode            =>  $mode  ,
                                              filename        =>  $file  ,
                                              recreate        =>  0,
                                              recreate_signal => 'USR1';
                                                
       ### Config Logger
       $appender->layout( $layout );
       $l->add_appender( $appender);
       $l->level( $INFO );
       $l;
}


sub  log_reject_errors {
	my ( $s, $errstr, $section ) = @_;
	return unless  $s->{reject_log};
	my $file = $s->{reject_log};
	state  $last_section ;
	$last_section //= 'new';
	my $l;
	if ( $last_section ne $section ) {
		$last_section = $section;
		$l = _stack_logger ($file, 'clobber', '%m%n') ;
	}else{
		$l = _stack_logger ($file, 'append', '%m%n' ) ;
	};
	$l->info( $errstr )  if $errstr;
}



sub  log_rejected_data {
	# Error Checking
	my ( $s,  $section) = @_ ;
	return unless $s->{reject_data};
	my $file = $s->{reject_data};
 	return unless Log::Log4perl::NDC->get();
	state  $last_section ;
	$last_section //= 'new';
	my $l;
	if ( $last_section ne $section ) {
		$last_section = $section;
		$l = _stack_logger ($file, 'clobber', ' %x%n') ;
	}else{
		$l = _stack_logger ($file, 'append' , ' %x%n') ;
	};
	$l->info(  ) ;
 	Log::Log4perl::NDC->remove;
}


1;
__END__
=head1 NAME

Pg::Loader::Log - Helper module for Pg::Loader

=head1 SYNOPSIS

  use Pg::Loader::Log;

=head1 DESCRIPTION

This is a helper module for pgloader.pl(1). It controls messages
for rejected entries.


=head2 EXPORT


Pg::Loader::Log - Helper module for Pg::Loader


=head1 SEE ALSO

http://pgfoundry.org/projects/pgloader/  hosts the original python
project.


=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
   
