package Shipwright::Script::Requires;

use strict;
use warnings;

use base qw/App::CLI::Command Shipwright::Base Shipwright::Script/;
__PACKAGE__->mk_accessors(
    qw/skip skip_recommends skip_all_recommends version as_graph min_perl_version
      include_dual_lifed/
);

use Shipwright;
use Shipwright::Util;
use File::Spec::Functions qw/catfile catdir/;

sub options {
    (
        'skip=s'              => 'skip',
        'skip-recommends=s'   => 'skip_recommends',
        'skip-all-recommends' => 'skip_all_recommends',
        'version=s'           => 'version',
        'as-graph'            => 'as_graph',
        'min-perl-version=s'  => 'min_perl_version',
        'include-dual-lifed'  => 'include_dual_lifed',
    );
}

sub run {
    my $self   = shift;
    my $source = shift;
    confess_or_die "we need source arg\n" unless $source;

    $self->skip( { map { $_ => 1 } split /\s*,\s*/, $self->skip || '' } );
    $self->skip_recommends(
        { map { $_ => 1 } split /\s*,\s*/, $self->skip_recommends || '' } );

    my $deps       = {};
    my $shipwright = Shipwright->new(
        source              => $source,
        skip_all_recommends => $self->skip_all_recommends,
        min_perl_version    => $self->min_perl_version,
        include_dual_lifed  => $self->include_dual_lifed,
        skip                => $self->skip,
        version             => $self->version,
        skip_recommends     => $self->skip_recommends,
    );
    my $name = $source;
    $name =~ s/^cpan://;
    $source = $shipwright->source->run();

    next
      unless $source;    # if running the source returned undef, we should skip

    $self->_requires( $source, $deps, $name );

    my $out;
    if ( $self->as_graph ) {
        $out = 'digraph g {
        graph [ overlap = scale, rankdir= LR ];
        node [ fontsize = "18", shape = record, fontsize = 18 ];
    ';

        for my $module ( keys %$deps ) {
            $out .=
qq{ "$module" [shape = record, fontsize = 18, label = "$module" ];\n};
            for my $dep ( keys %{ $deps->{$module} } ) {
                $out .= qq{"$module" -> "$dep";\n};
            }
        }
        $out .= "\n};";
    }
    else {
        $out = dump_yaml($deps);
    }
    $self->log->fatal($out);
}

# _import_req: import required dists for a dist

sub _requires {
    my $self   = shift;
    my $source = shift;
    my $deps   = shift;
    my $name   = shift;

    my $dir = parent_dir($source);
    my $map_file    = catfile( $dir, 'map.yml' );
    my $map         = load_yaml_file($map_file);
    my $reverse_map = { reverse %$map };

    opendir my ($d), $dir;
    my @sources = readdir $d;
    close $d;

    my $require_file = catfile( $source, '__require.yml' );
    if ( -e $require_file ) {
        my $d = load_yaml_file($require_file);
        for my $type ( keys %$d ) {
            for my $dep ( keys %{ $d->{$type} } ) {
                my $dep_source = catdir( $dir, $dep );
                my $dep_module = $reverse_map->{$dep} || $dep;

                $deps->{$name} ||= {};
                if ( exists $deps->{$name}{$dep_module} ) {
                    my $old = $deps->{$name}{$dep_module};
                    my $new = $d->{$type}{$dep}{version};

                    my $old_v = version->new($old);
                    my $new_v = version->new($new);
                    
                    if ( $new_v->numify > $old_v->numify ) {
                        $deps->{$name}{$dep_module} =
                          $d->{$type}{$dep}{version};
                    }
                }
                else {
                    $deps->{$name}{$dep_module} = $d->{$type}{$dep}{version};
                }

                next if $deps->{$dep_module};
                $self->_requires( $dep_source, $deps, $dep_module );
            }
        }
    }
    else {
        $self->log->warn("failed to find requirments of $source");
    }

}

1;

__END__

=head1 NAME

Shipwright::Script::Requires - list CPAN modules the source depends on

=head1 SYNOPSIS

 requires cpan:Jifty

=head1 OPTIONS

 --version                      : specify the source's version
 --skip                         : specify a list of modules/dist names of
                                  which we don't want to show
 --skip-recommends              : specify a list of modules/dist names of
                                  which recommends we don't want to show
 --skip-all-recommends          : skip all the recommends to show
 --min-perl-version             : minimal perl version (default is the same as
                                  the one which runs this command)
 --include-dual-lifed           : include modules which live both in the perl core 
                                  and on CPAN
 --as-graph                     : output a graph source suitable for rendering
                                  by dot (http://graphviz.org) 
 
=head1 DESCRIPTION

The requires command only show the requirements of a source, it doesn't
create or import at all.

=head1 GLOBAL OPTIONS

 -r [--repository] REPOSITORY   : specify the repository uri of our shipyard
 -l [--log-level] LOGLEVEL      : specify the log level
                                  (info, debug, warn, error, or fatal)
 --log-file FILENAME            : specify the log file

=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

