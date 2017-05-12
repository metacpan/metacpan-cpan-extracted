use strict; use warnings;
package Swim::Plugin::cpan;
our $VERSION = '0.0.7';

package Swim::Pod;

sub block_func_cpan_head {
  my ($self, $args) = @_;
  $self->create_output($args, [ qw(name badge version) ]);
}

sub block_func_cpan_tail {
  my ($self, $args) = @_;
  my $meta = $self->meta;
  $meta->{author} = [ $meta->{author} ]
    unless ref($meta->{author}) eq 'ARRAY';
  $meta->{author}[0]{copyright} ||= $meta->{copyright};
  $self->create_output($args, [ qw(author copyright) ]);
}

sub create_output {
  my ($self, $args, $sections) = @_;

  my @args = grep $_, split /\s+/, $args;
  if (@args) {
    if (not grep /^[-+]/, @args) {
      @$sections = @args;
    }
    else {
      for my $arg (@args) {
        if ($arg =~ /^-(.*)/) {
          @$sections = grep { $_ ne $1 } @$sections;
        }
        else {
          $arg =~ s/^\+//;
          @$sections = grep { $_ ne $arg } @$sections;
          if ($arg =~ /^(see)/) {
            unshift @$sections, $arg;
          }
          else {
            push @$sections, $arg;
          }
        }
      }
    }
  }

  my @output;
  for my $section (@$sections) {
    my $method = "add_$section";
    my $output = $self->$method or next;
    push @output, $output;
  }
  return join "\n", @output;
}

sub add_name {
  my ($self) = @_;
  my $meta = $self->meta;
  my $uc = $self->option->{'pod-upper-head'};
  my $head_name = $uc ? 'NAME' : 'Name';
  (my $name = $meta->{name}) =~ s/-/::/g;
  return <<"...";
=head1 $head_name

$name - $meta->{abstract}
...
}

sub add_badge {
  my ($self) = @_;
  my $meta = $self->meta;
  my $out = '';
  while (1) {
    my $badge = $self->{meta}{badge} or return;
    $badge = [$badge] unless ref $badge;
    my $repo = $meta->{devel}{git} or return;
    $repo =~ s!.*[:/]([^/]+)/([^/]+?)(?:\.git)?$!$1/$2!
        or return;
    eval "require Swim::Plugin::badge; 1" or return;
    $out .= "\n" . $self->phrase_func_badge("@$badge $repo");
    $out =~ s/\n+\z/\n/;
    $out =~ s/\A\n+//;
    return $out;
  }
}

sub add_version {
  my ($self) = @_;
  my $uc = $self->option->{'pod-upper-head'};
  my $head_version = $uc ? 'VERSION' : 'Version';
  my $meta = $self->meta;
  (my $name = $meta->{name}) =~ s/-/::/g;
  return <<"...";
=head1 $head_version

This document describes L<$name> version B<$meta->{version}>.
...
}

sub add_see {
  my ($self, $args) = @_;
  my $meta = $self->meta;
  my $uc = $self->option->{'pod-upper-head'};
  my $head_see = $uc ? 'SEE ALSO' : 'See Also';
  my $out = '';
  if (my $see = $meta->{see}) {
    $out .= "=head1 $head_see\n\n=over\n\n";
    $see = [$see] unless ref $see;
    for (@$see) {
      $out .= "=item * L<$_>\n\n";
    }
    $out .= "=back\n";
  }
  return $out;
}

sub add_author {
  my ($self) = @_;
  my $meta = $self->meta;
  my $uc = $self->option->{'pod-upper-head'};
  my $head_author = $uc ? 'AUTHOR' : 'Author';
  my $authors = $meta->{author};
  if (@$authors > 1) {
    $head_author = $uc ? 'AUTHORS' : 'Authors';
  }
  my $out .= "=head1 $head_author\n\n";
  for my $author (@$authors) {
    $out .= "$author->{name} <$author->{email}>\n\n";
  }
  chomp $out;
  return $out;
}

sub add_copyright {
  my ($self, $args) = @_;
  my $meta = $self->meta;
  my $uc = $self->option->{'pod-upper-head'};
  my $head_copyright = $uc
    ? 'COPYRIGHT AND LICENSE'
    : 'Copyright and License';
  my $authors = $meta->{author};
  my $out = "=head1 $head_copyright\n\n";
  for my $author (@$authors) {
    if ($author->{copyright}) {
      $out .= "Copyright $author->{copyright}. $author->{name}.\n\n";
    }
  }

  return $out . <<'...';
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
...
}

1;
