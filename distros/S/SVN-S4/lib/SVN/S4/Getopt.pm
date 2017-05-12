# See copyright, etc in below POD section.
######################################################################

package SVN::S4::Getopt;

use strict;
use vars qw($AUTOLOAD $Debug);
use Carp;
use IO::File;
use Cwd;
use Data::Dumper;

######################################################################
#### Configuration Section

our $VERSION = '1.064';

our %_Aliases =
    (
     'ann'	=> 'blame',
     'annotate'	=> 'blame',
     'ci'	=> 'commit',
     'cl'	=> 'changelist',
     'co'	=> 'checkout',
     'cp'	=> 'copy',
     'del'	=> 'delete',
     'di'	=> 'diff',
     'h'	=> 'help',
     'ls'	=> 'list',
     'mv'	=> 'move',
     'pd'	=> 'propdel',
     'pdel'	=> 'propdel',
     'pe'	=> 'propedit',
     'pedit'	=> 'propedit',
     'pg'	=> 'propget',
     'pget'	=> 'propget',
     'pl'	=> 'proplist',
     'plist'	=> 'proplist',
     'praise'	=> 'blame',
     'ps'	=> 'propset',
     'pset'	=> 'propset',
     'remove'	=> 'delete',
     'ren'	=> 'move',
     'rename'	=> 'move',
     'rm'	=> 'delete',
     'snap'	=> 'snapshot',
     'st'	=> 'status',
     'stat'	=> 'status',
     'sw'	=> 'switch',
     'up'	=> 'update',
     # S4 additions
     'qci'	=> 'quick-commit',
     );

# List of commands and arguments.
# Forms:
#    [-switch]
#    [-switch argument]
#    nonoptional		# One parameter
#    nonoptional...		# Many parameters
#    [optional]			# One parameter
#    [optional...]		# Many parameters
# The arguments "PATH*" are specially detected by s4 for filename parsing.

