package Pod::Elemental::Transformer::Pod5;
# ABSTRACT: the default, minimal semantics of Perl5's pod element hierarchy
$Pod::Elemental::Transformer::Pod5::VERSION = '0.103004';
use Moose;
with 'Pod::Elemental::Transformer';

#pod =head1 SYNOPSIS
#pod
#pod   Pod::Elemental::Transformer::Pod5->new->transform_node($pod_elem_document);
#pod
#pod ...and that's it.
#pod
#pod =head1 OVERVIEW
#pod
#pod The Pod5 transformer is meant to be used to convert the result of a "stock"
#pod Pod::Elemental::Document into something simpler to work with.  It assumes that
#pod the document conforms more or less to the convetions laid out in L<perlpod> and
#pod L<perlpodspec>.  It is not very strict, and makes very few assumptions,
#pod described here:
#pod
#pod =over 4
#pod
#pod =item * =begin/=end and =for enclose or produce regions within the document
#pod
#pod =item * regions are associated with format names; format names that begin with a colon enclose more pod-like content
#pod
#pod =item * regions nest strictly; all inner regions must end before outer regions
#pod
#pod =item * paragraphs in non-pod regions are "data" paragraphs
#pod
#pod =item * non-data paragraphs that start with spaces are "verbatim" paragraphs
#pod
#pod =item * groups of data or verbatim paragraphs can be consolodated
#pod
#pod =back
#pod
#pod Further, all elements are replaced with equivalent elements that perform the
#pod L<Pod::Elemental::Autoblank> role, so all "blank" events can be removed form
#pod the tree and ignored.
#pod
#pod =head1 CONFIGURATION
#pod
#pod None.  For now, it just does the same thing every time with no configuration or
#pod options.
#pod
#pod =cut

use namespace::autoclean;

use Pod::Elemental::Document;
use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Element::Pod5::Data;
use Pod::Elemental::Element::Pod5::Nonpod;
use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Elemental::Element::Pod5::Verbatim;
use Pod::Elemental::Element::Pod5::Region;

use Pod::Elemental::Selectors -all;

sub _gen_class { "Pod::Elemental::Element::Generic::$_[1]" }
sub _class     { "Pod::Elemental::Element::Pod5::$_[1]" }

sub _region_para_parts {
  my ($self, $para) = @_;

  my ($colon, $target, $content, $nl) = $para->content =~ m/
    \A
    (:)?
    (\S+)
    (?:\s+(.+))?
    (\s+)\z
  /xsm;

  confess("=begin cannot be parsed") unless defined $target;

  $colon   ||= '';
  $content ||= '';

  return ($colon, $target, "$content$nl");
}

sub __extract_region {
  my ($self, $name, $in_paras) = @_;

  my %nest = ($name => 1);
  my @region_paras;

  REGION_PARA: while (my $region_para = shift @$in_paras) {
    if (s_command([ qw(begin end) ], $region_para)) {
      my ($r_colon, $r_target) = $self->_region_para_parts($region_para);

      for ($nest{ "$r_colon$r_target" }) {
        $_ += $region_para->command eq 'begin' ? 1 : -1;

        confess("=end $r_colon$r_target without matching begin") if $_ < 0;

        last REGION_PARA if !$_ and "$r_colon$r_target" eq $name;
      }
    }

    push @region_paras, $region_para;
  };

  return \@region_paras;
}

sub _upgrade_nonpod {
  my ($self, $in_paras) = @_;

  @$in_paras = map {
    $_->isa( $self->_gen_class('Nonpod') )
      ? $self->_class('Nonpod')->new({
          content => $_->content,
        })
      : $_
  } @$in_paras;
}

sub _collect_regions {
  my ($self, $in_paras) = @_;

  my @out_paras;

  my $s_region = s_command([ qw(begin for) ]);
  my $region_class = $self->_class('Region');

  PARA: while (my $para = shift @{ $in_paras }) {
    push(@out_paras, $para), next PARA unless $s_region->($para);

    if ($para->command eq 'for') {
      # factor out (for vertical space if nothing else) -- rjbs, 2009-10-20
      my ($colon, $target, $content) = $self->_region_para_parts($para);

      my $region = $region_class->new({
        children    => [
          $self->_gen_class('Text')->new({ content => $content }),
        ],
        format_name => $target,
        is_pod      => $colon ? 1 : 0,
        content     => "\n",
      });

      push @out_paras, $region;
      next PARA;
    }

    my ($colon, $target, $content) = $self->_region_para_parts($para);

    my $region_paras = $self->__extract_region("$colon$target", $in_paras);

    shift @$region_paras while s_blank($region_paras->[0]);
    pop @$region_paras   while @$region_paras && s_blank($region_paras->[-1]);

    my $region = $region_class->new({
      children    => $self->_collect_regions($region_paras),
      format_name => $target,
      is_pod      => $colon ? 1 : 0,
      content     => $content,
    });

    push @out_paras, $region;
  }

  @$in_paras = @out_paras;

  return $in_paras;
}

