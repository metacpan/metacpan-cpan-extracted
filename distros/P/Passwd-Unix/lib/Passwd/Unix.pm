package Passwd::Unix;
$Passwd::Unix::VERSION = '1.09';
use parent 		qw( Exporter::Tiny );
use warnings;
use strict;
#-----------------------------------------------------------------------
use Config;
use Crypt::Password;
use IO::Compress::Bzip2 	qw( bzip2 $Bzip2Error );
use Path::Tiny;
use Tie::Array::CSV;
#-----------------------------------------------------------------------
use constant DAY => 86400;
use constant SEP => q[:];

use constant ALG => q[sha512];
use constant BCK => 1;
use constant CMP => 1;
use constant DBG => 0;
use constant WRN => 0;
use constant MSK => 0022;

use constant PWD => q[/etc/passwd];
use constant GRP => q[/etc/group];
use constant PSH => q[/etc/shadow];
use constant GSH => q[/etc/gshadow];
#=======================================================================
our @EXPORT_OK	= qw(
	
	backup
	compress
	debug
	warnings
	error
	
	encpass 
	
	exists_user 
	exists_group
	
	passwd_file 
	group_file 
	shadow_file 
	gshadow_file
	
	user
	uid 
	gid 
	gecos 
	home 
	shell 
	passwd 
	rename 
	
	del 
	del_user  
	
	group
	del_group
	
	users 
	users_from_shadow
	
	minuid
	mingid
	
	maxuid
	maxgid
	
	unused_uid 
	unused_gid
	
	groups 
	groups_from_gshadow
	
	reset
	
	default_umask
);
#======================================================================
my $Self = __PACKAGE__->new();
#======================================================================
sub new {
	my ( $class, %opt ) = @_;
	
	my $self = bless { }, $class;
	
	$self->algorithm	( $opt{ algorithm 	} // ALG );
	$self->backup	 	( $opt{ backup  	} // BCK );
	$self->compress 	( $opt{ compress  	} // CMP );
	$self->debug	 	( $opt{ debug 	 	} // DBG );
	$self->default_umask( $opt{ umask 		} // MSK );
	$self->warnings	 	( $opt{ warnings 	} // WRN );
	
	
	$self->passwd_file	( $opt{ passwd  	} // PWD );
	$self->group_file	( $opt{ group   	} // GRP );
	$self->shadow_file	( $opt{ shadow		} // PSH );
	$self->gshadow_file	( $opt{ gshadow 	} // GSH );
	
	return $self;
}
#=======================================================================
sub _err {
	my ( $self, @str ) = @_;
	
	$self->{ err } = join( q[], @str );
	warn $self->{ err } if $self->{ wrn };
	
	return;
}
#=======================================================================
sub _dat {
	my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime( time );
	
	$year += 1900;
	$mon  += 1;
	
	$sec  = q[0] . $sec  if $sec  =~ /^\d$/o;
	$min  = q[0] . $min  if $min  =~ /^\d$/o;
	$hour = q[0] . $hour if $hour =~ /^\d$/o;
	$mday = q[0] . $mday if $mday =~ /^\d$/o;
	$mon  = q[0] . $mon  if $mon  =~ /^\d$/o;
	
	return $year . q[.] . $mon . q[.] . $mday . q[-] . $hour . q[.] . $min . q[.] . $sec;
}
#=======================================================================
sub _bck {
	my ( $self ) = @_;
	
	#-------------------------------------------------------------------
	return unless $self->{ bck };
	
	#-------------------------------------------------------------------
	my $dir = path( $self->{ pwd } . q[.bak], _dat() );
	
	if( $dir->exists ){
		return $self->_err( $dir . " is a file. It should be a directory.\n" ) if $dir->is_file;
	}else{
		$dir->mkpath;
	}
	
	#-------------------------------------------------------------------
	for my $dis ( qw( pwd grp psh gsh ) ){
		my $src = path( $self->{ $dis } );
		my $dst = $dir->child( $src->basename . q[.bz2] );
		
		if( $self->{ cmp } ){
			$dst->touch;
			$dst->chmod( $src->stat->mode  );
			bzip2 $src->stringify => $dst->stringify or return $self->_err( $Bzip2Error );
		}else{
			$src->copy( $dst );
		}
	}
	
	#-------------------------------------------------------------------
	return 1;
}
#=======================================================================
sub del_group {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( @val ) = @_;
	
	return $self->_err( q[Supplied value is undefined.] 	) unless @val;
	#return $self->_err( q[Supplied group does not exists.] 	) unless _exs( $self->{ grp }, $val );
	return $self->_err( q[Unsufficient permissions.] 		) unless open my $fhd, '>>', $self->{ gsh };
	
	close( $fhd );
	
	#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$self->_bck or return;
	#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	tie my @ary, q[Tie::Array::CSV], $self->{ grp }, { 
		tie_file => { 
			autochomp => 1, 
		}, 
		text_csv => { 
			sep_char 	=> SEP,
			binary 		=> 1,
			quote_char => undef,
		},
	};
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	tie my @yra, q[Tie::Array::CSV], $self->{ gsh }, { 
		tie_file => { 
			autochomp => 1, 
		}, 
		text_csv => { 
			sep_char 	=> SEP,
			binary 		=> 1,
			quote_char => undef,
		},
	};
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	
	for my $val ( @val ){
		my $sav;
		for my $idx ( 0 .. $#ary ){
			next if $ary[ $idx ][ 0 ] ne $val;
			splice @ary, $idx, 1;
			$sav = $idx;
			last;
		}
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		if( $yra[ $sav ][ 0 ] eq $val ){
			splice @yra, $sav, 1;
		}else{
			for my $idx ( 0 .. $#yra ){
				next if $yra[ $idx ][ 0 ] ne $val;
				splice @yra, $idx, 1;
				last;
			}
		}
	}
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	return 1;
}
#=======================================================================
#*del_user = { };
*del_user = \&del;
#-----------------------------------------------------------------------
sub del {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( @val ) = @_;
	
	return $self->_err( q[Supplied value is undefined.] 	) unless @val;
	#return $self->_err( q[Supplied user does not exists.] 	) unless _exs( $self->{ pwd }, $val );
	return $self->_err( q[Unsufficient permissions.] 		) unless open my $fhd, '>>', $self->{ psh };
	
	close( $fhd );
	
	#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$self->_bck or return;
	#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	tie my @ary, q[Tie::Array::CSV], $self->{ pwd }, { 
		tie_file => { 
			autochomp => 1, 
		}, 
		text_csv => { 
			sep_char 	=> SEP,
			binary 		=> 1,
			quote_char => undef,
		},
	};
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	tie my @yra, q[Tie::Array::CSV], $self->{ psh }, { 
		tie_file => { 
			autochomp => 1, 
		}, 
		text_csv => { 
			sep_char 	=> SEP,
			binary 		=> 1,
			quote_char => undef,
		},
	};
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	
	for my $val ( @val ){
		my $usr;
		my $sav;
		for my $idx ( 0 .. $#ary ){
			next if $ary[ $idx ][ 0 ] ne $val;
			$usr = splice @ary, $idx, 1;
			$sav = $idx;
			last;
		}
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		if( $yra[ $sav ][ 0 ] eq $val ){
			splice @yra, $sav, 1;
		}else{
			for my $idx ( 0 .. $#yra ){
				next if $yra[ $idx ][ 0 ] ne $val;
				splice @yra, $idx, 1;
				last;
			}
		}
	}
	#+ + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +
	untie @ary;
	untie @yra;
	
	@ary = ( );
	@yra = ( );
	
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	tie @ary, q[Tie::Array::CSV], $self->{ grp }, { 
		tie_file => { 
			autochomp => 1, 
		}, 
		text_csv => { 
			sep_char 	=> SEP,
			binary 		=> 1,
			quote_char => undef,
		},
	};
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	tie @yra, q[Tie::Array::CSV], $self->{ gsh }, { 
		tie_file => { 
			autochomp => 1, 
		}, 
		text_csv => { 
			sep_char 	=> SEP,
			binary 		=> 1,
			quote_char => undef,
		},
	};
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	for my $val ( @val ){
		my $sav;
		for my $idx ( 0 .. $#ary ){
			next if $ary[ $idx ][ 3 ] !~ /\b$val\b/;
			$ary[ $idx ][ 3 ] = join( q[,], grep { $_ ne $val } split( /\s*,\s*/, $ary[ $idx ][ 3 ] ) );
		}
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		for my $idx ( 0 .. $#yra ){
			next if $ary[ $idx ][ 3 ] !~ /\b$val\b/;
			$ary[ $sav ][ 3 ] = join( q[,], grep { $_ ne $val } split( /\s*,\s*/, $ary[ $sav ][ 3 ] ) );
		}
	}
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	return 1;
}
#=======================================================================
sub rename {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $usr, $val ) = @_;
	
	return $self->_err( q[Supplied value is undefined.] 	) unless defined $usr and defined $val;
	return $self->_err( q[Supplied user does not exists.] 	) unless _exs( $self->{ pwd }, $usr );
	
	_set( $self->{ pwd }, $usr, 0, $val );
	_set( $self->{ psh }, $usr, 0, $val );
	
	return;
}
#=======================================================================
sub passwd {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $usr, $val ) = @_;
	
	return $self->_err( q[Supplied value is undefined.] 	) unless defined $usr and defined $val;
	return $self->_err( q[Supplied user does not exists.] 	) unless _exs( $self->{ pwd }, $usr );
	
	if( defined $val ){
		return $self->_set( $self->{ psh }, $usr, 1, $val );
	}else{
		return $self->_get( $self->{ psh }, $usr, 1 );
	}
}
#=======================================================================
sub shell {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $usr, $val ) = @_;
	
	return $self->_err( q[Supplied value is undefined.] 	) unless defined $usr and defined $val;
	return $self->_err( q[Supplied user does not exists.] 	) unless _exs( $self->{ pwd }, $usr );
	
	if( defined $val ){
		return $self->_set( $self->{ pwd }, $usr, 6, $val );
	}else{
		return $self->_get( $self->{ pwd }, $usr, 6 );
	}
}
#=======================================================================
sub home {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $usr, $val ) = @_;
	
	return $self->_err( q[Supplied value is undefined.] 	) unless defined $usr and defined $val;
	return $self->_err( q[Supplied user does not exists.] 	) unless _exs( $self->{ pwd }, $usr );
	
	if( defined $val ){
		return $self->_set( $self->{ pwd }, $usr, 5, $val );
	}else{
		return $self->_get( $self->{ pwd }, $usr, 5 );
	}
}
#=======================================================================
sub gecos {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $usr, $val ) = @_;
	
	return $self->_err( q[Supplied value is undefined.] 	) unless defined $usr and defined $val;
	return $self->_err( q[Supplied user does not exists.] 	) unless _exs( $self->{ pwd }, $usr );
	
	if( defined $val ){
		return $self->_set( $self->{ pwd }, $usr, 4, $val );
	}else{
		return $self->_get( $self->{ pwd }, $usr, 4 );
	}
}
#=======================================================================
sub gid {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $usr, $val ) = @_;
	
	return $self->_err( q[Supplied value is undefined.] 	) unless defined $usr and defined $val;
	return $self->_err( q[Supplied user does not exists.] 	) unless _exs( $self->{ pwd }, $usr );
	
	if( defined $val ){
		return $self->_set( $self->{ pwd }, $usr, 3, $val );
	}else{
		return $self->_get( $self->{ pwd }, $usr, 3 );
	}
}
#=======================================================================
sub uid {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $usr, $val ) = @_;
	
	return $self->_err( q[Supplied value is undefined.] 	) unless defined $usr and defined $val;
	return $self->_err( q[Supplied user does not exists.] 	) unless _exs( $self->{ pwd }, $usr );
	
	if( defined $val ){
		return $self->_set( $self->{ pwd }, $usr, 2, $val );
	}else{
		return $self->_get( $self->{ pwd }, $usr, 2 );
	}
}
#=======================================================================
sub _set {
	my ( $self, $pth, $usr, $pos, $val ) = @_;

	return $self->_err( q[Unsufficient permissions.] ) unless open my $fhd, '>>', $pth;
	close( $fhd );
	
	#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$self->_bck or return;
	#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	tie my @ary, q[Tie::Array::CSV], $pth, { 
		tie_file => { 
			autochomp => 1, 
		}, 
		text_csv => { 
			sep_char 	=> SEP,
			binary 		=> 1,
			quote_char => undef,
		},
	};

	for my $idx ( 0 .. $#ary ){
		next if $ary[ $idx ][ 0 ] ne $usr;
		$ary[ $idx ][ $pos ] = $val;
	}
	
	return 1;
}
#=======================================================================
sub _get {
	my ( $self, $pth, $usr, $pos ) = @_;
	
	return $self->_err( q[Unsufficient permissions.] ) unless open my $fhd, '<', $pth;
	
	while( <$fhd> ){
		my @tmp = split /:/;
		next if $tmp[ 0 ] ne $usr;
		return $tmp[ $pos ];
	}
	close( $fhd );
	
	return;
}
#=======================================================================
sub group {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( @arg ) = @_;
	
	#-------------------------------------------------------------------
	if( @arg == 3 ){
		return $self->_err( q[Unsufficient permissions.] ) unless open my $fhd, '>>', $self->{ gsh };
		close( $fhd );
		
		#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		$self->_bck or return;
		#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		tie my @ary, q[Tie::Array::CSV], $self->{ grp }, { 
			tie_file => { 
				autochomp => 1, 
			}, 
			text_csv => { 
				sep_char 	=> SEP,
				binary 		=> 1,
				quote_char => undef,
			},
		};
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		tie my @yra, q[Tie::Array::CSV], $self->{ gsh }, { 
			tie_file => { 
				autochomp => 1, 
			}, 
			text_csv => { 
				sep_char 	=> SEP,
				binary 		=> 1,
				quote_char => undef,
			},
		};
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		my $lst = join( q[,], @{ $arg[ 2 ] } );
		
		if(  _exs( $self->{ grp }, $arg[ 0 ] ) ){
			my $sav;
			for my $idx ( 0 .. $#ary ){
				next if $ary[ $idx ][ 0 ] ne $arg[ 0 ];
				$ary[ $idx ][ 2 ] = $arg[ 1 ];
				$ary[ $idx ][ 3 ] = $lst;
				$sav = $idx;
				last;
			}
			if( $yra[ $sav ][ 0 ] eq $arg[ 0 ] ){
				$yra[ $sav ][ 3 ] = $lst;
			}else{
				for my $idx ( 0 .. $#yra ){
					next if $yra[ $idx ][ 0 ] ne $arg[ 0 ];
					$yra[ $idx ][ 3 ] = $lst;
					last;
				}
			}
		}else{
			push @ary, [
				$arg[ 0 ],
				q[x],
				$arg[ 1 ],
				$lst
			];
			
			push @yra, [
				$arg[ 0 ],
				q[!],
				q[],
				$lst
			];
		}
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		return 1;
	}
	#-------------------------------------------------------------------
	elsif( @arg == 1 ){
		open( my $fhd, '<', $self->{ grp } ) or die $!;
		my @grp = ( undef, [ ] );
		while( <$fhd> ){
			my @tmp = split /:/;
			next if $tmp[ 0 ] ne $arg[ 0 ];
			
			chomp $tmp[ 3 ];
			
			$grp[ 0 ] = $tmp[ 2 ];
			$grp[ 1 ] = [ split( /\s*,\s*/, $tmp[ 3 ] ) ];
		
			last;
		}
		close( $fhd );
		
		return wantarray ? @grp : \@grp;	
	}
	#-------------------------------------------------------------------
}
#=======================================================================
sub user {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( @arg ) = @_;
	
	#-------------------------------------------------------------------
	if( @arg == 7 ){
		return $self->_err( q[Unsufficient permissions.] ) unless open my $fhd, '>>', $self->{ psh };
		close( $fhd );
		
		#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		$self->_bck or return;
		#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		my $pwd = $arg[ 1 ];
		$arg[ 1 ] = q[x];
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		tie my @ary, q[Tie::Array::CSV], $self->{ pwd }, { 
			tie_file => { 
				autochomp => 1, 
			}, 
			text_csv => { 
				sep_char 	=> SEP,
				binary 		=> 1,
				quote_char => undef,
			},
		};
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		tie my @yra, q[Tie::Array::CSV], $self->{ psh }, { 
			tie_file => { 
				autochomp => 1, 
			}, 
			text_csv => { 
				sep_char 	=> SEP,
				binary 		=> 1,
				quote_char => undef,
			},
		};
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		if(  _exs( $self->{ pwd }, $arg[ 0 ] ) ){
			my $sav;
			for my $idx ( 0 .. $#ary ){
				next if $ary[ $idx ][ 0 ] ne $arg[ 0 ];
				$ary[ $idx ][ $_ ] = $arg[ $_ ] for 1 .. 6;
				$sav = $idx;
				last;
			}
			#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			if( $yra[ $sav ][ 0 ] eq $arg[ 0 ] ){
				$yra[ $sav ][ 1 ] = $pwd;
			}else{
				for my $idx ( 0 .. $#yra ){
					next if $yra[ $idx ][ 0 ] ne $arg[ 0 ];
					$yra[ $idx ][ 1 ] = $pwd;
					last;
				}
			}
		}else{
			push @ary, \@arg;
			push @yra, [
				$arg[ 0 ],
				$pwd,
				int( time / DAY ), 
				0, 
				99999, 
				7, 
				q[], q[], q[]
			];
		}
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		return 1;
	}
	#-------------------------------------------------------------------
	elsif( @arg == 1 ){
		my @usr;
		open( my $fhd, '<', $self->{ pwd } ) or die $!;
		while( <$fhd> ){
			my @tmp = split /:/;
			next if $tmp[ 0 ] ne $arg[ 0 ];
			$usr[ $_ - 1 ] = $tmp[ $_ ] for 1 .. 6;
			last;
		}
		close( $fhd );
		
		chomp $usr[ $#usr ] if @usr;
		
		#if( $> == 0 ){
			if( open( my $fhd, '<', $self->{ psh } ) ){
				while( <$fhd> ){
					my @tmp = split /:/;
					next if $tmp[ 0 ] ne $arg[ 0 ];
					$usr[ 0 ] = $tmp[ 1 ];
					last;
				}
				close( $fhd );
			}
		#}
		
		return wantarray ? @usr : \@usr;
	}
	#-------------------------------------------------------------------
}
#=======================================================================
sub _unu {
	my ( $pth, $min, $max ) = @_;
	
	my %all;
	open( my $fhd, '<', $pth ) or die $!;
	while( <$fhd> ){
		$all{ ( split /:/ )[ 2 ] } = 1;
	}
	close( $fhd );
	
	for( my $idx = $min; $idx <= $max; $idx++ ){
		return $idx if not exists $all{ $idx };
	}
}
#=======================================================================
sub unused_uid {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $min, $max ) = @_;
	
	return _unu( $self->{ pwd }, $min || 0, $max || ( 2 ** ( $Config{ intsize } * 8 ) ) );
}
#=======================================================================
sub unused_gid {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $min, $max ) = @_;
	
	return _unu( $self->{ grp }, $min || 0, $max || ( 2 ** ( $Config{ intsize } * 8 ) ) );
}
#=======================================================================
sub _min {
	my ( $pth, $min ) = @_;
	
	my %all;
	open( my $fhd, '<', $pth ) or die $!;
	while( <$fhd> ){
		$all{ ( split /:/ )[ 2 ] } = 1;
	}
	close( $fhd );
	
	for( ;; ){
		return $min if exists $all{ $min };
		$min++;
	};
}
#=======================================================================
sub minuid {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return _min( $self->{ pwd }, $val || 0 );
}
#=======================================================================
sub mingid {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return _min( $self->{ grp }, $val || 0 );
}
#=======================================================================
sub _max {
	my ( $pth ) = @_;
	
	my $max = 0;
	open( my $fhd, '<', $pth ) or die $!;
	while( <$fhd> ){
		my @tmp = split /:/;
		$max = $tmp[ 2 ] if $tmp[ 2 ] > $max;
	}
	close( $fhd );
	
	return $max;
}
#======================================================================
sub maxuid {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	return _max( $self->{ pwd } );
}
#======================================================================
sub maxgid {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	return _max( $self->{ grp } );
}
#=======================================================================
sub _exs {
	my ( $pth, $val, $pos ) = @_;
	
	$pos //= 0;
	
	open( my $fhd, '<', $pth ) or die $!;
	while( <$fhd> ){
		my @tmp = split /:/;
		return 1 if $tmp[ $pos ] eq $val;
	}
	close( $fhd );

	return;
}
#======================================================================
sub exists_user {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return unless defined $val;
	return _exs( $self->{ pwd }, $val );
}
#======================================================================
sub exists_group {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return unless defined $val;
	return _exs( $self->{ grp }, $val );
}
#=======================================================================
sub reset {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	$self->passwd_file	( PWD );
	$self->group_file	( GRP );
	$self->shadow_file	( PSH );
	$self->gshadow_file	( GSH );
		
	return 1;
}
#=======================================================================
sub encpass {
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return unless defined $val;
	return password( $val, undef, $self->{ alg } );
}
#=======================================================================
sub algorithm { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return $self->{ alg } unless defined $val;

	my $alg =	$val eq q[md5] 		? $val :
				$val eq q[blowfish] ? $val :
				$val eq q[sha256] 	? $val : q[sha512];
					
	$self->{ alg } = $alg;
	
	return $self->{ alg };
}
#=======================================================================
sub default_umask { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return $self->{ msk } unless defined $val;
	
	$self->{ msk } = $val ? 1 : 0;
	
	return $self->{ msk };
}
#=======================================================================
sub backup { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return $self->{ bck } unless defined $val;
	
	$self->{ bck } = $val ? 1 : 0;
	
	return $self->{ bck };
}
#=======================================================================
sub compress { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return $self->{ cmp } unless defined $val;
	
	$self->{ cmp } = $val ? 1 : 0;
	
	return $self->{ cmp };
}
#=======================================================================
sub warnings { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return $self->{ wrn } unless defined $val;
	
	$self->{ wrn } = $val ? 1 : 0;
	
	return $self->{ wrn };
}
#=======================================================================
sub debug { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return $self->{ dbg } unless defined $val;
	
	$self->{ dbg } = $val ? 1 : 0;
	
	return $self->{ dbg };
}
#=======================================================================
sub error { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return $self->{ err };
}
#=======================================================================
sub passwd_file { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return $self->{ pwd } unless defined $val;
	
	my $pth = path( $val );
	die q[Password file cannot be a directory.] if $pth->is_dir;
	
	#$pth->touchpath unless $pth->exists;
	
	$self->{ pwd } = $pth->absolute->canonpath;
	
	return $self->{ pwd };
}
#=======================================================================
sub group_file { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return $self->{ grp } unless defined $val;
	
	my $pth = path( $val );
	die q[Group file cannot be a directory.] if $pth->is_dir;
	
	#$pth->touchpath unless $pth->exists;
	
	$self->{ grp } = $pth->absolute->canonpath;
	
	return $self->{ grp };
}
#=======================================================================
sub shadow_file { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return $self->{ psh } unless defined $val;
	
	my $pth = path( $val );
	die q[Shadowed passwd file (aka "shadow") file cannot be a directory.] if $pth->is_dir;
	
	#$pth->touchpath unless $pth->exists;
	
	$self->{ psh } = $pth->absolute->canonpath;
	
	return $self->{ psh };
}
#=======================================================================
sub gshadow_file { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my ( $val ) = @_;
	
	return $self->{ gsh } unless defined $val;
	
	my $pth = path( $val );
	die q[Shadowed group file (aka "gshadow") file cannot be a directory.] if $pth->is_dir;
	
	#$pth->touchpath unless $pth->exists;
	
	$self->{ gsh } = $pth->absolute->canonpath;
	
	return $self->{ gsh };
}
#=======================================================================
sub _lst {
	my ( $pth ) = @_;
	
	my @ary;
	open( my $fhd, '<', $pth ) or die $!;
	push @ary, ( split( /:/, $_ ) )[ 0 ] while <$fhd>;
	close($fhd);
	
	return wantarray ? @ary : \@ary;
}
#=======================================================================
sub groups { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	return _lst( $self->{ grp } );
}
#=======================================================================
sub groups_from_gshadow { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	return _lst( $self->{ gsh } );
}
#=======================================================================
sub users { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	return _lst( $self->{ pwd } );
}
#=======================================================================
sub check_sanity {
	return 1;
}
#=======================================================================
sub users_from_shadow { 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	return _lst( $self->{ psh } );
}
#======================================================================

