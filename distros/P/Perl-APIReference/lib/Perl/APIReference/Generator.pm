package Perl::APIReference::Generator;

use 5.006;
use strict;
use warnings;
use Carp qw/croak/;
use Pod::Eventual::Simple;
use Perl::APIReference;

our $VERSION = '0.01';

sub parse {
  shift if @_ and defined $_[0] and $_[0] eq __PACKAGE__;
  my %args = @_;
  my $perl_version = $args{perl_version};
  croak("Bad perl version '$perl_version'")
    if not defined $perl_version or $perl_version !~ /^5/;
  my $file = $args{file};
  croak("Bad input file")
    if not defined $file or not -e $file;

  my $output = Pod::Eventual::Simple->read_file($file);
  croak("Failed to parse POD")
    if not defined $output;

  my $entries = _get_entries($output);

  return Perl::APIReference->_new_from_parse(
    perl_version => $perl_version,
    index => $entries,
  );
}

sub _get_entries {
  my $output = shift;
  my $in_entry = 0;
  my $entry = {};
  my $entries = {};
  # TODO add "section"
  # TODO review and robustify
  foreach my $node (@$output) {
    my $type = $node->{type};
    next if $type eq 'nonpod';
    my $command = $node->{command};

    if ($in_entry) {
      if ($type eq 'command') {
        if ($command eq 'item') {
          _finish_entry($entry, $entries);
          $in_entry = _start_entry($entry, $node);
        }
        elsif ($command eq 'back') {
          $in_entry = 0;
          _finish_entry($entry, $entries);
        }
      }
      elsif ($type eq 'text' or $type eq 'blank') {
        $entry->{text} .= $node->{content};
      }

    } # end if in entry
    else {
      if ($type eq 'command'
          and $command eq 'item')
      {
        $in_entry = _start_entry($entry, $node);
      }
    } # end if not in entry
  }
  _finish_entry($entry, $entries);
  return $entries;
}


sub _finish_entry {
  my $entry = shift;
  my $entries = shift;
  if (not defined $entry->{name} or not defined $entry->{text}) {
    return;
  }
  $entry->{text} =~ s/\s+$//;
  $entry->{text} =~ s/^\s+//;
  # TODO fix collisions!
  $entries->{$entry->{name}} = {%$entry};
  %$entry = ();
  return();
}

sub _start_entry {
  my $entry = shift;
  my $node = shift;
  my $name = $node->{content};
  $name =~ s/\s+$//;
  $name =~ /([^\n]+)/ or return;
  $name = $1;
  %$entry = (
    name => $name,
    text => '',
  );
  return(1);
}

1;
__END__

=head1 NAME

Perl::APIReference::Generator - Generate an APIReference from a perlapi.pod

=head1 SYNOPSIS

  use Perl::APIReference::Generator;
  my $api = Perl::APIReference::Generator->parse(
    file => 'perlapi.5.10.0.pod',
    perl_version => '5.10.0',
  );
  # $api is now a Perl::APIReference object

=head1 DESCRIPTION

Generate a perl API reference object from a F<perlapi.pod> file.
This is a maintainer's tool and requires L<Pod::Eventual::Simple>
and a small change to the main F<APIReference.pm> file if the
perl API version isn't supported yet.

=head1 SEE ALSO

L<Perl::APIReference>

L<perlapi>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, 2015 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
