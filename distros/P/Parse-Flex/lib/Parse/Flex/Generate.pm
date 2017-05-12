# Copyright (C) 2003 Ioannis Tambouras <ioannis@earthlink.net> . All rights reserved.
# LICENSE:  Latest version of GPL. Read licensing terms at  http://www.fsf.org .
 
package Parse::Flex::Generate;

use 5.006;
use warnings;
use strict;
use base 'Exporter';


our $VERSION  = '0.03';
our @EXPORT   =  qw( pm_content   makefile_content   xs_content 
		     Usage        check_argv
);


sub  check_argv {
	my ( $package, $grammar) = ($_[0], $_[1]||return) ;
	-f  $grammar       or   die  "did not find $grammar \n" ;
	-f "${package}.xs" and  warn "overiding $package}.xs  \n" ;
	-f "${package}.pm" and  warn "overiding ${package}.pm  \n" ;
}

sub Usage {
	my $package = shift;
	(my $tmp = <<"EOM" ) =~ s/^\t//m ;  $tmp;
	Usage: $0 [ hrn ]  grammar.l
		-n    module name.  [Currently set to $package]
                -k    keep compilation directory
                -l    command options passed to flex(1) [ defaults to -Cf ]
                -v    verbose
		-h    This help	
EOM
}


sub pm_content  {  
	my $p = shift || die;
	my $msg = <<"EOM" ;
	package $p;
	use XSLoader;
	XSLoader::load $p;
	use Parse::Flex;
	use base 'Exporter';

EOM
	($msg .= <<'EOM') =~  s/^\t//gm ;	
	our @EXPORT_OK = qw(
				yypop_buffer_state            make_yp
				yyset_debug    yyget_debug
				yyget_leng     yy_scan_bytes  create_push
	);


	our @EXPORT = qw( 
				yyout          yyin           yylex
				yyget_lineno   yyset_lineno   yyset_in
				walkthrough    gen_walker     yy_scan_string
				yyrestart      yapp_new       yapp_parse
	);
		
	sub  create_push {
		# need to move create_push for Flex.pm to here
		# we assume $fd is either glob or filename
		our  $fd    =  shift || return;
		open $fd, $fd   if ( 'SCALAR' eq typeme $fd);
		create_push_buffer( $fd, 16384 );
	}

	sub walkthrough {
		for (@_) {
			my ($iter, @a) = gen_walker( shift);
			print "@a"    while  @a = $iter->() ;
		}
	}

	sub control_yyin {
	     my $param = shift || return;
	     ({'SCALAR'    =>sub{ yyin($param)             },
	       'GLOB'      =>sub{ yyset_in($param)         },
	       'REF_SCALAR'=>sub{ yy_scan_string( $$param) },
	     }->{typeme($param)})->();
	}
	
	sub gen_walker {
		control_yyin( shift );
		sub  { wantarray ? yylex() : [yylex()] }
	}
	
	sub make_yp {
		my $grammar =  shift || 'grammar.yp' ;
		grep { -e "$_/yapp" }  split /:/, $ENV{PATH}
			or die q(You need yapp(1) in your $PATH.) ;
		-f $grammar  or die qq("$grammar". $!);
		
		(my $makefile = <<"EOM") =~ s/^\t//gm ;
		MyYapp.pm:  $grammar 
			yapp -m MyYapp  \$<
	EOM
		open my ($o),  "| make -s -f -";
		print $o $makefile;
	}
	
	
	sub yapp_new {
		my $parser = shift || 'MyYapp' ;
		$parser =~   s/\.pm$//;
		eval "use $parser" ;
		die qq(Did not find "$parser") if $@;
		bless \ $parser -> new();
	}
	
	sub yapp_parse {
		my ($p, $rc, $debug) =  @_ ;
		defined $rc and  -f $rc      || die qq("$rc". $!);
		my $walker = gen_walker ( $rc );
		my $err = sub{ printf qq(Error: got '%s' \n), $_[0]->YYCurval}; 
		print $$p->YYParse ( yylex => $walker, 
			 	     yyerror => $err,  debug=> $debug||0 ) ;
	}
	

	sub pbyacc_new {
		my ($rc, $parser, $debug) = @_ ;
		open my ($fd), $rc;
		($parser = $parser || 'MyByacc')   =~   s/\.pm$// ;
		eval "use $parser" ;
		die qq(Did not find "$parser") if $@;
		
		my $walker =  gen_walker( $rc);
		my $err    =  sub{ print qq(Error)  };
		
		# you can also enable debuging via $ENV{YYDEBUG} = 1
		bless \ $parser -> new( $walker, $err, $debug||0 );
	}
	
	sub pbyacc_parse {
		${$_[0]}->yyparse ;
	}
	
	
	1;

EOM
	$msg;
}



	sub makefile_content {
		my ($package, $grammar ) =  ( $_[0], $_[1]||return ) ;
		my ($lflags, $verbose)   =  ( $_[2], $_[3] ) ;
		$grammar =~ s{^.*/}{};
		(my $msg  = <<'EOM') =~ s/^\t//gm ;
	.PHONY:  try.pl
	.SILENT:

	OPTS  =  -lw  -MData::Dumper
	fopt  =  -Cf 
	ifdef n
	noerr = 2>/dev/null
	endif


	PFLAGS =  -I. -D_REENTRANT -D_GNU_SOURCE -DTHREADS_HAVE_PIDS -DDEBIAN -fno-strict-aliasing -pipe -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -O2   -DVERSION=\"0.01\" -DXS_VERSION=\"0.01\" -fPIC "-I/usr/lib/perl/5.8/CORE"

	PACK= Flexer

	OBJ = $(PACK).o  lex.yy.o

	#all: try.pl
	all: $(OBJ)  $(PACK).so  mv #clean
		
	try.pl:
		perl $(OPTS)  $@

	lex.yy.c: custom.l
		flex  $(fopt)  $^


	$(PACK).c: $(PACK).xs
		/usr/bin/perl /usr/share/perl/5.8/ExtUtils/xsubpp  -typemap /usr/share/perl/5.8/ExtUtils/typemap  $(PACK).xs $(noerr) > $(PACK).xsc && mv $(PACK).xsc $(PACK).c  


	$(PACK).o: $(PACK).c
		gcc -c -o $@  $(PFLAGS)  $^

	$(PACK).so: $(OBJ)
		gcc  -s -shared -L/usr/local/lib   -o $@  $^


	clean:
		rm -f $(OBJ)   *.o *.a  $(PACK).c  *.xs lex.yy.[co]

	mv:
		mv $(PACK).pm  $(PACK).so ..

	realclean: clean
		rm -f  $(PACK).so  $(PACK).pm



	$(PACK).pm: $(PACK).so
		echo $(PM_DATA)  > $@
EOM
	($msg =~ s/Flexer/$package/g) ; 
	($msg =~ s/custom[.]l/$grammar/g) ; 
	 $msg =~ s/fopt  =  -Cf /fopt  =  $lflags/   if $lflags;
	 $msg =~ s/ifdef n/ifndef n/                 if $verbose;
         $msg;
}