=head1 NAME

Passwd::Unix - access to standard unix files

=head1 SYNOPSIS

	use Passwd::Unix;
	
	my $pu = Passwd::Unix->new;
	
	my $err = $pu->user(
				"example", 
				$pu->encpass("my_secret"), 
				$pu->unused_uid, 
				$pu->unused_gid, 
				"My User", 
				"/home/example", 
				"/bin/bash" 
	);
	
	$pu->passwd("example", $pu->encpass( "newsecret") );
	foreach my $user ($pu->users) {
		print "Username: $user\nFull Name: ", $pu->gecos($user), "\n\n";
	}
	
	my $uid = $pu->uid('example');
	$pu->del("example");

	# or 

	use Passwd::Unix qw( 
		algorithm backup check_sanity compress del del_group del_user
		encpass exists_group exists_user gecos gid group group_file
		groups groups_from_gshadow home maxgid maxuid mingid minuid
		passwd passwd_file rename reset shadow_file shell uid user
		users users_from_shadow warnings
	);
	
	my $err = user( "example", encpass("my_secret"), unused_uid(), unused_gid(),
					"My User", "/home/example", "/bin/bash" );
	passwd("example",encpass("newsecret"));
	foreach my $user ( users() ) {
		print "Username: $user\nFull Name: ", gecos( $user ), "\n\n";
	}
	
	my $uid = uid( 'example' );
	del( 'example' );

