use strict; use warnings;
package Module::Build::InlineModule;
our $VERSION = '0.04';

use base 'Module::Build';
__PACKAGE__->add_property('inline');

use Inline::Module();

sub ACTION_code {
    my $self = shift;
    $self->SUPER::ACTION_code(@_);
    my $meta = $self->get_meta;
    my @inc = @INC;
    local @INC = (
        (-e 'inc' ? ('inc') : ()),
        'lib',
        @inc,
    );
    for my $module (@{$meta->{module}}) {
        eval "require $module; 1" or die $@;
    }
    Inline::Module->handle_fixblib;
}

sub ACTION_distdir {
    my $self = shift;
    $self->SUPER::ACTION_distdir(@_);
    my $distdir = $self->dist_dir;
    my $meta = $self->get_meta;

    my $stub_modules = $meta->{stub};
    my $included_modules = Inline::Module->included_modules($meta);

    my $files_added = Inline::Module->add_to_distdir(
        $distdir,
        $stub_modules,
        $included_modules,
    );

    # XXX ask leont:
    # $self->_add_to_manifest($_)
    #     for @$files_added;
}

sub get_meta {
    my $self = shift;
    my $meta = $self->{properties}{inline}
        or die "Missing Module::Build property: 'inline'";
    $meta->{module} or die
        "Module::Build::InlineModule property 'inline' missing key 'module'";
    Inline::Module->default_meta($meta);
    return $meta;
}

1;
