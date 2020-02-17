##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

package PApp::I18n;

=head1 NAME

PApp::I18n - internationalisation support for PApp

=head1 SYNOPSIS

   use PApp::I18n;
   # nothing exported by default

   my $translator = PApp::I18n::open_translator("/libdir/i18n/myapp", "de");
   my $table = $translator->get_table("uk,de,en"); # will return de translator
   print $table->gettext("yeah"); # better define __ and N_ functions

=head1 DESCRIPTION

This module provides basic translation services, .po-reader and writer
support and text and database scanners to identify tagged strings.

=head2 Anatomy of a Language/Locale ID

A "language" can be designated by either a free-form-string (that doesn't
match the following formal definition) or a language-region code that must match the
following regex:

 /^ ([a-z][a-z][a-z]?) (?:[-_] ([a-z][a-z][a-z]?))? (?:\.(\S+))? $/ix
     ^                  ^  ^    ^
    "two or three letter code"
                       "optionally followed by"
                          "- or _ as seperator"
                               "two or three letter code"
                                                    "optionally followed by"
                                                       ". as seperator"
                                                         "character encoding"

There is no charset indicator, as only utf-8 is supported currently. The
first part must be a two or three letter code from iso639-2/t (alpha2 or
alpha3), optionally followed by the two or three letter country/region
code from iso3166-1 and -2. Numeric region codes might be supported one day.

=cut

no warnings;
use utf8;
no bytes;

use File::Glob;
use Convert::Scalar 'weaken';
use Convert::Scalar ':utf8';

use PApp::Exception;
use PApp::SQL;
use PApp::Config;

BEGIN {
   use base 'Exporter';

   $VERSION = 2.2;
   @EXPORT = qw();
   @EXPORT_OK = qw(
         open_translator
         scan_file scan_init scan_end scan_field 
         export_dpo
         normalize_langid translate_langid locale_charsets
   );

   require XSLoader;
   XSLoader::load PApp::I18n, $VERSION;
}

my ($iso3166, $iso639, $locale) = do {
   local $/;
   split /^__SPLIT__/m, utf8_on <DATA>
};

close DATA;

{
   sub iso639          { [map [split /\s+/, $_, 3], split /\n/, $iso639 ] }
   sub iso639_a2_a3    { $iso639 =~ /^(...)\t\Q$_[0]\E\t/m ? $1 : $_[0] }
   sub iso639_a3_name  { $iso639 =~ /^\Q$_[0]\E\t[^\t]*\t(.*)$/m and $1 }

   sub iso3166         { [map [split /\s+/, $_, 3], split /\n/, $iso3166] }
   sub iso3166_a2_a3   { $iso3166 =~ /^(...)\t\Q$_[0]\E\t/m ? $1 : $_[0] }
   sub iso3166_a3_name { $iso3166 =~ /^\Q$_[0]\E\t[^\t]*\t(.*)$/m and $1 }

   sub locale2charsets { $locale =~ /^\Q$_[0]\E\t(.*)$/m and $1 }
}

our $i18ndir;

=over 4

=item set_base $path

Set the default i18n directory to C<$path>. This must be done before any
calls to C<translate_langid> or when using relative i18n paths.

=cut

sub set_base($) {
   $i18ndir = shift;
}

=item normalize_langid $langid

Normalize the language and country id into it's three-letter form, if
possible. This requires a grep through a few kb of text but the result is
cached. The special language code "*" is translated to "mul".

=cut

our %nlid_cache = ();

my $locale_regex = qr/^
           ([a-z][a-z][a-z]?)
   (?:[-_] ([a-z][a-z][a-z]?))?
   (?:\.   (\S+))?
$/ix;

sub normalize_langid($) {
   use bytes;
   $nlid_cache{$_[0]} ||= do {
      local $_ = lc $_[0];
      if ($_ =~ $locale_regex) {
         my ($l, $c, $e) = (lc $1, lc $2, lc $3);
         $l = "mul" if $l eq "*";
         $l = iso639_a2_a3  $l if 3 > length $l;
         $l = "heb" if $l eq "iw"; # "iw" is the old code, which has not been reused so far
         $l = "yid" if $l eq "ji"; # "ji" is the old code, which has not been reused so far
         if ($c ne "") {
            $c = iso3166_a2_a3 $c if 3 > length $c;
            $l .= "_$c";
         }
         $l = "zha" if $l eq "zho_twn"; # new code "Zhuang" for "Chinese Traditional"
         $l = "zho" if $l eq "zho_chn"; # old code "Chinese" here means "Chinese Simplified"
         if ($e ne "") {
            $l .= ".$e";
         }
         $l;
      } else {
         $_;
      }
   }
}

=item translate_langid $langid[, $langid]

Decode the first C<langid> into a description of itself and translate it
into the language specified by the second C<langid> (the latter does not
work yet). The result of this function is being cached.

=cut

our %tlid_cache = ();
our $tlid_iso3166;
our $tlid_iso639;

# perl does STRANGE things to characters when using
# ucfirst unarmed (like duplicating han characters etc...)
sub _ucfirst {
   local $_ = shift;
   substr($_,0,1) =~ y[abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþ]
                      [ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞ];
   $_;
}

sub translate_langid($;$) {
   $tlid_cache{"$_[0]\x00$_[1]"} ||= do {
      my $langid = normalize_langid $_[0];
      my $dest = $_[1];
      use bytes;
      if ($langid =~ $locale_regex) {
         no bytes;
         my ($l, $c) = ($1, $2);
         $l = iso639_a3_name $l;
         if (@_) {
            $tlid_iso639 ||= open_translator ("iso639", "en");
            $l = _ucfirst $tlid_iso639->get_table ($_[0])->gettext ($l);
         }
         if ($c) {
            $c = iso3166_a3_name $c;
            if (@_) {
               no bytes;
               $tlid_iso3166 ||= open_translator ("iso3166", "en");
               $c = _ucfirst $tlid_iso3166->get_table ($_[0])->gettext ($c);
            }
            return "$l ($c)" if $c;
         } elsif ($l) {
            return $l;
         }
      }
      undef;
   }
}

