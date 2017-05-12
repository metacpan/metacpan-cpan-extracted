package Pod::Section;

use warnings;
use strict;
use IO::String;
use Pod::Abstract;
use Pod::Perldoc;
use Pod::Perldoc::ToPod;
use base qw/Exporter/;
use Carp qw/croak/;

our @EXPORT_OK = qw/select_podsection/;

sub select_podsection {
  my ($module, @functions) = @_;
  my $pod = Pod::Perldoc->new;
  my @path = $pod->grand_search_init([$module]) or croak "Cannot find $module";
  my $parser = Pod::Perldoc::ToPod->new;
  my $fh = IO::String->new;
  $parser->parse_from_file(@path, $fh);
  seek $fh, 0, 0;
  my $pa = Pod::Abstract->load_file($fh);

  my @function_node;
  my $func_regexp = join "|", @functions;
  $func_regexp    = qr{((^($func_regexp))|[^a-zA-Z_0-9_\$]($func_regexp)|(\->($func_regexp))|(\s($func_regexp)))\b};
  my @try = ($pa, $func_regexp);
  if ($module eq 'Carp') {
    @function_node = _try_from_carp(@try);
  } else {
  CHECK: {
      @function_node = _try_head(2, @try)      and last;
      @function_node = _try_head_item(2, @try) and last;
      @function_node = _try_head_item(1, @try) and last;
      @function_node = _try_head(3, @try)      and last;
      @function_node = _try_head_item(3, @try) and last;
      @function_node = _try_head(4, @try)      and last;
      @function_node = _try_head_item(4, @try) and last;
      @function_node = _try_head(1, @try)      and last;
    }
  }
  my @pod;
  foreach my $pod (@function_node) {
    $pod =~s{L</(.+?)>}{L<$module/$1>}gs;
    push @pod, $pod;
  }
  return wantarray ? @pod : join "", @pod;
}

sub _try_head_item {
  my ($n, $pa, $regexp) = @_;
  my @target;
  push @target, "/head$_" for 1 .. $n;
  my $target = join '', @target;
  my @nodes = $pa->select("$target/over/item");
  my @function_node;
  foreach my $node (@nodes) {
    foreach my $f ($node->param('label')->children) {
      if ($f->text =~ $regexp) {
        push @function_node, $node->pod;
      }
    }
  }
  return @function_node;
}

sub _try_head {
  my ($n, $pa, $regexp) = @_;
  my @target;
  push @target, "/head$_" for 1 .. $n;
  my $target = join '', @target;
  my @nodes = $pa->select($target);
  my @function_node;
  foreach my $node (@nodes) {
    foreach my $f ($node->param('heading')->children) {
      if ($f->text =~ $regexp) {
        push @function_node, $node->pod;
      }
    }
  }
  return @function_node;
}

sub _try_from_carp {
  my ($pa, $regexp) = @_;
  my @nodes = $pa->select('/head1');
  my @function_node;
  foreach my $node (@nodes) {
    foreach my $f ($node->param('heading')->children) {
      if ($f->text =~ m{NAME}) {
        my $pod = $node->pod;
        $pod =~ s{=head1 NAME}{};
        $pod =~ s{^(\w+)[\s\t]*(.+)$}{=head2 $1\n\n$2}gm;
        if ($pod =~ $regexp) {
          push @function_node, $pod;
        }
      }
    }
  }
  return @function_node;
}

=head1 NAME

Pod::Section - select specified section from Module's POD

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Pod::Section qw/select_podsection/;

    my @function_pods = select_podsection($module, @functions);
    my @section_pods = select_podsection($module, @sections);

In scalar context, pod is joined as one scalar.

    my $function_pods = select_podsection($module, @functions);
    my $section_pods = select_podsection($module, @sections);

use podsection on shell

    % podsection Catalyst req res
    $c->req
      Returns the current Catalyst::Request object, giving access to
      information about the current client request (including parameters,
      cookies, HTTP headers, etc.). See Catalyst::Request.
    
    $c->res
      Returns the current Catalyst::Response object, see there for details.

=head1 EXPORT

=head2 select_podsection

See SYNOPSIS.

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 BUGS

The way to search section is poor. This cannot find section correctly in some modules.

Please report any bugs or feature requests to C<bug-pod-section at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Section>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::Section
    perldoc podsection

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Section>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pod-Section>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Pod-Section>

=item * Search CPAN

L<http://search.cpan.org/dist/Pod-Section/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 SEE ALSO

=head2 Pod::Select

This also select section, but cannot search function/method explanation.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Pod::Section