=head1 ABSTRACT

Passwd::Unix provides an abstract object-oriented and function interface to
standard Unix files, such as /etc/passwd, /etc/shadow, /etc/group. Additionally
this module provides  environment for testing software without using
system critical files in /etc/ dir (you can specify other files than 
/etc/passwd etc.).

=head1 DESCRIPTION

The Passwd::Unix module provides an abstract interface to /etc/passwd, 
/etc/shadow, /etc/group, /etc/gshadow format files. It is inspired by 
Unix::PasswdFile module (that one does not handle /etc/shadow file).

B<Module was rewritten from the ground in version 1.0 (i.e. to support 
newer hash algorithms and so on), however with compatibility in mind. 
Despite this some incompatibilities can occur.>

=head1 SUBROUTINES/METHODS

=over 4

=item B<new( [ param0 => 1, param1 => 0... ] )>

Constructor. Possible parameters are:

=over 8

=item B<passwd> - path to passwd file; default C</etc/passwd>

=item B<shadow> - path to shadow file; default C</etc/shadow>

=item B<group> - path to group file; default C</etc/group>

=item B<gshadow> - path to gshadow file if any; default C</etc/gshadow>

=item B<algorithm> - hash algorithm, possible values: md5, blowfish, sha256, sha512; default C<sha512>

