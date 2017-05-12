package Morpheus::Plugin::File;
{
  $Morpheus::Plugin::File::VERSION = '0.46';
}
use strict;

# ABSTRACT: plugin reading perl-based configs

use base qw(Morpheus::Plugin::Content);

use Morpheus;
use File::Find;
use Params::Validate;

sub new {
    my $class = shift;
    my $self = validate(@_, {
        path => { default => sub { morph('/morpheus/plugin/file/options/path') } },
        suffix => { default => qr/(?:\.(-?\d+))?\.(?:cfg|conf)$/ },
    });

    if (ref $self->{suffix} eq "Regexp") {
        my $re = $self->{suffix};
        $self->{suffix} = sub {
            my $fname = shift;
            $fname =~ s/$re// or return;
            return ($fname, $1);
        };
    }

    bless $self => $class;
}

sub content ($$) {
    my ($self, $file) = @_;
    open my $fh, "<", "$file" or die "open '$file' failed: $!";
    my $content = do { local $/; <$fh> };
    close $fh or die "close '$file' failed: $!";
    return $content;
}

sub list ($$) {
    my ($self, $main_ns) = @_;
    $main_ns =~ s{^/+}{};

    my $paths = $self->{path};
    $paths = $paths->() if ref $paths eq "CODE";
    return () unless $paths;
    die unless ref $paths eq "ARRAY";
    #FIXME: cache those paths?
    
    my $suffix = $self->{suffix};

    my @list;
    for my $path (@{$paths}) {
        $path =~ s{/+$}{};
        my %list;

        my $process_file = sub ($;$) {
            my ($full_file, $desired_ns) = @_;
            -f $full_file or return;
            die 'mystery' unless $full_file =~ m{^\Q$path\E/(.*)};
            my $file = $1;
            my ($ns, $priority) = $suffix->($file);
            return if not $ns or $desired_ns and $ns ne $desired_ns;
            push @{$list{$ns}}, {
                file => $full_file,
                priority => $priority || 0,
            };
        };

        if (-d "$path/$main_ns") {
            find({
                no_chdir => 1,
                follow_skip => 2,
                wanted => sub { $process_file->($File::Find::name) },
            }, "$path/$main_ns");
        }

        my $ns = $main_ns;
        while ($ns) {
            for my $file (glob ("$path/$ns*")) { # $ns.cfg or $ns.10.cfg but not $ns-blah.cfg
                $process_file->($file, $ns);
            }
            $ns =~ s{/?[^/]+$}{};
        }

        for my $ns (sort { length $b <=> length $a } keys %list) {
            for (sort { $b->{priority} <=> $a->{priority} } @{$list{$ns}}) {
                push @list, $ns => $_->{file};
            }
        }
    }

    return @list; 
    # priority rules: config path, then file depth, then file suffix.
    # for example if config path is /etc/:/etc2/ and there exist files 
    # /etc/x/y.10.cfg /etc/x/y.cfg /etc/x/y.-10.cfg 
    # /etc/x.10.cfg /etc/x.cfg /etc/x.-10.cfg 
    # /etc2/x/y.10.cfg /etc2/x/y.cfg /etc2/x/y.-10.cfg 
    # /etc2/x.10.cfg /etc2/x.cfg /etc2/x.-10.cfg
    # then the order of their priority from higher to lower is from left to right
}

1;

__END__
=pod

=head1 NAME

Morpheus::Plugin::File - plugin reading perl-based configs

=head1 VERSION

version 0.46

=head1 AUTHOR

Andrei Mishchenko <druxa@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

