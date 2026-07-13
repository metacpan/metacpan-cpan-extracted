package Mojolicious::Plugin::Fondation::Utils;
$Mojolicious::Plugin::Fondation::Utils::VERSION = '0.04';
# ABSTRACT: Utility functions: config merge, name resolution, share directory helpers

use Mojo::Base -strict, -signatures;
use File::ShareDir 'dist_dir';
use Hash::Merge ();
use Mojo::File;

use Exporter 'import';
our @EXPORT_OK = qw( long_name short_name share_relative find_share_dir merge);

sub long_name {
    my ($name) = @_;
    return $name if $name =~ /^Mojolicious::Plugin::/;
    return "Mojolicious::Plugin::$name";
}

sub short_name {
    my ($name) = @_;
    $name =~ s/^Mojolicious::Plugin:://;
    return $name;
}

sub share_relative {
    my ($path) = @_;
    # Normalize to forward slashes (cross-platform: Windows uses backslashes)
    (my $normalized = $path) =~ s{\\}{/}g;
    my $pos = rindex($normalized, '/share/');
    return $path if $pos == -1;
    return substr($normalized, $pos + 1);
}

sub find_share_dir ($class_name, $override = undef) {
    return Mojo::File->new($override) if $override;

    my $dist = $class_name;
    $dist =~ s/::/-/g;

    # 1) Try File::ShareDir (installed modules)
    my $dir = eval { Mojo::File->new(dist_dir($dist)) };
    return $dir if $dir;

    # 2) Fallback: derive share dir from the class's location in %INC
    #    This handles test/dev environments where the module is not yet installed.
    (my $rel_path = "$class_name.pm") =~ s{::}{/}g;
    if (my $inc_path = $INC{$rel_path}) {
        my $pm     = Mojo::File->new($inc_path);
        my $root   = $pm;
        my $levels = scalar(split /::/, $class_name) + 1;  # +1 for lib/
        $root = $root->dirname for 1 .. $levels;
        my $share = $root->child('share');
        return $share if -d $share;
    }

    # 3) Last resort
    return Mojo::File->curfile->sibling('share');
}

# 3-level merging with priority (uses Hash::Merge for recursive merge):
# 1. direct config (in dependencies list)     -- highest priority
# 2. config in the app file (myapp.conf)
# 3. plugin defaults (via fondation_meta)     -- lowest priority
#
# Hash::Merge::merge() is LEFT_PRECEDENT, so we reverse the call order:
#   merge(direct, merge(app_conf, defaults))
#   -> direct wins over app_conf wins over defaults for scalars
#   -> arrays are concatenated, hashes are merged recursively
sub merge ($direct = {}, $app_conf = {}, $plugin_defaults = {}) {
    return Hash::Merge::merge(
        $direct // {},
        Hash::Merge::merge($app_conf // {}, $plugin_defaults // {})
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Utils - Utility functions: config merge, name resolution, share directory helpers

=head1 VERSION

version 0.04

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