=item B<umask> - not used anymore; left only for compatibility reason

=item B<debug> - not used anymore; left only for compatibility reason

=item B<backup> - boolean; if set to C<1>, backup will be made; default C<1>

=item B<compress> - boolean; if set to C<1>, backup compression will be made; default C<1>

=item B<warnings> - boolean; if set to C<1>, important warnings will be displayed; default C<0>

=back

=item B<algorithm()>

This method allows to specify algorithm for password generation. Possible values: C<md5>, C<blowfish>, C<sha256>, C<sha512>

=item B<backup()>

This method allows to specify if backups files have to be made before every modyfication (C<1> for on, C<0> for off).

=item B<compress()>

This method allows to specify if compression to backup files has to be made (C<1> for on, C<0> for off).

=item B<check_sanity()>

This function was left only for compatibility reason. Currently it does nothing (always returns 1).

=item B<debug()>

This function was left only for compatibility reason. Currently it does nothing.

=item B<default_umask( [UMASK] )>

This function was left only for compatibility reason. Currently it does nothing.

=item B<del( USERNAME0, USERNAME1... )>

This method is an alias for C<del_user>. It's for transition only.

=item B<del_user( USERNAME0, USERNAME1... )>

This method will delete the list of users. It has no effect if the 
supplied users do not exist.

