=head1 NAME

Perl::Strip - reduce file size by stripping whitespace, comments, pod etc.

=head1 SYNOPSIS

   use Perl::Strip;

=head1 DESCRIPTION

This module transforms perl sources into a more compact format. It does
this by removing most whitespace, comments, pod, and by some other means.

The resulting code looks obfuscated, but perl (and the deparser) don't
have any problems with that. Depending on the source file you can expect
about 30-60% "compression".

The main target for this module is low-diskspace environments, such as
L<App::Staticperl>, boot floppy/CDs/flash environments and so on.

See also the commandline utility L<perlstrip>.

=head1 METHODS

The C<Perl::Strip> class is a subclsass of L<PPI::Transform>, and as such
inherits all of it's methods, even the ones not documented here.

=over 4

=cut

package Perl::Strip;

our $VERSION = '1.1';
our $CACHE_VERSION = 2;

use common::sense;

use PPI;

use base PPI::Transform::;

=item my $transform = new Perl::Strip key => value...

Creates a new Perl::Strip transform object. It supports the following
parameters:

=over 4
 
=item optimise_size => $bool

By default, this module optimises I<compressability>, not raw size. This
switch changes that (and makes it slower).

=item keep_nl => $bool

By default, whitespace will either be stripped or replaced by a space. If
this option is enabled, then newlines will not be removed. This has the
advantage of keeping line number information intact (e.g. for backtraces),
but of course doesn't compress as well.

=item cache => $path

Since this module can take a very long time (minutes for the larger files
in the perl distribution), it can utilise a cache directory. The directory
will be created if it doesn't exist, and can be deleted at any time.

=back

=cut

