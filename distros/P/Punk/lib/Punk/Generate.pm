package Punk::Generate;

use 5.010;
use strict;
use warnings;
use Carp ();
use File::Path ();
use File::Spec ();
use File::Copy ();
use File::Basename ();
use Template::Stencil;

our $VERSION = '0.17';

sub new {
    my ($class, %args) = @_;

    my $name = $args{name};
    Carp::croak('Punk::Generate: an application name is required')
        unless defined $name && length $name;
    Carp::croak("Punk::Generate: '$name' is not a legal Perl package name")
        unless _pkg_ok($name);

    my $self = bless {
        name  => $name,
        api   => $args{api},
        force => $args{force} ? 1 : 0,
        dir   => $args{dir},
        written => [],
    }, $class;

    $self->{dir} = _dist_dir($name) unless defined $self->{dir};
    return $self;
}

# The operation plan for a spec - groups, security schemes, the lot - without
# generating anything. `punk api sync` reuses it so the grouping rules have one
# implementation, not two that drift.
sub api_plan {
    my ($class, $spec) = @_;
    return _read_api(undef, $spec);
}

# The package-name-safe identifier for a tag or a path segment, so a caller
# grouping operations reaches the same answer this does.
sub ident {
    my ($class, $raw) = @_;
    return _ident($raw);
}

# Render one skeleton template to a string, or straight to a file. Same engine,
# same options, so a stub added later is identical to one generated up front.
sub render_skel {
    my ($class, $template, $vars) = @_;
    return _shared_engine()->render($template, $vars || {});
}

sub write_skel {
    my ($class, $template, $abs, $vars) = @_;
    File::Path::make_path(File::Basename::dirname($abs));
    open my $fh, '>:encoding(UTF-8)', $abs
        or Carp::croak("Punk::Generate: cannot write $abs: $!");
    print $fh $class->render_skel($template, $vars);
    close $fh or Carp::croak("Punk::Generate: cannot close $abs: $!");
    return $abs;
}

sub name    { $_[0]{name} }
sub dir     { $_[0]{dir} }
sub written { @{ $_[0]{written} } }

sub run {
    my ($self) = @_;
    my $dir = $self->{dir};

    if (-e $dir) {
        Carp::croak("Punk::Generate: '$dir' exists and is not a directory")
            unless -d $dir;
        Carp::croak("Punk::Generate: '$dir' is not empty")
            if !$self->{force} && _has_entries($dir);
    }

    # Everything that can fail on bad input fails before the first write: an
    # unreadable or invalid spec should not leave half a tree behind.
    my $api = $self->{api} ? $self->_read_api($self->{api}) : undef;

    my $path = $self->{name};
    $path =~ s{::}{/}g;

    my %vars = (
        name    => $self->{name},
        path    => $path,
        lc_name => lc(($self->{name} =~ /([^:]+)\z/)[0]),
        uc_name => uc(($self->{name} =~ /([^:]+)\z/)[0]),
        api     => $api ? 1 : 0,
    );
    if ($api) {
        $vars{first_op}   = $api->{first_op};
        $vars{schemes}    = $api->{schemes};
        $vars{auth_class} = $api->{auth_class};
    }

    $self->_render('app_psgi.tmpl',             'app.psgi',       \%vars);
    $self->_render('punk_yml.tmpl',             'config/punk.yml', \%vars);
    $self->_render('app_class.tmpl',            "lib/$path.pm",   \%vars);
    $self->_render('controller_web_root.tmpl',
                   "lib/$path/Controller/Web/Root.pm",            \%vars);
    $self->_render('basic_t.tmpl',              't/01-basic.t',   \%vars);
    $self->_render('readme_md.tmpl',            'README.md',      \%vars);
    $self->_render('gitignore.tmpl',            '.gitignore',     \%vars);

    $self->_copy('view/layout.tmpl',  'root/templates/layout.tmpl');
    $self->_copy('view/welcome.tmpl', 'root/templates/welcome.tmpl');
    $self->_copy('view/style.css',    'root/static/style.css');

    if ($api) {
        $self->_copy_file($self->{api}, 'openapi.json');
        for my $group (@{ $api->{groups} }) {
            $self->_render('controller_api.tmpl',
                "lib/$path/Controller/API/$group->{group}.pm",
                { %vars, %$group });
        }
        $self->_render('controller_auth.tmpl',
            "lib/$path/Controller/API/$api->{auth_class}.pm", \%vars)
            if @{ $api->{schemes} };
    }

    chmod 0755, File::Spec->catfile($dir, 'app.psgi');
    return $self->written;
}

