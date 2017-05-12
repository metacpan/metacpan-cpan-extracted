package MobaSiF::Template::Compiler;

use 5.008;
use strict;
use FileHandle;
use constant {
	
	# タイプID
	
	TYPE_PLAIN   => 1,
	TYPE_REPLACE => 2,
	TYPE_LOOP    => 3,
	TYPE_IF      => 4,
	TYPE_ELSE    => 5,
	TYPE_QSA     => 6,
	TYPE_LB      => 253,
	TYPE_RB      => 254,
	TYPE_END     => 255,
	
	# オプション値
	
	O_ENCODE => 1, # url encode
	O_HSCHRS => 2, # htmlspecialchars
	O_NL2BR  => 4, # nl2br
	O_SUBSTR => 8, # substr
	
	# デリミタ
	
	DELIM_OR  => '\\|+',
	DELIM_AND => '\\&+',
	
	# 条件タイプ
	
	COND_EQ => 0,
	COND_NE => 1,
	COND_GT => 2,
	COND_GE => 3,
	COND_LT => 4,
	COND_LE => 5,
	
	# その他
	
	TRUE  => 1,
	FALSE => 0,
};

our $VERSION = '0.03';

#---------------------------------------------------------------------

sub loadTemplate {
	my ($in) = @_;
	
	my $tpl;
	if (ref($in)) {
		# ファイル名ではなくて文字列参照から生成する場合
		$tpl = ${$in};
	} else {
		my $fh = new FileHandle;
		open($fh, $in) || die "Can't find template $in\n";
		$tpl = join('', <$fh>);
		close($fh);
	}
	return _parseTemplate(\$tpl);
}