sub  xs_content {

	my $package = shift || die;
	(my $msg = <<'EOM' ) =~ s/Flexer/$package/g; 
	#include "EXTERN.h"
	#include "perl.h"
	#include "XSUB.h"
	
	extern  char    *yytext;
	extern  int     yy_flex_debug, yylineno, yyleng;
	extern  FILE   *yyin, *yyout ;
	extern  int     maxwrap;
	extern  char*  wrap[];
	
	
	
	MODULE = Flexer            PACKAGE = Flexer

	void
	yylex()
	   PPCODE:
	      char* id = 0;
	      if (id = (char*) yylex() ) {
		      XPUSHs (sv_2mortal(newSVpv(id,0)));
		      XPUSHs (sv_2mortal(newSVpv( yytext, 0)));
		      XSRETURN(2);
	      }
	      XSRETURN_EMPTY;

	void
	yylex_int()
	   PPCODE:
	      int id; 
	      if (id = (int) yylex() ) {
		      XPUSHs (sv_2mortal(newSViv(id)));
		      XPUSHs (sv_2mortal(newSVpv( yytext, 0)));
		      XSRETURN(2);
	      }
	      XSRETURN_EMPTY;


	void
	yyin( file )
	   char* file
	   CODE:
	     if ( (yyin=fopen(file,"r")) == NULL ) {
	     	     perror("yyin");
	     }


	void
	yyout( file )
	   char* file
	   CODE:
	     if ( (yyout=fopen(file,"w")) == NULL ) {
	            perror("yyout");
	     }


	void
	yyset_in( fd )
	   FILE  *fd
	   CODE:
	      yyin = fd;
	
	void
	yyset_out( fd )
	   FILE  *fd
	   CODE:
	      yyout = fd;
	 	
	FILE*
	yyget_in( )
	   CODE:
	      RETVAL = yyin;
	   OUTPUT:
	      RETVAL
	
	FILE*
	yyget_out( )
	   CODE:
	      RETVAL = yyout;
	   OUTPUT:
	      RETVAL
	
	int
	yyget_lineno()
	   CODE:
		RETVAL = yylineno ;
	   OUTPUT:
		RETVAL

	void
	yyset_lineno ( val )
	   int val
	   CODE:
	      yylineno = val;

	int
	yyget_leng()
	   CODE:
		RETVAL = yyleng ;
	   OUTPUT:
		RETVAL

	void
	yyset_debug ( flag )
	   int flag
	   CODE:
	      yy_flex_debug = flag;  
	
	int
	yyget_debug()
	   CODE:
	        RETVAL = yy_flex_debug ;
	   OUTPUT:
	       RETVAL

	char*
	yyget_text()
	   CODE:
	       RETVAL = yytext;
	   OUTPUT:
	       RETVAL
	
	void
	yy_scan_string( str )
	   char *str
	   CODE:
	      yy_scan_string( str );
	
	void
	yy_scan_bytes( str, len )
	   char *str
	   int  len
	   CODE:
	      yy_scan_bytes( str, len );
	
	void
	yyrestart( fd )
	   FILE *fd
	   CODE:
	        yyrestart( fd );
	
	void
	create_push_buffer( fd, size)
	   FILE *fd
	   int   size
	   CODE:
	      yypush_buffer_state( yy_create_buffer(fd,size) ) ;
	
	void
	yypop_buffer_state()
	   CODE:
	      yypop_buffer_state();


EOM
$msg =~ s/^\t//gm;  
$msg;
}

1;
__END__

=head1 NAME

Parse::Flex::Generate -  Internal driver routines for makelexer.pl

=head1 SYNOPSIS

 use Parse::Flex::Generate;

=head1 DESCRIPTION

This module is not intended to be used directly. It provides function
definitions for the makelexer.pl script.


=head1 EXPORT

All exported methods are of little value to the user: they are
all internal fuctions:
pm_content, makefile_content,  xs_content , Usage , check_argv

=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@earthlink.netE<gt>

=head1 SEE ALSO

None

=cut
