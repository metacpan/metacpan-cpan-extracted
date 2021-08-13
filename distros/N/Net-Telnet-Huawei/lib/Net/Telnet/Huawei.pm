=pod

=encoding utf8

=head1 NAME

Net::Telnet::Huawei

=head1 SYNOPSIS

	use Net::Telnet::Huawei;
	my $net_dev=Net::Telnet::Huawei->new;
	my ($host, $user, $password, $super_password) = ('192.168.1.1', 'admin', 'password', 'super password');

	$net_dev->login($host, $user, $password, $super_password);

	# or ssh login
	# $net_dev->login($host, $user, $password, $super_password, 1);

	my @lines = $net_dev->exec_cmd('display version');
	print join("\n", @lines), "\n";

=head1 DESCRIPTION

  利用TELNET协议访问华为系列网络设备。

=cut

package Net::Telnet::Huawei;
use parent 'Net::Telnet';
use feature ':5.10';
use Net::Ping;
use Array::Utils qw(:all);
use Carp ();
use Devel::StackTrace;
use CPAN::Version;
use if CPAN::Version->vgt($^V,  'v5.10.1'), experimental => 'switch';

our $VERSION='0.0.5';

# debug flag
my $debug=0;
sub DEBUG(){$debug}

sub spawn {
	my (@cmd) = @_;
	my ($pid, $pty, $tty, $tty_fd);

    ## Create a new pseudo terminal.
	eval 'use IO::Pty';

    $pty = IO::Pty->new
        or die $!;

    ## Execute the program in another process.
    unless ($pid = fork) {  # child process
        die "problem spawning program: $!\n" unless defined $pid;

        ## Disassociate process from its controlling terminal.
        use POSIX ();
        POSIX::setsid()
            or die "setsid failed: $!";

        ## Associate process with a new controlling terminal.
        $pty->make_slave_controlling_terminal;
        $tty = $pty->slave;
        $tty_fd = $tty->fileno;
        close $pty;

        ## Make standard I/O use the new controlling terminal.
        open STDIN, "<&$tty_fd" or die $!;
        open STDOUT, ">&$tty_fd" or die $!;
        open STDERR, ">&STDOUT" or die $!;
        close $tty;

        ## Execute requested program.
        exec @cmd
            or die "problem executing $cmd[0]\n";
    } # end child process

    $pty;
} # end sub spawn

=head2 Subs

=over 4

=item debug

Enable/Disable debug mode if passing an argument. Return debug mode if no argument.

=back

=cut

sub debug{
	my $self=shift;
	$debug=shift if @_;
	$debug;
}

sub qre{
	my $re=shift;
	"/$re/";
}

sub printstack{
	my $trace = Devel::StackTrace->new();
	while ( my $frame = $trace->prev_frame() ) {
		print STDERR "Sub: ", $frame->subroutine(), "\n";
	}
}

# initial state
sub init_state{
	my ($self, %h) = @_;

	my $prompt=qr'\<(?:[^\<\>]*)\>|\[(?:[^\[\]]*)\]';
	my $state={
		USERNAME => '',
		PASSWORD => '',
		SU_PASSWORD => '',

		INPUT_LOG  => DEBUG ? 'input.log' : undef,
		OUTPUT_LOG => DEBUG ? 'output.log' : undef,
		DUMP_LOG => DEBUG ? 'dump.log': undef,

		HOST_NAME => '',
		DEVICE_TYPE => undef,
		DEVICE_VERSION => undef,
		MAC_CACHE => undef,
		LOGIN_CMD => [],
		PROMPT => qr/$prompt/,
		PROMPT_END => qr/$prompt$/,
		PROMPT_RE_END => "/^$prompt\$/m",
		PROMPT_HOST_NAME => qr/$prompt$/
	};

	while(my ($o, $v) = each %h){
		$state->{uc($o)}=$v;
	}

	*$self->{state} = $state;
}


=over 4

=item new

Constructor.

=back

=cut

sub new {
	my $class=shift;

	my $self=$class->SUPER::new(@_);


	&init_state($self, @_);

	
	bless $self, $class;
}


=over 4

=item wait_prompt

Wait until prompt is found.

=back

=cut

