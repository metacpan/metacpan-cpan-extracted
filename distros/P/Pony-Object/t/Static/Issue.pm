package Static::Issue;
use Pony::Object qw/Static::Base/;
  
  protected 'title';
  protected 'description';
  protected static 'close_type_list' => {
    'closed' => 1,
    'resolved' => 2,
    'won\'t fix' => 3,
  };
  protected 'close_type';
  
  sub set_close_type : Public
    {
      my $this = shift;
      my $type_name = shift;
      if (exists $this->close_type_list->{$type_name}) {
        $this->close_type = $this->close_type_list->{$type_name};
      } else {
        throw Pony::Object::Throwable('Wrong type');
      }
    }
  
  sub get_close_type : Public
    {
      my $this = shift;
      my @types = grep {$_ == $this->close_type} @{$this->close_type_list};
      return shift @types if @types;
      return undef;
    }
  
  
1;