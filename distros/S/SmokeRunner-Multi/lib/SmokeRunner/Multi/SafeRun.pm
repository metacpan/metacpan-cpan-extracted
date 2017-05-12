package SmokeRunner::Multi::SafeRun;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Run an external command safely in taint mode
$SmokeRunner::Multi::SafeRun::VERSION = '0.21';
use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = 'safe_run';

use Cwd qw( abs_path );
use File::Spec;
use File::Which qw( which );
use SmokeRunner::Multi::Validate
    qw( validate SCALAR_TYPE ARRAYREF_TYPE SCALARREF_TYPE );
use IPC::Run3 qw( run3 );


{
    my $spec = { command       => SCALAR_TYPE,
                 args          => ARRAYREF_TYPE( default => [] ),
                 stdout_buffer => SCALARREF_TYPE,
                 stderr_buffer => SCALARREF_TYPE,
               };

    sub safe_run
    {
        my %p = validate( @_, $spec );

        my $cmd;
        if ( File::Spec->file_name_is_absolute( $p{command} ) )
        {
            $cmd = $p{command};

            die "$cmd is not executable"
                unless -x $cmd;
        }
        else
        {
            $cmd = which( $p{command} )
                or die "Cannot find $p{command} in path";

            $cmd = abs_path($cmd);
        }

        # This is a simple way to make the path taint-safe.
        local $ENV{PATH} = '';
        run3( [ $cmd, @{ $p{args} } ],
              undef,
              $p{stdout_buffer}, $p{stderr_buffer}
            );
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SmokeRunner::Multi::SafeRun - Run an external command safely in taint mode

=head1 VERSION

version 0.21

=head1 SYNOPSIS

  use SmokeRunner::Multi::SafeRun qw( safe_run );

  my $stdour;
  my $stderr;
  safe_run(
      command       => 'agitate',
      args          => [ '-file', $filename ],
      stdout_buffer => \$stdout,
      stderr_buffer => \$stderr,
  );

=head1 DESCRIPTION

This module provides a taint-safe wrapper around the C<run3()>
function from C<IPC::Run3>.

=head1 FUNCTIONS

This module exports one optional subroutine:

=head2 safe_run(...)

This runs the specified command and captures its stdout and stderr
streams in scalar references.

The command will be run in a taint-safe manner.

It expects the following parameters:

=over 4

=item * command

The name to the command to run. The module internally uses
C<File::Which> to find a matching executable in the path. If none can
be found, the function will die.

=item * args

This should be an array reference containing arguments to be passed to
the command. This parameter is optional.

=item * stdout_buffer

=item * stderr_buffer

These parameter should be references to scalars, which will be used to
capture the output stream. You can pass the same scalar reference for
both parameters.

If you are not interested in a particular stream, pass a reference to
undef - C<\undef> for that parameter.

=back

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-smokerunner-multi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 LiveText, Inc., All Rights Reserved.

This program is free software; you can redistribute it and /or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by LiveText, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
