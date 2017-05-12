package Net::SMTP::Bulk::AnyEvent;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;

use MIME::Base64;
use Encode;

=head1 NAME

Net::SMTP::Bulk::AnyEvent - NonBlocking batch SMTP using Net::SMTP interface cia AnyEvent

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';

=head2 new(%options, Hosts=>[\%options2,\%options3])

You can supply multiple hosts in an array.


=head2 auth( [ MECHANISM,] USERNAME, PASSWORD  )



=head2 mail( ADDRESS )

=head2 to( ADDRESS )

=head2 data()

=head2 datasend( DATA )

=head2 dataend( DATA )

=head2 reconnect(  )

=head2 quit(  )

=cut


sub new {
    my $class=shift;
    my %new=@_;
    my $self={};

    if ($#_ % 2 == 0) {
        $new{Host}=shift;
    }

    bless($self, $class||'Net::SMTP::AnyEvent');

    $self->{new}=\%new;
    $self->{encode} =  ( ($new{Encode}||'') eq '1' ) ? 'utf8':'';
    $self->{debug} = (($new{Debug}||0) >= 1) ? int($new{Debug}):0;
    
    if ( ($new{DebugPath}||'') ne '' ) {
        $self->{debug_path} = ( lc($new{DebugPath}) eq 'default' ) ? 'debug_[HOST]_[THREAD].txt':$new{DebugPath};
    }
    
   
    
    
    $self->{func} = $new{Callbacks};
    $self->{global_timeout} = $new{GlobalTimeout}||120;
    $self->{last_active}=time;
    $self->{timer_actions}=[];
    $self->{defaults}={
                       threads=>$new{Threads}||2,
                       port=>$new{Port}||25,
                       timeout=>$new{Timeout}||30,
                       secure=>$new{Secure}||0,
                       pipe=>$new{Pipeline}||0,
		       sleep=>{
                               hang=>0,
                               fail=>0,
                               },
                       retry=>{
                        global_hang=>1,
                        hang=>1,
                        fail=>5
                       }
                       };
    
    
    $self->{cv} = AnyEvent->condvar;
    
    if (exists($new{Hosts})) {
       $self->_PREPARE($new{Hosts});
    } else {
       $self->_PREPARE([\%new]);
    }

    return $self;
}




sub auth {
    my $self=shift;
    my $type=shift;
    my $user=shift;
    my $pass=shift;
    my $k=shift||$self->{last}[0];
    
    
    if ( !defined($type) and exists($self->{auth}{ $k->[0] }{ $k->[1] }[0])) {
        
    
    } elsif ( !defined($pass) or ref($pass) eq 'ARRAY' ) {
        $k=$pass if ref($pass) eq 'ARRAY';
        $self->{auth}{ $k->[0] }{ $k->[1] }=['AUTO',$type,$user];

    } else {
        $self->{auth}{ $k->[0] }{ $k->[1] }=[$type,$user,$pass];
    }
    
    
    
 # print "GOTHERE($self->{last}[0][0]){ $k->[0] }{ $k->[1] }\n";
    #if ( $self->{status_code}{ $k->[0] }{ $k->[1] } == 250 and $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'HEADER' and $self->{stage}{ $k->[0] }{ $k->[1] }[1] == 1 ) {
    #            $self->_AUTH($k);
    #}
    
    #}
    
}


sub mail {
    my $self=shift;
    my $user=shift;
    my $k=shift||$self->{last}[0];


    $self->{queue}{ $k->[0] }{ $k->[1] }[$self->{queue_size}{ $k->[0] }{ $k->[1] }]{mail}=$user;
    # $self->{data}{ $k->[0] }{ $k->[1] }{mail}=$user;
    #if ( $self->{status_code}{ $k->[0] }{ $k->[1] } == 250 and $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'MAIL' and $self->{stage}{ $k->[0] }{ $k->[1] }[1] == 0 ) {
    #            $self->_MAIL($k);
    #} elsif ( $self->{status_code}{ $k->[0] }{ $k->[1] } == 250 and $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'END' and $self->{stage}{ $k->[0] }{ $k->[1] }[1] == 0 ) {
    #            $self->_MAIL($k);
    #}
    
}


sub to {
    my $self=shift;
    my $user=shift;
    my $k=shift||$self->{last}[0];

    

    $self->{queue}{ $k->[0] }{ $k->[1] }[$self->{queue_size}{ $k->[0] }{ $k->[1] }]{to}=$user;
    #$self->{data}{ $k->[0] }{ $k->[1] }{to}=$user;
    #if ( $self->{status_code}{ $k->[0] }{ $k->[1] } == 250 and $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'TO' and $self->{stage}{ $k->[0] }{ $k->[1] }[1] == 0 ) {
    #            $self->_TO($k);
    #}  
}

