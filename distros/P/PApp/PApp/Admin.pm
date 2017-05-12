##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::Admin - perform various administrative tasks

=head1 SYNOPSIS

 use PApp::Admin;

=head1 DESCRIPTION

With this module you can perform various administrative tasks. Normally you
would use the C<papp-admin> commandline-tool.

=over 4

=cut

package PApp::Admin;

use PApp::SQL;
use Convert::Scalar ':utf8';

use base 'Exporter';

$VERSION = 2.1;
@EXPORT = qw();

our $verbose = 1;

=item $verbose

This global variable can be set to a value higher then one (the default)
to get more info printed to the screen. If set to zero, nothing at all is
printed.

=cut

=item export_po $dirflag, $domain, $destpath

Export translation domain C<$domain> into a po-like file-format. If
C<$dirflag> is false, a single file C<$destpath> is created and
written. If C<$dirflag> is true, a directory with one po-like-file
per domain is created (everything else in that directory might get
clobbered!).

=cut

sub export_po {
   require PApp::I18n;
   my ($dir, $domain, $dst) = @_;
   print STDERR "exporting $domain to $dst\n" if $verbose;

   my @hdr = ("MIME-Version: 1.0\n".
              "Content-Type: text/plain: charset=utf-8\n".
              "Content-Transfer-Encoding: 8bit\n",
              " PApp translation table 1.0");
   my $po;
   my %po;
   my %cnt;

   if ($dir) {
      if (!-d $dst) {
         mkdir $dst, 0755 or die "$dst: $!";
         print STDERR "created directory $dst" if $verbose > 1;
      }
      unlink $_ for glob "$dst/*.po";
   } else {
      $po = new PApp::I18n::PO_Writer $dst
         or die "$dst: $!";
      $po->add(
          "",
          @hdr,
          "",
          "\$domain=$domain",
      );
   }

   my $st = sql_exec \my($id, $lang1, $context, $lang2, $flags, $msg),
                     "select i.id, i.lang, i.context, s.lang, s.flags*1, s.msg
                      from msgid i left join msgstr s on (i.nr = s.nr) where i.domain = ?
                      order by 4,1,2,6",
                     $domain;

   while ($st->fetch) {
      utf8_on $id;
      utf8_on $context;
      utf8_on $msg;

      unless ($po{$lang2}) {
         if ($po) {
            $po{$lang2} = $po;
            $po{$lang2}->add(
                "",
                "",
                "\$lang=$lang2",
            );
         } else {
            $po{$lang2} ||= $po || new PApp::I18n::PO_Writer "$dst/$lang2.po"
               or die "$dst/$lang2.po: $!";
            $po{$lang2}->add(
                "",
                @hdr,
                "",
                "\$domain=$domain",
                "\$lang=$lang2",
            );
         }
      }

      if (($flags != 2 or $msg ne "") and $id ne "") {
         $cnt{$lang2}++;
         $po{$lang2}->add(
               $id,
               $msg,
               (map " $_", split /\n/, $context),
               "\$lang=$lang1",
               $flags != 1 ? ("\$flags=$flags") : (),
         );
      }
   }

   if ($verbose) {
      while (my ($k, $v) = each %cnt) {
         if ($po) {
            print STDERR "$k... $v entries\n";
         } else {
            print STDERR "$dst/$k.po... $v entries\n";
         }
      }
   }
}

=item import_po $dirflag, $srcpath[, $overwrite]

Import all domains from file or directory C<$srcpath>, depending on the
setting of C<$dirflag>. Valid translations from the file do not overwrite
valid translations already in the database unless C<$overwrite> is true,
in which case valid translations in the file(s) overwrite valid ones in
the database.

=cut

sub import_po {
   require PApp::I18n;
   my ($dir, $dst, $overwrite) = @_;

   print STDERR "importing domains from $dst\n" if $verbose;

   !$dir || -d $dst or die "$dst: Not a directory\n";

   outer:
   for ($dir ? glob "$dst/*.po" : $dst) {
      print STDERR "$_... " if $verbose > 1;
      my $po = new PApp::I18n::PO_Reader $_
         or die "$_: $!\n";
      my ($cnt, $mod) = (0, 0);
      my $lang;

      while (my ($id, $msg, @comments) = $po->next) {
         my $comment = "";
         my %val;
         for (@comments) {
            if (/^\$(\w+)=(.*)$/) {
               $val{$1} = $2;
            } else {
               s/^\s//;
               $comment .= "$_\n";
            }
         }
         if ($id eq "") {
            if ($str != "" && $comment !~ /PApp translation table/) {
               print STDERR "not a papp translation table, skipped\n";
               next outer;
            }
            $domain = $val{domain} if exists $val{domain};
            $lang   = $val{lang}   if exists $val{lang};
         } elsif (!$lang) {
            print STDERR "format error, no header found, skipped\n";
            next outer;
         } elsif (!exists $val{lang}) {
            print STDERR "format error, skipped\n";
            next outer;
         } else {
            sql_ufetch \my($nr),
                      "select nr from msgid where id = ? and lang = ? and domain = ?",
                      $id, $val{lang}, $domain;
            unless ($nr) {
               $nr = sql_insertid sql_uexec "insert into msgid values (NULL, ?, ?, ?, ?)",
                        $id, $domain, $val{lang}, $comment;
            } else {
               sql_uexec "update msgid set context = ? where nr = ?", $comment, $nr;
            }

            $val{flags} = 1 unless exists $val{flags};

            unless (sql_uexists "msgstr where nr = ? and lang = ?", $nr, $lang) {
               sql_uexec "insert into msgstr values (?, ?, ?, ?)", $nr, $lang, $val{flags}, $msg;
               $mod++;
            } elsif ($overwrite or $val{flags} & 1) {
               my $st = sql_uexec "update msgstr set flags = ?, msg = ? where nr = ? and lang = ?",
                           $val{flags}, $msg, $nr, $lang;
               $mod += $st->rows;
            } else {
               my $st = sql_uexec "update msgstr set flags = ?, msg = ? where nr = ? and lang = ? and flags & 1 = 0",
                           $val{flags}, $msg, $nr, $lang;
               $mod += $st->rows;
            }

            $cnt++;
         }
      }

      print STDERR "$cnt entries, $mod changed\n" if $verbose > 1;
   }
}

sub reorganize {
   require PApp::I18n;
   PApp::I18n::reorganize_i18ndb();
}

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

