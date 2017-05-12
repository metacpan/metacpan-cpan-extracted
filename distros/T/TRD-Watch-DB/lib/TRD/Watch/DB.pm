package TRD::Watch::DB;

use 5.008008;
use strict;
use warnings;
use POSIX;
use Carp;
use DBI;
use threads ( 'exit' => 'threads_only' );
use Time::HiRes qw(sleep);
use TRD::DebugLog;

=head1 NAME

TRD::Warch::DB - データベースの死活監視

=head1 VERSION

Version 0.0.5

=cut

our $VERSION = '0.0.5';
our $default_timeout = 5;	# sec
our $default_interval = 60;	# sec
our $default_sql = "select TO_CHAR( sysdate, 'YYYY-MM-DD HH24:MI:SS' ) from dual";
our $default_db_sid = 'Oracle:emp';
our $default_db_user = 'sccot';
our $default_db_pass = 'tiger';

=head1 SYNOPSIS

use TRD::Watch::DB;
use DBI;

my $db_th = new1 TRD:Watch::DB(
	$name,
	'-db_sid' => 'Oracle:emp',
	'-db_user' => 'sccot',
	'-db_pass' => 'tiger',
	'-sql' => q!select TO_CHAR( sysdate, 'YYYY-MM-DD' ) from dual!,
	'-checkfunc' => \&checkfunc,
	'-errorfunc' => \&errorfunc,
	'-recoverfunc' => \&recoverfunc
);
$db_th->start;

sub checkfunc($$)
{
	my( $name, $sth ) = @_;
	my $stat = -1;	# 0=normal, 0!=error

	my( $row ) = $sth->fetchrow_array();
	if( $row=~m/^\d\d\d\d-\d\d-\d\d$/ ){
		$stat = 0;	# normal
	} else {
		$stat = 1;	# error
	}

	return $stat;
}

sub errorfunc($$)
{
	my( $name, $db_sid ) = @_;
	&send_error_mail( 'DB', $name, $db_sid );
}

sub recoverfunc($$)
{
	my( $name, $db_sid ) = @_;
	&send_recover_mail( 'DB', $name, $db_sid );
}

=head1 DESCRIPTION

DBIでアクセスできるデータベースを死活監視します。

=head1 METHODS

=head2 Constractor

TRD::Watch::DBのコンストラクタです。

=head3 $db_th = new TRD::Watch::DB( $name [, '-db_sid' => $db_sid] [, '-db_user' => $db_user] [, '-db_pass' => $db_pass] [, '-sql' => $sql] [, '-errorfunc' => \$errorfunc] [, '-recoverfunc' => \$recoverfunc] [, '-checkfunc' => \$checkfunc] [, '-timeout' => $timeout] [, '-interval' => $interval] );

TRD::Watch::DBオブジェクトを作成するコンストラクタです。

最初の引数は、オブジェクトの名前で、必須です。
その他のオプションは、省略可能です。

=over 4

=item '-db_sid'

DBIに設定するデータソースを指定します。

=item '-db_user'

DBIに設定するユーザ名を指定します。

=item '-db_pass'

DBIに設定するパスワードを指定します。

=item '-sql'

死活監視で発行するSQL文を指定します。

=item '-errorfunc'

障害が発生したときに呼び出されるコールバック関数を指定します。

=item '-recoverfunc'

障害が回復したときに呼び出されるコールバック関数を指定します。

=item '-checkfunc'

監視を行うコールバック関数を指定します。

=item '-timeout'

監視のタイムアウトを秒で指定します。

=item '-interval'

死活監視の間隔を秒で指定します。

=back

=cut
#=======================================================================
sub new
{
	my( $pkg, $name, %opt ) = @_;

	bless {
		name => $name,
		db_sid => exists($opt{'-db_sid'}) ? $opt{'-db_sid'} : $default_db_sid,
		db_user => exists($opt{'-db_user'}) ? $opt{'-db_user'} : $default_db_user,
		db_pass => exists($opt{'-db_pass'}) ? $opt{'-db_pass'} : $default_db_pass,
		sql => exists($opt{'-sql'}) ? $opt{'-sql'} : $default_sql,
		errorfunc => exists($opt{'-errorfunc'}) ? $opt{'-errorfunc'} : \&default_errorfunc,
		recoverfunc => exists($opt{'-recoverfunc'}) ? $opt{'-recoverfunc'} : \&default_recuverfunc,
		checkfunc => exists($opt{'-checkfunc'}) ? $opt{'-checkfunc'} : \&default_checkfunc,
		timeout => exists($opt{'-timeout'}) ? $opt{'-timeout'} : $default_timeout,
		interval => exists($opt{'-interval'}) ? $opt{'-interval'} : $default_interval,
		sleepcron => undef,
		pid => undef,
		start => 0,
	}, $pkg;
}

