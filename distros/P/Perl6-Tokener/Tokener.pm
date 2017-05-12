package Perl6::Tokener;
use Text::Balanced qw(extract_quotelike);
my %keywords = map {$_=>1} (qw(
given when CATCH break try POST class
__FILE__ __LINE__ __PACKAGE__ __DATA__ __END__ AUTOLOAD BEGIN CORE 
DESTROY END INIT CHECK abs accept alarm and atan2 bind binmode bless 
caller chdir chmod chomp chop chown chr chroot close closedir cmp 
connect continue cos crypt dbmclose dbmopen defined delete die do 
each else elsif endgrent endhostent endnetent endprotoent endpwent 
endservent eof eq eval exec exists exit exp fcntl fileno flock for 
foreach fork format formline ge getc glob gmtime goto grep gt hex if 
index int ioctl join keys kill last lc lcfirst le length link listen 
local localtime lock log lstat lt m map mkdir my ne next no not oct 
open opendir or ord our pack package pipe pop pos print printf prototype 
push q qq qr quotemeta qw qx rand read readdir readline readlink readpipe 
recv redo ref rename require reset return reverse rewinddir rindex rmdir 
s scalar seek seekdir select shift sin sleep sort splice split sprintf 
sqrt srand stat study sub substr tell telldir tie tied time tr truncate 
uc ucfirst umask undef unless unlink unpack unshift untie until use 
values vec wait waitpid wantarray warn while write x xor y 
));

my %tokener = (
    '$'  => \&dollar,
    '@'  => \&at,
    '%'  => \&hash,
    '+'  => sub {operator(shift, type => "addop")}, 
    '+=' => sub {operator(shift, type => "assignop", length => 2)},
    '*'  => sub {operator(shift, type => "mulop")}, 
    '**' => sub {operator(shift, type => "powop",    length => 2)},
    '*=' => sub {operator(shift, type => "assignop", length => 2)},
    '-'  => sub {operator(shift, type => "addop")}, 
    '-=' => sub {operator(shift, type => "assignop", length => 2)},
    '++' => \&inc,
    '--' => \&dec,
    '/' => \&slash,

    '>=' => sub {operator(shift, type => "comparison", length => 2)},
    '>' => sub {operator(shift, type => "comparison")},
    '>>' => sub {operator(shift, type => "shiftop", length => 2)},

    '==' => sub {operator(shift, type => "comparison", length => 2)},
    '=>' => sub {operator(shift, type => "pair", length => 2)},
    '=~' => sub {operator(shift, type => "match", length => 2)},
    '=' => sub {operator(shift, type => "assignop") },
    '#' => \&comment,

    '<' => \&less_or_readln,
    '<=' => sub {operator(shift, type => "comparison", length => 2)},
    '<=>' => sub {operator(shift, type => "comparison", length => 3)},
    '<<' => \&shift_or_heredoc,

    ' '   => \&space, "\t" => \&space, "\n" => \&space, 
    ';'   => \&operator, 
    '.'   => \&dot,
    '..' => sub {operator(shift, type => "range", length => 2)},
    '...' => \&tripledot,
    ','   => \&operator, 
    '['   => \&operator,
    ']'  =>  \&term,
    '!'   =>  sub {operator(shift, type=> "unop") },
    '\\'   =>  sub {operator(shift, type=> "refgen") },
    '('  => sub {operator(shift, type=> "token", check => "no") },
    ')'  => sub {term(shift, check=>"no") },
    '{'  => sub {operator(shift, type=> "blockstart") },
    '}'  => sub {operator(shift, type=> "blockend", check => "no", state => "ANY") },
    #'{'  => \&block_or_subscript,
    #'}'  => \&end_curly,
    '_' => sub {operator(shift, type=>"addop")},
    '|' => sub {operator(shift, type=>"logop")},
    '||' => sub {operator(shift, length=>2, type=>"logop")},
    '||=' => sub {operator(shift, length=>3, type=>"assignop")},

    '^'  => \&hyper, 
    '"'  => \&quote, "'" => \&quote,
    '`'  => \&quote, # Of sorts

);

$tokener{$_} = \&number for 0 .. 9;
$tokener{$_} = \&bareword for "a".."z","A".."Z", "_";

$tokener{"-$_"} = \&filetest
    for split //, "rwxoRWXOezsfdlpSugkbctTBMAC";

