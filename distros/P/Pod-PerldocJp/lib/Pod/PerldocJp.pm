package Pod::PerldocJp;

use strict;
use warnings;
use base 'Pod::Perldoc';
use Encode;
use Encode::Guess;
use Term::Encoding;
use HTTP::Tiny;
use Path::Tiny;
use URI::Escape;
use utf8;

my $term_encoding = Term::Encoding::get_encoding() || 'utf-8';

our $VERSION = '0.19';

sub opt_J { shift->_elem('opt_J', @_) }

sub _perldocjp_dir {
  my $self = shift;

  my @subs = (
    sub {
      require File::HomeDir;
      path(File::HomeDir->my_home, '.perldocjp');
    },
    sub { path(File::Spec->tmpdir, '.perldocjp') },
    sub { path('.') },
  );

  foreach my $sub (@subs) {
    my $dir = eval { $sub->() } or next;
    $dir->mkpath;
    return $dir if -d $dir && -w $dir;
  };
}

sub grand_search_init {
  my ($self, $pages, @found) = @_;

  my $dir = $self->_perldocjp_dir()
    or return $self->SUPER::grand_search_init($pages, @found);

    my @encodings =
      split ' ', $ENV{PERLDOCJP_ENCODINGS} || 'euc-jp shiftjis utf8';

  if (not $self->opt_F and ($self->opt_J or ($pages->[0] && $pages->[0] =~ /^https?:/))) {
    my $ua  = HTTP::Tiny->new(agent => "Pod-PerldocJp/$VERSION");

    my $api_url = $ENV{PERLDOCJP_SERVER} || 'http://perldoc.charsbar.org/api/pod';
    $api_url =~ s|/+$||;

    foreach my $page (@$pages) {
      $self->aside("Searching for $page\n");
      my $url = ($page =~ /^https?:/) ? $page : "$api_url/$page";
      my $file = $dir->child(uri_escape($page, '^A-Za-z0-9_') . '.pod');
      unless ($file->exists && $file->stat->size && $file->stat->mtime > time - 60 * 60 * 24) {
        my $res = $ua->mirror($url => "$file");
        if ($res->{success} && (my $pod = $file->slurp) !~ /^=encoding\s/m) {
          # You can't trust perldoc.jp's Content-Type too much.
          # (there're several utf-8 translations, though perldoc.jp
          # is (or was) supposed to use euc-jp)
          my $encoding;
          my $enc = guess_encoding($pod, @encodings);
          if (ref $enc) {
            $encoding = $enc->name;
          }
          elsif (my $ctype = $res->{headers}{'content-type'}) {
            ($encoding) = $ctype =~ /charset\s*=\s*([\w-]+)/;
          }
          if ($encoding) {
            $pod = "=encoding $encoding\n\n$pod";
            $file->spew($pod);
          }
        }
      }
      push @found, "$file" if $file->stat->size;
    }
    return @found if @found;
  }

  @found = $self->SUPER::grand_search_init($pages, @found);

  if ($self->opt_J) {
    foreach my $path (@found) {
      my $pod = path($path)->slurp;
      unless ($pod =~ /^=encoding\s/m) {
        my $encoding;
        my $enc = guess_encoding($pod, @encodings);
        if (ref $enc) {
          $encoding = $enc->name;
          next if $encoding eq 'ascii';
          $pod = "=encoding $encoding\n\n$pod";
          my $file = $dir->child(uri_escape($path, '^A-Za-z0-9_'));
          $file->spew($pod);
          $path = "$file" if $file->stat->size;
        }
      }
    }
  }
  @found;
}

