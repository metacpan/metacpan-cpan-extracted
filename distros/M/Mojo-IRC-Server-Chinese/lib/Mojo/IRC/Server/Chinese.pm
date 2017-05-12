package Mojo::IRC::Server::Chinese;
use strict;
$Mojo::IRC::Server::Chinese::VERSION = "1.8.1";
use Encode;
use Encode::Locale;
use Carp;
use Parse::IRC;
use Mojo::IOLoop;
use POSIX ();
use List::Util qw(first);
use Fcntl ':flock';
use Mojo::IRC::Server::Chinese::Base 'Mojo::EventEmitter';
use Mojo::IRC::Server::Chinese::User;
use Mojo::IRC::Server::Chinese::Channel;

has host => "0.0.0.0";
has port => 6667;
has listen => undef;
has network => "Chinese IRC NetWork";
has ioloop => sub { Mojo::IOLoop->singleton };
has parser => sub { Parse::IRC->new };
has servername => "chinese-irc-server";
has clienthost => undef,
has create_time => sub{POSIX::strftime( '%Y/%m/%d %H:%M:%S', localtime() )};
has log_level => "info";
has log_path => undef;
has auth=>undef;

has version => sub{$Mojo::IRC::Server::Chinese::VERSION};
has start_time => sub{time};

has user => sub {[]};
has channel => sub {[]};

has log => sub{
    require Mojo::Log;
    no warnings 'redefine';
    *Mojo::Log::append = sub{
        my ($self, $msg) = @_;
        return unless my $handle = $self->handle;
        flock $handle, LOCK_EX;
        $handle->print(encode("console_out", decode("utf8",$msg))) or $_[0]->die("Can't write to log: $!");
        flock $handle, LOCK_UN;
    };
    Mojo::Log->new(path=>$_[0]->log_path,level=>$_[0]->log_level,format=>sub{
        my ($time, $level, @lines) = @_;
        my $title="";
        if(ref $lines[0] eq "HASH"){
            my $opt = shift @lines; 
            $time = $opt->{"time"} if defined $opt->{"time"};
            $title = (defined $opt->{"title"})?$opt->{title} . " ":"";
            $level  = $opt->{level} if defined $opt->{"level"};
        }
        @lines = split /\n/,join "",@lines;
        my $return = "";
        $time = POSIX::strftime('[%y/%m/%d %H:%M:%S]',localtime($time));
        for(@lines){
            $return .=
                $time
            .   " " 
            .   "[$level]" 
            . " " 
            . $title 
            . $_ 
            . "\n";
        }
        return $return;
    });
};

