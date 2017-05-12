
# Copyright (C) 2008 Ioannis Tambouras <ioannis@cpan.org>. All rights reserved.
# LICENSE:  GPLv3, eead licensing terms at  http://www.fsf.org .

package Pg::Loader::Update;

use 5.010000;
use DBI;
use Fatal qw(open);
use Data::Dumper;
use Time::HiRes qw( gettimeofday tv_interval );
use strict;
use warnings;
use Pg::Loader::Query qw/  update_string create_tmp_table/;
use Pg::Loader::Misc qw( error_check filter_ini pk4updates 
			reformat_values add_modules update_semantic_check
);
use Pg::Loader::Copy  qw/ _stop_input _no_pk_found load_2table/;
use Pg::Loader::Columns;
use Pg::Loader::Log;
use Log::Log4perl  qw( :easy );
use base 'Exporter';
use SQL::Abstract;
use Storable qw( dclone );
#create_tmp_table 

our $VERSION = '0.17';

our @EXPORT = qw( update_loader ) ;

sub update_loader {
	my ( $conf, $ini, $dh, $section ) = @_                 ;
	my   $s    =  $ini->{$section}                         ;
	my   $dry  =  $conf->{dry}                             ;

	INFO("UPDATE, as per  [$section]")                     ;
        $ini->{$section}{table}      = $conf->{relation} if $conf->{relation} ;
        $ini->{$section}{copy_every} = 1                 if $conf->{every}    ;
	error_check(      $ini, $section        )                             ;
	filter_ini(       $ini->{$section}, $dh )                             ;
	pk4updates($dh, $ini->{$section}) or return _no_pk_found($ini,$section);
 	eval { update_semantic_check(  $ini->{$section} ) ; 1 
             } or return { name=>$section, elapsed=>0, 
                    rows=>0, errors=>'config', size=>$s->{copy_every} };
	reformat_values(  $ini->{$section}, $dh )              ;
	add_modules(      $ini->{$section}, $dh )              ;

        # Prepare for internal COPY
        my $c_conf = dclone( $conf );
        my $c_ini  = dclone( $ini  );
        my $c_s    = $c_ini->{$section} ;
 	@{$c_conf}{'indexes','disable_triggers','vacuum'}  = qw( 0 0 0) ;
	push @{$c_s->{copy_columns}}, $ _     for  @{$s->{pk}};
 	@{$c_s}{'table',} = qw( d ) ;

	# Load to internal table
	create_tmp_table( $dh, $s->{table} );
        my $ret = load_2table ( $c_conf, $c_ini, $dh, $section )  ;
	return $ret if $ret->{errors};

	DEBUG "\tUpdating " . $s->{table}  ;
	my $t0  =  [gettimeofday];
	my $sql = update_string('d', @{$s}{'table','copy_columns','pk'} );
	DEBUG "\t\t$sql";
	unless ($dry) {
	         $dh->begin_work;
		 if ( my $total = $dh->do($sql) ) {
			 $dh->commit ;
			  return
                         { name=> $section, 
                           elapsed => $ret->{elapsed}+tv_interval($t0),
                           rows=> $total//0, errors  => $ret->{errors}//0,
                           size=> $s->{copy_every},
			 }
		 }else{
			$dh->rollback;
			  return
                         { name=> $section, elapsed => $ret->{elapsed}//0,
                           rows=> 0,        errors  => $ret->{errors}//0,
                           size=> $s->{copy_every},
			 }
		}
	}
}


1;
__END__

=over

=item dist_abstract

=back

Perl extension for loading and updating Postgres tables


=head1 NAME

Pg::Loader::Copy - The update operation 

=head1 SYNOPSIS

  use Pg::Loader;

=head1 DESCRIPTION

This is a helper module for pgloader.pl(1), it loads and updates 
tables in a Postgres database. It is similar in function to 
the pgloader(1) python program (written by other authors) with
enhancements plus the ability to update tables.

=head2 EXPORT

Pg::Loader - Perl extension for loading and updating Postgres tables


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
