package PerlSpeak;
use 5.006;
use strict;
use warnings;
use POSIX qw(:termios_h);
use IO::Socket;
use vars qw($VERSION);
$VERSION = '2.01';



sub new {
	my $pkg = shift;
	my $self = {
		"tts_engine" => "festival_pipe",
		"tts_command" => "",
		"tts_file_command" => "",
		"file2wave_command" => "",
		"make_readable" => "[_\/]",
		"no_dot_files" => 1,
		"hide_extentions" => 0,
		"browsable" => 1,
		"dir_return" => 1,
		"file_prefix" => "File",
		"dir_prefix" => "Folder",
		"echo_off" => 0,
                "voice" => "kal_diphone",
                "rate" => 1,
                "volume" => 1,
                "pitch" => 50,
                "lang" => "en",
		@_};
	return bless $self, $pkg;
}

sub say {
	my $self = shift;
	my $arg = shift;
        my $rep = shift || " ";
	chomp $arg;
	print "\n$arg\n" unless $self->{echo_off};
	if ($self->{tts_command}){
		my $command = $self->{tts_command};
		$command =~s/text_arg/\"$arg\"/ ;
		system $command or die "Error with tts_command";
	}elsif ($self->{tts_engine} eq "festival"){
		system "echo \"$arg\" | festival --tts";
	}elsif ($self->{tts_engine} eq "cepstral"){
		system "swift \"$arg\"";
	}elsif ($self->{tts_engine} eq "espeak"){
	        $arg =~s/!/\./g;
		system "echo  \"$arg\" | espeak -v $self->{voice} -s $self->{rate} -a $self->{volume} -p $self->{pitch}";
	}elsif ($self->{tts_engine} eq "festival_server") {
            $arg =~ s/[\n\r"]/$rep/g;
            $self->festival("(let ((utt (Utterance Text \"$arg\")))  (begin ($self->{voice}) (Parameter.set 'Duration_Stretch $self->{rate})  (utt.synth utt) (utt.wave.resample utt 8000) (utt.wave.rescale utt $self->{volume})  (utt.play utt)))\n");
        }elsif ($self->{tts_engine} eq "festival_pipe") {
            return unless $arg;
            system("echo \"(let ((utt (Utterance Text \\\"$arg\\\")))  (begin ($self->{voice}) (Parameter.set 'Duration_Stretch $self->{rate})  (utt.synth utt) (utt.wave.resample utt 8000) (utt.wave.rescale utt $self->{volume})  (utt.play utt)))\" | festival --pipe");
        }
}

sub festival {
    my $self = shift;
    my $arg = shift;
    return unless $self->{tts_engine} eq "festival_server";
    $self->{'handle'}->print("$arg\n");
}

sub config_festival { # voice, rate, volume
    my $self = shift;
    my $voice = shift;
    my $rate = shift;
    my $vol = shift;
    return $self->config_voice($voice, $rate, $vol);
}

sub config_voice { # voice, rate, volume, pitch
    my $self = shift;
    my $voice = shift;
    my $rate = shift;
    my $vol = shift;
    my $pitch = shift || 50;
    return 0 unless $self->voice($voice);
    return 0 unless $self->rate($rate);
    return 0 unless $self->volume($vol);
    return 0 unless $self->pitch($pitch);
    return 1;
}


sub voice {
    my $self = shift;
    my $voice = shift;
    $self->{voice} = $voice if $voice;
    return $self->{voice};
}

sub pitch {
    my $self = shift;
    my $pitch = shift || "50";
    $self->{pitch} = $pitch if $pitch;
    return $self->{pitch};
}

sub rate {
    my $self = shift;
    my $rate = shift;
    $self->{rate} = $rate if $rate;
    return $self->{rate};
}

sub volume {
    my $self = shift;
    my $vol = shift;
    $self->{volume} = $vol if $vol;
    return $self->{volume};
}

sub get_voices {
    my $self = shift;
    my $line = "";
    my @lst = ();
    my @voice_lst = ();
    if (($self->{tts_engine} eq "festival_server") || ($self->{tts_engine} eq "festival_pipe")) {
        return unless $self->{handle}->connected();
        
        die "can't fork: $!" unless defined(my $kidpid = fork());

        if ($kidpid) {
            # parent copies the socket to standard output
            while ($line !~ /voices/) {
                $line = $self->{handle}->getline;
            }
            $line =~ s/[()\n\r]//g;
            @lst = split " ", $line;
            foreach (@lst) {
                next if /\.|1|voices/;
                push @voice_lst, $_ if /\w_\w/;
            }

            kill("TERM" => $kidpid);        # send SIGTERM to child
            return \@voice_lst;
        }
        else {
            $self->{handle}->print("voice-locations\n");
        }
    } elsif ($self->{tts_engine} eq "espeak") {
        my @tmp = `espeak --voices=$self->{lang}`;
        foreach my $line (@tmp) {
        next if $line =~ /ender/;
            $line =~ s/^ //;
            my @word = split /\s/, $line;
            foreach (@word) {
                if (/\//) {
                    push @voice_lst, $_;
                    last;
                }
            }
        }
        return \@voice_lst;
    }
}

sub festival_connect {
    my $self = shift;
    if ($self->{handle}) {
        return 1 if $self->{handle}->connected();
    }
    $self->{host} = shift || "127.0.0.1";
    $self->{port} = shift || 1314;
    $self->{handle} = IO::Socket::INET->new(Proto     => "tcp",
				PeerAddr  => $self->{host},
				PeerPort  => $self->{port})
    or die "
  Can't connect to port $self->{port} on $self->{host}: $!
  (Are you sure the server is running and accepting connections?)

";
return $self->{handle};
}

sub tts_engine {
    my $self = shift;
    if (my $tts = shift) {
        $self->{tts_engine} = $tts;
    }
    return $self->{tts_engine};
}

sub readfile {
	my $self = shift;
	my $arg = shift;
	if (-e $arg){
		if ($self->{tts_file_command}){
			my $command = $self->{tts_file_command};
			$command =~s/file_arg/$arg/;
			system $command;
		}elsif ($self->{tts_engine} eq "festival"){
			system "festival --tts $arg";
		}elsif ($self->{tts_engine} eq "cepstral"){
			system "$self->{path_to_tts}swift -f $arg";
		}elsif ($self->{tts_engine} eq "espeak"){
			system "espeak -f $arg";
                }elsif (($self->{tts_engine} eq "festival_server") or ($self->{tts_engine} eq "festival_pipe")) {
                    open FH, "$arg" or die "ERROR! Could not open $arg: $!\n";
                    my $txt = "";
                    while (<FH>) {
                        $txt .= $_;
                    }
                    $txt =~ s/[\n\r"`]/ /g;
                    close FH;
                    $self->say($txt);
		}else {
			$self->say("ERROR! with tts engine or tts  file command.") & die "ERROR! with tts_engine or tts_file_command.";
		}	
	} else {
		$self->say("ERROR! $arg is not a file.") & die "ERROR! $arg is not a file.";
	}
}

sub file2wave {
	my $self = shift;
	my $in = shift;
	my $out = shift;
	my $play = shift or 1;
	if (-e $in){
		if ($self->{file2wave_command}){
			my $command = $self->{file2wave_command};
			$command =~s/IN/$in/;
			$command =~s/OUT/$out/;
			system "$command";
		} elsif ($self->{tts_engine} eq "festival") {
			system "text2wave -otype riff -o $out $in";
		} elsif ($self->{tts_engine} eq "cepstral") {
			system "swift -m text -f $in -o $out";
		} elsif ($self->{tts_engine} eq "espeak") {
		        print "espeak -f $in -w $out\n";
			system "espeak -f $in -w $out";
		} elsif ($self->{tts_engine} eq "festival_server") {
                        $self->file2wave_festival($in, $out, " ", $play);
                } elsif ($self->{tts_engine} eq "festival_pipe") {
                        $self->say("ERROR! TTS engine festival_pipe cannot convert text to wave files.  Use TTS engine festival_server instead.");
                }
	} else {
		$self->say("ERROR! $in is not a file.") & die "ERROR! $in is not a file.";
	}
}

sub file2wave_festival {
	my $self = shift;
	my $in = shift;
	my $out = shift;
        my $rep = shift;
        my $play = shift;
        $rep = " " unless $rep;

    my ($host, $port, $kidpid, $handle, $line, $remains, $result);

    my $wave_type = "riff";                 # the type of the audio files
    my $file_stuff_key = "ft_StUfF_key";    # defined in speech tools

    # tell the server to send us back a 'file' of the right type
    $self->festival("(Parameter.set 'Wavefiletype '$wave_type)");

    # split the program into two processes, identical twins
    die "can't fork: $!" unless defined($kidpid = fork());

    # the if{} block runs only in the parent process
    if ($kidpid) {
       # the parent handles the input so it can exit on quit
        undef $line;
        while (($line = $remains) || defined ($line = $self->{handle}->getline())) {
            undef $remains;
            if ($line eq "WV\n") { # we have a waveform coming
                undef $result;
                if ($out) {
                    open(AUDIO, ">$out");
                } else {
                    die "ERROR! No output file argument";
                }
                while ($line = $self->{handle}->getline()) {
                    if ($line =~ s/$file_stuff_key(.*)$//s) {
                        $remains = $1;
                        print AUDIO $line;
                        last;
                    }
                    print AUDIO $line;
                }
                close AUDIO;
                last;
            }
        }
        kill("TERM" => $kidpid);        # send SIGTERM to child
        system("mplayer $out") if $play;
    } else {
        my $txt = "";
        open FH, "$in" or  die "ERROR! Could not open $in: $!\n";
        while (<FH>) {
            $txt .= $_;
        }
        $txt =~ s/[\n\r"]/$rep/g;
        close FH;
        $self->festival("(let ((utt (Utterance Text \"$txt\")))  (begin ($self->{voice}) (Parameter.set 'Duration_Stretch $self->{rate})  (utt.synth utt) (utt.wave.resample utt 8000) (utt.wave.rescale utt $self->{volume})  (utt.send.wave.client utt)))");
    }
}




sub menu { 
	my $self = shift;
	my $count = shift;
	my @var = @_;
	if ($#var % 2 == 0) {
	   unshift @var, $count;
	   $count = 0;
	}
	my %var_hash = @var;
	my @keys = sort(keys %var_hash);
	my $str = "";
	my $command = "";
	while (not $command){
		$self->say($keys[$count]);
		my $answ = $self->getch();
		if (ord($answ)==27){
		        $str = "";
			$answ  = $self->getch();
			if (ord($answ)==91){
				$answ  = $self->getch();
				$count++ if $answ =~/B/;
				$count-- if $answ =~/A/;
				$count = 0 if $count == scalar(@keys);
				$count = scalar(@keys) - 1 if $count < 0;
			}

		} elsif ((ord($answ)==10) or (ord($answ)==13) or ($answ =~ /[yY]/)){
			$command = 1;
			&{$var_hash{$keys[$count]}};
		} elsif (($answ =~ /\d/) and ($str eq "")) {
			$count = $answ -1;
                        $command = 1;
			#&{$var_hash{$keys[$count]}};
		} elsif ($answ =~ /\w/) {
			$str .= uc $answ;
			foreach my $i (0..$#keys) {
				my $test = uc $keys[$i];
				$count = $i and last if ($test =~ /^\d\. $str/);
			}
		}
	}
	return $count;
}

sub menu_list {
	my $self = shift;
	my @lst = @_;
	my $count = 0;
	my $str = "";
	while (1) {
		$self->say($lst[$count]);
		my $answ = $self->getch();
		if (ord($answ)==27){
		        $str = "";
			$answ  = $self->getch();
			if (ord($answ)==91){
				$answ  = $self->getch();
				$count++ if $answ =~/B/;
				$count-- if $answ =~/A/;
				$count = 0 if $count > $#lst;
				$count = $#lst if $count < 0;
			}
		} elsif ((ord($answ)==10) or (ord($answ)==13) or (ord($answ)==89) or (ord($answ)==121)){
			last;
		} elsif ($answ =~ /\w/) {
		   $str .= lc $answ;
		   $count = 0;
		   foreach (@lst) {
		      my $test = lc $_;
		      if ($test =~ /^$str/) {
		          last;
		      } else {
		          $count++;
		          $count = $#lst if $count > $#lst;
		      }
		   }
	        }
	}
	return $lst[$count];
}

sub filepicker {
	my $self = shift;
	my $d = shift;
	my $file = "";
	my $flter = "";
	my $answ = "";
	my @tmp = ();
	my @lst = ();
	while (not $file) {
		my $count = 0;
		opendir DH, $d or die("Error opening directory: $d\n   $!");
		my @dirlst = (sort readdir DH) or die("Error reading directory: $d\n   $!");
		my $od = $d;
		while ((not $file) and ($od eq $d)) {
			my $f = $dirlst[$count];
			if (($f eq ".") or ($f eq "..") or ($self->{no_dot_files} and $f =~/^\./)) {
				$count++;
				next;
			}
			if (-d"$d/$f"){
				$flter = $f;
				$flter =~ s/_/ /g;
				$self->say("$self->{dir_prefix} $flter?");
				$answ = $self->getch();
                                if ($answ =~ /[a-zA-Z0-9]/){
                                    for( my $c = 0; $c < $#dirlst; $c++) {
                                        if ($dirlst[$c] =~ /^$answ/) {
                                            $count = $c;
                                            last;
                                        }
                                    }
                                    next;
                                } 
				if (ord($answ)==27){
					$answ  = $self->getch();
					if (ord($answ)==91){
					       
						$answ  = $self->getch();
						$count++ if $answ =~/B/;
						$count-- if $answ =~/A/;
						$count = 0 if $count == scalar(@dirlst);
						$count = scalar(@dirlst) - 1 if $count < 0;
						if (($answ =~/C/) && ($self->{browsable})) {
							$d = "$d/$f";
							last;
						}
						if (($answ =~/D/) && ($self->{browsable})) {
							@lst = split '/', $d;
							pop @lst;
							$d = join '/', @lst;
							$d = '/' if $d eq "";
							next;
						}
					}
				}elsif ((ord($answ)==10) or (ord($answ)==13) or (ord($answ)==89) or (ord($answ)==121)){
					$file = "$d/$f";
					return $file;
				}elsif ((ord($answ)==85) or (ord($answ)==117)){
					@lst = split '/', $d;
					pop @lst;
					$d = join '/', @lst;
					$d = '/' if $d eq "";
					next;				
				}
			}elsif (-f "$d/$f"){
				$flter = $f;
				if ($self->{hide_extentions}){
					$flter =~ s/\.[\w]*$//;
				}
				if ($self->{make_readable}) {
					my $pattern = $self->{make_readable};
					$flter =~ s/$pattern/ /g;
				}
				$self->say("$self->{file_prefix} $flter?");
				$answ = $self->getch();
                                if ($answ =~ /[a-zA-Z0-9]/){
                                    for( my $c = 0; $c < $#dirlst; $c++) {
                                        if ($dirlst[$c] =~ /^$answ/) {
                                            $count = $c;
                                            last;
                                        }
                                    }
                                    next;
                                } 
				if (ord($answ)==27){
					$answ  = $self->getch();
					if (ord($answ)==91){
						$answ  = $self->getch();
						$count++ if $answ =~/B/;
						$count-- if $answ =~/A/;
						$count = 0 if $count == scalar(@dirlst);
						$count = scalar(@dirlst) - 1 if $count < 0;
						if (($answ =~/C/) && ($self->{browsable})) {
							$file = "$d/$f";
							last;
						}
						if (($answ =~/D/) && ($self->{browsable})) {
							@lst = split '/', $d;
							pop @lst;
							$d = join '/', @lst;
							$d = '/' if $d eq "";
							next;
						}
					}
				}elsif ((ord($answ)==10) or (ord($answ)==89) or (ord($answ)==121)){
					$file = "$d/$f";
					return $file;
					last;
				}
			}else{print "Error $d/$f";}
		}
		closedir DH;
	}
	return $file;
}


sub dirpicker {
	my $self = shift;
	my $d = shift;
	my $folder = "";
	my $answ = "";
	my @lst = ();
	while ($folder eq "") {
		my $count = 0;
		opendir DH, $d or die("Error opening directory: $d\n   $!");
		my @dirlst = (sort readdir DH) or die("Error reading directory: $d\n   $!");
		closedir DH;
		while ($folder eq "") {
			my $f = $dirlst[$count];
			if (($f eq ".") or ($f eq "..") or ($self->{no_dot_files} and $f =~/^\./)) {
				$count++;
				next;
			}
			if (-d"$d/$f"){
				$self->say($f);
				$answ = $self->getch();
				if (ord($answ)==27){
					$answ  = $self->getch();
					if (ord($answ)==91){
						$answ  = $self->getch();
						$count++ if $answ =~/B/;
						$count-- if $answ =~/A/;
						$count = 0 if $count == scalar(@dirlst);
						$count = scalar(@dirlst) - 1 if $count < 0;
						if ($answ =~/C/){
							$folder = $self->dirpicker("$d/$f");
						}
						if ($answ =~/D/){
							@lst = split '/', $d;
							pop @lst;
							$d = join '/', @lst;
							$d = '/' if $d eq "";
							last;
						}

					}
				}elsif ((ord($answ)==10) or (ord($answ)==89) or (ord($answ)==121)){
					$folder = "$d/$f";
				}elsif ((ord($answ)==85) or (ord($answ)==117)){
					@lst = split '/', $d;
					pop @lst;
					$d = join '/', @lst;
					$d = '/' if $d eq "";
					last;
				}

			}else{
                                $count++;
                                if ($count > $#dirlst) {
                                    $self->say("There are no folders in this directory. Moving up one level.");
				    @lst = split '/', $d;
				    pop @lst;
				    $d = join '/', @lst;
				    $d = '/' if $d eq "";
				    last;
	                        }
				next;
			}
		}
	}
	return $folder;
}

sub fileselect {
    my $self = shift;
    my $dir = shift;
    my @prompt = @_;
    $prompt[0] = "Enter a file filter" unless $prompt[0];
    $prompt[1] = "Press F1 for help" unless $prompt[1];
    $prompt[2] = "Spacebar Selects or Deselects a file... Press Control-A to select all... Press enter key when done... Press F1 for help" unless $prompt[2];
    chdir $dir;
    my $filter = $self->getString($prompt[0], 1);
    my @lst = `ls $filter`;
    unless ($lst[0]) {
        $self->say("No Files Found.");
        return 0;
    }
    my @counts;
    my $count = 0;
    my $str = "";
    my $speech_flag = 1;
    $self->say($prompt[1]) if $prompt[1];
    while (1) {
        my $fname = "";
        chomp $lst[$count];
        print "$dir/$lst[$count]\n";
        if (-d "$dir/$lst[$count]") {
        print "DIR\n";
            $fname = "$self->{dir_prefix} $lst[$count]";
        } elsif (-f "$dir/$lst[$count]") {
        print "FILE\n";
            $fname = "$self->{file_prefix} $lst[$count]";
        }
        $self->say($fname) if $speech_flag;
        my $answ = $self->getch();
        if ($answ eq " ") { # Select or Deselect a file
            push @counts, $count;
            $speech_flag = 0;
        } elsif (ord($answ)==1) { # Control-A
            @counts = ();
            my $i;
            foreach (@lst) {
                push @counts, $i++;
            }
            $speech_flag = 0;
        } elsif (ord($answ)==27){
            $str = "";
            $answ  = $self->getch();
            if (ord($answ)==91){
                $answ  = $self->getch();
                $count++ if $answ =~/B/;
		$count-- if $answ =~/A/;
		$count = 0 if $count > $#lst;
		$count = $#lst if $count < 0;
		$speech_flag = 1;
		if (ord($answ)==49){
                    $a = $self->getch();
                    $b = $self->getch() if ord($a) == 49;
                    if (ord($b) == 126) { # F1 pressed
                        if ($prompt[2] ne 'F1') {
                            $self->say($prompt[2]);
                        } else {
                            return '^F1 Pressed^';
                        }
                    }
                }
       	    }
        } elsif ((ord($answ)==10) or (ord($answ)==13)) {
            last;
        } elsif ($answ =~ /\w/) {
	   $str .= lc $answ;
	   $count = 0;
	   foreach (@lst) {
	      my $test = lc $_;
	      if ($test =~ /^$str/) {
	          last;
	      } else {
	          $count++;
	          $count = $#lst if $count > $#lst;
	      }
	   }
	   $speech_flag = 1;
        }
    }
        my %hash;
        my @file_list;
	foreach (@counts) {
	   $hash{$_}++;
	}
	foreach (keys %hash) {
	   if ($hash{$_} % 2 == 1) { # File is selected
	       push @file_list, $lst[$_];
	   }
        }
        return @file_list;
}


sub getch {
	my $self = shift;
        my $fd_stdin = fileno(STDIN);
        my $term = POSIX::Termios->new();
        $term->getattr($fd_stdin);
        my $oterm = $term->getlflag();
        my $echo = ECHO | ECHOK | ICANON;
        my $noecho = $oterm & ~$echo;
        my $key = '';
        $term->setlflag($noecho);
        $term->setcc(VTIME, 1);
        $term->setattr($fd_stdin, TCSANOW);
        sysread(STDIN, $key, 1);
    	$term->setlflag($oterm); 
    	$term->setcc( VTIME, 0);
    	$term->setattr($fd_stdin, TCSANOW); 
        return $key;
}

sub getString {
	my $self = shift;
	my $prompt = shift;
        my $no_confirm = shift;
	$self->say($prompt) if $prompt;
	my $ord = 0;
	my $string;
	my @chrlst;
	while (1){
		my $chr = $self->getch();
		$ord = ord($chr);
		if ($ord == 127) {
			pop @chrlst;
			$self->say("Backspace");
		} elsif ($ord == 32) {
			$self->say("Space");
			push @chrlst, $chr;
                } elsif ($ord == 46) {
                       $self->say("dot");
			push @chrlst, $chr;
                } elsif ($ord == 45) {
                       $self->say("dash");
			push @chrlst, $chr;
                } elsif ($ord == 10){
                        last;
		} elsif ($ord < 28) {
			return $ord;
		} else {
			$self->say($chr);
			push @chrlst, $chr;
		}
	}
		
	$string = join '', @chrlst;
	chomp $string;
        if ($no_confirm){
            return $string;
        } else {
            $self->say("You have entered $string. Is this correct?");
            $self->confirm() ? return $string : return $self->getString($prompt);
        }
}

sub confirm {
	my $self = shift;
	my $txt = shift;
	$self->say($txt) if $txt;
	my $answ = $self->getch();
	return 1 if $answ =~/[yY\n]/;
	return 0 if $answ =~/[nN]/;
	$self->say("Please answer Y for yes or N for no.");
	return $self->confirm();
}

sub getType {
	my $self = shift;
	my $fname=shift;
	my %Type = (
	'HTML', "text/html",
	'HTM', "text/html",
	'STM', "text/html",
	'SHTML', "text/html",
	'TXT', "text/plain",
	'PREF', "text/plain",
	'AIS', "text/plain",
	'RTX', "text/richtext",
	'TSV', "text/tab-separated-values",
	'NFO', "text/warez-info",
	'ETX', "text/x-setext",
	'SGML', "text/x-sgml",
	'SGM', "text/x-sgml",
	'TALK', "text/x-speech",
	'CGI', "text/plain", # we want these two as text files
	'PL', "text/plain", # and not application/x-httpd-cgi
	'PHP', "text/plain",
	#-------------------------------------<IMAGE>----
	'COD', "image/cis-cod",
	'FID', "image/fif",
	'GIF', "image/gif",
	'ICO', "image/ico",
	'IEF', "image/ief",
	'JPEG', "image/jpeg",
	'JPG', "image/jpeg",
	'JPE', "image/jpeg",
	'PNG', "image/png",
	'TIF', "image/tiff",
	'TIFF', "image/tiff",
	'MCF', "image/vasa",
	'RAS', "image/x-cmu-raster",
	'CMX', "image/x-cmx",
	'PCD', "image/x-photo-cd",
	'PNM', "image/x-portable-anymap",
	'PBM', "image/x-portable-bitmap",
	'PGM', "image/x-portable-graymap",
	'PPM', "image/x-portable-pixmap",
	'RGB', "image/x-rgb",
	'XBM', "image/x-xbitmap",
	'XPM', "image/x-xpixmap",
	'XWD', "image/x-xwindowdump",
	#-------------------------------------<APPS>-----
	'BZ2', "application/x-bzip2",
	'EXE', "application/octet-stream",
	'BIN', "application/octet-stream",
	'DMS', "application/octet-stream",
	'LHA', "application/octet-stream",
	'CLASS', "application/octet-stream",
	'DLL', "application/octet-stream",
	'AAM', "application/x-authorware-map",
	'AAS', "application/x-authorware-seg",
	'AAB', "application/x-authorware-bin",
	'VMD', "application/vocaltec-media-desc",
	'VMF', "application/vocaltec-media-file",
	'ASD', "application/astound",
	'ASN', "application/astound",
	'DWG', "application/autocad",
	'DSP', "application/dsptype",
	'DFX', "application/dsptype",
	'EVY', "application/envoy",
	'SPL', "application/futuresplash",
	'IMD', "application/immedia",
	'HQX', "application/mac-binhex40",
	'CPT', "application/mac-compactpro",
	'DOC', "application/msword",
	'ODA', "application/oda",
	'PDF', "application/pdf",
	'AI', "application/postscript",
	'EPS', "application/postscript",
	'PS', "application/postscript",
	'PPT', "application/powerpoint",
	'RTF', "application/rtf",
	'APM', "application/studiom",
	'XAR', "application/vnd.xara",
	'ANO', "application/x-annotator",
	'ASP', "application/x-asap",
	'CHAT', "application/x-chat",
	'BCPIO', "application/x-bcpio",
	'VCD', "application/x-cdlink",
	'TGZ', "application/x-compressed",
	'Z', "application/x-compress",
	'CPIO', "application/x-cpio",
	'PUZ', "application/x-crossword",
	'CSH', "application/x-csh",
	'DCR', "application/x-director",
	'DIR', "application/x-director",
	'DXR', "application/x-director",
	'FGD', "application/x-director",
	'DVI', "application/x-dvi",
	'LIC', "application/x-enterlicense",
	'EPB', "application/x-epublisher",
	'FAXMGR', "application/x-fax-manager",
	'FAXMGRJOB', "application/x-fax-manager-job",
	'FM', "application/x-framemaker",
	'FRAME', "application/x-framemaker",
	'FRM', "application/x-framemaker",
	'MAKER', "application/x-framemaker",
	'GTAR', "application/x-gtar",
	'GZ', "application/x-gzip",
	'HDF', "application/x-hdf",
	'INS', "application/x-insight",
	'INSIGHT', "application/x-insight",
	'INST', "application/x-install",
	'IV', "application/x-inventor",
	'JS', "application/x-javascript",
	'SKP', "application/x-koan",
	'SKD', "application/x-koan",
	'SKT', "application/x-koan",
	'SKM', "application/x-koan",
	'LATEX', "application/x-latex",
	'LICMGR', "application/x-licensemgr",
	'MAIL', "application/x-mailfolder",
	'MIF', "application/x-mailfolder",
	'NC', "application/x-netcdf",
	'CDF', "application/x-netcdf",
	'SDS', "application/x-onlive",
	'SGI-LPR', "application/x-sgi-lpr",
	'SH', "application/x-sh",
	'SHAR', "application/x-shar",
	'SWF', "application/x-shockwave-flash",
	'SPRITE', "application/x-sprite",
	'SPR', "application/x-sprite",
	'SIT', "application/x-stuffit",
	'SV4CPIO', "application/x-sv4cpio",
	'SV4CRC', "application/x-sv4crc",
	'TAR', "application/x-tar",
	'TARDIST', "application/x-tardist",
	'TCL', "application/x-tcl",
	'TEX', "application/x-tex",
	'TEXINFO', "application/x-texinfo",
	'TEXI', "application/x-texinfo",
	'T', "application/x-troff",
	'TR', "application/x-troff",
	'TROFF', "application/x-troff",
	'MAN', "application/x-troff-man",
	'ME', "application/x-troff-me",
	'MS', "application/x-troff-ms",
	'TVM', "application/x-tvml",
	'TVM', "application/x-tvml",
	'USTAR', "application/x-ustar",
	'SRC', "application/x-wais-source",
	'WKZ', "application/x-wingz",
	'ZIP', "application/x-zip-compressed",
	'ZTARDIST', "application/x-ztardist",
	#-------------------------------------<AUDIO>----
	'AU', "audio/basic",
	'SND', "audio/basic",
	'ES', "audio/echospeech",
	'MID', "audio/midi",
	'KAR', "audio/midi",
	'MPGA', "audio/mpeg",
	'MP2', "audio/mpeg",
	'TSI', "audio/tsplayer",
	'VOX', "audio/voxware",
	'AIF', "audio/x-aiff",
	'AIFC', "audio/x-aiff",
	'AIFF', "audio/x-aiff",
	'MID', "audio/x-midi",
	'MP3', "audio/x-mpeg",
	'MP2A', "audio/x-mpeg2",
	'MPA2', "audio/x-mpeg2",
	'M3U', "audio/x-mpegurl",
	'MP3URL', "audio/x-mpegurl",
	'PAT', "audio/x-pat",
	'RAM', "audio/x-pn-realaudio",
	'RPM', "audio/x-pn-realaudio-plugin",
	'RA', "audio/x-realaudio",
	'SBK', "audio/x-sbk",
	'STR', "audio/x-str",
	'WAV', "audio/x-wav",
	#-------------------------------------<VIDEO>----
	'MPEG', "video/mpeg",
	'MPG', "video/mpeg",
	'MPE', "video/mpeg",
	'QT', "video/quicktime",
	'MOV', "video/quicktime",
	'VIV', "video/vivo",
	'VIVO', "video/vivo",
	'MPS', "video/x-mpeg-system",
	'SYS', "video/x-mpeg-system",
	'MP2V', "video/x-mpeg2",
	'MPV2', "video/x-mpeg2",
	'AVI', "video/x-msvideo",
	'MV', "video/x-sgi-movie",
	'MOVIE', "video/x-sgi-movie",
	#-------------------------------------<EXTRA>----
	'PDB', "chemical/x-pdb",
	'XYZ', "chemical/x-pdb",
	'CHM', "chemical/x-cs-chemdraw",
	'SMI', "chemical/x-daylight-smiles",
	'SKC', "chemical/x-mdl-isis",
	'MOL', "chemical/x-mdl-molfile",
	'RXN', "chemical/x-mdl-rxn",
	'SMD', "chemical/x-smd",
	'ACC', "chemical/x-synopsys-accord",
	'ICE', "x-conference/x-cooltalk",
	'SVR', "x-world/x-svr",
	'WRL', "x-world/x-vrml",
	'VRML', "x-world/x-vrml",
	'VRJ', "x-world/x-vrt",
	'VRJT', "x-world/x-vrt",
	#-----------------------------------<Windows Media Files>
	'ASX', "video/x-ms-asf",
	'WMA', "audio/x-ms-wma",
	'WAX', "audio/x-ms-wax",
	'WMV', "audio/x-ms-wmv",
	'WVX', "video/x-ms-wvx",
	'WM', "video/x-ms-wm",
	'WMX', "video/x-ms-wmx",
	'WMZ', "application/x-ms-wmz",
	'WMD', "application/x-ms-wmd",
        #------------------------------------<Open Office Files>
        'ODT', "application/vnd.oasis.opendocument.text",
        'OTT', "application/vnd.oasis.opendocument.text-template",
        'OTH', "application/vnd.oasis.opendocument.text-web",
        'ODM', "application/vnd.oasis.opendocument.text-master",
        'ODG', "application/vnd.oasis.opendocument.graphics",
        'OTG', "application/vnd.oasis.opendocument.graphics-template",
        'ODP', "application/vnd.oasis.opendocument.presentation",
        'OTP', "application/vnd.oasis.opendocument.presentation-template",
        'ODS', "application/vnd.oasis.opendocument.spreadsheet",
        'OTS', "application/vnd.oasis.opendocument.spreadsheet-template",
        'ODC', "application/vnd.oasis.opendocument.chart",
        'ODF', "application/vnd.oasis.opendocument.formula",
        'ODB', "application/vnd.oasis.opendocument.database",
        'ODI', "application/vnd.oasis.opendocument.image",
	);
	my @tmp = split(/\./, $fname);
	my $ext = pop @tmp;
	$ext = uc $ext;
	$Type{$ext}?return $Type{$ext}:return "unknown/unknown";
}


1;

__END__

=head1 NAME

 PerlSpeak - Perl Module for text to speech with festival, espeak, cepstral and others.

=head1 SYNOPSIS

 my $ps = PerlSpeak->new([property => value, property => value, ...]);

=head2 METHODS

 $ps = PerlSpeak->new([property => value, property => value, ...]);
 # Creates a new instance of the PerlSpeak object.

 $ps->say("Text to speak.");
 $ps->say("file_name");
 # The basic text to speech interface.
 
 $ps->readfile("file_name");
 # Reads contents of a text file.
 
 $ps->file2wave("text_file_in", "audio_file_out");
 # Converts a text file to an audio file.

 $path = $ps->filepicker("/start/directory");
 # An audio file selector that returns a path to a file. If "dir_return" is true
 # "filepicker" may also return the path to a directory.

 $path = $ps->dirpicker("/start/directory");
 # An audio directory selector that returns a path to a directroy.

 $chr = $ps->getchr(); 
 # Returns next character typed on keyboard

 $ps->menu($prompt => $callback, ...)
 # An audio menu executes callback when item is selected

 $item = $ps->menu_list(@list);
 # Returns element of @list selected by user.

 $string = $ps->getString([$prompt]);
 # Returns a string speaking each character as you type. Also handles backspaces

 $boolean = $ps->confirm([$prompt]);
 # Returns boolean. Prompts user to enter Y for yes or N for no.  Enter also returns true.

 $ps->config_voice("voice_name", $voice_rate, $voice_volume, $voice_pitch);
 # Configures voice. Excepts standard parameters for festival and espeak.
 # For festival:
 #   The voice rate values should be between 0.50 and 2.00;
 #   The voice volume values should be between 0.33 and 6.00;
 #   The voice pitch is not used.
 # For espeak:
 #   The voice rate values are words per minute. 160 is a standard setting;
 #   The voice volume values should be between 0 and 20. 10 is a standard setting;
 #   The voice pitch values should be between 0 and 99. 50 is a standard setting;
 
 $ps->config_festival("voice_name", $voice_speed, $voice_volume);
 # See as config_voice above.

 $tts = $ps->tts_engine(["tts_engine"]); # Gets or Sets tts_engine property.
 $voice = $ps->set_voice(["voice_name"]); # See config_voice above.
 $rate = $ps->set_rate([$rate]); # See config_voice above.
 $volume = $ps->set_volume([$volume]); # See config_voice above.
 $pitch = $ps->set_pitch([$pitch]); # See config_voice above.

 $voices = $ps->get_voices();
 # Returns a refrence to a list of available voices in the language of $self->{lang} property.

 $ps->festival_connect([$host, $port]);
 # Must be used if using festival_server as the tts_engine.

 $mime_type = $ps->getType($filename); # Returns Mime Type for $filename.
 

=head2 PROPERTIES

 # The default property settings should work in most cases. The exception is
 # if you want to use a tts system other than festival or cepstral. The rest
 # of the properties are included because I found them usefull in some instances.

 $ps->{tts_engine} => $text; # Default is "festival_pipe"
 # Valid values are "festival", "festival_server", "festival_pipe", "espeak" or
 # "cepstral" Other tts engines can be used by using the tts command properties.
 
 $ps->{tts_command} => "command text_arg"; # Default is ""
 # Command to read a text string. "text_arg" = text string.
 
 $ps->{tts_file_command} => "command file_arg" # Default is ""
 # Command to read a text file. "file_arg"  = path to text file to be read.
 
 $ps->{file2wave_command} => "command IN OUT"; # Default is ""
 # Command for text file to wave file. "IN" = input file "OUT" = output file.
 # Not needed if tts_engine is festival" or "cepstral.
 
 $ps->{no_dot_files} => $boolean; # Default is 1
 $ Hides files that begin with a '.'
 
 $ps->{hide_extentions} => $boolean;  # Default is 0
 # Will hide file extensions.
 # NOTE: If hiding extensions the no_dot_files property must be set to 1.
 
 $ps->{make_readable} => "regexp pattern"; # default is "[_\\]"  
 # will substitute spaces for regexp pattern 
 
 $ps->{browsable} => $boolean; # Default is 1
 # If true filepicker can browse other directories via the right and left arrows. 
 
 $ps->{dir_return} => $boolean; # Default is 1
 # If true filepicker may return directories as well as files.
 
 $ps->{file_prefix} => $text; # Default is "File"
 # For filepicker. Sets text to speak prior to file name. 
 
 $ps->{dir_prefix} => "text"; # Default is "Folder"
 # For filepicker and dirpicker. Sets text to speak prior to directory name. 

 $ps->{echo_off} => $boolean; # Default is 0
 # If set to true, turns off printing of text to screen.

 $ps->{voice} => $text; # # Use set_voice($voice) instead.
 # Must be set to a valid voice name for tts_engine used. This is especially
 # true for festival_server and festival_pipe

 $ps->{lang} => $text; # Default is "en" for english.
 # Used only if espeak is the tts_engine.

 $ps->{rate} => $double; # Use set_rate($rate) instead.

 $ps->{volume} => $double; # Use set_volume($volume) instead.

 $ps->{pitch} => $double; # Use set_pitch($pitch) instead.


=head1 DESCRIPTION

  PerlSpeak.pm is Perl Module for text to speech with festival or cepstral.
  (Other tts systems may be used by setting the tts command properties).
  PerlSpeak.pm includes several useful interface methods like an audio file 
  selector and menu system. PerlSpeak.pm was developed to use in the 
  Linux Speaks system, an audio interface to linux for blind users. 
  More information can be found at the authors website http://www.joekamphaus.net


=head1 CHANGES

 1/9/2007 ver 0.03

 * Fixed error handling for opendir and readdir.

 * Added property tts_command => $string 
    (insert "text_arg" where the text to speak should be.)

 * Added property no_dot_files => $boolean default is 1
    (Set to 0 to show hidden files)

 * Fixed bug in tts_engine => "cepstral" (previously misspelled as cepstrel)

 * Added funtionality to traverse directory tree up as well as down.
    (user can now use the arrow keys for browsing and selecting
    up and down browses files in current directory. Right selects the 
    file or directory. Left moves up one directory like "cd ..")

 * Added property hide_extentions => $boolean to turn off speaking of file
    extensions with the filepicker method. Default is 0.
    (NOTE: If hiding extensions the no_dot_files property must be set to 1)
    
 * Added property "make_readable" which takes a regular expression as an
    argument. PerlSpeak.pm substitues a space for characters that match
    expression. The default is "[_\\]" which substitutes a space for "\"
    and "_".



 1/9/2007 ver 0.50
 
 * Added funtionality for reading a text file. Method "say" will now take
    text or a file name as an argument. Also added method "readfile" which
    takes a file name as an argument. The property tts_file_command was also
    added to accomodate tts systems other than festival or cepstral.

 * Added funtionality for converting a text file to a wave file via the
    "file2wave" method and optionally the "file2wave_command" property.
 
 * Added properties "file_prefix" and "dir_prefix" to enable changing
    text to speak prior to file and directory names in the "filepicker"
    and "dirpicker" methods.
    
 * Added "browsable", a boolean property which will togle the browsable feature
    of the "filepicker" method. 
    
 * Added "dir_return", a boolean property which will allows the "filepicker" 
    method to return the path to a directory as well as the path to a file.
    
 * Changed required version of perl to 5.6. I see no reason why PerlSpeak.pm
    should not work under perl 5.6, however, this has not yet been tested. If
    you have problems with PerlSpeak on your version of perl let me know.
    
    

 10/10/2007 ver 1.50
  * Added boolean property echo_off to turn off printing of text said to screen.

  * Added method menu_list(@list) Returns element of @list selected by user.

  * Added method getString() Returns a string speaking each character as you
    type. Also handles backspaces.

  * Added method conirm(). Returns boolean. Prompts user to enter Y for yes
    or N for no.  Enter also returns true.

  * Added shortcuts to the menu() method. You can press the number of menu
    index or the letter of the first word in menu item to jump to that item.

 01/02/2008 ver 2.01
  * Added suport for festival_server, festival_pipe, and espeak text to speech
    engines. This includes several methods and properties such as voice, pitch
    volume, and rate.

  * Added method getType(filename) Returns mime type for filename.



=head1 EXAMPLE

  # Several examples can be found in the example directory included with the
  # tarball for this module.

  use PerlSpeak;
  
  my $ps = PerlSpeak->new();
  
  # Set properties
  $ps->{tts_engine} = "festival"; # or cepstrel
  # Optionally set your own tts command use text_arg where the text goes
  $ps->{tts_command} => ""; 
  $ps->{no_dot_files} => 1;
  $ps->{hide_extentions} => 0;
    
   
  # Audio file selectors
  my $file = $ps->filepicker($ENV{HOME}); # Returns a file.
  my $dir = $ps->dirpicker($ENV{HOME}); # Returns a directory.
  
  $ps->say("Hello World!"); # The computer talks.

  # Returns the next character typed on the keyboard
  # May take 2 or 3 calls for escape sequences.
  print $ps->getch(); 

  # Make some sub refs to pass to menu  
  my $email = sub {
	print "Email\n";
  };
  my $internet = sub {
	print "Internet\n";
  };
  my $docs = sub {
	print "Documents\n"
  };
  my $mp3 = sub {
	print "MP3\n";	
  };
  my $cdaudio = sub {
	print "CD Audio\n"
  };
  my $help = sub {
	print "Browse Help\n"
  };

  # menu is a audio menu
  # Pass menu a hash of "text to speak" => $callback pairs
  $ps->menu(
	"E-mail Menu" => $email,
	"Internet Menu" => $internet,
	"Documents Menu" => $docs,
	"M P 3 audio" => $mp3,
	"C D audio" => $cdaudio,
	"Browse help files" => $help,
  };


=head1 SEE ALSO

  More information can be found at the authors website http://www.joekamphaus.net
  
  The Festival Speech Synthesis System can be found at:
    http://www.cstr.ed.ac.uk/projects/festival/

  The eSpeak text to speech synthesizer can be found at:
    http://espeak.sourceforge.net/

  Reasonably priced high quality proprietary software voices from Cepstral 
  can be found at: http://www.cepstral.com.

  The Flite (festival-lite) Speech Synthesis System can be found at:
    http://www.speech.cs.cmu.edu/flite/index.html


=head1 AUTHOR

Joe Kamphaus, E<lt>joe@joekamphaus.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joe Kamphaus

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.

# This module is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.


=cut
