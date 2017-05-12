package Regexp::Wildcards;

use strict;
use warnings;

use Carp           qw<croak>;
use Scalar::Util   qw<blessed>;
use Text::Balanced qw<extract_bracketed>;

=head1 NAME

Regexp::Wildcards - Converts wildcard expressions to Perl regular expressions.

=head1 VERSION

Version 1.05

=cut

use vars qw<$VERSION>;
BEGIN {
 $VERSION = '1.05';
}

=head1 SYNOPSIS

    use Regexp::Wildcards;

    my $rw = Regexp::Wildcards->new(type => 'unix');

    my $re;
    $re = $rw->convert('a{b?,c}*');          # Do it Unix shell style.
    $re = $rw->convert('a?,b*',   'win32');  # Do it Windows shell style.
    $re = $rw->convert('*{x,y}?', 'jokers'); # Process the jokers and
                                             # escape the rest.
    $re = $rw->convert('%a_c%',   'sql');    # Turn SQL wildcards into
                                             # regexps.

    $rw = Regexp::Wildcards->new(
     do      => [ qw<jokers brackets> ], # Do jokers and brackets.
     capture => [ qw<any greedy> ],      # Capture *'s greedily.
    );

    $rw->do(add => 'groups');            # Don't escape groups.
    $rw->capture(rem => [ qw<greedy> ]); # Actually we want non-greedy
                                         # matches.
    $re = $rw->convert('*a{,(b)?}?c*');  # '(.*?)a(?:|(b).).c(.*?)'
    $rw->capture();                      # No more captures.

=head1 DESCRIPTION

In many situations, users may want to specify patterns to match but don't need the full power of regexps.
Wildcards make one of those sets of simplified rules.
This module converts wildcard expressions to Perl regular expressions, so that you can use them for matching.

It handles the C<*> and C<?> jokers, as well as Unix bracketed alternatives C<{,}>, but also C<%> and C<_> SQL wildcards.
If required, it can also keep original C<(...)> groups or C<^> and C<$> anchors.
Backspace (C<\>) is used as an escape character.

Typesets that mimic the behaviour of Windows and Unix shells are also provided.

=head1 METHODS

=cut

sub _check_self {
 croak 'First argument isn\'t a valid ' . __PACKAGE__ . ' object'
  unless blessed $_[0] and $_[0]->isa(__PACKAGE__);
}

my %types = (
 jokers   => [ qw<jokers> ],
 sql      => [ qw<sql> ],
 commas   => [ qw<commas> ],
 brackets => [ qw<brackets> ],
 unix     => [ qw<jokers brackets> ],
 win32    => [ qw<jokers commas> ],
);
$types{$_} = $types{win32} for qw<dos os2 MSWin32 cygwin>;
$types{$_} = $types{unix}  for qw<linux
                                  darwin machten next
                                  aix irix hpux dgux dynixptx
                                  bsdos freebsd openbsd
                                  svr4 solaris sunos dec_osf
                                  sco_sv unicos unicosmk>;

my %escapes = (
 jokers   => '?*',
 sql      => '_%',
 commas   => ',',
 brackets => '{},',
 groups   => '()',
 anchors  => '^$',
);

my %captures = (
 single   => sub { $_[1] ? '(.)' : '.' },
 any      => sub { $_[1] ? ($_[0]->{greedy} ? '(.*)'
                                            : '(.*?)')
                         : '.*' },
 brackets => sub { $_[1] ? '(' : '(?:'; },
 greedy   => undef,
);

sub _validate {
 my $self  = shift;
 _check_self $self;
 my $valid = shift;
 my $old   = shift;
 $old = { } unless defined $old;

 my %opts;
 if (@_ <= 1) {
  $opts{set} = defined $_[0] ? $_[0] : { };
 } elsif (@_ % 2) {
  croak 'Arguments must be passed as an unique scalar or as key => value pairs';
 } else {
  %opts = @_;
 }

 my %checked;
 for (qw<set add rem>) {
  my $opt = $opts{$_};
  next unless defined $opt;

  my $cb = {
   ''      => sub { +{ ($_[0] => 1) x (exists $valid->{$_[0]}) } },
   'ARRAY' => sub { +{ map { ($_ => 1) x (exists $valid->{$_}) } @{$_[0]} } },
   'HASH'  => sub { +{ map { ($_ => $_[0]->{$_}) x (exists $valid->{$_}) }
                        keys %{$_[0]} } }
  }->{ ref $opt };
  croak 'Wrong option set' unless $cb;
  $checked{$_} = $cb->($opt);
 }

 my $config = (exists $checked{set}) ? $checked{set} : $old;
 $config->{$_} = $checked{add}->{$_} for grep $checked{add}->{$_},
                                          keys %{$checked{add} || {}};
 delete $config->{$_}                for grep $checked{rem}->{$_},
                                          keys %{$checked{rem} || {}};

 $config;
}

