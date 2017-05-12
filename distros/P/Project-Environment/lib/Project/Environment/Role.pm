package Project::Environment::Role;

# ABSTRACT: Moose role for Project::Environment

use Moose::Role;
use MooseX::Types::Path::Tiny qw(Path);

use Carp qw();
use File::Spec qw();
use Path::Tiny qw(path);
use Class::Inspector qw();
use Path::FindDev qw(find_dev);
use Module::Path qw(module_path);



has project_root => (
    is      => 'ro',
    isa     => Path,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_project_root',
);

sub _build_project_root {
    my $self = shift;

    my $class = ref $self || $self;

    my $file
        = $class eq 'Project::Environment'
        ? $self->_caller->[1]
        : $self->_module_path;

    my $dir = find_dev(path($file)->dirname);

    unless ($dir) {
        $dir = find_dev(File::Spec->curdir());
    }

    unless ($dir) {
        Carp::croak(
                  q{}
                . 'Cannot build project_root. '
                . 'Please set project_root attribute by hand or create one of '
                . 'the project_root_files in the root of the project.',
        );
    }

    return $dir;
}


sub _module_path {
    my ($self,) = @_;

    return module_path(ref $self || $self);
}


has environment_filename => (
    is      => 'ro',
    isa     => 'Str',
    default => '.environment',
);


has environment_path => (
    is      => 'ro',
    isa     => Path,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_environment_path',
);

sub _build_environment_path {
    my $self = shift;

    return $self->project_root->child($self->environment_filename);
}


has default_environment => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_default_environment',
);


has environment_variable => (
    is      => 'ro',
    isa     => 'Str',
    default => 'PROJECT_ENVIRONMENT',
);


has project_environment => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_project_environment',
);

sub _build_project_environment {
    my $self = shift;

    ## see if %ENV is set
    my $ev = $self->environment_variable;
    if (exists $ENV{$ev} && defined $ENV{$ev} && $ENV{$ev}) {
        return $ENV{$ev};
    }

    ## now check .environment file
    if (-e $self->environment_path) {
        my $env = scalar $self->environment_path->slurp;

        if ($env) {
            chomp($env);
            return $env;
        }
    }

    ## finally, try default
    if ($self->has_default_environment) {
        return $self->default_environment;
    }

    Carp::croak(
              q{}
            . 'Cannot find environment file at '
            . $self->environment_path
            . ' and no default_environment is set.',
    );
}


sub environment {
    return shift->project_environment;
}


sub env {
    return shift->project_environment;
}

1;    ## eof

__END__

=pod

=encoding UTF-8

=head1 NAME

Project::Environment::Role - Moose role for Project::Environment

=head1 VERSION

version v1.2.0

=head1 DESCRIPTION

This role defines most of the logic for L<Project::Environment>.

=head1 ATTRIBUTES

=head2 project_root

An instance of L<Path::Tiny>, which defines the root path of the project
as detected by L<Path::FindDev>.

Will croak if it cannot successfully build project_root.

=head2 mpath()

=head2 environment_filename

A name of the file to look for in the L</project_root> directory to read the
environment string from.

File must contain a single line with the environment name. It will attempt to
chomp the line. So, this will work:

 echo "develop" > .environment

Default: C<.environment>

=head2 environment_path

Full path to the L</environment_filename>. Basically just concatenation of
C<project_root> and C<environment_filename>.

=head2 default_environment

You can set a default environment in your subclass for when no environment
could be detected.

 package MyApp::Environment;
 use Moose;
 extends 'Project::Environment';

 has '+default_environment' => (default => 'development');

=head3 has_default_environment

A predicate method to test if a default environment is set or not.

=head2 environment_variable

An environment variable name to look for the value. This will always take
precedence over anything.

 PROJECT_ENVIRONMENT=test prove t/app.t

Default: C<PROJECT_ENVIRONMENT>

=head2 project_environment

Finally the star of the show. This attribute stores the actual value of the
environment as it was established. The value is determined in the following
order:

=over 4

=item C<environment_variable>

First, we check the value of the environment variable. If the value is set,
then we use that as C<project_environment>.

=item C<.environment>

Second, we check the C<.environment> file in the C<project_root>.

=item C<default_environment>

Lastly, we check the C<default_environment> attribute for a default value

=back

If the value cannot be established, the builder will croak with an explanation.

=head1 METHODS

=head2 environment

Shortcut for L</project_environment>.

=head2 env

Shortcut for L</project_environment>.

=head1 AUTHOR

Roman F. <romanf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Roman F..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