sub wait_prompt{
	my $self=shift;
	my $state=&get_state($self);
	my $timeout=shift;

	my $data='';
	eval{
		my $more =  '\s+---- More ----';
			while(my ($p, $m) = $self->waitfor(
												Match => "/$more/",
												Match => $state->{PROMPT_RE_END},
												Timeout => $timeout, @_)){
			if($m =~ /$more/){
				$data .= $p;
				$self->put(' ');
			}
			elsif($m =~ /$state->{PROMPT_END}/){
				$data .= $p;
				last;
			}
			else{
				die 'Unexpected response';
			}
		}
	};
	if($@){
		return;
	}

	# remove '---- More ----' message
	$data =~ s/\x1b\[42D\s+\x1b\[42D/\n/g;
	$data;
}

# split input data
sub split_result{
	my $self=shift;
	my $state=&get_state($self);

	my $data=shift;
	my $irs=$self->input_record_separator;
	my @r = split /$irs/, $data;
	if(@r > 0 ){
		splice @r, 0, 1;
	}

	@r;
}

=over 4

=item can

Check if a device command exists.

=back

=cut

sub can{
	my ($self, $cmd_name) =@_;

	my $state=&get_state($self);
	return unless $cmd_name;

	$self->put("$cmd_name?");

	my ($p, $m) = $self->waitfor(Match => "/$state->{PROMPT}$cmd_name\$/");

	$self->clear_cmdline;

	my @lines = $self->split_result($p);

	splice @lines, -2 if $lines[$#lines] =~ /^Error: /;

	my %cmd;
	my $s=join ' ', @lines;

	$s =~ s/^\s+|\s+$//;

	my @names=split /\s+/, $s;
	$cmd{ $_ } = 1 for @names;

	my @cn = split /\s+/, $cmd_name;
	
	$cmd{$cn[$#cn]};
}

# clear incomplete command line
sub clear_cmdline{
	my $self = shift;
	$self->buffer_empty;
	return unless $self->print("abort incomplete command");
	return unless $self->wait_prompt;
	1;
}

# reset object
sub reset {
	my $self = shift;

	# delete old attributes
	delete *$self->{state};

	# 设置各属性的初始值。
	# 先赋值给一个变量。否则会造成sub无限循环。
	my $init_state = $self->init_state;
	while(my ($k, $v) = each %$init_state){
		*$self->{$k} = $v;
	}
	1;
}

=over 4

=item enter_super

Enter privilege view.

=back

=cut

sub enter_super {
	my $self = shift;
	my $su_password=shift;

	my $state=&get_state($self);

	my $prompt = $state->{PROMPT_RE_END};

	eval{
		if( $self->can('super') ){
			$self->print("super");
			push @{$state->{LOGIN_CMD}}, 'super';
		}
		elsif( $self->can('system-view') ){
			$self->print("system");
			push @{$state->{LOGIN_CMD}}, 'system-view';
		}
		else{
			die "Unexpected error\n";
		}

		my ( $prem, $match ) = $self->waitfor(Match => '/Password:$/i', Match => $prompt);
		if ( $match =~ /Password:/i ) {
			$self->print($su_password);
			push @{$state->{LOGIN_CMD}}, $su_password;
			($prem, $match) = $self->waitfor(Match => '/Password:$/i', Match=>$prompt);
		}
		die if $prem =~ /Access Denied|Error:/i;

		if( $self->view eq 'system'){
			$self->print('quit');
			$self->wait_prompt;
		}
	};
	if($@){
		return;
	}
	return 1;
}


=over 4

=item set_vty_no_pause

Setting no page pause

=back

=cut

sub set_vty_no_pause {
	my $self = shift;

	eval{
		my $ui= '0 4';
		my $cmd = "user-interface vty $ui";

		$self->print("$cmd");
		$self->wait_prompt;

		$self->print("screen-length 0");
		$self->wait_prompt;

		$self->print("quit");
		$self->wait_prompt;

		$self->print("return");
		$self->wait_prompt;
	};

	if($@){
		die "set_vty_no_pause: $@\n";
	}

	return 1;
}

=over 4

=item set_vty_pause

 Setting page pause

=back

=cut

sub set_vty_pause {
	my $self = shift;

  SWITCH: {
			# 生成命令行
			my $ui	= '0 4';
			my $cmd = "user-interface vty $ui";

			if ( $self->view ne 'system') {
				return unless $self->enter_system();
			}

			return unless $self->print("$cmd");
			return unless $self->wait_prompt;

			return unless $self->print("undo screen-length");
			return unless $self->wait_prompt;

			return unless $self->print("quit");
			return unless $self->wait_prompt;

			return unless $self->print("return");
			return unless $self->wait_prompt;

			last SWITCH;
	}

	return 1;
}

=over 4

=item prompt_str

Return prompt status

=back

=cut

sub prompt_str {
	my $self = shift;
	my $state=&get_state($self);

	$self->print('');
	my $prompt=$state->{PROMPT};
	my (undef, $match) = $self->waitfor(Match => $state->{PROMPT_RE_END});
	$match;
}

#获取设备sysname

=over 4

=item get_sysname

Return device host name.

=back

=cut

sub get_sysname {
	my $self=shift;
	my $prompt_str = $self->prompt_str;
	$prompt_str =~ s/^[<[]|[>\]]$//g;
	$prompt_str;
}

# return current view
sub view{
	my $self=shift;
	my $prompt_str=$self->prompt_str;
	my $sysname=$self->get_sysname;

	$prompt_str =~ /^<$sysname(\S*?>)|\[$sysname(\S*?\])$/;
	my $view=$+;
	if($view eq '>'){
		$view='user';
	}
	elsif($view eq ']'){
		$view='system';
	}
	else{
		$view =~ s/^-|[>\]]$//g;
	}
	
	$view;
}


#登录到网络设备的用户视图

=over 4

=item login

	$obj->login($host, $username, $password, $ssh )

$ssh: 1  using ssh
	  0  use telnet

Login to device.

=back

=cut

sub login {
	my ( $self, $host, $username, $password, $ssh ) = @_;

	# 只有处于'NONE'状态才能进行登录
	return unless $self->reset;

	my $state=&get_state(@_);
	my $prompt_end = $state->{PROMPT_RE_END};

	#存储参数供后续操作使用
	$state->{USERNAME} = $username;
	$state->{PASSWORD} = $password;

	$self->input_log($state->{INPUT_LOG});
	$self->output_log($state->{OUTPUT_LOG});
	$self->dump_log($state->{DUMP_LOG});

	$self->prompt($prompt_end);
	$self->cmd_remove_mode(0);

	# 登录过程
	eval{
		my ($u_count, $p_count) = (0,0);
		my ($u_retry, $p_retry) = (1, 1);

	
		my $s = *$self->{state};

		if($ssh){
			## Start ssh program.
			my $pty = spawn("ssh",
				"-l", $username,
				"-e", "none",
				"-F", "/dev/null",
				"-o", "PreferredAuthentications=password",
				"-o", "NumberOfPasswordPrompts=1",
				"-o", "StrictHostKeyChecking=no",
				"-o", "UserKnownHostsFile=/dev/null",
				$host);
			$self->fhopen($pty);
		}else{
			$self->open($host);
		}

		*$self->{state} = $s;

		LOGIN:
		while(1){
			my (undef, $m) = $self->waitfor(Match => '/Password:\s?$/i', 
											Match => '/Username:\s?$/i', 
											Match=>$prompt_end,
											Timeout=>2,
											);
			given($m){
				when(/Username:\s?$/i){
					die "Retry 'Login' exceed $u_retry\n" unless $u_count++ < $u_retry;
					$self->print($username);
				}
				when(/Password:\s?$/i){
					die "Retry 'Login' exceed $u_retry\n" unless $p_count++ < $u_retry;
					$self->print($password);
				}
				when(/$state->{PROMPT_END}/i){
					($state->{HOST_NAME})= ($m =~ /^.(.*).$/);
					$state->{PROMPT_HOST_NAME} = $state->{HOST_NAME} . '\[\>\]\]';
					last LOGIN;
				}
				default{
                    say STDERR $m;
					die "Unexpected error\n";
				}
			}
		}
	};
	if($@){
		$self->close if $self;
		return;
	}

	return 1;
}

#退出登录

=over 4

=item logout

$obj->logout

Logout from device.

=back

=cut

sub logout {
	my $self   = shift;
	my $state=&get_state($self);

	eval{
		SWITCH:{
			local $_=$self->view;

			/^user$/ && do{
				$self->print('quit');
				last;
			};

			/^system$/ && do{
				$self->print('quit');
				$self->wait_prompt; $self->print('quit'); last;
			};

			$self->print('quit');
			$self->wait_prompt;
			$self->print('quit');
		}

		die unless $self->reset;
	};

	if($@){
		return;
	}

	return 1;
}

#获取设备型号

=over 4

=item get_device_type

Get device type

=back

=cut

sub get_device_type {
	my $self = shift;
	my $ret  = undef;

	my $state=&get_state($self);
	return $state->{DEVICE_TYPE} if $state->{DEVICE_TYPE};

	#读取设备版本信息
	my $in=$self->exec_cmd('display version');
	my $r = qr/
	\s*(?!NetEngine)(\S+)\s+uptime.+?
	|
	\s*((?=NetEngine)\S+\s+)uptime.+?
	|
	\s*Quidway\s+(NetEngine\s+[^\s]+)
	|
	\s*Quidway\s+(\S+)\s+Routing\s+Switch
	|
	\s*Quidway\s+(\S+)\s+Terabit\s+Routing\s+Switch
	|
	\s*H3C\s+(.+?)\s+uptime
	/xi;

	if($in =~ $r){
		$state->{DEVICE_TYPE} = $+;
		return $+;
	}
}

#返回设备的配置文件名

=over 4

=item get_config_filename

Get configuration filename.

=back

=cut

sub get_config_filename{
	my $self = shift;

	my $prematch = $self->exec_cmd('dir');
	if($prematch){
		$prematch =~ /((?:vrpcfg|config|startup)\.(?:txt|zip|cfg))$/im;
		return $1 if defined $1;
	}
}

#将一个指定的文件备份到指定的ftp服务器

=over 4

=item backup_config

backup config file to a ftp server.

=back

=cut

sub backup_config{
	my $self = shift;

	#读取ftp服务器的参数
	my ( $ftp_server, $ftp_user, $ftp_password) = @_;
	
	#1.确定配置文件名称
	return unless my $filename = $self->get_config_filename;

	my $p = Net::Ping->new( 'tcp', 5 );
	return if !$p->ping($ftp_server);	# 如果ftp服务器无法ping通则返回

	#设置telnet参数

	my $sys_name = $self->get_sysname;
	return unless $self->print("ftp $ftp_server");

	my ( $pre, $match ) = $self->waitfor('/User\(.*\)/');
	return unless $match;

	return unless $self->print("$ftp_user");
	return unless $self->waitfor('/Password:$/i');

	return unless $self->print("$ftp_password");
	return unless $self->waitfor('/\[ftp\]$/');

	#3. 设置为二进制方式
	return unless $self->print('bin');
	return unless $self->waitfor('/\[ftp\]$/');

	#4. 创建存放配置文件的目录
	return unless $self->print('mkdir netconfig');
	return unless $self->waitfor('/\[ftp\]$/');

	#5. 进入目录
	return unless $self->print('cd netconfig');
	return unless $self->waitfor('/\[ftp\]$/');

	#6. 生成备份目录名
	my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime(time);
	$year += 1900;
	$mon  += 1;

	my $dir_name = "$year-$mon-${mday}_$sys_name";
	return unless $self->print("mkdir $dir_name");
	return unless $self->waitfor('/\[ftp\]$/');

	#7. 进入备份目录
	return unless $self->print("cd $dir_name");
	return unless $self->waitfor('/\[ftp\]$/');

	#8. 上传备份文件

	return unless $self->print("put $filename");
	($pre) = $self->waitfor('/\[ftp\]$/');

	return if $pre !~ /200 PORT Command successful\.|226 Transfer complete\./;
	#退出ftp
	return unless $self->print('quit');
	return unless $self->wait_prompt;
	1;
}

# change system password
sub change_password {
	undef;
}

# get software version

=over 4

=item get_version

Get software version string.

=back

=cut

sub get_version{
	my $self = shift;

	my $state=&get_state($self);
	return $state->{DEVICE_VERSION} if $state->{DEVICE_VERSION};

	my $version = $state->{DEVICE_VERSION};
	unless($version){
		return unless $self->print('display version');
		my ($input) = $self->wait_prompt;
		my $r = qr/^\s*(?:VRP(?: \(R\))? SOFTWARE,\s*(VERSION [\d\.]+).*)$/mi;
		$input =~ $r;
		$version = $1;
		$state->{DEVICE_VERSION} =$version;
	}

	return $version;
}

# execute command

=over 4

=item exec_cmd

Execute command and get output.

=back

=cut

sub exec_cmd {
	my $self   = shift;
	my $cmd = shift;

	$self->print($cmd);

	my $data=$self->wait_prompt(@_);

	if($data){
		return wantarray ? $self->split_result($data) : $data;
	}
	else{
		return wantarray ? () : undef;
	}
}

# enter system view

=over 4

=item enter_system

Enter system mode.

=back

=cut

sub enter_system{
	my $self = shift;

	my $state=&get_state($self);
	return 1 if $self->view eq 'system';

	return unless $self->print("system");
	my ( undef, $match ) = $self->waitfor(Match => '/Password:$/', Match => $state->{PROMPT_RE_END});

	if($match =~ /password:/i){
		push @{$state->{LOGIN_CMD}}, $state->{SU_PASSWORD};
	}

	return 1;
}

# quit system view

=over 4

=item quit_system

Quit system mode.

=back

=cut

sub quit_system{
	my $self = shift;

	if( $self->view eq 'system'){
		return unless $self->print('quit');
		return unless $self->wait_prompt;
	}

	return 1;
}

# save config

=over 4

=item save configration file

=back

=cut

sub save_config{
	my $self = shift;
	
	$self->buffer_empty;

	$self->quit_system if $self->view eq 'system';
	if($self->view eq 'user'){
		return unless $self->print('save');

		# save errmode
		my $old_errmode = $self->errmode;
		$self->errmode('return');
		
		while (my ($p, $m) = $self->waitfor(
				Match => '/\s*\[Y\/N\]\s*:?\s*$/',
				Match => '/press the enter key/i',
				Match => '/successfully/i',
				Timeout => 5, @_
			)){

			if($m =~ /\[Y\/N\]/){
				$self->print('Y');
			}
			elsif($m =~ /press the enter key/i ){
				$self->print('');
			}
			elsif( $m =~ /successfully/i ) {
				last;
			}
		}

		# restore errmode
		$self->errmode($old_errmode);
		$self->buffer_empty;

		return unless $self->wait_prompt;

	}
	else{
		return;
	}
	1;
}

# get arp list

=over 4

=item get_arp

Get arp list.

=back

=cut

sub get_arp{
	my $self = shift;
	my $state=&get_state($self);
	my $prompt_str = $state->{PROMPT_RE_END};

	my $data;
	if( $self->can('display arp all') ){
		$data=$self->exec_cmd('display arp all');
	}
	elsif($self->can('display arp')){
		$data=$self->exec_cmd('display arp');
	}
	else{
		return;
	}

	return split /\n/, $data;
}

#读取mac列表

=over 4

=item get_maclist

Get mac list.

=back

=cut

sub get_maclist{
	my $self = shift;
	$self->enter_system;
	$self->set_vty_no_pause;

	my @result = $self->exec_cmd('display mac-address');
	$self->quit_system;
	$self->set_vty_pause;

	return wantarray ? @result : @result >= 0;
}

#读取配置文件

=over 4

=item get_config

Get configration file.

=back

=cut

sub get_config{
	my $self=shift;
	my $old_timeout=$self->timeout;
	$self->timeout(30);

	$self->enter_system;
	$self->set_vty_no_pause;
	my @result = $self->exec_cmd('display current');
	$self->quit_system;
	$self->set_vty_pause;

	$self->timeout($old_timeout);

	# 去除SRG3260时间戳
	my $date_re = qr<\d{2}:\d{2}:\d{2}\s+\d{4}/\d{2}/\d{2}>;
	if($result[0] =~ $date_re){
		splice @result, 0, 1;
	}

	join("\n", @result);
}

# parse interfaces attributes
sub parse_interfaces{
	my $self=shift;
	my $interfaces = [];

	my $props = [
		['name', qr/^\s*interface ([^#]+?)$/mi],
		['desc', qr/^\s*description (.+?)$/mi],
		['type', qr/^\s*port link-type (.+?)$/mi],
		['permit', qr/^\s*port trunk (?:permit|allow-pass) vlan (.+?)$/mi],
		['access', qr/^\s*port (?:access|default) vlan (.+?)$/mi],
		['vlan', qr/^\s*vlan-type dot1q (?:vid )?(\d+)$/mi],
		['ip', qr/^\s*ip address (\S+ \S+)(?:\s*sub)?$/mi],
		['vrrp_ip', qr/\s*vrrp vrid \d+ virtual-ip ([\d.]+?)(?:master|slave)??$/mi],
		['conn', qr/\s*\$\$<(.+)>\$\$/mi],
	];

	my $config_data = get_config($self);
	my @parts = split /\#[\r\n]+/, $config_data;
	@parts = grep /^interface /, @parts;

	for my $int(@parts){
		my $result = {};
		my ($desc, $type, $permit, $access) = ('', '', '', '');
		$desc = $1 if $int =~ /\n description (.+)\n/;
		for my $prop( @$props){
			my ($name, $qr) = @$prop;
			my @l = $int =~ /$qr/g;
			if(@l == 1){
				$result->{$name} = $l[0];
			}
			elsif(@l>1){
				$result->{$name} = \@l;
			}
		}

		if (%$result){
			if ($result->{name} =~ /^Vlanif\D*(\d+)/i){
				$result->{vlan} = $1;
			}
			$result->{mac}=$self->get_int_mac($result->{name});

			push @$interfaces, $result;
		}
	}

	$interfaces;
}

# cache switch hardware address
sub get_int_mac{
	my ($self, $port_name)=@_;
	my ($port_base_name)=split /\./,$port_name;

	my $state=&get_state($self);
	my $device_type = $self->get_device_type;

	# 从缓存读取交换机MAC
	if($device_type =~ /^S/i){
		return $state->{MAC_CACHE} if $state->{MAC_CACHE};
	}

	my @output_lines=$self->exec_cmd("display interface $port_base_name");
	chomp @output_lines;

	my @mac_address=grep /address/i, @output_lines;
	return unless @mac_address;


	my $mac;
	for(@mac_address){
		if ( $_ =~ /([0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4})$/){
			$mac = $1;
			last;
		}
	}

	# 保存结果到缓存
	if($device_type =~ /^S/i){
		$state->{MAC_CACHE} = $mac;
	}

	# 返回结果
	$mac;
}

# set device name

=over 4

=item set_sysname

Set the name of the device.

=back

=cut

sub set_sysname{
	my ($self, $sysname) = @_;
	return unless $self->enter_system;
	return unless $self->print("sysname $sysname");
	return unless $self->wait_prompt;
	1;
}

# generate login commands
sub get_login_process {
	my ( $self, $host, $username, $password, $su_password ) = @_;
	my $state=&get_state($self);

	# 只有处于'NONE'状态才能进行登录
	return unless $self->reset;
	my $prompt_end = $state->{PROMPT_RE_END};

	######################
	$self->input_log($state->{INPUT_LOG});
	$self->output_log($state->{OUTPUT_LOG});
	$self->dump_log($state->{DUMP_LOG});

	$self->prompt($prompt_end);
	$self->cmd_remove_mode(0);
	
	#存储参数供后续操作使用
	$state->{USERNAME} = $username;
	$state->{PASSWORD} = $password;

	#连接到设备
	return undef unless $self->open($host);
	push @{$state->{LOGIN_CMD}}, "telnet $host";
	eval{
		my ($u_count, $p_count) = (0,0);
		my ($u_retry, $p_retry) = (1, 1);

		LOGIN:
		while(1){
			my (undef, $m) = $self->waitfor(Match => '/Password: ?$/i', Match => '/Username: ?$/i', Match=>$prompt_end);
			die "Login timeout\n" unless $m; # time out

			given($m){
				when(/Username: ?$/i){
					die "Retry 'Login' exceed $u_retry\n" unless $u_count++ < $u_retry;
					$self->print($username);
					push @{$state->{LOGIN_CMD}}, $username;
				}
				when(/Password: ?$/i){
					die "Retry 'Login' exceed $u_retry\n" unless $p_count++ < $u_retry;
					$self->print($password);
					push @{$state->{LOGIN_CMD}}, $password;
				}
				when(/$state->{PROMPT_END}/){
					last LOGIN;
				}
				default{
					die "Unexpected response: $m\n";
				}
			}
		}
	};

	if($@){
		$self->close;
		return;
	}

	return unless $self->enter_super($su_password);
	return unless $self->enter_system;
	return @{$state->{LOGIN_CMD}};
}

sub get_bind_mac_list{

	my ($self) = @_;

	my $config_data = $self->exec_cmd('disp current');

	my $s;
	for (split /\n\#\n/,$config_data){
		$s = $_,last if /dhcp enable/;
	}

	my @macs = split /\n+/, $s;
	s/^\s+// for @macs;

	my (%ip_mac, %mac_ip);
	for(@macs){
		/user-bind static ip-address ([^ ]+) mac-address ([^ ]+)/;
		push @{$ip_mac{$1}}, $2;
		push @{$mac_ip{$2}}, $1;
	}

	\%ip_mac;
}

sub bind_mac{

	my ($self, $ip, $mac) = @_;

	my $config_data = $self->exec_cmd('disp current');

	my $s;
	for (split /\n\#\n/,$config_data){
		$s = $_,last if /dhcp enable/;
	}

	my @macs = split /\n+/, $s;
	s/^\s+// for @macs;

	my (%ip_mac, %mac_ip);
	for(@macs){
		/user-bind static ip-address ([^ ]+) mac-address ([^ ]+)/;
		push @{$ip_mac{$1}}, $2;
		push @{$mac_ip{$2}}, $1;
	}

	my @cmds;
	my $mac_bind_list_ref = $ip_mac{$ip};
	if(defined $mac_bind_list_ref && @$mac_bind_list_ref > 0){
		for(@$mac_bind_list_ref){
			push @cmds, "undo user-bind static ip-address $ip mac-address $_";
		}
	}

	$mac_bind_list_ref = $mac_ip{$mac};
	if(defined $mac_bind_list_ref && @$mac_bind_list_ref > 0){
		for(@$mac_bind_list_ref){
			push @cmds, "undo user-bind static ip-address $_ mac-address $mac";
		}
	}

	@cmds = unique @cmds;
	push @cmds, "user-bind static ip-address $ip mac-address $mac";

	$self->enter_system;
	for( @cmds ){
		$self->exec_cmd($_);
	}

	$self->save_config;
}

sub unbind_mac{

	my ($self, $ip, $mac) = @_;

	my $config_data = $self->exec_cmd('disp current');

	my $s;
	for (split /\n\#\n/,$config_data){
		$s = $_,last if /dhcp enable/;
	}

	my @macs = split /\n+/, $s;
	s/^\s+// for @macs;

	my (%ip_mac, %mac_ip);
	for(@macs){
		/user-bind static ip-address ([^ ]+) mac-address ([^ ]+)/;
		push @{$ip_mac{$1}}, $2;
		push @{$mac_ip{$2}}, $1;
	}

	my @cmds;
	my $mac_bind_list_ref = $ip_mac{$ip};
	if(defined $mac_bind_list_ref && @$mac_bind_list_ref > 0){
		for(@$mac_bind_list_ref){
			push @cmds, "undo user-bind static ip-address $ip mac-address $_";
		}
	}

	$mac_bind_list_ref = $mac_ip{$mac};
	if(defined $mac_bind_list_ref && @$mac_bind_list_ref > 0){
		for(@$mac_bind_list_ref){
			push @cmds, "undo user-bind static ip-address $_ mac-address $mac";
		}
	}

	@cmds = unique @cmds;
	$self->enter_system;
	for( @cmds ){
		$self->exec_cmd($_);
	}

	$self->save_config;
}
sub AUTOLOAD{
	my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
	my $r=eval{
		shift->$method(@_);
	};
	if($@){
	}
	$r;
}

sub get_state{
	my $self=shift;
	*$self->{state};
}

1;

__END__