# ---- names -------------------------------------------------------------------

# MyApp -> MyApp; My::App -> My-App, the CPAN convention for a distribution
# directory holding a nested package.
sub _dist_dir {
    my ($name) = @_;
    (my $dir = $name) =~ s/::/-/g;
    return $dir;
}

sub _pkg_ok {
    my ($name) = @_;
    return $name =~ /\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/;
}

# A tag, a path segment or an operationId turned into something that can sit
# in a package name: word characters kept, everything else a boundary, each
# resulting piece capitalised. "books & authors" -> BooksAuthors.
sub _ident {
    my ($raw) = @_;
    return '' unless defined $raw;
    my @parts = grep { length } split /[^A-Za-z0-9]+/, $raw;
    return '' unless @parts;
    my $id = join '', map { ucfirst $_ } @parts;
    $id = "N$id" if $id =~ /\A[0-9]/;   # a package name cannot start with a digit
    return $id;
}

# ---- writing -----------------------------------------------------------------

sub _skel_dir {
    my $pm = $INC{'Punk/Generate.pm'}
        or Carp::croak('Punk::Generate: cannot locate my own installation');
    (my $dir = $pm) =~ s/\.pm\z//;
    return "$dir/skel";
}

# The engine. auto_escape => 0 because this generates Perl, YAML and psgi -
# escaping would turn every quote, & and < in the output into an entity.
# One per process: Stencil caches compiled templates, and there is no reason
# for a second generator to compile them again.
my $ENGINE;
sub _shared_engine {
    return $ENGINE ||= Template::Stencil->new(
        template_dir => _skel_dir(),
        auto_escape  => 0,
        chars        => 1,       # decoded text; the write below encodes once
    );
}

sub _engine { return _shared_engine() }

sub _has_entries {
    my ($dir) = @_;
    opendir(my $dh, $dir) or return 0;
    my @e = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    return scalar @e;
}

sub _dest {
    my ($self, $rel) = @_;
    my $abs = File::Spec->catfile($self->{dir}, split m{/}, $rel);
    File::Path::make_path(File::Basename::dirname($abs));
    return $abs;
}

sub _render {
    my ($self, $template, $rel, $vars) = @_;
    my $abs = $self->_dest($rel);
    open my $fh, '>:encoding(UTF-8)', $abs
        or Carp::croak("Punk::Generate: cannot write $abs: $!");
    print $fh $self->_engine->render($template, $vars);
    close $fh or Carp::croak("Punk::Generate: cannot close $abs: $!");
    push @{ $self->{written} }, $rel;
    return $abs;
}

sub _copy {
    my ($self, $skel_rel, $rel) = @_;
    return $self->_copy_file(
        File::Spec->catfile(_skel_dir(), split m{/}, $skel_rel), $rel);
}

sub _copy_file {
    my ($self, $src, $rel) = @_;
    my $abs = $self->_dest($rel);
    File::Copy::copy($src, $abs)
        or Carp::croak("Punk::Generate: cannot copy $src to $abs: $!");
    push @{ $self->{written} }, $rel;
    return $abs;
}

# ---- the OpenAPI side --------------------------------------------------------