sub new_user{
    my $s = shift;
    my $user = $s->add_user(Mojo::IRC::Server::Chinese::User->new(@_,_server=>$s));
    return $user if $user->is_virtual;
    $user->io->on(read=>sub{
        my($stream,$bytes) = @_;
        $bytes = $user->buffer . $bytes;
        my $pos = rindex($bytes,"\r\n");
        if($pos != -1){#\r\n
            my $lines = substr($bytes,0,$pos);
            my $remains = substr($bytes,$pos+2);
            $user->buffer($remains);
            $stream->emit(line=>$_) for split /\r?\n/,$lines;
        }
        else{
            $pos = rindex($bytes,"\n");
            if($pos != -1){
                my $lines = substr($bytes,0,$pos);
                my $remains = substr($bytes,$pos+1);
                $user->buffer($remains);
                $stream->emit(line=>$_) for split /\r?\n/,$lines;
            }
            else{
                $user->buffer($bytes); 
            }
        }
    });
    $user->io->on(line=>sub{
        my($stream,$line)  = @_;
        my $msg = $s->parser->parse($line);
        $user->last_active_time(time());
        $s->emit(user_msg=>$user,$msg);
        if($msg->{command} eq "CAP"){$user->emit(cap=>$msg);$s->emit(cap=>$user,$msg);}
        elsif($msg->{command} eq "PASS"){$user->emit(pass=>$msg);$s->emit(pass=>$user,$msg);}
        elsif($msg->{command} eq "NICK"){$user->emit(nick=>$msg);$s->emit(nick=>$user,$msg);}
        elsif($msg->{command} eq "USER"){$user->emit(user=>$msg);$s->emit(user=>$user,$msg);}
        elsif($msg->{command} eq "JOIN"){$user->emit(join=>$msg);$s->emit(join=>$user,$msg);}
        elsif($msg->{command} eq "PART"){$user->emit(part=>$msg);$s->emit(part=>$user,$msg);}
        elsif($msg->{command} eq "PING"){$user->emit(ping=>$msg);$s->emit(ping=>$user,$msg);}
        elsif($msg->{command} eq "PONG"){$user->emit(pong=>$msg);$s->emit(pong=>$user,$msg);}
        elsif($msg->{command} eq "MODE"){$user->emit(mode=>$msg);$s->emit(mode=>$user,$msg);}
        elsif($msg->{command} eq "PRIVMSG"){$user->emit(privmsg=>$msg);$s->emit(privmsg=>$user,$msg);}
        elsif($msg->{command} eq "QUIT"){$user->is_quit(1);$user->emit(quit=>$msg);$s->emit(quit=>$user,$msg);}
        elsif($msg->{command} eq "WHO"){$user->emit(who=>$msg);$s->emit(who=>$user,$msg);}
        elsif($msg->{command} eq "WHOIS"){$user->emit(whois=>$msg);$s->emit(whois=>$user,$msg);}
        elsif($msg->{command} eq "LIST"){$user->emit(list=>$msg);$s->emit(list=>$user,$msg);}
        elsif($msg->{command} eq "TOPIC"){$user->emit(topic=>$msg);$s->emit(topic=>$user,$msg);}
        elsif($msg->{command} eq "AWAY"){$user->emit(away=>$msg);$s->emit(away=>$user,$msg);}
        else{$user->send($user->serverident,"421",$user->nick,$msg->{command},"Unknown command");}
    });

    $user->io->on(error=>sub{
        my ($stream, $err) = @_;
        $user->emit("close",$err);
        $s->emit(close_user=>$user,$err);
        $s->debug("C[" .$user->name."] 连接错误: $err");
    });
    $user->io->on(close=>sub{
        my ($stream, $err) = @_;
        $user->emit("close",$err);
        $s->emit(close_user=>$user,$err);
    });
    $user->on(close=>sub{
        my ($user,$err) = @_;
        return if $user->is_quit;
        my $quit_reason = defined $user->close_reason? $user->close_reason:
                          defined $err               ? $err               :
                                                       "remote host closed connection";
        $user->forward($user->ident,"QUIT",$quit_reason);
        $user->is_quit(1);
        $user->info("[" . $user->name . "] 已退出($quit_reason)");
        $user->{_server}->remove_user($user);
    });
    $user->on(pass=>sub{my($user,$msg) = @_;my $pass = $msg->{params}[0]; $user->pass($pass);});
    $user->on(nick=>sub{my($user,$msg) = @_;my $nick = $msg->{params}[0];$user->set_nick($nick)});
    $user->on(user=>sub{my($user,$msg) = @_;
        if(defined $user->search_user(user=>$msg->{params}[0])){
            $user->send($user->serverident,"446",$user->nick,"该帐号已被使用");
            $user->io->close_gracefully();
            $user->{_server}->remove_user($user);
            return;
        }
        $user->user($msg->{params}[0]);
        #$user->mode($msg->{params}[1]);
        $user->realname($msg->{params}[3]);
        if(!$user->is_registered and $user->nick ne "*" and $user->user ne "*"){
            $user->is_registered(1);
        }
    });
    $user->on(join=>sub{my($user,$msg) = @_;
        my $channels = $msg->{params}[0];
        for my $channel_name (split /,/,$channels){
            my $channel = $user->search_channel(name=>$channel_name);
            if(defined $channel){
                $user->join_channel($channel);
            }
            else{
                $channel = $user->new_channel(name=>$channel_name,id=>lc($channel_name));
                $user->join_channel($channel);
            }
        }
    });
    $user->on(part=>sub{my($user,$msg) = @_;
        my $channel_name = $msg->{params}[0];
        my $part_info = $msg->{params}[1];
        my $channel = $user->search_channel(name=>$channel_name);
        return if not defined $channel;
        $user->part_channel($channel,$part_info);
    });
    $user->on(ping=>sub{my($user,$msg) = @_;
        my $servername = $msg->{params}[0];
        $user->send($user->serverident,"PONG",$user->servername,$servername);
    });
    $user->on(pong=>sub{
        my($user,$msg) = @_;
        my $current_ping_count = $user->ping_count;
        $user->ping_count(--$current_ping_count);
    });
    $user->on(quit=>sub{my($user,$msg) = @_;
        my $quit_reason = $msg->{params}[0];
        $user->quit($quit_reason);
    });
    $user->on(privmsg=>sub{my($user,$msg) = @_;
        $user->last_speak_time(time());
        if(substr($msg->{params}[0],0,1) eq "#" ){
            my $channel_name = $msg->{params}[0];
            my $content = $msg->{params}[1];
            my $channel = $user->search_channel(name=>$channel_name);
            if(not defined $channel){$user->send($user->serverident,"403",$user->nick,$channel_name,"No such channel");return}
            $channel->forward($user,$user->ident,"PRIVMSG",$channel_name,$content);
            $s->info({level=>"IRC频道消息",title=>$user->nick ."|" .$channel->name.":"},$content);
        }
        else{
            my $nick = $msg->{params}[0];
            my $content = $msg->{params}[1];
            my $u = $user->search_user(nick=>$nick);
            if(defined $u){
                $u->send($user->ident,"PRIVMSG",$nick,$content);
                $user->send($user->serverident,"301",$user->nick,$u->nick,$u->away_info) if $u->is_away;
                $s->info({level=>"IRC私信消息",title=>"[".$user->nick."]->[$nick] :"},$content);
            }
            else{
                $user->send($user->serverident,"401",$user->nick,$nick,"No such nick");
            }
        }
    });
    $user->on(mode=>sub{my($user,$msg) = @_;
        if(substr($msg->{params}[0],0,1) eq "#" ){
            my $channel_name = $msg->{params}[0];
            my $channel_mode = $msg->{params}[1];
            my $channel = $user->search_channel(name=>$channel_name);
            if(not defined $channel){$user->send($user->serverident,"403",$user->nick,$channel_name,"No such channel");return}
            if(defined $channel_mode and $channel_mode eq "b"){
                $user->send($user->serverident,"368",$user->nick,$channel_name,"End of channel ban list");
            }
            elsif(defined $channel_mode and $channel_mode ne "b") {
                $channel->set_mode($user,$channel_mode);
            }
            else{
                $user->send($user->serverident,"324",$user->nick,$channel_name,'+'.$channel->mode);
                $user->send($user->serverident,"329",$user->nick,$channel_name,$channel->ctime);
            }
        }
        else{
            my $nick = $msg->{params}[0];
            my $mode = $msg->{params}[1];
            if(defined $mode){$user->set_mode($mode)}
            else{$user->send($user->serverident,"221",$user->nick,'+'.$user->mode)}
        }    
    });
    $user->on(who=>sub{my($user,$msg) = @_;
        if(substr($msg->{params}[0],0,1) eq "#" ){
            my $channel_name = $msg->{params}[0];
            my $channel = $user->search_channel(name=>$channel_name);
            if(not defined $channel){$user->send($user->serverident,"403",$user->nick,$channel_name,"No such channel");return}
            for($channel->users){
                $user->send($user->serverident,"352",$user->nick,$channel_name,$_->user,$_->host,$_->servername,$_->nick,"H","0 " . $_->realname);
            }
            $user->send($user->serverident,"315",$user->nick,$channel_name,"End of WHO list");
        }
        else{
            my $nick = $msg->{params}[0];
            my $u = $user->search_user(nick=>$nick);
            if(defined $u){
                my $channel_name = "*";
                if($u->is_join_channel()){
                    my $last_channel = (grep {$_->mode !~ /s/} $u->channels)[-1];
                    $channel_name = $last_channel->name if defined $last_channel;
                }
                $user->send($user->serverident,"352",$user->nick,$channel_name,$u->user,$u->host,$u->servername,$u->nick,"H","0 " . $u->realname);
                $user->send($user->serverident,"315",$user->nick,$nick,"End of WHO list");
            }
            else{
                $user->send($user->serverident,"401",$user->nick,$nick,"No such nick");
            }
            
        }
    });
    $user->on(whois=>sub{my($user,$msg) = @_;});
    $user->on(list=>sub{my($user,$msg) = @_;
        for my $channel ($user->{_server}->channels){
            next if $channel->mode =~ /s/;
            $user->send($user->serverident,"322",$user->nick,$channel->name,$channel->count(),$channel->topic);
        }
        $user->send($user->serverident,"323",$user->nick,"End of LIST");
    });
    $user->on(topic=>sub{my($user,$msg) = @_;
        my $channel_name = $msg->{params}[0];
        my $channel = $user->search_channel(name=>$channel_name);
        if(not defined $channel){$user->send($user->serverident,"403",$user->nick,$channel_name,"No such channel");return}
        if(defined $msg->{params}[1]){
            my $topic = $msg->{params}[1];
            $channel->set_topic($user,$topic);
        }
        else{
            $user->send($user->serverident,"332",$user->nick,$channel_name,$channel->topic);
        }
    });
    $user->on(away=>sub{my($user,$msg) = @_;
        if($msg->{params}[0]){
            my $away_info = $msg->{params}[0];
            $user->away($away_info); 
        }
        else{
            $user->back();
        }
    });

    $user;
}
sub new_channel{
    my $s = shift;
    my $channel = $s->add_channel(Mojo::IRC::Server::Chinese::Channel->new(@_,_server=>$s));
    $s->emit(new_channel=>$channel);
    return $channel;
}
sub add_channel{
    my $s = shift;
    my $channel = shift;
    my $is_cover = shift;
    my $channel_name = $channel->name;
    $channel_name = "#" . $channel_name if substr($channel_name,0,1) ne "#";
    $channel_name=~s/\s|,|&//g;
    $channel->name($channel_name);
    my $c = $s->search_channel(name=>$channel->name);
    return $c if defined $c;
    $c = $s->search_channel(id=>$channel->id);
    if(defined $c){if($is_cover){$s->info("频道 " . $c->name. " 已更新");$c=$channel;};return $c;}
    else{push @{$s->channel},$channel;$s->info("频道 ".$channel->name. " 已创建");return $channel;}

}
sub add_user{
    my $s = shift;
    my $user = shift;
    my $is_cover = shift;
    if($user->is_virtual){
        my $nick = $user->nick;
        $nick =~s/\s|\@|!//g;$nick = '未知昵称' if not $nick;
        $user->nick($nick);
        my $u = $s->search_user(nick=>$user->nick,virtual=>1,id=>$user->id);
        return $u if defined $u;
        while(1){
            my $u = $s->search_user(nick=>$user->nick);
            if(defined $u){
                if($u->nick =~/\((\d+)\)$/){
                    my $num = $1;$num++;$user->nick($nick . "($num)");
                }
                else{$user->nick($nick . "(1)")}
            }
            else{last};
        }
    }
    my $u = $s->search_user(id=>$user->id);
    if(defined $u){if($is_cover){$s->info("C[".$u->name. "]已更新");$u=$user;};return $u;}
    else{
        push @{$s->user},$user;$s->info("C[".$user->name. "]已加入");return $user;
    }    
}
sub remove_user{
    my $s = shift;
    my $user = shift;
    for(my $i=0;$i<@{$s->user};$i++){
        if($user->id eq $s->user->[$i]->id){
            $_->remove_user($s->user->[$i]->id) for $s->user->[$i]->channels;
            $user->channel([]);
            splice @{$s->user},$i,1;
            if($user->is_virtual){
                $s->info("c[".$user->name."] 已被移除");
            }
            else{
                $s->info("C[".$user->name."] 已离开");
            }
            last;
        }
    }
}

