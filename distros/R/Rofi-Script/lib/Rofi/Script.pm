package Rofi::Script;
use strict;
use warnings;
use v5.10;

use Carp qw( croak );
use Data::Printer;
use Env qw(
  $ROFI_RETV
  $ROFI_INFO
  $ROFI_SCRIPT_DEBUG
);

use base 'Exporter';
our @EXPORT = qw(
  rofi
);

use namespace::autoclean;

=head1 NAME

Rofi::Script - perl interface to the rofi menu

=head1 DESCRIPTION

rofi is a lightweight, extensible, scriptable, menu interface for Linux. It has
a scripting API documented in C<man rofi-script>. This module is a perl
interface to that API.

=head1 SYNOPSIS

  use Rofi::Script;

  if (rofi->is_initial_call) {
      rofi->set_prompt("Please select one")
          ->add_option("Show markup example");
  }

  SWITCH: for (rofi->shift_arg) {
      next unless $_;

      /markup/ && rofi
          ->set_prompt("markup")
          ->enable_markup_rows
          ->add_option(qq{<i>You can use pango for markup</i>});
  }

=cut

my $DELIM = "\n";

=head1 EXPORTED FUNCTIONS

=head2 rofi

  rofi
    ->set_prompt('Please choose')
    ->add_option("Foo")
    ->add_option("Bar");
  if rofi->is_initial_call;

  if (my $cmd = rofi->shift_arg) {
    $cmd =~ /foo/ && rofi
      ->set_prompt("foo")
      ->add_option("bar");
  }

  ...etc

This is a god object that's the primary interface to the entire script
interface. This object uses a fluid configuration style where you can chain
various methods and configuration options.

With the standard initialization, the object returned by C<rofi> will:

=over

=item

Parse args from C<@ARGV>

=item

Print output to STDOUT (this is how the rofi app actually displays things)

=back

=cut


our $rofi;
sub rofi () {
  return $rofi if $rofi;

  my $init_state = {
    args         => \@ARGV,
    output_rows  => [],
    mode_options => {},
    show_handle  => undef,
  };

  $rofi = bless($init_state, __PACKAGE__);

  return $rofi;
}

=head1 METHODS

=head2 get_args

Gets the arguments L</rofi> is aware of.

=cut

sub get_args {
  my ($self) = @_;
  return $self->{args};
}

=head2 set_args

Setter for the args L</rofi> cares about.

=cut

sub set_args {
  my ($self, @args) = @_;

  $self->{args} = \@args;

  return $self;
}

=head2 shift_arg

  my $cmd = rofi->shift_arg

Shift the leading arg from the args queue. This is how you would navigate your
way through the rofi's "call stack"

=cut

sub shift_arg {
  my ($self) = @_;

  my @args = @{$self->get_args};
  my $arg = shift @args;

  $self->set_args(@args);

  return $arg;
}

=head2 add_option

  rofi->add_option("Choice #1");

Add a row to rofi's output. If you select a row, it will cause your script to
be re-called, with the selected row pushed onto the args stack.

=cut

sub add_option {
  my ($self, $option, %mode_options) = @_;
  my $what;
  for (qw(urgent active)) {
    $mode_options{$_} = 'true' if $mode_options{$_};
  }

  if (%mode_options) {
    $what = [
      $option,
      \%mode_options,
    ];
  } else {
    $what = $option;
  }
  push @{$self->{output_rows}}, $what;

  return $self;
}

=head2 show

  rofi->show;

Renders the script output to whatever handle was set by L</set_show_handle>. By
default, this goes to STDOUT.

=cut

sub show {
  my ($self) = @_;

  $self->_print_global_mode_options;

  my @output_rows = @{$self->{output_rows}};
  for my $output_row (@output_rows) {
    $self->_print_row($output_row);
  }
}

=head2 set_show_handle

  my $str = '';
  open my $h, '>', $str;
  rofi->set_show_handle($h);

Set the handle that is printed to by L<show>.

=cut

sub set_show_handle {
  my ($self, $handle) = @_;

  $self->{show_handle} = $handle;

  return $self;
}

=head2 get_show_handle

  my $h = rofi->get_show_handle;
  close $h;

Return the output handle used by L</show>, set by L</set_show_handle>.

=cut

sub get_show_handle {
  my ($self) = @_;

  return $self->{show_handle};
}

=head2 is_initial_call

True if this is the first time the script is being called