sub _do {
 my $self = shift;

 my $config;
 $config->{do}      = $self->_validate(\%escapes, $self->{do}, @_);
 $config->{escape}  = '';
 $config->{escape} .= $escapes{$_} for keys %{$config->{do}};
 $config->{escape}  = quotemeta $config->{escape};

 $config;
}

sub do {
 my $self = shift;
 _check_self $self;

 my $config  = $self->_do(@_);
 $self->{$_} = $config->{$_} for keys %$config;

 $self;
}

sub _capture {
 my $self = shift;

 my $config;
 $config->{capture} = $self->_validate(\%captures, $self->{capture}, @_);
 $config->{greedy}  = delete $config->{capture}->{greedy};
 for (keys %captures) {
  $config->{'c_' . $_} = $captures{$_}->($config, $config->{capture}->{$_})
                                               if $captures{$_}; # Skip 'greedy'
 }

 $config;
}

sub capture {
 my $self = shift;
 _check_self $self;

 my $config  = $self->_capture(@_);
 $self->{$_} = $config->{$_} for keys %$config;

 $self;
}

sub _type {
 my ($self, $type) = @_;
 $type = 'unix'     unless defined $type;
 croak 'Wrong type' unless exists $types{$type};

 my $config      = $self->_do($types{$type});
 $config->{type} = $type;

 $config;
}

sub type {
 my $self = shift;
 _check_self $self;

 my $config  = $self->_type(@_);
 $self->{$_} = $config->{$_} for keys %$config;

 $self;
}

sub new {
 my $class = shift;
 $class    = blessed($class) || $class || __PACKAGE__;

 croak 'Optional arguments must be passed as key => value pairs' if @_ % 2;
 my %args = @_;

 my $self = bless { }, $class;

 if (defined $args{do}) {
  $self->do($args{do});
 } else {
  $self->type($args{type});
 }

 $self->capture($args{capture});
}

=head2 C<new>

    my $rw = Regexp::Wildcards->new(do => $what, capture => $capture);
    my $rw = Regexp::Wildcards->new(type => $type, capture => $capture);

Constructs a new L<Regexp::Wildcard> object.

C<do> lists all features that should be enabled when converting wildcards to regexps.
Refer to L</do> for details on what can be passed in C<$what>.

The C<type> specifies a predefined set of C<do> features to use.
See L</type> for details on which types are valid.
The C<do> option overrides C<type>.

C<capture> lists which atoms should be capturing.
Refer to L</capture> for more details.

=head2 C<do>

    $rw->do($what);
    $rw->do(set => $c1);
    $rw->do(add => $c2);
    $rw->do(rem => $c3);

Specifies the list of metacharacters to convert or to prevent for escaping.
They fit into six classes :

=over 4

=item *

C<'jokers'>

Converts C<?> to C<.> and C<*> to C<.*>.

    'a**\\*b??\\?c' ==> 'a.*\\*b..\\?c'

=item *

C<'sql'>

Converts C<_> to C<.> and C<%> to C<.*>.

    'a%%\\%b__\\_c' ==> 'a.*\\%b..\\_c'

=item *

C<'commas'>

Converts all C<,> to C<|> and puts the complete resulting regular expression inside C<(?: ... )>.

    'a,b{c,d},e' ==> '(?:a|b\\{c|d\\}|e)'

=item *

C<'brackets'>

Converts all matching C<{ ... ,  ... }> brackets to C<(?: ... | ... )> alternations.
If some brackets are unbalanced, it tries to substitute as many of them as possible, and then escape the remaining unmatched C<{> and C<}>.
Commas outside of any bracket-delimited block are also escaped.

    'a,b{c,d},e'    ==> 'a\\,b(?:c|d)\\,e'
    '{a\\{b,c}d,e}' ==> '(?:a\\{b|c)d\\,e\\}'
    '{a{b,c\\}d,e}' ==> '\\{a\\{b\\,c\\}d\\,e\\}'

=item *

C<'groups'>

