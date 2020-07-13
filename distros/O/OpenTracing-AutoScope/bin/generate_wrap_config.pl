#!/usr/bin/env perl
package OpenTracing::WrapScope::ConfigGenerator;
use strict;
use warnings;
use autodie;
use feature qw/say state/;
use Carp qw/croak/;
use Getopt::Long qw/GetOptionsFromArray/;
use IO::File;
use List::MoreUtils qw/notall/;
use List::Util qw/uniq/;
use PPI;
use Pod::Usage qw/pod2usage/;
use YAML::XS;

exit run(@ARGV) unless caller;

sub run {
    GetOptionsFromArray(\@_,
        'spec=s'    => \my $spec_file,
        'file=s'    => \my @files,
        'ignore=s'  => \my @ignore,
        'include=s' => \my @include,
        'exclude=s' => \my @exclude,
        'filter=s'  => \my @filters,
        'out=s'     => \my $output_file,
        'help'      => \my $help,
    ) or pod2usage (
        -verbose   => 1,
        -noperldoc => 1,
        -msg       => 'Invalid options',
    );
    pod2usage -verbose => 1, -noperldoc => 1 if $help;

    my %args;
    %args = %{ YAML::XS::LoadFile($spec_file) } if defined $spec_file;
    push @{ $args{files} },   @files;
    push @{ $args{ignore} },  @ignore;
    push @{ $args{include} }, @include;
    push @{ $args{exclude} }, @exclude;
    push @{ $args{filters} }, @filters;

    my @subs = OpenTracing::WrapScope::ConfigGenerator::examine_files(%args);

    open my $fh_out, '>', $output_file if $output_file;
    $fh_out //= \*STDOUT;

    say {$fh_out} $_ foreach @subs;

    return 0;
}


sub examine_files {
    my %args         = @_;
    my $files_base   = $args{files} // [];
    my $files_ignore = $args{ignore} // [];
    my $subs_include = $args{include} // [];
    my $subs_exclude = $args{exclude} // [];
    my $filters      = $args{filters} // [];

    my @files = map { glob } @$files_base;
    my %file_ignored = map { $_ => undef } map { glob } @$files_ignore;
    my %sub_excluded = map { $_ => undef } @$subs_exclude;

    state $FILTERS = {
        exclude_private => sub {
            my $sub = (split /'|::/, $_[0])[-1];
            return index($sub, '_') != 0;
        },
    };

    my @subs    = @$subs_include;
    my @filters = map { $FILTERS->{$_} or croak "No such filter: $_" } @$filters;
    foreach my $file (@files) {
        next if exists $file_ignored{$file};

        foreach my $sub (list_subs($file)) {
            next if exists $sub_excluded{$sub};
            next if notall { $_->($sub) } @filters;
            push @subs, $sub;
        }
    }
    return uniq @subs;
}

sub list_subs {
    my ($filename) = @_;

    my $doc  = PPI::Document->new($filename);
    my $subs = $doc->find('PPI::Statement::Sub');
    return if not $subs;

    my @subs;
    foreach my $sub (@$subs) {
        if ($sub->name =~ /'|::/) { # qualified
            push @subs, $sub->name;
        }
        else {
            my $pkg = _detect_package($sub);
            $pkg = $pkg ? $pkg->namespace : 'main';
            push @subs, $pkg . '::' . $sub->name;
        }
    }
    return @subs;
}

sub _detect_package {
    my ($elem) = @_;
    return unless $elem;
    return $elem if $elem->isa('PPI::Statement::Package');

    my $prev = $elem;
    while ($prev = $prev->sprevious_sibling) {
        return $prev if $prev->isa('PPI::Statement::Package');
    }
    return _detect_package($elem->parent);
}

1;
__END__
=pod

=head1 NAME

generate_wrap_config.pl - generate input for OpenTracing::WrapScope

=head1 SYNOPSIS

  generate_wrap_config.pl --out wrapscope.conf --file 'lib/*.pm'

=head1 OPTIONS

=head2 --file $file_pattern

Shell file pattern for files to include in the search.
Can be specified multiple times.

=head2 --ignore $file_pattern

Shell file pattern for files to ignore.
Can be specified multiple times.

=head2 --include $subroutine

A subroutine name to unconditionally include in the results.
Overrides all other settings.
Can be specified multiple times.

=head2 --exclude $subroutine

A subroutine name to remove from the results.
Can be specified multiple times.

=head2 --filter $filter_name

A filter to apply. Currently, the only supported filter is B<exclude_private>,
which removes all subroutines starting with an underscore.
Can be specified multiple times.

=head2 --out $filename

The filename where the resulting config file should be written.
If this argument is not specified,
results will be printed to standard output.

=head2 --spec $filename

The filename of a YAML file which contains options for this program in hash form.
The keys correspond directly to options, most options can be specified multiple
times and their values should be arrays in the YAML file.

For example, given this file:

  wrapscope_gen_config.yaml

  file: [ 'bin/*.pl', 'lib/*.pm' ]
  filter: [ 'exclude_private' ]
  ignore: [ 'Private*' ]
  out: wrapscope_config.txt

calling:

  generate_wrap_config.pl --spec wrapscope_gen_config.yaml

is equivalent to:

  generate_wrap_config.pl \
    --file 'bin/*.pl' \
    --file 'lib/*.pm' \
    --filter exclude_private \
    --out wrapscope_config.txt \
    --ignore 'Private*'

if other options are specified alongside a spec file, they will be merged.

=head2 --help

Show this help.

=cut