=head2 setName( $name )

オブジェクトの名前を設定します。

=head3 $db_th->setName( 'test' );

死活監視のコールバック関数が呼ばれる際に名前がわたされます。
死活監視が開始されていた場合、再起動されます。

=cut
#=======================================================================
sub setName
{
	my $self = shift;
	my $name = (@_) ? shift : '';
	$self->{'name'} = $name;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
}

=head2 setDbSid( $db_sid )

DBIに指定するデータソースを設定します。

=head3 $db_th->setDbSid( 'Oracle:emp' );

死活監視のコールバック関数が呼ばれる際にデータソース名がわたされます。
死活監視が開始されていた場合、再起動されます。

=cut
#=======================================================================
sub setDbSid
{
	my $self = shift;
	my $db_sid = (@_) ? shift : $default_db_sid;
	$self->{'db_sid'} = $db_sid;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
}

=head2 setDbUser( $db_user )

DBIに指定するユーザ名を設定します。

=head3 $db_th->setDbUser( 'sccot' );

死活監視が開始されていた場合、再起動されます。

=cut
#=======================================================================
sub setDbUser
{
	my $self = shift;
	my $db_user = (@_) ? shift : $default_db_user;
	$self->{'db_user'} = $db_user;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
}

=head2 setDbPassword( $db_password )

DBIに指定するパスワードを設定します。

=head3 $db_th->setDbPassword( 'tiger' );

死活監視が開始されていた場合、再起動されます。

=cut
#=======================================================================
sub setDbPassword
{
	my $self = shift;
	my $db_pass = (@_) ? shift : $default_db_pass;
	$self->{'db_pass'} = $db_pass;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
}

=head2 setSql( $sql )

死活監視で発行するSQLを設定します。

=head3 $db_th->setSql( q!select sysdate from dual! );

死活監視が開始されていた場合、再起動されます。

=cut
#=======================================================================
sub setSql
{
	my $self = shift;
	my $sql = (@_) ? shift : $default_sql;
	$self->{'sql'} = $sql;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
}

=head2 setWatchSleep( $name, $datetime, $sleeptime );

死活監視を休止する時間を設定します。

=head3 $db_th->setWatchSleep( 'cron time sleep', '59 3 * * *', 60*60 );

設定した時間、死活監視を休止(sleep)し、計画的な障害検知を回避します。

=over 4

=item $name

休止に名前を設定します。

=item $datetime

休止する開始時間をcronのような形式で設定します。
5つの空白で区切られた値を設定します。
詳しくはcrontabを参考にしてください。

=item $sleeptime

休止時間を秒で設定します。
死活監視が開始されていた場合、再起動されます。

=back

=cut
#=======================================================================
sub setWatchSleep($$$$)
{
	my( $self, $name, $datetime, $sleeptime ) = @_;

	my $item = {
		name => $name,
		datetime => $datetime,
		sleeptime => $sleeptime,
	};
	push( @{$self->{'sleepcron'}}, $item );

	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
}

=head2 setTimeout( $timeout );

監視のタイムアウトを設定します。

=head3 $db_th->setTimeout( 30 );

DBからタイムアウト値までに返答が来ない場合、障害として扱います。
死活監視が開始されていた場合、再起動されます。

=cut
#=======================================================================
sub setTimeout
{
	my $self = shift;
	my $timeout = (@_) ? shift : $default_timeout;
	$self->{'timeout'} = $timeout;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
}

=head2 setInterval( $interval )

死活監視の間隔を設定します。

=head3 $db_th->setInterval( 60 );

死活監視が開始されていた場合、再起動されます。

