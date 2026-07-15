package Mojolicious::Plugin::Fondation::Setup::MetaCPAN;
$Mojolicious::Plugin::Fondation::Setup::MetaCPAN::VERSION = '0.10';
# ABSTRACT: MetaCPAN discovery for Fondation plugins

use Mojo::Base -base, -signatures;
use version;

has base_url => 'https://fastapi.metacpan.org/v1';


sub discover_p ($self, $app) {
    my $ua  = $app->ua;
    my $url = $self->base_url
        . '/release/_search?q=distribution:Mojolicious-Plugin-Fondation-*'
        . '&size=100&sort=date:desc';

    return $ua->get_p($url)->then(sub ($tx) {
        my $data = $tx->result->json;
        my $hits = $data->{hits}{hits} // [];

        my %seen;
        my @plugins;

        for my $hit (@$hits) {
            my $src = $hit->{_source} // {};

            my $dist = $src->{distribution} or next;
            next if $seen{$dist}++;  # latest version only (sorted by date desc)

            # Derive the plugin class from the distribution name:
            # Mojolicious-Plugin-Fondation-Foo-Bar → Mojolicious::Plugin::Fondation::Foo::Bar
            my $module_class = $dist;
            $module_class =~ s/^Mojolicious-Plugin-//;
            $module_class = "Mojolicious::Plugin::$module_class";
            $module_class =~ s/-/::/g;

            my $installed_ver = $self->installed_version($module_class);
            my $has_upgrade = 0;
            if (defined $installed_ver && $src->{version}) {
                $has_upgrade = 1
                    if version->parse($src->{version}) > version->parse($installed_ver);
            }

            push @plugins, {
                distribution      => $dist,
                version           => $src->{version} // '',
                abstract          => $src->{abstract}  // '',
                author            => $src->{author}    // '',
                date              => $src->{date}      // '',
                module_class      => $module_class,
                installed         => defined $installed_ver ? 1 : 0,
                installed_version => $installed_ver,
                upgrade_available => $has_upgrade,
                dependencies      => $self->_fondation_deps($src->{dependency}),
            };
        }

        return \@plugins;
    });
}


sub installed_version ($self, $class) {
    my $file = $class =~ s{::}{/}gr . '.pm';
    return undef unless $INC{$file} || eval "require $class; 1";
    return eval { $class->VERSION } // undef;
}

# Extract Fondation-level dependencies from CPAN runtime requirements.
# Filters modules starting with Mojolicious::Plugin::Fondation::,
# excluding Mojolicious::Plugin::Fondation itself (the loader).
sub _fondation_deps ($self, $deps) {
    return [] unless $deps && ref $deps eq 'ARRAY';
    my @deps;
    for my $d (@$deps) {
        next unless ($d->{phase} // '') eq 'runtime';
        next unless ($d->{module} // '') =~ /^Mojolicious::Plugin::Fondation::/;
        next if $d->{module} eq 'Mojolicious::Plugin::Fondation';
        push @deps, $d->{module};
    }
    return \@deps;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Setup::MetaCPAN - MetaCPAN discovery for Fondation plugins

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  my $mc = Mojolicious::Plugin::Fondation::Setup::MetaCPAN->new;

  $mc->discover_p($app)->then(sub ($plugins) {
      for my $p (@$plugins) {
          say "$p->{module_class} — $p->{abstract}";
          say "  installed: " . ($p->{installed} ? 'yes' : 'no');
      }
  });

=head1 NAME

Mojolicious::Plugin::Fondation::Setup::MetaCPAN — MetaCPAN discovery for Fondation plugins

=head1 METHODS

=head2 discover_p

  my $promise = $mc->discover_p($app);

Queries MetaCPAN for all releases whose distribution starts with
C<Mojolicious-Plugin-Fondation->. Deduplicates by distribution name
(showing the latest version only). Derives the Perl module class from
the distribution name.

Returns a L<Mojo::Promise> resolving to an arrayref of hashrefs:

  {
      distribution  => 'Mojolicious-Plugin-Fondation-Blog',
      version       => '0.01',
      abstract      => 'Blog plugin for Fondation',
      author        => 'DAB',
      date          => '2026-06-15',
      module_class  => 'Mojolicious::Plugin::Fondation::Blog',
      installed     => $bool,
  }

=head2 installed_version

  my $version = $mc->installed_version('Mojolicious::Plugin::Fondation::Blog');

Returns the installed version string if the class is loadable and has a
C<$VERSION>, or C<undef> if not installed.

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation::Setup>,
L<https://metacpan.org>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
