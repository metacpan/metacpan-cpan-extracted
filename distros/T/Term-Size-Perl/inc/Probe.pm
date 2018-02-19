
package Probe;

=head1 NAME

inc/Probe.pm - Probes some machine configuration parameters for Term::Size::Perl's sake

=head1 SYNOPSIS

    $ perl 'inc/Probe.pm';

=head1 DESCRIPTION

TODO: improve error handling - this failed horribly in Windows with ExtUtils::CBuilder

  Probe.pm 
  * writes a C file
  * builds it (ExtUtils::CBuilder)
  * runs it (backquote)
  * grabs the output and creates Term/Size/Perl/Params.pm

Yes, that's Perl code which writes C code which writes Perl code.

a typical declaration (found somewhere along "termios.h")

  /* Interface to get and set terminal size. */
  struct  winsize {
    unsigned short  ws_row;    /* Rows, in characters     */
    unsigned short  ws_col;    /* Columns, in characters  */
    unsigned short  ws_xpixel; /* Horizontal size, pixels */
    unsigned short  ws_ypixel; /* Vertical size, pixels   */
  };

ASSUMPTIONS SO FAR:

=over 4

=item * 

struct winsize has no alignment pad
  (because we'll be using C<unpack> and relying on this arrangement)

=item *

the fields follow the order: ws_row, ws_col, ws_xpixel, ws_ypixel 
  (because we'll be using C<unpack> and relying on this order)

=item *

the type of each field is native unsigned short
  (because we'll be using C<unpack> with S! field)

=back

WHAT WE ARE PROBING

=over 4

=item * 

sizeof(struct winsize)

=item * 

TIOCGWINSZ

=item * 

the definition of TIOCGWINSZ

=back

WHAT THE OUTPUT LOOKS LIKE

  package Term::Size::Perl::Params; 

  sub params {
      return (
          winsize => {
              sizeof => 8,
              mask => 'S!S!S!S!'
          },
          TIOCGWINSZ => {
              value => 21505,
              definition => qq{(('T' << 8) | 1)}
          }
      );
  }

  1;

=head2 FUNCTIONS

=over 4

=cut

use ExtUtils::MakeMaker; # MM->parse_version($file)

# ATTENTION: $ and @ (if any) should be escaped (to survive interpolation)
# ATTENTION: % should be doubled (to pass through Perl sprintf)
# ATTENTION: POD directives are escaped so that Test::Pod don't say bad things about my POD

my $PARAMS_TEMPLATE = <<PARAMS;

package Term::Size::Perl::Params; 

# created @{[scalar localtime]}

use vars qw(\$VERSION);
\$VERSION = '@{[MM->parse_version('Perl.pm')]}';

sub params {
    return (
        winsize => {
            sizeof => %%.f,
            mask => 'S!S!S!S!'
        },
        TIOCGWINSZ => {
            value => %%.f,
            definition => qq{%%s}
        }
    );
}

1;

\=pod

\=head1 NAME

Term::Size::Perl::Params - Configuration for Term::Size::Perl

\=head1 SYNOPSIS

    use Term::Size::Perl::Params ();

    %%%%params = Term::Size::Perl::Params::params();

\=head1 DESCRIPTION

The configuration parameters C<Term::Size::Perl> needs to
know for retrieving the terminal size with C<ioctl>.

\=head1 FUNCTIONS

\=head2 params

The configuration parameters C<Term::Size::Perl> needs to
know for retrieving the terminal size with C<ioctl>.

\=cut

PARAMS

sub _quote_chunk {
    my $string = shift;
    return map { qq{"$_\\n"\n} } split "\n", $string;
}

my $PROBE_TEMPLATE = sprintf <<PROBE;

// probe.c

/*
 * This is meant to probe a few values from the machine 
 * configuration to make it possible using 
 * ioctl(., TIOCGWINSZ, .) to
 * get the terminal size via pure Perl code. 
 */

#include <stdio.h>

#include <sys/ioctl.h>
#include <termios.h>

#define xstr(s) str(s)
#define str(s) #s

int main(int argc, char *argv[]) {
    printf(
@{[_quote_chunk $PARAMS_TEMPLATE]},
        (double)sizeof(struct winsize),
        (double)TIOCGWINSZ,
        xstr(TIOCGWINSZ));

    return 0;
}

PROBE

sub _print_s { print __FILE__, ": ", @_ }
sub _print_ok { print((shift() ? 'ok' : 'NO'), "\n") };
sub _warn_s { print __FILE__, ": ", @_ }

sub _write_file {
    my $contents = shift;
    my $fn = shift;
    local (*FH, $!);
    open FH, "> $fn" or _warn_s("can't create '$fn': $!\n"), return undef;
    print FH $contents;
    _warn_s("error writing to '$fn': $!\n") if $!;
    close FH or _warn_s("error closing '$fn': $!\n");
    return 1
}

=item write_probe

  $c_file = write_probe($c_file);

Writes the source code of the probe to the file C<$c_file>.
Returns C<$c_file> if successful. Returns C<undef> if something
bad happened while writing the file.

=cut

sub write_probe {
    my $c_file = shift;
    my $ok;
    _print_s("writing C probe... ");
    $ok = _write_file($PROBE_TEMPLATE, $c_file); 
    _print_ok($ok);
    return undef unless $ok;
    return $c_file;
}

=item build_probe

  $exe_file = build_probe($c_file);

Compiles the C source C<$c_file> to object and then
links it to an executable file. Returns the executable
file name. If successful, it deletes the intermediary
object file. If compiling or linking fails,
returns undef.

=cut

# if you want to suppress compiler/linker output: ( quiet => 1 )
my %options = ( quiet => 0 );

sub build_probe {
    my $c_file = shift;
    require ExtUtils::CBuilder;
    my $builder = ExtUtils::CBuilder->new(%options);

    _print_s("compiling C probe... ");
    my $obj_file = eval { $builder->compile(source => $c_file) }; # don't die (now)
    _print_ok($obj_file);
    return undef unless $obj_file;

    _print_s("linking C probe... ");
    my $exe_file = eval { $builder->link_executable(objects => $obj_file) }; # don't die (now)
    _print_ok($exe_file);
    return undef unless $exe_file;

    unlink $obj_file or _warn_s $!;
    return $exe_file;
}

=item run_probe

  $output = run_probe($exe_file);

Runs the executable file C<$exe_file>, captures its output 
to STDOUT and returns it. Returns C<undef> if the exit
code (C<$?>) is not 0.

=cut

sub run_probe {
    my $exe_file = shift;
    _print_s("running C probe... ");
    my $output = `./$exe_file`;
    _print_ok(!$?);
    return undef if $?;
    return $output;
}

=item write_params

  $out_file = write_params($pl_code, $out_file);

Writes the contents of C<$pl_code> (a scalar supposed to
contain the Perl code of the information we were after)
to file C<$out_file>. Returns C<$out_file> if successful. 
Returns C<undef> if something
bad happened while writing the file.

=cut

sub write_params {
    my $pl_code = shift;
    my $out_file = shift;
    _print_s("writing '$out_file'... ");
    my $ok = _write_file($pl_code, $out_file);
    _print_ok($ok);
    return undef unless $ok;
    return $out_file;
}

=item run

  run()

Runs the probe. First, it writes a C file named F<probe.c>.
Second, it compiles and links this source.
Then, the resulting executable is run and its output captured.
At last, this output get written to the file F<Params.pm>.
(The intermediary files - F<probe.c>, object and executable
files - are deleted at the end of a successful run.)
If successful, returns 0. Otherwise, returns true.

=cut

sub run {
    my ($c_file, $exe_file, $out_file);
    $c_file = write_probe('probe.c') or return 1; # FAIL
    $exe_file = build_probe($c_file) or return 1; # FAIL
    $out_file = run_probe($exe_file) or return 1; # FAIL
    write_params($out_file, 'Params.pm') or return 1; # FAIL
    # clean
    unlink $c_file or _warn_s $!;
    unlink $exe_file or _warn_s $!;
    return 0; # SUCCESS
}


=pod

=back

=head1 SEE ALSO

L<Term::Size::Perl>

=head1 AUTHOR

A. R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by A. R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package main;

my $exit = Probe::run();
exit($exit);

