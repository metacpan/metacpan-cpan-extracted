use strict;
use Test::More qw(no_plan);
use Shell::Parser;

my $parser = new Shell::Parser syntax => 'bash', 
    handlers => { default => \&push_token };

my @tests = (
    { # first, a very simple test
        script => 'echo "hello world"', 
        expected => [
            { type => 'builtin', token => 'echo' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => '"hello world"' }, 
        ]
    }, 
    
    { # now, something a little more complex
        script => qq{word="some text"\ncat file.txt | grep \$word}, 
        expected => [
            { type => 'assign', token => 'word="some text"' }, 
            { type => 'text', token => "\n" }, 
            { type => 'text', token => 'cat' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => 'file.txt' }, 
            { type => 'text', token => ' ' }, 
            { type => 'metachar', token => '|' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => 'grep' }, 
            { type => 'text', token => ' ' }, 
            { type => 'variable', token => '$word' }, 
        ]
    }, 
    
    { # now, a real script (although not very useful)
        script => <<'SCRIPT', 
#!/bin/sh
user="$1"
case "$user" in
  'root')
    echo "You are the BOFH."
    ;;
  *)
    if [ -f /etc/passwd ]; then 
        grep "$user" /etc/passwd | awk -F: '{print $5}'
    else
        echo "No /etc/passwd"
    fi
esac
SCRIPT
        expected => [
            { type => 'comment', token => '#!/bin/sh' }, 
            { type => 'text', token => "\n" }, 
            { type => 'assign', token => 'user="$1"' }, 
            { type => 'text', token => "\n" }, 
            { type => 'keyword', token => 'case' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => '"$user"' }, 
            { type => 'text', token => ' ' }, 
            { type => 'keyword', token => 'in' }, 
            { type => 'text', token => "\n" }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => q!'root'! }, 
            { type => 'metachar', token => ')' }, 
            { type => 'text', token => "\n" }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'builtin', token => 'echo' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => '"You are the BOFH."' }, 
            { type => 'text', token => "\n" }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'metachar', token => ';' }, 
            { type => 'metachar', token => ';' }, 
            { type => 'text', token => "\n" }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => '*' }, 
            { type => 'metachar', token => ')' }, 
            { type => 'text', token => "\n" }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'keyword', token => 'if' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => '[' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => '-f' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => '/etc/passwd' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ']' }, 
            { type => 'metachar', token => ';' }, 
            { type => 'text', token => ' ' }, 
            { type => 'keyword', token => 'then' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => "\n" }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => 'grep' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => '"$user"' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => '/etc/passwd' }, 
            { type => 'text', token => ' ' }, 
            { type => 'metachar', token => '|' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => 'awk' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => '-F:' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => q!'{print $5}'! }, 
            { type => 'text', token => "\n" }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'keyword', token => 'else' }, 
            { type => 'text', token => "\n" }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'builtin', token => 'echo' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => '"No /etc/passwd"' }, 
            { type => 'text', token => "\n" }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'text', token => ' ' }, 
            { type => 'keyword', token => 'fi' }, 
            { type => 'text', token => "\n" }, 
            { type => 'keyword', token => 'esac' }, 
            { type => 'text', token => "\n" }, 
        ]
    }, 
);

my @tokens = ();
my $i = 0;

sub push_token {
    push @tokens, { self => shift, @_ }
}

# run the tests
for my $test (@tests) {
    trace_parsing($test->{script}, $test->{expected})
}

sub trace_parsing {
    my $script = shift;
    my $expected = shift;
    
    # at init, @tokens is empty
    @tokens = ();
    $i = 0;
    is( scalar @tokens, 0 );

    # now parse some shell code
    eval { $parser->parse($script) };
    # then check @tokens
    ok( scalar @tokens > 0 );
    for my $token (@tokens) {
        is( $token->{self}, $parser );
        is( $token->{type}, $expected->[$i]{type} );
        is( $token->{token}, $expected->[$i]{token} );
        $i++;
        #print STDERR "token: ",join(', ', map { "$_=<$$token{$_}>" } keys %$token),"\n";
    }
}
