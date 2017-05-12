#######################################################################
#
# $Id: SC.pm,v 1.22 2009-11-14 10:18:40 gosha Exp $
#
#              Socks Chain ( TCP only )
#
# Copyright (C)  Okunev Igor gosha@prv.mts-nn.ru 2002-2006
#
#      All rights reserved. This program is free software;
#      you can redistribute it and/or modify it under the
#               same terms as Perl itself.
#
########################################################################
package Net::SC;

use strict;
use vars qw( @ISA @EXPORT $VERSION );

use Fcntl qw(:DEFAULT :flock);
use Symbol;
use Config;
use Exporter;
use IO::Socket;
use MIME::Base64;

local $[ = 0;

($VERSION='$Revision: 1.21 $')=~s/^\S+\s+(\S+)\s+.*/$1/;

@ISA = qw( Exporter );

@EXPORT = qw(	socks_error

				SOCKS_GENERAL_SOCKS_SERVER_FAILURE
				SOCKS_CONNECTION_NOT_ALLOWED_BY_RUL
				SOCKS_NETWORK_UNREACHABLE
				SOCKS_HOST_UNREACHABLE
				SOCKS_CONNECTION_REFUSED
				SOCKS_TTL_EXPIRED
				SOCKS_COMMAND_NOT_SUPPORTED
				SOCKS_ADDRESS_TYPE_NOT_SUPPORTED
				SOCKS_OKAY
				SOCKS_FAILED
				SOCKS_NO_IDENT
				SOCKS_USER_MISMATCH
				SOCKS_INCOMPLETE_AUTH
				SOCKS_BAD_AUTH
				SOCKS_SERVER_DENIES_AUTH_METHOD
				SOCKS_MISSING_SOCKS_SERVER_NET_DATA
				SOCKS_MISSING_PEER_NET_DATA
				SOCKS_SOCKS_SERVER_UNAVAILABLE
				SOCKS_TIMEOUT
				SOCKS_UNSUPPORTED_PROTOCOL_VERSION
				SOCKS_UNSUPPORTED_ADDRESS_TYPE
				SOCKS_HOSTNAME_LOOKUP_FAILURE
		);

#
# Расширенные сообщения об ошибках
#
use constant SOCKS_MSG => {
	1	=>	'general SOCKS server failure',			# SOCKS5
	2	=>	'connection not allowed by ruleset',
	3	=>	'network unreachable',
	4	=>	'host unreachable',
	5	=>	'connection refused',
	6	=>	'TTL expired',
	7	=>	'command not supported',
	8	=>	'address type not supported',
	90	=>	'okay',									# SOCKS4
	91	=>	'failed',
	92	=>	'no ident',
	93	=>	'user mismatch',
	100	=>	'incomplete auth',						# generic
	101	=>	'bad auth',
	102	=>	'server denies auth method',
	202	=>	'missing SOCKS server net data',
	203	=>	'missing peer net data',
	204	=>	'SOCKS server unavailable',
	205	=>	'timeout',
	206	=>	'unsupported protocol version',
	207	=>	'unsupported address type',
	208	=>	'hostname lookup failure'
};

#
# Доствпные параметры конфигурации сокс серверов
#
use constant SOCKS_PARAM => {
	addr				=> 1,
	port				=> 2,
	user_id				=> 3,
	user_pswd			=> 4,
	protocol_version	=> 5,

	attempt_cnt			=> 6,
	last_check_time		=> 7,

	cd					=> 8,
	addr_type			=> 9,
	listen_addr			=> 10,
	listen_port			=> 11,
	prev_user_id		=> 12
};

#
#  Коды возврвта сокс серверов.
#
sub SOCKS_GENERAL_SOCKS_SERVER_FAILURE		{ 1 };

sub SOCKS_CONNECTION_NOT_ALLOWED_BY_RULESET	{ 2 };

sub SOCKS_NETWORK_UNREACHABLE				{ 3 };

sub SOCKS_HOST_UNREACHABLE					{ 4 };

sub SOCKS_CONNECTION_REFUSED				{ 5 };

sub SOCKS_TTL_EXPIRED						{ 6 };

sub SOCKS_COMMAND_NOT_SUPPORTED				{ 7 };

sub SOCKS_ADDRESS_TYPE_NOT_SUPPORTED		{ 8 };

sub SOCKS_OKAY								{ 90 };

sub SOCKS_FAILED							{ 91 };

sub SOCKS_NO_IDENT							{ 92 };

sub SOCKS_USER_MISMATCH						{ 93 };

sub SOCKS_INCOMPLETE_AUTH					{ 100 };

sub SOCKS_BAD_AUTH							{ 101 };

sub SOCKS_SERVER_DENIES_AUTH_METHOD			{ 102 };

sub SOCKS_MISSING_SOCKS_SERVER_NET_DATA		{ 202 };

sub SOCKS_MISSING_PEER_NET_DATA				{ 203 };

sub SOCKS_SOCKS_SERVER_UNAVAILABLE			{ 204 };

sub SOCKS_TIMEOUT							{ 205 };

sub SOCKS_UNSUPPORTED_PROTOCOL_VERSION		{ 206 };

sub SOCKS_UNSUPPORTED_ADDRESS_TYPE			{ 207 };

sub SOCKS_HOSTNAME_LOOKUP_FAILURE			{ 208 };

#
# Конструктор...
#
# Возвращает ссылку на созданный обьект.
#
sub new {
	my ( $class, %conf ) = @_;
	my $self = bless {}, $class;
	my $key;
	local $_;

	my %def_conf = (
						CHAIN_FILE		=> $ENV{HOME} . '/.sc.conf',
						LOG_FILE		=> undef,
						TIMEOUT			=> 180,

						CHAIN_FILE_DATA	=> undef,

						CHECK_DELAY		=> 24 * 3600,

						DEBUG			=> 0x09,
						CHAIN_LEN		=> 10,
						RANDOM_CHAIN	=> 0,

						RESTORE_TYPE	=> 0,
						AUTO_SAVE		=> 0,
						LOOP_CONNECT	=> 0x02, # 0x01 - проверка Socks 5
											     # 0x02 - проверка Socks 4
											     # 0x04 - проверка HTTP proxies
						LOG_FH			=> undef,

						SYSLOG			=> 0,

						HTTP_CLIENT		=> 'Proxy chain client $Id: SC.pm,v 1.21 2009-11-14 10:18:40 gosha Exp $',

						LOG_SOCKS_FIELD	=> [ qw( addr port user_id protocol_version ) ]
	);
	#
	# Инициализируем значения по умолчанию, и данные переданные в качестве
	# параметров конфигурации...
	#
	# Внутри данные хранятся с префиксами CFG_
	#
	foreach $key ( keys %conf ) {
		$_ = uc($key);
		if ( exists $def_conf{$_} ) {
			$self->{"CFG_$_"} = $conf{$key};
		}
	}
	foreach $key ( keys %def_conf ) {
		unless ( exists $self->{"CFG_$key"} ) {
			$self->{"CFG_$key"} = $def_conf{$key};
		}
	}
	#
	# Готовим место для данных из файла конфигурации
	#
	undef $self->{CFG_CHAIN_DATA};

	unless ( defined $self->configure( 'TIMEOUT' ) ) {
		$self->configure( TIMEOUT => 0 );
	}
	#
	# Если установлена переменная SYSLOG то лог пишется через:
	# *nix - syslogd,
	# win32 - eventlog,
	# иначе если возможно открываем LOG файл, так же можно напрямую передать
	# дескриптор файла  в LOG_FH, но тогда надо чтоб LOG_FILE был undef...
	#
	if ( $self->configure( 'SYSLOG' ) ) {
		if ( $^O =~ /[Ww]in32/ ) {
			require Win32::EventLog;

			$self->configure( 'LOG_FH' => Win32::EventLog->new( 'sc45', '' ) );

			unless ( defined $self->configure( 'LOG_FH' ) ) {
					$self->configure( SYSLOG => 0 );
					$self->log_error( "Cannot open EventLog:" . Win32::GetLastError() );
			}
		} else {
			require Sys::Syslog;
			import  Sys::Syslog qw(:DEFAULT setlogsock );

			if ( $^O ne 'solaris' && $^O ne 'freebsd' &&
					eval { &Sys::Syslog::_PATH_LOG() } ) {

				unless ( defined setlogsock( 'unix' ) ) {
					$self->configure( SYSLOG => 0 );
					$self->log_error("Can't `setlogsock' : $!");
				}
			}
			if ( not defined openlog( 'sc45', 'cons,pid', 'daemon') ) {
				$self->configure( SYSLOG => 0 );
				$self->log_error("Can't `openlog' : $!");
			}
		}
	} elsif ( defined $self->configure( 'LOG_FILE' ) ) {
		$key = gensym;
		$self->configure( LOG_FH => $key );
		if ( open ( $key , '>>' . $self->configure( 'LOG_FILE' ) ) ) {
			select((select($key), $| = 1)[0]);
		} else {
			$self->configure( LOG_FH => undef );
			$self->log_error("Can't open file " . $self->configure('LOG_FILE') ." : $!");
			ungensym $key;
		}
	}

	return $self;
}

#
# Читает/устанавливает переменные из 'конфигурационного хеша'
# ( тот который CFG_... )
# Если задано 2 аргумента то устанавливается переменная
# с именем `первый аргумент' в значение `второй аргумент',
# и возвращает данное значение.
# Если задан один аргумент то возвращает переменную с
# именем `первый аргумент'...
#
sub configure {
	my ( $self, $section, $var ) = @_;
	local $_;

	unless ( exists $self->{ 'CFG_' . uc($section) } ) {
		$self->log_error("Use unknown configuration variable : `$section'");
		return undef;
	} elsif ( uc($section) eq 'CHAIN_DATA' and (caller)[0] ne __PACKAGE__ ) {
		#
		# Маленькая кучка соломки, от изменения данных конфигурационного файла...
		#
		return $self->{ 'CFG_' . uc($section) };
	} else {
		if ( scalar @_ > 2 ) {
			$self->{ 'CFG_' . uc($section) } = $var;
		}
		return $self->{ 'CFG_' . uc($section) };
	}
}

#
# Соединение с удаленной машиной через socks цепь.
#
# Ну это вроде как просто обертка для create_chain,
# плюс автоматическое чтение конфигов.
#
# Возвращает SOCKS_OK если все OK
#
sub connect {
	my ( $self, $peer_host, $peer_port ) = @_;
	my $rc;
	local $_;

	unless ( defined $self->configure( 'CHAIN_DATA' ) ) {
		unless ( ( $rc = $self->read_chain_data ) == SOCKS_OKAY ) {
			return $rc;
		}
		if ( $self->configure( 'AUTO_SAVE' ) ) {
			$self->restore_cfg_data;
		}
	}

	$rc = $self->create_chain( $peer_host, $peer_port, 1 );

	if ( $self->configure( 'AUTO_SAVE' ) ) {
		$self->dump_cfg_data;
	}

	return $rc;
}

#
# Установка связи для принятия соединений через socks цепь.
#
# Ну это вроде как просто обертка для create_chain,
# плюс автоматическое чтение конфигов.
#
# Возвращает SOCKS_OK если все OK
#
sub bind {
	my ( $self, $peer_host, $peer_port ) = @_;
	my $rc;
	local $_;

	unless ( defined $self->configure( 'CHAIN_DATA' ) ) {
		unless ( ( $rc = $self->read_chain_data ) == SOCKS_OKAY ) {
			return $rc;
		}
		if ( $self->configure( 'AUTO_SAVE' ) ) {
			$self->restore_cfg_data;
		}
	}

	$rc = $self->create_chain( $peer_host, $peer_port, 2 );

	if ( $self->configure( 'AUTO_SAVE' ) ) {
		$self->dump_cfg_data;
	}

	return $rc;
}

#
# Ждет соединение удаленной машины, через цепочку
# Socks серверов.
#
sub accept {
	my $self = shift;
	local $_;

	if ( $self->socks_param( 'protocol_version' ) == 4 ) {
		return $self->get_resp4;
	} elsif ( $self->socks_param('protocol_version') == 5 ) {
		return $self->get_resp5;
	} else {
		return SOCKS_UNSUPPORTED_PROTOCOL_VERSION;
	}
}

#
# Возвращает сокет цепочки socks'ов
#
sub sh {
	my $self = shift;

	return $self->{sock_h};
}

#
# Закрывает соединение через socks цепь.
#
sub close {
	my $self = shift;

	$self->sh->shutdown(2);

	$self->sh->close;

	undef $self->{sock_h};
}

#
# Возвращает параметры сеанса работы последнего socks сервера
#
# Возможные параметры : listen_addr, listen_port, proxy_id, etc...
#
# при отсутствии $param возвращает ссылку на хеш со всеми
# имеющимися параметрами...
#
# Если не задан $id то берутся данные о последнем socks сервере цепочки...
#
# При установленном $value параметр param устанавливается в
# данное значение.
#
sub socks_param {
	my ( $self, $param, $value, $id ) = @_;
	local $_;

	unless ( defined $id ) {
		$id = $self->{__last_socks};
	}
	unless ( defined $id ) {
		return undef;
	} elsif ( not defined $param ) {
		return $self->configure( 'CHAIN_DATA' )->[ $id ];
	} elsif ( not exists SOCKS_PARAM->{$param} ) {
		$self->log_error("Use unknown socks parameter: `$param'");
		return undef;
	} elsif ( defined $value ) {
		return $self->configure( 'CHAIN_DATA' )->[ $id ]->{$param} = $value;
	} elsif ( not exists $self->configure( 'CHAIN_DATA' )->[ $id ]->{$param} ) {
		return undef;
	} else {
		return $self->configure( 'CHAIN_DATA' )->[ $id ]->{$param};
	}
}

#
# Выводит текстовое сообщение в соответствующее коду возврата
# socks сервера.
#
sub socks_error {
	if ( defined $_[0] ) {
		return SOCKS_MSG->{$_[0]} || $_[0];
	} else {
		return undef;
	}
}

#
# Читает конфиг для модуля Net::SC. Формат:
#
# #host           :   port    : uid   :   pswd    : socks_proto
# 192.168.1.90    :   1080    :       :           :   5
#
# В качестве комментариев используется `#' в начале строки,
# пустые строки пропускаются. Данные записываются в массив
# CFG_CHAIN_DATA, который состоит из ссылок на хеш вида:
#   0  addr				- имя socks сервера
#   1  port				- порт socks сервера
#   2  user_id			- пользователь socks
#   3  user_pswd		- пароль пользователя socks
#   4  protocol_version	- протокол socks сервера ( 4 или 5 или 0 (для http) )
#   5  last_check_time	- время последней проверки сервера ( unixtime )
#   6  attempt_cnt		- количество неудачных проверок ( 1 - все ок )
#
# Если все OK то возвращает SOCKS_OKAY
#
# С версии 1.17 также можно отказаться от чтения данных из конфигурационного
# файла ( new( CHAIN_FILE_DATA => [ 'str1', .., 'strN' ] ) )
# где strX - строка в формате описанном выше...
#
sub read_chain_data {
	my $self = shift;
	local $_;

	$self->configure( CHAIN_DATA => [] );

	my @data;

	if ( defined $self->configure( 'CHAIN_FILE_DATA' ) and
		 ref $self->configure( 'CHAIN_FILE_DATA' ) eq 'ARRAY' ) {

		 @data = @{ $self->configure( 'CHAIN_FILE_DATA' ) };
	} else {
		my $sym = gensym;

		unless ( open($sym, '<' . $self->configure( 'CHAIN_FILE' ) ) ) {
			$self->log_error("Can't open file " . $self->configure( 'CHAIN_FILE' ) ." : $!");
			return SOCKS_FAILED;
		}

		my_flock ( $sym, LOCK_SH );

		@data = <$sym>;

		CORE::close $sym;

		ungensym $sym;
	}

	chomp @data;

	for my $line ( 0 .. $#data ) {

		next if $data[$line] =~ /^#/ || $data[$line] =~ /^\s*$/;

		my ( $socks_host, $socks_port,
			$socks_user, $socks_pswd, $socks_proto ) = split( /\s*:\s*/, $data[$line] );

		unless ( defined $socks_host and length $socks_host ) {
			$self->log_error( "Parse config: host name not defined [ $line ]" );
			next;
		}
		unless ( defined $socks_port and $socks_port > 0 ) {
			$self->log_error( "Parse config: bad number port [ $line ]" );
			next;
		}
		unless (	defined $socks_proto and
					length( $socks_proto ) and
					( $socks_proto == 4 or $socks_proto == 5 or $socks_proto == 0 ) ) {

			$socks_proto = 5;
		}
		unless ( defined $socks_user ) {
			$socks_user = '';
		}
		unless ( defined $socks_pswd ) {
			$socks_pswd = '';
		}
		push @{$self->configure( 'CHAIN_DATA' )}, {
						addr				=> $socks_host,
						port				=> $socks_port,
						user_id				=> $socks_user || '',
						user_pswd			=> $socks_pswd || '',
						protocol_version	=> $socks_proto,
						last_check_time		=> 0,
						attempt_cnt			=> 0 };
	}

	if ( scalar @{$self->configure( 'CHAIN_DATA' )} ) {
		return SOCKS_OKAY;
	} else {
		$self->log_error('Configuration file is empty');
		return SOCKS_FAILED;
	}
}

#
# Возвращает количество Socks серверов с `непросроченным'
# временем пользования, т.е. не `отдыхающих' по таймауту
# в связи с недоступностью
#
sub get_socks_count {
	my $self = shift;
	local $_;

	unless ( defined $self->configure( 'CHAIN_DATA' ) ) {
		return 0;
	} else {
		return scalar ( grep {
					$self->socks_param( 'last_check_time', undef, $_ ) + ( $self->configure( 'CHECK_DELAY' ) * $self->socks_param( 'attempt_cnt', undef, $_ ) ) < time
				} ( 0 .. $#{$self->configure( 'CHAIN_DATA' )} ) );
	}
}

#
# Помечает прокси с порядковым номером в конфиге $id как временно
# недоступный на CHECK_DELAY * КОЛИЧЕСТВО_НЕУДАЧНЫХ_КОННЕКТОВ секунд -
# если $status != SOCKS_OKAY, иначе очищает счетчик неудачных попыток...
#
# Если все нормально возвращает SOCKS_OKAY
#
sub mark_proxy {
	my ( $self, $id, $status ) = @_;
	local $_;

	unless ( defined $self->configure( 'CHAIN_DATA' ) and defined $id ) {
		unless ( defined $id ) {
			$self->log_error('Socks identifer not defined');
		} else {
			$self->log_error('Configuration data not defined...');
		}
		return SOCKS_FAILED;
	}

	if ( $status == SOCKS_OKAY ) {
		$self->socks_param( 'last_check_time', time - 1, $id );
		$self->socks_param( 'attempt_cnt', 0, $id );
	} else {
		$self->socks_param( 'last_check_time', time, $id );
		$self->socks_param( 'attempt_cnt', ( $self->socks_param( 'attempt_cnt' ) || 0 ) + 1, $id );
	}

	return SOCKS_OKAY;
}

#
# Сбрасывает текущее состояние данных о Socks серверах из конфига в
# хеш файл, на диске. Используется для последующего восстановления
# данных о `дохлых' серверах
#
# Если все нормально возвращает SOCKS_OKAY
#
sub dump_cfg_data {
	my $self = shift;
	my ( $sym, %hash, $id, $key );
	local $_;

	unless ( defined $self->configure( 'CHAIN_DATA' ) ) {
		return SOCKS_OKAY;
	}

	unless ( dbmopen ( %hash, $self->configure( 'CHAIN_FILE' ) . '-cache', 0600 ) ) {
		$self->log_error("Can't create dump hash : $!");
		return SOCKS_FAILED;
	}
	$sym = gensym;
	#
	# В качестве лок файла - используем текстовы конфигурационный файл
	#
	unless ( open( $sym, '<'. $self->configure( 'CHAIN_FILE' ) ) ) {
		$self->log_error("Can't open file " . $self->configure( 'CHAIN_FILE' ) . " : $!");
		dbmclose %hash;
		return SOCKS_FAILED;
	}
	my_flock ( $sym, LOCK_EX );

	foreach $id ( 0 .. $#{$self->configure( 'CHAIN_DATA' )} ) {
		$key = join( "\x00",	$self->configure( 'CHAIN_DATA' )->[$id]->{addr},
								$self->configure( 'CHAIN_DATA' )->[$id]->{port},
								$self->configure( 'CHAIN_DATA' )->[$id]->{user_id} || '',
								$self->configure( 'CHAIN_DATA' )->[$id]->{user_pswd} || '',
								$self->configure( 'CHAIN_DATA' )->[$id]->{protocol_version}
					);
		unless ( defined $hash{$key} ) {
			$hash{$key} = join( "\x00", $self->dump_cfg_filter( %{$self->configure( 'CHAIN_DATA' )->[$id]} ) );
		}
	}
	dbmclose %hash;
	CORE::close $sym;
	ungensym $sym;

	return SOCKS_OKAY;
}

#
# Читает данные записанные на диск процедурой dump_cfg_data
#
# Данные хранятся в .db файле с именем идентичным имени конфига + '-cache',
# но с добавленным расширением .db ( или .pag & .dir у кого как )
#
# Если все в порядке возвращает SOCKS_OKAY
#
sub restore_cfg_data {
	my $self = shift;
	my ( $sym, %hash, %hash2, $id, $key );
	local $_;

	unless ( defined $self->configure( 'CHAIN_DATA' ) ) {
		return SOCKS_OKAY;
	}

	unless ( dbmopen ( %hash, $self->configure( 'CHAIN_FILE' ) . '-cache', 0600 ) ) {
		$self->log_error("Can't open damp hash : $!");
		return SOCKS_FAILED;
	}
	#
	# Пустой файл ( только что созданный )
	#
	if ( scalar keys %hash == 0 ) {
		dbmclose %hash;
		return SOCKS_OKAY;
	}

	$sym = gensym;
	#
	# В качестве лок файла - используем текстовы конфигурационный файл
	#
	unless ( open( $sym, '<'. $self->configure( 'CHAIN_FILE' ) ) ) {
		$self->log_error("Can't open file " . $self->configure( 'CHAIN_FILE' ) . " : $!");
		dbmclose %hash;
		return SOCKS_FAILED;
	}
	my_flock ( $sym, LOCK_SH );

	#
	# Создаем ключи и соответствующие им индексы
	#
	foreach $id ( 0 .. $#{$self->configure( 'CHAIN_DATA' )} ) {
		$key = join( "\x00",	$self->configure( 'CHAIN_DATA' )->[$id]->{addr},
								$self->configure( 'CHAIN_DATA' )->[$id]->{port},
								$self->configure( 'CHAIN_DATA' )->[$id]->{user_id} || '',
								$self->configure( 'CHAIN_DATA' )->[$id]->{user_pswd} || '',
								$self->configure( 'CHAIN_DATA' )->[$id]->{protocol_version}
					);
		#
		# Может быть несколько одинаковых серверов в конфиге...
		#
		push @{$hash2{ $key }}, $id;
	}

	#
	# Восстанавливаем значения из кэша
	#
	foreach $key ( keys %hash ) {
		if ( not exists $hash2{$key} and $self->configure( 'RESTORE_TYPE' ) == 1 ) {
			delete $hash{$key};
		} else {
			foreach $id ( @{$hash2{$key}} ) {
				$self->configure( 'CHAIN_DATA' )->[$id] = { $self->dump_cfg_filter( split(/\x00/, $hash{$key}) ) };
			}
		}
	}
	dbmclose %hash;
	CORE::close $sym;
	ungensym $sym;

	return SOCKS_OKAY;
}

#
# Проверяет данные подлежащие кешированию на наличие \x00 и \n,
# проверяет корректность используемых параметров для socks_param
#
# Разбор с помощью массива а не хеша сделан для возможности
# использования внешней сортировки ключей.
#
# Возвращает проверенный массив элементов
#
sub dump_cfg_filter {
	my $self = shift;
	my ( $key, $val, @param );
	local $_;

	while ( defined ( $key = shift @_ ) ) {
		$val = shift;

		next unless exists SOCKS_PARAM->{$key};

		unless ( defined $val ) {
			push @param, $key, '';
		} else {
			$val =~ s#[\x00\n]##g;
			push @param, $key, $val;
		}
	}
	return @param;
}

#
# Создает цепочку Socks серверов до/для хоста $peer_host и порта $peer_port
# $type - тип сервиса : 1 - connect
#                     : 2 - bind
#
# До использования данной процедуры должен быть прочитан конфигурационный
# файл.
#
# Если все Ok то возвращает SOCKS_OKAY
#
sub create_chain {
	my ( $self, $peer_host, $peer_port, $type ) = @_;
	my ( $host_ind, $rc );
	my ( @hosts_id );
	local $_;

	unless ( defined $self->configure( 'CHAIN_DATA' ) ) {
		$self->log_error('Configuration data not defined...');
		return SOCKS_FAILED;
	} elsif ( not defined $peer_host or not defined $peer_port ) {
		$self->log_error('Destination host or destination addr not defined...');
		return SOCKS_MISSING_PEER_NET_DATA;
	} elsif ( not defined $type or ( $type != 1 and $type != 2 ) ) {
		return SOCKS_COMMAND_NOT_SUPPORTED;
	} elsif ( $self->configure( 'CHAIN_LEN' ) < 1 ) {
		$self->log_error('Length of chain very small...');
		return SOCKS_FAILED;
	} elsif ( $self->configure( 'RANDOM_CHAIN' ) > 0 ) {
		#
		# Random select proxies
		#
  	    @hosts_id = ( grep {
							$self->socks_param( 'last_check_time', undef, $_ ) + ( $self->configure( 'CHECK_DELAY' ) * $self->socks_param( 'attempt_cnt', undef, $_ ) ) < time
						} ( sort { rand(10) <=> rand(10) } ( 0 .. $#{$self->configure( 'CHAIN_DATA' )} ) ) );
	} else {
		#
		# Select proxies in order definition
		#
  	    @hosts_id = ( grep {
							$self->socks_param( 'last_check_time', undef, $_ ) + ( $self->configure( 'CHECK_DELAY' ) * $self->socks_param( 'attempt_cnt', undef, $_ ) ) < time
						} ( 0 .. $#{$self->configure( 'CHAIN_DATA' )} ) );
	}

	CHAIN:{
		if ( defined $self->sh ) {
			$self->close;
		}

		if ( scalar @hosts_id < $self->configure( 'CHAIN_LEN' ) ) {
			$self->log_error("Can't create socks chain, many servers not response...");
			return SOCKS_FAILED;
		}

		#
		# Connect to first socks/HTTP proxy
		#
		$self->{__last_socks} = $hosts_id[0];
		unless ( $self->first_connect == SOCKS_OKAY ) {
			shift @hosts_id;
			redo CHAIN;
		}

		for ( $host_ind = 0; $host_ind <= $#hosts_id; $host_ind++ ) {
			#
			# Last proxy identifier...
			#
			$self->{__last_socks} = $hosts_id[$host_ind];

			last if $host_ind >= $self->configure( 'CHAIN_LEN' ) - 1;

			#
			# Check proxies for connection ( create loop connection )
			#
			if ( $self->socks_param( 'protocol_version' ) == 5 and $self->configure( 'LOOP_CONNECT' ) & 0x01 ) {
				$rc = $self->request_socks5( 1,
						$self->socks_param('addr',undef,$hosts_id[$host_ind]),
						$self->socks_param('port',undef,$hosts_id[$host_ind]));
			} elsif ( $self->socks_param( 'protocol_version' ) == 0 and $self->configure( 'LOOP_CONNECT' ) & 0x04 ) {
				$rc = $self->request_http( 1,
						$self->socks_param('addr',undef,$hosts_id[$host_ind]),
						$self->socks_param('port',undef,$hosts_id[$host_ind]));
			} elsif ( $self->socks_param( 'protocol_version' ) == 4 and $self->configure( 'LOOP_CONNECT' ) & 0x02 ) {
				$rc = $self->request_socks4( 1,
						$self->socks_param('addr',undef,$hosts_id[$host_ind]),
						$self->socks_param('port',undef,$hosts_id[$host_ind]));
			} else {
				$rc = SOCKS_OKAY;
			}

			#
			# LoopCheck failed
			#
			unless ( $rc == SOCKS_OKAY ) {
				$self->mark_proxy( $self->{__last_socks}, $rc );

				if ( $self->configure( 'DEBUG' ) & 0x01 ) {
					$self->debug( "Socks error[$rc]: " . $self->log_str( $self->{ __last_socks }) );
				}
				if ( $self->configure( 'DEBUG' ) & 0x08 ) {
					$self->debug( '            [ ' . ( socks_error($rc) ) . ' ]' );
				}
				splice( @hosts_id, $host_ind, 1);

				redo CHAIN;
			}

			#
			# Create connection to next proxy server
			#
			if ( $self->socks_param( 'protocol_version' ) == 5 ) {
				$rc = $self->request_socks5( 1,
							$self->socks_param('addr',undef,$hosts_id[$host_ind+1]),
							$self->socks_param('port',undef,$hosts_id[$host_ind+1]));
			} elsif ( $self->socks_param( 'protocol_version' ) == 0 ) {
				$rc = $self->request_http( 1,
							$self->socks_param('addr',undef,$hosts_id[$host_ind+1]),
							$self->socks_param('port',undef,$hosts_id[$host_ind+1]));
			} else {
				$rc = $self->request_socks4( 1,
							$self->socks_param('addr',undef,$hosts_id[$host_ind+1]),
							$self->socks_param('port',undef,$hosts_id[$host_ind+1]));
			}

			$self->mark_proxy( $self->{__last_socks}, $rc );

			unless ( $rc == SOCKS_OKAY ) {
				if ( $self->configure( 'DEBUG' ) & 0x01 ) {
					$self->debug( "Socks error[$rc]: " . $self->log_str( $hosts_id[$host_ind+1] ) );
				}
				if ( $self->configure( 'DEBUG' ) & 0x08 ) {
					$self->debug( '            [ ' . ( socks_error($rc) ) . ' ]' );
				}
				splice( @hosts_id, $host_ind+1, 1);
				redo CHAIN;
			}
		}
	}

	if ( $host_ind < $self->configure( 'CHAIN_LEN' ) - 1 ) {
		$self->log_error("Can't create socks chain, many servers not response...");
		return SOCKS_FAILED;
	}

	#
	# Create connectino to destination addr/port
	#
	if ( $self->socks_param( 'protocol_version' ) == 5 ) {
		$rc = $self->request_socks5( $type, $peer_host, $peer_port );
	} elsif ( $self->socks_param( 'protocol_version' ) == 0 ) {
		$rc = $self->request_http( $type, $peer_host, $peer_port  );
	} else {
		$rc = $self->request_socks4( $type, $peer_host, $peer_port  );
	}

	$self->mark_proxy( $self->{__last_socks}, $rc );

	return $rc;
}

#
# Процедура блокировки файлов, с учетом проверки на возможности системы...
#
sub my_flock {
	my ( $fh, $mode ) = @_;

	return 1 unless defined $Config::Config{d_flock};

	flock ( $fh, $mode );
}

#
# Используется для отладки - при использовании SYSLOG'а сообщения пишутся
# в `debug', если syslog не пользуется то вызывается log_error...
#
sub debug {
	my $self = shift;

	#
	# syslogd
	#
	if ( ref $self and $self->configure( 'SYSLOG' ) and $^O !~ /[Ww]in32/ ) {
		foreach ( @_ ) {
			syslog( 'debug', '%s [ %d ]', $_, (caller)[-1] ) unless /^\s*$/;
		}
		return 1;
	}
	#
	# Все остальное
	#
	return log_error( $self, @_);
}

#
# Пишет сообщения об ошибках в log файл или передает syslogd.
# Можно было конечно Carp.pm пользовать, но привычка...
#

sub log_error {
	my $self = shift;
	my $sym;
	local $_;

	if ( ref $self and $self->configure( 'SYSLOG' ) and $^O !~ /[Ww]in32/ ) {
		#
		# syslogd
		#
		foreach ( @_ ) {
			syslog( 'warning', '%s [ %d ]', $_, (caller)[-1] ) unless /^\s*$/;
		}
	} elsif (	ref $self and
				$self->configure( 'SYSLOG' ) and
				defined $self->configure( 'LOG_FH' ) ) {
		#
		# eventlog
		#
		$self->configure('LOG_FH')->Report( {
				Category	=> 20,
				EventType	=> Win32::EventLog::EVENTLOG_INFORMATION_TYPE(),
				Strings		=> join( "\n", '', @_ ),
				Data		=> '',
				EventID		=> 0
		} );
	} else {
		#
		# write co STDERR
		#
		unless ( ref $self ) {
			unshift @_, $self;
			$sym = \*STDERR;
		} elsif ( not defined ( $sym = $self->configure( 'LOG_FH' ) ) ) {
				$sym = \*STDERR;
		}
		my_flock ( $sym, LOCK_EX );
		foreach ( @_ ) {
			printf $sym "%2.2d/%2.2d %2.2d:%2.2d:%2.2d [ %5.5d : %d ] : %s\n",(localtime(time))[3,4,2,1,0], $$, (caller)[-1], $_ unless /^\s*$/;
		}
		my_flock ( $sym, LOCK_UN );
	}

	return 1;
}

#
# Возвращает лог строку о соединении id...
#
sub log_str {
	my ( $self, $id ) = @_;
	my $str;
	local $_;

	$str = '';

	foreach ( @{$self->configure('LOG_SOCKS_FIELD')} ) {
		if ( defined $self->socks_param( $_, undef, $id ) ) {
			$str .= ' : ' . $self->socks_param( $_, undef, $id );
		} else {
			$str .= ' : ';
		}
	}

	return substr $str, 3;
}

#
# Производит коннект в `открытую' к первому socks серверу.
#
# Если все Ok возвращает SOCKS_OKAY
#
sub first_connect {
	my $self = shift;
	local $_;

	$self->{sock_h} = new IO::Socket::INET (
			PeerAddr	=> $self->socks_param( 'addr' ),
			PeerPort	=> $self->socks_param( 'port' ),
			Timeout		=> $self->configure( 'TimeOut' ),
			Proto		=> 'tcp'
		);

	unless ( defined $self->sh ) {
		$self->log_error( $@, "Can't create network socket... : $!" );
		return SOCKS_FAILED;
	}

	binmode $self->sh;

	$self->sh->autoflush(1);

	return SOCKS_OKAY;
}

#
# Читает данные из сокета $fh1. $fh2 может быть как ссылкой на сокет
# так и ссылкой на скаляр, для первого случая должно быть определено
# значение $cnt. Если $fh2 ссылка на сокет ( файловый дескриптор )
# то данные читаются до 'конца' из $fh1 и пишутся в $fh2
#
# Возвращает  0 - при таймауте
#            -1 - при чтении 0 байт
#             1 - все Ok
sub read_data {
	my ( $self, $fh1, $fh2, $cnt ) = @_;
	my ( $char, $rc, $rin );
	local $_ = 1;

	unless ( defined $cnt ) {
		$cnt = 0;
	}

	vec( $rin = '', fileno( $fh1 ), 1 ) = 1;

	$rc = eval {
		local $SIG{__DIE__}	= sub { die @_ };
		local $SIG{PIPE}	= sub { die "Pipe error\n" };
		if ( ref $fh2 eq 'SCALAR' ) {
			$$fh2 = '';

			#
			# HTTP proxies support
			#
			my $is_http_proxy = 0;
			$is_http_proxy = 1 if $self->socks_param('protocol_version') == 0;

			#
			# \r\n\r\n - for http proxies support
			#
			while( $_ && ($is_http_proxy ? $$fh2 !~ /\r\n\r\n$/ : $cnt-- ) ) {
				unless ( select( $rin, undef, undef, $self->configure( 'TimeOut' ) ) ) {
					die "Read data - timeout\n";
				}
				$_ = sysread( $fh1, $char, 1 );
				$$fh2 .= $char;
			}
		} else {
			while ( $_ ) {
				unless ( select( $rin, undef, undef, $self->configure( 'TimeOut' ) ) ) {
					die "Read data - timeout\n";
				}
				$_ = sysread( $fh1, $char, 1 );
				print $fh2 $char;
			}
		}
	};

	unless ( defined $rc ) {
		if ( $@ eq "Read data - timeout\n" ) {
			$self->log_error( 'Timeout...' );
			return 0;
		} else {
			$self->log_error( $@ );
			return 0;
		}
	}

	if ( $_ < 1 ) {
		return -1;
	} elsif ( ref $fh2 eq 'SCALAR' and $self->configure( 'DEBUG' ) & 0x02 ) {
		$self->debug('READ: ' . unpack('H*', $$fh2) );
	}
	return 1;
}

#
# Пишет данные @data в сокет $fh ( сокет вроде как FH Socks сервера )
#
# Возвращает 1 - все Ok
#            0 - какие то проблемы...
#
sub print_data {
	my ( $self, $fh, @data ) = @_;
	my $rc;
	local $_;

	$rc = eval {
		local $SIG{__DIE__}	= sub { die @_ };
		local $SIG{PIPE}	= sub { die "Pipe error\n" };

		print $fh @data;
	};

	unless ( defined $rc ) {
		$self->log_error( $@ || 'Print data error...' );
		return 0;
	} else {
		if ( $self->configure( 'DEBUG' ) & 0x04 ) {
			$self->debug('WRITE: ' . unpack('H*', join('', @data) ) );
		}
		return 1;
	}
}

#
# Запрос к 4 соксу...
#
# req_num - тип запроса к socks серверу:
#     1 - connect
#     2 - bind
#
# Если все OK то возвращает SOCKS_OKAY
#
sub request_socks4 {
	my ( $self, $req_num, $peer_host, $peer_port ) = @_;
	local $_;

	#
	# Print debug message
	#
	if ( $self->configure( 'DEBUG' ) & 0x01 ) {
		$self->debug( 'Connect over socks4: ' . $self->log_str( $self->{__last_socks}) . ", to $peer_host:$peer_port" );
	}

	$self->print_data( $self->sh,
			pack ( 'CCn', 4, $req_num, $peer_port ),
			inet_aton( $peer_host ),
			$self->socks_param( 'user_id' ),
			pack 'x' );

	return $self->get_resp_socks4;
}

#
# Запрос к 5 соксу...
#
# req_num - тип запроса к socks серверу:
#     1 - connect
#     2 - bind
#
# Если все OK то возвращает SOCKS_OKAY
#
sub request_socks5 {
	my ( $self, $req_num, $peer_host, $peer_port ) = @_;
	local $_;

	#
	# Print debug message
	#
	if ( $self->configure( 'DEBUG' ) & 0x01 ) {
		$self->debug( 'Connect over socks5: ' . $self->log_str( $self->{__last_socks}) . ", to $peer_host:$peer_port" );
	}

	#
	# Check socks5 auth
	#
	unless ( ( my $rc = $self->socks5_auth ) == SOCKS_OKAY ) {
		$self->close;
		return $rc;
	}

	my $addr_type;

	if ( $peer_host =~ /[a-zA-Z]/) {	# FQDN?
		$addr_type = 3;
		$peer_host = pack('C',length( $peer_host )) . $peer_host;
	} else {									# nope.  Must be dotted-dec.
		$addr_type = 1;
		$peer_host = inet_aton( $peer_host );
	}

	$self->print_data( $self->sh,
			pack ( 'CCCC', 5, $req_num, 0, $addr_type ),
			$peer_host,
			pack( 'n', $peer_port ) );

	return $self->get_resp_socks5;
}

#
# Request to HTTP proxies
#
# req_num - тип запроса к socks серверу:
#     1 - connect
#
# Если все OK то возвращает SOCKS_OKAY
#
sub request_http {
	my ( $self, $req_num, $peer_host, $peer_port ) = @_;
	local $_;

	#
	# Print debug message
	#
	if ( $self->configure( 'DEBUG' ) & 0x01 ) {
		$self->debug( 'Connect over http: ' . $self->log_str( $self->{__last_socks}) . ", to $peer_host:$peer_port" );
	}

	#
	# bind command not support in http proxies...
	#
	if ( $req_num == 2 ) {
		return SOCKS_COMMAND_NOT_SUPPORTED;
	}

	my $CRLF = "\015\012";

	my @headers = (	"CONNECT $peer_host:$peer_port HTTP/1.1",
					'User-Agent: ' . $self->configure( 'Http_Client' ),
					'Proxy-Connection: keep-alive' );

	#
	# Basic authorization
	#
	if (	length ( $self->socks_param( 'user_id' ) ) > 0 and
			length ( $self->socks_param( 'user_pswd' ) ) > 0 ) {

			push @headers,	'Proxy-Authorization: ' .
							'Basic ' .
							MIME::Base64::encode(
								$self->socks_param( 'user_id' )
									. ':' .
								$self->socks_param( 'user_pswd' ), ''
							);
	}

	$self->print_data( $self->sh, join( $CRLF, @headers, '', '' ) );

	return $self->get_resp_http;
}

#
# Аутентификация для 5 сокса...
#
# Если все OK то возвращает SOCKS_OKAY
#
sub socks5_auth {
	my ( $self ) = @_;
	my ( $status, $method, $received, $ver );
	local $_;

	$method = pack('C', 0);
	$status = 0;
	if (	length ( $self->socks_param( 'user_id' ) ) > 0 and
			length ( $self->socks_param( 'user_pswd' ) ) > 0 ) {

		$method .= pack('C', 2);
	}

	$self->print_data( $self->sh,
			pack ('CC', 5, length($method) ),
			$method );

	$received = '';

	if ( ! $self->read_data($self->sh, \$received, 2) or length($received) < 2 ) {
		return SOCKS_TIMEOUT;
	}

	( $ver, $method ) = unpack 'CC', $received;
	if ( $ver != 5) {
		return SOCKS_UNSUPPORTED_PROTOCOL_VERSION
	}
	if ( $method == 255 ) {
		return SOCKS_SERVER_DENIES_AUTH_METHOD
	}
	if ( $method == 2 and (
				length ( $self->socks_param( 'user_id' ) ) == 0 or
				length ( $self->socks_param( 'user_pswd' ) ) == 0 ) ) {

		return SOCKS_INCOMPLETE_AUTH;
	} elsif ( $method == 2 ) {
		$self->print_data( $self->sh,
				pack ('CC', 1, length( $self->socks_param( 'user_id' ) ) ),
				$self->socks_param( 'user_id' ),
				pack ('C', length( $self->socks_param( 'user_pswd' ) )),
				$self->socks_param( 'user_pswd' ) );

		if ( ! $self->read_data($self->sh, \$received, 2) or length($received) < 2 ) {
			return SOCKS_TIMEOUT;
		}
		( $ver, $status ) = unpack 'CC', $received;
	}

	if ( $status == 0 ) {
		return SOCKS_OKAY;
	} else {
		return SOCKS_BAD_AUTH;
	}
}

#
# Ответ 4 сокса
#
# Если все OK то возвращает SOCKS_OKAY
#
sub get_resp_socks4 {
	my ( $self ) = @_;
	my $received;
	local $_;

	$received = '';

	if ( ! $self->read_data($self->sh, \$received, 8) or length($received) < 8 ) {
		return SOCKS_TIMEOUT;
	}
	(	$self->configure( 'CHAIN_DATA' )->[ $self->{__last_socks} ]->{vn},
		$self->configure( 'CHAIN_DATA' )->[ $self->{__last_socks} ]->{cd},
		$self->configure( 'CHAIN_DATA' )->[ $self->{__last_socks} ]->{listen_port},
	) = unpack 'CCn', $received;

	$self->socks_param( 'listen_addr', inet_ntoa( substr $received, 4 ) );

	return $self->socks_param( 'cd' );
}

#
# Ответ 5 сокса
#
# Если все OK то возвращает SOCKS_OKAY
#
sub get_resp_socks5 {
	my ( $self ) = @_;
	my ( $received, $length );
	local $_;

	$received = '';

	if ( ! $self->read_data($self->sh, \$received, 4) or length($received) < 4 ) {
		return SOCKS_TIMEOUT;
	}
	(
	 $self->configure( 'CHAIN_DATA' )->[ $self->{__last_socks} ]->{vn},
	 $self->configure( 'CHAIN_DATA' )->[ $self->{__last_socks} ]->{cd},
	 $self->configure( 'CHAIN_DATA' )->[ $self->{__last_socks} ]->{socks_flag},
	 $self->configure( 'CHAIN_DATA' )->[ $self->{__last_socks} ]->{addr_type}
	) = unpack('CCCC', $received);

	if ( $self->socks_param( 'addr_type' ) == 3 ) {				# FQDN
		if ( ! $self->read_data($self->sh, \$received, 1) or length($received) < 1 ) {
			return SOCKS_TIMEOUT;
		}
		$length = unpack('C', $received);
		if ( ! $self->read_data($self->sh, \$received, $length) or length($received) < $length ) {
			return SOCKS_TIMEOUT;
		}
		unless ( $received = gethostbyname( $received ) ) {
			return SOCKS_HOSTNAME_LOOKUP_FAILURE;
		}
	} elsif ( $self->socks_param( 'addr_type' ) == 1) {			# IPv4 32 bit
		if ( ! $self->read_data($self->sh, \$received, 4) or length($received) < 4 ) {
			return SOCKS_TIMEOUT;
		}
	} else {											# IPv6, others
		return SOCKS_UNSUPPORTED_ADDRESS_TYPE;
	}

	$self->socks_param( 'listen_addr', inet_ntoa( $received ) );

	if ( ! $self->read_data($self->sh, \$received, 2) or length($received) < 2 ) {
		return SOCKS_TIMEOUT;
	}

	$self->socks_param( 'listen_port', unpack('n', $received) );

	if ( $self->socks_param( 'cd' ) == 0 ) {
		$self->socks_param( 'cd', SOCKS_OKAY );
	}

	return $self->socks_param( 'cd' );
}

#
# Ответ http прокси
#
# Если все OK то возвращает SOCKS_OKAY
#
sub get_resp_http {
	my ( $self ) = @_;
	local $_;

	my $received = '';

	if ( ! $self->read_data($self->sh, \$received, 0) or length($received) < 5 ) {
		return SOCKS_TIMEOUT;
	}

	$self->configure( 'CHAIN_DATA' )->[ $self->{__last_socks} ] = {};

	if ( $received =~ /HTTP\/\d+\.\d+\s+200/is ) {
		return SOCKS_OKAY;
	} elsif ( $received =~ /HTTP\/\d+\.\d+\s+(\d+)\s+([^\r\n]+)/is ) {
		SOCKS_MSG->{"-$1"} = $2;
		return "-$1";
	}

	return SOCKS_FAILED;
}

#
# так..., почистим за собой...
#
sub DESTROY	{};

1;

__END__

=head1 NAME

 

Net::SC - perl module for create the chain from the SOCKS/HTTP proxies.

=head1 SYNOPSIS

 

 # CONNECT TO HOST
 # ----------------

 ...
 $self = new Net::SC(
                     Timeout         => ( $opt{'to'}  || 10      ),
                     Chain_Len       => ( $opt{'l'}   || 2       ),
                     Debug           => ( $opt{'d'}   || 0x04    ),
                     Log_File        => ( $opt{'lf'}  || undef   ),
                     Random_Chain    => ( $opt{'rnd'} || 0       ),
                     Auto_Save       => 1
                  );

 die unless ref $self;

 unless ( ( $rc = $self->connect( $host, $port ) ) == SOCKS_OKAY ) {
   print STDERR "Can't connect to $host:$port [".( socks_error($rc) )."]\n";
   exit;
 }

 $sh = $self->sh;

 print $sh, "Hello !!!\n";
 ...

 --- or ---

 ...
 $self = new Net::SC(
                     Timeout         => ( $opt{'to'}  || 10      ),
                     Chain_Len       => ( $opt{'l'}   || 2       ),
                     Debug           => ( $opt{'d'}   || 0x04    ),
                     Random_Chain    => ( $opt{'rnd'} || 0       ),
                     Auto_Save       => 0,
                     Chain_File_Data => [
                                          '200.41.23.164:1080:::4:383 b/s Argentina',
                                          '24.232.88.160:1080:::4:1155 b/s Argentina',
                                          '24.2.8.160:3128:::0:HTTP proxy',
                                        ],
                  );

 die unless ref $self;

 unless ( ( $rc = $self->connect( $host, $port ) ) == SOCKS_OKAY ) {
   print STDERR "Can't connect to $host:$port [".( socks_error($rc) )."]\n";
   exit;
 }

 $sh = $self->sh;

 print $sh, "Hello !!!\n";
 ...
 $self->close;
 ...

 #  BIND THE PORT ( only SOCKS [4/5] proxies )
 # ---------------
 
 ...
 $self = new Net::SC(
                     Timeout         => ( $opt{'to'}  || 10      ),
                     Chain_len       => ( $opt{'l'}   || 2       ),
                     Debug           => ( $opt{'d'}   || 0x04    ),
                     Log_file        => ( $opt{'lf'}  || undef   ),
                     Random_chain    => ( $opt{'rnd'} || 0       ),
                     Auto_save       => 1
                  );

 die unless ref $self;

 unless ( ( $rc = $self->bind( $host, $port ) ) == SOCKS_OKAY ) {
   print STDERR "Can't bind port [".( socks_error($rc) )."]\n";
   exit;
 }

 print STDOUT "Binding the port : ",
               $self->socks_param('listen_port'), "\n";
 print STDOUT "     in the host : ",
               $self->socks_param('listen_addr'), "\n";
 print STDOUT "     for $host\n";
	
 $self->configure( TIMEOUT => 45 );
 unless ( ( $rc = $self->accept() ) == SOCKS_OKAY ) {
	return $rc;
 } else {
   $sh = $self->sh;
 }
 
 print STDOUT 'Connect from: ',
                        $self->socks_param('listen_addr'), ':',
                        $self->socks_param('listen_port'), "\n";

 print $sh 'Hello : ', $self->socks_param('listen_addr'), "\n";
 print $sh ' port : ', $self->socks_param('listen_port'), "\n";

 print STDOUT <$sh>;
 ...
 

For more information see examples: telnet_over_socks_chain.pl and accept_over_socks_chain.pl

=head1 DESCRIPTION

 

=head2 CONSTRUCTOR

 

=over 5

=item new

 

 TIMEOUT         - Time Out in seconds.

 CHAIN_LEN       - Length of chain.

 DEBUG           - Debug level ( 0x00 | 0x01 | 0x02 | 0x04 )
                   0x00 - Off
                   0x01 - Debug On
                   0x02 - Write all answers of socks servers.
                   0x04 - Write all requests of socks servers.
                   0x08 - Extended error information.

 CHAIN_FILE      - Configuration file name.

 CHAIN_FILE_DATA - Array reference. ( a format same as well as
                   in a file of a configuration ). It is possible
                   to use for data transmission about chains directly,
                   without use of a file of a configuration. At use
                   of the given parameter, parameter CHAIN_FILE is
                   ignored, that is the file of a configuration
                   is not read.

 LOG_FILE        - Log file name. if undef, writing
                   all errors to STDERR or `syslogd`

 RANDOM_CHAIN    - Rule for create the chains ( 0 || 1 ).
                   0 - create chain by index...
                   1 - create chain by random...

 CHECK_DELAY     - Delay time for the next usage this proxy if
                   the last connection failed ( in seconds )

 AUTO_SAVE       - Auto save the data of chain to the cache file. 

 LOG_FH          - File Descriptor of LOG file.

 SYSLOG          - 1 - Use syslogd ( for *nix ), or eventlog
                   ( for win32 ) for debug messages. Default 0.

 HTTP_CLIENT     - User-Agent name for http proxies


=back

=head2 METHODS

 

=over 10

=item connect

Create new connection to remote host.

 Usage:

  die unless $self->connect( $peer_host, $peer_port ) == SOCKS_OKAY;

=item bind

Binding port.

 Usage:

  die unless $self->bind( $peer_host, $peer_port ) == SOCKS_OKAY;

=item accept

Accepting connection over SOCKS

 Usage:

  die unless $self->accept() == SOCKS_OKAY;
  $sh = $self->sh;

=item sh

Returns the sock handle

 Usage:

  $sh = $self->sh;

=item close

Close the connection.

 Usage:

  $self->close;

=item configure

Returns [ and modify ] the current configuration options.

 Usage:
  
  # Change TIMEOUT
  $self->configure( TIMEOUT => 10 );

  # Returns TIMEOUT
  $timeout = $self->configure( 'TIMEOUT' );

=item socks_param

Returns parameters of the last server into the chain socks...

 Usage:

  $listen_addr = $self->socks_param( 'listen_Addr' );

 or:

  $all_param = $self->socks_param();
  $listen_addr = $all_param->{'listen_addr'};

=back

=head1 ANY ROUTINES

 

    socks_error( ERROR_CODE ) 

     Returns the error message.

    Socks error codes:

    SOCKS_GENERAL_SOCKS_SERVER_FAILURE
    SOCKS_CONNECTION_NOT_ALLOWED_BY_RUL
    SOCKS_NETWORK_UNREACHABLE
    SOCKS_HOST_UNREACHABLE
    SOCKS_CONNECTION_REFUSED
    SOCKS_TTL_EXPIRED
    SOCKS_COMMAND_NOT_SUPPORTED
    SOCKS_ADDRESS_TYPE_NOT_SUPPORTED
    SOCKS_OKAY
    SOCKS_FAILED
    SOCKS_NO_IDENT
    SOCKS_USER_MISMATCH
    SOCKS_INCOMPLETE_AUTH
    SOCKS_BAD_AUTH
    SOCKS_SERVER_DENIES_AUTH_METHOD
    SOCKS_MISSING_SOCKS_SERVER_NET_DATA
    SOCKS_MISSING_PEER_NET_DATA
    SOCKS_SOCKS_SERVER_UNAVAILABLE
    SOCKS_TIMEOUT
    SOCKS_UNSUPPORTED_PROTOCOL_VERSION
    SOCKS_UNSUPPORTED_ADDRESS_TYPE
    SOCKS_HOSTNAME_LOOKUP_FAILURE


    $self->read_chain_data();

     Reading the configuration file.

    $self->get_socks_count

     Returns the number of the socks servers

    $self->mark_proxy ( $proxy_id, $status );

     Mark the socks server with index $proxy_id how dead
     if $status not equally SOCKS_OKAY, otherwise
     clearing counter of the connection failure...

    $self->dump_cfg_data();

     Dump socks data, in the cache file.

    $self->restore_cfg_data();

     Restore socks data, from the cache file.

=head1 NOTES

 

accept method change the follow variable, which returns of the socks_param:

 listen_addr
 listen_port


Methods connect, bind, accept returnings SOCKS_OKAY if it succeeded.

Http proxies do not support bind method.

Http proxies support only Basic auth.


=head1 CONFIG FORMAT

 

 #host           :   port    : uid   :   pswd    : socks_proto
 192.168.1.90    :   1080    :       :           :   5
 192.18.122.90   :   3128    : bbb   :  ccc      :   0
 ...

 You can use the comments in the configuration file, for 
 this you must write `#' in the beginning of string...


=head1 THANKS

 JoNO <jonozzz[at]yahoo.com> - for ideas of a writing of support http a proxy.


=head1 SEE ALSO

 

perl, RFC 1928, RFC 1929, ...

=head1 AUTHOR

 

 Igor V. Okunev  mailto:igor@prv.mts-nn.ru
                 http://www.mts-nn.ru/~gosha
                 icq:106183300

