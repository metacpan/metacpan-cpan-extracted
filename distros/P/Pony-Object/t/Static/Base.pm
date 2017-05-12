package Static::Base;
use Pony::Object;
use Pony::Object::Throwable;
  
  public static 'type_list' => {
    bug => 1,
    feature => 2,
    improvement => 3,
    task => 4,
    subtask => 5,
    epic => 6,
  };
  protected 'type';
  
  sub set_type : Public
    {
      my $this = shift;
      my $type_name = shift;
      if (exists $this->type_list->{$type_name}) {
        $this->type = $this->type_list->{$type_name};
      } else {
        throw Pony::Object::Throwable('Wrong type');
      }
    }
  
  sub get_type : Public
    {
      my $this = shift;
      my @types = grep {$this->type_list->{$_} == $this->type} keys %{$this->type_list};
      return shift @types if @types;
      return undef;
    }
  
1;