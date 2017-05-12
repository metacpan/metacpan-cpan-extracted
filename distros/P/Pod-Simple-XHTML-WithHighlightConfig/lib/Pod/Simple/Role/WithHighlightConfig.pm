package Pod::Simple::Role::WithHighlightConfig;
use Moo::Role;

sub BUILD {}

after BUILD => sub {
  $_[0]->accept_targets('highlighter');
};

has _highlight_config => (is => 'rw', init_arg => undef);
has _highlight_config_text => (is => 'rw', clearer => 1, predicate => 1, init_arg => undef);

our $_verbatim_sub;
around _handle_element_start => sub {
  my $orig = shift;
  my $self = shift;
  my ($element, $item) = @_;
  if ($element eq 'for' && $item->{target_matching} eq 'highlighter') {
    $self->_highlight_config({});
    $self->_highlight_config_text('');
  }
  elsif ($element eq 'Verbatim' && $self->_highlight_config) {
    local $_verbatim_sub = $orig;
    return $self->start_highlight($item, $self->_highlight_config);
  }
  else {
    $self->$orig(@_);
  }
};

around _handle_text => sub {
  my $orig = shift;
  my $self = shift;
  my ($text) = @_;
  if ($self->_has_highlight_config_text) {
    $self->_highlight_config_text($self->_highlight_config_text . $text);
  }
  else {
    $self->$orig(@_);
  }
};


around _handle_element_end => sub {
  my $orig = shift;
  my $self = shift;
  my ($element, $item) = @_;

  if ($element eq 'for' and $self->_has_highlight_config_text) {
    my $text = $self->_highlight_config_text;
    $self->_clear_highlight_config_text;
    s/^\s+//, s/\s+$// for $text;
    my $config = {};
    for my $config_item (map { [ split /=/, $_, 2 ] } split /\s+/, $text) {
      my ($key, $value) = @$config_item;
      if ($key =~ /^(?:start_line|highlight|line_numbers|language)$/) {
        if(!defined $value || !length $value) {
          $self->whine($item->{start_line}, "Invalid empty $key setting.")
        }
        elsif ($key eq 'start_line' && $value !~ /^\d+$/) {
          $self->whine($item->{start_line}, "Invalid non-number ($value) for $key setting.")
        }
        elsif ($key eq 'highlight' && $value !~ /^\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*$/) {
          $self->whine($item->{start_line}, "Invalid number sequence ($value) for $key setting.")
        }
        elsif ($key eq 'line_numbers' && $value !~ /^[01]$/) {
          $self->whine($item->{start_line}, "Invalid boolean ($value) for $key setting.")
        }
        else {
          $config->{$key} = $value;
        }
      }
      elsif (!defined $value) {
        $config->{language} = $key;
      }
      else {
        $self->whine($item->{start_line}, "Invalid setting \"$key\".")
      }
    }
    $self->_highlight_config($config);
  }
  else {
    $self->$orig(@_);
  }
};

sub start_highlight {
    my $self = shift;
    my $orig = $_verbatim_sub;
    my ($item, $config) = @_;
    $self->$orig(my $verb = 'Verbatim', $item, $config);
}


1;
__END__