=item locale_charsets $locale

Returns a list of character sets that might be good to use for this
locale. This definition is neccessarily imprecise.

The charsets returned should be considered to be in priority order, i.e.
the first charset is the best. The intention of this function is to
provide a list of character sets to try when outputting html text (you can
output any html text in any encoding supporting html's active characters,
so this is indeed a matter of taste).

If the locale contains a character set it will be the first in the
returned list. The other charsets are taken from a list (see the source of
this module for details).

Here are some examples of what you might expect:

   de          => iso-8859-1 iso-8859-15 cp1252 utf-8
   rus_ukr     => koi8-u iso-8859-5 cp1251 iso-ir-111 cp866 koi8-r iso-8859-5
                  cp1251 iso-ir-111 cp866 koi8-u utf-8
   ja_JP.UTF-8 => utf-8 euc-jp sjis iso-2022-jp jis7 utf-8

This function can be slow and does NOT cache any results.

=cut

sub locale_charsets($) {
   my $locale = normalize_langid $_[0];
   my @charsets;
   
   if ($locale =~ $locale_regex) {
      my ($lang, $country, $charset) = (lc $1, lc $2, lc $3);
      push @charsets, $charset if $charset ne "";
      push @charsets, split /,/, locale2charsets "$1_$2";
      push @charsets, split /,/, locale2charsets $1;
   } else {
      push @charsets, split /,/, locale2charsets $_[0];
   }

   (@charsets, "utf-8")
}

our @table_registry;

END {
   # work around a bug perl5.6
   # it seems that global destruction (which has undefined order)
   # causes killbackrefs to fail because the weak ref is already destroyed
   undef @table_registry;
}

=back

=head2 Translation Support

=over 4

=item open_translator $path, lang1, lang2....

Open an existing translation directory. A translation directory can
contain any number of language translation tables with filenames of the
form "language.dpo". Since the translator cannot guess in which language
the source has been written you have to specify this by adding additional
language names.

=cut

sub open_translator {
   my $path = shift;
   new PApp::I18n path => $path, langs => [@_];
}

sub new {
   my $class = shift;
   my $self = { @_ };
   bless $self, $class;

   $self->{path} = "$i18ndir/$self->{path}" unless $self->{path} =~ /^\//;

   opendir local *DIR, "$self->{path}"
      and push @{$self->{langs}}, grep s/\.dpo$//, readdir *DIR;

   my %uniq; @{$self->{langs}} = grep !$uniq{$_}++,
                                    map normalize_langid($_),
                                        @{$self->{langs}};

   push @table_registry, $self;
   weaken($table_registry[-1]);
   $self;
}

=item $translator->langs

Return all languages supported by this translator (in normalized form). Can be
used to create language-selectors, for example.

=cut

sub langs {
   @{$_[0]->{langs}};
}

#=item expand_lang langid, langid... [internal utility function]
#
#Try to identify the closest available language. #fixme#
#
#=cut

sub expand_lang {
   my $langs = shift;
   my $lang;
   my %lang;
   @lang{@_} = @_;

   for (split /,/, $langs) {
      $lang = normalize_langid $_; $lang =~ s/^\s+//; $lang =~ s/\s+$//; $lang =~ y/-/_/;
      next unless $lang;
      return $lang if exists $lang{$lang};
      $lang =~ s/_.*$//;
      return $lang if exists $lang{$lang};
      for (keys %lang) {
         if (/^${lang}_/) {
            return $_;
         }
      }
   }
   ();
}

=item $table = $translator->get_table($languages)

Find and return a translator table for the language that best matches the
C<$languages>. This function always succeeds by returning a dummy trable
if no (physical) table can be found. This function is very fast in the
general case.

=cut

sub get_table {
   $_[0]->{table_cache}{$_[1]} ||= do {
      my ($self, $langs) = @_;

      # first, map the "langs" into a real language code
      $lang = expand_lang $langs, @{$self->{langs}};

      # then map the lang into the corresponding .dpo file
      my $db = $self->{db}{$lang};
      unless ($db) {
         my $path = "$self->{path}/$lang.dpo";
         $self->{db}{$lang} = $db = new PApp::I18n::Table -r $path && $path, $lang;
         $db or fancydie "unable to open translation table '$lang'", "in directory '$self->{path}'";
      }
      $db;
   }
}

=item $translation = $table->gettext($msgid)