=item B<del_group( GROUPNAME0, GROUPNAME1... )>

This method will delete the list of groups. It has no effect if the 
supplied groups do not exist.

=item B<encpass( PASSWORD )>

This method will encrypt plain text into unix style password.

=item B<error()>

This method returns the last error (even if "warnings" is disabled).

=item B<exists_user(USERNAME)>

This method checks if specified user exists. It returns C<undef> on failure and C<1> on success.

=item B<exists_group(GROUPNAME)>

This method checks if specified group exists. It returns C<undef> on failure and C<1> on success.

=item B<gecos( USERNAME [,GECOS] )>

Read or modify a user's GECOS string (typically full name). 
Returns the result of operation (C<1> or C<undef>) if GECOS was specified. 
Otherwhise returns the GECOS if any.

=item B<gid( USERNAME [,GID] )>

Read or modify a user's GID. Returns the result of operation (C<1> or C<undef>) if GID was specified otherwhise returns the GID if any.

=item B<group( GROUPNAME [,GID, ARRAYREF] )>

This method can add, modify, or return information about a group. 
Supplied with a single groupname parameter, it will return a two element 
list consisting of (GID, ARRAYREF), where ARRAYREF is a ref to array 
consisting names of users in this GROUP. It will return undef and ref to empty array (C<undef, [ ]>) if no such group 
exists. If you supply all three parameters, the named group will be 
created or modified if it already exists.

