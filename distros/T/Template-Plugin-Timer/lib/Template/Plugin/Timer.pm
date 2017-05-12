package Template::Plugin::Timer;
use strict;
use warnings;
use Benchmark::Timer;
use base qw(Template::Plugin);

our $VERSION = '0.02';

sub new {
    my $class   = shift;
    my $context = shift;
    my %args    = ref($_[0]) eq 'HASH' ? %{$_[0]} : ();
    Benchmark::Timer->new(%args);
}

1;

__END__

=head1 NAME

Template::Plugin::Timer - A Template Plugin to Profile Template
Processing

=head1 SYNOPSIS

  [% USE timer = Timer( ... options for Benchmark::Timer ... ) %]

  [% CALL timer.start('part1') %]
      ... do something you want to measure the time ...
  [% CALL timer.stop('part1') %]

  [% CALL timer.start('part2') %]
      ... do something you want to measure the time ...
  [% CALL timer.stop('part2') %]

  [% FOREACH report IN timer.reports %]
    [% report %]
  [% END %]

=head1 DESCRIPTION

Template::Plugin::Timer is just a glue module between L<Template> and
L<Benchmark::Timer>. See the POD of L<Benchmark::Timer> for more
details about the options you can pass into the constructor and the
methods the module provides.

=head1 SEE ALSO

=over 4

=item * Benchmark::Timer

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

=head1 SEE ALSO

=head1 COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
