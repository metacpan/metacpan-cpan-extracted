package Silki::Role::CLI::HasOptionalProcess;
{
  $Silki::Role::CLI::HasOptionalProcess::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::Schema::Process;
use Silki::Types qw( Str );

use Moose::Role;
use Moose::Util::TypeConstraints;

requires qw( _run _final_result_string _print_success_message );

{
    subtype 'Process', as 'Silki::Schema::Process';
    coerce 'Process',
        from Str,
        via { Silki::Schema::Process->new( process_id => $_ ) };

    MooseX::Getopt::OptionTypeMap->add_option_type_to_map(
        'Process' => '=s' );

    has process => (
        is     => 'ro',
        isa    => 'Process',
        coerce => 1,
        documentation =>
            'A process id. If given, this process is updated instead of sending output to the console',
    );
}

sub run {
    my $self = shift;

    $self->process()->update(
        status     => 'Starting work',
        system_pid => $$,
    ) if $self->process();

    my @results = eval { $self->_run() };

    if ( my $e = $@ ) {
        $self->_handle_error($e);
    }
    else {
        $self->_handle_success(@results);
    }
}

sub _log_coderef {
    my $self = shift;

    if ( $self->process() ) {
        my $process = $self->process();

        return sub { $process->update( status => join '', @_ ) };
    }
    else {
        return sub { print q{  }, @_, "\n" };
    }
}

sub _handle_error {
    my $self  = shift;
    my $error = shift;

    if ( $self->process() ) {
        $self->process()->update(
            status      => "Error doing work: $error",
            is_complete => 1,
        );
    }
    else {
        die $error;
    }

    exit 1;
}

sub _handle_success {
    my $self = shift;

    if ( $self->process() ) {
        $self->process()->update(
            status         => 'Completed work',
            is_complete    => 1,
            was_successful => 1,
            final_result   => $self->_final_result_string(@_),
        );
    }
    else {
        $self->_print_success_message(@_);
    }

    exit 0;
}

if ( eval "use Getopt::Long::Descriptive; 1;"
    && Getopt::Long::Descriptive->VERSION < 0.087 ) {
    eval <<'EOF';
{
package
    Getopt::Long::Descriptive::Usage;
no warnings 'redefine';

sub option_text {
  my ($self) = @_;

  my @options  = @{ $self->{options} || [] };
  my $string   = q{};

  # a spec can grow up to 4 characters in usage output:
  # '-' on short option, ' ' between short and long, '--' on long
  my @specs = map { $_->{spec} } grep { $_->{desc} ne 'spacer' } @options;
  my $length   = (max(map { length } @specs) || 0) + 4;
  my $spec_fmt = "\t%-${length}s";

  while (@options) {
    my $opt  = shift @options;
    my $spec = $opt->{spec};
    my $desc = $opt->{desc};
    if ($desc eq 'spacer') {
      $string .= sprintf "$spec_fmt\n", $opt->{spec};
      next;
    }

    $spec = Getopt::Long::Descriptive->_strip_assignment($spec);
    $spec = join " ", reverse map { length > 1 ? "--$_" : "-$_" }
                              split /\|/, $spec;

    my @desc = $self->_split_description($length, $desc);

    $string .= sprintf "$spec_fmt  %s\n", $spec, shift @desc;
    for my $line (@desc) {
        $string .= "\t";
        $string .= q{ } x ( $length + 2 );
        $string .= "$line\n";
    }
  }

  return $string;
}

sub _split_description {
  my ($self, $length, $desc) = @_;

  # 8 for a tab, 2 for the space between option & desc;
  my $max_length = 78 - ( $length + 8 + 2 );

  return $desc if length $desc <= $max_length;

  my @lines;
  while (length $desc > $max_length) {
    my $idx = rindex( substr( $desc, 0, $max_length ), q{ }, );
    push @lines, substr($desc, 0, $idx);
    substr($desc, 0, $idx + 1) = q{};
  }
  push @lines, $desc;

  return @lines;
}
}
EOF
}

1;
