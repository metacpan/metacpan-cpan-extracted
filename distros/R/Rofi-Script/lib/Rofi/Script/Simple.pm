package Rofi::Script::Simple;
use strict;
use warnings;

use parent 'Exporter';

sub option      ($&);
sub prompt      ($ );
sub end_options (  );

use Rofi::Script;

our @EXPORT = qw(
  end_options
  option
  prompt
);

my %actions = ();

sub prompt ($) {
  rofi->set_prompt(shift);
}

sub option ($&) {
  my ($name, $coderef) = @_;

  $actions{$name} = $coderef;
}

sub end_options () {
  if (rofi->is_initial_call) {
    rofi->add_option($_) for sort keys %actions;
    rofi->show;
  } else {
    my $action = rofi->shift_arg;
    my $coderef = $actions{$action};
    $coderef->();
  }
}

1;

__END__;

=head1 NAME

Rofi::Script::Simple - a simpler Rofi::Script

=head1 SYNOPSIS

  use Rofi::Script::Simple;

  prompt "make a choice";

  option foo => sub {
    # code that runs when someone selects 'foo'
  };

  option bar => sub {
    # code that runs when someone selects 'bar'
  };

  # displays foo and bar as rofi menu options
  end_options;

=head1 EXPORTED FUNCTIONS

=head2 end_options

Call this at the end of your script after you've defined all of the options.

=head2 option

  option foo => sub {
    ...;
  };

Quickly define a menu option and an action that runs when the option is
selected

=head2 prompt

Set the prompt text.

=cut
