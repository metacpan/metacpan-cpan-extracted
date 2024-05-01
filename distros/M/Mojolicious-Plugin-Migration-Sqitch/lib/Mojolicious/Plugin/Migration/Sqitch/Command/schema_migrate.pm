package Mojolicious::Plugin::Migration::Sqitch::Command::schema_migrate 0.01;
use v5.26;
use warnings;

=pod

=head1 SYNOPSIS

  Usage: <APP> schema-migrate [args]

  Options:
    args        passed to sqitch
                (defaults to "deploy" if omitted)

=cut

use Mojo::Base 'Mojolicious::Command';

use experimental qw(signatures);

has description => 'Perform database schema migrations';
has usage       => sub ($self) {$self->extract_usage};

sub run($self, @args) {
  unshift(@args, 'deploy') unless (@args);
  die("You must specify a sqitch subcommand (e.g., deploy or revert)\n") if (@args && !grep {/^[^-]/} @args);
  my $v = $self->app->run_schema_migration(join(q{ }, @args));
  warn "an error occurred: $v\n" and exit $v if ($v);
}

=pod

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__
