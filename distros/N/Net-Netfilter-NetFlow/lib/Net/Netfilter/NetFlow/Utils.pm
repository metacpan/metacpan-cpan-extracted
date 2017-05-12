package Net::Netfilter::NetFlow::Utils;
{
  $Net::Netfilter::NetFlow::Utils::VERSION = '1.113260';
}

use strict;
use warnings FATAL => 'all';

use base 'Exporter';
our @EXPORT = qw(
    load_config
    format_args
    can_run
    merge_hashes
);

use Config::Any 0.15;

# use Config::Any to load a configuration file
sub load_config {
    my $name = shift;
    die "No filename specified to load_config!\n" if !defined $name;
    my $config = eval{ Config::Any->load_files({
        files => [$name],
        use_ext => 1,
        flatten_to_hash => 1,
    })->{$name} };
    die "Failed to load config [$name]\n" if $@ or !defined $config;
    return $config;
}

# interpolate the config vars
sub format_args {
    my $stub = shift;
    my $pre  = shift || ''; # maybe init_
    my $rv = sprintf $stub->{"${pre}format"},
        @{$stub->{"${pre}args"} || []};
    return split /\s+/, $rv;
}

# check if we have a program installed, and locate it
# borrowed from IPC::Cmd
sub can_run {
    my $command = shift;

    use Config;
    require File::Spec;
    require ExtUtils::MakeMaker;

    if( File::Spec->file_name_is_absolute($command) ) {
        return MM->maybe_command($command);
    }
    else {
        for my $dir (
            (split /\Q$Config{path_sep}\E/, $ENV{PATH}),
            File::Spec->curdir
        ) {           
            my $abs = File::Spec->catfile($dir, $command);
            return $abs if $abs = MM->maybe_command($abs);
        }
    }
}

# recursively merge two hashes together with right-hand precedence
# borrowed from Catalyst::Utils
sub merge_hashes {
    my ( $lefthash, $righthash ) = @_;
    return $lefthash unless defined $righthash;

    my %merged = %$lefthash;
    for my $key ( keys %$righthash ) {
        my $right_ref = ( ref $righthash->{ $key } || '' ) eq 'HASH';
        my $left_ref  = ( ( exists $lefthash->{ $key } && ref $lefthash->{ $key } ) || '' ) eq 'HASH';
        if( $right_ref and $left_ref ) {
            $merged{ $key } = merge_hashes(
                $lefthash->{ $key }, $righthash->{ $key }
            );
        }
        else {
            $merged{ $key } = $righthash->{ $key };
        }
    }

    return \%merged;
}

__END__

=head1 AUTHOR

Oliver Gorwits C<< <oliver@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) The University of Oxford 2009.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

