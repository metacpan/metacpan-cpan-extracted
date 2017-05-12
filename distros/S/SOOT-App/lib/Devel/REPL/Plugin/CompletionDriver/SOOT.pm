package Devel::REPL::Plugin::CompletionDriver::SOOT;
use Devel::REPL::Plugin;
use Scalar::Util qw(blessed);
use namespace::clean -except => [ 'meta' ];
use Term::ANSIColor qw(:constants :pushpop);

sub BEFORE_PLUGIN {
    my $self = shift;
    $self->load_plugin('Completion');
}

# returns array ref: [$ok, $show_prototype, $methname, $invocant]
sub _match_method_call {
  my ($self, $last) = @_;
  my $show_prototype = 0;
  # If we're after a paren (and the rest below matches, too),
  # then we want to print method signatures.
  if ($last->isa('PPI::Token::Structure') and $last->content eq '(') {
    $show_prototype = 1;
    $last = $last->parent->sprevious_sibling;
    last if not $last;
  }
  # match method name
  return [0, $show_prototype]
    if not $last or not $last->isa('PPI::Token::Word');
  
  # match arrow operator
  my $prev = $last->sprevious_sibling;
  return [0, $show_prototype]
    if not $prev or not $prev->isa('PPI::Token::Operator') or $prev->content ne '->';

  # match invocant
  my $invocant = $prev->sprevious_sibling;
  return [0, $show_prototype]
    if not $invocant
    or not ($invocant->isa('PPI::Token::Symbol') || $invocant->isa('PPI::Token::Word'));

  return [1, $show_prototype, $last, $invocant];
}

sub _is_soot_object {
  my $var = shift;
  return()
    if not blessed($var)
    or not ($var->isa('TObject') or SOOT::API->is_soot_class(ref($var)));
  return 1;
}

sub _show_matching_methods {
  my ($self, $var, $invocant, $methname, $document, $show_prototype) = @_;

  my $class = $var->Class;
  if ($show_prototype) {
    my @meth = $class->soot_method_complete_proto_str($methname->content, 1);
    print "\n" if @meth;
    for (@meth) {
      print LOCALCOLOR YELLOW $_;
      print "\n";
    }
    local $| = 1;
    print LOCALCOLOR UNDERLINE $self->prompt;
    print $document->content;
    return [];
  }
  else {
    my @meth = $class->soot_method_complete_name($methname->content);
    return [map "$_(", @meth];
  }
}

sub _try_complete_lexical {
  my ($self, $invocant, $methname, $document, $show_prototype) = @_;
  
  my $invocant_str = $invocant->content;
  my $lexenv = $self->lexical_environment();
  my $cxt = $lexenv->get_context('_');
  my $var = $cxt->{$invocant_str};

  return if not _is_soot_object($var);

  return $self->_show_matching_methods($var, $invocant, $methname, $document, $show_prototype);
}

sub _try_complete_global {
  my ($self, $invocant, $methname, $document, $show_prototype) = @_;
  
  my $invocant_str = $invocant->content;

  my $sigil = $invocant_str =~ s/^([\$\@\%\&\*])// ? $1 : 0; # remove sigil

  my @package_fragments = split qr/::|'/, $invocant_str;

  # Almost verbatim from the ::Globals completion driver...

  # split drops the last fragment if it's empty
  push @package_fragments, '' if $invocant_str =~ /(?:'|::)$/;

  # the beginning of the variable, or an incomplete package name
  my $incomplete = pop @package_fragments;

  # recurse for the complete package fragments
  my $stash = \%::;
  for (@package_fragments) {
    $stash = $stash->{"$_\::"};
  }

  # collect any variables from this stash
  my @found = grep { $_ eq $invocant_str }
              keys %$stash;
  return if not @found;

  my $varname = shift(@found);
  my $var = $stash->{$varname};
  $var = *{$var}{SCALAR};
  $var = $$var if $var;

  return if not _is_soot_object($var);

  return $self->_show_matching_methods($var, $invocant, $methname, $document, $show_prototype);
}

around complete => sub {
  my $orig = shift;
  my ($self, $text, $document) = @_;

  # The last token the user has entered (will dive as deep as possible into the PPI structure)
  my $last = $self->last_ppi_element($document);

  my $rv = $self->_match_method_call($last);
  my ($ok, $show_prototype, $methname, $invocant) = @{$rv||[]};
  return if not $ok;

  my $completions;

  $completions = $self->_try_complete_lexical($invocant, $methname, $document, $show_prototype);
  return $orig->(@_), @$completions if $completions;

  $completions = $self->_try_complete_global($invocant, $methname, $document, $show_prototype);
  return $orig->(@_), @$completions if $completions;

  return $orig->(@_);
};

1;

__END__

=head1 NAME

Devel::REPL::Plugin::CompletionDriver::SOOT - Complete SOOT method names

=head1 ACKNOWLEDGMENTS

Contains some code adapted from L<Devel::REPL::Plugin::CompletionDriver::LexEnv>
and L<Devel::REPL::Plugin::CompletionDriver::Globals>.

=head1 AUTHOR

Steffen Mueller, C<< <smueller@cpan.org> >>

=cut

