package Rhetoric::Theme::BrownStone;
use common::sense;
use aliased 'Squatting::H';
use Squatting::View;
use Method::Signatures::Simple;

our $VERSION = '0.01';

our $view = Squatting::View->new(
  'BrownStone',
  _init => method($include_path) {
    $self->{tt} = Template->new({
      INCLUDE_PATH => $include_path,
      POST_CHOMP   => 1,
    });
  },
  layout => method($v, $content) {
    my $output;
    $v->{R}       = \&Rhetoric::Views::R;
    $v->{content} = $content;
    $self->{tt}->process('layout.html', $v, \$output);
    $output;
  },
  _ => method($v) {
    my $file = "$self->{template}.html";
    my $output;
    $v->{R} = \&Rhetoric::Views::R;
    my $r   = $self->{tt}->process($file, $v, \$output);
    warn $r unless ($r);
    $output;
  },
);

sub view { $view }

1;