our %_Args =
 (
  'add'		=> {
      s4_changed => 1,
      args => (''
	       .' [--no-fixprop]'		# S4 addition
	       .' [--fixprop]'			# S4 addition
	       #
	       .' [--auto-props]'
	       .' [--depth ARG]'		# 1.6
	       .' [--force]'
	       .' [--no-auto-props]'
	       .' [--no-ignore]'		# 1.8
	       .' [--parents]'			# 1.6
	       .' [--targets FILENAME]'
	       .' [-N|--non-recursive]'
	       .' [-q|--quiet]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PATH...')},
  'blame'	=> {
      args => (''
	       .' [--force]'			# 1.4
	       .' [--incremental]'		# 1.6
	       .' [--xml]'			# 1.6
	       .' [-g|--use-merge-history]'	# 1.6
	       .' [-r|--revision REV]'
	       .' [-v|--verbose]'
	       .' [-x|--extensions ARGS]'	# 1.4
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PATH@PATHREV...')},	# PATH[@REV]
  'cat'		=> {
      args => (''
	       .' [-r|--revision REV]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PATH@PATHREV...')},	# PATH[@REV]
  'changelist'	=> {
      args => (''
	       .' [--changelist ARG'		# 1.6
	       .' [--depth ARG]'		# 1.6
	       .' [--remove]'			# 1.6
	       .' [--targets ARG]'		# 1.6
	       .' [-R|--recursive]'		# 1.6
	       .' [-q|--quiet]'			# 1.6
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PATH@PATHREV...')},	# PATH[@REV]
  'checkout'	=> {
      s4_changed => 1,
      args => (''
	       .' [--depth ARG]'
	       .' [--force]'
	       .' [--ignore-externals]'
	       .' [-N|--non-recursive]'
	       .' [-q|--quiet]'
	       .' [-r|--revision REV]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' URL@URLREV... [PATH]')},  # URL[@REV]  path will parse to be last element in {url}
  'cleanup'	=> {
      args => (''
	       .' [--diff3-cmd CMD]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' [PATH...]')},
  'commit'	=> {
      s4_changed => 1,
      args => (''
	       .' [--unsafe]'			# S4 addition
	       #
	       .' [--changelist ARG]'		# 1.6
	       .' [--depth ARG]'
	       .' [--editor-cmd ARG]'		# 1.6
	       .' [--encoding ENC]'
	       .' [--force-log]'
	       .' [--include-externals]'	# 1.8
	       .' [--keep-changelists]'		# 1.8
	       .' [--keep-changelist ARG]'	# 1.6
	       .' [--no-unlock]'
	       .' [--non-interactive]'
	       .' [--targets FILENAME]'
	       .' [--with-revprop ARG]'		# 1.6
	       .' [-F|--file FILE]'
	       .' [-N|--non-recursive]'
	       .' [-m|--message TEXT]'
	       .' [-q|--quiet]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' [PATH...]')},
  'copy'	=> {
      args => (''
	       .' [--editor-cmd EDITOR]'
	       .' [--encoding ENC]'
	       .' [--force-log]'
	       .' [--ignore-externals]'		# 1.6
	       .' [--parents]'
	       .' [--with-revprop ARG]'		# 1.6
	       .' [-F|--file FILE]'
	       .' [-m|--message TEXT]'
	       .' [-q|--quiet]'
	       .' [-r|--revision REV]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' SRC DST')},
  'delete'	=> {
      args => (''
	       .' [--editor-cmd EDITOR]'
	       .' [--encoding ENC]'
	       .' [--force-log]'
	       .' [--force]'
	       .' [--keep-local]'		# 1.6
	       .' [--targets FILENAME]'
	       .' [--with-revprop ARG]'		# 1.6
	       .' [-F|--file FILE]'
	       .' [-m|--message TEXT]'
	       .' [-q|--quiet]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PATHORURL...')},
  'diff'	=> {
      args => (''# 'diff [-r N[:M]]       [PATH[@REV]...]'
	       # 'diff [-r N[:M]] --old OLD-TGT[@OLDREV] [--new NEW-TGT[@NEWREV]] [PATH...]'
	       # 'diff                  OLD-URL[@OLDREV]        NEW-URL[@NEWREV]'
	       .' [--changelist ARG]'
	       .' [--depth ARG]'		# 1.6
	       .' [--diff-b|-b]'	# 1.4
	       .' [--diff-cmd CMD]'
	       .' [--diff-u|-u]'	# 1.4
	       .' [--diff-w|-w]'	# 1.4
	       .' [--force]'		# 1.6
	       .' [--git]'		# 1.7
	       .' [--ignore-eol-style]'	# 1.4
	       .' [--ignore-properties]'	# 1.8
	       .' [--internal-diff]'	# 1.8
	       .' [--new NEWPATH@NEWPATHREV]'	#PATH[@REV]
	       .' [--no-diff-added]'	# 1.8
	       .' [--no-diff-deleted]'
	       .' [--notice-ancestry]'
	       .' [--old OLDPATH@OLDPATHREV]'	#PATH[@REV]
	       .' [--patch-compatible]'	# 1.8
	       .' [--properties-only]'	# 1.8
	       .' [--show-copies-as-adds]'	# 1.7
	       .' [--summarize]'	# 1.4
	       .' [--xml]'		# 1.6
	       .' [-N|--non-recursive]'
	       .' [-c|--change REV]'	# 1.4
	       .' [-r|--revision REVS]'	#OLDREV[:NEWREV]
	       .' [-x|--extensions ARGS]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' [PATHORURL...]')},
  'export'	=> {
      args => (''
	       .' [--depth ARG]'		# 1.6
	       .' [--force]'
	       .' [--ignore-externals]'		# 1.4
	       .' [--ignore-keywords]'		# 1.8
	       .' [--native-eol ARG]'
	       .' [-N|--non-recursive]'
	       .' [-q|--quiet]'
	       .' [-r|--revision REV]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PATHORURL [PATH@PATHREV]')},  # [@PEGREV]
  'help'	=> {
      args => (''
	       .' [--version]'
	       .' [-q|--quiet]'
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' [SUBCOMMAND...]')},
  'import'	=> {
      args => (''
	       .' [--auto-props]'
	       .' [--depth ARG]'		# 1.6
	       .' [--editor-cmd EDITOR]'
	       .' [--encoding ENC]'
	       .' [--force]'
	       .' [--force-log]'
	       .' [--ignore-externals]'
	       .' [--no-auto-props]'
	       .' [--no-ignore]'		# 1.6
	       .' [--with-revprop ARG]'		# 1.6
	       .' [-F|--file FILE]'
	       .' [-N|--non-recursive]'
	       .' [-m|--message TEXT]'
	       .' [-q|--quiet]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' [PATH] URL')},
  'info'	=> {
      args => (''
	       .' [--changelist ARG]'
	       .' [--depth ARG]'		# 1.6
	       .' [--incremental]'
	       .' [--targets FILENAME]'
	       .' [--xml]'
	       .' [-R|--recursive]'
	       .' [-r|--revision]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' [PATH...]')},
  'list'	=> {
      args => (''
	       .' [--depth ARG]'		# 1.6
	       .' [--include-externals]'	# 1.8
	       .' [--incremental]'
	       .' [--xml]'
	       .' [-R|--recursive]'
	       .' [-r|--revision REV]'
	       .' [-v|--verbose]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' [PATH@PATHREV...]')},		# PATH[@REV]...
  'lock'	=> {
      args => (''
	       .' [--encoding ENC]'
	       .' [--force]'			# 1.8
	       .' [--force-log]'
	       .' [--targets FILENAME]'
	       .' [-F|--file FILE]'
	       .' [-m|--message TEXT]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' [--force]'
	       .' PATH...')},
  'log'		=> {
      args => (''
	       .' [--depth ARG]'		# 1.8
	       .' [--diff-cmd ARG]'		# 1.8
	       .' [--diff]'			# 1.8
	       .' [--incremental]'
	       .' [--internal-diff]'		# 1.8
	       .' [--limit NUM]'
	       .' [--search ARG]'		# 1.8
	       .' [--search-and ARG]'		# 1.8
	       .' [--stop-on-copy]'
	       .' [--targets FILENAME]'
	       .' [--with-all-revprops]'	# 1.6
	       .' [--with-no-revprops]'		# 1.6
	       .' [--with-revprop ARG]'		# 1.6
	       .' [--xml]'
	       .' [-c|--change ARG]'		# 1.6
	       .' [-g|--use-merge-history]'
	       .' [-l|--limit ARG]'		# 1.6
	       .' [-q|--quiet]'
	       .' [-r|--revision REV]'
	       .' [-v|--verbose]'
	       .' [-x|--extensions ARG]'	# 1.8
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PATHORURL [PATH...]')},
  'merge'	=> {
      s4_changed => 1,
      args => (''#'merge        PATHORURL1[@N]  PATHORURL2[@M]  [WCPATH]'
	       #'merge -r N:M SOURCE[@REV]                    [WCPATH]'
	       .' [--accept ARG]'		# 1.6
	       .' [--allow-mixed-revisions]'	# 1.8
	       .' [--depth ARG]'		# 1.6
	       .' [--diff3-cmd CMD]'
	       .' [--dry-run]'
	       .' [--force]'
	       .' [--ignore-ancestry]'
	       .' [--record-only]'		# 1.6
	       .' [--reintegrate]'		# 1.6
	       .' [-N|--non-recursive]'
	       .' [-c|--change REV]'		# 1.4
	       .' [-q|--quiet]'
	       .' [-r|--revision REV]'
	       .' [-v|--verbose]'		# 1.8
	       .' [-x|--extensions ARGS]'	# 1.4
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PATHORURL@PATHORURLREV...')},
  'mergeinfo'	=> {
      args => (''#mergeinfo SOURCE[@REV] [TARGET[@REV]]
	       .' [--depth ARG]'		# 1.8
	       .' [--show-revs ARG]'		# 1.6
	       .' [-r|--revision ARG]'		# 1.6
	       .' [-R|--recursive]'		# 1.8
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PATHORURL@PATHORURLREV...')},
  'mkdir'	=> {
      args => (''
	       .' [--editor-cmd EDITOR]'
	       .' [--encoding ENC]'
	       .' [--force-log]'
	       .' [--parents]'			# 1.6
	       .' [--with-revprop ARG]'		# 1.6
	       .' [-F|--file FILE]'
	       .' [-m|--message TEXT]'
	       .' [-q|--quiet]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PATHORURL...')},
  'move'	=> {
      args => (''
	       .' [--allow-mixed-revisions]'	# 1.8
	       .' [--editor-cmd EDITOR]'
	       .' [--encoding ENC]'
	       .' [--force-log]'
	       .' [--force]'
	       .' [--parents]'			# 1.6
	       .' [--with-revprop ARG]'		# 1.6
	       .' [-F|--file FILE]'
	       .' [-m|--message TEXT]'
	       .' [-q|--quiet]'
	       .' [-r|--revision REV]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' SRC DST')},
  'patch'	=> {				# 1.7
      args => (''
	       .' [-q|--quiet]'
	       .' [--dry-run]'
	       .' [--strip ARG]'
	       .' [--reverse-diff]'
	       .' [--ignore-whitespace]'
	       .' PATCHFILE [WCPATH]')},
  'propdel'	=> {
      args => (''#'propdel PROPNAME [PATH...]'
	       #'propdel PROPNAME --revprop -r REV [URL]'
	       .' [--changelist ARG]'
	       .' [--depth ARG]'		# 1.6
	       .' [--revprop]'
	       .' [-R|--recursive]'
	       .' [-q|--quiet]'
	       .' [-r|--revision REV]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PROPNAME [PATHORURL...]')},
  'propedit'	=> {
      args => (''#'propedit PROPNAME PATH...'
	       #'propedit PROPNAME --revprop -r REV [URL]'
	       .' [--editor-cmd EDITOR]'
	       .' [--encoding ENC]'
	       .' [--force]'
	       .' [--force-log]'
	       .' [--revprop]'
	       .' [--with-revprop ARG]'
	       .' [-F|--file PATH]'
	       .' [-m|--message ARG]'
	       .' [-r|--revision REV]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PROPNAME [PATHORURL...]')},
  'propget'	=> {
      args => (''#'propget PROPNAME [PATH[@REV]...]'
	       #'propget PROPNAME --revprop -r REV [URL]'
	       .' [--changelist ARG]'
	       .' [--depth ARG]'		# 1.6
	       .' [--revprop]'
	       .' [--show-inherited-props]'	# 1.8
	       .' [--strict]'
	       .' [--xml]'
	       .' [-R|--recursive]'
	       .' [-r|--revision REV]'
	       .' [-v|--verbose]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PROPNAME [PATHORURL@PATHORURLREV...]')},
  'proplist'	=> {
      args => (''#'proplist [PATH[@REV]...]'
	       #'proplist -revprop -r REV [URL]'
	       .' [--changelist ARG]'
	       .' [--depth ARG]'		# 1.6
	       .' [--revprop]'
	       .' [--show-inherited-props]'	# 1.8
	       .' [--xml]'
	       .' [-R|--recursive]'
	       .' [-q|--quiet]'
	       .' [-r|--revision REV]'
	       .' [-v|--verbose]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PROPNAME [PATHORURL@PATHORURLREV...]')},
  'propset'	=> {
      args => (''#'propset PROPNAME [PROPVAL | -F VALFILE] PATH...'
	       #'propset PROPNAME --revprop -r REV [PROPVAL | -F VALFILE] [URL]'
	       .' [--changelist ARG]'
	       .' [--depth ARG]'		# 1.6
	       .' [--encoding ENC]'
	       .' [--force]'
	       .' [--revprop]'
	       .' [--targets FILENAME]'
	       .' [-F|--file FILE]'
	       .' [-R|--recursive]'
	       .' [-q|--quiet]'
	       .' [-r|--revision REV]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PROPNAME [PATHORURL...]')},
  'relocate'	=> {				# 1.7
      args => (''
	       #'relocate FROM-PREFIX TO-PREFIX [PATH...]
	       #'relocate TO-URL [PATH]
	       .' [--ignore-externals]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'
	       .' TOFROM [PATHORURL...]')},
  'resolve'	=> {
      args => (''
	       .' [--accept ARG]'
	       .' [--depth ARG]'
	       .' [--targets FILENAME]'
	       .' [-R|--recursive]'
	       .' [-q|--quiet]'
	       #
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PATH...')},
  'resolved'	=> {
      args => (''
	       .' [--depth ARG]'		# 1.6
	       .' [--targets FILENAME]'
	       .' [-R|--recursive]'
	       .' [-q|--quiet]'
	       #
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PATH...')},
  'revert'	=> {
      args => (''
	       .' [--changelist ARG]'
	       .' [--depth ARG]'		# 1.6
	       .' [--targets FILENAME]'
	       .' [-R|--recursive]'
	       .' [-q|--quiet]'
	       #
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PATH...')},
  'status'	=> {
      args => (''
	       .' [--top]'			# S4 addition
	       #
	       .' [--changelist ARG]'
	       .' [--depth ARG]'		# 1.6
	       .' [--ignore-externals]'
	       .' [--incremental]'
	       .' [--no-ignore]'
	       .' [--xml]'
	       .' [-N|--non-recursive]'
	       .' [-q|--quiet]'
	       .' [-u|--show-updates]'
	       .' [-v|--verbose]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' [PATH...]')},
  'switch'	=> {
      args => (''#'switch URL [PATH]'
	       #'switch --relocate FROM TO [PATH...]'
	       .' [--accept ARG]'
	       .' [--depth ARG]'
	       .' [--diff3-cmd CMD]'
	       .' [--force]'
	       .' [--ignore-ancestry]'		# 1.7
	       .' [--ignore-externals]'
	       .' [--relocate]'   # technically [--relocate FROM TO] but parser below doesn't support
	       .' [--set-depth ARG]'
	       .' [-N|--non-recursive]'
	       .' [-q|--quiet]'
	       .' [-r|--revision REV]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' ARG...')},
  'unlock'	=> {
      args => (''
	       .' [--force]'
	       .' [--targets FILENAME]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' PATH...')},
  'update'	=> {
      s4_changed => 1,
      args => (''
	       .' [--top]'			# S4 addition
	       #
	       .' [--accept ARG]'
	       .' [--changelist ARG]'
	       .' [--depth ARG]'		# 1.6
	       .' [--diff3-cmd CMD]'
	       .' [--editor-cmd EDITOR]'
	       .' [--force]'
	       .' [--ignore-externals]'
	       .' [--parents]'			# 1.8
	       .' [--set-depth ARG]'		# 1.6
	       .' [-N|--non-recursive]'
	       .' [-q|--quiet]'
	       .' [-r|--revision REV]'
	       #
	       .' [--username USER]'
	       .' [--password PASS]'
	       .' [--no-auth-cache]'
	       .' [--non-interactive]'
	       .' [--trust-server-cert]'	# 1.6
	       .' [--config-dir DIR]'
	       .' [--config-option ARG]'	# 1.6
	       .' [PATH...]')},
  'upgrade'	=> {
      args => (''
	       .' [-q|--quiet]')},		# 1.8
  #####
  # Commands added in S4
  'cat-or-mods' => {
      s4_addition => 1,
      args => (''
	       .' [PATH...]')},
  'fixprop'	=> {
      s4_addition => 1,
      args => (''
	       .' [-q|--quiet]'
	       .' [-R|--recursive]'		# Ignored as is default
	       .' [-N|--non-recursive]'
	       .' [--dry-run]'
	       .' [--personal]'
	       .' [--no-autoprops]'
	       .' [--no-keywords]'
	       .' [--no-ignores]'
	       .' [PATH...]')},
  'help-summary' => {
      s4_addition => 1,
      args => (''
	       .'')},
  'info-switches' => {
      s4_addition => 1,
      args => (''
	       .' [PATH...]')},
  'quick-commit' => {
      s4_addition => 1,
      args => (''
	       .' [-m|--message TEXT]'
	       .' [-F|--file FILE]'
	       .' [-q|--quiet]'
	       .' [--dry-run]'
	       .' [-R|--recursive]'		# Ignored as is default
	       .' [-N|--non-recursive]'
	       .' [PATH...]')},
  'snapshot' => {
      s4_addition => 1,
      args => (''
	       .' [--no-ignore]'
               .' PATH')},
  'scrub' => {
      s4_addition => 1,
      args => (''
	       .' [-r|--revision REV]'
               .' [--url URL]'
               .' [-v|--verbose]'
               . ' PATH')},
  'workpropdel'	=> {
      s4_addition => 1,
      args => (''
	       .' PROPNAME')},
  'workpropget'	=> {
      s4_addition => 1,
      args => (''
	       .' PROPNAME')},
  'workproplist' => {
      s4_addition => 1,
      args => (''
	       .' [--xml]'
	       .' [-v|--verbose]')},
  'workpropset'	=> {
      s4_addition => 1,
      args => (''
	       .' PROPNAME PROPVAL')},
  );

#######################################################################
#######################################################################
#######################################################################

sub new {
    @_ >= 1 or croak 'usage: SVN::S4::Getopt->new ({options})';
    my $class = shift;		# Class (Getopt Element)
    $class ||= __PACKAGE__;
    my $defaults = {pwd=>Cwd::getcwd(),
		    editor=>($ENV{SVN_EDITOR}||$ENV{VISUAL}||$ENV{EDITOR}||'emacs'),
		    ssh=>($ENV{SVN_SSH}),
		    # Ours
		    fileline=>'Command_Line:0',
		};
    my $self = {%{$defaults},
		defaults=>$defaults,
		@_,
	    };
    bless $self, $class;
    return $self;
}

#######################################################################
# Option parsing

sub parameter {
    my $self = shift;
    # Parse a parameter. Return list of leftover parameters

    my @new_params = ();
    foreach my $param (@_) {
	print " parameter($param)\n" if $Debug;
	$self->{_parameter_unknown} = 1;  # No global parameters
	if ($self->{_parameter_unknown}) {
	    push @new_params, $param;
	    next;
	}
    }
    return @new_params;
}

#######################################################################
# Accessors

sub commands_sorted {
    return (sort (keys %_Args));
}

sub command_arg_text {
    my $self = shift;
    my $cmd = shift;
    return ($_Args{$cmd}{args});
}

sub command_s4_addition {
    my $self = shift;
    my $cmd = shift;
    return ($_Args{$cmd}{s4_addition});
}

sub command_s4_changed {
    my $self = shift;
    my $cmd = shift;
    return ($_Args{$cmd}{s4_changed});
}

sub _param_changed {
    my $self = shift;
    my $param = shift;
    return (($self->{$param}||"") ne ($self->{defaults}{$param}||""));
}

#######################################################################
# Methods - help

sub command_help_summary {
    my $self = shift;
    my $cmd = shift;

    my $out = "";
    my $args = $self->command_arg_text($cmd);
    while ($args =~ / *(\[[^]]+\]|[^ ]+)/g) {
	$out .= "  $1\n";
    }
    return $out;
}

#######################################################################
# Methods - parsing

sub dealias {
    my $self = shift;
    my $cmd = shift;
    return $_Aliases{$cmd}||$cmd;
}

sub parse_pegrev {
    my $self = shift;
    my $arg = shift;
    if ($arg =~ /\@$/) {
	return ($arg, undef);
    } elsif ($arg =~ /^(.*)\@([0-9]+|HEAD|BASE|COMMITTED|PREV)$/) {
	return ($1,$2);
    } else {
	return ($arg, undef);
    }
}

sub _parse_template {
    my $self = shift;
    my $cmd = shift;
    # Parse the template and return state, or undef for unknown commands

    $cmd = $self->dealias($cmd);
    my $cmdTemplate = $_Args{$cmd}{args};
    return undef if !$cmdTemplate;

    my %parser;  # Hash of switch and if it gets a parameter
    my $paramNum=0;
    my $tempNum=0;
    my $tempElement = $cmdTemplate;
    while ($tempElement) {
	$tempElement =~ s/^\s+//;
	if ($tempElement =~ s/^\[(-\S+)\]//) {
	    my $switches = $1;
	    my $name = $1 if $switches =~ /(--[---a-zA-Z0-9_]+)/;
	    foreach my $sw (split /[|]/, $switches) {
		$parser{$sw} = {what=>$name, then=>undef, more=>0, num=>$tempNum++};
		print "case1. added parser{$sw} = ", Dumper($parser{$sw}), "\n" if $Debug;
	    }
	} elsif ($tempElement =~ s/^\[(-\S+)\s+(\S+)\]//) {
	    my $switches = $1;  my $then=$2;
	    my $name = $1 if $switches =~ /(--[---a-zA-Z0-9_]+)/;
	    $then = lc $name; $then =~ s/^-+//;  $then =~ s/[^a-z0-9]+/_/g;
	    foreach my $sw (split /[|]/, $switches) {
		$parser{$sw} = {what=>$name, then=>$then, more=>0, num=>$tempNum++};
		print "case2. added parser{$sw} = ", Dumper($parser{$sw}), "\n" if $Debug;
	    }
	} elsif ($tempElement =~ s/^\[(\S+)\.\.\.\]//) {
	    $parser{$paramNum} = {what=>lc $1, then=>undef, more=>1, num=>$tempNum++};
	    print "case3. added parser{$paramNum} = ", Dumper($parser{$paramNum}), "\n" if $Debug;
	    $paramNum++;
	} elsif ($tempElement =~ s/^\[(\S+)\]//) {
	    $parser{$paramNum} = {what=>lc $1, then=>undef, more=>0, num=>$tempNum++};
	    print "case4. added parser{$paramNum} = ", Dumper($parser{$paramNum}), "\n" if $Debug;
	    $paramNum++;
	} elsif ($tempElement =~ s/^(\S+)\.\.\.//) {
	    $parser{$paramNum} = {what=>lc $1, then=>undef, more=>1, num=>$tempNum++};
	    print "case5. added parser{$paramNum} = ", Dumper($parser{$paramNum}), "\n" if $Debug;
	    $paramNum++;
	} elsif ($tempElement =~ s/^(\S+)//) {
	    $parser{$paramNum} = {what=>lc $1, then=>undef, more=>0, num=>$tempNum++};
	    print "case6. added parser{$paramNum} = ", Dumper($parser{$paramNum}), "\n" if $Debug;
	    $paramNum++;
	} else {
	    die "s4: Internal-%Error: Bad Cmd Template $cmd/$paramNum: $cmdTemplate,";
	}
    }
    #use Data::Dumper; print "parseCmd: ",Dumper(\%parser) if $Debug||1;
    return \%parser;
}

sub parseCmd {
    my $self = shift;
    my $cmd = shift;
    my @args = @_;

    # Returns an array elements for each parameter.
    #    It's what the given argument is
    #		Switch, The name of the switch, or unknown
    my $parser = $self->_parse_template($cmd);
    $parser ||= {};
    print "parseCmd($cmd @args)\n" if $Debug;

    my @out;
    my $inSwitch;
    my $paramNum = 0;
    my $inFlags = 1;
    foreach my $arg (@args) {
	if ($inSwitch) {   # Argument to a switch
	    push @out, $inSwitch;
	    $inSwitch = 0;
	} elsif ($inFlags && $arg =~ /^-/) {
	    if ($arg eq "--") {
		$inFlags = 0;
	    } elsif ($parser->{$arg}) {
		push @out, $parser->{$arg}{what};
		$inSwitch = $parser->{$arg}{then};
	    } else {
		push @out, "unknown";
	    }
	} else {
	    if ($parser->{$paramNum}) {  # Named [optional?] argument
		push @out, $parser->{$paramNum}{what};
		$paramNum++ if !$parser->{$paramNum}{more};
	    } else {
		push @out, "unknown";
	    }
	}
    }
    return @out;
}

sub formCmd {
    my $self = shift;
    my $cmd = shift;
    my $hash = shift;
    my @out;

    my $parser = $self->_parse_template($cmd);
    $parser or croak "%Error: Undefined formCmd command: $cmd,";
    push @out, $cmd;

    my %didarg;  # Remove duplicates, for example -R and -revision
    foreach my $state (sort {$a->{num} <=> $b->{num}} values %{$parser}) {
	if ($state->{what} =~ /^--?(.*)$/) {
	    next if $didarg{$1}++;
	    if (defined $hash->{$1}) {
		if ($state->{then}) {  # --flag VALUE
		    push @out, $state->{what};
		    push @out, $hash->{$1};
		} else {  # --flag
		    if ($hash->{$1}) {
			push @out, $state->{what};
		    }
		}
	    }
	} else {
	    my $val = $hash->{$state->{what}};
	    if (defined $val) {
		if (ref $val && ref $val eq 'ARRAY') {
		    push @out, @$val;
		} else {
		    push @out, $val;
		}
	    }
	}
	#print Dumper($state);
    }
    #print Dumper(\@out);
    return @out;
}

sub expand_single_dash_args {
    my $self = shift;
    my @out;
    #$Debug=1;
    foreach my $arg (@_) {
        if ($arg =~ /^(-[A-Za-z])(.+)/) {
	    print "Expanding single-dash arg: $arg\n" if $Debug;
	    push @out, ($1,$2);
	} elsif ($arg =~ /^(-[^=]+)=(.+)/) {
	    print "Expanding option argument with equals: $arg\n" if $Debug;
	    push @out, ($1,$2);
	} else {
	    push @out, $arg;
	}
    }
    return @out;
}

sub hashCmd {
    my $self = shift;
    my $cmd = shift;
    my @args = @_;

    # If args passed from Getopt, then it's a object, which may confuse
    # later SWIG SVN::Client operations
    @args = map { $_.'' } @args;

    # if any single-dash args like "-r2000", expand them into "-r" and "2000"
    # before parsing.
    @args = $self->expand_single_dash_args (@args);

    my %hashed;
    my @cmdParsed = $self->parseCmd($cmd, @args);
    #use Data::Dumper; print "hashCmd: ",Dumper(\@args, \@cmdParsed);
    for (my $i=0; $i<=$#cmdParsed; $i++) {
	die if !defined $cmdParsed[$i];
	if ($cmdParsed[$i] =~ /^(-.*)$/) {
	    $hashed{$1} = 1;
	} else {
	    my $cmdname = $cmdParsed[$i];
	    my $arg = $args[$i];
	    if ($cmdname =~ /(.*)@(.*)$/) {
		$cmdname = $1;
		my $pegcmd = $2;
		my ($pegarg,$pegrev) = $self->parse_pegrev($arg);
		$arg = $pegarg;
		if (!ref $hashed{$pegcmd}) {
		    $hashed{$pegcmd} = [$pegrev];
		} else {
		    push @{$hashed{$pegcmd}}, $pegrev;
		}
	    }
	    if (!ref $hashed{$cmdname}) {
		$hashed{$cmdname} = [$arg];
	    } else {
		push @{$hashed{$cmdname}}, $arg;
	    }
	}
    }
    return %hashed;
}

sub stripOneArg {
    my $self = shift;
    my $switch = shift;
    my @args = @_;
    my @out;
    foreach my $par (@args) {
	push @out, $par unless $par eq $switch;
    }
    return @out;
}

#######################################################################

sub AUTOLOAD {
    my $self = $_[0];
    my $func = $AUTOLOAD;
    $func =~ s/.*:://;
    if (exists $self->{$func}) {
	eval "sub $func { \$_[0]->{'$func'} = \$_[1] if defined \$_[1]; return \$_[0]->{'$func'}; }; 1;" or die;
	goto &$AUTOLOAD;
    } else {
	croak "Undefined ".__PACKAGE__." subroutine $func called,";
    }
}

sub DESTROY {}

######################################################################
### Package return
1;
__END__

=pod

=head1 NAME

SVN::S4::Getopt - Get Subversion command line options

=head1 SYNOPSIS

  use SVN::S4::Getopt;
  my $opt = new SVN::S4::Getopt;
  ...
=head1 DESCRIPTION

The L<SVN::S4::Getopt> package provides standardized handling of global options
for the front of svn commands.

=over 4

=item $opt = SVN::S4::Getopt->new ( I<opts> )

Create a new Getopt.

=back

=head1 ACCESSORS

There is a accessor for each parameter listed above.  In addition:

=over 4

=item $self->commands_sorted()

Return sorted list of all commands.

=item $self->command_arg_text(<cmd>)

Return textual description of the specified command.

=item $self->command_s4_addition(<cmd>)

Return true if the command is only in s4.

=item $self->command_s4_changed(<cmd>)

Return true if the command is modified from normal SVN operation by s4.

=item $self->fileline()

The filename and line number last parsed.

=item $self->formCmd(<cmd>, <opts>)

Return an array of command arguments needed to specify the given command
with hash of given options.  Hash elements with unsupported options are
silently ignored.

=item $self->hashCmd(<cmd>, <opts>)

Return a hash with one key for each option.  The value of the key is 1 if a
no-argument option was set, else it is an array with each value the option
was set to.

=item $self->parseCmd(<cmd>, <opts>)

Return a array with one element for each option.  The element is either
'switch', the name of the switch the option is specifying, or the name of
the parameter.

=item $self->stripOneArg(-<arg>, <opts>...)

Return the option list, with the specified matching argument removed.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.org/>.

Copyright 2002-2017 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<SVN::S4>

=cut
