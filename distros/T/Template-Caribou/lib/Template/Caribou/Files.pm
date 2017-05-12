package Template::Caribou::Files;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Role to load templates from files
$Template::Caribou::Files::VERSION = '1.2.1';

use strict;
use warnings;

use MooseX::Role::Parameterized;

use Module::Runtime qw/ module_notional_filename /;
use Path::Tiny;
use Try::Tiny;

use experimental 'postderef';

parameter dirs => (
    default => undef,
);

parameter intro => (
    default => sub { [] },
);

    sub _load_template_file {
        my $self = shift;
        my $target = shift;

        my( $name, $file ) = @_ == 2 ? @_ : ( undef, @_ );

        $file = path($file);

        unless( $name ) {
            $name = $file->basename =~ s/\.bou//r;
        }

        my $class = ref $target || $target;

        my $code = join "\n",
            "package $class;",
            $self->intro->@*,
            "# line 1 ". $file,
            $file->slurp;

        my $coderef = eval $code;
        die $@ if $@;

        Template::Caribou::Role::template( (ref $target ? ( $target->meta, $target ) : $target->meta), $name, $coderef );
    };


    sub _load_template_dir {
        my ( $self, $target, $dir ) = @_;

        $dir = path($dir);

        Template::Caribou::Files::_load_template_file($self,$target,$_) for $dir->children( qr/\.bou$/ );
    };


role {
    my $p = shift;
    my %arg = @_;

    has template_dirs => (
        traits => [ 'Array' ],
        isa => 'ArrayRef',
        builder => '_build_template_dirs',
        handles => {
            all_template_dirs => 'elements',
            add_template_dirs => 'push',
        },
    );

    my $intro = $p->intro;
    has file_intro => (
        is => 'ro',
        default => sub { $intro },
    );

    my $dirs = $p->dirs;

    unless ( $dirs ) {
        my $name = $arg{consumer}->name;

        try {
            my $path = path( $INC{ module_notional_filename( $name )} =~ s/\.pm$//r );
            die unless $path->is_dir;
            $dirs = [ $path ];
        } catch {
            die "can't find directory for module '$name'";
        };
    }

    # so that we can call the role many times,
    # and the defaults will telescope into each other
    sub _build_template_dirs { [] }

    around _build_template_dirs => sub {
        my( $ref, $self ) = @_;

        return [ @{ $ref->($self) }, @$dirs ];
    };


    Template::Caribou::Files::_load_template_dir( $p, $arg{consumer}->name, $_) for @$dirs;

    method add_template_file => sub {
        my( $self, $file ) = @_;
        $file = path($file);

        Template::Caribou::Files::_load_template_file(
            $p,
            $self,
            $file
        );
    };




};



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Caribou::Files - Role to load templates from files

=head1 VERSION

version 1.2.1

=head1 SYNOPSIS

    package MyTemplate;

    use Template::Caribou;

    with 'Template::Caribou::Files' => {
        dirs  => [ './my_templates/' ],
        intro => [ 'use 5.10.0;' ],
    };

    1;

=head1 DESCRIPTION

A Caribou class consuming the C<Template::Caribou::Files> role
will automatically import
all template files (i.e., all files with a C<.bou> extension) under the given directories.

The names of the imported templates will be their path, relative to the
imported directories, without their extension. To take the example in the
L</SYNOPSIS>, if the content of C<my_templates/> is:

    ./foo.bou
    ./bar.bou

then the templates C<foo.bou> and C<bar.bou> will be created.

The template files themselves will be eval'ed in the context of
the parent class/namespace, and must return a coderef. E.g.,

    # file ./foo.bou

    # should be done in the class declaration, but
    # can be done here as well
    use Template::Caribou::Tags::HTML ':all';

    # likewise, would be better if added to
    # as a Template::Caribou::Files's intro
    use experimental 'signatures';

    sub ($self) {
        div {
            say 'this is foo';
            $self->bar;
        }
    }

=head1 METHODS

=head2 all_template_dirs

Returns a list of all template directories loaded by the
class (directories included by parent classes included).

=head2 file_intro

Returns the arrayref of the intro lines added to the F<.bou>
templates.

=head1 ROLE PARAMETERS

=head2 dirs

The array ref of directories to scan for templates.

If not provided,
it defaults to the directory associated with the template class.
For example, for

    package MyTemplates::Foo;

    use Template::Caribou;

    with 'Template::Caribou::Files';

    1;

located at F<lib/MyTemplates/Foo.pm>, the default directory
will be F<lib/MyTemplates/Foo/>.

=head2 intro

Arrayref of lines to add at the beginning of all F<.bou> templates.

    package MyTemplates::Foo;

    use Template::Caribou;

    with 'Template::Caribou::Files' => {
        intro => [
            q{ use 5.10.0; },
            q{ use experimental 'signatures'; },
        ];
    };

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
