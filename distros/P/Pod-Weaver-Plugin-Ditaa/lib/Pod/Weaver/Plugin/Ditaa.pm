package Pod::Weaver::Plugin::Ditaa;
$Pod::Weaver::Plugin::Ditaa::VERSION = '0.001006';
# ABSTRACT: include ditaa diagrams in your pod

use Moose;
with 'Pod::Weaver::Role::Dialect';

sub translate_dialect {
   Pod::Elemental::Transformer::Ditaa->new->transform_node($_[1])
}

package Pod::Elemental::Transformer::Ditaa {
$Pod::Elemental::Transformer::Ditaa::VERSION = '0.001006';
use Moose;
   with 'Pod::Elemental::Transformer';

   use Capture::Tiny 'capture';
   use autodie;
   use File::Temp;
   use IPC::System::Simple 'system';
   use IO::All;
   use MIME::Base64;
   use namespace::clean;

   sub transform_node {
      my ($self, $node) = @_;
      my $children = $node->children;

    my $x = 0;

    for (my $i = 0 ; $i < @$children; $i++) {
         my $para = $children->[$i];
         next
           unless $para->isa('Pod::Elemental::Element::Pod5::Region')
           and !$para->is_pod
           and $para->format_name eq 'ditaa';

         my $length = @{$para->children};
         confess 'ditaa transformer expects exec region to contain 1 Data para'
           unless $length == 1
           and $para->children->[0]->isa('Pod::Elemental::Element::Pod5::Data');

         $x++;
         my $text = $para->children->[0]->content;

         my %meta = ( label => "Figure $x" );;
         my ($meta, $rest) = split /\n\n/, $text, 2;

         if ($rest) {
            %meta = map { split qr/\s*:\s*/, $_, 2 } split "\n", $meta;
            $text = $rest;
         }

         my $new_doc = $self->_render_figure(
            %meta,
            text => $text,
            b64 => $self->_text_to_b64image(
               $text,
               split qr/\s+/, $para->content || '',
            ),
         );

         splice @$children, $i, 1, @{$new_doc->children};
      }

      return $node;
   }

   sub _text_to_b64image {
      my ($self, $text, @flags) = @_;

      my $tmp_text = tmpnam();
      my $tmp_img  = tmpnam() . '.png';
      open my $fh, '>', $tmp_text;
      print {$fh} $text;
      close $fh;

      my @cmd = ('ditaa', @flags, '-o', $tmp_text, $tmp_img);
      print STDERR join q( ), @cmd
         if $ENV{DITAA_TRACE};

      my $merged_out = capture { system @cmd };
      print STDERR $merged_out if $ENV{DITAA_TRACE};
      my $image = encode_base64(io->file($tmp_img)->binary->all, '');
      unlink $tmp_text unless $ENV{DITAA_TRACE} && $ENV{DITAA_TRACE} =~ m/keep/;
      unlink $tmp_img unless $ENV{DITAA_TRACE} && $ENV{DITAA_TRACE} =~ m/keep/;

      return $image
   }

   sub _render_figure {
      my ($self, %args) = @_;

      my $new_doc = Pod::Elemental->read_string(
         "\n\n=begin text\n\n$args{label}\n\n" .
         "$args{text}\n\n=end text\n\n" .
          qq(\n\n=begin html\n\n) .
             qq(<p><i>$args{label}</i>) .
             qq(<img src="data:image/png;base64,$args{b64}"></img></p>\n\n) .
          qq(=end html\n\n)
      );
      Pod::Elemental::Transformer::Pod5->transform_node($new_doc);
      shift @{$new_doc->children}
        while $new_doc->children->[0]
        ->isa('Pod::Elemental::Element::Pod5::Nonpod');

      return $new_doc
   }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Ditaa - include ditaa diagrams in your pod

=head1 VERSION

version 0.001006

=head1 SYNOPSIS

In your F<weaver.ini>:

 [@Default]
 [-Ditaa]

In the pod of one of your modules:

 =head1 HOW IT WORKS

 =begin ditaa

 label: How it works

    +--------+   +-------+    +-------+
    |        | --+ ditaa +--> |       |
    |  Text  |   +-------+    |diagram|
    |Document|   |!magic!|    |       |
    |     {d}|   |       |    |       |
    +---+----+   +-------+    +-------+
        :                         ^
        |       Lots of work      |
        +-------------------------+

 =end ditaa

=head1 DESCRIPTION

It has often been said that a picture is worth a thousand words.  I find that
sometimes a diagram truly can illuminate your design.  This L<Pod::Weaver>
plugin allows you to put L<ditaa|http://ditaa.sourceforge.net/> diagrams in your
pod and render the image for an html view.  In text mode it merely uses the text
diagram directly.

Note that you may put a C<label: Foo> at the top of your diagram, but if you
do not you will get a numbered label in the format C<Figure $i>.

=head1 IN ACTION

=begin text

How it works

   +--------+   +-------+    +-------+
   |        | --+ ditaa +--> |       |
   |  Text  |   +-------+    |diagram|
   |Document|   |!magic!|    |       |
   |     {d}|   |       |    |       |
   +---+----+   +-------+    +-------+
       :                         ^
       |       Lots of work      |
       +-------------------------+

=end text

=for html <p><i>How it works</i><img src="data:image/png;base64,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"></img></p>

=head1 SYNTAX

The ditaa syntax L<is documented here|http://ditaa.sourceforge.net/#usage>.

=head1 PASSING FLAGS TO DITAA

 =begin ditaa -r -S

 label: Passing Flags

    +--------+
    |        |
    |  Test  |
    |        |
    +---+----+

 =end ditaa

=begin text

Passing Flags

    +--------+
    |        |
    |  Test  |
    |        |
    +---+----+

=end text

=for html <p><i>Passing Flags</i><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAALQAAAB+CAIAAAAC3Ky3AAADsUlEQVR42u3dv0sycRzAcSOR6IcIGYYoJEQ0ODg01aVCDg4ODS5FETU1BK0Njg39CQ5BBkWCQy6Km5RBgYOQkENBFJX9gCIcrIae5wP3oE/PYy3PNTx37/d2d17g19fd974gafpB9EkmhoDAQeAgcBA4CBwEDgIHgYPAQeAgAgeBg8BB4CBwEDgIHAQOAgeBgwgcBA4CB4GDwEHgIHAQOAgcBA4icBA4CBwEjhaVy+WZmZnBwUGbzWYyUvJ+h4eHFxcXz8/PwdGidDotY7S2tlapVJ6engx1fcv7lQtjZWVFRqBQKIDjQ9Vq1W635/N5g88CyWRyYGCgXq+Do9nq6qpMKDwiSIqibG1tgePDiORyOWRI8Xhcw+tEDzhkrn14eECGVCwWfT4fOH57DyYW5L+SBYs8doADHK1XLnIfBQc4vn00wAEOcIADHAQOcIADHOAABzjAAQ5wgAMc4AAHOBgOcIADHOAABzi+B8fX3/bW5I+DQw93Ds0/S3CAAxwGxlEoFEKhUE9Pj9VqHR0dzWQyjUNXV1dzc3Mul8tisTgcjqmpqf39/ZYTFjh0iCOfz5vNZr/ff3Z29vj4ODs7K6/Z3NxUjwYCAdnc3d19eXm5ubnZ3t4eHx/nzmEUHMJCdh4fH6ubd3d3sjk0NKRudnV1yabcLd7f35lWDIejs7Pz71VMe3u7elRRFHWPvMzn8y0vL19fX4PDWDju7+9bnnJ5eTk/P+92uxtuhAs4jIIjGAzKzlQq9fW5z8/POzs78kqZaBo729rawKFnHAcHB7IS8Xg8R0dHr6+vFxcXiURibGxMPToxMSFPo3JfeXt7y2azcrqsaxrnOp1O2XNycgIO3S5li8Xi5ORkb2+vLFvk856ent7b22usZaLRaF9fnwCSyWVhYeH29rZx4sbGhqxvWcrqAYeRRwMc4AAHOMBB4AAHOMABDnCAAxzgAAc4wAEOcICD4QAHOMABDnCAAxzgAAc4wPGv1Wq17u5ucICjRfzv8z+Ta8Vov870WaVSyev1gqPZyMgIP9OklkgkotEoOJrFYrGlpSVkSJFIZH19HRzNTk9PbTZbuVw2uAy5fdrtdg1nWJ08ysXj8f7+/mQyqeHP3/1fixQZAblC0um0lk/6uhmgXC6nKIrZbDYZr46OjnA4fHh4qPEykHmawEHgIHAQOAgcBA4CB4GDwEHgIAIHgYPAQeAgcBA4CBwEDgIHgYMIHAQOAgeBg8BB4CBwEDgIHAQOInAQOAgcpGE/AbCDGU/FtxzJAAAAAElFTkSuQmCC"></img></p>

To pass flags to C<ditaa> simply append the flags to the C<< =begin ditaa >>
directive.

=head1 DEBUGGING

Set the C<DITAA_TRACE> env var and you'll see all of the commands that this
plugin runs printed to C<STDERR>.  If you set the env var to C<keep> the
temporary files referenced in the command will not automatically be deleted, so
you can ensure that the text and image diagrams were created correctly.

=head1 PERL SUPPORT POLICY

Because this module is geared towards helping release code, as opposed to
helping run code, I only aim at supporting the last 3 releases of Perl.  So for
example, at the time of writing that would be 5.22, 5.20, and 5.18.  As an
author who is developing against Perl and using this to release modules, you can
use either L<perlbrew|http://perlbrew.pl/> or
L<plenv|https://github.com/tokuhirom/plenv> to get a more recent perl for
building releases.

Don't bother sending patches to support older versions; I could probably support
5.8 if I wanted, but this is more so that I can continue to use new perl
features.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
