package SmokeRunner::Multi::Runner::Prove;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Runner subclass which uses prove
$SmokeRunner::Multi::Runner::Prove::VERSION = '0.21';
use strict;
use warnings;

use base 'SmokeRunner::Multi::Runner';
__PACKAGE__->mk_ro_accessors( 'output' );

use File::chdir;
use SmokeRunner::Multi::SafeRun qw( safe_run );
use SmokeRunner::Multi::Validate qw( validate ARRAYREF_TYPE );
use YAML::Syck qw( Dump );


sub run_tests
{
    my $self = shift;

    local $CWD = $self->set()->set_dir();

    safe_run
        ( command       => 'prove',
          args          => [ '-b', '-l', '-v', $self->set()->test_files() ],
          stdout_buffer => \$self->{output},
          stderr_buffer => \$self->{output},
        );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SmokeRunner::Multi::Runner::Prove - Runner subclass which uses prove

=head1 VERSION

version 0.21

=head1 SYNOPSIS

  my $runner = SmokeRunner::Multi::Runner::Prove->new( set => $set );

  $runner->run_tests();

  print $runner->output();

=head1 DESCRIPTION

This is a runner subclass that runs tests using F<prove>, the
command-line script that comes with C<Test::Harness>.

=head1 METHODS

This class provides the following methods:

=head2 SmokeRunner::Multi::Runner::Prove->new(...)

This method creates a new runner object. It requires one parameter:

=over 4

=item * set

A C<SmokeRunner::Multi::TestSet> object.

=back

=head2 $runner->run_tests()

This method runs the tests and captures both stdout and stderr in one
buffer.

=head2 $runner->output()

This returns the buffer of captured output from running F<prove>.

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
