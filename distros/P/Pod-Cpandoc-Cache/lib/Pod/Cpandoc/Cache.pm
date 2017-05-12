package Pod::Cpandoc::Cache;
use 5.008005;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use parent 'Pod::Cpandoc';
use File::Spec::Functions qw(catfile catdir);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Copy;
use Class::Method::Modifiers;
use Time::Piece 1.16;

our $VERSION = "0.03";
use constant DEBUG => $ENV{POD_CPANDOC_CACHE_DEBUG};
use constant TTL => 3600*24;

sub live_cpan_url {
    my $self   = shift;
    my $module = shift;
    if ($self->opt_c) {
        return $self->SUPER::live_cpan_url($module);
    }
    "http://api.metacpan.org/v0/source/$module";
}

around 'grand_search_init' => sub {
    my $orig = shift;
    my ($self, $module_names) = @_;
    my $module_name = $module_names->[0];

    if ($self->opt_c) {
        if ( my $found = $self->search_from_cache($module_name)) {
            return $found;
        }
        my $found = $orig->(@_);
        $self->put_cache_file($found,$module_name);
        return $found;
    }

    $orig->(@_);
};

around 'searchfor' => sub {
    my $orig = shift;
    my ($self, undef, $module_name) = @_;

    if ( my $found = $self->search_from_cache($module_name)) {
        return ($found);
    }

    my @found = $orig->(@_) or return;

    warn "found number: ", scalar @found if DEBUG;
    warn "found file: ", $found[0] if DEBUG;

    $self->put_cache_file($found[0],$module_name);

    return @found;
};

sub search_from_cache {
    my $self = shift;
    my $module_name = shift;
    my $path = $self->module_name_to_path($module_name);
    return unless (-f $path);

    my $mtime = (stat($path))[9];

    if ( (localtime->epoch - localtime($mtime)->epoch) > TTL() ) {
        warn 'expire cache' if DEBUG;
        return;
    }else{
        warn 'search from cache' if DEBUG;
        return $path;
    }
}

sub is_tempfile {
    my $self = shift;
    my $file_name = shift;
    my $module_name = shift;

    my $hyphenated_module_name = join '-' => split('::',$module_name);
    $file_name =~ /${hyphenated_module_name}-[a-zA-Z0-9_]{4}\.(pm|txt)\z/;
}

sub cache_root_dir {
    my $self = shift;
    $self->{cache_root_dir} ||=
        $ENV{POD_CPANDOC_CACHE_ROOT} || catdir($ENV{HOME}, '.pod_cpandoc_cache');
}

sub module_name_to_path {
    my $self = shift;
    my $module_name = shift;
    my $cache_file_path = catfile($self->cache_root_dir,split('::',$module_name)) . ($self->opt_c ? '.txt' : '.pm');
    return $cache_file_path;
}

sub put_cache_file {
    my $self = shift;
    my $tempfile_name = shift;
    my $module_name = shift;

    if ($self->is_tempfile($tempfile_name,$module_name)) {
        my $path = $self->module_name_to_path($module_name);
        warn "put cache file: $path" if DEBUG;

        my $errors = [];
        make_path(dirname($path),{ error => \$errors });
        croak Dumper $errors if @$errors;

        copy($tempfile_name,$path) or die "Copy failed: $!";
    }
}


1;

__END__

=encoding utf-8

=head1 NAME

 Pod::Cpandoc::Cache - Caching cpandoc

=head1 SYNOPSIS

 $ ccpandoc Acme::No
 $ ccpandoc -m Acme::No
 $ ccpandoc -c Acme::No

 # support Pod::Perldoc::Cache
 $ ccpandoc -MPod::Perldoc::Cache -w parser=Pod::Text::Color::Delight Acme::No


=head1 DESCRIPTION

Pod::Cpandoc::Cache cache fetched document from CPAN.
B<TTL is 1day>.

=head1 CONFIGURATION

Pod::Cpandoc::Cache uses F<$HOME/.pod_cpandoc_cache> directory for keeping cache files. By setting the environment variable B<POD_CPANDOC_CACHE_ROOT>, you can select cache directory anywhere you want.

=head1 SEE ALSO

L<Pod::Cpandoc>

=head1 LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokubass E<lt>tokubass {at} cpan.orgE<gt>

=cut