=cut
#=======================================================================
sub setInterval
{
	my $self = shift;
	my $interval = (@_) ? shift : $default_interval;
	$self->{'interval'} = $interval;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
}

=head2 setErrorFunc( \&errorfunc )

障害が発生したときに呼ばれるコールバック関数を指定します。

=head3 $db_th->setErrorFunc( \&errorfunc );

コールバック関数には死活監視の名前($name)とデータソース名($db_sid)が渡されます。
死活監視が開始されていた場合、再起動されます。

=cut
#=======================================================================
sub setErrorFunc
{
	my $self = shift;
	my $func = (@_) ? shift : undef;
	$self->{'errorfunc'} = $func;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
}

=head2 setRecoverFunc( \&recoverfunc )

障害が回復したときに呼ばれるコールバック関数を設定します。

=head3 $db_th->setRecoverFunc( \&recoverfunc );

コールバック関数には死活監視の名前($name)とデータソース名($db_sid)が渡されます。
死活監視が開始されていた場合、再起動されます。

=cut
#=======================================================================
sub setRecoverFunc
{
	my $self = shift;
	my $func = (@_) ? shift : \&default_recoverfunc;
	$self->{'recoverfunc'} = $func;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
}

=head2 setCheckFunc( \&checkfunc )

死活監視を行うコールバック関数を設定します。

=head3 $db_th->setCheckFunc( \&checkfunc );

コールバック関数には死活監視の名前($name)とDBIからのステートメントハンドル($sth)が渡されます。
死活監視が開始されていた場合、再起動されます。

=cut
#=======================================================================
sub setCheckFunc
{
	my $self = shift;
	my $func = (@_) ? shift : undef;
	$self->{'checkfunc'} = $func;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
}

=head2 start

死活監視を開始します。

=head3 $db_th->start();

死活監視を開始し、checkfuncがinterval間隔で呼び出されます。
障害が発生するとerrorfuncが呼び出され、障害が回復するとrecoverfuncが呼び出されます。

=cut
#=======================================================================
sub start
{
	my $self = shift;

	my $stat = 1;
	if( $self->{'start'} ){
		dlog( "already started:". $self->{'name'} );
	} else {
		my $pid = threads->new( \&db_thread, $self );
		$self->{'pid'} = $pid;
		$self->{'start'} = 1;
		$stat = 0;
		sleep( 0.1 );
	}

	return $stat;
}

=head2 stop

死活監視を停止します。

=head3 $db_th->stop();

死活監視を停止します。

=cut
#=======================================================================
sub stop
{
	my $self = shift;

	my $stat = 1;
	if( !$self->{'start'} ){
		dlog( "already stoped:". $self->{'name'} );
	} else {
		$self->{'pid'}->kill('TERM');
		$self->{'pid'}->detach();
		$self->{'pid'} = undef;
		$self->{'start'} = 0;
		$stat = 0;
		sleep( 0.1 );
	}

	return $stat;
}

=head2 db_thread

内部関数：死活監視を行うスレッド関数
監視はforkで起動される。

=cut
#=======================================================================
sub db_thread
{
	my $self = shift;
	my $stat = -1;
	my $old_stat = undef;

	$SIG{'TERM'} = sub { dlog( "term:". $self->{'name'} ); threads->exit(); };

	my $pid;
	my $t;
	my $func;
	my $sleeptime = 0;

	while( 1 ){
		if( $pid = fork ){
			$t = 0;
			while( 1 ){
				if( waitpid( $pid, &POSIX::WNOHANG ) != 0 ){
					$stat = $? >> 8;
					last;
				} else {
					# running
					if( $t > $self->{'timeout'} ){
						# timeout
dlog( "timeout:". $self->{'name'} );
						kill SIGKILL, $pid;
						kill SIGTERM, $pid;
						waitpid( $pid, 0 );
						$stat = 2;
						last;
					}
				}
				sleep( 0.1 );
				$t += 0.1;
			}
		} else {
			# forked proc
			$stat = &db( $self );
			POSIX::_exit( $stat );
		}

		if( defined( $old_stat ) ){
			if( $old_stat != $stat ){
				$func = undef;
				if( $stat ){
					$func = $self->{'errorfunc'};
				} else {
					$func = $self->{'recoverfunc'};
				}
				if( ref( $func ) eq 'CODE' ){
					&{$func}( $self->{'name'}, $self->{'db_sid'} );
				}
			}
		}
		$old_stat = $stat;

		$sleeptime = ($self->{'interval'} - $t);
		$sleeptime += &checkSleep( $self );
		$sleeptime = 0 if( $sleeptime < 0 );
		sleep( $sleeptime );
	}

	return $stat;
}