{
  # shamelessly ripped from Pod::Perldoc 3.23 and tweaked

  sub opt_o_with { # "o" for output format
    my($self, $rest) = @_;
    return unless defined $rest and length $rest;
    if($rest =~ m/^(\w+)$/s) {
      $rest = $1; #untaint
    } else {
      $self->warn( qq("$rest" isn't a valid output format.  Skipping.\n") );
      return;
    }

    $self->aside("Noting \"$rest\" as desired output format...\n");

    # Figure out what class(es) that could actually mean...

    my @classes;
    # TWEAKED: to include "Pod::PerldocJp::To"
    foreach my $prefix ("Pod::PerldocJp::To", "Pod::Perldoc::To", "Pod::Simple::", "Pod::") {
      # Messy but smart:
      foreach my $stem (
        $rest,  # Yes, try it first with the given capitalization
        "\L$rest", "\L\u$rest", "\U$rest" # And then try variations

      ) {
        $self->aside("Considering $prefix$stem\n");
        push @classes, $prefix . $stem;
      }

      # Tidier, but misses too much:
      #push @classes, $prefix . ucfirst(lc($rest));
    }
    $self->opt_M_with( join ";", @classes );
    return;
  }

  sub init_formatter_class_list {
    my $self = shift;
    $self->{'formatter_classes'} ||= [];

    # Remember, no switches have been read yet, when
    # we've started this routine.

    $self->opt_M_with('Pod::Perldoc::ToPod');   # the always-there fallthru
    $self->opt_o_with('text');

    # TWEAKED: XXX: should support term later
    # $self->opt_o_with('term') unless $self->is_mswin32 || $self->is_dos
    #   || !($ENV{TERM} && (
    #       ($ENV{TERM} || '') !~ /dumb|emacs|none|unknown/i
    #      ));

    return;
  }

  sub maybe_generate_dynamic_pod {
    my ($self, $found_things) = @_;
    my @dynamic_pod;

    $self->search_perlapi($found_things, \@dynamic_pod)   if  $self->opt_a;

    $self->search_perlfunc($found_things, \@dynamic_pod)  if  $self->opt_f;

    $self->search_perlvar($found_things, \@dynamic_pod)   if  $self->opt_v;

    $self->search_perlfaqs($found_things, \@dynamic_pod)  if  $self->opt_q;

    if( ! $self->opt_f and ! $self->opt_q and ! $self->opt_v and ! $self->opt_a) {
      Pod::Perldoc::DEBUG > 4 and print "That's a non-dynamic pod search.\n";
    } elsif ( @dynamic_pod ) {
      $self->aside("Hm, I found some Pod from that search!\n");
      my ($buffd, $buffer) = $self->new_tempfile('pod', 'dyn');
      if ( $] >= 5.008 && $self->opt_L ) {
        binmode($buffd, ":utf8");
        print $buffd "=encoding utf8\n\n";
      }

      push @{ $self->{'temp_file_list'} }, $buffer;
      # I.e., it MIGHT be deleted at the end.

      my $in_list = !$self->not_dynamic && $self->opt_f || $self->opt_v || $self->opt_a;
      # TWEAKED: to add =encoding utf-8 and encode_utf8
      print $buffd "=encoding utf-8\n\n";
      print $buffd "=over 8\n\n" if $in_list;
      print $buffd map {encode_utf8($_)} @dynamic_pod  or die "Can't print $buffer: $!";
      print $buffd "=back\n"     if $in_list;

      close $buffd        or $self->die( "Can't close $buffer: $!" );

      @$found_things = $buffer;
        # Yes, so found_things never has more than one thing in
        #  it, by time we leave here

      $self->add_formatter_option('__filter_nroff' => 1);

    } else {
      @$found_things = ();
      $self->aside("I found no Pod from that search!\n");
    }

    return;
  }

  sub search_perlfunc {
    my($self, $found_things, $pod) = @_;

    Pod::Perldoc::DEBUG > 2 and print "Search: @$found_things\n";

    my $perlfunc = shift @$found_things;
    open(PFUNC, "<", $perlfunc) # "Funk is its own reward"
        or $self->die("Can't open $perlfunc: $!");

    # Functions like -r, -e, etc. are listed under `-X'.
    my $search_re = ($self->opt_f =~ /^-[rwxoRWXOeszfdlpSbctugkTBMAC]$/)
                        ? '(?:I<)?-X' : quotemeta($self->opt_f) ;

    Pod::Perldoc::DEBUG > 2 and
     print "Going to perlfunc-scan for $search_re in $perlfunc\n";

    my $re = 'Alphabetical Listing of Perl Functions';

    # Check available translator or backup to default (english)
    if ( $self->opt_L && defined $self->{'translators'}->[0] ) {
        my $tr = $self->{'translators'}->[0];
        $re =  $tr->search_perlfunc_re if $tr->can('search_perlfunc_re');
        if ( $] < 5.008 ) {
            $self->aside("Your old perl doesn't really have proper unicode support.");
        }
        else {
            binmode(PFUNC, ":utf8");
        }
    }

    # Skip introduction
    local $_;
    # TWEAKED: to find encoding
    my $encoding = 'utf-8';
    while (<PFUNC>) {
      if (/^=encoding\s+(\S+)/) {
        $encoding = $1;
      }
      last if /^=head2 $re/;
    }

    # Look for our function
    my $found = 0;
    my $inlist = 0;

    my @perlops = qw(m q qq qr qx qw s tr y);

    my @related;
    my $related_re;
    while (<PFUNC>) {  # "The Mothership Connection is here!"
      last if( grep{ $self->opt_f eq $_ }@perlops );

      if ( /^=over/ and not $found ) {
        ++$inlist;
      }
      elsif ( /^=back/ and not $found and $inlist ) {
        --$inlist;
      }


      if ( m/^=item\s+$search_re\b/ and $inlist < 2 )  {
        $found = 1;
      }
      elsif (@related > 1 and /^=item/) {
        $related_re ||= join "|", @related;
        if (m/^=item\s+(?:$related_re)\b/) {
          $found = 1;
        }
        else {
          last if $found > 1 and $inlist < 2;
        }
      }
      elsif (/^=item/) {
        last if $found > 1 and $inlist < 2;
      }
      elsif ($found and /^X<[^>]+>/) {
        push @related, m/X<([^>]+)>/g;
      }
      next unless $found;
      if (/^=over/) {
        ++$inlist;
      }
      elsif (/^=back/) {
        --$inlist;
      }
      # TWEAKED: to decode
      push @$pod, decode($encoding, $_);
      ++$found if /^\w/;        # found descriptive text
    }

    if( !@$pod ){
        $self->search_perlop( $found_things, $pod );
    }

    if (!@$pod) {
      CORE::die( sprintf
        "No documentation for perl function `%s' found\n",
        $self->opt_f )
        ;
    }
    close PFUNC                or $self->die( "Can't open $perlfunc: $!" );

    return;
  }

  sub search_perlvar {
    my ($self, $found_things, $pod) = @_;

    my $opt = $self->opt_v;

    if ( $opt !~ /^ (?: [\@\%\$]\S+ | [A-Z]\w* ) $/x ) {
      CORE::die( "'$opt' does not look like a Perl variable\n" );
    }

    Pod::Perldoc::DEBUG > 2 and print "Search: @$found_things\n";

    my $perlvar = shift @$found_things;
    open(PVAR, "<", $perlvar)               # "Funk is its own reward"
        or $self->die("Can't open $perlvar: $!");

    if ( $opt ne '$0' && $opt =~ /^\$\d+$/ ) { # handle $1, $2, ..., $9
      $opt = '$<I<digits>>';
    }
    my $search_re = quotemeta($opt);

    Pod::Perldoc::DEBUG > 2 and
      print "Going to perlvar-scan for $search_re in $perlvar\n";

    # Skip introduction
    local $_;
    # TWEAKED: to find encoding
    my $encoding = 'utf-8';
    while (<PVAR>) {
      if (/^=encoding\s+(\S+)/) {
        $encoding = $1;
      }
      last if /^=over 8/;
    }

    # Look for our variable
    my $found = 0;
    my $inheader = 1;
    my $inlist = 0;
    while (<PVAR>) {  # "The Mothership Connection is here!"
      last if /^=head2 Error Indicators/;
      # \b at the end of $` and friends borks things!
      if ( m/^=item\s+$search_re\s/ )  {
        $found = 1;
      }
      elsif (/^=item/) {
        last if $found && !$inheader && !$inlist;
      }
      elsif (!/^\s+$/) { # not a blank line
        if ( $found ) {
          $inheader = 0; # don't accept more =item (unless inlist)
	    }
        else {
          @$pod = (); # reset
          $inheader = 1; # start over
          next;
        }
      }

      if (/^=over/) {
        ++$inlist;
      }
      elsif (/^=back/) {
        last if $found && !$inheader && !$inlist;
        --$inlist;
      }
      # TWEAKED: to decode
      push @$pod, decode($encoding, $_);
#     ++$found if /^\w/;        # found descriptive text
    }
    @$pod = () unless $found;
    if (!@$pod) {
      CORE::die( "No documentation for perl variable '$opt' found\n" );
    }
    close PVAR                or $self->die( "Can't open $perlvar: $!" );

    return;
  }

  sub search_perlfaqs {
    my ($self, $found_things, $pod) = @_;

    my $found = 0;
    my %found_in;
    my $search_key = $self->opt_q;

    my $rx = eval { qr/$search_key/ }
      or $self->die( <<EOD );
Invalid regular expression '$search_key' given as -q pattern:
$@
Did you mean \\Q$search_key ?

EOD

    local $_;
    foreach my $file (@$found_things) {
      $self->die( "invalid file spec: $!" ) if $file =~ /[<>|]/;
      open(INFAQ, "<", $file)  # XXX 5.6ism
        or $self->die( "Can't read-open $file: $!\nAborting" );
      # TWEAKED: to find encoding
      my $encoding = 'utf-8';
      while (<INFAQ>) {
        if (/^=encoding\s+(\S+)/) {
          $encoding = $1;
        }
        if ( m/^=head2\s+.*(?:$search_key)/i ) {
          $found = 1;
          push @$pod, "=head1 Found in $file\n\n" unless $found_in{$file}++;
        }
        elsif (/^=head[12]/) {
          $found = 0;
        }
        next unless $found;
        # TWEAKED: to decode
        push @$pod, decode($encoding, $_);
      }
      close(INFAQ);
    }
    CORE::die("No documentation for perl FAQ keyword `$search_key' found\n")
      unless @$pod;

    if ( $self->opt_l ) {
        CORE::die((join "\n", keys %found_in) . "\n");
    }
    return;
  }

  sub search_perlapi {
    my($self, $found_things, $pod) = @_;

    Pod::Perldoc::DEBUG > 2 and print "Search: @$found_things\n";

    my $perlapi = shift @$found_things;
    open(PAPI, "<", $perlapi)               # "Funk is its own reward"
      or $self->die("Can't open $perlapi: $!");

    my $search_re = quotemeta($self->opt_a);

    Pod::Perldoc::DEBUG > 2 and
     print "Going to perlapi-scan for $search_re in $perlapi\n";

    # Check available translator or backup to default (english)
    if ( $self->opt_L && defined $self->{'translators'}->[0] ) {
      my $tr = $self->{'translators'}->[0];
      if ( $] < 5.008 ) {
        $self->aside("Your old perl doesn't really have proper unicode support.");
      }
      else {
        binmode(PAPI, ":utf8");
      }
    }

    local $_;
    # TWEAKED: to find encoding
    my $encoding = 'utf-8';
    while (<PAPI>) {
      if (/^=encoding\s+(\S+)/) {
        $encoding = $1;
      }
      last if /^=over 8/;
    }

    # Look for our function
    my $found = 0;
    my $inlist = 0;

    my @related;
    my $related_re;
    while (<PAPI>) {  # "The Mothership Connection is here!"
      if ( m/^=item\s+$search_re\b/ )  {
        $found = 1;
      }
      elsif (@related > 1 and /^=item/) {
        $related_re ||= join "|", @related;
        if (m/^=item\s+(?:$related_re)\b/) {
          $found = 1;
        }
        else {
          last;
        }
      }
      elsif (/^=item/) {
        last if $found > 1 and not $inlist;
      }
      elsif ($found and /^X<[^>]+>/) {
        push @related, m/X<([^>]+)>/g;
      }
      next unless $found;
      if (/^=over/) {
        ++$inlist;
      }
      elsif (/^=back/) {
        last if $found > 1 and not $inlist;
        --$inlist;
      }
      push @$pod, decode($encoding, $_);
      ++$found if /^\w/;        # found descriptive text
    }

    if (!@$pod) {
      CORE::die( sprintf
        "No documentation for perl api function '%s' found\n",
        $self->opt_a )
      ;
    }
    close PAPI                or $self->die( "Can't open $perlapi: $!" );

    return;
  }

  # TWEAKED: translation and encoding
  sub usage {
    my $self = shift;
    $self->warn( "@_\n" ) if @_;

    # Erase evidence of previous errors (if any), so exit status is simple.
    $! = 0;

    my $usage = <<"EOF";
perldoc [options] PageName|ModuleName|ProgramName|URL...
perldoc [options] -f BuiltinFunction
perldoc [options] -q FAQRegex
perldoc [options] -v PerlVariable

オプション:
    -h   このヘルプを表示する
    -V   バージョンを表示する
    -r   再帰検索 (時間がかかります)
    -i   大文字小文字を無視する
    -t   pod2manとnroffではなくpod2textを使って表示(デフォルト)
    -u   整形前のPODを表示する
    -m   指定したモジュールのコードも含めて表示する
    -n   nroffのかわりを指定する
    -l   モジュールのファイル名を表示する
    -F   引数はモジュール名ではなくファイル名である
    -D   デバッグメッセージを表示する
    -T   ページャを通さずに画面に出力する
    -d   保存するファイル名
    -o   出力フォーマット名
    -M   フォーマット用のモジュール名(FormatterModuleNameToUse)
    -w   フォーマット用のオプション:値(formatter_option:option_value)
    -L   国別コード。（あれば）翻訳を表示します
    -X   あれば索引を利用する (pod.idxを探します)
    -J   perldoc.jpの日本語訳も検索
    -q   perlfaq[1-9]の質問を検索
    -f   Perlの組み込み関数を検索
    -a   Perl APIを検索
    -v   Perlの定義済み変数を検索

PageName|ModuleName|ProgramName|URL...
    表示したいドキュメント名です。「perlfunc」のようなページ名、
    モジュール名(「Term::Info」または「Term/Info」)、「perldoc」
    のようなプログラム名、http(s)で始まるURLを指定できます。

BuiltinFunction
    Perlの関数名です。「perlfunc」ないし「perlop」からドキュメント
    を抽出します。

FAQRegex
    正規表現です。perlfaq[1-9]を検索してマッチした質問を抽出します。

PERLDOC環境変数で指定したスイッチはコマンドライン引数の前に適用されます。
PODの索引には(あれば)ファイル名の一覧が(1行に1つ)含まれています。

[PerldocJp v$Pod::PerldocJp::VERSION based on Perldoc v$Pod::Perldoc::VERSION]
EOF

    CORE::die encode($term_encoding => $usage);
  }

  sub usage_brief {
    my $self = shift;
    my $program_name = $self->program_name;

    my $usage =<<"EOUSAGE";
使い方: $program_name [-hVriDtumFXlTJ] [-n nroffer_program]
     [-d output_filename] [-o output_format] [-M FormatterModule]
     [-w formatter_option:option_value] [-L translation_code]
     PageName|ModuleName|ProgramName

Examples:

       $program_name -f PerlFunc
       $program_name -q FAQKeywords
       $program_name -v PerlVar
       $program_name -a PerlAPI

-hオプションをつけるともう少し詳しいヘルプが表示されます。
詳細は"perldocjp perldocjp"をご覧ください。
[PerldocJp v$Pod::PerldocJp::VERSION based on Perldoc v$Pod::Perldoc::VERSION]
EOUSAGE

    CORE::die encode($term_encoding => $usage);
  }
}