=item B<group_file([PATH])>

This method, if called with an argument, sets path to the I<group> file.
Otherwise returns the current PATH.

=item B<groups()>

This method returns a list of all existing groups. 

=item B<groups_from_gshadow()>

This method returns a list of all existing groups in a gshadow file. 

=item B<gshadow_file([PATH])>

This method, if called with an argument, sets path to the I<gshadow> file.
Otherwise returns the current PATH.

=item B<home( USERNAME [,HOMEDIR] )>

Read or modify a user's home directory. Returns the result of operation 
(C<1> or C<undef>) if HOMEDIR was specified otherwhise returns the HOMEDIR if any.

=item B<maxuid( )>

This method returns the maximum UID in use. 

=item B<maxgid()>

This method returns the maximum GID in use. 

=item B<minuid( [UID] )>

This method returns the minimum UID in use, that is greater then spupplied.

=item B<mingid()>

This method returns the minimum GID in use, that is greater then spupplied.

=item B<passwd( USERNAME [,PASSWD] )>

Read or modify a user's password. If you have a plaintext password, 
use the encpass method to encrypt it before passing it to this method. 
Returns the result of operation (C<1> or C<undef>) if PASSWD was specified. 
Otherwhise returns the PASSWD if any.

=item B<passwd_file([PATH])>