=cut

sub is_initial_call         { $ROFI_RETV == 0 }

=head2 provided_entry_selected

The user selected a value from the list of provided entries

=cut

sub provided_entry_selected { $ROFI_RETV == 1 }

=head2 custom_entry_selected

User manually entered a value on the previous run

=cut

sub custom_entry_selected   { $ROFI_RETV == 2 }

=head2 set_prompt

  rofi->set_prompt("Please select a value");

Set the prompt on the rofi popup

=cut

sub set_prompt {
  my ($self, $prompt) = @_;
  croak "Need prompt" unless $prompt;
  $self->_set_mode_option(prompt => $prompt);

  return $self;
}

=head2 set_message

Set a message in the rofi box

=cut

sub set_message {
  my ($self, $message) = @_;
  croak "Need message" unless $message;
  $self->_set_mode_option(message => $message);

  return $self;
}

=head2 enable_markup_rows

Turn on pango markup for rows

=cut

sub enable_markup_rows {
  my ($self) = @_;

  $self->_set_mode_option(markup_rows => "true");

  return $self;
}

=head2 disable_markup_rows

Turn off pango markup for rows

=cut


sub disable_markup_rows {
  my ($self) = @_;

  $self->_set_mode_option(markup_rows => "false");

  return $self;
}

=head2 markup_rows_enabled

Query whether or not markup rows are enabled

=cut

sub markup_rows_enabled {
  my ($self) = @_;
  $self->_get_mode_option('markup_rows') eq 'true';
}

=head2 set_delim

Change the delimiter used to indicate new lines. This is C<\n> by default.
There's not really a need to mess with this. I'm not even sure it's implemented
100% correctly.

=cut

sub set_delim {
  my ($self, $delim) = @_;

  croak "Need delim" unless $delim;
  $DELIM = $delim;
  $self->_set_mode_option(delim => $delim);

  return $self;
}

=head2 set_no_custom

Call this to ignore any custom entries from the user

=cut

sub set_no_custom {
  my ($self, $set) = @_;

  croak "must be 'true' or 'false' (not $set)"
    unless grep { $set eq $_ } qw( true false );

  $self->_set_mode_option(no_custom => $set);

  return $self;
}

=head2 use_hot_keys

Something to do with custom keybinds from the user. This isn't implemented.
I haven't needed it yet.

=cut

sub use_hot_keys {
  my ($self, $set) = @_;
  croak "use_hot_keys not yet implemented";
}

sub _set_mode_option {
  my ($self, $option, $value) = @_;

  $option =~ s/_/-/g;

  $self->{mode_options}->{$option} = $value;
}

sub _get_mode_option {
  my ($self, $option) = @_;

  $option =~ s/_/-/g;

  return $self->{mode_options}->{$option};
}

sub _print {
  my ($self, $whatever) = @_;
  my $show_handle = $self->{show_handle} || *STDOUT;
  my $delim       = $self->{mode_options}->{delim} || "\n";
  print $show_handle $whatever.$delim;
}

sub _print_global_mode_options {
  my ($self) = @_;

  $DB::single = 1;

  my %global_mode_options = %{$self->{mode_options}};

  return unless %global_mode_options;

  for my $opt (keys %global_mode_options) {
    my $val = $global_mode_options{$opt};
    $self->_print(
      _render_option($opt => $val)
    );
  }
}

sub _print_row {
  my ($self, $row) = @_;

  if (ref $row eq 'ARRAY') {
    my $content = $row->[0];
    my %mode_options = %{$row->[1]};

    my @collected_mode_options;
    for (my ($opt, $val) = each %mode_options) {
      push @collected_mode_options, _render_option($opt => $val);
    }
    my $rendered_mode_options = join "\x1f", @collected_mode_options;

    $self->_print($content);
    $self->_print($rendered_mode_options);
  }

  elsif (not ref $row) {
    $self->_print($row);
  }

  else {
    croak "unsupported output row type: " . ref($row);
  }
}

sub _render_option {
  my ($option, $value) = @_;
  return "\x00$option\x1f$value";
}

=head2 debug

  rofi->debug

Dump the contents of the L</rofi> object to STDERR

=cut

sub debug {
  return unless $ROFI_SCRIPT_DEBUG;

  if (ref($_[0]) =~ /Rofi::Script/) {
    p $_[0];
  } else {
    p @_;
  }
}

1;
