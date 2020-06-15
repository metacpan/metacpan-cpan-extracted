package Mojolicious::Command::Author::generate::cpanfile;

our $VERSION = '0.10';

use Mojo::Base 'Mojolicious::Command';
use Mojo::Collection 'c';
use Mojo::File 'path';
use Mojo::Util 'getopt';

has description => 'Generate "cpanfile"';

has usage => sub { shift->extract_usage };

my $COMMENT = qr/(?:(?:#)(?:[^\n]*)(?:\n))/;
my $DATA    = qr/^__(DATA|END)__$(.)+/ms;
my $POD     = qr/(?:(^=[a-z]+[0-9]?\b).*?^=cut\b)/ms;
my $TEXT    = qr/(?:(?|(?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\")|(?:\')(?:[^\\\']*(?:\\.[^\\\']*)*)(?:\')|(?:\`)(?:[^\\\`]*(?:\\.[^\\\`]*)*)(?:\`)))/;

# $module_name => $module_version
# not defined($module_version): failed to load $module_name without success
# $module_version == 0: loaded $module_name successfully, doesn't have $VERSION
my %ModuleInfo;

sub run {
    my ($self, @args) = @_;
    my $path          = path;
    my $lib           = c;
    my $requires      = {};
    my $t             = c;
    my $test_requires = {};
    my $packages      = {};

    getopt(
        \@args,
        'l|lib=s'      => sub { push @$lib, $path->child($_[1]) },
        'r|requires=s' => sub { ++$requires->{$_[1]} },
        't=s'          => sub { push @$t, $path->child($_[1]) },
    )
        or return;

    push @$lib, $path->child('lib') unless $lib->size;
    push @$t,   $path->child('t')   unless $t->size;

    $self->_find_dependencies($lib, $requires, $packages);
    $self->_find_dependencies($t, $test_requires, $packages, qr/\.t$/);

    delete @$test_requires{keys %$requires};
    $self->render_to_rel_file(
        'cpanfile',
        'cpanfile',
        {requires => $requires, test_requires => $test_requires});
}

sub _find_dependencies {
    my ($self, $paths, $requires, $packages, $match) = @_;
    my %modules = %$requires;

    $paths->uniq->each(sub {
        shift->list_tree->each(sub {
            my $file = shift;
            my $content = $file->slurp;

            $content =~ s/$TEXT|$POD|$COMMENT|$DATA//g;
            ++$packages->{$_} for $content =~ /\bpackage\s+(\w+(?:\:\:\w+)*)/gs;

            return 1 if $match and $file !~ $match;
            ++$modules{$_}    for $content =~ /\b(?:use|require)\s+(\w+(?:\:\:\w+)*)/gs;
        });
    });

    delete @modules{keys %$packages};   # remove own modules

    foreach my $module (keys %modules) {
        my $version = $self->_module_version($module) // next;

        $requires->{$module} = $version;
    }

    return $self;
}

sub _module_version {
    my ($self, $module) = @_;

    return $ModuleInfo{$module} if exists $ModuleInfo{$module};

    no strict 'refs';

    my $version = eval("require $module") ? ${"${module}::VERSION"} // 0 : undef;

    $ModuleInfo{$module} = $version;

    return $version // 0;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::Author::generate::cpanfile - cpanfile generator command

=head1 SYNOPSIS

  Usage: APPLICATION generate cpanfile [OPTIONS]

    mojo generate cpanfile
    mojo generate cpanfile -r Mojolicious::Plugin::OpenAPI
    mojo generate cpanfile -l lib -l src -t t -t xt

  Options:
    -h, --help      Show this summary of available options
    -l, --lib       Overwrite module directories in which to look for
                    dependencies.  Can be used multiple times.
                    Defaults to 'lib' if no -l option is used.
    -r, --requires  Add module to dependencies that can't be found by
                    scanner.  Can be used multiple times.
    -t              Overwrite test directories in which to look for
                    test dependencies.  Can be used multiple times.
                    Defaults to 't' if no -t option is used.

=head1 DESCRIPTION

L<Mojolicious::Command::Author::generate::cpanfile> generates a C<cpanfile> file
by analyzing the application source code. It scans the C<*.pm> files in the
directories under F<./lib> (or whatever is given by the C<-l> option) for
regular module dependencies and C<*.t> files in F<./t> (or whatever is given by
the C<-t> option) for test dependencies.

=head1 ATTRIBUTES

L<Mojolicious::Command::Author::generate::cpanfile> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $cpanfile->description;
  $cpanfile       = $cpanfile->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $cpanfile->usage;
  $cpanfile = $cpanfile->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::Author::generate::cpanfile> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $cpanfile->run(@ARGV);

Run this command.

=head1 LICENSE

Copyright (C) Bernhard Graf.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernhard Graf E<lt>augensalat@gmail.comE<gt>

=cut

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut

__DATA__

@@ cpanfile
# https://metacpan.org/pod/distribution/Module-CPANfile/lib/cpanfile.pod

requires 'Mojolicious', '<%= $Mojolicious::VERSION %>';
% foreach my $module (sort { lc($a) cmp lc($b) } keys %$requires) {
requires '<%= $module %>'<% if ($requires->{$module}) { %>, '<%= $requires->{$module} %>'<% } %>;
% }

% if (%$test_requires) {
on test => sub {
% foreach my $module (sort { lc($a) cmp lc($b) } keys %$test_requires) {
    requires '<%= $module %>'<% if ($test_requires->{$module}) { %>, '<%= $test_requires->{$module} %>'<% } %>;
% }
};
% }