Find the translation for $msgid, or return the original string if no
translation is found. If the msgid starts with the two characters "\"
and "{", then these characters and all remaining characters until the
closing '}' are skipped before attempting a translation. If you do want
to include these two characters at the beginning of the string, use the
sequence "\{\{". This can be used to specify additional arguments to some
translation steps (like the language used). Here are some examples:

  string      =>    translation
  \{\string   =>    \translation
  \{\{string  =>    \{translation
  \{}string   =>    translation

To ensure that the string is translated "as is" just prefix it with "\{}".

=item $lang = $table->lang

Return the language this translation table contains.

=cut

=item flush_cache

Flush the translation table cache. This is rarely necessary, translation
hash files are not written to. This can be used to ensure that new calls
to C<get_table> get the updated tables instead of already opened ones.

=cut

sub flush_cache {
   if (@_) {
      my $self = shift;
      delete $self->{db};
      delete $self->{table_cache};
   } else {
      my @tables = @table_registry;
      @table_registry = ();
      for(@tables) {
         if ($_) {
            push @table_registry, $_;
            $_->flush_cache;
         }
      }
   }
   $tlid_cache = ();
   $nlid_cache = ();
}

#############################################################################

use PApp::SQL;

=back

=head2 Scanning Support

As of yet undocumented

=over 4

=cut

sub quote($) {
   local $_ = shift;

   s/\\/\\\\/g;
   s/\"/\\"/g;
   s/\n/\\n/g;
   s/\r/\\r/g;
   s/\t/\\t/g;
   s/([\x00-\x1f\x80-\x9f])/sprintf "\\x%02x", ord $1/ge;
   #s/([\x{0100}-\x{ffff}])/sprintf "\\x{%04x}", ord($1)/ge;
   $_
}

sub unquote($) {
   local $_ = shift;

   s{\\(?:
      "                     (?{ "\"" })
    | n                     (?{ "\n" })
    | r                     (?{ "\r" })
    | t                     (?{ "\t" })
    | x ([0-9a-fA-F]{2,2})  (?{ chr hex $1 })
    | x \{([0-9a-fA-F]+)\}  (?{ chr hex $2 })
    | \\                    (?{ "\\" })
    | (.)                   (?{ "<unknown escape $3>" })
   )}{
      $^R
   }gex;
   $_
}

sub reorganize_i18ndb {
   local $PApp::SQL::DBH = PApp::Config::DBH;

   my $st = sql_exec "select i.nr, s.lang
                      from msgid i, msgstr s
                      where i.nr = s.nr and i.lang = s.lang";
   while (my($nr, $lang) = $st->fetchrow_array) {
      sql_exec "delete from msgstr where nr = ? and lang = ?", $nr, $lang;
   }

   # and non-context msgstr's
   sql_exec "delete from msgid where context = ''";

   # delete msgid-less msgstr's
   my $st = sql_exec "select s.nr
                      from msgstr s left join msgid i using (nr)
                      where i.nr is null";
   while (my($nr) = $st->fetchrow_array) {
      sql_exec "delete from msgstr where nr = ?", $nr;
   }
}

=item \%trans = fuzzy_translation $string, [$domain]

Try to find a translation for the given string in the given domain (or
globally) by finding the most similar string already in the database and
return its translation(s).

=cut

sub fuzzy_translation  {
   my ($string, $domain) = @_;
   local $PApp::SQL::DBH = PApp::Config::DBH;

   require String::Similarity;

   my ($st, $nr, $id);
   if ($domain) {
      $st = sql_exec \($nr, $id, $lang, $msg),
                     "select i.nr, i.id, s.lang, s.msg
                      from msgid as i, msgstr as s
                      where i.nr = s.nr
                            and domain = ?
                            and flags & 1 != 0
                      order by nr",
                     $domain;
   } else {
      $st = sql_exec \($nr, $id, $lang, $msg),
                     "select i.nr, i.id, s.lang, s.msg
                      from msgid as i, msgstr as s
                      where i.nr = s.nr
                            and flags & 1 != 0
                      order by nr",
   }

   my %w;
   my %trans;

   # we use a minimum similarity of 0.6

   while ($st->fetch) {
      my $w = String::Similarity::fstrcmp($string, $id, $w{$lang} ||= 0.6);

      if ($w >= $w{$lang}) {
         $trans{$lang} = utf8_on $msg;
         $w{$lang} = $w;
      }
   }

   \%trans
}

# our instead of my due to mod_perl bugs
our %scan_msg;
our $scan_app;

=item scan_init $domain

=cut

sub scan_init {
   ($scan_app) = @_;
   utf8_upgrade $scan_app;
   %scan_msg = ();
   sql_exec "update msgid set context = '' where domain = ?", $scan_app;
}

sub scan_add {
   my ($lang, $id, $context) = @_;
   push @{$scan_msg{$lang}{$id}}, $context;
}

=item scan_str $prefix, $string, $lang

=cut

sub scan_str($$$) {
   my ($prefix, $string, $lang) = @_;
   my $line = 1;

   # macintoshes not supported, but who cares ;-<
   while() {
      if ($string =~ m/\G
         (
            (?> [^\012N_]+ | [N_][^\012_] | [N_]_[^\012"(] )*
            [N_]_
               \(?" (
                  (?> [^"\\]+ | \\. )+
               ) "\)?
            (?> [^\012N_]+ | [N_][^\012_] | [N_]_[^\012"(] )*
         )
      /sgcx) {
         my ($context, $id) = ($1, $2);
         scan_add $lang, PApp::I18n::unquote $id, "$prefix:$line $context";
         $line += $context =~ y%\012%%;
      } elsif ($string =~ m/\G([^\012]*)\012/sgc) {
         $line++;
      } else {
         last;
      }
   }
}

=item scan_file

=cut

sub scan_file($$) {
   my ($path, $lang) = @_;
   local *FILE;
   print "file '$path' for '$scan_app' in '$lang'\n";
   open FILE, "<", $path or fancydie "unable to open file for scanning", "$path: $!";
   local $/;
   my $file = <FILE>;
   utf8::decode $file;
   scan_str ($path, $file, $lang);
}

=item scan_field $dsn, $field, $style, $lang

=cut

sub scan_field {
   my ($dsn, $field, $style, $lang) = @_;
   my $table;
   print "field $field for '$scan_app' in '$lang'\n";
   my $db = $dsn->checked_dbh;
   ($table, $field) = split /\./, $field;
   my $st = sql_exec $db, "show columns from $table like ?", $field;
   my $type = $st->fetchrow_arrayref;
   defined $type or fancydie "no such table", "$table.$field";
   $type = utf8_on $type->[1];
   if ($type =~ /^(set|enum)\('(.*)'\)$/) {
      for (split /','/, $2) {
         scan_add $lang, $_, "DB:".$dsn->dsn.":$table:$field:$1";
      }
   } else {
      my $row;
      my $st = sql_exec $db, \my($msgid), "select $field from $table";
      my $prefix = $dsn->dsn."/$table.$field";
      while ($st->fetch) {
         utf8_on $msgid;
         $row++;
         if ($style eq "code"
             or ($style eq "auto"
                 and $msgid =~ /[_]_"(?:[^"\\]+|\\.)+"/s)) {
            scan_str "$prefix:$row $msgid", $msgid, $lang;
         } else {
            scan_add $lang, $msgid, "$prefix:$row";
         }
      }
   }
}

=item scan_end

=cut

sub scan_end {
   local $PApp::SQL::DBH = PApp::Config::DBH;
   my $st0 = $PApp::SQL::DBH->prepare ("select nr from msgid where id = ? and domain = ? and lang = ?");
   my $st1 = $PApp::SQL::DBH->prepare ("update msgid set context = ? where nr = ?");
   while (my ($lang, $v) = each %scan_msg) {
      while (my ($msg, $context) = each %$v) {
         $context = join "\n", @$context;
         utf8::encode $msg; utf8::encode $lang; utf8::encode $context;
         $st0->execute ($msg, $scan_app, $lang);
         my $nr = $st0->fetchrow_arrayref;
         if ($nr) {
            $st1->execute ($context, $nr->[0]); $st1->finish;
         } else {
            $nr = sql_insertid
                     sql_exec "insert into msgid (id, domain, lang, context) values (?, ?, ?, ?)",
                              $msg, $scan_app, $lang, $context;

            # now enter existing, similar, translations
            my $trans = fuzzy_translation $msg, $scan_app;
            while (my ($lang, $str) = each %$trans) {
               sql_exec "insert into msgstr (nr, lang, flags, msg) values (?, ?, 'fuzzy', ?)",
                        $nr, $lang, $str;
            }
         }
      }
   }

   my $st = sql_exec \my($nr), "select nr from msgid where domain = ? and context = ''", $scan_app;
   while ($st->fetch) {
      sql_exec "update msgstr set flags = flags | 4 where nr = ?", $nr;
   }

   ($scan_app, $scan_lang, %scan_msg) = ();
}

=item export_dpo $domain, $path, [$userid, $groupid, $attr]

Export translation domain C<$domain> in binary hash format to directory
C<$path>, creating it if necessary.

=cut

sub export_dpo($$;$$) {
   my ($domain, $path, $uid, $gid, $attr) = @_;
   local $PApp::SQL::DBH = PApp::Config::DBH;
   mkdir $path, defined $attr ? $attr | 0111 : 0755;
   chown $uid, $gid, $path if defined $uid;
   unlink for glob "$path/*.dpo";
   for my $lang (sql_fetchall "select distinct s.lang
                               from msgid i, msgstr s
                               where i.domain = ? and i.nr = s.nr",
                              $domain) {
      my $pofile = "$path/$lang.dpo";
      my $st = sql_exec \my($id, $msg),
                        "select id, msg
                         from msgid i, msgstr s
                         where i.domain = ? and i.nr = s.nr and s.lang = ?
                               and s.flags & 1 and msg != ''
                         order by 2",
                        $domain, $lang;
      my $rows = $st->rows;
      if ($rows) {
         my $prime = int ($rows * 4 / 3) | 1;
         {
            use integer;

            outer:
            for (;; $prime += 2) {
               my $max = int sqrt $prime;
               for (my $i = 3; $i <= $max; $i += 2) {
                  next outer unless $prime % $i;
               }
               last;
            }
         }
         my $dpo = new PApp::I18n::DPO_Writer "$pofile~", $prime;
         while ($st->fetch) {
            $dpo->add(utf8_on $id,utf8_on $msg) if $id ne $msg;
         }
         undef $dpo;
         chown $uid, $gid, "$pofile~" if defined $uid;
         chmod $attr, "$pofile~" if defined $attr;
         rename "$pofile~", $pofile;
         push @files, $pofile;
      } else {
         unlink $pofile;
      }
   }
}

package PApp::I18n::PO_Reader;

use Carp;

=back

=head2 PO Reading and Writing

CLASS PApp::I18n::PO_Reader

This class can be used to read serially through a .po file. (where "po
file" is about the same thing as a standard "Portable Object" file from
the NLS standard developed by Uniforum).

=over 4

=item $po = new PApp::I18n::PO_Reader $pathname

Opens the given file for reading.

=cut

sub new {
   my ($class, $path) = @_;
   my $self;

   $self->{path} = $path;
   open $self->{fh}, "<", $path or croak "unable to open '$path' for reading: $!";

   bless $self, $class;
}

=item ($msgid, $msgstr, @comments) = $po->next;

Read the next entry. Returns nothing on end-of-file.

=cut

sub peek {
   my $self = shift;
   unless ($self->{line}) {
      do {
         chomp ($self->{line} = $self->{fh}->getline);
         Convert::Scalar::utf8_on $self->{line};
      } while defined $self->{line} && $self->{line} =~ /^\s*$/;
   }
   $self->{line};
}

sub line {
   my $self = shift;
   $self->peek;
   delete $self->{line};
}

sub perr {
   my $self = shift;
   croak "$_[0], at $self->{path}:$.";
}

sub next {
   my $self = shift;
   my ($id, $str, @c);

   while ($self->peek =~ /^\s*#(.*)$/) {
      push @c, $1;
      $self->line;
   }
   if ($self->peek =~ /^\s*msgid/) {
      while ($self->peek =~ /^\s*(?:msgid\s+)?\"(.*)\"\s*$/) {
         $id .= PApp::I18n::unquote "$1";
         $self->line;
      }
      if ($self->peek =~ /^\s*msgstr/) {
         while ($self->peek =~ /^\s*(?:msgstr\s+)?\"(.*)\"\s*$/) {
            $str .= PApp::I18n::unquote "$1";
            $self->line;
         }
      } elsif ($self->peek =~ /\S/) {
         $self->perr("expected msgstr, not ");
      } else {
         return;
      }
   } elsif ($self->peek =~ /\S/) {
      $self->perr("expected msgid");
   } else {
      return;
   }
   ($id, $str, @c);
}

package PApp::I18n::PO_Writer;

use Carp;

=back

CLASS PApp::I18n::PO_Writer

This class can be used to write a new .po file. (where "po file" is about
the same thing as a standard "Portable Object" file from the NLS standard
developed by Uniforum).

=over 4

=item $po = new PApp::I18n::PO_Writer $pathname

Opens the given file for writing.

=cut

sub new {
   my ($class, $path) = @_;
   my $self;

   $self->{path} = $path;
   open $self->{fh}, ">:utf8", $path or croak "unable to open '$path' for writing: $!";

   bless $self, $class;
}

=item $po->add ($msgid, $msgstr, @comments);

Write another entry to the po file. See PO_Reader's C<next> method.

=cut

sub splitstr($) {
   local $_ = "\"" . (PApp::I18n::quote shift) . "\"\n";
   if (s/\\n(..)/\\n"\n"$1/g) {
      $_ = "\"\"\n" . $_;
   }
   $_;
}

sub add {
   my $self = shift;
   my ($id, $str, @c) = @_;

   $self->{fh}->print(
      (map "#$_\n", @c),
      "msgid " , splitstr $id,
      "msgstr ", splitstr $str,
      "\n"
   );
}

package PApp::I18n;

1;

=back

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

# the following data tables are originally from http://iso.plan9.de/
__DATA__
abw	aw	Aruba
afg	af	Afghanistan
ago	ao	Angola
aia	ai	Anguilla
alb	al	Albania
and	ad	Andorra
ant	an	Netherlands Antilles
are	ae	Arab Emirates
arg	ar	Argentina
arm	am	Armenia
asm	as	American Samoa
atg	ag	Antigua and Barbuda
aus	au	Australia
aut	at	Austria
aze	az	Azerbaijan
bdi	bi	Burundi
bel	be	Belgium
ben	bj	Benin
bfa	bf	Burkina Faso
bgd	bd	Bangladesh
bgr	bg	Bulgaria
bhr	bh	Bahrain
bhs	bs	Bahamas
bih	ba	Bosnia and Herzegovina
blr	by	Belarus
blz	bz	Belize
bmu	bm	Bermuda
bol	bo	Bolivia
bra	br	Brazil
brb	bb	Barbados
brn	bn	Brunei
btn	bt	Bhutan
bwa	bw	Botswana
caf	cf	Central African Republic
can	ca	Canada
che	ch	Switzerland
chl	cl	Chile
chn	cn	China
civ	ci	Côte d'Ivoire
cmr	cm	Cameroon
cod	cd	Congo
cog	cg	Congo
cok	ck	Cook Islands
col	co	Colombia
com	km	Comoros
cpv	cv	Cape Verde
cri	cr	Costa Rica
cub	cu	Cuba
cym	ky	Cayman Islands
cyp	cy	Cyprus
cze	cz	Czech Republic
deu	de	Germany
dji	dj	Djibouti
dma	dm	Dominica
dnk	dk	Denmark
dom	do	Dominican Republic
dza	dz	Algeria
ecu	ec	Ecuador
egy	eg	Egypt
eri	er	Eritrea
esh	eh	Western Sahara
esp	es	Spain
est	ee	Estonia
eth	et	Ethiopia
fin	fi	Finland
fji	fj	Fiji
flk	fk	Malvinas
fra	fr	France
fro	fo	Faeroe Islands
fsm	fm	Micronesia
gab	ga	Gabon
gbr	gb	United Kingdom
geo	ge	Georgia
gha	gh	Ghana
gib	gi	Gibraltar
gin	gn	Guinea
glp	gp	Guadeloupe
gmb	gm	Gambia
gnb	gw	Guinea-Bissau
gnq	gq	Equatorial Guinea
grc	gr	Greece
grd	gd	Grenada
grl	gl	Greenland
gtm	gt	Guatemala
guf	gf	French Guiana
gum	gu	Guam
guy	gy	Guyana
hkg	hk	Hong Kong
hnd	hn	Honduras
hrv	hr	Croatia
hti	ht	Haiti
hun	hu	Hungary
idn	id	Indonesia
ind	in	India
irl	ie	Ireland
irn	ir	Iran
irq	iq	Iraq
isl	is	Iceland
isr	il	Israel
ita	it	Italy
jam	jm	Jamaica
jor	jo	Jordan
jpn	jp	Japan
kaz	kz	Kazakhstan
ken	ke	Kenya
kgz	kg	Kyrgyzstan
khm	kh	Cambodia
kir	ki	Kiribati
kna	kn	Saint Kitts and Nevis
kor	kr	Republic of Korea
kwt	kw	Kuwait
lao	la	Lao
lbn	lb	Lebanon
lbr	lr	Liberia
lby	ly	Jamahiriya
lca	lc	Saint Lucia
lie	li	Liechtenstein
lka	lk	Sri Lanka
lso	ls	Lesotho
ltu	lt	Lithuania
lux	lu	Luxembourg
lva	lv	Latvia
mac	mo	Macao
mar	ma	Morocco
mco	mc	Monaco
mda	md	Moldova
mdg	mg	Madagascar
mdv	mv	Maldives
mex	mx	Mexico
mhl	mh	Marshall Islands
mkd	mk	Macedonia
mli	ml	Mali
mlt	mt	Malta
mmr	mm	Myanmar
mng	mn	Mongolia
mnp	mp	Mariana Islands
moz	mz	Mozambique
mrt	mr	Mauritania
msr	ms	Montserrat
mtq	mq	Martinique
mus	mu	Mauritius
mwi	mw	Malawi
mys	my	Malaysia
nam	na	Namibia
ncl	nc	New Caledonia
ner	ne	Niger
nfk	nf	Norfolk Island
nga	ng	Nigeria
nic	ni	Nicaragua
niu	nu	Niue
nld	nl	Netherlands
nor	no	Norway
npl	np	Nepal
nru	nr	Nauru
nzl	nz	New Zealand
omn	om	Oman
pak	pk	Pakistan
pan	pa	Panama
pcn	pn	Pitcairn
per	pe	Peru
phl	ph	Philippines
plw	pw	Palau
png	pg	Papua New Guinea
pol	pl	Poland
pri	pr	Puerto Rico
prk	kp	Korea
prt	pt	Portugal
pry	py	Paraguay
pse	ps	Palestine
pyf	pf	French Polynesia
qat	qa	Qatar
reu	re	Réunion
rom	ro	Romania
rus	ru	Russia
rwa	rw	Rwanda
sau	sa	Saudi Arabia
sdn	sd	Sudan
sen	sn	Senegal
sgp	sg	Singapore
shn	sh	Saint Helena
sjm	sj	Svalbard and Jan Mayen Islands
slb	sb	Solomon Islands
sle	sl	Sierra Leone
slv	sv	El Salvador
smr	sm	San Marino
som	so	Somalia
spm	pm	Saint Pierre and Miquelon
stp	st	São Tome and Principe
sur	sr	Suriname
svk	sk	Slovakia
svn	si	Slovenia
swe	se	Sweden
swz	sz	Swaziland
syc	sc	Seychelles
syr	sy	Syria
tca	tc	Turks and Caicos Islands
tcd	td	Chad
tgo	tg	Togo
tha	th	Thailand
tjk	tj	Tajikistan
tkl	tk	Tokelau
tkm	tm	Turkmenistan
tmp	tp	East Timor
ton	to	Tonga
tto	tt	Trinidad and Tobago
tun	tn	Tunisia
tur	tr	Turkey
tuv	tv	Tuvalu
twn	tw	Taiwan
tza	tz	Tanzania
uga	ug	Uganda
ukr	ua	Ukraine
ury	uy	Uruguay
usa	us	United States
uzb	uz	Uzbekistan
vat	va	Holy See
vct	vc	Saint Vincent and the Grenadines
ven	ve	Venezuela
vgb	vg	British Virgin Islands
vir	vi	Virgin Islands
vnm	vn	Viet Nam
vut	vu	Vanuatu
wlf	wf	Wallis and Futuna Islands
wsm	ws	Samoa
yem	ye	Yemen
scg	cs	Serbia and Montenegro
zaf	za	South Africa
zmb	zm	Zambia
zwe	zw	Zimbabwe
__SPLIT__
aar	aa	Afar
abk	ab	Abkhazian
ace		Achinese
ach		Acoli
ada		Adangme
afa		Afro-Asiatic (Other)
afh		Afrihili
afr	af	Afrikaans
aka		Akan
akk		Akkadian
ale		Aleut
alg		Algonquian languages
amh	am	Amharic
ang		English, Old (ca. 450-1100)
apa		Apache languages
ara	ar	Arabic
arc		Aramaic
arn		Araucanian
arp		Arapaho
art		Artificial (Other)
arw		Arawak
asm	as	Assamese
ath		Athapascan languages
aus		Australian languages
ava		Avaric
ave	ae	Avestan
awa		Awadhi
aym	ay	Aymara
aze	az	Azerbaijani
bad		Banda
bai		Bamileke languages
bak	ba	Bashkir
bal		Baluchi
bam		Bambara
ban		Balinese
bas		Basa
bat		Baltic (Other)
bej		Beja
bel	be	Belarusian
bem		Bemba
ben	bn	Bengali
ber		Berber (Other)
bho		Bhojpuri
bih	bh	Bihari
bik		Bikol
bin		Bini
bis	bi	Bislama
bla		Siksika
bnt		Bantu (Other)
bod	bo	Tibetan
bos	bs	Bosnian
bra		Braj
bre	br	Breton
btk		Batak (Indonesia)
bua		Buriat
bug		Buginese
bul	bg	Bulgarian
cad		Caddo
cai		Central American Indian (Other)
car		Carib
cat	ca	Catalan
cau		Caucasian (Other)
ceb		Cebuano
cel		Celtic (Other)
ces	cs	Czech
cha	ch	Chamorro
chb		Chibcha
che	ce	Chechen
chg		Chagatai
chk		Chuukese
chm		Mari
chn		Chinook jargon
cho		Choctaw
chp		Chipewyan
chr		Cherokee
chu	cu	Church Slavic
chv	cv	Chuvash
chy		Cheyenne
cmc		Chamic languages
cop		Coptic
cor	kw	Cornish
cos	co	Corsican
cpe		Creoles and pidgins, English based (Other)
cpf		Creoles and pidgins, French-based (Other)
cpp		Creoles and pidgins, Portuguese-based (Other)
cre		Cree
crp		Creoles and pidgins (Other)
cus		Cushitic (Other)
cym	cy	Welsh
dak		Dakota
dan	da	Danish
day		Dayak
del		Delaware
den		Slave (Athapascan)
deu	de	German
dgr		Dogrib
din		Dinka
div		Divehi
doi		Dogri
dra		Dravidian (Other)
dua		Duala
dum		Dutch, Middle (ca. 1050-1350)
dyu		Dyula
dzo	dz	Dzongkha
efi		Efik
egy		Egyptian (Ancient)
eka		Ekajuk
ell	el	Greek, Modern (1453-)
elx		Elamite
eng	en	English
enm		English, Middle (1100-1500)
epo	eo	Esperanto
est	et	Estonian
eus	eu	Basque
ewe		Ewe
ewo		Ewondo
fan		Fang
fao	fo	Faroese
fas	fa	Persian
fat		Fanti
fij	fj	Fijian
fin	fi	Finnish
fiu		Finno-Ugrian (Other)
fon		Fon
fra	fr	French
frm		French, Middle (ca. 1400-1600)
fro		French, Old (842-ca. 1400)
fry	fy	Frisian
ful		Fulah
fur		Friulian
gaa		Ga
gay		Gayo
gba		Gbaya
gem		Germanic (Other)
gez		Geez
gil		Gilbertese
gla	gd	Gaelic (Scots)
gle	ga	Irish
glg	gl	Gallegan
glv	gv	Manx
gmh		German, Middle High (ca. 1050-1500)
goh		German, Old High (ca. 750-1050)
gon		Gondi
gor		Gorontalo
got		Gothic
grb		Grebo
grc		Greek, Ancient (to 1453)
grn	gn	Guarani
guj	gu	Gujarati
gwi		Gwich´in
hai		Haida
hau	ha	Hausa
haw		Hawaiian
heb	he	Hebrew
her	hz	Herero
hil		Hiligaynon
him		Himachali
hin	hi	Hindi
hit		Hittite
hmn		Hmong
hmo	ho	Hiri Motu
hrv	hr	Croatian
hun	hu	Hungarian
hup		Hupa
hye	hy	Armenian
iba		Iban
ibo		Igbo
ijo		Ijo
iku	iu	Inuktitut
ile	ie	Interlingue
ilo		Iloko
ina	ia	Interlingua (International Auxiliary Language Association)
inc		Indic (Other)
ind	id	Indonesian
ine		Indo-European (Other)
ipk	ik	Inupiaq
ira		Iranian (Other)
iro		Iroquoian languages
isl	is	Icelandic
ita	it	Italian
jaw	jw	Javanese
jpn	ja	Japanese
jpr		Judeo-Persian
kaa		Kara-Kalpak
kab		Kabyle
kac		Kachin
kal	kl	Kalaallisut
kam		Kamba
kan	kn	Kannada
kar		Karen
kas	ks	Kashmiri
kat	ka	Georgian
kau		Kanuri
kaw		Kawi
kaz	kk	Kazakh
kha		Khasi
khi		Khoisan (Other)
khm	km	Khmer
kho		Khotanese
kik	ki	Kikuyu
kin	rw	Kinyarwanda
kir	ky	Kirghiz
kmb		Kimbundu
kok		Konkani
kom	kv	Komi
kon		Kongo
kor	ko	Korean
kos		Kosraean
kpe		Kpelle
kro		Kru
kru		Kurukh
kum		Kumyk
kur	ku	Kurdish
kut		Kutenai
lad		Ladino
lah		Lahnda
lam		Lamba
lao	lo	Lao
lat	la	Latin
lav	lv	Latvian
lez		Lezghian
lin	ln	Lingala
lit	lt	Lithuanian
lol		Mongo
loz		Lozi
ltz	lb	Letzeburgesch
lua		Luba-Lulua
lub		Luba-Katanga
lug		Ganda
lui		Luiseno
lun		Lunda
luo		Luo (Kenya and Tanzania)
lus		lushai
mad		Madurese
mag		Magahi
mah	mh	Marshall
mai		Maithili
mak		Makasar
mal	ml	Malayalam
man		Mandingo
map		Austronesian (Other)
mar	mr	Marathi
mas		Masai
mdr		Mandar
men		Mende
mga		Irish, Middle (900-1200)
mic		Micmac
min		Minangkabau
mis		Miscellaneous languages
mkd	mk	Macedonian
mkh		Mon-Khmer (Other)
mlg	mg	Malagasy
mlt	mt	Maltese
mnc		Manchu
mni		Manipuri
mno		Manobo languages
moh		Mohawk
mol	mo	Moldavian
mon	mn	Mongolian
mos		Mossi
mri	mi	Maori
msa	ms	Malay
mul		Multiple languages
mun		Munda languages
mus		Creek
mwr		Marwari
mya	my	Burmese
myn		Mayan languages
nah		Nahuatl
nai		North American Indian
nau	na	Nauru
nav	nv	Navajo
nbl	nr	Ndebele, South
nde	nd	Ndebele, North
ndo	ng	Ndonga
nds		Low German; Low Saxon; German, Low; Saxon, Low
nep	ne	Nepali
new		Newari
nia		Nias
nic		Niger-Kordofanian (Other)
niu		Niuean
nld	nl	Dutch
nno	nn	Norwegian Nynorsk
nob	nb	Norwegian Bokmål
non		Norse, Old
nor	no	Norwegian
nso		Sotho, Northern
nub		Nubian languages
nya	ny	Chichewa; Nyanja
nym		Nyamwezi
nyn		Nyankole
nyo		Nyoro
nzi		Nzima
oci	oc	Occitan (post 1500); Provençal
oji		Ojibwa
ori	or	Oriya
orm	om	Oromo
osa		Osage
oss	os	Ossetian; Ossetic
ota		Turkish, Ottoman (1500-1928)
oto		Otomian languages
paa		Papuan (Other)
pag		Pangasinan
pal		Pahlavi
pam		Pampanga
pan	pa	Panjabi
pap		Papiamento
pau		Palauan
peo		Persian, Old (ca. 600-400 b.c.)
phi		Philippine (Other)
pli	pi	Pali
pol	pl	Polish
pon		Pohnpeian
por	pt	Portuguese
pra		Prakrit languages
pro		Provençal, Old (to 1500)
pus	ps	Pushto
que	qu	Quechua
raj		Rajasthani
rap		Rapanui
rar		Rarotongan
roa		Romance (Other)
rom		Romany
ron	ro	Romanian
run	rn	Rundi
rus	ru	Russian
sad		Sandawe
sag	sg	Sango
sah		Yakut
sai		South American Indian (Other)
sal		Salishan languages
sam		Samaritan Aramaic
san	sa	Sanskrit
sas		Sasak
sat		Santali
sco		Scots
sel		Selkup
sem		Semitic (Other)
sga		Irish, Old (to 900)
sgn		Sign Languages
shn		Shan
sid		Sidamo
sin	si	Sinhalese
sio		Siouan languages
sit		Sino-Tibetan (Other)
sla		Slavic (Other)
slk	sk	Slovak
slv	sl	Slovenian
sme	se	Northern Sami
smi		Sami languages (Other)
smo	sm	Samoan
sna	sn	Shona
snd	sd	Sindhi
snk		Soninke
sog		Sogdian
som	so	Somali
son		Songhai
sot	st	Sotho, Southern
spa	es	Spanish
sqi	sq	Albanian
srd	sc	Sardinian
srp	sr	Serbian
srr		Serer
ssa		Nilo-Saharan (Other)
ssw	ss	Swati
suk		Sukuma
sun	su	Sundanese
sus		Susu
sux		Sumerian
swa	sw	Swahili
swe	sv	Swedish
syr		Syriac
tah	ty	Tahitian
tai		Tai (Other)
tam	ta	Tamil
tat	tt	Tatar
tel	te	Telugu
tem		Timne
ter		Tereno
tet		Tetum
tgk	tg	Tajik
tgl	tl	Tagalog
tha	th	Thai
tig		Tigre
tir	ti	Tigrinya
tiv		Tiv
tkl		Tokelau
tli		Tlingit
tmh		Tamashek
tog		Tonga (Nyasa)
ton	to	Tonga (Tonga Islands)
tpi		Tok Pisin
tsi		Tsimshian
tsn	tn	Tswana
tso	ts	Tsonga
tuk	tk	Turkmen
tum		Tumbuka
tur	tr	Turkish
tut		Altaic (Other)
tvl		Tuvalu
twi	tw	Twi
tyv		Tuvinian
uga		Ugaritic
uig	ug	Uighur
ukr	uk	Ukrainian
umb		Umbundu
und		Undetermined
urd	ur	Urdu
uzb	uz	Uzbek
vai		Vai
ven		Venda
vie	vi	Vietnamese
vol	vo	Volapük
vot		Votic
wak		Wakashan languages
wal		Walamo
war		Waray
was		Washo
wen		Sorbian languages
wol	wo	Wolof
xho	xh	Xhosa
yao		Yao
yap		Yapese
yid	yi	Yiddish
yor	yo	Yoruba
ypk		Yupik languages
zap		Zapotec
zen		Zenaga
zha	za	Zhuang
zho	zh	Chinese
znd		Zande
zul	zu	Zulu
zun		Zuni
__SPLIT__
afr	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
ara	iso-8859-6,iso-ir-127,cp1256
bel	iso-8859-5,cp1251,iso-ir-111,iso-ir-144,cp866
bre	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100,iso-8859-14
bul	iso-8859-5,cp1251,iso-ir-111,iso-ir-144,cp866
cat	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
ces	iso-8859-2,cp1250,iso-ir-101
cor	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100,iso-8859-14
cym	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100,iso-8859-14
dan	cp1252,iso-8859-9,iso-8859-1,iso-8859-15,cp819,iso-ir-100
dan_dnk	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100,iso-646-dk
deu	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
ell	iso-8859-7,cp1253,iso-ir-126
eng	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
eng_usa	us-ascii,iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100,cp367
epo	iso-8859-3,iso-ir-109
est	iso-8859-4,iso-8859-10,cp1257,iso-ir-110,iso-8859-15
eus	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
fao	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
fas	iso-8859-6,iso-ir-127
fin	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
fra	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
gla	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100,iso-8859-14
gle	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100,iso-8859-14
glg	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
glv	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100,iso-8859-14
heb	iso-8859-8,cp1255
hrv	iso-8859-2,cp1250,iso-ir-101
hun	iso-8859-2,cp1250,iso-ir-101,iso-ir-87
hye	armscii-8
iku	nunacom-8
ind	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
ipk	iso-8859-10
isl	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
ita	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
jpn	euc-jp,sjis,iso-2022-jp,jis7
kal	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
kor	euc-kr,uhc,johab,iso-2022-kr,iso-646-kr,ksc5636
lao	mulelao-1,ibm-cp1133
lav	iso-8859-4,iso-8859-10,cp1257,iso-ir-110,iso-8859-13
lit	iso-8859-4,iso-8859-10,cp1257,iso-ir-110,iso-8859-13
mkd	iso-8859-5,cp1251,iso-ir-111,iso-ir-144,cp866
mkd_mkd	iso-ir-147,iso-8859-5,cp1251,iso-ir-111,iso-ir-144,cp866
mlt	iso-8859-3,iso-ir-109
nld	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
nno	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
nob	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
nor	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
oci	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
pol	iso-8859-2,cp1250,iso-ir-101
por	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
ron	iso-8859-2,cp1250,iso-ir-101
rus	koi8-r,iso-8859-5,cp1251,iso-ir-111,iso-ir-144,cp866,koi8-u
rus_ukr	koi8-u,iso-8859-5,cp1251,iso-ir-111,iso-ir-144,cp866
slk	iso-8859-2,cp1250,iso-ir-101
slv	iso-8859-2,cp1250,iso-ir-101
sme	iso-8859-10
spa	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
sqi	iso-8859-2,cp1250,iso-ir-101,iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100,iso-8859-9
srp	iso-8859-2,cp1250,iso-ir-101,iso-8859-5,cp1251,iso-ir-111,iso-ir-144,cp866,iso-ir-146
swa	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
swe	iso-8859-1,iso-8859-15,cp1252,cp819,iso-ir-100
tha	cp874,tis-620,iso-8859-11
tur	iso-8859-9,iso-8859-3,iso-ir-109,cp1254
ukr	iso-8859-5,cp1251,iso-ir-111,iso-ir-144,cp866,koi8-u
vie	cp1258,viscii,tcvn5712,vps
zho	euc-tw,big5
zho_chn	euc-cn,gbk,iso-2022-cn,iso-ir-58
