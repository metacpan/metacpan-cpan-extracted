
use strict;
use warnings;

package Paludis::UseCleaner::App;
BEGIN {
  $Paludis::UseCleaner::App::VERSION = '0.01000307';
}

# ABSTRACT: Command Line App Interface to Paludis::UseCleaner


use Getopt::Lucid qw( :all );

sub _gen_spec {
  return (
    Param(
      "conf|c",
      sub {
        return 1 if $_ eq q{-};
        return 1 if -e $_ && -f $_;
        return;
      }
      )->default("/etc/paludis/use.conf"),
    Param("output|o")->default("/tmp/use.conf.out"),
    Param("rejects|r")->default("/tmp/use.conf.rej"),
    Switch("clobber-output|x")->default(1),
    Switch("clobber-rejects|y")->default(1),
    Switch("quiet|q")->default(1),
    Switch("silent|s")->default(0),
    Switch("help|h")->anycase(),
  );
}

sub _help {
  my @spec = @_;
  my %doc  = (
    'conf'           => {},
    'output'         => {},
    'rejects'        => {},
    'clobber-output' => {},
    'quiet'          => {},
    'silent'         => {},
    'help'           => {},
  );

  for my $rule (@spec) {
    my $name     = $rule->{canon};
    my $doc      = $doc{$name};
    my @switches = split /\|/, $rule->{name};
    for (@switches) {
      if ( ( length $_ ) < 2 ) {
        $_ =~ s/^/-/;
      }
      else {
        $_ =~ s/^/--/;
      }
    }
    @switches = sort { ( length $a ) <=> ( length $b ) } @switches;
    ## no critic(ProhibitComplexMappings)
    if ( $rule->{type} eq 'parameter' ) {
      @switches = map { ( "$_ \$x", "$_=\$x" ) } @switches;
    }
    elsif ( $rule->{type} eq 'switch' ) {
      @switches = map {
        my $i = $_;
        my $j = $i;
        $j =~ s/^--/--no-/;
        ( $j eq $i ) ? $i : ( $i, $j );
      } @switches;
    }
    printf qq{%-50s => %s \n}, ( join q{ }, @switches ), ( defined $rule->{default} ? $rule->{default} : 'undef' );

  }
  return;
}

sub _read_fd {
  my $source = shift;
  ## no critic ( ProhibitPunctuationVars )
  open my $fh, '<', $source or die "Cant open $source $@ $? $!\n";
  return $fh;
}

sub _write_fd {
  my $source = shift;
  ## no critic ( ProhibitPunctuationVars )
  open my $fh, '>', $source or die "Cant open $source $@ $? $!\n";
  return $fh;
}

sub _silent_args {
  return (
    show_skip_empty => 0,
    show_skip_star  => 0,
    show_dot_trace  => 0,
    show_clean      => 0,
    show_rules      => 0,
  );
}

sub _quiet_args {
  return (
    show_skip_empty => 0,
    show_skip_star  => 0,
    show_dot_trace  => 1,
    show_clean      => 0,
    show_rules      => 0,
  );

}

sub _noisy_args {
  return (
    show_skip_empty => 1,
    show_skip_star  => 1,
    show_dot_trace  => 0,
    show_clean      => 1,
    show_rules      => 1,
  );

}

sub run {
  my @spec = _gen_spec();

  my $got = Getopt::Lucid->getopt( \@spec );
  if ( $got->get_help ) {
    _help(@spec);
    exit;

  }

  my %flags = ();

  if ( $got->get_conf eq q{-} ) {
    $flags{input} = \*STDIN;
  }
  else {
    $flags{input} = _read_fd( $got->get_conf );
  }

  if ( $got->get_output eq q{-} ) {
    $flags{output} = \*STDOUT;
  }
  else {
    if ( -e $got->get_output && !$got->get_clobber_output ) {
      die $got->output . " Exists and --no-clobber-output is specified\n";
    }
    $flags{output} = _write_fd( $got->get_output );
  }

  if ( $got->get_rejects eq q{-} ) {
    $flags{rejects} = \*STDERR;
  }
  else {
    if ( -e $got->get_rejects && !$got->get_clobber_rejects ) {
      die $got->get_rejects . " Exists and --no-clobber-rejects is specified\n";
    }
    $flags{rejects} = _write_fd( $got->get_rejects );
  }

  $flags{debug}     = \*STDERR;
  $flags{dot_trace} = \*STDERR;

  ## no critic (ProhibitMagicNumbers)

  $flags{display_ui_generator} = sub {
    my $self = shift;
    require Class::Load;
    Class::Load->VERSION(0.06);
    Class::Load::load_class( $self->display_ui_class );
    return $self->display_ui_class->new(
      do {
        if    ( $got->get_silent ) { _silent_args() }
        elsif ( $got->get_quiet )  { _quiet_args() }
        else                       { _noisy_arg() }
      },
      fd_debug     => $self->debug,
      fd_dot_trace => $self->dot_trace,
    );

  };
  require Class::Load;
  Class::Load->VERSION(0.06);
  Class::Load::load_class('Paludis::UseCleaner');
  my $cleaner = Paludis::UseCleaner->new( \%flags );

  return $cleaner->do_work();
}

1;

__END__
=pod

=head1 NAME

Paludis::UseCleaner::App - Command Line App Interface to Paludis::UseCleaner

=head1 VERSION

version 0.01000307

=head1 SYNOPSIS

This is really just a huge wrapper around L<Getopt::Lucid>
which sets up L<Paludis::UseCleaner> in a friendly way.

    @ARGV=qw( --command -l -i -n -e --arguments );
    use Paludis::UseCleaner::App;

    Paludis::UseCleaner::App->run();

=head1 METHODS

=head2 run

Execute the code.

=head1 COMMAND LINE ARGUMENTS

=head2 --output $file

Set the file to write the cleaned use.conf to.

Defaults as C</tmp/use.conf.out>.

Use C<-> for C<STDOUT>.

=head2 --rejects $file

Set the file to write the rejected lines to.

Defaults as C</tmp/use.conf.rej>.

Use C<-> for C<STDERR>

=head2 --conf

Sets the file to read use.conf from,

Defaults as C</etc/paludis/use.conf>

Use C<-> for C<STDIN>

=head2 --no-clobber-output

If C<--output> exists, die instead of overwriting it.

=head2 --no-clobber-rejects

If C<--rejects> exists, die instead of overwriting it.

=head2 --silent

Print nothing debug related to stderr.

=head2 --no-quiet

Print verbose messages to stderr instead of a dot-trace

=head2 --help

Show a brief command line summary.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