my %keyword_tokens = ( 
    '__FILE__' => sub {$_[0]->{type}="constant"; $_[0]->{token}=$_[0]->file },
    '__LINE__' => sub {$_[0]->{type}="constant"; $_[0]->{token}=$_[0]->{line} },
    '__PACKAGE__' => sub {$_[0]->{type}="constant"; $_[0]->{token}=$_[0]->{package} },
    'AUTOLOAD' => \&block_or_sub,
    'BEGIN' => \&block_or_sub,
    'CATCH' => \&block_or_sub,
    'CHECK' => \&block_or_sub,
    'DESTROY' => \&block_or_sub,
    'END' => \&block_or_sub,
    'INIT' => \&block_or_sub,
    'POST' => \&block_or_sub,
    # I don't care about CORE:: any more. Do you?
    'abs' => \&uni,
    'alarm' => \&uni,
    'and' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="andop" },
    'atan2' => \&uni,
    'binmode' => \&lop,
    'bless' => \&lop,
    'chop' => \&uni,
    'continue' => \&preblock,
    'chdir' => \&uni,
    'close' => \&uni,
    'closedir' => \&uni,
    'cmp' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="comparison" },
    'caller' => \&uni,
    'crypt' => \&lop,
    'chmod' => \&lop,
    'chown' => \&lop,
    'class' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="operator" }, #also need to set $t->{package}
    'connect' => \&lop,
    'chr' => \&uni,
    'cos' => \&uni,
    'die' => \&lop,
    'defined' => \&uni,
    'delete' => \&uni,
    'else' => \&preblock,
    'elsif' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="operator" },
    'eq' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="comparison" },
    'eval' => \&preblock, # A Perl 6ism.
    'exists' => \&uni,
    'exit' => \&uni,
    'eof' => \&uni,
    'exp' => \&uni,
    'each' => \&uni,
    'exec' => \&lop,
    'fcntl' => \&lop,
    'fileno' => \&uni,
    'flock' => \&lop,
    #'for' => \&do_for,     # This is going to suck
    #'foreach' => \&do_for, # really quite nastily
    'fork' => sub { my $t=shift; $t->{type}="func0" },
    'ge' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="comparison" },
    'getc' => \&uni,
    'given' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="operator" },
    'glob' => \&lop,
    'gmtime' => \&uni,
    'goto' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="loopx"; $t->{next}->{type} = "bareword" },
    'grep' => sub { lop(shift, "REF") },
    'gt' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="comparison" },
    'hex' => \&uni,
    'if' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="operator" },
    'index' => \&lop,
    'int' => \&uni,
    'ioctl' => \&lop,
    'join' => \&lop,
    'keys' => \&uni,
    'kill' => \&lop,
    'last' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="loopx"; $t->{next}->{type} = "bareword" },
    'lc' => \&uni,
    'lcfirst' => \&uni,
    'le' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="comparison" },
    'length' => \&uni,
    'local' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="operator" },
    'localtime' => \&uni,
    'log' => \&uni,
    'link' => \&lop,
    'listen' => \&lop,
    'lock' => \&uni,
    'lstat' => \&uni,
    'lt' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="comparison" },
    'map' => sub { lop(shift, "REF") },
    'mkdir' => \&lop,
    'my' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="operator" },
    'ne' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="comparison" },
    'next' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="loopx"; $t->{next}->{type} = "bareword" },
    #'no' => \&use_no,
    #'not' => \&do_not,
    'open' => \&lop,
    'or' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="operator" },
    'ord' => \&uni,
    'oct' => \&uni,
    'open' => \&lop,
    'opendir' => \&lop,
    'our' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="operator" },
    'package' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="operator" }, #also need to set $t->{package}
    'print' => sub { lop(shift, "REF") },
    'printf' => sub { lop(shift, "REF") },
    'prototype' => \&uni,
    'push' => \&lop,
    'pop' => \&uni,
    'pos' => \&uni,
    'pack' => \&lop,
    'pipe_op' => \&lop,
    'quotemeta' => \&uni,
    'redo' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="loopx"; $t->{next}->{type} = "bareword" },
    'return' => \&lop, # XXX
    'require' => \&uni,
    'reset' => \&uni,
    'rename' => \&lop,
    'rand' => \&uni,
    'rmdir' => \&uni,
    'rindex' => \&lop,
    'read' => \&lop,
    'readdir' => \&uni,
    'readline' => \&uni,
    'rewinddir' => \&uni,
    'recv' => \&lop,
    'reverse' => \&lop,
    'readlink' => \&uni,
    'ref' => \&uni,
    'chomp' => \&uni,
    'scalar' => \&uni,
    'select' => \&lop,
    'seek' => \&lop,
    'shift' => \&uni,
    'sin' => \&uni,
    'sleep' => \&uni,
    'socket' => \&lop,
    'sort' => sub { lop(shift, "REF") },
    'split' => \&lop,
    'sprintf' => \&lop,
    'splice' => \&lop,
    'sqrt' => \&uni,
    'srand' => \&uni,
    'stat' => \&uni,
    'study' => \&uni,
    #'sub' => \&do_sub,
    'substr' => \&lop,
    'system' => \&lop,
    'symlink' => \&lop,
    'syscall' => \&lop,
    'sysopen' => \&lop,
    'sysseek' => \&lop,
    'sysread' => \&lop,
    'syswrite' => \&lop,
    'tell' => \&uni,
    'telldir' => \&uni,
    'tie' => \&lop,
    'tied' => \&uni,
    'time' => sub { my $t=shift; $t->{type}="func0" },
    'truncate' => \&lop,
    'uc' => \&uni,
    'ucfirst' => \&uni,
    'untie' => \&uni,
    'until' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="operator" },
    'unless' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="operator" },
    'unlink' => \&lop,
    'undef' => \&uni,
    'unpack' => \&lop,
    'utime' => \&lop,
    'umask' => \&uni,
    'unshift' => \&lop,
    #'use' => \&use_no,
    'values' => \&uni,
    'vec' => \&lop,
    'warn' => \&lop,
    'wait' => sub { my $t=shift; $t->{type}="func0" },
    'waitpid' => \&lop,
    'when' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="operator" },
    'while' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="operator" },
    'write' => \&uni,
    'x' => \&do_repeat,
    'xor' => sub { my $t=shift; $t->{state}="TERM"; $t->{type}="operator" },
);