sub remove_channel{
    my $s = shift;
    my $channel = shift;
    for(my $i=0;$i<@{$s->channel};$i++){
        if($channel->id eq $s->channel->[$i]->id){
            splice @{$s->channel},$i,1;
            $s->info("频道 ".$channel->name." 已删除");
            last;
        }
    }
}
sub users {
    my $s = shift;
    return @{$s->user};
}
sub channels{
    my $s = shift;
    return @{$s->channel};
}

sub search_user{
    my $s = shift;
    my %p = @_;
    return if 0 == grep {defined $p{$_}} keys %p;
    if(wantarray){
        return grep {my $c = $_;(first {$p{$_} ne $c->$_} grep {defined $p{$_}} keys %p) ? 0 : 1;} @{$s->user};
    }
    else{
        return first {my $c = $_;(first {$p{$_} ne $c->$_} grep {defined $p{$_}} keys %p) ? 0 : 1;} @{$s->user};
    }

}
sub search_channel{
    my $s = shift;
    my %p = @_;
    return if 0 == grep {defined $p{$_}} keys %p;
    if(wantarray){
        return grep {my $c = $_;(first {$_ eq "name"?(lc($p{$_}) ne lc($c->$_)):($p{$_} ne $c->$_)} grep {defined $p{$_}} keys %p) ? 0 : 1;} @{$s->channel};
    }
    else{
        return first {my $c = $_;(first {$_ eq "name"?(lc($p{$_}) ne lc($c->$_)):($p{$_} ne $c->$_)} grep {defined $p{$_}} keys %p) ? 0 : 1;} @{$s->channel};
    }

}
sub timer{
    my $s = shift;
    $s->ioloop->timer(@_);
}
sub interval{
    my $s = shift;
    $s->ioloop->recurring(@_);
}
sub ident {
    return $_[0]->servername;
}
sub ready {
    my $s = shift;
    my @listen = ();
    if(defined $s->listen and ref $s->listen eq "ARRAY"){
        for (@{$s->listen}){
            $_->{address} = (delete $_->{host}) // "0.0.0.0";
            $_->{port} = ($_->{tls} ? 6697: 6667) if not defined $_->{port};
            push @listen,$_;
        }
    }
    else{
        @listen = ({host=>$s->host,port=>$s->port});
    }
    for my $listen (@listen){
        $s->ioloop->server($listen=>sub{
            my ($loop, $stream) = @_;
            $stream->timeout(0);
            my $id = join ":",(
                $stream->handle->sockhost,
                $stream->handle->sockport,
                $stream->handle->peerhost,
                $stream->handle->peerport
            );
            my $user = $s->new_user(
                id      =>  $id,
                name    =>  join(":",($stream->handle->peerhost,$stream->handle->peerport)),
                io      =>  $stream,
            );
            $user->host($s->clienthost) if defined $s->clienthost;
            $s->emit(new_user=>$user);
        });
    }
    
    $s->on(new_user=>sub{
        my ($s,$user)=@_;
        $s->debug("C[".$user->name. "]已连接");
    });

    $s->on(user_registered=>sub{
        my($s,$user) = @_;
        if(defined $s->auth and ref $s->auth eq "CODE"){
            if(! $s->auth->($user->nick,$user->user,$user->pass)){
                $user->send($user->serverident,"464",$user->nick,"认证失败");
                $user->io->close_gracefully();
                $user->{_server}->remove_user($user);
                return;
            }
        }
        $user->send($user->serverident,"001",$user->nick,"Welcome to " . $s->network . " " .  $user->ident);
        $user->send($user->serverident,"002",$user->nick,"Your host is " . $s->servername. ", running version " . $s->version);
        $user->send($user->serverident,"003",$user->nick,"This server was created " . POSIX::strftime('%a %b %d %y at %H:%M:%S %Z',localtime($s->start_time)));
        $user->send($user->serverident,"004",$user->nick,$s->servername." " .$s->version . " DOQRSZaghilopswz Pbis");
        #$user->send($user->serverident,"001",$user->nick,"欢迎来到 Chinese IRC Network " . $user->ident);
        $user->send($user->serverident,"396",$user->nick,$user->host,"您的主机地址已被隐藏");    
    });
    $s->on(user_msg=>sub{
        my ($s,$user,$msg)=@_;
        $s->debug("C[".$user->name."] $msg->{raw_line}");
    });

    $s->on(close_user=>sub{
        my ($s,$user,$msg)=@_;
    });

    $s->interval(60,sub{
        for(grep {defined $_->last_active_time and time() - $_->last_active_time > 60 } grep {!$_->is_virtual} $s->users){
            if($_->ping_count >=3 ){
                $_->close_reason("PING timeout 180 seconds");
                $_->io->close_gracefully();  
            }
            else{
                $_->send(undef,"PING",$_->servername);
                my $current_ping_count = $_->ping_count;
                $_->ping_count(++$current_ping_count);
            }
        }
    });
}

sub run{
    my $s = shift;
    $s->ready();
    $s->ioloop->start unless $s->ioloop->is_running;
} 
sub die{
    my $s = shift; 
    local $SIG{__DIE__} = sub{$s->log->fatal(@_);exit -1};
    Carp::confess(@_);
}
sub info{
    my $s = shift;
    $s->log->info(@_);
    $s;
}
sub warn{
    my $s = shift;
    $s->log->warn(@_);
    $s;
}
sub error{
    my $s = shift;
    $s->log->error(@_);
    $s;
}
sub fatal{
    my $s = shift;
    $s->log->fatal(@_);
    $s;
}
sub debug{
    my $s = shift;
    $s->log->debug(@_);
    $s;
}


1;
