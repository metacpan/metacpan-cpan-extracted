package Static::Unstatic;
use Pony::Object qw/Static::Base/;
  
  public 'type_list' => {
    bug => 1,
    feature => 2,
    improvement => 3,
    task => 4,
    subtask => 5,
    epic => 6,
  };
  
1;