sub _parseTemplate {
	my ($rTpl) = @_;
	my $i;
	
	my @parts;
	my $pos = 0;
	
	# Vodafone 絵文字(SJIS)がテンプレに入っていると
	# 悪影響を与えるのでいったんエスケープ
	
	my $voda_esc1  = chr(0x1B).chr(0x24);
	my $voda_esc2  = chr(0x0F);
	my $voda_esc_q = quotemeta($voda_esc1). '(.*?)'. quotemeta($voda_esc2);
	
	${$rTpl} =~ s($voda_esc_q) {
		my $in = $1;
		$in =~ s/./unpack('H2',$&)/eg;
		('%%ESC%%'. $in. '%%/ESC%%');
	}eg;
	
	${$rTpl} =~ s(\t*\$(\s*([\=\{\}]|if|loop|/?qsa|.)[^\$]*)\$\t*|[^\$]+) {
		if (!(my $cmd = $1)) {
			
			#-----------------
			# PLAIN
			
			my $text = $&;
			$text =~ s(\%\%ESC\%\%(.*?)\%\%/ESC\%\%) {
				my $in = $1;
				$in =~ s/[a-f\d]{2}/pack("C", hex($&))/egi;
				($voda_esc1. $in. $voda_esc2);
			}eg;
			push(@parts, { type => TYPE_PLAIN, text => $text }); $pos++;
			
		} else {
			
			my $cmd_orig = $cmd;
			$cmd =~ s/\s+//g;
			
			#-----------------
			# REPLACE
			
			if ($cmd =~ /^\=((b|e|h|hn)\:)?/i) {
				my ($l, $o, $key) = ('', "$2", "$'");
				
				die "no replace type '$cmd_orig'\n" if ($o eq '');
				
				my $opt = 0;
				$opt = O_ENCODE            if ($o eq 'e');
				$opt = O_HSCHRS            if ($o eq 'h');
				$opt = O_HSCHRS | O_NL2BR  if ($o eq 'hn');
				
				push(@parts, { type => TYPE_REPLACE,
					key => $key, opt => $opt }); $pos++;
			}
			
			#-----------------
			# LOOP
			
			elsif ($cmd =~ /^loop\(([^\)]+)\)\{$/i) {
				my $key = $1;
				push(@parts, { type => TYPE_LOOP,
					key => $key, loopend => $pos + 1 }); $pos++;
				push(@parts, { type => TYPE_LB }); $pos++;
			}
			
			#-----------------
			# [ELS]IF -> [RB + ELSE +] IF + LB
			
			elsif ($cmd =~ /^(\}els)?if\(([^\)]+)\)\{$/i) {
				my $else = $1;
				my $cond = $2;
				my $delim = ($cond =~ /\|/) ? DELIM_OR : DELIM_AND;
				my @p = split($delim, $cond);
				my $ofs_next = scalar(@p);
				
				if ($else) {
					$ofs_next++;
					push(@parts, { type => TYPE_RB }); $pos++;
					push(@parts, { type => TYPE_ELSE,
						ontrue => $pos + 1, onfalse => $pos + $ofs_next });
					$pos++; $ofs_next--;
				}
				for my $p (@p) {
					if ($delim eq DELIM_AND) {
						push(@parts, { type => TYPE_IF,
							ontrue => $pos + 1, onfalse => $pos + $ofs_next,
							cond => $p });
					} else {
						push(@parts, { type => TYPE_IF,
							ontrue => $pos + $ofs_next, onfalse => $pos + 1,
							cond => $p });
					}
					$pos++; $ofs_next--;
				}
				push(@parts, { type => TYPE_LB }); $pos++;
			}
			
			#-----------------
			# ELSE -> RB + ELSE + LB
			
			elsif ($cmd =~ /^\}else\{$/i) {
				push(@parts, { type => TYPE_RB }); $pos++;
				push(@parts, { type => TYPE_ELSE,
					ontrue => $pos + 1, onfalse => $pos + 1 }); $pos++;
				push(@parts, { type => TYPE_LB }); $pos++;
			}
			
			#-----------------
			# RB
			
			elsif ($cmd =~ /^\}$/i) {
				push(@parts, { type => TYPE_RB }); $pos++;
			}
			
			#-----------------
			# QSA
			
			elsif ($cmd =~ /^(\/)?qsa$/i) {
				push(@parts, { type => TYPE_QSA, inout => $1 ? 1 : 0 }); $pos++;
			}
			
			#-----------------
			# ERROR
			
			else {
				die "Unknown command \$$cmd_orig\$\n";
			}
		}
	}egisx;
	push(@parts, { type => TYPE_END });
	
	if (${$rTpl} =~ /\$/) {
		die "unmatched '\$' found\n";
	}
	
	# 括弧の対応関係を設定
	
	$i = 0;
	my @stack;
	for my $raPart (@parts) {
		if ($raPart->{type} == TYPE_LB) {
			push(@stack, $i);
		}
		elsif ($raPart->{type} == TYPE_RB) {
			$parts[pop(@stack)]->{rbpos} = $i;
		}
		$i++;
	}
	
	# 各条件部の飛び先を正しく設定
	
	for my $raPart (@parts) {
		if ($raPart->{type} == TYPE_IF ||
		    $raPart->{type} == TYPE_ELSE) {
			if ($parts[$raPart->{onfalse}]->{type} == TYPE_LB) {
				$raPart->{onfalse} =
					$parts[$raPart->{onfalse}]->{rbpos};
			}
		} elsif ($raPart->{type} == TYPE_LOOP) {
			$raPart->{loopend} =
				$parts[$raPart->{loopend}]->{rbpos};
			$parts[$raPart->{loopend}]->{type} = TYPE_END;
		}
	}
	
	# 括弧の対応関係をチェック
	
	{
		my $lv = 1;
		for my $raPart (@parts) {
			if ($raPart->{type} == TYPE_LB) {
				$lv++;
			} elsif
				($raPart->{type} == TYPE_RB ||
			     $raPart->{type} == TYPE_END ) {
				$lv--;
				if ($lv < 0) {
					die "unmatched {}\n";
				}
			}
		}
		if ($lv != 0) {
			die "unmatched {}\n";
		}
	}
	
	# 条件部を生成
	
	for my $raPart (@parts) {
		if ($raPart->{type} == TYPE_IF) {
			my $cond_str = $raPart->{cond};
			if      ($cond_str =~ />(\=)?/) {
				my $val = int($');
				$raPart->{condkey} = $`;
				$raPart->{condval} = $val;
				$raPart->{condtyp} = $1 ? COND_GE : COND_GT;
			} elsif ($cond_str =~ /<(\=)?/) {
				my $val = int($');
				$raPart->{condkey} = $`;
				$raPart->{condval} = $val;
				$raPart->{condtyp} = $1 ? COND_LE : COND_LT;
			} elsif ($cond_str =~ /^\!/) {
				$raPart->{condkey} = $';
				$raPart->{condval} = '';
				$raPart->{condtyp} = COND_EQ;
			} elsif ($cond_str =~ /(\!)?==?/) {
				$raPart->{condkey} = $`;
				$raPart->{condval} = $';
				$raPart->{condtyp} = $1 ? COND_NE : COND_EQ;
			} else {
				$raPart->{condkey} = $cond_str;
				$raPart->{condval} = '';
				$raPart->{condtyp} = COND_NE;
			}
		}
	}
	
	return(\@parts);
}

#=====================================================================
#                       バイナリテンプレート生成
#=====================================================================

sub compile {
	my ($in, $out_file) = @_;
	
	my $raParts = loadTemplate($in);
	
	# 行オフセットの計算
	
	{
		my $ofs = 0;
		for my $raPart (@{$raParts}) {
			$raPart->{ofs} = $ofs;
			
			my $type = $raPart->{type};
			if    ( $type == TYPE_PLAIN   ) { $ofs += 8;  }
			elsif ( $type == TYPE_REPLACE ) { $ofs += 12; }
			elsif ( $type == TYPE_IF      ) { $ofs += 24; }
			elsif ( $type == TYPE_ELSE    ) { $ofs += 12; }
			elsif ( $type == TYPE_LOOP    ) { $ofs += 12; }
			elsif ( $type == TYPE_QSA     ) { $ofs += 8;  }
			elsif ( $type == TYPE_LB      ) { $ofs += 4;  }
			elsif ( $type == TYPE_RB      ) { $ofs += 4;  }
			elsif ( $type == TYPE_END     ) { $ofs += 4;  }
		}
	}
	
	# ジャンプ先参照位置の修正
	
	{
		for my $raPart (@{$raParts}) {
			my $type = $raPart->{type};
			if ($type == TYPE_LOOP) {
				$raPart->{loopend} = $raParts->[ $raPart->{loopend} ]->{ofs};
			}
			elsif ($type == TYPE_IF) {
				$raPart->{ontrue}  = $raParts->[ $raPart->{ontrue}  ]->{ofs};
				$raPart->{onfalse} = $raParts->[ $raPart->{onfalse} ]->{ofs};
			}
			elsif ($type == TYPE_ELSE) {
				$raPart->{ontrue}  = $raParts->[ $raPart->{ontrue}  ]->{ofs};
				$raPart->{onfalse} = $raParts->[ $raPart->{onfalse} ]->{ofs};
			}
		}
	}
	
	# 文字列参照バッファ位置の設定
	
	my $strBuf = "";
	my %strPos = ();
	for my $raPart (@{$raParts}) {
		my $type = $raPart->{type};
		if ($type == TYPE_PLAIN) {
			$raPart->{text} =
				useStringPos(\$strBuf, \%strPos, $raPart->{text});
		}
		elsif ($type == TYPE_REPLACE) {
			$raPart->{key} =
				useStringPos(\$strBuf, \%strPos, $raPart->{key});
		}
		elsif ($type == TYPE_IF) {
			$raPart->{condkey} =
				useStringPos(\$strBuf, \%strPos, $raPart->{condkey});
			if ($raPart->{condtyp} == COND_EQ ||
				$raPart->{condtyp} == COND_NE) {
				$raPart->{condval} =
					useStringPos(\$strBuf, \%strPos, $raPart->{condval});
			}
		}
		elsif ($type == TYPE_LOOP) {
			$raPart->{key} =
				useStringPos(\$strBuf, \%strPos, $raPart->{key});
		}
	}
	
	# 出力
	
	if ($out_file) {
		my $fh = new FileHandle;
		my $bin = makeBinTemplate($raParts, \$strBuf);
		open($fh, ">$out_file") || die "Can't open $out_file";
		print $fh $bin;
		close($fh);
	} else {
		debugBinTemplate($raParts, \$strBuf);
	}
}

sub useStringPos {
	my ($rStrBuf, $rhStrPos, $str) = @_;
	
	if (exists($rhStrPos->{$str})) {
		return($rhStrPos->{$str});
	}
	my $newPos = length(${$rStrBuf});
	$rhStrPos->{$str} = $newPos;
	${$rStrBuf} .= ($str. chr(0));
	return($newPos);
}

#-------------------------
# バイナリ化

sub makeBinTemplate {
	my ($raParts, $rStrBuf) = @_;
	my $bin = '';
	
	for my $raPart (@{$raParts}) {
		my $type = $raPart->{type};
		
		if ($type == TYPE_PLAIN) {
			$bin .= pack('LL', $type,
				$raPart->{text});
		}
		elsif ($type == TYPE_REPLACE) {
			$bin .= pack('LLL', $type,
				$raPart->{key},
				$raPart->{opt});
		}
		elsif ($type == TYPE_LOOP) {
			$bin .= pack('LLL', $type,
				$raPart->{key},
				$raPart->{loopend});
		}
		elsif ($type == TYPE_IF) {
			$bin .= pack('LLLLLL', $type,
				$raPart->{ontrue},
				$raPart->{onfalse},
				$raPart->{condkey},
				$raPart->{condval},
				$raPart->{condtyp});
		}
		elsif ($type == TYPE_ELSE) {
			$bin .= pack('LLL', $type,
				$raPart->{ontrue},
				$raPart->{onfalse});
		}
		elsif ($type == TYPE_QSA) {
			$bin .= pack('LL', $type, $raPart->{inout});
		}
		elsif ($type == TYPE_LB) {
			$bin .= pack('L', $type);
		}
		elsif ($type == TYPE_RB) {
			$bin .= pack('L', $type);
		}
		elsif ($type == TYPE_END) {
			$bin .= pack('L', $type);
		}
		else {
			die "unknown type ($type)\n";
		}
	}
	return(pack('L', length($bin)). $bin. ${$rStrBuf});
}

#-------------------------
# テンプレートの解析結果のデバッグ出力

sub debugBinTemplate {
	my ($raParts, $rStrBuf) = @_;
	
	print "     :{\n";
	for my $raPart (@{$raParts}) {
		my $type = $raPart->{type};
		
		printf("%5d:", $raPart->{ofs});
		
		if ($type == TYPE_PLAIN) {
			my $s = _debug_getString($rStrBuf, $raPart->{text});
			$s =~ s/\s+/ /g;
			print qq|"$s"|;
		}
		elsif ($type == TYPE_REPLACE) {
			my @opt;
			push(@opt, "e") if ($raPart->{opt} & O_ENCODE);
			push(@opt, "h") if ($raPart->{opt} & O_HSCHRS);
			push(@opt, "n") if ($raPart->{opt} & O_NL2BR);
			my $opt = scalar(@opt) ? join ('', @opt) : '';
			my $s = _debug_getString($rStrBuf, $raPart->{key});
			print qq|=$opt:$s|;
		}
		elsif ($type == TYPE_LOOP) {
			my $s = _debug_getString($rStrBuf, $raPart->{key});
			print qq|loop (\@$s) loopend L$raPart->{loopend}|;
		}
		elsif ($type == TYPE_IF) {
			my $cmp = '';
			$cmp = '==' if ($raPart->{condtyp} == COND_EQ);
			$cmp = '!=' if ($raPart->{condtyp} == COND_NE);
			$cmp = '>'  if ($raPart->{condtyp} == COND_GT);
			$cmp = '<'  if ($raPart->{condtyp} == COND_LT);
			$cmp = '>=' if ($raPart->{condtyp} == COND_GE);
			$cmp = '<=' if ($raPart->{condtyp} == COND_LE);
			my $s1 = _debug_getString($rStrBuf, $raPart->{condkey});
			my $s2 = $raPart->{condval};
			my $s2 =
				($raPart->{condtyp} == COND_EQ ||
				 $raPart->{condtyp} == COND_NE) ?
				 "'". _debug_getString($rStrBuf, $raPart->{condval}). "'" :
				 $raPart->{condval};
			print qq|if ( $s1 $cmp $s2 ) L$raPart->{ontrue} else L$raPart->{onfalse}|;
		}
		elsif ($type == TYPE_ELSE) {
			print qq|if ( PREV_COND_IS_FALSE ) L$raPart->{ontrue} else L$raPart->{onfalse}|;
		}
		elsif ($type == TYPE_LB) {
			print qq|{|;
		}
		elsif ($type == TYPE_RB) {
			print qq|}|;
		}
		elsif ($type == TYPE_END) {
			print qq|} END|;
		}
		print "\n";
	}
}
sub _debug_getString {
	my ($rStrBuf, $pos) = @_;
	my $str = substr(${$rStrBuf}, $pos);
	my $delim = chr(0);
	$str = $` if ($str =~ /$delim/);
	return($str);
}

#=====================================================================

1;

__END__

=encoding euc-jp

=head1 NAME

MobaSiF::Template::Compiler - Template compiler for MobaSiF::Template

=head1 SYNOPSIS

  use MobaSiF::Template::Compiler;
  MobaSiF::Template::Compiler::compile($in, $out_file);
  
=head1 DESCRIPTION

  MobaSiF::Template::Compiler::compile($in_file, $out_file);
  
    $in をコンパイルして $out_file にバイナリテンプレートを出力します。
    $out_file を指定しないと、デバッグ出力が表示されます。
    $in には、ファイル名か文字列への参照を渡すことができます。
  
=head1 テンプレートの書式

■ 置換コマンド

$={b|e|h|hn}:NAME$
  
  NAME が指すパラメータ値に置換します。
  以下のいずれかの変換方法を指定します。
  
  b:    無変換
  e:    url encode
  h:    htmlspecialchars
  hn:   htmlspecialchars + nl2br

■ ループコマンド

$ loop (NAME) { $ 〜 $ } $

  〜の部分を繰り返します。
  NAME はハッシュを参照する配列への参照を指します。

■ 条件コマンド

$ if (条件部) { $
$ } elsif (条件部) { $
$ } else { $
$ } $
  
  条件分岐を行います。ネストも可能です。
  条件部についての詳細は下記を参照。

=head2 条件部の書式

  NAME        : NAME が "",0,NULL 以外の場合に真となります。
 !NAME        : NAME が "",0,NULL     の場合に真となります。
  NAME==VALUE : NAME==VALUE の場合に真となります。
  NAME!=VALUE : NAME!=VALUE の場合に真となります。
  COND1 && COND2 && ... and : and 条件がつなげられます。
  COND1 || COND2 || ... or  : or  条件がつなげられます。
  
  制限：and, or を混在することはできません。

=head1 SEE ALSO

MobaSiF::Template

=cut