This method, if called with an argument, sets path to the I<passwd> file.
Otherwise returns the current PATH.

=item B<rename( OLDNAME, NEWNAME )>

This method changes the username for a user. If NEWNAME corresponds to 
an existing user, that user will be overwritten. It returns C<undef> on 
failure and C<1> on success.

=item B<reset()>

This method sets paths to files I<passwd>, I<shadow>, I<group>, I<gshadow> to the
default values.

=item B<shell( USERNAME [,SHELL] )>

Read or modify a user's shell. Returns the result of operation (C<1> or C<undef>) if SHELL was specified otherwhise returns the SHELL if any.

=item B<uid( USERNAME [,UID] )>

Read or modify a user's UID. Returns the result of operation (C<1> or C<undef>) if UID was specified otherwhise returns the UID if any.

=item B<user( USERNAME [,PASSWD, UID, GID, GECOS, HOMEDIR, SHELL] )>

This method can add, modify, or return information about a user. 
Supplied with a single username parameter, it will return a six element 
list consisting of (PASSWORD, UID, GID, GECOS, HOMEDIR, SHELL), or 
undef if no such user exists. If you supply all seven parameters, 
the named user will be created or modified if it already exists.

=item B<users()>

This method returns a list of all existing usernames. 

=item B<users_from_shadow()>

