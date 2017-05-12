package Shebangml;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

=head1 NAME

Shebangml - markup with bacon

=head1 SYNOPSIS

This is an experimental markup language + parser|interpreter with
support for plugins and cleanly configurable add-on features.  I use it
as a personal home page tool and lots of other things.

See L<Shebangml::Syntax> for details.

=cut

use Class::Accessor::Classy;
with 'new';
ro 'state';
rw 'out_fh';
no  Class::Accessor::Classy;

use constant DEBUG => 0;

# XXX experimental global variable and accessor :-/
our $current_file; sub current_file {$current_file};

use Shebangml::State;

=head1 Methods

=head2 configure

  $hbml->configure(%options);

=cut

sub configure {
  my $self = shift;
  my (%opts) = @_;

  if(my $h = $opts{handlers}) {
    while(my ($name, $pm) =  each(%$h)) {
      require($pm);
      $self->add_handler($name);
    }
  }
} # end subroutine configure definition
########################################################################

=head2 add_handler

Adds a handler for a namespace.

  $hbml->add_handler($name);

The C<$name> will have C<Shebangml::Handler::> prepended to it, and
should already be loaded at this point.  It is good practice to declare
a version (e.g. C<our $VERSION = v0.1.1>) in your handler package -- and
may be required in the future.

If a C<new> method is available, a new object will be constructed and
stored as the handler.  Otherwise, the handler will be treated as a
class name.  Tags in the handlers namespace are constructed as:

  .yourclass.themethod[foo=bar]

or

  .yourclass.themethod[foo=bar]{{{content literal}}}

These would cause the processing to invoke one of the following (the
latter if you have defined C<new()>) and send the result to
C<$hbml-E<gt>output()>.

  Shebangml::Handler::yourclass->themethod($atts, $content);

  $yourobject->themethod($atts, $content);

=cut

sub add_handler {
  my $self = shift;
  my ($name, $what) = @_;

  if($what) {
    die "teach me that trick please";
  }
  else {
    $what = 'Shebangml::Handler::' . $name;
    if(my $construct = $what->can('new')) {
      $what = $what->$construct;
    }
  }

  my $h = $self->{handlers} ||= {};
  $h->{$name} = $what;
} # end subroutine add_handler definition
########################################################################

=head2 add_hook

  $hbml->add_hook($name => sub {...});

=cut

sub add_hook {
  my $self = shift;
  my ($what, $hook) = @_; 

  $self->{hooks}{$what} = $hook;
} # end subroutine add_hook definition
########################################################################

=head2 process

Processes a given input $source.  This method holds its own state and
can be repeatedly called with new inputs (each of which must be a
well-formed shebangml document) using the same $hbml object.

Arguments are passed to L<Shebangml::State/new>.

  $hbml->process($source);

=cut

