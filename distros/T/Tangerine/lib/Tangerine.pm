package Tangerine;
$Tangerine::VERSION = '0.23';
# ABSTRACT: Examine perl files and report dependency metadata
use 5.010;
use strict;
use warnings;
use utf8;
use PPI;
use Scalar::Util qw(blessed);
use Tangerine::Hook;
use Tangerine::Occurence;
use Tangerine::Utils qw(any accessor addoccurence none);

sub new {
    my $class = shift;
    my %args = @_;
    bless {
        _file => $args{file},
        _mode => $args{mode} // 'all',
        _hooks => {
            package => [ qw/package/ ],
            compile => [ qw/use list prefixedlist if inline moduleload
                moduleruntime mooselike testrequires tests xxx/ ],
            runtime => [ qw/require/ ],
        },
        _package => {},
        _compile => {},
        _runtime => {},
    }, $class
}

sub file { accessor _file => @_ }
sub mode { accessor _mode => @_ }

sub package { accessor _package => @_ }
sub compile { accessor _compile => @_ }
sub runtime { accessor _runtime => @_ }
# For pre-0.15 compatibility
*provides = \&package;
*requires = \&runtime;
*uses = \&compile;

sub run {
    my $self = shift;
    return 0 unless -r $self->file;
    $self->mode('all')
        unless $self->mode =~
            /^(a(ll)?|p(ackage|rov)?|compile|d(ep)?|r(untime|eq)?|u(se)?)$/;
    my $document = PPI::Document->new($self->file, readonly => 1);
    return 0 unless $document;
    my $statements = $document->find('Statement') or return 1;
    my @hooks;
    for my $type (qw(package compile runtime)) {
        for my $hname (@{$self->{_hooks}->{$type}}) {
            my $hook = "Tangerine::hook::$hname";
            if (eval "require $hook; 1") {
                push @hooks, $hook->new(type => $type);
            } else {
                warn "Couldn't load the tangerine hook `${hname}'!";
            }
        }
    }
    @hooks = grep {
            if ($self->mode =~ /^a/o ||
                $_->type eq 'package' && $self->mode =~ /^p/o ||
                $_->type eq 'compile' && $self->mode =~ /^[cdu]/o ||
                $_->type eq 'runtime' && $self->mode =~ /^[dr]/o) {
                $_
            }
        } @hooks;
    my $children;
    my $forcetype;
    STATEMENT: for my $statement (@$statements) {
        $children //= [ $statement->schildren ];
        if ($children->[1] &&
            ($children->[1] eq ',' || $children->[1] eq '=>')) {
            undef $children;
            next STATEMENT
        }
        for my $hook (@hooks) {
            if (my $data = $hook->run($children)) {
                my $modules = $data->modules;
                undef %$modules if any { $_ eq '->' } keys %$modules;
                for my $k (keys %$modules) {
                    if ($k !~ m/^[a-z_][a-z0-9_]*(?:::[a-z0-9_]+)*(?:::)?$/io ||
                        $k =~ m/^__[A-Z]+__$/o) {
                        delete $modules->{$k};
                        next
                    }
                    if (my ($class) = ($k =~ /^(.+)::$/o)) {
                        $modules->{$class} = $modules->{$k}
                            unless exists $modules->{$class};
                        delete $modules->{$k};
                        $k = $class
                    }
                    $modules->{$k}->line($statement->line_number);
                }
                my $type = $forcetype // $hook->type;
                if ($type eq 'package') {
                    $self->package(addoccurence($self->package, $modules));
                } elsif ($type eq 'compile') {
                    $self->compile(addoccurence($self->compile, $modules));
                } elsif ($type eq 'runtime') {
                    $self->runtime(addoccurence($self->runtime, $modules));
                }
                if (@{$data->hooks}) {
                    for my $newhook (@{$data->hooks}) {
                        next if ($newhook->type eq 'package') && ($self->mode =~ /^[dcru]/o);
                        next if ($newhook->type eq 'runtime') && ($self->mode =~ /^[pcu]/o);
                        next if ($newhook->type eq 'compile') && ($self->mode =~ /^[pr]/o);
                        push @hooks, $newhook
                            if none {
                                blessed($newhook) eq blessed($_) &&
                                $newhook->type eq $_->type
                            } @hooks;
                    }
                }
                if (@{$data->children}) {
                    $children = $data->children;
                    $forcetype = $data->type;
                    redo STATEMENT;
                }
            }
        }
        undef $children,
        undef $forcetype;
    }
    1;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tangerine - Examine perl files and report dependency metadata

=head1 SYNOPSIS

    use Tangerine;
    use version 0.77;

    my $scanner = Tangerine->new(file => $file, mode => 'all');
    $scanner->run;

    print "$file contains the following modules: ".
        join q/, /, sort keys %{$scanner->package}."\n";

    print "$file requires Exporter, at runtime, on the following lines: ".
        join q/, /, sort map $_->line, @{$scanner->runtime->{Exporter}}."\n";

    my $v = 0;
    for (@{$scanner->compile->{'Test::More'}}) {
        $v = $_->version if $_->version && qv($v) < qv($_->version)
    }
    print "The minimum version of Test::More required by $file is $v.\n";

=head1 DESCRIPTION

Tangerine examines perl files and reports dependency metadata -- provided
modules, and both compile-time and run-time dependencies, along with line
numbers, versions and possibly other related information.

Currently, PPI is used for the initial parsing and statement extraction.

=head1 CONSTRUCTOR

=over

=item C<new>

Creates the Tangerine object.  Takes the following two named arguments:

    'file', the file to examine
    'mode', determines what to look for; may be one of 'all',
        'package', 'compile', or 'runtime'.

Both arguments are optional, however, 'file' needs to be set before
running the scanner, e.g.

    my $scanner = Tangerine->new;
    $scanner->file($file);
    $scanner->run;

=back

=head1 METHODS

=over

=item C<run>

Runs the analysis.

=item C<package>

Returns a hash reference.  Keys are the modules provided, values
references to lists of L<Tangerine::Occurence> objects.

=item C<compile>

Returns a hash reference.  Keys are the modules required at compile-time,
values references to lists of L<Tangerine::Occurence> objects.

=item C<runtime>

Returns a hash reference.  Keys are the modules required at run-time,
values references to lists of L<Tangerine::Occurence> objects.

=item C<provides>

=item C<requires>

=item C<uses>

Deprecated.  These are provided for backwards compatibility only.

=back

=head1 SEE ALSO

L<Tangerine::Occurence>

=head1 REPOSITORY

L<https://github.com/contyk/tangerine.pm>

=head1 AUTHOR

Petr Šabata <contyk@redhat.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016 Petr Šabata

See LICENSE for licensing details.

=cut