=head2 checkSleep

内部関数：休止時期を取得する。

=cut
#=======================================================================
sub checkSleep
{
	my $self = shift;
	my $cron;

	my $name;
	my $datetime;
	my $sleeptime;

	my( $cmin, $chour, $cday, $cmonth, $cwday );
	my $stat = 0;
	my $addsleep = 0;

	my( $sec, $min, $hour, $mday, $month, $year, $wday, $yday, $isdst ) =
		localtime( time );

	$month++;
	$year += 1900;

	foreach $cron ( @{$self->{'sleepcron'}} ){
		$name = $cron->{'name'};
		$datetime = $cron->{'datetime'};
		$sleeptime = $cron->{'sleeptime'};

		if( $datetime=~m/^(.+)\s+(.+)\s+(.+)\s+(.+)\s+(.+)$/ ){
			$cmin = $1;
			$chour = $2;
			$cday = $3;
			$cmonth = $4;
			$cwday = $5;

			$stat = 1;
			$stat = 0 if( ( $cmin ne '*' )&&( $cmin != $min ) );
			$stat = 0 if( ( $chour ne '*' )&&( $chour != $hour ) );
			$stat = 0 if( ( $cday ne '*' )&&( $cday != $mday ) );
			$stat = 0 if( ( $cmonth ne '*' )&&( $cmonth != $month ) );
			$stat = 0 if( ( $cwday ne '*' )&&( $cwday != $wday ) );

			if( $stat ){
				$addsleep = $sleeptime;
				last;
			}
		}
	}

	return $addsleep;
}

=head2 db

内部関数：監視を行う。

=cut
#=======================================================================
sub db
{
	my $self = shift;
	$SIG{'KILL'} = sub { threads->exit(-1); };
	$SIG{'TERM'} = sub { exit 2; };

	my $stat = 1;

	my $cmd;
	my $dbh;
	my $sth;
	my $func;
	my $db_val;
	if( !$self->{'db_sid'} ){
		$stat = 1;
	} else {
		$cmd = q!
			$dbh = DBI->connect(
				"DBI:". $self->{'db_sid'},
				$self->{'db_user'},
				$self->{'db_pass'},
				{
					RaiseError => 1
				},
			);
			$sth = $dbh->prepare( $self->{'sql'} );
			$sth->execute();

			$func = $self->{'checkfunc'};
			if( ref( $func ) eq 'CODE' ){
				$stat = &{$func}( $self->{'name'}, $sth );
			} else {
				$stat = 3;
			}
			$sth->finish;
			$dbh->disconnect;
		!;
		eval( $cmd ); ## no crtic
		if( $@ ne '' ){
			$stat = 1;
		}
	}

	return $stat;
}

=head2 default_errorfunc( $name, $db_sid )

内部関数：デフォルトの要害発生時のコールバック関数。

=cut
#=======================================================================
sub default_errorfunc($$)
{
	my( $name, $db_sid ) = @_;

	print STDERR "DB:ERROR:${name}:${db_sid}\n";
}

=head2 default_recoverfunc( $name, $db_sid )

内部関数：デフォルトの障害回復時のコールバック関数。

=cut
#=======================================================================
sub default_recoverfunc($$)
{
	my( $name, $db_sid ) = @_;

	print STDERR "DB:RECOVER:${name}:${db_sid}\n";
}

=head2 default_checkfunc( $name, $db_sid )

内部関数：デフォルトの監視コールバック関数。

=cut
#=======================================================================
sub default_checkfunc($$)
{
	my( $name, $sth ) = @_;
	my $stat = 1;	# 障害

	my( $value ) = $sth->fetchrow_array();
	if( $value=~m/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/ ){
		$stat = 0;	# 障害なし
	}

	return $stat;
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Takuya Ichikawa, C<< <ichi@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Takuya Ichikawa, all rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
