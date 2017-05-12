package Plack::Middleware::Debug::LazyLoadModules;
use strict;
use warnings;
use Plack::Util::Accessor qw/filter class elements/;
use parent qw/Plack::Middleware::Debug::Base/;
our $VERSION = '0.06';

sub prepare_app {
    my $self = shift;
    $self->elements([qw/lazy preload/])
        unless $self->elements;
}

sub run {
    my($self, $env, $panel) = @_;

    my %modules = ();
    $modules{$_}++ for keys %INC;

    return sub {
        my %preload_modules;
        my %lazy_load_modules;
        my $preload = $self->_included('preload');
        my $lazy    = $self->_included('lazy');
        my $filter  = $self->filter;
        for my $module (keys %INC) {
            next if $filter && _is_regexp($filter) && $module !~ /$filter/;
            if ($preload && $modules{$module}) {
                $preload_modules{$self->_classnize($module)} = $INC{$module};
            }
            elsif ($lazy && !$modules{$module}) {
                $lazy_load_modules{$self->_classnize($module)} = $INC{$module};
            }
        }

        $panel->title('Lazy Load Modules');
        $panel->nav_subtitle(
            sprintf(
                "%d/%d lazy loaded",
                    scalar(keys %lazy_load_modules), scalar(keys %modules),
            )
        );
        $panel->content(
            $self->render_hash(
                +{
                    lazy    => \%lazy_load_modules,
                    preload => \%preload_modules,
                },
                $self->elements,
            )
        );
    };
}

sub _classnize {
    my ($self, $module_path) = @_;

    if ($self->class && $module_path =~ /\.pm$/) {
        $module_path =~ s!/!::!g;
        $module_path =~ s!\.pm$!!g;
    }
    return $module_path;
}

sub _is_regexp {
    (ref($_[0]) eq 'Regexp') ? 1 : 0;
}

sub _included {
    my ($self, $element) = @_;

    for my $e (@{$self->elements}) {
        return 1 if $element eq $e;
    }
    return;
}

1;

__END__

=head1 NAME

Plack::Middleware::Debug::LazyLoadModules - debug panel for Lazy Load Modules


=head1 SYNOPSIS

    use Plack::Builder;
    builder {
      enable 'Debug::LazyLoadModules';
      $app;
    };

or you can set `filter` option(Regexp reference) and `class` option(Foo/Bar.pm to Foo::Bar).

      enable 'Debug::LazyLoadModules',
        filter => qr/\.pm$/,
        class  => 1;

if you want to specify the element(ex. lazy, preload) for showing on the debug panel, you set `elements` option. All elements show on the debug panel by default.

      enable 'Debug::LazyLoadModules',
        elements => [qw/lazy/],


=head1 DESCRIPTION

Plack::Middleware::Debug::LazyLoadModules is debug panel for watching lazy loaded modules.


=head1 METHOD

=head2 prepare_app

see L<Plack::Middleware::Debug>

=head2 run

see L<Plack::Middleware::Debug::Base>


=head1 REPOSITORY

Plack::Middleware::Debug::LazyLoadModules is hosted on github
<http://github.com/bayashi/Plack-Middleware-Debug-LazyLoadModules>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Plack::Middleware::Debug>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
