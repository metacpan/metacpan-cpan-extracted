package Object::HasMethod::Base;
use Pony::Object qw/:notry/;

my $level = 'info';
my $level_list = {
  debug => 00,
  info  => 20,
  warn  => 40,
  error => 60,
  fatal => 80,
};

# Generate log_* methods
for my $lvl (keys %$level_list) {
  has "log_$lvl" => sub {
    my $self = shift;
    my $content = shift;
    return if $level_list->{$lvl} < $level_list->{$level};
    $self->_write_log($content);
  };
}
  
  protected buffer => [];
  
  has _write_log => sub {
    my $this = shift;
    push @{$this->buffer}, @_;
    $this->__true_write_log() if @{$this->buffer} > 5;
  };
  
  has __true_write_log => sub {
    return "do nothing";
  };

1;