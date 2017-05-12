use Perl6::Form;

my $name = 'Damian';
my $age = 39;
my $ID = '000666';
my $comments = <<'END_COMMENT';
Do not feed after midnight.
Do not expose to "stupid" ideas.
Do not allow subject to talk for "as long as he likes".
END_COMMENT

print form 
    ' =================================== ',
    '| NAME     |    AGE     | ID NUMBER |',
    '|----------+------------+-----------|',
    '| {<<<<<<} | {||||||||} | {>>>>>>>} |',
       $name,     $age,        $ID,
    '|===================================|',
    '| COMMENTS                          |',
    '|-----------------------------------|',
    '| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |',
       $comments,
    ' =================================== ',
;