sub data {
    my $self=shift;
    my $k=shift||$self->{last}[0];
    
    $self->{queue}{ $k->[0] }{ $k->[1] }[$self->{queue_size}{ $k->[0] }{ $k->[1] }]{data}='';
    #$self->{data}{ $k->[0] }{ $k->[1] }{data}='';
    #if ( $self->{status_code}{ $k->[0] }{ $k->[1] } == 250 and $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'DATA' and $self->{stage}{ $k->[0] }{ $k->[1] }[1] == 0 ) {
    #            $self->_DATA($k);
    #}  
}


sub datasend {
    my $self=shift;
    my $data=shift;
    my $k=shift||$self->{last}[0];
    
    $self->{queue}{ $k->[0] }{ $k->[1] }[$self->{queue_size}{ $k->[0] }{ $k->[1] }]{data}.=$data;
    #$self->{data}{ $k->[0] }{ $k->[1] }{data}.=$data;
}

sub dataend {
    my $self=shift;
    my $k=shift||$self->{last}[0];
        $self->{queue_size}{ $k->[0] }{ $k->[1] }++;
      #  print "PQ($self->{queue_size}{ $k->[0] }{ $k->[1] })\n";
    #if ( $self->{status_code}{ $k->[0] }{ $k->[1] } == 250 and $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'DATA' and $self->{stage}{ $k->[0] }{ $k->[1] }[1] == 0 ) {
    #            $self->_DATAEND($k);
    #} 
    
    $self->_NEXT();
    # $self->_BULK();
}