# Parse the spec through Open::API itself, so a duplicate or missing
# operationId, or an unresolvable $ref, is caught here - by the same code that
# will mount it - rather than surfacing at the application's first boot.
sub _read_api {
    my ($self, $spec) = @_;   # $self is unused, so api_plan can pass undef
    Carp::croak("Punk::Generate: no such spec file: $spec") unless -f $spec;

    require Open::API;
    my $api = eval { Open::API->new(spec => $spec) }
        or Carp::croak("Punk::Generate: $spec is not a usable OpenAPI "
            . "document: $@");

    my $ops = $api->operations;
    Carp::croak("Punk::Generate: $spec declares no operations")
        unless $ops && @$ops;

    # operations comes back in hash order, which perl randomises per process.
    # Left alone that makes the generator non-deterministic - regenerating the
    # same spec would shuffle subs between and within files, and every diff
    # would be noise. Sort by path, then by method in the order a reader
    # expects to meet them.
    my %rank = (GET => 0, HEAD => 1, POST => 2, PUT => 3,
                PATCH => 4, DELETE => 5, OPTIONS => 6, TRACE => 7);
    my @sorted = sort {
           $a->{path} cmp $b->{path}
        || ($rank{ uc $a->{method} } // 99) <=> ($rank{ uc $b->{method} } // 99)
        || $a->{method} cmp $b->{method}
    } @$ops;
    $ops = \@sorted;

    my $doc = $api->spec;
    my (%by_group, @order);

    # Group by tag when the document uses tags at all, by first path segment
    # when it does not - a spec with no tags still deserves more than one
    # bucket, and one with tags has already told us how its author groups it.
    my $tagged = 0;
    for my $op (@$ops) {
        next unless @{ _tags_for($doc, $op) };
        $tagged = 1;
        last;
    }

    for my $op (@$ops) {
        my $label = $tagged ? (_tags_for($doc, $op)->[0] // '')
                            : (grep { length } split m{/}, $op->{path})[0] // '';
        my $group = _ident($label) || 'Default';
        push @order, $group unless $by_group{$group};
        my $node = _op_node($doc, $op);
        push @{ $by_group{$group}{ops} }, {
            id      => $op->{operationId},
            method  => uc $op->{method},
            path    => $op->{path},
            summary => _summary($node),
        };
        $by_group{$group}{group}       = $group;
        $by_group{$group}{group_label} = $label;
        $by_group{$group}{tagged}      = $tagged ? 1 : 0;
    }

    # Every securityScheme the document actually requires needs a checker in
    # the mount's security option, or Punk croaks at boot naming it. So the
    # scaffolder owes one stub per scheme - an application generated from a
    # secured spec has to start.
    my @schemes = _schemes($doc, $ops);
    my $auth_class;
    if (@schemes) {
        # A tag called Auth would already own that file; take the first free
        # name rather than clobbering a controller full of operations.
        my %taken = map { $_ => 1 } @order;
        ($auth_class) = grep { !$taken{$_} } qw(Auth Security Authentication);
        $auth_class ||= 'AuthSchemes';
        $_->{class} = $auth_class for @schemes;
    }

    my $first = $ops->[0];
    return {
        # by name, for the same reason the operations are sorted: which class
        # is written first should not depend on hash order
        groups     => [ map { $by_group{$_} } sort @order ],
        schemes    => \@schemes,
        auth_class => $auth_class,
        # The generated test needs a route it can prove is mounted. A path
        # template's placeholders get a filler so it is a real request path.
        first_op => {
            id           => $first->{operationId},
            method       => uc $first->{method},
            path         => $first->{path},
            path_literal => _fill_path($first->{path}),
        },
    };
}

# The securityScheme names the document actually requires - the union of the
# global `security` and every operation's own - paired with their definitions.
# A scheme defined in components but never required needs no checker, and
# generating one would only be noise.
sub _schemes {
    my ($doc, $ops) = @_;
    my $defs = ($doc->{components} || {})->{securitySchemes} || {};
    my (%want, @order);

    my $collect = sub {
        my ($req) = @_;
        return unless ref $req eq 'ARRAY';
        for my $alt (@$req) {
            next unless ref $alt eq 'HASH';
            for my $name (sort keys %$alt) {
                push @order, $name unless $want{$name}++;
            }
        }
    };
    $collect->($doc->{security});
    for my $op (@$ops) {
        my $node = _op_node($doc, $op);
        $collect->($node->{security}) if $node;
    }

    my @out;
    for my $name (@order) {
        my $d = ref $defs->{$name} eq 'HASH' ? $defs->{$name} : {};
        push @out, {
            name        => $name,
            # The mount key stays the spec's name. The sub keeps it too when
            # it is already a legal identifier - which is almost always - and
            # is only reshaped when the spec used something like 'api-key'.
            method      => ($name =~ /\A[A-Za-z_]\w*\z/
                            ? $name : (_ident($name) || 'check')),
            type        => $d->{type}   || '',
            in          => $d->{in}     || '',
            key         => $d->{name}   || '',
            scheme      => lc($d->{scheme} || ''),
            description => _summary($d),
            credential  => _credential_of($d),
        };
    }
    return @out;
}

# What arrives as the checker's first argument, per scheme shape - the one
# thing someone filling in a stub most needs to know.
sub _credential_of {
    my ($d) = @_;
    my $type = $d->{type} || '';
    if ($type eq 'apiKey') {
        my $where = $d->{in} || 'header';
        my $key   = $d->{name} // '';
        return "the $where '$key'";
    }
    if ($type eq 'http') {
        my $s = lc($d->{scheme} || '');
        return 'the base64-decoded "user:password" from the Authorization '
             . 'header' if $s eq 'basic';
        return 'the token from the Authorization header, without the '
             . '"Bearer " prefix' if $s eq 'bearer';
        return "the Authorization header's credential";
    }
    return 'the access token' if $type eq 'oauth2' || $type eq 'openIdConnect';
    return 'the credential';
}

sub _op_node {
    my ($doc, $op) = @_;
    my $p = $doc->{paths} && $doc->{paths}{ $op->{path} };
    return undef unless ref $p eq 'HASH';
    my $node = $p->{ lc $op->{method} };
    return ref $node eq 'HASH' ? $node : undef;
}

sub _tags_for {
    my ($doc, $op) = @_;
    my $node = _op_node($doc, $op);
    my $tags = $node && $node->{tags};
    return ref $tags eq 'ARRAY' ? [ grep { defined && length } @$tags ] : [];
}

sub _summary {
    my ($node) = @_;
    return '' unless ref $node eq 'HASH';
    my $s = $node->{summary};
    $s = $node->{description} unless defined $s && length $s;
    return '' unless defined $s && length $s;
    $s =~ s/\s+/ /g;                 # one line, for a comment and a POD para
    $s =~ s/\A\s+|\s+\z//g;
    $s =~ s/"/'/g;                   # it lands inside a double-quoted comment
    return $s;
}

# /books/{id} -> /books/1, so the generated test can request it.
sub _fill_path {
    my ($path) = @_;
    $path =~ s/\{[^}]*\}/1/g;
    return $path;
}

1;

__END__

=head1 NAME

Punk::Generate - scaffold a new Punk application

=head1 SYNOPSIS

    punk new MyApp
    punk new MyApp --api ./openapi.json

    # or from Perl
    use Punk::Generate;
    my @files = Punk::Generate->new(name => 'MyApp')->run;

=head1 DESCRIPTION

The generator behind C<punk new>. It writes a complete, running
application: the class with its routes, a controller, Stencil views with
a wrapper, C<config/punk.yml>, a psgi entry point and a test that starts
the app and requests a page.

The skeleton ships as templates beside this module and is rendered
through L<Template::Stencil> - the same engine the generated application
uses for its own views.

=head1 METHODS

=head2 new

    Punk::Generate->new(
        name  => 'MyApp',          # required; a legal Perl package name
        dir   => './MyApp',        # default: the name, :: replaced by -
        api   => './openapi.json', # optional; generates the API mount
        force => 0,                # write into a non-empty directory
    );

Croaks on a name that is not a legal package name.

=head2 run

Writes the tree and returns the list of paths written, relative to
C<dir>. Croaks - before writing anything - if the target directory is
not empty and C<force> was not given, or if the spec cannot be read.

=head2 name / dir / written

The application name, the target directory, and the paths written by the
last C<run>.

=head1 THE GENERATED APPLICATION

    app.psgi                          chdir to the root, then MyApp->to_app
    config/punk.yml                   views, static, and a commented database
    lib/MyApp.pm                      routes and wiring
    lib/MyApp/Controller/Web/Root.pm  the front page
    root/templates/layout.tmpl        the wrapper
    root/templates/welcome.tmpl       the welcome page
    root/static/style.css
    t/01-basic.t                      builds the app and requests /
    README.md
    .gitignore                        including config/punk.local.yml

C<app.psgi> changes directory to the application root before loading the
class, because C<punk.yml> carries relative paths; that is what makes
C<plackup app.psgi> work from anywhere.

=head2 With a spec

C<--api> adds C<openapi.json> at the application root, mounts it under
C</api> with the documentation UI at C</docs>, and generates one
controller per group of operations, each with a method named for its
C<operationId> answering C<501> until implemented.

Operations are grouped by their first tag when the document uses tags,
and by first path segment when it does not.

Every C<securityScheme> the document B<requires> also gets a checker
stub, in C<Controller::API::Auth> (or the next free name, if a tag
already owns that one), wired into the mount's C<security> option -
without which Punk croaks at boot naming the scheme. Those stubs refuse
every request until implemented, so the operations the specification
protects are not opened by a placeholder. A scheme defined in
C<components> but never required needs no checker and gets none.

=head1 SEE ALSO

L<Punk>, L<Punk::Controller>, L<Punk::Config>, L<Punk::Mount::OpenAPI>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
