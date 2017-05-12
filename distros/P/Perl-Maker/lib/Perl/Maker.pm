package Perl::Maker;
use 5.008003;
use strict;
use Mouse;
use YAML::XS;
use File::ShareDir;
use Getopt::Long;
use IPC::Run;

$Perl::Maker::VERSION = '0.01';

has action => (is => 'ro');
has args => (is => 'ro', default => sub {[]});
has file => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $script, @args) = @_;
    my $hash = {};

    while (1) {
        if (not @args) {
            $hash->{action} = 'help';
            last;
        }
        if ($args[0] !~ /^-/) {
            $hash->{action} = shift(@args);
            last;
        }
        local @ARGV = @args;
        GetOptions(               

        );
        @args = @ARGV;
    }
    $hash->{file} = shift(@args) || '';
    die "Extra arguments '@args'\n" if @args;

    $class->$orig($hash);
};

sub run {
    my $self = shift;
    my $action = $self->action;
    my $method = "handle_$action";
    die "'action' command not supported\n"
        unless $self->can($method);
    $self->$method(@{$self->args});
}

sub handle_new {
    my $self = shift;
}

sub handle_make {
    my $self = shift;
}

sub write_makefile {
    die "Perl::Maker does not work!\n";
}

1;

=enccoding utf8

=head1 NAME

Perl::Maker - Make a Custom Perl with Modules

=head1 SYNOPSIS

    > perl-maker --make ingy-perl-maker.yaml
    > make install

    > make perlbrew
    > make debian
    > make dmg
    > make rpm
    > make msi

=head1 STATUS

This software is pre-alpha quality. Don't use it yet.

=head1 DESCRIPTION

Perl::Maker creates a custom Perl installation, complete with an
entire set of modules, based on a simple YAML specification. You can
share the installation as a system package (like Debian for instance).
You can also share the YAML specification, or use an existing one from
somebody else.

The point of Perl::Maker is to make usable Perl installations that are
shareable. In many situations (especially in production environments),
it is critical not just to require that Perl and some modules to be
installed, but specific versions of things that are configured a
specific way.

With Perl::Maker, you specify all your requirements in a clean and
simple YAML file. Perl::Maker will turn this into a Makefile. Then you
simply invoke C<make> to do all the necessary work. Since the Makefile
targets know all their dependencies, when you make small changes to the
YAML file, only the minimum work to accomplish your goals will be
performed.

=head1 USAGE

Perl::Maker installs a command line tool called C<perl-maker>. This
section explains the commands you can use.

=over

=item perl-maker --new filename.yaml

This will create a sample Perl::Maker YAML specification for you.

=item perl-maker --make filename.yaml

This will generate a C<Makefile> from the YAML specification.

=back

=head1 TARGETS

This section describes the targets that you can use in the C<Makefile>,
to do various tasks.

=over

=item make install

This will build everything and install it for you.

=item make debian

This will make a Debian package that you can share and install on Debian
based systems.

=item make dmg

This will make a Mac OS X distribution.

=item make perlbrew

Build and install in your perlbrew location.

=back

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2011. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
