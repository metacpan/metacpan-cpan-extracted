#!/usr/bin/env perl

package Pod::Extract;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans :chars);
use CLI::Simple::Utils qw(choose);
use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use IO::Scalar;
use Module::Load;

our $VERSION = '1.0.0';

use Readonly;

Readonly our $POD_START => qr/^=(?:pod|begin)/xsm;
Readonly our $POD_END   => qr/^=(?:cut|end)/xsm;

our @EXPORT = qw(extract_pod);

use parent qw(CLI::Simple Exporter);

caller or __PACKAGE__->main();

########################################################################
sub extract_pod {
########################################################################
  my ( $fh, $options ) = @_;

  $options //= {};

  my %pod_sections;

  my $start_of_pod = <<'START_OF_POD';

__END__

START_OF_POD

  my $pod = "=pod\n";

  my $code = $EMPTY;

  my $pod_out = IO::Scalar->new( \$pod );

  my $code_out = IO::Scalar->new( \$code );

  my $in_pod = $FALSE;

  while ( my $line = <$fh> ) {

    if ( $line =~ $POD_START ) {
      $in_pod = $TRUE;
      next;
    }

    if ( $line =~ $POD_END ) {
      $in_pod = $FALSE;

      next;
    }

    if ( !$in_pod ) {
      print {$code_out} $line;
    }
    else {
      print {$pod_out} $line;
    }

    if ( $line =~ /^=([\S]+)\s+(.*)\s+$/xsm ) {

      my ( $section, $title ) = ( $1, $2 );

      next if $section !~ /head/xsm;

      $pod_sections{$section} //= [];

      push @{ $pod_sections{$section} }, $title;
    }
    else {
      next;
    }
  }

  print {$pod_out} "=cut\n";

  close $pod_out;

  close $code_out;

  my %result = (
    pod   => $pod,
    code  => $code,
    stats => \%pod_sections,
  );

  if ( $options->{markdown} ) {
    eval { load 'Pod::Markdown'; };

    if ( !$EVAL_ERROR ) {
      my $markdown = q{};

      my $url_prefix = $options->{'url-prefix'} // $options->{url_prefix};

      if ( $url_prefix && $url_prefix !~ /\/$/xsm ) {
        $url_prefix = $url_prefix . q{/};
      }

      my $parser = Pod::Markdown->new( $url_prefix ? ( perldoc_url_prefix => $url_prefix ) : () );

      $parser->output_string( \$markdown );
      $parser->parse_string_document($pod);

      $result{markdown} = $markdown;
    }
    else {
      warn "WARN: Pod::Markdown unavailable.\n";
    }
  }

  return wantarray ? ( $pod, $code, \%pod_sections, $result{markdown} ? $result{markdown} : () ) : \%result;
}

########################################################################
sub _write_file {
########################################################################
  my ( $file, $text ) = @_;

  my $fh;

  if ( !ref $file && !fileno $file ) {

    open $fh, '>', $file ## no critic (RequireBriefOpen)
      or croak "could not open $file for writing";
  }
  else {
    $fh = $file;
  }

  print {$fh} $text;

  return close $fh;
}

########################################################################
sub cmd_check {
########################################################################
  my ($self) = @_;

  warn "Coming soon...not yet implemented!\n";

  return $SUCCESS;
}

########################################################################
sub cmd_extract {
########################################################################
  my ($self) = @_;

  my $infile = $self->get_infile;

  my $fh = choose {
    if ($infile) {
      open my $fh, '<', $infile
        or croak "could not open $infile";

      return $fh;
    }

    return *STDIN;
  };

  my %options = (
    markdown     => $self->get_markdown,
    'url-prefix' => $self->get_url_prefix,
  );

  my $result = extract_pod( $fh, \%options );

  my $outfile = $self->get_outfile // *STDOUT;

  if ( $self->get_markdown && $result->{markdown} ) {
    _write_file( $outfile, $result->{markdown} );
  }
  else {
    _write_file( $outfile, $result->{code} );

    my $podfile = $self->get_podfile // *STDERR;

    _write_file( $podfile, $result->{pod} );
  }

  return $SUCCESS;
}

########################################################################
sub main {
########################################################################
  my @option_specs = qw(
    help|h
    infile|i=s
    outfile|o=s
    podfile|p=s
    markdown|m
    url-prefix|u=s
  );

  my %commands = (
    extract => \&cmd_extract,
    default => \&cmd_extract,
    check   => \&cmd_check,
  );

  return Pod::Extract->new(
    commands     => \%commands,
    option_specs => \@option_specs,
  )->run;
}

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

Pod::Extract - remove pod from file

=head1 SYNOPSIS

 podextract -i path/to/module -o path/to/module-without-pod -p path/to/pod

or use the module...

 use Pod::Extract;

 open my $fh, '<', 'myfile.pm';

 my ($pod, $code, $sections) = extract_pod($fh);

=head1 DESCRIPTION

Parses a Perl script or module looking for pod. Returns the pod and
code in separate objects or prints the code and pod to two different
locations. By default pod is written to STDERR, code to STDOUT.

Instead of returning pod, use the C<--markdown> option to return
markdown.

This module does not attempt to check the validity of the pod
syntax. It's just a simple parser that looks for what might pass as
pod within your code. If you've done something odd, don't expect this
module to figure it out.

This module was a result of refactoring lots of Perl modules that had
pod scattered about the module on the basis of Perl Best Practices
recommendations to place pod at the end of a module. In addition to
the obvious standardization this provides for an application, it was
an eye-opening experience finding all the pod errors. ;-)

I<This module has very few dependencies (and very few features). If
you want real pod parsing, use L<Pod::Simple>>.
 
=head2 Options

 --infile, -i      input file
 --outfile, -o     file to write code to 
 --markdown, -m    return markdown
 --podfile, -p     file to write pod to
 --url-prefix, -u  URL prefix (see Pod::Markdown)

=head2 Commands

 extract (default)
 check

=head2 Notes
 
 If --infile is not specified, script reads from stdin
 If --outfile is not specified, code is written to stdout
 If --podfile is not specified, pod is written to stderr

=head1 METHODS AND SUBROUTINES

=head2 extract_pod

 extract_pod( file-handle ) 

In list context returns a three element list consisting of the pod,
the code and a hash with section names. In scalar context returns a
hash consisting of the keys C<pod>, C<code> and C<sections>
representing the same objects in list context.

=over 5

=item pod

The pod text contained in the script or module in the order it was
encountered.

=item code

The code text with the pod removed.

=item sections

A hash reference containing the section and section titles.

=back

=head1 AUTHOR

Rob Lauer - rlauer@treasurersbriefcase.com

=head1 SEE OTHER

L<Pod::Markdown>, L<Pod::Simple>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