$Perl6::Tokener::VERSION = '0.01';

=head1 NAME

Perl6::Tokener - It's a Perl 6 tokener. It tokenises Perl 6.

=head1 SYNOPSIS

    use Perl6::Tokener;
    my $t = new Perl6::Tokener(file=>"foo.pl", buffer => $code);
    while ($t->{buffer}) {
        my ($type, $token) = $t->toke();
        ...
    }

=head1 DESCRIPTION

I don't think there's really much I need to say about this. It isn't
perfect, but I'm working on it. The synopsis pretty much gives you all
you need to know to drive the thing, and, bluntly, if you're futzing
with tokenising Perl 6, you're already beyond the need for most kinds of
documentation. So have fun.

Oh, one thing - when you're parsing, you probably want to discard the
type of everything called C<operator> or C<term> and just use the token
value. Oh, and white space will return C<undef> for token and type, so
don't try using this in a C<while> loop.

=head1 BUGS

=over 3

=item *

C<{> doesn't do what it ought. This is going to suck.

=item *

Some of the important keyword subs aren't implemented.

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=cut

sub new {
    my $class = shift;
    my $t = bless {
        state  => "STATE",
        line   => 1,
        char   => 1,
        @_
    }, $class;
    return $class;

}

sub toke {
    my $t = shift;
    my $thistoke = { line => $t->{line}, char => $t->{char} };
    if (not $t->prime()) { 
        for (sort { length $b <=> length $a } keys %tokener) {
            if ($t->{buffer} =~ /^\Q$_/) {
                #print "Matched |$_|\n";
                $tokener{$_}->($t);
                goto done;
            }
        }
        die "Can't find a callback for \"$t->{buffer}\"\n";
    }
    done:
    die $t->{error} if $t->{error};
    if ($t->{hyper}) {
        $t->{token} = "^".$t->{token};
    }
    return ($t->{type}, $t->{token}); # Convenience
}
# Utility functions

sub prime { 
    my $t = shift;
    $t->{hyper} = $t->{next}->{hyper};
    $t->{state} = $t->{next}->{state} if $t->{next}->{state};
    if ($t->{next}->{type} and $t->{next}->{token}) {
        $t->{type} = $t->{next}->{type};
        $t->{token} = $t->{next}->{token};
        delete $t->{next};
        return 1;
    }
    delete $t->{next};
    return 0;
}

sub no_op { return "$_[0] found where operator expected" }
sub not_op { return "$_[0] found where term expected" }

sub read_ident {
    $_[0] =~ s/^\s+//;
    $_[0] =~ s/^(\d+)// and return $1;
    $_[0] =~ s/^((\w+|::)+)// and return $1;
    $_[0] =~ s/^([\$@%](\w+|::)+)// and return $1;
    $_[0] =~ s/^(\$)$// and return $1;
    $_[0] =~ s/^(\$[?!\$])// and return $1;
    die "tricky identifier encountered: $_[0]";
}


# Individual characters

sub dollar {
    my ($t) = shift;
    my $first = substr($t->{buffer}, 1, 1);
    if ($t->{state} eq "OPERATOR") {
        $t->{error} = no_op('$');
        return;
    }
    if ($first eq "#") {
        $t->{buffer} =~ s/../@/;
        my $ident = read_ident($t->{buffer});
        $_[0] = $buffer;
        $t->{type} = "term";
        $t->{token} = "\$#$ident";
        $t->{char}+= length $t->{token};
        $t->{state} = "OPERATOR";
        return ;
    }
    my $ident = read_ident($t->{buffer});
    if (length $ident ==1) {
        $t->{error} = 'Final $ should be \\$ or $name' if not $t->{buffer};
        $t->{type}  = "preref";
        $t->{token} = '$';
        $t->{char}+= length $t->{token};
        $t->{state} = "REF";
        return;
    } 
    $t->{type} = "term";
    $t->{token} = $ident;
    $t->{char}+= length $t->{token};
    $t->{state} = "OPERATOR";
}

sub hash {
    my $t = shift;
    if ($t->{state} eq "OPERATOR") {
        operator($t, type=>"mulop");
        return
    }
    $t->{token} = read_ident($t->{buffer});
    $t->{type} = "term";
    $t->{char}+= length $t->{token};
    $t->{state} = "OPERATOR";

}


sub at {
    my $t = shift;
    $t->{token} = read_ident($t->{buffer});
    $t->{type} = "term";
    $t->{char}+= length $t->{token};
    $t->{state} = "OPERATOR";
}

sub space { 
    my $t = shift;
    $t->{char}=1, $t->{line}++ if $t->{buffer}=~ s/^\n//; 
    $t->{buffer} =~ s/^([\t ]+)//s;  $t->{char} += length $1;
    delete $t->{type}; delete $t->{token};
}

sub inc {
    my $t = shift;
    $t->{buffer} =~ s/..//;
    $t->{char}+=2;
    $t->{token}="++";
    $t->{type}  = $t->{state} eq "OPERATOR" ? "postinc" : "preinc";
}

sub dec {
    my $t = shift;
    $t->{buffer} =~ s/..//;
    $t->{char}+=2;
    $t->{token}="--";
    $t->{type}  = $t->{state} eq "OPERATOR" ? "postdec" : "predec";
}

sub operator  { 
    my $t = shift;
    my %options = @_;
    if ($t->{state} eq "TERM" and not $options{check} eq "no") {
        $t->{error} = not_op($options{token} || "operator");
        return;
    }
    $options{length} = 1 if not defined $options{length};
    my $was = substr($t->{buffer},0,$options{length},"");
    $t->{char} += $options{length};
    $t->{token} = $options{token} || $was;
    $t->{type}  = $options{type} || "operator";
    $t->{state} = $options{state} || "TERM";
}      

sub term { 
    my $t = shift;
    my %options = @_;
    if ($t->{state} eq "OPERATOR" and not $options{check} eq "no") {
        $t->{error} = no_op($options{token} || "term");
        return;
    }
    $options{length} = 1 if not defined $options{length};
    my $was = substr($t->{buffer},0,$options{length},"");
    $t->{char} += $options{length};
    $t->{token} = $options{token} || $was;
    $t->{type}  = $options{type} || "term";
    $t->{state} = $options{state} || "OPERATOR";
}

sub number {
    $t = shift;
    $t->{buffer} =~ s/^
        (
            0x[0-9A-Fa-f](_?[0-9A-Fa-f])*
          | 0[0-7](_?[0-7])* 
          | 0b[01](_?[01])*
          | \.\d(_?\d)*[Ee][\+\-]?(\d(_?\d)*) 
          | \d(_?\d)*(\.(\d(_?\d)*)?)?[Ee][\+\-]?(\d(_?\d)*)
          | [\d_]+(\.[\d_]+)?
        )//x or die "Didn't match $t->{buffer}!";
    $t->{type} = "const", 
    $t->{char} += length $1;
    $t->{token} = eval $1;
    $t->{state} = "OPERATOR";
}

sub bareword { 
    $t = shift;
    $t->{buffer} =~ s/^(\w+)//;
    my $what = $1;
    $t->{token} = $what;
    if ($t->{token} =~ /^(s|tr|y|m|qr)$/) { 
        ($t->{token}, $t->{buffer}) = extract_quotelike($t->{token}.$t->{buffer});
        $t->{type} = "regex";
        $t->{state} = "OPERATOR";
        $t->{char}+= length $t->{token}; # XXX NEWLINES.
        return;
    }
    if ($t->{token} =~ /^(q|qq|qw|qx)$/) {
        ($t->{token}, $t->{buffer}) = extract_quotelike($t->{token}.$t->{buffer});
        $t->{type} = "const";
        $t->{state} = "OPERATOR";
        $t->{char}+= length $t->{token}; # XXX NEWLINES.
        return;
    }

    $t->{char} += length $what;
    if ($t->{buffer} =~ s/^((::\w+)+)//) {
        $t->{token} .= $1;
        $t->{type} = "class";
    } elsif ($t->{buffer} =~ s/^://) {
        $t->{type} = "label";
    } elsif ($t->{buffer} =~ /^\s*=>/) {
        $t->{type} = "const";
    } elsif (exists $keywords{$what}) {
        $t->{type} = "key_$what";
        $keyword_tokens{$t->{token}}->($t) 
            if exists $keyword_tokens{$t->{token}};
    } elsif ($t->{buffer} =~ /^\s*\(/) {
        # It's a subroutine, so fake up a subroutine call
        $t->{next}->{token} = $t->{token};
        $t->{next}->{type} = "bareword";
        $t->{token} = "&";
        $t->{type} = "token";
    } else {
        $t->{type} = "bareword";
    }
    $t->{state} = "ANY"; # Hack
}

sub hyper { 
    $t=shift;
    $t->{buffer} =~ s/.//;
    if ($t->{state} ne "OPERATOR") {
        $t->{error} = no_op("hyperoperation");
        return;
    }
    if ($t->{hyper}) { 
        $t->{error} = "Can't multiply hyperoperate";
        return;
    }
    $t->{next}->{hyper}=1;
}

sub quote {
    $t = shift;
    # Cheat
    ($t->{token}, $t->{buffer}) = extract_quotelike($t->{buffer});
    $t->{type} = "const";
    for (split //, $t->{token}) {
        $t->{char}++;
        $t->{line}++, $t->{char} = 1  if $_ eq "\n";
    }
    $t->{state} = "OPERATOR";
}

sub comment {
    $t = shift;
    $t->{buffer} =~ s/.*//;
    $t->{line}++; $t->{char}=1;
} 

sub slash {
    my $t= shift;
    if ($t->{state} eq "OPERATOR") { 
        return operator($t, type =>"mulop");
    }
    ($t->{token}, $t->{buffer}) = extract_quotelike($t->{buffer});
    $t->{type} = "regex";
    $t->{state} = "OPERATOR";
}

sub tripledot {
    my $t = shift;
    if ($t->{state} eq "OPERATOR") {
        return operator($t, type=>"range", length => 3);
    } else {
        return operator($t, type=>"notyet", check=> "no", state=>"ANY", length => 3);
    }
}

sub dot {
    my $t = shift;
    if ($t->{state} eq "OPERATOR") {
        return operator($t, type=>"method");
    } else {
        # Dirty hack
        $t->{buffer} = '$_'. $t->{buffer};
        $t->{char} -= 2;
        delete $t->{token}; delete $t->{type};
    }
}

sub filetest {
    my $t = shift;
    if ($t->{buffer}=~/-\w\w+/) {
        # I'm not really a filetest
        return operator($t, type=>"addop"); # Just return the -, try again
    }
    return operator($t, type=>"filetest", length=>2, check=>"no");
}

# Keywords, and what we do with them

sub block_or_sub {
    my $t= shift;
    if ($t->{state} eq "STATE") { # XXX
        do_sub($t);
    } else {
        $t->{type}="bareword";
    }
}

sub uni {
    my $t = shift;
    $t->{state} = "TERM";
    if ($t->{buffer}=~/^s*\(/) {
        $t->{type} = "func1";
    } else {
        $t->{type} = "unop";
    }
}

sub lop {
    my $t = shift;
    $t->{state} = "TERM";
    if ($t->{next}->{type}) {
        $t->{type} = "listop";
    } elsif ($t->{buffer}=~/^s*\(/) {
        $t->{type} = "func";
    } else {
        $t->{type} = "listop";
    }
}

__END__