# PPI::Transform compatible
sub document {
   my ($self, $doc) = @_;

   $self->{optimise_size} = 1; # more research is needed

   # special stripping for unicore/ files
   if (eval { $doc->child (1)->content =~ /^# .* (build by mktables|machine-generated .*mktables) / }) {

      for my $heredoc (@{ $doc->find (PPI::Token::HereDoc::) }) {
         my $src = join "", $heredoc->heredoc;

         # special stripping for unicore swashes and properties
         # much more could be done by going binary
         for ($src) {
            s/^(?:0*([0-9a-fA-F]+))?\t(?:0*([0-9a-fA-F]+))?\t(?:0*([0-9a-fA-F]+))?/$1\t$2\t$3/gm
               if $self->{optimise_size};

#            s{
#               ^([0-9a-fA-F]+)\t([0-9a-fA-F]*)\t
#            }{
#               # ww - smaller filesize, UU - compress better
#               pack "C0UU",
#                    hex $1,
#                    length $2 ? (hex $2) - (hex $1) : 0
#            }gemx;

            s/#.*\n/\n/mg;
            s/\s+\n/\n/mg;
         }

         # PPI seems to be mostly undocumented
         $heredoc->{_heredoc} = [split /$/, $src];
      }
   }

   $doc->prune (PPI::Token::Comment::);
   $doc->prune (PPI::Token::Pod::);

   # prune END stuff
   for (my $last = $doc->last_element; $last; ) {
      my $prev = $last->previous_token;

      if ($last->isa (PPI::Token::Whitespace::)) {
         $last->delete;
      } elsif ($last->isa (PPI::Statement::End::)) {
         $last->delete;
         last;
      } elsif ($last->isa (PPI::Token::Pod::)) {
         $last->delete;
      } else {
         last;
      }

      $last = $prev;
   }

   # prune some but not all insignificant whitespace
   for my $ws (@{ $doc->find (PPI::Token::Whitespace::) }) {
      my $prev = $ws->previous_token;
      my $next = $ws->next_token;

      if (!$prev || !$next) {
         $ws->delete;
      } else {
         if (
            $next->isa (PPI::Token::Operator::) && $next->{content} =~ /^(?:,|=|!|!=|==|=>)$/ # no ., because of digits. == float
            or $prev->isa (PPI::Token::Operator::) && $prev->{content} =~ /^(?:,|=|\.|!|!=|==|=>)$/
            or $prev->isa (PPI::Token::Structure::)
            or ($self->{optimise_size} &&
                ($prev->isa (PPI::Token::Word::)
                   && (PPI::Token::Symbol:: eq ref $next
                       || $next->isa (PPI::Structure::Block::)
                       || $next->isa (PPI::Structure::List::)
                       || $next->isa (PPI::Structure::Condition::)))
               )
         ) {
            $ws->delete;
         } elsif ($prev->isa (PPI::Token::Whitespace::)) {
            $ws->{content} = ' ';
            $prev->delete;
         } else {
            $ws->{content} = ' ';
         }
      }
   }

   # prune whitespace around blocks, also ";" at end of blocks
   if ($self->{optimise_size}) {
      # these usually decrease size, but decrease compressability more
      for my $struct (PPI::Structure::Block::, PPI::Structure::Condition::, PPI::Structure::List::) {
         for my $node (@{ $doc->find ($struct) }) {
            my $n1 = $node->first_token;
#            my $n2 = $n1->previous_token;
            my $n3 = $n1->next_token;
            $n1->delete if        $n1->isa (PPI::Token::Whitespace::);
#            $n2->delete if $n2 && $n2->isa (PPI::Token::Whitespace::); # unsafe! AE::timer $MAX_SIGNAL_LATENCY -($NOW - int$NOW)
            $n3->delete if $n3 && $n3->isa (PPI::Token::Whitespace::);
            my $n1 = $node->last_token;
            my $n2 = $n1->next_token;
            my $n3 = $n1->previous_token;
            $n1->delete if        $n1->isa (PPI::Token::Whitespace::);
            $n2->delete if $n2 && $n2->isa (PPI::Token::Whitespace::);
            $n3->{content} = "" # delete seems to trigger a bug inside PPI
                        if $n3 && ($n3->isa (PPI::Token::Whitespace::)
                                   || ($n3->isa (PPI::Token::Structure::) && $n3->content eq ";"));
         }
      }
   }

   # foreach => for
   for my $node (@{ $doc->find (PPI::Statement::Compound::) }) {
      if (my $n = $node->first_token) {
         $n->{content} = "for" if $n->{content} eq "foreach" && $n->isa (PPI::Token::Word::);
      }
   }

   # reformat qw() lists which often have lots of whitespace
   for my $node (@{ $doc->find (PPI::Token::QuoteLike::Words::) }) {
      if ($node->{content} =~ /^qw(.)(.*)(.)$/s) {
         my ($a, $qw, $b) = ($1, $2, $3);
         $qw =~ s/^\s+//;
         $qw =~ s/\s+$//;
         $qw =~ s/\s+/ /g;
         $node->{content} = "qw$a$qw$b";
      }
   }

   # prune return at end of sub-blocks
   #TODO:
   # PPI::Document
   #   PPI::Statement::Sub
   #     PPI::Token::Word    'sub'
   #     PPI::Token::Whitespace      ' '
   #     PPI::Token::Word    'f'
   #     PPI::Structure::Block       { ... }
   #       PPI::Statement
   #         PPI::Token::Word        'sub'
   #         PPI::Structure::Block   { ... }
   #           PPI::Statement::Break
   #             PPI::Token::Word    'return'
   #             PPI::Token::Whitespace      ' '
   #             PPI::Token::Number          '5'
   #         PPI::Token::Structure   ';'
   #       PPI::Statement::Compound
   #         PPI::Structure::Block   { ... }
   #           PPI::Statement::Break
   #             PPI::Token::Word    'return'
   #             PPI::Token::Whitespace      ' '
   #             PPI::Token::Number          '8'
   #       PPI::Statement::Break
   #         PPI::Token::Word        'return'
   #         PPI::Token::Whitespace          ' '
   #         PPI::Token::Number      '7'

   1
}

=item $perl = $transform->strip ($perl)

Strips the perl source in C<$perl> and returns the stripped source.

=cut

sub strip {
   my ($self, $src) = @_;

   my $filter = sub {
      my $ppi = new PPI::Document \$src
         or return;

      $self->document ($ppi)
         or return;

      $src = $ppi->serialize;
   };

   if (exists $self->{cache} && (2048 <= length $src)) {
      my $file = "$self->{cache}/" . Digest::MD5::md5_hex "$CACHE_VERSION \n" . (!!$self->{optimise_size}) . "\n\x00$src";

      if (open my $fh, "<:perlio", $file) {
         # zero size means unchanged
         if (-s $fh) {
            local $/;
            $src = <$fh>
         }
      } else {
         my $oldsrc = $src;

         $filter->();

         mkdir $self->{cache};

         if (open my $fh, ">:perlio", "$file~") {
            # write a zero-byte file if source is unchanged
            if ($oldsrc eq $src or (syswrite $fh, $src) == length $src) {
               close $fh;
               rename "$file~", $file;
            }
         }
      }
   } else {
      $filter->();
   }

   $src
}

=back

=head1 SEE ALSO

L<App::Staticperl>, L<Perl::Squish>.

=head1 AUTHOR

   Marc Lehmann <schmorp@schmorp.de>
   http://home.schmorp.de/

=cut

1;

