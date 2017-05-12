our $name     = 'Damian';
our $age      = 39;
our $ID       = '000666';
our $comments = <<'END_COMMENT';
Do not feed after midnight.
Do not expose to "stupid" ideas.
Do not allow subject to talk for "as long as he likes".
END_COMMENT

format STDOUT =
 ===================================
| NAME     |    AGE     | ID NUMBER |       
|----------+------------+-----------|       
| @<<<<<<< | @||||||||| | @>>>>>>>> |
  $name,     $age,        $ID,
|===================================|       
| COMMENTS                          |
|-----------------------------------|
| ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< |~~
  $comments,
 =================================== 
.

write STDOUT;
