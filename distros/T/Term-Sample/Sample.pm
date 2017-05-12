#!/usr/bin/perl	

# Copyright (c) 2000  Josiah Bryan  USA
#
# See AUTHOR section in pod text below for usage and distribution rights.   
#

BEGIN {
	 $Term::Sample::VERSION = "0.25";
	 $Term::Sample::ID = 
'$Id: Term::Sample.pm, v'.$Term::Sample::VERSION.' 2000/16/09 01:29:08 josiah Exp $';
}


package Term::Sample;

    @ISA = qw(Exporter);
	@EXPORT = qw();
	@EXPORT_OK = qw(sample average new_set
					load save analyze 
					diff print_data p 
					intr round plus 
					new_Set to_string);

    use strict;
	use Time::HiRes qw(gettimeofday);  
	
	sub new {
		bless {},shift;
	}
	
	sub sample {
		my $self = shift if(substr($_[0],0,6) eq 'Term::');
		my %args = @_;
		my $echo = $args{echo} || 0;
		$echo=0 if($echo eq 'key');
		my $print_flag = ($echo eq 'none')?0:1;                          
		my $newline = $args{newline} || 1;
		my ($flag,$state,$key,$delay,$sample,$ms1,$s1,$ms2,$s2,$counter)=
		(0,0,0,0,[],0,0,0,0);
		while(!$flag) {
			my @ci = getch();
			my $c=$ci[0];
			my $s=$ci[1];
			my $ok=(ascii($c)!=13 && ascii($c)!=8 && ascii($c)!=0)?1:0;
			
			# Handle key down
			if(($c && $s && $ok) 
			|| ($^O ne "MSWin32" && $c && $ok)) {
				($s1,$ms1) = gettimeofday;
				if(!$key) {                     
					$sample->[$key] = { key => $c, delay => 0, inter => 0 };
				} else {
					$sample->[$key] = { key => $c, delay => plus($ms1-$ms2), inter => 0 };
				}
				$counter = 0;
			} 
			
			# Handle key up
			elsif(($c && !$s && $ok) 
			   || ($^O ne "MSWin32" && $c && $ok)) {
				($s2,$ms2) = gettimeofday;
				$sample->[$key]->{inter} = plus($ms2-$ms1);
				$counter = 0;
				$key++;
			} 
			
			# Handle backspace display and data removal
			if($c && !$s && ascii($c)==8) {
				print "$c $c" if($key>0);
				$key-- if($key>0);
				$sample->[$key] = { key => '', $delay => 0, inter => 0 };
			
			# Print out all correct echoes
			} else {         
				print $echo if($c && !$s && $echo && $print_flag && ascii($c)!=0);
				print $c if($c && !$s && !$echo && $print_flag && ascii($c)!=13 && ascii($c)!=0);
			}
			
			# Exit loop if enter pressed
			$flag = 1 if(ascii($c) == 13 && $key);
		}
		print "\n" if($newline);
		return $sample;
	}	
	            
	sub print_data {
		my $self = shift if(substr($_[0],0,6) eq 'Term::');
		my $sample = shift; # || $_;
		my %args = @_;
		my $type = $args{type};
		if(ref($sample) ne "ARRAY" && ($type eq "basic" || $type eq "avg" || $type eq "average")) {
			print "Error: Invalid sample data type at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
			return undef;
		} 
		elsif(ref($sample) ne "HASH" && ($type eq "analysis" || $type eq "overview" || $type eq "details")) {
			print "Error: Invalid analysis data type at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
			return undef;
		}
		if(ref($sample) eq "ARRAY") {
			if(!$type || $type eq 'basic') {
				for my $key (0..$#{$sample}) {
					print "idx: $key ",(($key<10)?'  ':' '),"[ key => $sample->[$key]->{key}, delay => $sample->[$key]->{delay}, inter => $sample->[$key]->{inter} ]\n";
				}
			} 
			elsif($type eq 'average' || $type eq 'avg') {
				my $delay = 0;
				my $inter = 0;
				my $codes = 0;
				for my $key (0..$#{$sample}) {
					 $codes+=ascii($sample->[$key]->{key});
					 $delay+=$sample->[$key]->{delay};
					 $inter+=$sample->[$key]->{inter};
				}
				print "Total Key Presses      : $#{$sample}\n";
				print "Average Key Codes      : ",plus(round($codes/$#{$sample},2)),"\n";
				print "Average Key Hold Time  : ",plus(round($inter/$#{$sample},2)),"\n";
				print "Average Inter-Key Time : ",plus(round($delay/$#{$sample},2)),"\n";
			}
		} elsif(ref($sample) eq "HASH") {
			if($type eq "overview" || !$type) {
				print "\nAnalysis Overview\n";
				print "\nTotal Key Presses      : $sample->{size}\n";
				print "Average Key Codes      : ",round($sample->{avg_codes},2),"\n";
				print "Average Key Hold Time  : ",round($sample->{avg_delay},2),"\n";
				print "Average Inter-Key Time : ",round($sample->{avg_inter},2),"\n";

				my $x=0;                         
				print "\nTop Inter-Key Speeds: \n";
				print "\tKeys     : $sample->{sorted_delay}->[0]->{codes}->[0]->{char}, $sample->{sorted_delay}->[0]->{codes}->[1]->{char}, $sample->{sorted_delay}->[0]->{codes}->[2]->{char} \n";
				print "\tCodes    : $sample->{sorted_delay}->[0]->{codes}->[0]->{key}, $sample->{sorted_delay}->[0]->{codes}->[1]->{key}, $sample->{sorted_delay}->[0]->{codes}->[2]->{key} \n";
				print "\tSum Delay: $sample->{sorted_delay}->[0]->{delay}    Sum Inter: $sample->{sorted_delay}->[0]->{inter}\n";
				print "\n";
				print "\tKeys     : $sample->{sorted_delay}->[1]->{codes}->[0]->{char}, $sample->{sorted_delay}->[1]->{codes}->[1]->{char}, $sample->{sorted_delay}->[1]->{codes}->[2]->{char} \n";
				print "\tCodes    : $sample->{sorted_delay}->[1]->{codes}->[0]->{key}, $sample->{sorted_delay}->[1]->{codes}->[1]->{key}, $sample->{sorted_delay}->[1]->{codes}->[2]->{key} \n";
				print "\tSum Delay: $sample->{sorted_delay}->[1]->{delay}    Sum Inter: $sample->{sorted_delay}->[1]->{inter}\n";
				
				my $x=0;                         
				print "\nLowest Press Times: \n";
				print "\tKeys     : $sample->{sorted_inter}->[0]->{codes}->[0]->{char}, $sample->{sorted_inter}->[0]->{codes}->[1]->{char}, $sample->{sorted_inter}->[0]->{codes}->[2]->{char} \n";
				print "\tCodes    : $sample->{sorted_inter}->[0]->{codes}->[0]->{key}, $sample->{sorted_inter}->[0]->{codes}->[1]->{key}, $sample->{sorted_inter}->[0]->{codes}->[2]->{key} \n";
				print "\tSum Delay: $sample->{sorted_inter}->[0]->{delay}    Sum Inter: $sample->{sorted_inter}->[0]->{inter}\n";
				print "\n";
				print "\tKeys     : $sample->{sorted_inter}->[1]->{codes}->[0]->{char}, $sample->{sorted_inter}->[1]->{codes}->[1]->{char}, $sample->{sorted_inter}->[1]->{codes}->[2]->{char} \n";
				print "\tCodes    : $sample->{sorted_inter}->[1]->{codes}->[0]->{key}, $sample->{sorted_inter}->[1]->{codes}->[1]->{key}, $sample->{sorted_inter}->[1]->{codes}->[2]->{key} \n";
				print "\tSum Delay: $sample->{sorted_inter}->[1]->{delay}    Sum Inter: $sample->{sorted_inter}->[1]->{inter}\n";
			} 
			elsif($type eq "analysis" || $type eq "details") {
				print "\nAnalysis Details\n";
				print "\nTotal Key Presses      : $sample->{size}\n";
				print "Average Key Codes      : ",round($sample->{avg_codes},2),"\n";
				print "Average Key Hold Time  : ",round($sample->{avg_delay},2),"\n";
				print "Average Inter-Key Time : ",round($sample->{avg_inter},2),"\n";

				print "\nInter-Key Speeds: \n";
				for my $x (0..$#{$sample->{sorted_delay}}) {
					print "\tKeys     : $sample->{sorted_delay}->[$x]->{codes}->[0]->{char}, $sample->{sorted_delay}->[$x]->{codes}->[1]->{char}, $sample->{sorted_delay}->[$x]->{codes}->[2]->{char} \n";
					print "\tCodes    : $sample->{sorted_delay}->[$x]->{codes}->[0]->{key}, $sample->{sorted_delay}->[$x]->{codes}->[1]->{key}, $sample->{sorted_delay}->[$x]->{codes}->[2]->{key} \n";
					print "\tSum Delay: $sample->{sorted_delay}->[$x]->{delay}    Sum Inter: $sample->{sorted_delay}->[$x]->{inter}\n";
					print "\n";
				}
								
				print "\nKey Hold Times: \n";
				for my $x (0..$#{$sample->{sorted_delay}}) {
					print "\tKeys     : $sample->{sorted_inter}->[$x]->{codes}->[0]->{char}, $sample->{sorted_inter}->[$x]->{codes}->[1]->{char}, $sample->{sorted_inter}->[$x]->{codes}->[2]->{char} \n";
					print "\tCodes    : $sample->{sorted_inter}->[$x]->{codes}->[0]->{key}, $sample->{sorted_inter}->[$x]->{codes}->[1]->{key}, $sample->{sorted_inter}->[$x]->{codes}->[2]->{key} \n";
					print "\tSum Delay: $sample->{sorted_inter}->[$x]->{delay}    Sum Inter: $sample->{sorted_inter}->[$x]->{inter}\n";
					print "\n";
				}
				
			}
		} else {
			print "Error: Invalid data type at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
			return undef;				
		}
	}
	
	sub to_string {
		my $self = shift if(substr($_[0],0,6) eq 'Term::');
		my $sample = shift;
		if(ref($sample) ne "ARRAY") {
			print "Error: Invalid data type at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
			return undef;				
		}

		my $str;
		$str.=$sample->[$_]->{key} for (0..$#{$sample});
		
		return $str;
	}
		
	sub diff {
		my $self = shift if(substr($_[0],0,6) eq 'Term::');
		my $sample1 = shift;
		my $sample2 = shift;
		my %args = @_;
		my $v = $args{verbose} || 0;
		if(ref($sample1) ne "HASH" || ref($sample2) ne "HASH") {
			print "Error: Invalid data type at @{[(caller)[1]]} line @{[(caller)[2]]}: Both arguments must be HASH refrences from analyze().\n";
			return undef;				
		}
		
		my $diff = 0; 
		my $count = 0;
		my $sample;
			    
		if($v) {			   
	    	print "\nAnalysis Diff\n";
			print "\nTotal Key Presses         : ",round(p($sample1->{size},$sample2->{size}),2),"%\n";
			print "Average Key Codes Diff      : ",round(p($sample1->{avg_codes},$sample2->{avg_codes}),2),"%\n";
			print "Average Key Hold Time Diff  : ",round(p($sample1->{avg_inter},$sample2->{avg_inter}),2),"%\n";
			print "Average Inter-Key Time Diff : ",round(p($sample1->{avg_delay},$sample2->{avg_delay}),2),"%\n";
	    }
	    
	    $diff+=p($sample1->{size}*2000,$sample2->{size}*2000);
		$diff+=p($sample1->{avg_codes}*1050,$sample2->{avg_codes}*1050);
		$diff+=p($sample1->{avg_inter},$sample2->{avg_inter});
		$diff+=p($sample1->{avg_delay},$sample2->{avg_delay});
		
		$count+=4;
	    
		print "\nInter-Key Speeds Diff: \n" if($v);
		for my $x (0..$#{$sample1->{sorted_delay}}) {
			my $a = p(ascii($sample1->{sorted_delay}->[$x]->{codes}->[0]->{char}),ascii($sample2->{sorted_delay}->[$x]->{codes}->[0]->{char})) + 
				    p(ascii($sample1->{sorted_delay}->[$x]->{codes}->[1]->{char}),ascii($sample2->{sorted_delay}->[$x]->{codes}->[1]->{char})) + 
				    p(ascii($sample1->{sorted_delay}->[$x]->{codes}->[2]->{char}),ascii($sample2->{sorted_delay}->[$x]->{codes}->[2]->{char}));
			
			my $b = p(ascii($sample1->{sorted_delay}->[$x]->{codes}->[0]->{key}),ascii($sample2->{sorted_delay}->[$x]->{codes}->[0]->{key})) + 
				    p(ascii($sample1->{sorted_delay}->[$x]->{codes}->[1]->{key}),ascii($sample2->{sorted_delay}->[$x]->{codes}->[1]->{key})) + 
				    p(ascii($sample1->{sorted_delay}->[$x]->{codes}->[2]->{key}),ascii($sample2->{sorted_delay}->[$x]->{codes}->[2]->{key}));
			
			my $c = p($sample1->{sorted_delay}->[$x]->{delay}, $sample2->{sorted_delay}->[$x]->{delay});
			my $d = p($sample1->{sorted_delay}->[$x]->{inter}, $sample2->{sorted_delay}->[$x]->{inter});
			
			if(($x<3 && $v==1) || ($v==2)) {
				print "\tKeys     : $a\n";
				print "\tCodes    : $b\n";
				print "\tSum Delay: $c    Sum Inter: $d\n";
				print "\n";
			}
			
			$diff  += ($a+$b+$c+$d);
			$count += 8;
		}
								
		print "\nKey Hold Times: \n" if($v);
		for my $x (0..$#{$sample1->{sorted_delay}}) {
			my $a = p(ascii($sample1->{sorted_inter}->[$x]->{codes}->[0]->{char}),ascii($sample2->{sorted_inter}->[$x]->{codes}->[0]->{char})) + 
				    p(ascii($sample1->{sorted_inter}->[$x]->{codes}->[1]->{char}),ascii($sample2->{sorted_inter}->[$x]->{codes}->[1]->{char})) + 
				    p(ascii($sample1->{sorted_inter}->[$x]->{codes}->[2]->{char}),ascii($sample2->{sorted_inter}->[$x]->{codes}->[2]->{char}));
			
			my $b = p(ascii($sample1->{sorted_inter}->[$x]->{codes}->[0]->{key}),ascii($sample2->{sorted_inter}->[$x]->{codes}->[0]->{key})) + 
				    p(ascii($sample1->{sorted_inter}->[$x]->{codes}->[1]->{key}),ascii($sample2->{sorted_inter}->[$x]->{codes}->[1]->{key})) + 
				    p(ascii($sample1->{sorted_inter}->[$x]->{codes}->[2]->{key}),ascii($sample2->{sorted_inter}->[$x]->{codes}->[2]->{key}));
			
			my $c = p($sample1->{sorted_inter}->[$x]->{delay}, $sample2->{sorted_inter}->[$x]->{delay});
			my $d = p($sample1->{sorted_inter}->[$x]->{inter}, $sample2->{sorted_inter}->[$x]->{inter});
			
			if(($x<3 && $v==1) || ($v==2)) {
				print "\tKeys     : $a\n";
				print "\tCodes    : $b\n";
				print "\tSum Delay: $c    Sum Inter: $d\n";
				print "\n";
			}
			
			$diff  += ($a+$b+$c+$d);
			$count += 8;
		}             
		
		return intr(($diff/$count)%100);
	
	}
	
	sub average {
		my $self = shift if(substr($_[0],0,6) eq 'Term::');
		my @vectors = @_;
		my $out;
		
		if(ref($vectors[0]) eq "HASH") {
			$out = {};
		
			my $x = $#vectors+1;
			for my $sample (@vectors) {
				$out->{size} += $sample->{size};
				$out->{avg_codes} += ($sample->{avg_codes}/$x);
				$out->{avg_delay} += ($sample->{avg_delay}/$x);
				$out->{avg_inter} += ($sample->{avg_inter}/$x);
	
				for my $x (0..$#{$sample->{sorted_delay}}) {
					$out->{sorted_delay}->[$x]->{codes}->[0]->{char} = $vectors[0]->{sorted_delay}->[$x]->{codes}->[0]->{char};
					$out->{sorted_delay}->[$x]->{codes}->[1]->{char} = $vectors[0]->{sorted_delay}->[$x]->{codes}->[0]->{char};
					$out->{sorted_delay}->[$x]->{codes}->[2]->{char} = $vectors[0]->{sorted_delau}->[$x]->{codes}->[0]->{char};
					$out->{sorted_delay}->[$x]->{codes}->[0]->{key}+=($sample->{sorted_delay}->[$x]->{codes}->[0]->{key}/$x); 
					$out->{sorted_delay}->[$x]->{codes}->[1]->{key}+=($sample->{sorted_delay}->[$x]->{codes}->[1]->{key}/$x); 
					$out->{sorted_delay}->[$x]->{codes}->[2]->{key}+=($sample->{sorted_delay}->[$x]->{codes}->[2]->{key}/$x); 
					$out->{sorted_delay}->[$x]->{delay}+=($sample->{sorted_delay}->[$x]->{delay}/$x); 
					$out->{sorted_delay}->[$x]->{inter}+=($sample->{sorted_delay}->[$x]->{inter}/$x); 
				}
									
				for my $x (0..$#{$sample->{sorted_delay}}) {
					$out->{sorted_inter}->[$x]->{codes}->[0]->{char} = $vectors[0]->{sorted_inter}->[$x]->{codes}->[0]->{char};
					$out->{sorted_inter}->[$x]->{codes}->[1]->{char} = $vectors[0]->{sorted_inter}->[$x]->{codes}->[1]->{char};
					$out->{sorted_inter}->[$x]->{codes}->[2]->{char} = $vectors[0]->{sorted_inter}->[$x]->{codes}->[2]->{char};
					$out->{sorted_inter}->[$x]->{codes}->[0]->{key}+=($sample->{sorted_inter}->[$x]->{codes}->[0]->{key}/$x); 
					$out->{sorted_inter}->[$x]->{codes}->[1]->{key}+=($sample->{sorted_inter}->[$x]->{codes}->[1]->{key}/$x); 
					$out->{sorted_inter}->[$x]->{codes}->[2]->{key}+=($sample->{sorted_inter}->[$x]->{codes}->[2]->{key}/$x); 
					$out->{sorted_inter}->[$x]->{delay}+=($sample->{sorted_inter}->[$x]->{delay}/$x); 
					$out->{sorted_inter}->[$x]->{inter}+=($sample->{sorted_inter}->[$x]->{inter}/$x); 
				}
			}
		} elsif(ref($vectors[0]) eq "ARRAY") {
			$out = [];
			my $x = $#vectors+1;
			for my $sample (@vectors) {
				for my $key (0..$#{$sample}) {
					$out->[$key]->{key} = $vectors[0]->[$key]->{key};
					$out->[$key]->{delay} += ($sample->[$key]->{delay}/$x);
					$out->[$key]->{inter} += ($sample->[$key]->{inter}/$x);
				}
			}
		} else {
			print "Error: Invalid data type at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
			return undef;
		}
		
		return $out;
	}    
	
	sub save {
		my $self = shift if(substr($_[0],0,6) eq 'Term::');
		my $sample = shift;
		my $file = shift;  
		if(ref($sample) ne "ARRAY" && ref($sample) ne "HASH") {
			print "Error: Invalid save data type at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
			return undef;
		} 
	
		open(F, ">$file");
		
		if(ref($sample) eq "HASH") {
			print F "type=hash\n";
			print F "size=$sample->{size}\n";
			print F "avg_codes=$sample->{avg_codes}\n";
			print F "avg_delay=$sample->{avg_delay}\n";
			print F "avg_inter=$sample->{avg_inter}\n";
			
			print F "sorted_delay_size=$#{$sample->{sorted_delay}}\n";
			for my $x (0..$#{$sample->{sorted_delay}}) {                                         
				print F "sorted_delay:$x:keys=$sample->{sorted_delay}->[$x]->{codes}->[0]->{char}::$sample->{sorted_delay}->[$x]->{codes}->[1]->{char}::$sample->{sorted_delay}->[$x]->{codes}->[2]->{char}\n";
				print F "sorted_delay:$x:codes=$sample->{sorted_delay}->[$x]->{codes}->[0]->{key},$sample->{sorted_delay}->[$x]->{codes}->[1]->{key},$sample->{sorted_delay}->[$x]->{codes}->[2]->{key}\n";
				print F "sorted_delay:$x:delay=$sample->{sorted_delay}->[$x]->{delay}\n";
				print F "sorted_delay:$x:inter=$sample->{sorted_delay}->[$x]->{inter}\n";
			}
									
			print F "sorted_inter_size=$#{$sample->{sorted_inter}}\n";
			for my $x (0..$#{$sample->{sorted_inter}}) {                                         
				print F "sorted_inter:$x:keys=$sample->{sorted_inter}->[$x]->{codes}->[0]->{char}::$sample->{sorted_inter}->[$x]->{codes}->[1]->{char}::$sample->{sorted_inter}->[$x]->{codes}->[2]->{char}\n";
				print F "sorted_inter:$x:codes=$sample->{sorted_inter}->[$x]->{codes}->[0]->{key},$sample->{sorted_inter}->[$x]->{codes}->[1]->{key},$sample->{sorted_inter}->[$x]->{codes}->[2]->{key}\n";
				print F "sorted_inter:$x:delay=$sample->{sorted_inter}->[$x]->{delay}\n";
				print F "sorted_inter:$x:inter=$sample->{sorted_inter}->[$x]->{inter}\n";
			}
		} else {
			print F "type=array\n";
			print F "index_size=$#{$sample}\n";
			for my $key (0..$#{$sample}) {
				print F "index$key=$sample->[$key]->{key}::$sample->[$key]->{delay}::$sample->[$key]->{inter}\n";
			}
		}
	    
		close(F);
		return $sample;
	}		
	
	sub load {
		my $self = shift if(substr($_[0],0,6) eq 'Term::');
		my $file = shift; 
		if(!(-f $file)) {
			print "Error: File $file doesn't exist at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
			return undef;
		}
		
		open(F, $file);
		my @lines = <F>;
		close(F);
		
		my %db;
	    for my $line (@lines) {
	    	chomp($line);
	    	my ($a,$b) = split /=/, $line;
	    	$db{$a}=$b;
	    }
	    
	    my $sample;
	    
		if($db{type} eq "hash") {
			$sample = {};
			$sample->{size}=$db{size};
			$sample->{avg_codes}=$db{avg_codex};
			$sample->{avg_delay}=$db{avg_delay};
			$sample->{avg_inter}=$db{avg_inter};
			
			for my $x (0..$db{sorted_delay_size}) {
				($sample->{sorted_delay}->[$x]->{codes}->[0]->{char},$sample->{sorted_delay}->[$x]->{codes}->[1]->{char},$sample->{sorted_delay}->[$x]->{codes}->[2]->{char}) = 
					split /\:\:/, $db{"sorted_delay:$x:keys"};
				($sample->{sorted_delay}->[$x]->{codes}->[0]->{key},$sample->{sorted_delay}->[$x]->{codes}->[1]->{key},$sample->{sorted_delay}->[$x]->{codes}->[2]->{key}) = 
					split /,/, $db{"sorted_delay:$x:codes"};
				$sample->{sorted_delay}->[$x]->{delay}=$db{"sorted_delay:$x:delay"};
				$sample->{sorted_delay}->[$x]->{inter}=$db{"sorted_delay:$x:inter"};
			}
									
			for my $x (0..$db{sorted_inter_size}) {
				($sample->{sorted_inter}->[$x]->{codes}->[0]->{char},$sample->{sorted_inter}->[$x]->{codes}->[1]->{char},$sample->{sorted_inter}->[$x]->{codes}->[2]->{char}) = 
					split /\:\:/, $db{"sorted_inter:$x:keys"};
				($sample->{sorted_inter}->[$x]->{codes}->[0]->{key},$sample->{sorted_inter}->[$x]->{codes}->[1]->{key},$sample->{sorted_inter}->[$x]->{codes}->[2]->{key}) = 
					split /,/, $db{"sorted_inter:$x:codes"};
				$sample->{sorted_inter}->[$x]->{delay}=$db{"sorted_inter:$x:delay"};
				$sample->{sorted_inter}->[$x]->{inter}=$db{"sorted_inter:$x:inter"};
			}
		} 
		elsif($db{type} eq "array") {
			$sample = [];
			for my $key (0..$db{index_size}) {
				($sample->[$key]->{key},$sample->[$key]->{delay},$sample->[$key]->{inter}) = 
					split /\:\:/, $db{"index$key"};
			}
		} else {
			print "Error: Invalid file type in file $file at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
			return undef;
		}
		
		return $sample;
	}
		  
	sub analyze {
		my $self = shift if(substr($_[0],0,6) eq 'Term::');
		my $sample = shift;
		if(ref($sample) ne "ARRAY") {
			print "Error: Invalid sample data type at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
			return undef;
		} 
		
		my $delay = 0;
		my $inter = 0;
		my $codes = 0;
		my $size = $#{$sample};
		for my $key (0..$size-1) {
			 $codes+=ascii($sample->[$key]->{key});
			 $delay+=$sample->[$key]->{delay};
			 $inter+=$sample->[$key]->{inter};
		}
		
		$size = 1 if(!$size || $size == -1);
		my $analysis = {
			avg_codes => plus($codes/$size),
			avg_delay => plus($inter/$size),
			avg_inter => plus($delay/$size),
			size      => $size,
		};
		
		my @samples;
		for my $key (0..$size-1) {
			my $delay = 0;
			my $inter = 0;
			my $codes = [];                          
			my $keys = [];
			$codes->[++$#{$codes}]={ char => $sample->[$key-1]->{key}, key => $key-1 } if($key>0);
			$codes->[++$#{$codes}]={ char => $sample->[$key-0]->{key}, key => $key-0 };
			$codes->[++$#{$codes}]={ char => $sample->[$key+1]->{key}, key => $key+1 } if($key<$size);
			$delay+=$sample->[$key-1]->{delay} if($key>0);
			$delay+=$sample->[$key-0]->{delay};
			$delay+=$sample->[$key+1]->{delay} if($key<$size);
			$inter+=$sample->[$key-1]->{inter} if($key>0);
			$inter+=$sample->[$key-0]->{inter};
			$inter+=$sample->[$key+1]->{inter} if($key<$size);      
			$samples[++$#samples] = {
				codes => $codes,
				delay => $delay,
				inter => $inter,
			};
		}
		$analysis->{sorted_delay} = [sort by_delay @samples];
		$analysis->{sorted_inter} = [sort by_inter @samples];
		
		return $analysis;            
	}
	
	sub by_inter($$){$_[1]->{inter} <=> $_[0]->{inter}}
	sub by_delay($$){$_[1]->{delay} <=> $_[0]->{delay}}
	
	# Returns the difference between $fa and $fb as fraction of $fa
	sub p {
		shift if(substr($_[0],0,6) eq 'Term::');
		my ($fa,$fb)=(shift,shift); 
		sprintf("%.3f",$fa/($fb+1)*100); #((($fb-$fa)*((($fb-$fa)<0)?-1:1))/$fa)*100;
	}
	
	my %__ascii__lookup__table;
	for my $code (0..255){$__ascii__lookup__table{chr($code)}=$code}
	sub ascii {my $c=shift;$__ascii__lookup__table{$c}}
	
 	my $STDIN;
	if($^O eq "MSWin32") {		
		use Win32::Console;    
	    $STDIN  = new Win32::Console(STD_INPUT_HANDLE);
	} else {
		eval('use Term::ReadKey');
	}
	
	sub getch {  
 	 	if($^O eq "MSWin32") {		
		    my $e = $STDIN->GetEvents();
		   	if($e) {
		   		my @in = $STDIN->Input();
		   		return (chr($in[5]),$in[1]) if($in[0]==1);
		   	}
		   	return undef;
		} else {
			return (ReadKey(),1);
		}
	}

	# Rounds a floating-point to an integer with int() and sprintf()
	sub intr  {
    	shift if(substr($_[0],0,6) eq 'Term::');
      	try   { return int(sprintf("%.0f",shift)) }
      	catch { return 0 }
	}
    
    # Round $num to $size places after decimal
    sub round {
    	my $self = shift if(substr($_[0],0,6) eq 'Term::');
    	my $num = shift;
    	my $size = shift;
    	sprintf("%.$size".'f',$num);
    }
    
    # Make a negative number postive. No effect on positive numbers.
    sub plus {          
    	my $self = shift if(substr($_[0],0,6) eq 'Term::');
    	my $num = shift;
    	return ($num*=-1) if($num<0);
    	$num;
    }
    
    # For the lazy among us :-)
    sub new_Set {
    	my $self = shift if(substr($_[0],0,6) eq 'Term::');
    	Term::Sample::Set->new(@_);
    }
    
    # Alias for above
    sub new_set { new_Set(@_) }
1;

package Term::Sample::Set;
	use Term::Sample;
	use strict;

	sub new { 
		my $type = shift;
		my %args = @_;
		my $self = { term   => Term::Sample->new(), 
					 type   => $args{type}   || 'sample', 
					 silent => $args{silent} || 0 };
		bless $self, $type;
	}
	
	sub store {
		my $self = shift;
		my %args = @_;
		
		my ($key,$sample);
		while(($key,$sample) = each %args) {
			if(ref($sample) ne (($self->{type} eq 'sample')?"ARRAY":"HASH") && !$self->{silent}) {
				print "Error: Invalid sample data type for key `$key' at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
				return undef;
			}
			if(!exists $self->{samples}->{$key}) {
				$self->{samples}->{$key} = $sample;
			} else {
				$self->{samples}->{$key} = $self->{term}->average($self->{samples}->{$key},$sample);
			}
		}
		return $self;
	}	    
	
	sub remove {
		my $self = shift;
		my $key = shift;
		if(!exists $self->{samples}->{$key} && !$self->{silent}) {
			print "Error: Key `$key' does not exist in set at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
			return undef;
		}
		delete $self->{samples}->{$key};
		return $self;
	}
	
	sub get {
		my $self = shift;
		my $key = shift;
		if(!exists $self->{samples}->{$key} && !$self->{silent}) {
			print "Error: Key `$key' does not exist in set at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
			return undef;
		}
		return $self->{samples}->{$key};
	}

	sub match {
		my $self = shift;
		my $match = shift;
		my $term = $self->{term};
		my $v = shift || 0;
		if(ref($match) ne (($self->{type} eq 'sample')?"ARRAY":"HASH") && !$self->{silent}) {
			print "Error: Invalid sample data type at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
			return undef;
		}
		
		my $test = ($self->{type} eq 'sample')?$term->analyze($match):$match;
		my @diffs = ();
		my ($key,$sample);
		while(($key,$sample) = each %{$self->{samples}}) {
			if(ref($sample) ne (($self->{type} eq 'sample')?"ARRAY":"HASH") && !$self->{silent}) {
				print "Error: Corrupted sample data type for key `$key' at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
				return undef;
			}
			my $analysis = ($self->{type} eq 'sample')?$term->analyze($sample):$sample;
			my $i=++$#diffs;
			$diffs[$i] = { diff => $term->diff($analysis, $test), key => $key };  
			print "match(): $diffs[$i]->{diff} => $diffs[$i]->{key} \n" if($v);
		}                           
		
		my $top = 0;
		for(0..$#diffs) {
			$top = $_ if($diffs[$_]->{diff} < $diffs[$top]->{diff});
		}
		
		
		return ($diffs[$top]->{key}, $diffs[$_]->{diff});
	}
	
	sub save {
		my $self = shift;
		my $file = shift;
		
		open(F, ">$file");
		
		my ($key,$sample);
		while(($key,$sample) = each %{$self->{samples}}) {
			print F "_____KEY_____=$key\n";
			if(ref($sample) ne "ARRAY" && ref($sample) ne "HASH" && !$self->{silent}) {
				print "Error: Corrupted data type key `$key' at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
				return undef;
			} 
		
			if(ref($sample) eq "HASH") {
				print F "type=hash\n";
				print F "size=$sample->{size}\n";
				print F "avg_codes=$sample->{avg_codes}\n";
				print F "avg_delay=$sample->{avg_delay}\n";
				print F "avg_inter=$sample->{avg_inter}\n";
				
				print F "sorted_delay_size=$#{$sample->{sorted_delay}}\n";
				for my $x (0..$#{$sample->{sorted_delay}}) {                                         
					print F "sorted_delay:$x:keys=$sample->{sorted_delay}->[$x]->{codes}->[0]->{char}::$sample->{sorted_delay}->[$x]->{codes}->[1]->{char}::$sample->{sorted_delay}->[$x]->{codes}->[2]->{char}\n";
					print F "sorted_delay:$x:codes=$sample->{sorted_delay}->[$x]->{codes}->[0]->{key},$sample->{sorted_delay}->[$x]->{codes}->[1]->{key},$sample->{sorted_delay}->[$x]->{codes}->[2]->{key}\n";
					print F "sorted_delay:$x:delay=$sample->{sorted_delay}->[$x]->{delay}\n";
					print F "sorted_delay:$x:inter=$sample->{sorted_delay}->[$x]->{inter}\n";
				}
										
				print F "sorted_inter_size=$#{$sample->{sorted_inter}}\n";
				for my $x (0..$#{$sample->{sorted_inter}}) {                                         
					print F "sorted_inter:$x:keys=$sample->{sorted_inter}->[$x]->{codes}->[0]->{char}::$sample->{sorted_inter}->[$x]->{codes}->[1]->{char}::$sample->{sorted_inter}->[$x]->{codes}->[2]->{char}\n";
					print F "sorted_inter:$x:codes=$sample->{sorted_inter}->[$x]->{codes}->[0]->{key},$sample->{sorted_inter}->[$x]->{codes}->[1]->{key},$sample->{sorted_inter}->[$x]->{codes}->[2]->{key}\n";
					print F "sorted_inter:$x:delay=$sample->{sorted_inter}->[$x]->{delay}\n";
					print F "sorted_inter:$x:inter=$sample->{sorted_inter}->[$x]->{inter}\n";
				}
			} else {
				print F "type=array\n";
				print F "index_size=$#{$sample}\n";
				for my $key (0..$#{$sample}) {
					print F "index$key=$sample->[$key]->{key}::$sample->[$key]->{delay}::$sample->[$key]->{inter}\n";
				}
			}
		}
		    
		close(F);
		return $self;
	}		
	
	sub load {
		my $self = shift;
		my $file = shift; 
		if(!(-f $file) && !$self->{silent}) {
			print "Error: File $file doesn't exist at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
			return undef;
		} 
		
		return $self if(!(-f $file) && $self->{silent});
		
		open(F, $file);
		my @lines = <F>;
		close(F);
		
		my $data = {};
		my $key;
	    for my $line (@lines) {
	    	chomp($line);
	    	my ($a,$b) = split /=/, $line;
	    	$key = $b if($a eq "_____KEY_____");
	    	$data->{$key}->{$a}=$b;
	    }
	    
	    my ($tmp,%db);
	    while(($key,$tmp) = each %{$data}) {
	    	%db = %{$tmp};
	    	if($db{type} eq "hash") {
				$self->{samples}->{$key} = {};
				$self->{samples}->{$key}->{size}=$db{size};
				$self->{samples}->{$key}->{avg_codes}=$db{avg_codex};
				$self->{samples}->{$key}->{avg_delay}=$db{avg_delay};
				$self->{samples}->{$key}->{avg_inter}=$db{avg_inter};
				
				for my $x (0..$db{sorted_delay_size}) {
					($self->{samples}->{$key}->{sorted_delay}->[$x]->{codes}->[0]->{char},$self->{samples}->{$key}->{sorted_delay}->[$x]->{codes}->[1]->{char},$self->{samples}->{$key}->{sorted_delay}->[$x]->{codes}->[2]->{char}) = 
						split /\:\:/, $db{"sorted_delay:$x:keys"};
					($self->{samples}->{$key}->{sorted_delay}->[$x]->{codes}->[0]->{key},$self->{samples}->{$key}->{sorted_delay}->[$x]->{codes}->[1]->{key},$self->{samples}->{$key}->{sorted_delay}->[$x]->{codes}->[2]->{key}) = 
						split /,/, $db{"sorted_delay:$x:codes"};
					$self->{samples}->{$key}->{sorted_delay}->[$x]->{delay}=$db{"sorted_delay:$x:delay"};
					$self->{samples}->{$key}->{sorted_delay}->[$x]->{inter}=$db{"sorted_delay:$x:inter"};
				}
										
				for my $x (0..$db{sorted_inter_size}) {
					($self->{samples}->{$key}->{sorted_inter}->[$x]->{codes}->[0]->{char},$self->{samples}->{$key}->{sorted_inter}->[$x]->{codes}->[1]->{char},$self->{samples}->{$key}->{sorted_inter}->[$x]->{codes}->[2]->{char}) = 
						split /\:\:/, $db{"sorted_inter:$x:keys"};
					($self->{samples}->{$key}->{sorted_inter}->[$x]->{codes}->[0]->{key},$self->{samples}->{$key}->{sorted_inter}->[$x]->{codes}->[1]->{key},$self->{samples}->{$key}->{sorted_inter}->[$x]->{codes}->[2]->{key}) = 
						split /,/, $db{"sorted_inter:$x:codes"};
					$self->{samples}->{$key}->{sorted_inter}->[$x]->{delay}=$db{"sorted_inter:$x:delay"};
					$self->{samples}->{$key}->{sorted_inter}->[$x]->{inter}=$db{"sorted_inter:$x:inter"};
				}
			} 
			elsif($db{type} eq "array") {
				$self->{samples}->{$key} = [];
				for my $x (0..$db{index_size}) {
					($self->{samples}->{$key}->[$x]->{key},$self->{samples}->{$key}->[$x]->{delay},$self->{samples}->{$key}->[$x]->{inter}) = 
						split /\:\:/, $db{"index$x"};
				}
			} else {
				print "Error: Invalid file type in file $file at @{[(caller)[1]]} line @{[(caller)[2]]}\n";
				return undef;
			}
		}
			
		return $self;
	}

1;		

__END__


=head1 NAME

Term::Sample - Finger printing of your keyboard typing

=head1 SYNOPSIS

	use Term::Sample qw(sample average analyze intr);
	use strict;
 	
	my $set = Term::Sample::Set->new();
	
	my $sample_string = 'green eggs and ham';
	
	if(!$set->load("test3.set")) {
		my @samples;
		print "Person: Person #1\n";
		
		my $top = 3;
		for (0..$top) {
			print "[ Sample $_ of $top ]  Please type \"$sample_string\": ";
		   	$samples[$_] = sample();
		}
		
	   	$set->store( 'Person #1' => average(@samples) );
	   	
	   	print "Person: Person #2\n";

		my $top = 3;
		for (0..$top) {
			print "[ Sample $_ of $top ]  Please type \"$sample_string\": ";
		   	
		   	# This has the same effect as saving all the samples in an array 
		   	# then calling store on the average() output, as shown above.
		   	
		   	$set->store( 'Person #2' => sample() );
		}
		
	   	$set->save("test3.set");
	}
   	
   	print "Now to test it out...\n";
   	print "[ Anybody ] Please type \"$sample_string\": ";
   	my $sample = sample();

	my ($key, $diff) = $set->match($sample);
   	
   	print "I am sure (about ",
   		  intr(100-$diff),
   		  "% sure) that your signiture matched the key `$key'.\n";
   	   	

=head1 DESCRIPTION

Term::Sample implements simple typing analysis to find the "personality" in your typing. It uses
Timer::HiRes and Win32::Console for best results. If it is not run on a Win32 system, it
defaults to Term::ReadKey instead of Win32::Console. I'm not sure how well it works with
ReadKey, as I have not had a chance to test it out yet. 

In this module we deal with three basic items: samples, analysis', and sets. Samples are what
you get from the sample() function and are raw keyboard data. Samples can be averaged
together to produce master samples, or analyzed to produce unique sample analysis'. Analysis'
are produced by alanlyze()-ing samples from sample() or samples averaged together(). You
can store samples (averaged or analyzed) and analysis' in sets according to unique, 
user-defined keys. You can then match new samples against the samples in the set and find
out which key it matched in the set, as well as the percentage of error.

This module uses Timer::HiRes to time both the key-press time (time between the key-down signal
and the key-up signal) and the key-interveal (time between key-up of previous key and key-down
of next key). This creates what I call a keyboard sample, or just a "sample." This is created
by a custom prompt function, sample() which returns an array ref. This is the raw keyboard
sample data. It can be averaged together with multiple sample to create a master sample
to be used as a signiture, or it can be individually saved with save(). Aditionally, you can
get a dump of the raw sample data with print_data($sample, type => 'basic') or 
print_data($sample, type => 'average'). 

This creates a unique 'print', or analysis from a sample, or samples averaged together with
analyze(). analyze() uses several factors to make the unique analysis. First, it calculates
average ASCII key codes, as well as the average total key-press and inter-key times. Then
it loops through the sample and picks out the fastest key-press times and inter-key times, 
and taking a three-key average around that high-point to create a sample highlight. It creats
highlights from every key in the sample, fastest to slowest, and then sorts the hightlights by 
key-press times and inter-key times, storing both lists in a final "analysis" object, along 
with the averaged times created at the start. This gives a final, hopefully unique, sample 
analysis.

Once you have gotten some master samples (I usually consider a master sample to be a single 
averaged sample of three to five samples of the same string, averaged with average(). see 
SYNOPSIS), you can store them in a Set. Included is a handy module for just that purpose.

Term::Sample::Set provides a way of managing master samples and matching test samples against
the master samples. After creating a new Term::Sample::Set object, you simply add samples
to it, stored by key, with the $set->store(key => $sample) method. You can then gather
additional unique samples to match against the samples contained in the set by calling
match($sample). match() returns a two-element list with the first element being the key that
it matched. The keys are provided by the user when calling store(). The second element is
the ammount of differenece between the sample passed to match() and the sample that is stored
at $key. Therefore you can get the percenentage of confidence in the match with intr(100-$diff).
(intr() is an optional export of Term::Sample). Additionally, sets can be saved and loaded with
save() and load(). It stores data in a simple flat text file, so the data should be fairly
portable.

Try saving the SYNOPSIS above in a file and running it (you can find a copy of it in the
'examples' directory in this distribution, 'synopsis.pl'). It should run fine right out of the 
POD (pun intended :-) as-is. Get another person to type for Person #1, and you type for Person #2. 
Then either of you type at the "Test it out" prompt and see who it matches against. It will 
display the  percentage of confidence in the match. It automatically stores the initial three 
samples from each person in a single set, so you can run the script again without having to 
re-type the initial samples.


=head1 EXPORTS

Term::Sample can be used with a blessed refrence from the new() constructor or via
exported functions. No functions are exported by default, but below are the OK ones
to import to your script.

	sample 
	average 
	save 
	load 
	analyze 
	diff 
	print_data 
	to_string
	p 
	intr 
	round 
	plus 
	new_Set
	new_set 
	
A simple "use Term::Sample qw(sample average load save analyze diff print_data p intr round plus new_Set)"
will get you all the functions in to your script.


=head1 METHODS for Term::Sample

=item new()

Package Constructor. Takes no arguments and returns a blessed refrence to an object
which contains all the methods that are optionally exported. Below is a description
of those methods in the order that they appear in the list above.

=item sample( option_name => options_value )

This produces a raw keyboard sample using Win32::Console and Timer::HiRes. 

Options Tags:
	echo => $echo_type
	newline => $newline_flag
	
$echo_type can be one of three values: 'key', 'none', or any character to echo. If 
the echo tag is not included, it defaults to 'key'. A 'key' value echos every key typed
to STDIO with a simple print call. A 'none' value does just that: It doesn't print anything.
Any other character passed in the echo tag is echoed in place of every character typed. Good
for using '*' in place of characters, that sort of thing.

$newline_flag is 1 by default, unless specified otherwise. If $newline_flag is 1, it prints
a newline character (\n) to STDOUT after finishing with the sample, otherwise printing nothing.

sample() returns an array ref to be used in other functions in this module. 
	
=item average(@samples)

=item average(@analysis);

=item average($sample1, $sample2, ... I<$sampleN>);

=item average($analysis1, $analysis2, ... I<$analysisN>);

This averages together samples with samples or analysis' with anlysis' and returns a single,
averaged sample or analysis, whichever was passed in to it. They can be passed via an array 
(not array ref), or via a variable-length argument list.


=item save($sample, $file);

=item save($analysis, $file);

save() saves a sample or analysis to disk under $file name. It uses a flat file format and
the respective type (sample or analysis) will be restored by load().


=item load($file);

Loads a sample or analysis from file $file. Returns a refrence to the respective type of the
file, containing the data in the file.

 
=item analyze($sample);

This simply creates a unique analysis from a sample, or samples averaged together with
analyze(). analyze() uses several factors to make the unique analysis. First, it calculates
average ASCII key codes, as well as the average total key-press and inter-key times. Then
it loops through the sample and picks out the fastest key-press times and inter-key times, 
and taking a three-key average around that high-point to create a sample highlight. It creats
highlights from every key in the sample, fastest to slowest, and then sorts the hightlights by 
key-press times and inter-key times, storing both lists in a final "analysis" object, along 
with the averaged times created at the start. This gives a final, hopefully unique, sample 
analysis.

This returns a hash refrence to an analysis data structure.

=item diff($sample1, $sample2 [, $v]);

=item diff($analysis2, $analysis2 [, $v]);
  
This compares the samples or analysis' and returns the percentage of difference between the
two samples as an integer 0 and 100.

$v is an optional parameter to turn on verbose difference summary. If $v is not included,
it defaults to 0, turing verbose off. If $v is 1, it includes a brief summary as it 
calculates. If $v is 2 it includes full verbose output.

  
=item print_data($sample, type => $type);

This prints a summary or the raw data of the sample, depending on $type. If $type = 'average',
it prints the average summary for the sample. If $type = 'basic', it prints out the complete,
raw sample data.


=item print_data($analysis, type => $type);

This prints a overview or the complete highlights of the $analysis, depending on $type.
If $type = 'overview', it will print out the averages for the analysis, as well as the first
two highlights for key-press and inter-key times. If $type = 'analysis' or $type = 'details',
it prints the complete hightlights list for both key-press and inter-ley times, as well as
the averages for the analysis. 

=item to_string($sample);

This extracts the characters typed from the raw timing data in $sample and returns it as
a scalar string.


=item p($a,$b);

Returns the difference of $a-$b as a percentage of $a.


=item intr($float);

Rounds a float to an integer and returns the integer.


=item round($float, $places);

Rounds a floating point number to $places after the decimal and returns the float.


=item plus($neg);

Makes a negative number positive. No effect on positive numbers. Returns the positive number.

=item new_set(tags);

=item new_Set(tags);

This is for those of us that are lazy and don't wan't to type ``$set = Term::Sample::Set->new(tags)''
It is simply an alias for the new() method of Term::Sample::Set, below.

I included one with set capitalized and one not. I think the capitalized Set would be more
propoer, as that is the package name, but I am sure nobody will remember to always capitalize
Set, so I made an alias for both. Aren't I nice? :-)


=head1 METHODS for Term::Sample::Set

=item new(tags)

Optional tags:

	type   => $type
	silent => $silent_flag

Creates and returns a blessed refrence to a Term::Sample::Set object. $type is optional.
If $type is included, it is expected to be either 'sample' or 'analysis'. If $type is not
included it defaults to 'sample.' $type tells the object what data it is expected to store
in the set, wether raw sample data or analysis data from analyze().

If $silent is not specified, it defaults to 0. If $silent_flag is true, then all the methods
of the set object will NOT return any errors. If it is 0 (default) then it will always print 
errors. 


=item $set->store( %keys )

Stores a hash of data in the set. Example:
	
	$set->store( 'Josiah's Sample' => $josiah,
			     'Larry's Sample'  => $larry,
			     'Joe's Sample'    => $joe );
			   
store() expects the key values ($josiah, $larry, and $joe) to be an array ref as returned
by sample() or an average() of samples, UNLESS the Set object was concstucted with the 
'analysis' parameter. In that case, it expeccts the key values to be a hash refrence 
as returned by analyze().

Additionally, if your attempt to store() to a key that already exists, then store() will
average the data you are trying to store with the data already in the Set, storing the final
average data back in the set at the same key.

Returns undef on errors, otherwise returns $set.


=item $set->remove($key);

Removes the key $key from the set. Returns undef on errors, otherwise
returns $set.

=iutem $set->get($key);

Returns data stored at $key. Returns undef on errors, otherwise
returns data stored at key.


=item $set->match($data [, $flag]);

match() expects $data to be an array ref as returned by sample() or an average() of samples, 
UNLESS the Set object was concstucted with the 'analysis' parameter. In that case, it expeccts 
the key values to be a hash refrence as returned by analyze().

match() returns a two-element list. The first element is the key that $data matched with
the least ammount of error. The second element is the percentage difference between $data
and the data in the key matched.

$flag is an optional paramater. If $flag is true, it will print out the percentage 
differences according to their keys to STDOUT. $flag defaults to false.

Returns undef on errors, otherwise returns $set.


See SYNOPSIS for example usage.

=item $set->save($file);

Save the entire data set, keys and all, in file $file. Flat file format is used. Returns 
undef on errors, otherwise returns $set.

 

=item $set->load($file)

Loads keys from file $file into the dataset. Note: It over writes any keys existing in the
dataset if there is a conflicting key found in the file. Returns undef on errors, otherwise
returns $set.


=head1 EXAMPLES
                 
This example helps you to create a master sample file, as for the sample password
checking example below. It prompts you for the file to store the sample in, and the
number of samples to take. I have found that the samples match better with longer
strongs. I.e. instead of a password of "sue goo", try "blue sue ate the green goo".
It also is a good idea to get around 5 - 10 samples. This allows it to average a good
sampling of your typing together to create one master sample. Be sure to use the
same string for each sample.

	# File   : examples/sample.pl
	# Author : Josiah Bryan, jdb@wcoil.com, 2000/9/16
	use Term::Sample qw(sample average load save print_data);
	
	print "\nSample Creation Script\n\n";
	print "Please enter a file to save the final sample in: ";
	chomp(my $file = <>);
	print "Number of samples to take: ";
	chomp(my $num = <>);
	
	my @samples;
	for my $x (1..$num) {
		print "[$x of $num] Enter sample string: ";
		$samples[++$#samples] = sample();
	}
	
	print "Combining and saving samples...";
	save(average(@samples), $file);
	
	print "Done!\n";
	
	__END__
                 

Here is a simple password checker. It assumes you have used the above sample maker to make
a password file called "password.sample" with the correct password in it. This will ask
the user for the password, with only an astrisk (*) as echo. It will first compare the
text the user types to see if the password match. If they do, then it analyzes the input
and the password sample and gets the difference between the two. It then converts the
difference to a confidence percentage (100-diff), and displays the result.

	# File   : examples/passwd.pl
	# Author : Josiah Bryan, jdb@wcoil.com, 2000/9/16
	use Term::Sample qw(sample analyze load intr to_string diff plus);
	
	my $password = load("password.sample");
	
	print "Enter password: ";
	my $input = sample( echo => '*' );
	
	my $diff;
	if(to_string($input) ne to_string($password)) {
		print "Error: Passwords don't match. Penalty of 100%\n";
		$diff = 100;
	}
		
	$diff = intr(100 - (diff(analyze($input), analyze($password))+$diff));
	                                                                    
	print "I am $diff% sure you are ",(($diff>50)?"real.":"a fake!"),"\n";

	__END__
		                                                                    

This is a simple set builder. It modifies the sample creation script to prompt you for
a key name and a Set file name. Then it goes thru the sample sampling process as before.
Only instead of averaging and storing in a file, it averages and stores in a set, then saves
the set to disk.

	# File   : examples/set.pl
	# Author : Josiah Bryan, jdb@wcoil.com, 2000/9/16
	use Term::Sample qw(sample average print_data new_Set);
	
	print "\nSet Creation Script\n\n";
	print "Please enter a file to save the final sample in: ";
	chomp(my $file = <>);
	print "Please enter a key for this sample in the set: ";
	chomp(my $key = <>);
	print "Number of samples to take: ";
	chomp(my $num = <>);
	
	my @samples;
	for my $x (1..$num) {
		print "[$x of $num] Enter sample string: ";
		$samples[++$#samples] = sample();
	}
	
	print "Combining and saving samples...";
	
	# Since most of the set methods return the blessed object, 
	# (except match()) you can chain methods together
	
	new_Set(silent=>1)
		->load($file)
		->store($key => average(@samples))
		->save($file);
	
	print "Done!\n";
	
	__END__


The same password example as the password script above. The difference is that this
one asks for a username and draws the password from a Set file. If a key by that
username doesnt exist in the Set file, it prints an error and exists. It then checks
the validity and analysis' of the two samples, and prints the results.

	# File   : examples/spasswd.pl
	# Author : Josiah Bryan, jdb@wcoil.com, 2000/9/16
	use Term::Sample qw(sample analyze intr to_string diff plus new_Set);
	
	my $set = new_Set(silent=>1);
	$set->load("password.set");
	
	print "Enter username: ";
	chomp(my $key = <>);
	
	my $password = $set->get($key);
	if(!$password) {
		print "Error: No user by name `$key' in database. Exiting.\n";
		exit -1;
	}
	
	print "Enter password: ";
	my $input = sample( echo => '*' );
	
	print "got:",to_string($input)," needed:",to_string($password),"\n";
	my $diff;
	if(to_string($input) ne to_string($password)) {
		print "Error: Passwords don't match. Penalty of 100%\n";
		$diff = 100;
	}
		
	$diff = intr(100 - (diff(analyze($input), analyze($password))+$diff));
	                                                                    
	print "I am $diff% sure you are ",(($diff>50)?"real.":"a fake!"),"\n";

	__END__

	

=head1 NOTE

I have not tested this on a non-Windows system. I am not sure how well this will work, 
as I did not see anything in Term::ReadKey docs about a facility for detecting
key-down and key-up. From what I see, it just returns the key on key-up. I have written
around this in the sample() function. Therefore if it detects a non-Win32 system, it will
NOT measure the key-press times, only the inter-key delay times. 

If someone knows of a way to do detect key up and key down with a more portable solution 
other than Win32::Console, PLEASE email me (jdb@wcoil.com) and let me know. Thankyou very
much.


=head1 SMALL DISCLAIMER

I make no claims to the accuracy or reliablility of this module. I simply started to write
it as a fun experiment after creating Term::Getch the other day. It seems to work with some
measure of accuracy with the testing I have done with several people here. I would greatly
appreciate it if any of you that use it would email me and let me know how well it works for
you. (jdb@wcoil.com) Thankyou very much!

=head1 BUGS

=item Speed

The sample() function seems to have problems with fast typers (like me) who like to hold
down one key and not release the first key before pressing the second. This seems to confuse
it with the key-up and key-down signals. I might be able to fix that with some kind of 
internal hash-table lookup or something, but for now I'll leave it be. I'll try to have
it fixed by the next version. If anyone fixes it by themselves, or gets part of it fixed, please
let me know so I don't reinvent any wheels that I don't really need to.

=item Other

This is a beta release of C<Term::Sample>, and that holding true, I am sure 
there are probably bugs in here which I just have not found yet. If you find bugs in this module, I would 
appreciate it greatly if you could report them to me at F<E<lt>jdb@wcoil.comE<gt>>,
or, even better, try to patch them yourself and figure out why the bug is being buggy, and
send me the patched code, again at F<E<lt>jdb@wcoil.comE<gt>>. 



=head1 AUTHOR

Josiah Bryan F<E<lt>jdb@wcoil.comE<gt>>

Copyright (c) 2000 Josiah Bryan. All rights reserved. This program is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself.

The C<Term::Sample> and related modules are free software. THEY COME WITHOUT WARRANTY OF ANY KIND.


=head1 DOWNLOAD

You can always download the latest copy of Term::Sample
from http://www.josiah.countystart.com/modules/get.pl?term-sample:pod


=cut