sub quit {
    my $self = shift;
    my $id = shift || time;    
    
    my $timer;
    
    if ($self->{global_timeout} > 0) {
        $timer = AnyEvent->timer(
                             after=> int(($self->{global_timeout}+1)/2)+1,
                             cb=> sub {
                                
                                if ( ($self->{last_active} + $self->{global_timeout}) < time ) {
                                    
                                    
                                    my $r=$self->_FUNC('global_hang',$self,[-1,-1],0,[]);
                                    
                                    
#$self->{retry}{ $k->[0] }{hang}
                                    
                                    my $end=1;
                                    
                                        foreach my $h ( keys(%{ $self->{threads} })  ) {
                                            foreach my $t ( 0..$self->{threads}{ $h } ) {
                                                $self->{last_active}=time;
                                                #$self->{fh}{threads}{ $h }{ $t }->destroy if defined($self->{fh}{threads}{ $h }{ $t });
                                                $self->_DEBUG([$h,$t],'GLOBAL TIMEOUT : (PASS:'.($self->{stats}{ $h }{ $t }{queue}{pass}).'|HANG:'.($self->{stats}{ $h }{ $t }{queue}{hang}).'|FAIL:'.($self->{stats}{ $h }{ $t }{queue}{fail}).'|TOTAL:'.$self->{stats}{ $h }{ $t }{queue}{total}.')',5) if $self->{debug} >= 1;
                                                if ( $self->{retry}{ $k->[0] }{global_hang} >= $self->{retry}{ $k->[0] }{global_hang_count} ) {
                                                    $self->{retry}{ $k->[0] }{global_hang_count}++;
                                                    
                                                    
                                                    $self->reconnect([$h,$t],99,1);
                                                    $end=0;
                                                } else {
                                                    $self->{fh}{threads}{ $h }{ $t }->destroy if defined($self->{fh}{threads}{ $h }{ $t });
                                                }
                                                
                                                
                                            
                                            }
                                        }
                                        
                                        if ($end == 1) {
                                            undef($timer);
                                            undef($timer2);
                                            $self->{cv}->send;
                                        }
                                        
 
                                }
                                
                             }
                             
                             );
    }
    

    my $total=0;
    foreach my $h ( keys(%{ $self->{threads} })  ) {
        foreach my $t ( 0..$self->{threads}{ $h } ) {
#print "QSS($#{$self->{queue}{ $h }{ $t }})\n";
            $self->{stats}{ $h }{ $t }{queue}{id}=$id;
            $self->{stats}{ $h }{ $t }{queue}{total}=($#{$self->{queue}{ $h }{ $t }}+1);
            $total+=$self->{stats}{ $h }{ $t }{queue}{total};
            
            $self->_DEBUG([$h,$t],'Set Queue : '.$self->{stats}{ $h }{ $t }{queue}{total},5) if $self->{debug} >= 1;

            if ( $#{$self->{queue}{ $h }{ $t }} >= 0 ) {
     
            $self->{cv}->begin;
            $self->_CONNECT([$h,$t]);
      
            }
        }
    }
    

    my $timer2   = AnyEvent->timer(
    	interval => 1,
    	cb       => sub {
       	my @actions;
		foreach my $i ( 0 .. $#{ $self->{timer_actions} } ) {
			$self->{timer_actions}[$i][0]++;
                        #print "OK(  $self->{timer_actions}[$i][0] >= $self->{timer_actions}[$i][1] )\n";
			if ( $self->{timer_actions}[$i][0] >= $self->{timer_actions}[$i][1] ) {
				&{ $self->{timer_actions}[$i][2] }( @{ $self->{timer_actions}[$i][3] } );
			
			} else {
				push(@actions,$self->{timer_actions}[$i]);
			}
		
		}
		$self->{timer_actions}=\@actions;

	},
    );    
    
    #$self->_BULK();
    $self->{cv}->recv if $total > 0;
     
    undef($timer) if defined($timer);
    undef($timer2) if defined($timer2);
     
    my $rt1=$self->_FUNC('complete',$self,[-1,-1],0,[]);
    foreach my $h ( keys(%{ $self->{threads} })  ) {
        foreach my $t ( 0..$self->{threads}{ $h } ) {
            
            my $rt2=$self->_FUNC('end_thread',$self,$k,0,[]);
            $self->{fh}{threads}{ $h }{ $t }->destroy if defined($self->{fh}{threads}{ $h }{ $t });
            
             $self->_DEBUG([$h,$t],'End Queue : (PASS:'.($self->{stats}{ $h }{ $t }{queue}{pass}).'|HANG:'.($self->{stats}{ $h }{ $t }{queue}{hang}).'|FAIL:'.($self->{stats}{ $h }{ $t }{queue}{fail}).'|TOTAL:'.$self->{stats}{ $h }{ $t }{queue}{total}.')',5) if $self->{debug} >= 1;
            $self->{stats}{ $h }{ $t }{queue}{id}=0;
        }
    }
    
    foreach my $dfh ( keys(%{ $self->{debug_fh} }) ) {
        close($self->{debug_fh}{$dfh})
    }
     
}



sub reconnect {
       my $self=shift;
    my $k=shift||$self->{last}[0];
    my $retry=shift||0;
    my $global=shift||0;
    
    if ($retry > ($self->{on_queue}{ $k->[0] }{ $k->[1] }{retry}||0) ) {
        $self->{queue_size}{ $k->[0] }{ $k->[1] }++;
        $self->{on_queue}{ $k->[0] }{ $k->[1] }{retry} = ($self->{on_queue}{ $k->[0] }{ $k->[1] }||0) + 1 if $global == 0;
        push(@{ $self->{queue}{ $k->[0] }{ $k->[1] } }, $self->{on_queue}{ $k->[0] }{ $k->[1] });
    }
    
    $self->{fh}{ $k->[0] }{ $k->[1] }->destroy if defined($self->{fh}{ $k->[0] }{ $k->[1] });
    #$self->{cv}->end;
    #delete($self->{auth}{ $k->[0] }{ $k->[1] });
    #$self->{cv}->begin;
                $self->{stage}{ $k->[0] }{ $k->[1] }=['BEGIN',0];
            $self->_CONNECT($k);
    
}



sub _PREPARE {
    my $self=shift;
    my $hosts=shift;
    $self->{order}=[];
    $self->{open_threads}=0;
    foreach my $i ( 0..$#{$hosts} ) {
   
        my %new=( %{$hosts->[$i]} );
        $self->{host}{ $new{Host} }||=$new{Host};
        $self->{last}=[[$new{Host},0],0] if $i == 0; 
        if ($self->{host}{ $new{Host} }=~s/\:(\d+?)$//is) {
            $self->{port}{ $new{Host} }=$1;  
        }
    
        $self->{secure}{ $new{Host} }=$new{Secure}||$self->{defaults}{secure};
        $self->{pipe}{ $new{Host} }=$new{Pipeline}||$self->{defaults}{pipe};
        $self->{port}{ $new{Host} }||=$new{Port}||$self->{defaults}{port};
        $self->{helo}{ $new{Host} }=$new{Hello}||$self->{host}{ $new{Host} };
        $self->{timeout}{ $new{Host} }=$new{Timeout}||$self->{defaults}{timeout};
        $self->{threads}{ $new{Host} }=($new{Threads}||$self->{defaults}{threads}) - 1;

        $self->{sleep}{ $new{Host} }{hang}=$new{Sleep}{Hang}||$self->{defaults}{sleep}{hang};
        $self->{sleep}{ $new{Host} }{fail}=$new{Sleep}{Fail}||$self->{defaults}{sleep}{fail};
        
        $self->{retry}{ $new{Host} }{hang}=$new{Retry}{Hang}||$self->{defaults}{retry}{hang};
        $self->{retry}{ $new{Host} }{global_hang}=$new{Retry}{GlobalHang}||$self->{defaults}{retry}{global_hang};
        $self->{retry}{ $new{Host} }{global_hang_count}=0;
        $self->{retry}{ $new{Host} }{fail}=$new{Retry}{Hang}||$self->{defaults}{retry}{fail};
        
        $self->{open_threads}+=$self->{threads}{ $new{Host} };
        
       
        foreach my $t ( 0..$self->{threads}{ $new{Host} } ) {
            if ( exists($self->{debug_path}) ) {
                my $path=$self->_STRFTIME(''.$self->{debug_path},time);
                $path=~s/\[HOST\]/$new{Host}/gs;
                $path=~s/\[THREAD\]/$t/gs;
                
                $self->_MKDIRF($path);
                open( $self->{debug_fh}{ $new{Host}.':'.$t } , '>>'.$path );
                binmode( $self->{debug_fh}{ $new{Host}.':'.$t } , ':utf8' );
            }

            
            $self->{auth}{ $new{Host} }{$t}=$new{Auth}||[0,''];
            $self->{objects}{ $new{Host} }{$t}={};
            $self->{queue}{ $new{Host} }{$t}=[];
            $self->{queue_size}{ $new{Host} }{$t}=0;
            $self->{pipe_mode}{ $new{Host} }{$t}=[0,[],{}];
            $self->{stage}{ $new{Host} }{ $t }=['BEGIN',0];
            $self->{stats}{ $new{Host} }{ $t }={
                queue => {
                                                total=>0,
                                                pass=>0,
                                                hang=>0,
                                                fail=>0,
                                                count=>0,
                                                id=>0
                       }
                                                };
            push(@{$self->{order}}, [$new{Host},$t,1] );
            
            #$self->_CONNECT([$new{Host},$t]);

        }
        
        
      
        #foreach my $t ( 0..$self->{threads}{ $new{Host} } ) {
        #    $self->_HELO([$new{Host},$t]);
        #}
        #foreach my $t ( 0..$self->{threads}{ $new{Host} } ) {
        #    $self->_READ([$new{Host},$t]);
        #    $self->_HEADER([$new{Host},$t]);
        #}

    
    }
}


sub _CONNECT {
    my $self=shift;
    my $k=shift;
    
            my %extra;
         
            if ( $self->{secure}{ $k->[0] } == 1 ) {
                %extra=(
                    tls      => 'connect',
                    tls_ctx  => { verify => 0, verify_peername => "smtp" }
                );
            } elsif ( $self->{secure}{ $k->[0] } == 2 ) {
                %extra=(
                    tls      => 'connect',
                    tls_ctx  => { verify => 1, verify_peername => "smtp" }
                );
            } 
 
     $self->_DEBUG($k,"Connecting to $self->{host}{ $k->[0] } on port $self->{port}{ $k->[0] }") if $self->{debug} >= 1;
     
     $self->{fh}{ $k->[0] }{ $k->[1] } = new AnyEvent::Handle(
      connect  => [$self->{host}{ $k->[0] }, $self->{port}{ $k->[0] }],
      on_read => sub { $self->_READ($k); },
      
      timeout => ($self->{timeout}{ $k->[0] }||60),
      on_timeout=> sub {
        $self->{stats}{ $k->[0] }{ $k->[1] }{queue}{hang}++;
        my $r=$self->_FUNC('hang',$self,$k,0,[$self->{on_queue}{ $k->[0] }{ $k->[1] }]);
        $self->_DEBUG($k,'Email : '.(++$self->{stats}{ $k->[0] }{ $k->[1] }{queue}{count}).' : '.$self->{on_queue}{ $k->[0] }{ $k->[1] }{to}.' : HANG : '.$self->{stage}{ $k->[0] }{ $k->[1] }[0].','.$self->{stage}{ $k->[0] }{ $k->[1] }[1], 7) if $self->{debug} >= 1;

	 if ($r == 1 or $r == 103 ) {
	 	if ( ($self->{sleep}{ $k->[0] }{hang}||0) > 0 ) {
	       	push(@{$self->{timer_actions}},[0,$self->{sleep}{ $k->[0] }{hang},'reconnect',[$self, $k, $self->{retry}{ $k->[0] }{hang}]] );
	 	} else {
	       	$self->reconnect($k, $self->{retry}{ $k->[0] }{hang} );
		}

	 }
        
      },
      on_error => sub {
        $self->{stats}{ $k->[0] }{ $k->[1] }{queue}{fail}++;
        my $r=$self->_FUNC('fail',$self,$k,0,[$self->{on_queue}{ $k->[0] }{ $k->[1] }]);
        
        $self->_DEBUG($k,'Email : '.(++$self->{stats}{ $k->[0] }{ $k->[1] }{queue}{count}).' : '.$self->{on_queue}{ $k->[0] }{ $k->[1] }{to}.' : FAIL : '.$self->{stage}{ $k->[0] }{ $k->[1] }[0].','.$self->{stage}{ $k->[0] }{ $k->[1] }[1], 7) if $self->{debug} >= 1;

	if ( ($self->{sleep}{ $k->[0] }{fail}||0) > 0 ) {
	    push(@{$self->{timer_actions}},[0,$self->{sleep}{ $k->[0] }{fail},'reconnect',[$self, $k, $self->{retry}{ $k->[0] }{fail}]] );
	} else {
	    $self->reconnect($k, $self->{retry}{ $k->[0] }{fail} );
	}

        
        },
      %extra
      );
               
                
                
}

sub _FUNC {
    my $self=shift;
    no strict;
    my $func=shift;
    return &{$self->{func}{$func}}(@_) if exists($self->{func}{$func});
    return 1;
}

sub _BULK {
    my $self=shift;
    
    
    
}

sub _NEXT {
    my $self=shift;
    my $k=shift;
    
    my @next;
    
    while (!exists($next[0])) {
        $self->{last}[1]++;
        
        if (exists($self->{order}[ $self->{last}[1] ])) {
           # if ($self->{order}[ $self->{last}[1] ][2]==1) {
                @next=( $self->{order}[ $self->{last}[1] ], $self->{last}[1] );
              
           # }
        } else {
         
            
           
              @next=($self->{order}[0],0);    
        }
           #print "NEXT(@next)\n";
 
        
    }
    
    
    $self->{last}=\@next;
}

###########################


sub _HELO {
    my $self=shift;
    my $k=shift;
    
    $self->_WRITE($k,'EHLO '.$self->{helo}{ $k->[0] });
}

sub _PIPE {
    my $self=shift;
    my $k=shift;
    my $mode=shift;
    
    if ($self->{pipe}{ $k->[0] } > 0) {
        
        if ( $mode == 1 ) {
            $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[0]=$self->{pipe}{ $k->[0] };
        }
        
        
        
    }
    
    
    
    
}

sub _STARTTLS {
    my $self=shift;
    my $k=shift;

    if ($self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'HEADER') {
        $self->{stage}{ $k->[0] }{ $k->[1] }=['STARTTLS',0];
        
        
        $self->_WRITE($k,'STARTTLS');
    } else {
      
        my @extra;
         
        if ( $self->{secure}{ $k->[0] } == 3 ) {
            @extra=(
                'connect',
                { verify => 0, verify_peername => "smtp" }
                );
        } elsif ( $self->{secure}{ $k->[0] } == 4 ) {
            @extra=(
                'connect',
                { verify => 1, verify_peername => "smtp" }
            );
        }
        

        $self->{stage}{ $k->[0] }{ $k->[1] }=['BEGIN',0];
        $self->{fh}{ $k->[0] }{ $k->[1] }->starttls(@extra);

        $self->_HELO($k);
        $self->{header}{ $k->[0] }{ $k->[1] }={};
        $self->{stage}{ $k->[0] }{ $k->[1] }=['HELO',1];

    }

}

sub _AUTH {
    my $self=shift;
    my $k=shift;
    
    if ($self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'AUTH' ) {

        if ( $self->{stage}{ $k->[0] }{ $k->[1] }[1] == 1) {
            if (  my $str = $self->{objects}{ $k->[0] }{ $k->[1] }{sasl_client}->client_start()  ) {
                $self->_WRITE($k,MIME::Base64::encode_base64($str, ''));
                $self->{stage}{ $k->[0] }{ $k->[1] }[1]++;
                return;
            }
        }      
            
        my $msg = MIME::Base64::decode_base64($self->{status_text}{ $k->[0] }{ $k->[1] });
        $self->_WRITE($k, MIME::Base64::encode_base64($self->{objects}{ $k->[0] }{ $k->[1] }{sasl_client}->client_step( $msg ),'') );
        $self->{stage}{ $k->[0] }{ $k->[1] }[1]++;   
    } else {
        require Authen::SASL;
       
        my $mech=( $self->{auth}{ $k->[0] }{ $k->[1] }[0] eq 'AUTO' ) ? uc(join(' ',@{$self->{header}{ $k->[0] }{ $k->[1] }{auth}})) : $self->{auth}{ $k->[0] }{ $k->[1] }[0];

        $self->{objects}{ $k->[0] }{ $k->[1] }{sasl} = Authen::SASL->new (
            mechanism => $mech,
            callback => {
                user => $self->{auth}{ $k->[0] }{ $k->[1] }[1],
                pass => $self->{auth}{ $k->[0] }{ $k->[1] }[2],
                authname => $self->{auth}{ $k->[0] }{ $k->[1] }[1],
            }
        );

        $self->{objects}{ $k->[0] }{ $k->[1] }{sasl_client} = $self->{objects}{ $k->[0] }{ $k->[1] }{sasl}->client_new("smtp", $k->[0],1);
        $self->{stage}{ $k->[0] }{ $k->[1] }=['AUTH',0];
        $self->_WRITE($k,'AUTH '.$self->{objects}{ $k->[0] }{ $k->[1] }{sasl_client}->mechanism);
        $self->{stage}{ $k->[0] }{ $k->[1] }=['AUTH',1];
        
    }
    
}

sub _MAIL {
    my $self=shift;
    my $k=shift;
    
    $self->{queue_size}{ $k->[0] }{ $k->[1] }--;
    $self->{on_queue}{ $k->[0] }{ $k->[1] }=shift(@{ $self->{queue}{ $k->[0] }{ $k->[1] } });
    #print "QUEUES($#{$self->{queue}{ $k->[0] }{ $k->[1] }})\n";
    
    if ( $self->{queue_size}{ $k->[0] }{ $k->[1] } == -1 ) {
      
      
      $self->_WRITE($k,'QUIT');
	  
      $self->{fh}{ $k->[0] }{ $k->[1] }->destroy;
      $self->{cv}->end;
      
      $self->{stage}{ $k->[0] }{ $k->[1] }=['END',0];
    } else {
    
    
    $self->{stage}{ $k->[0] }{ $k->[1] }=['MAIL',1];
    #$self->_WRITE($k,'MAIL FROM: '.$self->{data}{ $k->[0] }{ $k->[1] }{mail});
    
    my $write = 'MAIL FROM: '.$self->{on_queue}{ $k->[0] }{ $k->[1] }{mail};
    
    if ( $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[0] == 0 ) {
        $self->_WRITE( $k, $write );
		
		$self->{stage}{ $k->[0] }{ $k->[1] }=['MAIL',2];
    } else {
	 
        push( @{ $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[1] }, $write );
		 $self->_TO($k);
    }

  
    
    
    }
}

sub _TO {
    my $self=shift;
    my $k=shift;
    $self->{stage}{ $k->[0] }{ $k->[1] }=['TO',1];
    #$self->_WRITE($k,'RCPT TO: '.$self->{data}{ $k->[0] }{ $k->[1] }{to});

    my $write = 'RCPT TO: '.$self->{on_queue}{ $k->[0] }{ $k->[1] }{to};
    
    if ( $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[0] == 0 ) {
        $self->_WRITE( $k, $write );
		$self->{stage}{ $k->[0] }{ $k->[1] }=['TO',2];
    } else {
        push( @{ $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[1] }, $write );
		$self->_DATA($k);
    }
     
    
}

sub _DATA {
    my $self=shift;
    my $k=shift;
    
    
    $self->{stage}{ $k->[0] }{ $k->[1] }=['DATA',1];
    
    my $write = 'DATA';
    
    if ( $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[0] == 0 ) {
        $self->_WRITE( $k, $write );
    } else {
	    push( @{ $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[1] }, $write );
		$write=join("\n",@{ $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[1] });
		$self->{pipe_mode}{ $k->[0] }{ $k->[1] }[1]=[];
	    $self->_WRITE($k, $write );

    }
    

    $self->{stage}{ $k->[0] }{ $k->[1] }=['DATA',2];
}

sub _DATAEND {
    my $self=shift;
    my $k=shift;
    $self->{stage}{ $k->[0] }{ $k->[1] }=['DATAEND',1];
    #$self->_WRITE($k,$self->{data}{ $k->[0] }{ $k->[1] }{data}."\r\n.");

    my $write = $self->{on_queue}{ $k->[0] }{ $k->[1] }{data}."\r\n.";
    
    if ( $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[0] < 2 ) {
	    $write = join("\n", (@{ $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[1] },$write) );
		$self->{pipe_mode}{ $k->[0] }{ $k->[1] }[1]=[];
        $self->_WRITE( $k, $write );

		$self->{stage}{ $k->[0] }{ $k->[1] }=['DATAEND',2];
		$self->{data}{ $k->[0] }{ $k->[1] }={};

		} elsif ( $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[0] == 2 ) {
        

		if ( $self->{queue_size}{ $k->[0] }{ $k->[1] } == 0 ) {
			$self->{pipe_mode}{ $k->[0] }{ $k->[1] }[2]=1;
      	    $write = join("\n",@{ $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[1] })."\n".$write;
			$self->{pipe_mode}{ $k->[0] }{ $k->[1] }[1]=[];
			$self->_WRITE( $k, $write );
			$self->{stage}{ $k->[0] }{ $k->[1] }=['DATAEND',2];
			$self->{data}{ $k->[0] }{ $k->[1] }={};
	    } else {
		    $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[2]{to}=$self->{on_queue}{ $k->[0] }{ $k->[1] }{to};
			$self->{pipe_mode}{ $k->[0] }{ $k->[1] }[2]{queue}=$self->{queue}{ $k->[0] }{ $k->[1] };
		
			push( @{ $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[1] }, $write );
			$self->{stage}{ $k->[0] }{ $k->[1] }=['MAIL',0];
			$self->{data}{ $k->[0] }{ $k->[1] }={};
			$self->_MAIL($k);
		}

		
    }

   

      #$self->{cv}->end;
}

sub _HEADER {
    my $self=shift;
    my $k=shift;
    my $line=shift;
    
    $line=~m/^((\d{3})[ \-](\w+?)(?: (.*?)|)[\r\n]*?)$/is;

    my $status = lc($2);
    my $head = lc($3);
    
    $self->{header}{ $k->[0] }{ $k->[1] }{$head}=[split/ /,($4||'')];
}


###########################


sub _READ {
    my $self=shift;
    my $k=shift;
    
    $self->{last_active}=time;
    
    $self->{fh}{ $k->[0] }{ $k->[1] }->push_read (line => sub {
        
        $self->{handle}{ $k->[0] }{ $k->[1] }=shift;
        $self->{buffer}{ $k->[0] }{ $k->[1] }=shift;
        $self->_DEBUG($k,$self->{buffer}{ $k->[0] }{ $k->[1] }) if $self->{debug} >= 1;
            
        if ($self->{buffer}{ $k->[0] }{ $k->[1] }=~m/^(\d+?)([ \-])(.*?)$/is) {
            $self->{status_code}{ $k->[0] }{ $k->[1] }=$1;
            $self->{status_mode}{ $k->[0] }{ $k->[1] }=$2;
            $self->{status_text}{ $k->[0] }{ $k->[1] }=$3;

            my $r_read=$self->_FUNC('read',$self,$k,0,$self->{queue}{ $k->[0] }{ $k->[1] });

            if ( $self->{status_code}{ $k->[0] }{ $k->[1] } == 250 and $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'DATAEND' and $self->{stage}{ $k->[0] }{ $k->[1] }[1] == 2 ) {
                #$self->{cv}->end;
                #$self->{open_threads}--;
                #if ($self->{open_threads} == -1) {
                  #  $self->{cv} = AnyEvent->condvar;
                #    $self->{open_threads}=3;
                #}
                
                $self->{stats}{ $k->[0] }{ $k->[1] }{queue}{pass}++;
                $self->_DEBUG($k,'Email : '.(++$self->{stats}{ $k->[0] }{ $k->[1] }{queue}{count}).' : '.$self->{on_queue}{ $k->[0] }{ $k->[1] }{to}.' : PASS',8) if $self->{debug} >= 1;
                my $r=$self->_FUNC('pass',$self,$k,0,$self->{queue}{ $k->[0] }{ $k->[1] });

                
                #print "THREADS($self->{open_threads})\n";
                $self->{stage}{ $k->[0] }{ $k->[1] }=['MAIL',0];
            } elsif ( $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[0] == 2 and $self->{status_code}{ $k->[0] }{ $k->[1] } == 250 and $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'DATA' and $self->{stage}{ $k->[0] }{ $k->[1] }[1] == 2 and $self->{pipe_mode}{ $k->[0] }{ $k->[1] }[2]{to} ne '') {

				$self->{stats}{ $k->[0] }{ $k->[1] }{queue}{pass}++;
                $self->_DEBUG($k,'Email : '.(++$self->{stats}{ $k->[0] }{ $k->[1] }{queue}{count}).' : '.$self->{pipe_mode}{ $k->[0] }{ $k->[1] }[2]{to}.' : PASS',8) if $self->{debug} >= 1;
                my $r=$self->_FUNC('pass',$self,$k,0,$self->{pipe_mode}{ $k->[0] }{ $k->[1] }[2]{queue});
				$self->{pipe_mode}{ $k->[0] }{ $k->[1] }[2]={};
			}
            
            if ( $self->{status_code}{ $k->[0] }{ $k->[1] } == 220 and ($self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'BEGIN' or $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'HELO') ) {
                $self->{stage}{ $k->[0] }{ $k->[1] }=['HELO',0];
                if (  $self->{status_mode}{ $k->[0] }{ $k->[1] } eq ' ' ) {
    
                my $r=$self->_FUNC('connect_pass',$self,$k,0,$self->{queue}{ $k->[0] }{ $k->[1] });

                $self->_HELO($k);
                $self->{stage}{ $k->[0] }{ $k->[1] }=['HELO',1];
                }
            } elsif ( $self->{status_code}{ $k->[0] }{ $k->[1] } == 220 and $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'STARTTLS' ) {    
               
               $self->_STARTTLS($k);
                
            } elsif ( $self->{status_code}{ $k->[0] }{ $k->[1] } == 221 ) {
                
                
                $self->{fh}{ $k->[0] }{ $k->[1] }->destroy;
                
                
                
            } elsif ( $self->{status_code}{ $k->[0] }{ $k->[1] } == 421 ) {
                               
                my $r=$self->_FUNC('hang',$self,$k,0,[$self->{on_queue}{ $k->[0] }{ $k->[1] }]);
        $self->_DEBUG($k,'Email : '.(++$self->{stats}{ $k->[0] }{ $k->[1] }{queue}{count}).' : '.$self->{on_queue}{ $k->[0] }{ $k->[1] }{to}.' : HANG',8) if $self->{debug} >= 1;
        $self->reconnect($k, $self->{retry}{ $k->[0] }{hang} ) if ($r == 1 or $r == 103);
                
            } elsif ( ($self->{status_code}{ $k->[0] }{ $k->[1] } == 250 and $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'HELO') or $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'HEADER' ) {
                $self->{stage}{ $k->[0] }{ $k->[1] }=['HEADER',0];
                $self->_HEADER($k,$self->{buffer}{ $k->[0] }{ $k->[1] });
        
                if ( $self->{status_mode}{ $k->[0] }{ $k->[1] } eq ' ' ) {
                     $self->{stage}{ $k->[0] }{ $k->[1] }=['HEADER',1]; 
                    
                   
                    if ( ($self->{secure}{ $k->[0] } == 3 or $self->{secure}{ $k->[0] } == 4) and exists($self->{header}{ $k->[0] }{ $k->[1] }{starttls})  ) {
                       $self->_STARTTLS($k);
                    } elsif ( ($self->{auth}{ $k->[0] }{ $k->[1] }[0]||'0') ne '0' ) {
                        $self->_PIPE($k,1);
                        
                        $self->_AUTH($k);
 
                    } else {
                         $self->_PIPE($k,1);
                         $self->{stage}{ $k->[0] }{ $k->[1] }=['MAIL',0];
                       
                    }
                }
               
               
            } elsif ($self->{status_code}{ $k->[0] }{ $k->[1] } == 334 and $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'AUTH' and $self->{stage}{ $k->[0] }{ $k->[1] }[1] >= 1 ) {
                 $self->_AUTH($k);
            } elsif ($self->{status_code}{ $k->[0] }{ $k->[1] } == 235 and $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'AUTH' and $self->{stage}{ $k->[0] }{ $k->[1] }[1] >= 1 ) {
                 $self->{stage}{ $k->[0] }{ $k->[1] }=['MAIL',0];
            }
            
            
            if (  $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'MAIL' and $self->{stage}{ $k->[0] }{ $k->[1] }[1] == 0 ) {
                $self->_MAIL($k);
                
            } elsif ( $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'MAIL' and $self->{stage}{ $k->[0] }{ $k->[1] }[1] == 2  ) {
            
                if ($self->{status_code}{ $k->[0] }{ $k->[1] } == 250) {
                    $self->{stage}{ $k->[0] }{ $k->[1] }=['TO',0];
                    $self->_TO($k);
                    
                }
                
                
            } elsif ( $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'TO' and $self->{stage}{ $k->[0] }{ $k->[1] }[1] == 2  ) {
                
                if ($self->{status_code}{ $k->[0] }{ $k->[1] } == 250) {
                    $self->{stage}{ $k->[0] }{ $k->[1] }=['DATA',0];
                    $self->_DATA($k);
                    
                }
                
                
            } elsif ( $self->{stage}{ $k->[0] }{ $k->[1] }[0] eq 'DATA' and $self->{stage}{ $k->[0] }{ $k->[1] }[1] == 2  ) {
                
                if ($self->{status_code}{ $k->[0] }{ $k->[1] } == 354 ) {
                    $self->{stage}{ $k->[0] }{ $k->[1] }=['DATAEND',0];
                    $self->_DATAEND($k);
                    
                }
                
                
            }
            

            
            

        }
        
    });
    
}

sub _WRITE {
   my $self=shift;
   my $k=shift;
    my $str=shift;
    $str=~s/[\r\n]+?$//s;
    
    $self->{last_active}=time;
    
   $self->_DEBUG($k,'>>'.$str) if $self->{debug} >= 1;
   $self->{handle}{ $k->[0] }{ $k->[1] }->push_write( ($self->{encode} ne '') ? Encode::encode($self->{encode}=>$str."\r\n"):$str."\r\n" );
}

sub _DEBUG {
    my $self=shift;
    my $k=shift;
    my $str=shift||'';
    my $dlevel = shift||10;
    
    if ( $dlevel <= $self->{debug} ) {
        my $out = '['.$k->[0].':'.$k->[1].':'.$self->{stats}{ $k->[0] }{ $k->[1] }{queue}{id}.']['.$self->_STRFTIME('[YYYY]-[MM]-[DD] [hh]:[mm]:[ss]',time).'] '.$str."\n";

        if ( exists($self->{debug_path}) ) {
            print { $self->{debug_fh}{ $k->[0].':'.$k->[1] }  } $out;
        } else {
            print $out;
        }
    
    }
}

sub _STRFTIME {
  my $self = shift;
  my $format=shift;
  my $time=shift;
  
    my @time=localtime($time);
    
    my %DT=(
            'YYYY'=>$time[5]+1900,
            'MM'=>sprintf('%.2d',$time[4]+1),
            'DD'=>sprintf('%.2d',$time[3]),
            'hh'=>sprintf('%.2d',$time[2]),
            'mm'=>sprintf('%.2d',$time[1]),
            'ss'=>sprintf('%.2d',$time[0]),
            #'MNA'=>$mon3[($time[4])],
            #'DNAME'=>$day6[($time[6])],
            'WK'=>(( ($time[7]+1-$time[6]) <= 7) ? '01':sprintf('%.2d',($time[7]+1-$time[6])/7)+1)
            );
    
    $format=~s/\[(YYYY|MM|DD|hh|mm|ss|MNA|DNAME|WK)\]/$DT{$1}/gs;
    
    return $format;

}


sub _MKDIRF {
    my $self=shift;
    my $path=shift;

    my $sep=0;
    my $np2='';

    if ($path=~s!^(\w\:|)\/!!s) {
    	$np2=''.($1||'');
    } else {
	$sep=1;
    }
    my @f=split/\//,$path;

    my $fl=pop(@f);
    foreach my $f (@f) {
	if ($sep == 0) {
            $np2.='/'.$f;
	} else {
            $np2.=$f;
	    $sep=0;
	}

         #print "DIR($np2)\n";
         if (!(-e $np2)) {
            #print "GOOD\n";
            my $mk=mkdir($np2);
            #print "MK($mk)\n";
         }
    }
    
}


1;