sub _strip_markers {
  my ($self, $in_paras) = @_;

  @$in_paras = grep { ! s_command([ qw(cut pod) ], $_) } @$in_paras;
  shift @$in_paras while @$in_paras and s_blank($in_paras->[0]);
}

sub _autotype_paras {
  my ($self, $paras, $is_pod) = @_;

  @$paras = map {
    my $elem = $_;
    if ($elem->isa( $self->_gen_class('Text') )) {
      my $class = $is_pod
                ? $elem->content =~ /\A\s/
                  ? $self->_class('Verbatim')
                  : $self->_class('Ordinary')
                : $self->_class('Data');

      $elem = $class->new({ content => $elem->content });
    }

    if ($elem->isa( $self->_class('Region') )) {
      $self->_autotype_paras( $elem->children, $elem->is_pod );
    }

    if ($elem->isa( $self->_gen_class('Command') )) {
      $elem = $self->_class('Command')->new({
        command => $elem->command,
        content => $elem->content,
      });
    }

    $elem;

  } @$paras;
}

sub __text_class {
  my ($self, $para) = @_;

  for my $type (qw(Verbatim Data)) {
    my $class = $self->_class($type);
    return $class if $para->isa($class);
  }

  return;
}

sub _collect_runs {
  my ($self, $paras) = @_;

  $self->_collect_runs($_->children)
    foreach grep { $_->isa( $self->_class('Region') ) } @$paras;

  PASS: for my $start (0 .. $#$paras) {
    last PASS if $#$paras - $start < 2; # we need X..Blank..X at minimum

    my $class = $self->__text_class( $paras->[ $start ] );
    next PASS unless $class;

    my @to_collect = ($start);
    NEXT: for my $next ($start+1 .. $#$paras) {
      if ($paras->[ $next ]->isa($class) or s_blank($paras->[ $next ])) {
        push @to_collect, $next;
        next NEXT;
      }

      last NEXT;
    }

    pop @to_collect while s_blank($paras->[ $to_collect[ -1 ] ]);

    next PASS unless @to_collect >= 3;

    my $new_content = join(qq{\n},
      map { $_ = $_->content; chomp; $_ } @$paras[@to_collect]
    );

    splice @$paras, $start, scalar(@to_collect), $class->new({
      content => $new_content,
    });

    redo PASS;
  }

  my @out;
  PASS: for (my $i = 0; $i < @$paras; $i++) {
    my $this = $paras->[$i];
    push @out, $this;

    while ($paras->[$i+1] and s_blank($paras->[$i+1])) {
      $i++;
      next unless $this->isa( $self->_class('Data') );
      $this->content( $this->content . $paras->[$i]->content );
    }
  }

  # @out = grep { not s_blank($_) } @$paras;

  # I really don't feel bad about rewriting in place by the time we get here.
  # These are private methods, and I know the consequence of calling them.
  # Nobody else should be.  So there.  -- rjbs, 2009-10-17
  @$paras = @out;
  return \@out;
}

sub transform_node {
  my ($self, $node) = @_;

  $self->_strip_markers($node->children);
  $self->_upgrade_nonpod($node->children);
  $self->_collect_regions($node->children);
  $self->_autotype_paras($node->children, 1);
  $self->_collect_runs($node->children);

  return $node;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Transformer::Pod5 - the default, minimal semantics of Perl5's pod element hierarchy

=head1 VERSION

version 0.103004

=head1 SYNOPSIS

  Pod::Elemental::Transformer::Pod5->new->transform_node($pod_elem_document);

...and that's it.

=head1 OVERVIEW

The Pod5 transformer is meant to be used to convert the result of a "stock"
Pod::Elemental::Document into something simpler to work with.  It assumes that
the document conforms more or less to the convetions laid out in L<perlpod> and
L<perlpodspec>.  It is not very strict, and makes very few assumptions,
described here:

=over 4

=item * =begin/=end and =for enclose or produce regions within the document

=item * regions are associated with format names; format names that begin with a colon enclose more pod-like content

=item * regions nest strictly; all inner regions must end before outer regions

=item * paragraphs in non-pod regions are "data" paragraphs

=item * non-data paragraphs that start with spaces are "verbatim" paragraphs

=item * groups of data or verbatim paragraphs can be consolodated

=back

Further, all elements are replaced with equivalent elements that perform the
L<Pod::Elemental::Autoblank> role, so all "blank" events can be removed form
the tree and ignored.

=head1 CONFIGURATION

None.  For now, it just does the same thing every time with no configuration or
options.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