sub process {
  my $self = shift;
  my $state = Shebangml::State->new(@_);
  local $current_file = $current_file;
  $current_file ||= $state->{filename} || undef;

  my @opened;
  my $bare = 0;
  my $in_att = 0;
  while(my $CL = $state->next) {

    # absorb the comments
    if($$CL =~ m/^\s*#/) {
      $state->skip_comment;
      next;
    }

    # main processing of the current line
    while($$CL =~ s/^(.*?)([\.\w-]+[\{\[]|\]\{|[\[\]\{\}]|\n)//x) {
      my ($text, $hit) = ($1, $2);
      DEBUG and warn join(',', $text, $hit), "\n";
      if($hit) {
        my $escaped;
        if($text =~ s/(\\+)$//) {
          my $bs = $1;
          my $n = length($bs);
          # TODO put-back half of them
          if($n %2) {
            $escaped = 1;
            chop($bs);
          }
          $text .= $bs;
        }
        if($hit eq '{') {
          # so what?  Should I count them?
          DEBUG and warn "#  Bare {\n";
          $bare++ unless($escaped);
          $text .= $hit;
        }
        elsif($hit eq '[') {
          $text .= $hit;
        }
        elsif($hit eq '}') {
          if($escaped) {
            $text .= $hit;
          }
          elsif($bare) {
            $bare--;
            $text .= $hit;
          }
          else { # closing
            my $guts = pop(@opened) or
              croak("no open tag where closing ($text)");
            $self->put_text($text); $text = '';
            my $tag = $guts->[0];
            $self->put_tag_end($tag);
            if($$CL =~ s/#([\.\w]+);//) {
              $1 eq $tag or croak("assertion $tag failed: $1");
            }
          }
        }
        elsif($hit eq ']' or $hit eq "]\{") {
          if($in_att) { # everything in $text is attributes now
            my @guts = @{$opened[-1]};
            $text =~ s/^\s*//;
            my $tag = shift(@guts);

            my $atts = $self->atts(@guts, $text||());

            # put_tag_start with attributes
            if($hit eq "]\{") {
              # look for fat quote
              if($$CL =~ s/^\{\{(\n?)//) {
                my $cr = $1;
                pop(@opened);
                DEBUG and warn "thick bacon!\n";
                $self->put_tag($tag, $atts, $state->read_literal($tag, $cr));
              }
              else {
                $self->put_tag_start($tag, $atts);
              }
            }
            else {
              $self->put_tag($tag, $atts);
              pop(@opened);
            }
            $text = '';

            $in_att = 0;
          }
          else { # no need to escape these brackets
            # XXX that's probably incorrect for the \]\{ case
            $text .= $hit;
          }
        }
        elsif($hit eq "\n") {
          if($in_att) {
            push(@{$opened[-1]}, $text);
            $text = '';
          }
          else {
            if($escaped) {
              # we dropped the $bs earlier so munch whitespace ...
              $state->skip_whitespace;
            }
            else {
              $text .= $hit;
            }
          }
        }
        else {
          my ($tag, $br) = ($hit =~ m/^(.*)([\[\{])/) or die "ouch";
          DEBUG and warn "yay: $tag --> $br\n";
          my $guts = [$tag];
          push(@opened, $guts);

          $self->put_text($text); $text = '';

          if($br eq '[') { # TODO greedy attribute grab?
            $in_att = 1;
            # TODO $self->put_tag_start goes here if we gobble the atts
            #      (But then I also have to deal with the fatquote)
          }
          else {
            if($$CL =~ s/^\{\{(\n?)//) {
              my $cr = $1;
              pop(@opened);
              DEBUG and warn "thick bacon\n";
              $self->put_tag($tag, undef, $state->read_literal($tag, $cr));
            }
            else {
              # if we have text here, it preceded the tag
              $self->put_tag_start($tag);
            }
          }
        }
        #die "text! $text" if($text);
      }
      else { # no hit
        # TODO text-only output only here?
      }

      # XXX we shouldn't have anything to output here after refactoring
      # warn "output ($text)\n";
      # die "argh ($text)" if($text ne "\n");
      $self->put_text($text);

      # more whitespace munching
      if($$CL =~ s/^\\\s+//) {
        $state->skip_whitespace if($$CL eq '');
      }

    } # end $CL muncher
  }

} # end subroutine process definition
########################################################################

=head2 put_tag

Handles contentless tags and any tags constructed with the {{{ ... }}}
literal quoting mechanism.

  $hbml->put_tag($tag, $atts, $string);

=cut

sub put_tag {
  my $self = shift;
  my ($tag, $atts, $string) = @_;

  if($tag =~ s/^\.//) { return $self->run_tag($tag, $atts, $string) }

  if(my $hook = $self->{hooks}{$tag}) {
    $hook->($tag, $atts);
  }

  if(defined($string)) {
    $self->put_tag_start($tag, $atts);
    $self->put_literal($string);
    $self->put_tag_end($tag);
  }
  else {
    $self->output('<' . $tag . ($atts ? $atts->as_string : '') . ' />');
  }
} # end subroutine put_tag definition
########################################################################

=head2 put_tag_start

  $hbml->put_tag_start($tag, $atts);

=cut

sub put_tag_start {
  my $self = shift;
  my ($tag, $atts) = @_;

  if($tag =~ s/^\.//) { return $self->run_tag($tag, $atts) }

  if(my $hook = $self->{hooks}{$tag}) {
    $hook->($tag, $atts);
  }

  $self->output('<' . $tag . ($atts ? $atts->as_string : '') . '>');
} # end subroutine put_tag_start definition
########################################################################

=head2 put_tag_end

  $hbml->put_tag_end($tag);

=cut

sub put_tag_end {
  my $self = shift;
  my ($tag) = @_;

  if($tag =~ s/^\.//) { return $self->run_tag($tag) }

  $self->output('</' . $tag . '>');
} # end subroutine put_tag_end definition
########################################################################

=head2 put_text

  $hbml->put_text($text);

=cut

sub put_text {
  my $self = shift;
  my ($text) = @_;
  $text or return; # XXX still need to signal?

  $self->output($self->escape_text($text));
} # end subroutine put_text definition
########################################################################


=head2 run_tag

This method is called for any whole, starting, or ending tags which
start with a dot ('.').  The builtin or plugin handler for the given tag
I<must> exist and I<must> have a prototype which corresponds to the way
it is used.

  $hbml->run_tag($tag, @and_stuff);

Yes, your method should have a prototype.

=cut

sub run_tag {
  my $self = shift;
  my ($tag, @and) = @_;

  my $call = sub {
    my ($h, $m) = @_;
    my $proto = prototype($m);
    croak("$tag prototype not defined") unless(defined $proto);
    croak("$tag prototype ($proto) invalid") unless($proto =~ m/^;?\$\$?$/);

    unless(@and) {
      $proto =~ m/^;/ or
        croak("$tag prototype ($proto) disallows start/end usage");
    }

    return($h->$m(@and));
  };

  if($tag =~ s/^x\.//) {
    my ($name, $method, @more) = split(/\./, $tag);
    my $handler = $self->{handlers}{$name} or
      croak("no handler for $name");
    my $ref = $handler->can($method) or
      croak("cannot find $method in $handler");
    while(@more) {
      $handler = $handler->$ref;
      $method = shift(@more);
      $ref = $handler->can($method) or
        croak("cannot find $method in $handler");
    }
    $method = $ref;
    return $self->output($call->($handler, $method));
  }
  else {
    my $method = $self->can('do_' . $tag) or
      croak("no builtin for .$tag");
    return $call->($self, $method);
  }
} # run_tag ############################################################

=head2 escape_text

  my $out = $hbml->escape_text($text);

=cut

sub escape_text {
  my $self = shift;
  my ($text) = @_;

  # escaping '&','<' and everything else
  $text =~ s/&/&amp;/g;
  $text =~ s/</&lt;/g;
  # must break-out all of the double backslashes I guess
  my @parts = split(/\\\\/, $text);
  for(@parts) {
    s#\\n;#<br/>#g;
    s/\\#(\d+|x[0-9a-f]+);/&#$1;/gi;
    s/\\#/#/g;
    s/\\_;/&nbsp;/g; # XXX that should be utf8 nbsp?
    s/\\-;/&ndash;/g;
    s/\\--;/&mdash;/g;
    s#\\---;#<hr />#g;
    s/\\(\w+);/&$1;/g;
  }

  return(join('\\', @parts));
} # escape_text ########################################################

=head2 put_literal

  $hbml->put_literal($string);

=cut

sub put_literal {
  my $self = shift;
  my ($string) = @_;

  # TODO trigger text hooks
  $self->output($string);
} # end subroutine put_literal definition
########################################################################

=head2 output

  $hbml->output(@strings);

=cut

sub output {
  my $self = shift;
  my (@strings) = @_;

  my $out_fh = $self->out_fh or croak("no output fh");
  print $out_fh @strings;
} # end subroutine output definition
########################################################################

=head1 Builtins

=head2 do_include

  $hbml->do_include($atts);

=cut

sub do_include ($$) {
  my $self = shift;
  my ($atts) = @_;
  my $filename = $atts->get('src') or croak("need filename for include");
  $self->process($filename);
} # end subroutine do_include definition
########################################################################

=head2 do_doctype

  $hbml->do_doctype($atts);

=cut

sub do_doctype ($$) {
  my $self = shift;
  (@_ == 2) or croak('.doctype cannot have data');
  my ($atts) = @_;
  my $opt = $atts->get('id') or croak("must select doctype with =type");

  my %types = (
    html_strict =>
    q(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN")."\n".
    q(  "http://www.w3.org/TR/html4/strict.dtd">),

    html_loose =>
    q(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN")."\n".
    q(  "http://www.w3.org/TR/html4/loose.dtd">),

    html_frameset =>
    q(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN")."\n".
    q(  "http://www.w3.org/TR/html4/frameset.dtd">),

    x_strict =>
    q(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN")."\n".
    q(  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">),

    x_loose =>
    q(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN")."\n".
    q(  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">),

    x_frameset =>
    q(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN")."\n".
    q(  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">),

    xhtml11 =>
    q(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" )."\n".
    q(  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">),
  );
  my $string = $types{$opt} or
    croak("$opt is not one of ", join(", ", sort(keys %types)));

  $self->output($string);
} # end subroutine do_doctype definition
########################################################################

{
package Shebangml::Attrs;
use Class::Accessor::Classy;
with 'new';
lw 'atts';
#ri 'as_string'; # ugh
no  Class::Accessor::Classy;


=for head2 as_string
Output pairs with = and quoting, leading space and spaces between them.
  $atts->as_string;

=cut

sub as_string {
  my $self = shift;

  # quote and = the pairs
  my @atts = $self->atts;
  croak(scalar(@atts), ' items cannot be a list of pairs')
    if(@atts % 2);

  return(' ' . join(' ', 
    map({$atts[2*$_] . '="' . $atts[2*$_+1] . '"'} 0..(($#atts-1)/2))
  ));
} # end subroutine as_string definition
########################################################################

=for head2 get
  $atts->get($name);

=cut

sub get {
  my $self = shift;
  my ($name) = @_;

  my @atts = $self->atts;
  my @ans = map({$atts[2*$_+1]}
    grep({$atts[$_*2] eq $name} 0..(($#atts-1)/2)));
  @ans or return();
  return(@ans == 1 ? ($ans[0]) : @ans);
} # end subroutine get definition
########################################################################

=for head2 delete
  my $v = $atts->delete($name);

=cut

sub delete {
  my $self = shift;
  my ($name) = @_;

  my $atts = $self->{atts} ||= [];
  for(my $i = 0; $i < @$atts; $i+=2) {
    if($atts->[$i] eq $name) {
      return scalar splice(@$atts, $i, 2);
    }
  }
  return();
} # delete #############################################################

=for head2 set
  $atts->set($name => $value);

=cut

sub set {
  my $self = shift;
  my ($n, $v) = @_;
  my $atts = $self->{atts} ||= [];
  for(my $i = 0; $i < @$atts; $i+=2) {
    if($atts->[$i] eq $n) {
      return $atts->[$i+1] = $v;
    }
  }
  push(@$atts, $n, $v);
  return($v);
} # set ################################################################

1;
}

=head2 atts

Parses one or more lines of attribute strings into pairs and returns an
atts object.

  my $atts = $self->atts(@atts);

=cut

# XXX guess this needs to return an object with accessors and a string
# method to preserve the original linebreaks and junk.
sub atts {
  my $self = shift;
  my (@atts) = @_;

  @atts or return();
  s/\n/ /g for(@atts);
  my $input = join(' ', @atts);

  # leading whitespace, multiline attributes, etc
  # UGH.  I think I would rather just collapse them
  # /=(\w)/="$1/ and /(\w) /$1"/ <-- but not when quoted
  # join it all together?
  # just split and then sort it out?

  my $attr = Shebangml::Attrs->new(atts => []);

  # shortcuts for id=, name=, class=
  my %short = (qw(
    : name
    = id
    @ class
  ));
  my $sigil = '[' . join('', keys %short) . ']';
  my $bareword = qr/[\/:._\w-]+/;
  my %did = map({$_ => 0} keys %short);
  while($input =~ s/^(\s*)($sigil)($bareword)//) {
    my ($ws, $f, $v) = ($1, $2, $3);
    my $n = $short{$f} or croak("no shortcut $f");
    $did{$f}++ and croak("duplicate shortcut $n");
    $attr->add_atts($n, $v);
  }

  # the rest is straight xml, but only optionally quoted
  while($input =~ m/\G(\s*)
    ($bareword) = ("(?:\\.|[^"])*" | $bareword)
    (\s*)/gx) {
    my ($lws, $name, $val, $tws) = ($1, $2, $3, $4);
    $val =~ s/^"//; $val =~ s/"$//;
    $attr->add_atts($name, $val);
  }

  return($attr);
} # end subroutine atts definition
########################################################################

=head1 Experimental

Some parts which might not survive revision:

=head2 current_file

This is set during process() and becomes accessible for callbacks as a
class accessor.

=cut

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2008 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