This method returns a list of all existing usernames in a shadow file. 

=item B<shadow_file([PATH])>

This method, if called with an argument, sets path to the I<shadow> file.
Otherwise returns the current PATH.

=item B<unused_uid( [MINUID] [,MAXUID] )>

This method returns the first unused UID in a given range. The default MINUID is 0. The default MAXUID is maximal integer value (computed from C<$Config{ intsize }> ).

=item B<unused_gid( [MINGID] [,MAXGID] )>

This method returns the first unused GID in a given range. The default MINGID is 0. The default MAXGID is maximal integer value (computed from C<$Config{ intsize }> ).

=item B<warnings()>

This method allows to specify if warnings has to be displayed (C<1> for on, C<0> for off). Whether you can check last warning/failure by calling C<error>.

=back

=head1 DEPENDENCIES

=over 4

=item Crypt::Password

=item IO::Compress::Bzip2

=item Path::Tiny

=item Tie::Array::CSV

=back

=head1 TODO

Preparation of tests.

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None. I hope. 

=head1 THANKS

=over 4

=item Thanks to Jonas Genannt for many suggestions and patches! 

=item Thanks to Christian Kuelker for suggestions and reporting some bugs :-).

=item Thanks to Steven Haryanto for suggestions.

=item BIG THANKS to Lopes Victor for reporting some bugs and his exact sugesstions :-)

=item Thanks to Foudil BRÉTEL for some remarks, suggestions as well as supplying relevant patch!

=item BIG thanks to Artem Russakovskii for reporting a bug.

=back

=head1 AUTHOR

Strzelecki Lukasz <lukasz@strzeleccy.eu>

=head1 LICENCE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
