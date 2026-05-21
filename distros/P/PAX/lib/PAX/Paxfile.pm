package PAX::Paxfile;

our $VERSION = '0.031';

use strict;
use warnings;

sub load_optional {
    my ($class, $path) = @_;
    $path //= 'paxfile.yml';
    return {} if !-f $path;
    return $class->load($path);
}

sub load {
    my ($class, $path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    local $/ = "\n";
    my %data;
    my $section;
    while (defined(my $line = <$fh>)) {
        chomp $line;
        $line =~ s/\r\z//;
        $line =~ s/\s+#.*\z//;
        next if $line =~ /^\s*(?:#.*)?\z/;

        if ($line =~ /^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*?)\s*\z/) {
            my ($key, $value) = ($1, $2);
            if ($value eq '') {
                $section = $key;
                $data{$section} //= [];
                next;
            }
            $data{$key} = _scalar($value);
            $section = undef;
            next;
        }

        if (defined $section && $line =~ /^\s*-\s*(.*?)\s*\z/) {
            push @{ $data{$section} }, _scalar($1);
            next;
        }

        die "unsupported paxfile.yml syntax: $line\n";
    }
    close $fh;
    return \%data;
}

sub _scalar {
    my ($value) = @_;
    $value =~ s/\A\s+|\s+\z//g;
    if ($value =~ /\A"(.*)"\z/s || $value =~ /\A'(.*)'\z/s) {
        $value = $1;
    }
    return $value;
}

1;

=pod

=head1 NAME

PAX::Paxfile - paxfile.yml parser and normalizer

=head1 SYNOPSIS

  use PAX::Paxfile;

  my $result = PAX::Paxfile->load_optional(...);

=head1 DESCRIPTION

Parses paxfile configuration, applies defaults, and presents build/run settings in one normalized structure for the CLI.

=head1 METHODS

=head2 load_optional, load

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the paxfile.yml parser and normalizer logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs paxfile.yml parser and normalizer. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects paxfile.yml parser and normalizer, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover paxfile.yml parser and normalizer.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::Paxfile -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
