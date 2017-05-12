#!/usr/bin/env perl -w
use strict;
use warnings;

use Pod::Simple;
use Pod::Select;
use File::Find;

update_env();
update_backends();
update_sources();

sub update_backends {
    my @list = backends();

    {
        my $file_name = 'lib/Shipwright/Backend.pm';
        my $buf = '';
        open my $out_fh, '>', \$buf;
        my $updater = new ListUpdater;
        $updater->{'my_list'} = \@list;
        $updater->parseopts(-want_nonPODs => 1);
        $updater->parseopts(-process_cut_cmd => 1);
        $updater->parse_from_file($file_name, $out_fh);
        close $out_fh;

        open $out_fh, '>:raw', $file_name;
        print $out_fh $buf;
        close $out_fh;
    }
}

sub update_sources {
    my @list = sources();

    {
        my $file_name = 'lib/Shipwright/Source.pm';
        my $buf = '';
        open my $out_fh, '>', \$buf;
        my $updater = new ListUpdater;
        $updater->{'my_list'} = \@list;
        $updater->parseopts(-want_nonPODs => 1);
        $updater->parseopts(-process_cut_cmd => 1);
        $updater->parse_from_file($file_name, $out_fh);
        close $out_fh;

        open $out_fh, '>:raw', $file_name;
        print $out_fh $buf;
        close $out_fh;
    }
}

sub update_env {
    my @files = files_with_pod();

    my %tmp;

    my $pod_selector = Pod::Select->new;
    $pod_selector->select('ENVIRONMENT|ENVIRONMENT VARIABLES');
    foreach my $file (@files) {
        my $buf = '';
        open my $out_fh, '>', \$buf;
        $pod_selector->parse_from_file( $file, $out_fh );
        close $out_fh;

        unless ( $buf ) {
            print "no env in $file, skipping\n";
            next;
        }
        $tmp{$file} = { pod => $buf };
    }

    my $parser = new EnvFinder;
    while ( my ($file, $meta) = each %tmp ) {
        my $buf = '';
        open my $in_fh, '<', \$meta->{'pod'};
        open my $out_fh, '>', \$buf;
        $parser->parse_from_filehandle( $in_fh, $out_fh );
        close $out_fh;

        $meta->{'env'} = {$parser->result};
        unless ( keys %{ $meta->{'env'} } ) {
            print STDERR "File $file has env section but we couldn't parse it\n";
        }
    }
    {
        my %dups;
        while ( my ($file, $meta) = each %tmp ) {
            push @{$dups{$_} ||= []}, $file foreach keys %{ $meta->{'env'} };
        }
        foreach my $var ( grep @{$dups{$_}}>1, keys %dups ) {
            print STDERR "ENV variable '$var' described in several files: "
                . join( ', ', @{ $dups{$var} } ) ."\n";
        }
    }
    my %env = map %{ $_->{'env'} }, values %tmp;

    {
        my $manual_fn = 'lib/Shipwright/Manual/ENV.pod';
        my $buf = '';
        open my $out_fh, '>', \$buf;
        my $updater = new EnvUpdater;
        $updater->{'env'} = \%env;
        $updater->parse_from_file($manual_fn, $out_fh);
        close $out_fh;

        open $out_fh, '>:raw', $manual_fn;
        print $out_fh $buf;
        close $out_fh;
    }
}

sub files_with_pod {
    my @res;
    find( {
        wanted => sub {
            return unless /\.pm$/ || $File::Find::dir =~ m{/bin$};
            my $path = $File::Find::name;
            return if $path =~ /Manual/;
            push @res, $path;
        },
    }, 'bin', 'lib' );
    return @res;
}

sub backends {
    my @res;
    find( {
        wanted => sub {
            return unless s/\.pm$//;
            return if /^Base$/;
            push @res, $_;
        },
    }, 'lib/Shipwright/Backend' );
    return @res;
}
sub sources {
    my @res;
    find( {
        wanted => sub {
            return unless s/\.pm$//;
            return if /^Base$/;
            push @res, $_;
        },
    }, 'lib/Shipwright/Source' );
    return @res;
}


package EnvFinder;

use base 'Pod::Parser';

sub begin_input { $_[0]->{'env_parser'} = {} }
sub result { return %{ $_[0]->{'env_parser'} } }

sub command {
    my ($self, $cmd, $text, $line, $pod) = @_;

    if ( $cmd eq 'item' ) {
        unless ( $text =~ /^\s*([A-Z_]+)\s*-/ ) {
            print STDERR "Couldn't parse '$text' for env var\n";
        }
        $self->{'env_parser'}{$1} = $pod->raw_text;
    }

    return (shift)->SUPER::command(@_);
}

package EnvUpdater;
use base 'Pod::Parser';

sub command {
    my ($self, $cmd, $text, $line, $pod) = @_;

    if ( $cmd eq 'item' ) {
        if ( $text =~ /^([A-Z_]+)\b/ && $self->{'env'}{$1} ) {
            $self->{'inside_env_item'} = 1;
            my $out_fh = $self->output_handle;
            print $out_fh delete $self->{'env'}{$1};
            return;
        }
    }
    elsif ( $cmd eq 'back' && keys %{ $self->{'env'} } ) {
        my $out_fh = $self->output_handle;
        print $out_fh $_ foreach values %{ $self->{'env'} };
    }
    $self->{'inside_env_item'} = 0;
    return (shift)->SUPER::command(@_);
}

sub verbatim { (shift)->SUPER::verbatim(@_) unless $_[0]->{'inside_env_item'} }
sub textblock { (shift)->SUPER::textblock(@_) unless $_[0]->{'inside_env_item'} }

package ListUpdater;
use base 'Pod::Parser';

sub preprocess_paragraph {
    my ($self, $text, $line) = @_;

    my $out_fh = $self->output_handle;
    print $out_fh $text if $self->cutting;

    return (shift)->SUPER::preprocess_paragraph(@_);
}

sub command {
    my ($self, $cmd, $text, $line, $pod) = @_;

    if ( $cmd eq 'head1' && $text =~ /^SUPPORTED (BACKEND|SOURCE)S\s*$/s ) {
        $self->{'inside_item'} = 1;

        my $type = $1;
        my $res = $pod->raw_text;
        my @list = map "L<$_|Shipwright::${type}::$_>", sort @{ $self->{'my_list'} };
        my $last = pop @list;
        $res .= "Currently, the supported \L$type\Es are "
            . join( ', ', @list )
            ." and $last.";

        my $out_fh = $self->output_handle;
        print $out_fh $res ."\n\n";
    } else {
        $self->{'inside_item'} = 0;
    }
    return (shift)->SUPER::command(@_);
}

sub verbatim { (shift)->SUPER::verbatim(@_) unless $_[0]->{'inside_item'} }
sub textblock { (shift)->SUPER::textblock(@_) unless $_[0]->{'inside_item'} }

