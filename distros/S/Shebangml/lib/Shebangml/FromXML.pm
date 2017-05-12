package Shebangml::FromXML;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

use XML::Parser::Expat;

use Class::Accessor::Classy;
ro 'parser';
lo 'output';
no  Class::Accessor::Classy;

use constant DEBUG => 0;

=head1 NAME

Shebangml::FromXML - SAX parse XML into HBML

=head1 SYNOPSIS

  my $parser = Shebangml::FromXML->new;
  $parser->parse($source);

The $source can be as-per L<XML::Parser::Expat>.

=cut

=head2 new

  my $parser = Shebangml::FromXML->new;

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = {parser => XML::Parser::Expat->new};
  bless($self, $class);

  $self->_setup;

  return($self);
} # end subroutine new definition
########################################################################

=head2 _setup

  $parser->_setup;

=cut

sub _setup {
  my $self = shift;

  my @output;
  $self->{output} = \@output;
  my @ctx = ({root => 1, had_content => 1});

  my %shortcuts = (
    br => '\n;',
  );
  my $start = sub {
    my ($el) = @_;

    my $short;
    $el = $short if($short = $shortcuts{$el});
    unless($ctx[-1]->{had_content}) {
      $ctx[-1]->{had_content} = 1;
      push(@output, '{', $el);
      return($short);
    }
    else {
      if($short) {
        push(@output, $short);
        return($short);
      }
      push(@output,
        (@output && $output[-1] =~ m/[\.\w]$/ ? '\\' : ''),
        $el);
      return();
    }
  };
  my $out = sub {
    push(@output, @_);
  };
  my $sh = sub {
    my ($p, $el, @atts) = @_;

    DEBUG and warn "start handler $el at ", $p->current_byte;

    $start->($el) and return;

    # XXX ugh.  The only way I'm going to get the &foo; entities in the
    # attributes is uh... I have to use not expat?
    # warn $p->original_string;

    push(@ctx, my $e = { });
    if(@atts) {
      @atts = $self->_reduce_atts(@atts);

      # TODO sorting, quoting, and such
      my $att = join(' ', @atts);
      $out->("[$att]");
      $e->{had_atts} = 1;
    }
    elsif($p->original_string =~ m#/>$#) {
      # do I even need to tag it as empty?
      $e->{had_atts} = 1;
      $out->('[]');
    }

  };
  my $eh = sub {
    my ($p, $el) = @_;
    $shortcuts{$el} and return; # never closing shortcuts
    DEBUG and warn "end handler $el at ", $p->current_byte;
    my $e = pop(@ctx);
    if($e->{had_content}) {
      $out->('}');
    }
    elsif(not $e->{had_atts}) {
      # we still have to make it an entity
      $out->('{}');
    }
    else {
      # XXX may need to output [] or {} to indicate br-like tag?
    }
  };
  my $ch = sub {
    my ($p, $s) = @_;
    my $e = $ctx[-1];
    $out->('{') unless($e->{had_content});
    $e->{had_content} = 1;

    # escaping the string...
    # TODO smarter [] and {} matched handling
    $s =~ s/([\{\}\[\]])/\\$1/g;
    $s =~ s/\\/\\\\/g;
    # TODO &lt; and such need to transform too

    $out->($s);
  };
  my $dt = sub {
    DEBUG and warn "doctype @_";
  };
  my $parser = $self->parser;
  $parser->setHandlers(
    Start => $sh,
    End   => $eh,
    Char  => $ch,
    Doctype => $dt,
    CdataStart => sub {DEBUG and warn "CdataStart @_"},
    Comment => sub {DEBUG and warn "comment @_"},
    Unparsed => sub {
      DEBUG and warn "unparsed @_";
    },
    #Attlist => sub { warn " atts @_"; },
    Default => sub {
      DEBUG and warn 'hit default: ',
        "@_ (", $output[-1] ? $output[-1] : (), ") ",
        "line ", $parser->current_line,
        ", column ", $parser->current_column,
        ", byte ", $parser->current_byte;
    },
    # ExternEnt => sub {warn "an externEnt?!"},
    # Entity => sub {warn "an Entity?! @_"},
  );
} # end subroutine _setup definition
########################################################################

=head2 parse

  $parser->parse($source);

=cut

sub parse {
  my $self = shift;
  my ($source) = @_;
  $self->parser->parse($source);
} # end subroutine parse definition
########################################################################

=head2 _reduce_atts

  my @atts = $self->_reduce_atts(@atts);

=cut

{
my %shortcut = (name => ':', id => '=', class => '@');
sub _reduce_atts {
  my $self = shift;
  my (@atts) = @_;

  # yank the id, name, class to the front -- with shortcuts
  my %num = map({my $n = $_*2; ($atts[$n] => $n)} 0..($#atts/2));
  my @cuts;
  my @out;
  foreach my $k (sort keys(%shortcut)) {
    if(exists($num{$k})) {
      push(@cuts, $num{$k});
      my $att = $atts[$num{$k}+1];
      if($att =~ m/^\w+$/) {
        push(@out, $shortcut{$k} . $att);
      }
      else {
        push(@out, $k . qq(="$att"));
      }
    }
  }
  foreach my $n (sort({$b <=> $a} @cuts)) {
    splice(@atts, $n, 2);
  }
  return(@out,
    @atts ?
    map({my $n = $_*2; $atts[$n].'="'.$atts[$n+1].'"'} 0..int($#atts/2))
    : ()
  );
}} # end subroutine _reduce_atts definition
########################################################################


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
