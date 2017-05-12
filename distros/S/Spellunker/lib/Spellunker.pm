package Spellunker;
use strict;
use warnings FATAL => 'all';
use utf8;
use 5.008001;

use version; our $VERSION = version->declare("v0.4.0");

use Scalar::Util ();
use File::Spec ();
use File::ShareDir ();
use Regexp::Common qw /URI/;

# Ref http://www.din.or.jp/~ohzaki/mail_regex.htm#Simplify
my $MAIL_REGEX = (
    q{(?:[-!#-'*+/-9=?A-Z^-~]+(?:\.[-!#-'*+/-9=?A-Z^-~]+)*|"(?:[!#-\[\]-} .
    q{~]|\\\\[\x09 -~])*")@[-!#-'*+/-9=?A-Z^-~]+(?:\.[-!#-'*+/-9=?A-Z^-~]+} .
    q{)*}
);


sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    my $self = bless {}, $class;

    # From https://code.google.com/p/dotnetperls-controls/downloads/detail?name=enable1.tx
    $self->load_dictionary(File::Spec->catfile(File::ShareDir::dist_dir('Spellunker'), 'enable1.txt'));
    $self->load_dictionary(File::Spec->catfile(File::ShareDir::dist_dir('Spellunker'), 'spellunker-dict.txt'));

    unless ($ENV{PERL_SPELLUNKER_NO_USER_DICT}) {
        $self->_load_user_dict();
    }
    return $self;
}

sub _load_user_dict {
    my $self = shift;
    my $home = $ENV{HOME};
    return unless defined $home;
    return unless -d $home;
    my $dictpath = File::Spec->catfile($home, '.spellunker.en');
    if (-f $dictpath) {
        $self->load_dictionary($dictpath);
    }
}

sub load_dictionary {
    my ($self, $filename_or_fh) = @_;

    my $fh;
    if (Scalar::Util::openhandle($filename_or_fh)) {
        $fh = $filename_or_fh;
    }
    else {
        open $fh, '<:utf8', $filename_or_fh
            or die "Cannot open '$filename_or_fh' for reading: $!";
    }

    local $/;
    my $chunk = <$fh>;
    $chunk =~ s/\#[^\n]*$//xmsg; # remove comments.
    $self->add_stopwords(split ' ', $chunk);
}

sub add_stopwords {
    my $self = shift;
    for (@_) {
        $self->{stopwords}->{$_}++
    }
    return undef;
}

sub clear_stopwords {
    my $self = shift;
    undef $self->{stopwords};
}

