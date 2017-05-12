# Copyright (C) 2008 Ioannis Tambouras <ioannis@cpan.org>. All rights reserved.
# LICENSE:  GPLv3, eead licensing terms at  http://www.fsf.org .

package Pg::Loader::Misc_2;

use 5.010000;
use Data::Dumper;
use strict;
use warnings;
#use Config::Format::Ini;
use Log::Log4perl ':easy';
#use Text::CSV;
#use Pg::Loader::Columns;
#use Pg::Loader::Query;
use Pg::Loader::Log;
#use List::MoreUtils  qw( firstidx );
use base 'Exporter';
#use Quantum::Superpositions ;
use Text::Table;


our $VERSION = '0.01';

our @EXPORT = qw(
	sample_config  show_sections add_defaults
);

sub  sample_config {
	(my $tmp = <<EOM ) =~ s/^\t//gmo ;
	[pgsql]
	base  = people
	pass  = apple
	#host = localhost
	#pgsysconfdir=.
	#service=

	[exam]
	filename      = exam.dat
	table         = public.exam
	#copy         = *
	#copy_columns = id, name
	#only_cols    = 1-2,4,5
	#use_template = cvs1
	#copy_every=10000

	[cvs1]
	#template=true
	#format=cvs
	#doublequote=false
	#escapechar=|
	#quotechar="
	#skipinitialspace=true
	#reject_log=rej_log
	#reject_data=rej_data
	#reformat= fn:John::Util::jupper, score:John::Util::changed
	#null=\\NA
	#trailing_sep=true
	#datestyle=euro
	#client_encoding=
	#lc_messages=C
	#lc_numeric=C
	#lc_monetary=en_US
	#lc_type=C
	#lc_time=POSIX

EOM
	$tmp;
}




sub _merge_with_template {
        ## Output: add columns into $s
        my ( $s, $ini, $template) = @_;
	return                                  unless $template;
	LOGEXIT "Missing template [$template]"  unless $ini->{$template};
        $s->{$_} //= $ini->{$template}{$_}      for  keys %{$ini->{$template}};
}

sub add_defaults {
	my ( $ini, $section) = @_ ;
	LOGEXIT "invalid section name"              unless $section    ;
	my $s      =  $ini->{$section}                                 ;
	LOGEXIT "Missing section [$section]"        unless $s          ;
        _merge_with_template( $s, $ini, $s->{use_template} ) ;
	_switch_2_update( $s );

        $s->{ format      }   //=  'text'                            ;
	$s->{ copy        }   //= '*'                                ;  
	$s->{ copy_every  }   //=  10_000                            ;
        $s->{ filename    }   //=  'STDIN'                           ;
        $s->{ table       }   //=   $section                         ;
	$s->{ quotechar   }   //=  '"'                               ;
	$s->{ reject_data }   //=   ''                               ;
	$s->{ reject_log  }   //=   ''                               ;
	$s->{ lc_messages }   //=   ''                               ;
	$s->{ lc_numeric  }   //=   ''                               ;
	$s->{ lc_monetary }   //=   ''                               ;
	$s->{ lc_type     }   //=   ''                               ;
	$s->{ lc_time     }   //=   ''                               ;
	$s->{ datestyle   }   //=   ''                               ;
	$s->{ client_encoding } //= ''                               ;

	$s->{copy_columns} = $s->{copy} 
                        unless ($s->{only_cols}||$s->{copy_columns});

	if (  $s->{ format } =~ /^ '? text '?$/ox  ) { 
	        # format is 'text'
                $s->{null} //= '$$\NA$$'            ;
		$s->{null}   = '$$'.$s->{null}.'$$' if $s->{null} ne '$$\NA$$';
		$s->{ field_sep  }   //=  "\t"      ;
	}else{
	        # format is 'csv'
		$s->{null} //= '$$$$'               ;
		$s->{null}   = '$$'.$s->{null}.'$$' if  $s->{null} ne '$$$$';
		$s->{ field_sep  }   //= ','        ;
	}
}



sub _switch_2_update {
	my  $s  = shift;;
	# First, some error checking
	eval {
		$s->{ copy         } && $s->{ update         }  and die;
		$s->{ copy         } && $s->{ update_columns }  and die;
		$s->{ copy         } && $s->{ update_only    }  and die;
		$s->{ copy_columns } && $s->{ update         }  and die;
		$s->{ copy_columns } && $s->{ update_columns }  and die;
		$s->{ copy_columns } && $s->{ update_only    }  and die;
		$s->{ copy_only    } && $s->{ update         }  and die;
		$s->{ copy_only    } && $s->{ update_columns }  and die;
		$s->{ copy_only    } && $s->{ update_only    }  and die;
	1;
	} or  LOGDIE  qq(\tCannot mix "copy" with "update" columns) ;
	#TODO "update_only" should populate "update_columns"
	$s->{ update_only } and  LOGDIE qq(\t"update_only" not implemeted");
	# Should we switch to update mode?
	exists $s->{ update_columns }  and  $s->{mode}='update';
        exists $s->{ update_only }     and  $s->{mode}='update';
        exists $s->{ update }          and  $s->{mode}='update';
        ## key statement
	$s->{mode} //= 'copy' ;
	if ($s->{mode} eq 'update') {
		$s->{copy_columns} = $s->{update_columns}//$s->{update};
		$s->{copy_only}    = $s->{update_columns}//'';
		$s->{copy}         = $s->{update};
	}
	$s->{mode};
}
sub show_sections {
        my ($conf, $ini) = @_;
        my $port = ':'. ($ini->{port}||5432)  ;
        my $t    = new Text::Table  'SECTION   '  , 'TABLE    ',
                                    'FILE      '  , 'OPERATION' ;
        DEBUG  "$ini->{pgsql}{base}\@$ini->{pgsql}{host}$port"   ;
        while (my ($k,$v) = each %$ini) {
                my $s = $ini->{$k};
                next if $k eq 'pgsql';
                next if exists $s->{template};
                next if $s->{template};
                add_defaults  $ini, $k ;
                _switch_2_update $s ;
                my $file = $s->{filename}||'STDIN';
                #say  sprintf  '%-18s %-20s', "[$k]", $file ;
                $t->load( [ "[$k]", $s->{table}, $file,  $s->{mode} ] );
        }
        print $t;
}

1;
__END__
=pod