Keeps the parenthesis C<( ... )> of the original string without escaping them.
Currently, no check is done to ensure that the parenthesis are matching.

    'a(b(c))d\\(\\)' ==> (no change)

=item *

C<'anchors'>

Prevents the I<beginning-of-line> C<^> and I<end-of-line> C<$> anchors to be escaped.
Since C<[...]> character class are currently escaped, a C<^> will always be interpreted as I<beginning-of-line>.

    'a^b$c' ==> (no change)

=back

Each C<$c> can be any of :

=over 4

=item *

A hash reference, with wanted metacharacter group names (described above) as keys and booleans as values ;

=item *

An array reference containing the list of wanted metacharacter classes ;

=item *

A plain scalar, when only one group is required.

=back

When C<set> is present, the classes given as its value replace the current object options.
Then the C<add> classes are added, and the C<rem> classes removed.

Passing a sole scalar C<$what> is equivalent as passing C<< set => $what >>.
No argument means C<< set => [ ] >>.

    $rw->do(set => 'jokers');           # Only translate jokers.
    $rw->do('jokers');                  # Same.
    $rw->do(add => [ qw<sql commas> ]); # Translate also SQL and commas.
    $rw->do(rem => 'jokers');           # Specifying both 'sql' and
                                        # 'jokers' is useless.
    $rw->do();                          # Translate nothing.

The C<do> method returns the L<Regexp::Wildcards> object.

=head2 C<type>

    $rw->type($type);

Notifies to convert the metacharacters that corresponds to the predefined type C<$type>.
C<$type> can be any of :

=over 4

=item *

C<'jokers'>, C<'sql'>, C<'commas'>, C<'brackets'>

Singleton types that enable the corresponding C<do> classes.

=item *

C<'unix'>

Covers typical Unix shell globbing features (effectively C<'jokers'> and C<'brackets'>).

=item *

C<$^O> values for common Unix systems

Wrap to C<'unix'> (see L<perlport> for the list).

=item *

C<undef>

Defaults to C<'unix'>.

=item *

C<'win32'>

Covers typical Windows shell globbing features (effectively C<'jokers'> and C<'commas'>).

=item *

C<'dos'>, C<'os2'>, C<'MSWin32'>, C<'cygwin'>

Wrap to C<'win32'>.

=back

In particular, you can usually pass C<$^O> as the C<$type> and get the corresponding shell behaviour.

    $rw->type('win32'); # Set type to win32.
    $rw->type($^O);     # Set type to unix on Unices and win32 on Windows
    $rw->type();        # Set type to unix.

The C<type> method returns the L<Regexp::Wildcards> object.

=head2 C<capture>

    $rw->capture($captures);
    $rw->capture(set => $c1);
    $rw->capture(add => $c2);
    $rw->capture(rem => $c3);

Specifies the list of atoms to capture.
This method works like L</do>, except that the classes are different :

=over 4

=item *

C<'single'>

Captures all unescaped I<"exactly one"> metacharacters, i.e. C<?> for wildcards or C<_> for SQL.

    'a???b\\??' ==> 'a(.)(.)(.)b\\?(.)'
    'a___b\\__' ==> 'a(.)(.)(.)b\\_(.)'

=item *

C<'any'>

Captures all unescaped I<"any"> metacharacters, i.e. C<*> for wildcards or C<%> for SQL.

    'a***b\\**' ==> 'a(.*)b\\*(.*)'
    'a%%%b\\%%' ==> 'a(.*)b\\%(.*)'

=item *

C<'greedy'>

When used in conjunction with C<'any'>, it makes the C<'any'> captures greedy (by default they are not).

    'a***b\\**' ==> 'a(.*?)b\\*(.*?)'
    'a%%%b\\%%' ==> 'a(.*?)b\\%(.*?)'

=item *

C<'brackets'>

Capture matching C<{ ... , ... }> alternations.

    'a{b\\},\\{c}' ==> 'a(b\\}|\\{c)'

=back

    $rw->capture(set => 'single');           # Only capture "exactly one"
                                             # metacharacters.
    $rw->capture('single');                  # Same.
    $rw->capture(add => [ qw<any greedy> ]); # Also greedily capture
                                             # "any" metacharacters.
    $rw->capture(rem => 'greedy');           # No more greed please.
    $rw->capture();                          # Capture nothing.

The C<capture> method returns the L<Regexp::Wildcards> object.