sub check_word {
    my ($self, $word) = @_;
    return 0 unless defined $word;

    return 1 if length($word)==0;
    return 1 if length($word)==1;

    # There is no alphabetical characters.
    return 1 if $word !~ /[A-Za-z]/;

    # git sha1
    return 1 if $word =~ /\A[a-z0-9]{40}\z/;

    # 19xx 2xx
    return 1 if $word =~ /^[0-9]+(xx|yy)$/;
    # 4th
    return 1 if $word =~ /^[0-9]+(th)$/;

    # Method name
    return 1 if $word =~ /\A([a-zA-Z0-9]+_)+[a-zA-Z0-9]+\z/;

    # Extensions
    return 1 if $word =~ /\A\.[a-zA-Z0-9]{2,4}\z/;

    # File name
    return 1 if $word =~ /\A[a-zA-Z0-9-]+\.[a-zA-Z0-9]{1,4}\z/;

    return 1 if looks_like_domain($word);
    return 1 if looks_like_perl_code($word);
    return 1 if looks_like_file_path($word);

    # Ignore capital letter words like RT, RFC, IETF.
    # And so "IT'S" should be allow.
    # AUTHORS
    # APIs
    return 1 if $word =~ /\A [A-Z']+ s? \z/x;

    # good
    return 1 if $self->{stopwords}->{$word};

    # ucfirst-ed word.
    # 'How'
    # Dan
    if ($word =~ /\A[A-Z][a-z]+\z/) {
        return 1;
    }

    # CamelCase-ed word like "McCamant"
    if ($word =~ /\A [A-Z][a-z]+ (?:[A-Z][a-z]+)+ \z/x) {
        return 1;
    }

    # Suffix rules
    return 1 if $word =~ /\A
        (.*?)
        (?:
            's   # Dan's
          | s'   # cookies'
          | 've  # You've
          | 're  # We're
          | 'll  # You'll
          | n't  # doesn't
          | 'd   # You'd
          | -ish # -ish
        )
    \z/x && $self->check_word($1);

    # comE<gt>
    ## Prefixes
    return 1 if $word =~ /\Anon-(.*)\z/ && $self->check_word($1);
    return 1 if $word =~ /\Are-(.*)\z/ && $self->check_word($1);

    # <p></p>
    return 1 if $word =~ /\A<p>(.*)<\/p>\z/ && $self->check_word($1);

    # :Str - Moose-ish type definition
    return 1 if $word =~ /\A
        :
        (?:[A-Z][a-z]+)+
    \z/x;

    # IRC channel name
    return 1 if $word =~ /\A#[a-z0-9-]+\z/;

    # Suffix
    return 1 if $word =~ /\A(.*?)[^A-Za-z]+\z/ && $self->check_word($1);
    # Prefix
    return 1 if $word =~ /\A[^A-Za-z]+(.*?)\z/ && $self->check_word($1);

    if ($word =~ /[^A-Za-z]+/) {
        my @words = split /[^A-Za-z]+/, $word;
        my $ok = 0;
        for (@words) {
            if ($self->check_word($_)) {
                $ok++;
            }
        }
        return 1 if @words == $ok;
    }

    return 0;
}

sub looks_like_file_path {
    my ($word) = @_;

    # ~/
    # ~/foo/
    # ~foo/
    # /dev/tty
    # t/01_simple.t
    return 1 if $word =~ m{\A
        (?:
            ~ [a-zA-Z0-9_.-]* / (?: [a-z0-9A-Z_.-]+ / )* (?: [a-z0-9A-Z_.-]+ )?
        |
            / (?: [a-z0-9A-Z_.-]+ / )* (?: [a-z0-9A-Z_.]+ )?
        |
            (?: [a-z0-9A-Z_.-]+ / )+ (?: [a-z0-9A-Z_.]+ )?
        )
    \z}x;
    return 0;
}

sub looks_like_domain {
    my ($word) = @_;
    return 1 if $word =~ /\A
        ([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}
    \z/x;
    return 0;
}

sub check_line {
    my ($self, $line) = @_;
    return unless defined $line;

    $line =~ s!<$MAIL_REGEX>|$MAIL_REGEX!!;            # Remove E-mail address.
    $line =~ s!$RE{URI}{HTTP}{-scheme => 'https?'}!!g; # Remove HTTPS? URI

    my @bad_words;
    for ( grep /\S/, split /[\|*=\[\]`" \t,?!]+/, $line) {
        s/\n//;

        if (/\A'(.*)'\z/) {
            push @bad_words, $self->check_line($1);
        } elsif (/\A(.*)\.\z/) { # The word ended by dot
            my $word = $1;
            $self->check_word($word)
                or push @bad_words, $word;
        } elsif (/\./) { # The word includes dot
            $self->check_word($_)
                or push @bad_words, $_;
        } else {
            # Ignore command line options
            next if /\A
                --
                (?: [a-z]+ - )+
                [a-z]+
            \z/x;

            $self->check_word($_)
                or push @bad_words, $_;
        }
    }
    return @bad_words;
}

sub looks_like_perl_code {
    my $PERL_NAME = '[A-Za-z_][A-Za-z0-9_]*';

    # Class name
    # Foo::Bar
    # JSON::PP::
    return 1 if $_[0] =~ /\A
        [\+\$]?
        (?: $PERL_NAME :: )+
        $PERL_NAME
        $PERL_NAME?
    \z/x;

    # foo()
    return 1 if $_[0] =~ /\A
        $PERL_NAME
        \(
            \s*
            ( \$ $PERL_NAME \s* , \s*  )*
            ( \$ $PERL_NAME )?
            \s*
        \)
    \z/x;

    # 5.8.x
    # 5.10.x
    return 1 if $_[0] =~ /\A
        [0-9]+\.[0-9]+\.x
    \z/x;

    # U+002F
    return 1 if $_[0] =~ /\A
        U \+ [0-9a-fA-F]{4,}
    \z/x;

    # \x00-\x1f\x22\x2f\x5c
    # \x2f
    return 1 if $_[0] =~ /\A
        (
            \\ x [0-9a-fA-F][0-9a-fA-F] -?
        )+
    \z/x;

    # $foo
    # %foo
    # @foo
    # *foo
    # \$foo
    return 1 if $_[0] =~ /\A
        \\?
        [\*\@\$\%]
        $PERL_NAME
    \z/x;

    # Spellunker->bar
    # Foo::Bar->bar
    # $foo->bar
    # $foo->bar()
    return 1 if $_[0] =~ /\A
        (?:
            \$ $PERL_NAME
            | ( $PERL_NAME :: )* $PERL_NAME
        )
        ->
        $PERL_NAME
        (?:\([^\)]*\))?
    \z/x;

    # hash access
    return 1 if $_[0] =~ /\A
        \$ $PERL_NAME \{ $PERL_NAME \}
    \z/x;

    # hashref access
    return 1 if $_[0] =~ /\A
        \$ $PERL_NAME -> \{ $PERL_NAME \}
    \z/x;

    # JSON::XS-ish boolean value
    return 1 if $_[0] eq '\1' || $_[0] eq '\1';

    return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

Spellunker - Pure perl spelling checker implementation

=head1 DESCRIPTION

Spellunker is pure perl spelling checker implementation.
You can use this spelling checker as a library.

And this distribution provides L<spellunker> and L<spellunker-pod> command.

If you want to use this spelling checker in test script, you can use L<Test::Spellunker>.

=head1 METHODS

=over 4

=item my $spellunker = Spellunker->new();

Create new instance.

=item $spellunker->load_dictionary($filename_or_fh)

Loads stopwords from C<$filename_or_fh> and adds them to the on-memory dictionary.

=item $spellunker->add_stopwords(@stopwords)

Add some C<< @stopwords >> to the on memory dictionary.

=item $spellunker->clear_stopwords();

Crear the information of stop words.

=item $spellunker->check_word($word);

Check the word looks good or not.

=item @bad_words = $spellunker->check_line($line)

Check the text and returns bad word list.

=back

=head1 HOW DO I USE CUSTOM DICTIONARY?

You can put your personal dictionary at C<$HOME/.spellunker.en>.

=head1 WHY DOES SPELLUNKER NOT IGNORE PERL CODE?

In some case, Spellunker does not ignore the perl code. You need to wrap it by CE<lt> E<gt>.

=head1 CONTRIBUTION

You can send me pull-request on github

=head1 LICENSE

Copyright (C) tokuhirom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

