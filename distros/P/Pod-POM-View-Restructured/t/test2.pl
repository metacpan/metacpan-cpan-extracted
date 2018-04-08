#!/usr/local/bin/perl

# Original authors: don
# $Revision: $


use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config no_ignore_case bundling);
use Data::Dumper ();

use Pod::POM;

# main
{
    # local($SIG{__DIE__}) = sub { &Carp::confess };
    my $self = bless { };

    my $opts = $self->get_options([ "help|h" ], { });
    $self->check_options($opts, [ ]); # die's on bad options


    my $top_dir;
    # Set up @INC to get right version of module
    use File::Spec ();
    BEGIN {
        my $path = File::Spec->rel2abs($0);
        (my $dir = $path) =~ s{(?:/[^/]+){2}\Z}{};
        # unshift @INC, $dir . "/blib/lib", $dir . "/blib/arch";
        unshift @INC, $dir . "/lib";

        $top_dir = $dir;
    }

    my $test_dir = $top_dir . "/test_doc/source";
    my $doc_dir = $top_dir . "/test_doc";
    my $base_dir = "/owens_lib/cpan";

    # my $dest_dir = "$top_dir/test_doc/big_out";
    my $dest_dir = "$top_dir/test_doc/source";


    use Pod::POM::View::Restructured;

    my $link_cb = sub {
        my ($text) = @_;

        if ($text eq 'DBIx::Wrapper::Request') {
            return ('DBIx-Wrapper-Request.html', $text);
        }

        return;
    };

    my $callbacks = { link => $link_cb };

    chdir $dest_dir;
    
    my $files = [
                 { source_file => "$base_dir/Pod-POM-View-Restructured/lib/Pod/POM/View/Restructured.pm",
                   dest_file => "Pod-POM-View-Restructured.rst",
                   callbacks => $callbacks,
                 },
                 { source_file => "$base_dir/JSON-DWIW/lib/JSON/DWIW.pm",
                   dest_file => "JSON-DWIW.rst",
                   callbacks => $callbacks,
                 },
                 { source_file => "$base_dir/DBIx/Wrapper/DBIx-Wrapper/lib/DBIx/Wrapper.pm",
                   dest_file => 'DBIx-Wrapper.rst',
                   callbacks => $callbacks,
                 },

                 { source_file => "$base_dir/DBIx/Wrapper/DBIx-Wrapper/lib/DBIx/Wrapper/Request.pm",
                   dest_file => 'DBIx-Wrapper-Request.rst',
                   callbacks => $callbacks,
                   no_toc => 1,
                 },

                ];

    my $conv = Pod::POM::View::Restructured->new;


    my $rv = $conv->convert_files($files, "$dest_dir/index.rst", 'My Big Test', $dest_dir);

    print STDERR Data::Dumper->Dump([ $rv ], [ 'rv' ]) . "\n\n";

    chdir $doc_dir or die "couldn't chdir to $doc_dir";

    my @cmd = ('make', 'html');
    system {$cmd[0]} @cmd;

}

exit 0;

###############################################################################
# Subroutines

########## begin option processing ##########
sub print_usage {
    print STDERR qq{\nUsage: @{[ ($0 =~ m{\A.*/([^/]+)\Z})[0] || $0 ]} options

    Options:

        [-h | --help]    # this help msg
\n};
}

sub check_options {
    my ($self, $opts, $required) = @_;

    if (not $opts or $opts->{help}) {
        $self->print_usage;
        exit 1;
    }

    my $opt_ok = 1;
    $required = [ ] unless $required;
    foreach my $key (@$required) {
        if (defined($opts->{$key})) {
            if (my $v = $opts->{$key}) {
                if (my $ref = ref($v)) {
                    if ($ref eq 'ARRAY' ) {
                        unless (@$v) {
                            $opt_ok = 0;
                            warn "missing required option '$key'
";
                        }
                    }
                }
            }
        }
        else {
            $opt_ok = 0;
            warn "missing required option '$key'\n";
        }
    }

    unless ($opt_ok) {
        $self->print_usage;
        exit 1;
    }

    return $opt_ok;
}

sub get_options {
    my ($self, $spec, $defaults) = @_;
    my %opts = $defaults ? %$defaults : ();
    $spec = [ ] unless $spec;

    my $process_opt = sub {
        my ($key, $val) = @_;

        if (scalar(@_) > 2) {
            $opts{$key}{$val} = $_[2];
        }
        else {
            if ( exists($opts{$key}) and (my $v = $opts{$key}) ) {
                if (my $ref = ref($v)) {
                    if ($ref eq 'ARRAY' ) {
                        push @{ $opts{$key} }, $val;
                        return 1;
                    }
                }
            }

            $opts{$key} = $val;
        }
    };

    my $opt_rv = Getopt::Long::GetOptions(map { ($_ => $process_opt) } @$spec);

    return $opt_rv ? \%opts : undef;
}
########## end option processing ##########