=head2 C<convert>

    my $rx = $rw->convert($wc);
    my $rx = $rw->convert($wc, $type);

Converts the wildcard expression C<$wc> into a regular expression according to the options stored into the L<Regexp::Wildcards> object, or to C<$type> if it's supplied.
It successively escapes all unprotected regexp special characters that doesn't hold any meaning for wildcards, then replace C<'jokers'>, C<'sql'> and C<'commas'> or C<'brackets'> (depending on the L</do> or L</type> options), all of this by applying the C<'capture'> rules specified in the constructor or by L</capture>.

=cut

sub convert {
 my ($self, $wc, $type) = @_;
 _check_self $self;

 my $config = (defined $type) ? $self->_type($type) : $self;
 return unless defined $wc;

 my $e = $config->{escape};
 # Escape :
 # - an even number of \ that doesn't protect a regexp/wildcard metachar
 # - an odd number of \ that doesn't protect a wildcard metachar
 $wc =~ s/
  (?<!\\)(
   (?:\\\\)*
   (?:
     [^\w\s\\$e]
    |
     \\
     (?: [^\W$e] | \s | $ )
   )
  )
 /\\$1/gx;

 my $do = $config->{do};
 $wc = $self->_jokers($wc) if $do->{jokers};
 $wc = $self->_sql($wc)    if $do->{sql};
 if ($do->{brackets}) {
  $wc = $self->_bracketed($wc);
 } elsif ($do->{commas} and $wc =~ /(?<!\\)(?:\\\\)*,/) {
  $wc = $self->{'c_brackets'} . $self->_commas($wc) . ')';
 }

 $wc
}

=head1 EXPORT

An object module shouldn't export any function, and so does this one.

=head1 DEPENDENCIES

L<Carp> (core module since perl 5), L<Scalar::Util>, L<Text::Balanced> (since 5.7.3).

=head1 CAVEATS

This module does not implement the strange behaviours of Windows shell that result from the special handling of the three last characters (for the file extension).
For example, Windows XP shell matches C<*a> like C<.*a>, C<*a?> like C<.*a.?>, C<*a??> like C<.*a.{0,2}> and so on.

=head1 SEE ALSO

L<Text::Glob>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-regexp-wildcards at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Regexp-Wildcards>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Regexp::Wildcards

Tests code coverage report is available at L<http://www.profvince.com/perl/cover/Regexp-Wildcards>.

=head1 COPYRIGHT & LICENSE

Copyright 2007,2008,2009,2013 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

sub _extract ($) { extract_bracketed $_[0], '{',  qr/.*?(?<!\\)(?:\\\\)*(?={)/ }

sub _jokers {
 my $self = shift;
 local $_ = $_[0];

 # substitute ? preceded by an even number of \
 my $s = $self->{c_single};
 s/(?<!\\)((?:\\\\)*)\?/$1$s/g;
 # substitute * preceded by an even number of \
 $s = $self->{c_any};
 s/(?<!\\)((?:\\\\)*)\*+/$1$s/g;

 $_
}

sub _sql {
 my $self = shift;
 local $_ = $_[0];

 # substitute _ preceded by an even number of \
 my $s = $self->{c_single};
 s/(?<!\\)((?:\\\\)*)_/$1$s/g;
 # substitute % preceded by an even number of \
 $s = $self->{c_any};
 s/(?<!\\)((?:\\\\)*)%+/$1$s/g;

 $_
}

sub _commas {
 local $_ = $_[1];

 # substitute , preceded by an even number of \
 s/(?<!\\)((?:\\\\)*),/$1|/g;

 $_
}

sub _brackets {
 my ($self, $rest) = @_;

 substr $rest, 0, 1, '';
 chop $rest;

 my ($re, $bracket, $prefix) = ('');
 while (do { ($bracket, $rest, $prefix) = _extract $rest; $bracket }) {
  $re .= $self->_commas($prefix) . $self->_brackets($bracket);
 }
 $re .= $self->_commas($rest);

 $self->{c_brackets} . $re . ')';
}

sub _bracketed {
 my ($self, $rest) = @_;

 my ($re, $bracket, $prefix) = ('');
 while (do { ($bracket, $rest, $prefix) = _extract $rest; $bracket }) {
  $re .= $prefix . $self->_brackets($bracket);
 }
 $re .= $rest;

 $re =~ s/(?<!\\)((?:\\\\)*[\{\},])/\\$1/g;

 $re;
}

1; # End of Regexp::Wildcards
