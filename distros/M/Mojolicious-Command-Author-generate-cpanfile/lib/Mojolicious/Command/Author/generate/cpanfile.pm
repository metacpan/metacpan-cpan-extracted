package Mojolicious::Command::Author::generate::cpanfile;

our $VERSION = '0.20';

use 5.018;

use List::Util 'reduce';
use Mojo::Base 'Mojolicious::Command';
use Mojo::Collection 'c';
use Mojo::File 'path';
use Mojo::Util 'getopt';
use Perl::Tokenizer;
use version 0.77;

has description => 'Generate "cpanfile"';

has usage => sub { shift->extract_usage };

sub run {
    my ($self, @args) = @_;
    my $path          = path;
    my $lib           = c;
    my $requires      = {Mojolicious => 1};
    my $t             = c;
    my $test_requires = {};
    my $packages      = {};
    my $versions      = {};

    getopt(
        \@args,
        'l|lib=s'      => sub { push @$lib, $path->child($_[1]) },
        'r|requires=s' => sub { ++$requires->{$_[1]} },
        't=s'          => sub { push @$t, $path->child($_[1]) },
    )
        or return;

    push @$lib, $path->child('lib') unless $lib->size;
    push @$t,   $path->child('t')   unless $t->size;

    $self->_find_dependencies($lib, $requires, $packages, $versions);
    $self->_find_dependencies($t, $test_requires, $packages, $versions, 1);

    delete @$test_requires{keys %$requires};

    # add "perl" to requirements if (use|require) $version exists in sources
    $requires->{perl} = 1 if $versions->{perl};

    $self->_set_versions($requires, $versions);
    $self->_set_versions($test_requires, $versions);

    $self->render_to_rel_file(
        'cpanfile',
        'cpanfile',
        {
            perl          => delete($requires->{perl}),
            requires      => $requires,
            test_requires => $test_requires,
        });
}

sub _find_dependencies {
    my ($self, $paths, $requires, $packages, $module_versions, $test) = @_;
    my $match = $test ? qr/\.(pm|t)$/ : qr/\.pm$/;

    $paths->uniq->each(sub {
        shift->list_tree->grep($match)->each(sub {
            my $file      = shift;
            my $code      = $file->slurp;
            my ($keyword, $module);

            perl_tokens {
                my $token = $_[0];

                return if $token eq 'horizontal_space' or $token eq 'vertical_space';

                my $value = substr($code, $_[1], $_[2] - $_[1]);

                if ($token eq 'keyword') {
                    if ($value eq 'package' or $value eq 'use' or $value eq 'require') {
                        $keyword = $value;
                        undef $module;
                    }
                    else {
                        undef $keyword;
                    }
                }
                elsif ($keyword) {
                    if ($token eq 'bare_word') {
                        if ($keyword eq 'package') {
                            ++$packages->{$value};
                            undef $keyword;
                        }
                        elsif ($keyword eq 'use') {
                            # use if followed by module name and potentially a version
                            unless ($module) {
                                $module = $value;
                                ++$requires->{$module};
                            }
                        }
                        elsif ($keyword eq 'require') {
                            # require if followed by module name but no additional version number
                            ++$requires->{$value};
                            undef $keyword;
                        }
                    }
                    elsif ($token eq 'number' or $token eq 'v_string') {
                        if ($keyword eq 'use') {
                            if ($module) {  # use Module::Name 0.12
                                push @{$module_versions->{$module}}, $value;
                                undef $module;
                            }
                            else {          # use 5.24.3
                                push @{$module_versions->{perl}}, $value;
                            }
                        }
                        elsif ($keyword eq 'require') {
                            push @{$module_versions->{perl}}, $value;
                        }

                        undef $keyword;
                    }
                    else {
                        undef $keyword;
                        undef $module;
                    }
                }
            } $code;
        });
    });

    delete @$requires{keys %$packages};   # remove own modules

    return $self;
}

sub _set_versions {
    my ($self, $r, $v) = @_;

    foreach my $module_name (keys %$r) {
        if (my $module_versions = $v->{$module_name}) {
            $r->{$module_name} = reduce { version->parse($a) > version->parse($b) ? $a : $b } @$module_versions;
        }
        else {
            $r->{$module_name} = undef;
        }
    }
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

% if ($perl) {
requires 'perl', '<%= $perl %>';
% }
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