1;

__END__

=encoding utf-8

=head1 NAME

Pod::PerldocJp - perldoc that also checks perldoc.jp

=head1 SYNOPSIS

  perldocjp perlfunc  # show original version
  perldocjp perldocjp # 日本語で使い方を見る

=head1 DESCRIPTION

This is a drop-in-replacement for C<perldoc> for Japanese people. Usage is the same, except it looks for a translation at L<http://perldoc.jp>.

=head1 TWEAKED METHODS

=head2 opt_J

to support -J option.

=head2 grand_search_init

looks for a translation at perldoc.jp.

=head2 opt_o_with

looks also under Pod::PerldocJp namespace.

=head2 init_formatter_class_list

always try to use "text" formatter.

=head2 maybe_generate_dynamic_pod

adds encoding info while writing a temp file to show.

=head2 search_perlfaqs, search_perlfunc, search_perlvar, search_perlapi

decode while searching.

=head2 usage, usage_brief

are translated.

=head1 SEE ALSO

L<Pod::Perldoc>, L<Pod::Perldocs>

And for Japanized Perl Resources Project:

=over 4

=item L<http://perldoc.jp/>

=item L<http://perldocjp.sourceforge.jp/>

=item L<http://www.freeml.com/perldocjp>

=back

Kudos to all the contributors thereof.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
